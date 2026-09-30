/// Scripted rounds for recording short-form videos (TikTok/Reels/Shorts)
/// built on the "misdirection / plot twist" pattern: the green letters make
/// viewers expect a cheeky word, the last row resolves it.
///
/// A preset only exists in debug builds' video menu. It fixes the solution
/// and widens the dictionary; the player still types every row by hand.
class VideoPreset {
  final String id;
  final String title;

  /// The solution of the round (5 letters).
  final String targetWord;

  /// The rows the player types, in order. The last one is [targetWord].
  final List<String> forcedGuesses;

  /// Extra words the validator must accept even if the dictionary lacks
  /// them (slang, swear words, alternative bait words).
  final List<String> allowedWords;

  const VideoPreset({
    required this.id,
    required this.title,
    required this.targetWord,
    required this.forcedGuesses,
    this.allowedWords = const [],
  });

  /// Everything this preset needs the validator to accept.
  Set<String> get acceptedWords => {targetWord, ...forcedGuesses, ...allowedWords}.map((w) => w.toUpperCase()).toSet();
}

class VideoPresets {
  VideoPresets._();

  static const all = <VideoPreset>[
    VideoPreset(
      id: 'itch',
      title: '_ITCH-Reim → PITCH',
      targetWord: 'PITCH',
      forcedGuesses: ['DITCH', 'CATCH', 'WITCH', 'BITCH', 'PITCH'],
      allowedWords: ['BITCH'],
    ),
    VideoPreset(
      id: 'igga',
      title: '_IGGA-Bait → DIGGA',
      targetWord: 'DIGGA',
      forcedGuesses: ['LIGHT', 'SIGHT', 'SIGMA', 'DIGGA'],
      allowedWords: ['SIGMA'],
    ),
    VideoPreset(
      id: 'ick',
      title: '_ICK-Bait → BRICK',
      targetWord: 'BRICK',
      forcedGuesses: ['TRUCK', 'CLOCK', 'QUICK', 'THICK', 'DICKS', 'BRICK'],
      allowedWords: ['DICKS', 'CHICK'],
    ),
    VideoPreset(
      id: 'sht',
      title: 'SH_T-Bait → SHIRT',
      targetWord: 'SHIRT',
      forcedGuesses: ['SMART', 'SHORT', 'SHOOT', 'SHITS', 'SHIRT'],
      allowedWords: ['SHITS'],
    ),
    VideoPreset(
      id: 'ucks',
      title: '_UCKS-Bait → PUCKS',
      targetWord: 'PUCKS',
      forcedGuesses: ['DUCKS', 'BUCKS', 'SUCKS', 'FUCKS', 'PUCKS'],
      allowedWords: ['FUCKS', 'SUCKS'],
    ),
    VideoPreset(
      id: 'ocks',
      title: '_OCKS-Bait → DOCKS',
      targetWord: 'DOCKS',
      forcedGuesses: ['ROCKS', 'SOCKS', 'LOCKS', 'COCKS', 'DOCKS'],
      allowedWords: ['COCKS'],
    ),
    VideoPreset(
      id: 'ussy',
      title: '_USSY-Bait → FUSSY',
      targetWord: 'FUSSY',
      forcedGuesses: ['GASSY', 'MOSSY', 'BOSSY', 'PUSSY', 'FUSSY'],
      allowedWords: ['PUSSY'],
    ),
    VideoPreset(
      id: 'boo_s',
      title: 'BOO_S-Bait → BOOTS',
      targetWord: 'BOOTS',
      forcedGuesses: ['BOARD', 'BOOKS', 'BOOMS', 'BOOBS', 'BOOTS'],
      allowedWords: ['BOOBS'],
    ),
    VideoPreset(
      id: 'itty',
      title: '_ITTY-Bait → KITTY',
      targetWord: 'KITTY',
      forcedGuesses: ['DITTY', 'WITTY', 'TITTY', 'KITTY'],
      allowedWords: ['TITTY'],
    ),
    VideoPreset(
      id: 'who_e',
      title: 'WHO_E-Bait → WHOLE',
      targetWord: 'WHOLE',
      forcedGuesses: ['SHORE', 'CHORE', 'WHORE', 'WHOSE', 'WHOLE'],
      allowedWords: ['WHORE'],
    ),
    // German baits.
    VideoPreset(
      id: 'itte',
      title: '_ITTE-Bait → BITTE (DE)',
      targetWord: 'BITTE',
      forcedGuesses: ['MITTE', 'KITTE', 'TITTE', 'BITTE'],
      allowedWords: ['KITTE', 'TITTE'],
    ),
    VideoPreset(
      id: 'ickt',
      title: '_ICKT-Bait → NICKT (DE)',
      targetWord: 'NICKT',
      forcedGuesses: ['KICKT', 'TICKT', 'FICKT', 'NICKT'],
      allowedWords: ['KICKT', 'TICKT', 'FICKT'],
    ),
  ];

  static VideoPreset? byId(String? id) {
    if (id == null) return null;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
