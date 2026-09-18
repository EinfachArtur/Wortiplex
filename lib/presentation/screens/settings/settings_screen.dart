import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/language.dart';
import '../../state/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _label(Language l) => switch (l) {
        Language.de => 'Deutsch',
        Language.en => 'English',
        Language.ru => 'Русский',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) => ListView(
          children: [
            ListTile(title: Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.bold))),
            for (final lang in Language.values)
              RadioListTile<Language>(
                title: Text(_label(lang)),
                value: lang,
                groupValue: profile.language,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(profileControllerProvider.notifier).setLanguage(value);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
