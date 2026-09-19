import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/language.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/state/ads_providers.dart';
import 'presentation/state/profile_providers.dart';
import 'presentation/state/purchase_listener.dart';

class WortiplexApp extends ConsumerStatefulWidget {
  const WortiplexApp({super.key});

  @override
  ConsumerState<WortiplexApp> createState() => _WortiplexAppState();
}

class _WortiplexAppState extends ConsumerState<WortiplexApp> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the store connection may not be ready instantly, and
    // the purchase listener (activated below) still applies any purchases
    // that complete after this resolves.
    ref.read(iapServiceProvider).initialize();
    ref.read(adsServiceProvider); // creating it starts preloading the ad clips
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the app-wide purchase listener alive for as long as the app runs.
    ref.watch(purchaseListenerProvider);

    final profileAsync = ref.watch(profileControllerProvider);
    final locale = profileAsync.valueOrNull?.language.code;

    return MaterialApp(
      title: 'WortiPlex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.game(),
      darkTheme: AppTheme.game(),
      themeMode: ThemeMode.dark,
      locale: locale != null ? Locale(locale) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
