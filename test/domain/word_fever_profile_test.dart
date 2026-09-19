import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/config/word_fever_config.dart';
import 'package:wortiplex/data/repositories/profile_repository.dart';
import 'package:wortiplex/domain/models/user_profile.dart';
import 'package:wortiplex/presentation/state/profile_providers.dart';

class _MemoryRepo implements ProfileRepository {
  UserProfile profile;
  _MemoryRepo(this.profile);

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;
}

void main() {
  Future<(ProviderContainer, _MemoryRepo)> setup() async {
    final repo = _MemoryRepo(UserProfile.fresh('t'));
    final container = ProviderContainer(overrides: [profileRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.future);
    return (container, repo);
  }

  test('a run pays coins per solved word and stores the best score', () async {
    final (container, repo) = await setup();
    final notifier = container.read(profileControllerProvider.notifier);
    final before = container.read(profileControllerProvider).value!.coins;

    final payout = await notifier.recordWordFeverRun(score: 450, solved: 4);

    expect(payout.coins, 4 * WordFeverConfig.coinsPerWord);
    expect(payout.isNewBest, isTrue);
    final profile = container.read(profileControllerProvider).value!;
    expect(profile.coins, before + payout.coins);
    expect(profile.wordFeverBest, 450);
    expect(repo.profile.wordFeverBest, 450);
  });

  test('a lower score keeps the record and is not reported as a new best', () async {
    final (container, _) = await setup();
    final notifier = container.read(profileControllerProvider.notifier);
    await notifier.recordWordFeverRun(score: 450, solved: 4);

    final payout = await notifier.recordWordFeverRun(score: 200, solved: 2);

    expect(payout.isNewBest, isFalse);
    expect(container.read(profileControllerProvider).value!.wordFeverBest, 450);
  });

  test('a run without solved words pays nothing', () async {
    final (container, _) = await setup();
    final notifier = container.read(profileControllerProvider.notifier);
    final before = container.read(profileControllerProvider).value!.coins;

    final payout = await notifier.recordWordFeverRun(score: 0, solved: 0);

    expect(payout.coins, 0);
    expect(container.read(profileControllerProvider).value!.coins, before);
  });

  test('the best score survives a save/load round trip', () {
    final restored = UserProfile.fromMap(UserProfile.fresh('t').copyWith(wordFeverBest: 730).toMap());
    expect(restored.wordFeverBest, 730);
  });
}
