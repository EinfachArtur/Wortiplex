import 'daily_history.dart';
import 'game_stats.dart';
import 'language.dart';
import 'subscription_status.dart';

class UserProfile {
  final String id;
  final int coins;
  final Language language;
  final Map<String, GameStats> statsByKey; // e.g. "classic_de", "daily_ru"
  final SubscriptionStatus subscription;
  final Map<String, DateTime> lastDailyPuzzleCompletedAt; // per language code
  final int skipsAvailable;
  final DateTime? lastSkipRefillAt;
  final DateTime? lastDailyLoginClaimedAt;
  final int dailyLoginStreak;
  final DateTime? lastSpinAt;
  final int hintTokens;
  final int strikeoutTokens;
  final int spinTickets;
  final DailyHistory dailyHistory;
  final Set<String> claimedMonthlyPrizes;
  final List<DateTime> rewardedAdTimestamps;

  /// Best Word Fever score so far.
  final int wordFeverBest;

  static const int maxRewardedAdsPerHour = 5;
  static const Duration rewardedAdWindow = Duration(hours: 1);

  List<DateTime> get recentRewardedAds {
    final now = DateTime.now();
    return rewardedAdTimestamps
        .where((ts) => now.difference(ts) < rewardedAdWindow)
        .toList();
  }

  int get remainingRewardedAds =>
      (maxRewardedAdsPerHour - recentRewardedAds.length).clamp(0, maxRewardedAdsPerHour);

  bool get canWatchRewardedAd => remainingRewardedAds > 0;

  Duration? get rewardedAdCooldownRemaining {
    final recent = recentRewardedAds;
    if (recent.length < maxRewardedAdsPerHour) return null;
    final oldest = recent.reduce((a, b) => a.isBefore(b) ? a : b);
    final elapsed = DateTime.now().difference(oldest);
    if (elapsed >= rewardedAdWindow) return null;
    return rewardedAdWindow - elapsed;
  }

  const UserProfile({
    required this.id,
    this.coins = 0,
    this.language = Language.de,
    this.statsByKey = const {},
    this.subscription = const SubscriptionStatus(),
    this.lastDailyPuzzleCompletedAt = const {},
    this.skipsAvailable = 3,
    this.lastSkipRefillAt,
    this.lastDailyLoginClaimedAt,
    this.dailyLoginStreak = 0,
    this.lastSpinAt,
    this.hintTokens = 0,
    this.strikeoutTokens = 0,
    this.spinTickets = 0,
    this.dailyHistory = const DailyHistory(),
    this.claimedMonthlyPrizes = const {},
    this.rewardedAdTimestamps = const [],
    this.wordFeverBest = 0,
  });

  static String statsKey(String mode, Language language) => '${mode}_${language.code}';

  GameStats statsFor(String mode, Language language) =>
      statsByKey[statsKey(mode, language)] ?? const GameStats();

