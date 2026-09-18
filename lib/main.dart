import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/repositories/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveProfileRepository.ensureOpen();
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: WortiplexApp()));
}
