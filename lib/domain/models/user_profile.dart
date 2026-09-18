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

  const UserProfile({
    required this.id,
    this.coins = 0,
    this.language = Language.de,
    this.statsByKey = const {},
    this.subscription = const SubscriptionStatus(),
    this.lastDailyPuzzleCompletedAt = const {},
    this.skipsAvailable = 3,
    this.lastSkipRefillAt,
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
  }) {
    return UserProfile(
      id: id,
      coins: coins ?? this.coins,
      language: language ?? this.language,
      statsByKey: statsByKey ?? this.statsByKey,
      subscription: subscription ?? this.subscription,
      lastDailyPuzzleCompletedAt: lastDailyPuzzleCompletedAt ?? this.lastDailyPuzzleCompletedAt,
      skipsAvailable: skipsAvailable ?? this.skipsAvailable,
      lastSkipRefillAt: lastSkipRefillAt ?? this.lastSkipRefillAt,
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
    );
  }

  factory UserProfile.fresh(String id) => UserProfile(id: id);
}
