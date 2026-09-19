import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/config/word_fever_config.dart';
import 'package:wortiplex/domain/game/word_fever_run.dart';

void main() {
  test('starts with the configured time and no score', () {
    final run = WordFeverRun.start();
    expect(run.secondsLeft, WordFeverConfig.startSeconds);
    expect(run.score, 0);
    expect(run.isOver, isFalse);
  });

  test('ticking counts down and stops at zero', () {
    var run = const WordFeverRun(secondsLeft: 2);
    run = run.tick();
    expect(run.secondsLeft, 1);
    run = run.tick();
    expect(run.isOver, isTrue);
    expect(run.tick().secondsLeft, 0);
  });

  test('solving a word adds time and points, more for spare attempts', () {
    final quick = WordFeverRun.start().withSolved(attemptsLeft: 5);
    final slow = WordFeverRun.start().withSolved(attemptsLeft: 0);

    expect(quick.secondsLeft, WordFeverConfig.startSeconds + WordFeverConfig.solveBonusSeconds);
    expect(quick.solved, 1);
    expect(quick.score, WordFeverConfig.basePoints + 5 * WordFeverConfig.pointsPerAttemptLeft);
    expect(slow.score, WordFeverConfig.basePoints);
  });

  test('words solved in a row build a combo bonus that a failure resets', () {
    var run = WordFeverRun.start().withSolved(attemptsLeft: 0);
    final first = run.score;
    run = run.withSolved(attemptsLeft: 0);
    expect(run.score - first, WordFeverConfig.basePoints + WordFeverConfig.pointsPerCombo);

    run = run.withFailed();
    expect(run.failed, 1);
    expect(run.combo, 0);
    final before = run.score;
    run = run.withSolved(attemptsLeft: 0);
    expect(run.score - before, WordFeverConfig.basePoints);
  });

  test('the combo bonus is capped', () {
    var run = WordFeverRun.start();
    for (var i = 0; i < 30; i++) {
      run = run.withSolved(attemptsLeft: 0);
    }
    final before = run.score;
    run = run.withSolved(attemptsLeft: 0);
    expect(
      run.score - before,
      WordFeverConfig.basePoints + WordFeverConfig.pointsPerCombo * WordFeverConfig.maxComboBonusSteps,
    );
  });

  test('failing a word costs no time but gives no bonus either', () {
    final run = WordFeverRun.start().withFailed();
    expect(run.secondsLeft, WordFeverConfig.startSeconds);
    expect(run.score, 0);
  });
}
