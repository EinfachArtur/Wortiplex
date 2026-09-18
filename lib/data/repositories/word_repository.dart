import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/language.dart';

class WordList {
  final List<String> solutions;
  final List<String> validGuesses;

  const WordList({required this.solutions, required this.validGuesses});
}

abstract class WordRepository {
  Future<WordList> loadWordList(Language language);
  Future<String> randomSolution(Language language, {Random? random});
}

class AssetWordRepository implements WordRepository {
  final Map<Language, WordList> _cache = {};

  String _assetPath(Language language) => 'assets/words/${language.code}_5.json';

  @override
  Future<WordList> loadWordList(Language language) async {
    final cached = _cache[language];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath(language));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final solutions = (json['solutions'] as List).cast<String>();
    final validGuesses = (json['valid_guesses'] as List).cast<String>();

    final list = WordList(solutions: solutions, validGuesses: validGuesses);
    _cache[language] = list;
    return list;
  }

  @override
  Future<String> randomSolution(Language language, {Random? random}) async {
    final list = await loadWordList(language);
    final rng = random ?? Random();
    return list.solutions[rng.nextInt(list.solutions.length)];
  }
}