  UserProfile copyWith({
    int? coins,
    Language? language,
    Map<String, GameStats>? statsByKey,
    SubscriptionStatus? subscription,
    Map<String, DateTime>? lastDailyPuzzleCompletedAt,
    int? skipsAvailable,
    DateTime? lastSkipRefillAt,
    bool clearLastSkipRefillAt = false,
    DateTime? lastDailyLoginClaimedAt,
    int? dailyLoginStreak,
    DateTime? lastSpinAt,
    int? hintTokens,
    int? strikeoutTokens,
    int? spinTickets,
    DailyHistory? dailyHistory,
    Set<String>? claimedMonthlyPrizes,
    List<DateTime>? rewardedAdTimestamps,
    int? wordFeverBest,
  }) {
    return UserProfile(
      id: id,
      coins: coins ?? this.coins,
      language: language ?? this.language,
      statsByKey: statsByKey ?? this.statsByKey,
      subscription: subscription ?? this.subscription,
      lastDailyPuzzleCompletedAt: lastDailyPuzzleCompletedAt ?? this.lastDailyPuzzleCompletedAt,
      skipsAvailable: skipsAvailable ?? this.skipsAvailable,
      lastSkipRefillAt: clearLastSkipRefillAt ? null : (lastSkipRefillAt ?? this.lastSkipRefillAt),
      lastDailyLoginClaimedAt: lastDailyLoginClaimedAt ?? this.lastDailyLoginClaimedAt,
      dailyLoginStreak: dailyLoginStreak ?? this.dailyLoginStreak,
      lastSpinAt: lastSpinAt ?? this.lastSpinAt,
      hintTokens: hintTokens ?? this.hintTokens,
      strikeoutTokens: strikeoutTokens ?? this.strikeoutTokens,
      spinTickets: spinTickets ?? this.spinTickets,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      claimedMonthlyPrizes: claimedMonthlyPrizes ?? this.claimedMonthlyPrizes,
      rewardedAdTimestamps: rewardedAdTimestamps ?? this.rewardedAdTimestamps,
      wordFeverBest: wordFeverBest ?? this.wordFeverBest,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'coins': coins,
        'language': language.code,
        'statsByKey': statsByKey.map((k, v) => MapEntry(k, v.toMap())),
        'subscription': subscription.toMap(),
        'lastDailyPuzzleCompletedAt':
            lastDailyPuzzleCompletedAt.map((k, v) => MapEntry(k, v.toIso8601String())),
        'skipsAvailable': skipsAvailable,
        'lastSkipRefillAt': lastSkipRefillAt?.toIso8601String(),
        'lastDailyLoginClaimedAt': lastDailyLoginClaimedAt?.toIso8601String(),
        'dailyLoginStreak': dailyLoginStreak,
        'lastSpinAt': lastSpinAt?.toIso8601String(),
        'hintTokens': hintTokens,
        'strikeoutTokens': strikeoutTokens,
        'spinTickets': spinTickets,
        'dailyHistory': dailyHistory.toMap(),
        'claimedMonthlyPrizes': claimedMonthlyPrizes.toList(),
        'rewardedAdTimestamps':
            rewardedAdTimestamps.map((t) => t.toIso8601String()).toList(),
        'wordFeverBest': wordFeverBest,
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawStats = (map['statsByKey'] as Map?) ?? const {};
    final rawDaily = (map['lastDailyPuzzleCompletedAt'] as Map?) ?? const {};
    return UserProfile(
      id: map['id'] as String,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      language: LanguageCode.fromCode(map['language'] as String? ?? 'de'),
      statsByKey: rawStats.map((k, v) => MapEntry(k.toString(), GameStats.fromMap(v as Map?))),
      subscription: SubscriptionStatus.fromMap(map['subscription'] as Map?),
      lastDailyPuzzleCompletedAt: rawDaily.map(
        (k, v) => MapEntry(k.toString(), DateTime.parse(v as String)),
      ),
      skipsAvailable: (map['skipsAvailable'] as num?)?.toInt() ?? 3,
      lastSkipRefillAt:
          map['lastSkipRefillAt'] != null ? DateTime.tryParse(map['lastSkipRefillAt'] as String) : null,
      lastDailyLoginClaimedAt: map['lastDailyLoginClaimedAt'] != null
          ? DateTime.tryParse(map['lastDailyLoginClaimedAt'] as String)
          : null,
      dailyLoginStreak: (map['dailyLoginStreak'] as num?)?.toInt() ?? 0,
      lastSpinAt: map['lastSpinAt'] != null ? DateTime.tryParse(map['lastSpinAt'] as String) : null,
      hintTokens: (map['hintTokens'] as num?)?.toInt() ?? 0,
      strikeoutTokens: (map['strikeoutTokens'] as num?)?.toInt() ?? 0,
      spinTickets: (map['spinTickets'] as num?)?.toInt() ?? 0,
      dailyHistory: DailyHistory.fromMap(map['dailyHistory'] as Map?),
      claimedMonthlyPrizes: ((map['claimedMonthlyPrizes'] as List?) ?? const []).cast<String>().toSet(),
      rewardedAdTimestamps: ((map['rewardedAdTimestamps'] as List?) ?? const [])
          .map((t) => DateTime.tryParse(t.toString()))
          .whereType<DateTime>()
          .toList(),
      wordFeverBest: (map['wordFeverBest'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserProfile.fresh(String id) => UserProfile(id: id, coins: 300);
}
