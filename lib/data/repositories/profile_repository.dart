import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
}

/// Local-first persistence via Hive. Cloud sync (Firebase) can wrap this
/// repository later without changing callers, since callers only depend
/// on the [ProfileRepository] interface.
class HiveProfileRepository implements ProfileRepository {
  static const boxName = 'profile_box';
  static const _key = 'profile';
  static const _localProfileId = 'local_player';

  Box get _box => Hive.box(boxName);

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  @override
  Future<UserProfile> load() async {
    final raw = _box.get(_key);
    if (raw == null) {
      final fresh = UserProfile.fresh(_localProfileId);
      await save(fresh);
      return fresh;
    }
    return UserProfile.fromMap(raw as Map);
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _box.put(_key, profile.toMap());
  }
}
