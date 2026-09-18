import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/language.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/state/profile_providers.dart';

class WortiplexApp extends ConsumerWidget {
  const WortiplexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final locale = profileAsync.valueOrNull?.language.code;

    return MaterialApp(
      title: 'Wortiplex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale != null ? Locale(locale) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
