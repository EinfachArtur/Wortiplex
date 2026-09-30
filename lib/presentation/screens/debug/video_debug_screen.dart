import 'package:flutter/material.dart';

import '../../../core/config/video_presets.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/game/guess_evaluator.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/letter_state.dart';
import '../../widgets/game_scaffold.dart';
import '../game_board/game_board_screen.dart';

/// Debug-only menu for the video version: pick a scripted [VideoPreset]
/// and start a round with it. Reachable from the home screen in debug builds.
class VideoDebugScreen extends StatefulWidget {
  const VideoDebugScreen({super.key});

  @override
  State<VideoDebugScreen> createState() => _VideoDebugScreenState();
}

class _VideoDebugScreenState extends State<VideoDebugScreen> {
  VideoPreset _selected = VideoPresets.all.first;

  void _start() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameBoardScreen(mode: GameMode.classic, videoPreset: _selected)));
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Video-Szenarien',
      showCoins: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const GameText('Szenario', size: 18, textAlign: TextAlign.left, shadow: null),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            radius: 20,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VideoPreset>(
                value: _selected,
                isExpanded: true,
                dropdownColor: GameColors.night1,
                items: [
                  for (final p in VideoPresets.all)
                    DropdownMenuItem(value: p, child: GameText(p.title, size: 16, textAlign: TextAlign.left, shadow: null)),
                ],
                onChanged: (p) => setState(() => _selected = p ?? _selected),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const GameText('Skript', size: 18, textAlign: TextAlign.left, shadow: null),
          const SizedBox(height: 10),
          GlassCard(child: _ScriptPreview(preset: _selected)),
          const SizedBox(height: 24),
          ChunkyButton(
            height: 60,
            onPressed: _start,
            child: const GameText('AUFNAHME STARTEN', size: 18, color: GameColors.night0, shadow: null),
          ),
        ],
      ),
    );
  }
}

/// The rows to type, coloured as the game will evaluate them.
class _ScriptPreview extends StatelessWidget {
  final VideoPreset preset;
  const _ScriptPreview({required this.preset});

  Color _color(LetterState s) => switch (s) {
    LetterState.correct => GameColors.mint,
    LetterState.present => GameColors.amber,
    LetterState.absent => GameColors.slate,
    LetterState.unknown => GameColors.pill,
  };

  @override
  Widget build(BuildContext context) {
    const evaluator = GuessEvaluator();
    return Column(
      children: [
        for (final (i, word) in preset.forcedGuesses.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 28, child: GameText('${i + 1}', size: 14, color: GameColors.textDim, shadow: null)),
                for (final lg in evaluator.evaluate(guess: word, solution: preset.targetWord))
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _color(lg.state), borderRadius: BorderRadius.circular(8)),
                    child: GameText(lg.letter, size: 18, shadow: null),
                  ),
              ],
            ),
          ),
        if (preset.allowedWords.isNotEmpty) ...[
          const SizedBox(height: 10),
          GameText(
            'Zusätzlich erlaubt: ${preset.allowedWords.join(', ')}',
            size: 12,
            color: GameColors.textDim,
            shadow: null,
            weight: 600,
            textAlign: TextAlign.left,
          ),
        ],
      ],
    );
  }
}
