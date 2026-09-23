import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/language.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/game_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _label(Language l) => switch (l) {
        Language.de => 'Deutsch',
        Language.en => 'English',
        Language.ru => 'Русский',
        Language.fr => 'Français',
        Language.it => 'Italiano',
        Language.es => 'Español',
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
                      flag: lang.flagEmoji,
                      label: _label(lang),
                      selected: profile.language == lang,
                      onTap: () => ref.read(profileControllerProvider.notifier).setLanguage(lang),
                    ),
                  ),
                const SizedBox(height: 20),
                GameText(l10n.playerId, size: 18, textAlign: TextAlign.left, shadow: null),
                const SizedBox(height: 12),
                const _PlayerIdTile(),
              ],
            ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.flag, required this.label, required this.selected, required this.onTap});

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
              child: Text(flag, style: const TextStyle(fontSize: 24)),
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

class _PlayerIdTile extends ConsumerStatefulWidget {
  const _PlayerIdTile();

  @override
  ConsumerState<_PlayerIdTile> createState() => _PlayerIdTileState();
}

class _PlayerIdTileState extends ConsumerState<_PlayerIdTile> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final rc = ref.read(revenueCatServiceProvider);
    final id = await rc.getAppUserId();
    if (mounted) {
      setState(() => _userId = id);
    }
  }

  Future<void> _copyId() async {
    if (_userId == null || _userId!.isEmpty || _userId == 'unknown') return;
    await Clipboard.setData(ClipboardData(text: _userId!));
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.playerIdCopied),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1400),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final idText = _userId ?? '...';

    return GestureDetector(
      onTap: _copyId,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameColors.glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: GameColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GameColors.mint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.fingerprint_rounded, color: GameColors.mint, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameText(l10n.playerId, size: 16, textAlign: TextAlign.left, shadow: null, weight: 700),
                  const SizedBox(height: 3),
                  Text(
                    idText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.playerIdTapToCopy,
                    style: TextStyle(
                      fontSize: 11,
                      color: GameColors.mint.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GameColors.pill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
