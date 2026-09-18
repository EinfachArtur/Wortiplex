class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int maxStreak;
  final Map<int, int> guessDistribution; // 1..6 -> count

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.guessDistribution = const {},
  });

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  GameStats recordResult({required bool won, int? guessesUsed}) {
    final newStreak = won ? currentStreak + 1 : 0;
    final distribution = Map<int, int>.from(guessDistribution);
    if (won && guessesUsed != null) {
      distribution[guessesUsed] = (distribution[guessesUsed] ?? 0) + 1;
    }
    return GameStats(
      gamesPlayed: gamesPlayed + 1,
      gamesWon: gamesWon + (won ? 1 : 0),
      currentStreak: newStreak,
      maxStreak: newStreak > maxStreak ? newStreak : maxStreak,
      guessDistribution: distribution,
    );
  }

  Map<String, dynamic> toMap() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'guessDistribution': guessDistribution.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory GameStats.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const GameStats();
    final rawDist = (map['guessDistribution'] as Map?) ?? const {};
    return GameStats(
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      gamesWon: (map['gamesWon'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      maxStreak: (map['maxStreak'] as num?)?.toInt() ?? 0,
      guessDistribution: rawDist.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt())),
    );
  }
}
