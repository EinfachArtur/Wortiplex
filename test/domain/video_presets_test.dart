import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/config/video_presets.dart';

void main() {
  for (final preset in VideoPresets.all) {
    test('video preset ${preset.id} is a playable script', () {
      expect(preset.targetWord.length, 5);
      expect(preset.forcedGuesses.last, preset.targetWord);
      expect(preset.forcedGuesses.length, lessThanOrEqualTo(6));
      for (final w in preset.acceptedWords) {
        expect(w.length, 5, reason: w);
      }
    });
  }

  test('video preset ids are unique', () {
    final ids = VideoPresets.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
