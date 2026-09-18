import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/language.dart';
import '../../state/profile_providers.dart';
import '../../widgets/game_scaffold.dart';

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
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return GameScaffold(
      title: l10n.settings,
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                GameText(l10n.language, size: 18, textAlign: TextAlign.left, shadow: null),
                const SizedBox(height: 12),
                for (final lang in Language.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LanguageTile(
                      code: lang.code.toUpperCase(),
                      label: _label(lang),
                      selected: profile.language == lang,
                      onTap: () => ref.read(profileControllerProvider.notifier).setLanguage(lang),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.code, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? GameColors.mint.withValues(alpha: 0.14) : GameColors.glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? GameColors.mint : GameColors.glassBorder, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected ? GameColors.mint : GameColors.pill, borderRadius: BorderRadius.circular(15)),
              child: GameText(code, size: 16, color: selected ? GameColors.night0 : Colors.white, shadow: null),
            ),
            const SizedBox(width: 14),
            Expanded(child: GameText(label, size: 18, textAlign: TextAlign.left, shadow: null)),
            if (selected) const Icon(Icons.check_circle_rounded, color: GameColors.mint, size: 28),
          ],
        ),
      ),
    );
  }
}
