import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/theme/game_style.dart';
import 'data/repositories/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: GameColors.night0,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await initializeDateFormatting();
  await Hive.initFlutter();
  await HiveProfileRepository.ensureOpen();
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: WortiplexApp()));
}
