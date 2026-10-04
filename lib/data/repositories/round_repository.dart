import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/round.dart';

abstract class RoundRepository {
  Future<Round?> loadActiveRound(String key);
  Future<void> saveActiveRound(String key, Round round);
  Future<void> clearActiveRound(String key);
}

/// Local-first active round persistence via Hive.
class HiveRoundRepository implements RoundRepository {
  static const boxName = 'rounds_box';
  final Map<String, Map<String, dynamic>> _inMemoryFallback = {};

  Box? get _box => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  @override
  Future<Round?> loadActiveRound(String key) async {
    final box = _box;
    final raw = box != null ? box.get(key) : _inMemoryFallback[key];
    if (raw == null) return null;
    try {
      return Round.fromMap(raw as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveRound(String key, Round round) async {
    final map = round.toMap();
    final box = _box;
    if (box != null) {
      await box.put(key, map);
    } else {
      _inMemoryFallback[key] = map;
    }
  }

  @override
  Future<void> clearActiveRound(String key) async {
    final box = _box;
    if (box != null) {
      await box.delete(key);
    } else {
      _inMemoryFallback.remove(key);
    }
  }
}
