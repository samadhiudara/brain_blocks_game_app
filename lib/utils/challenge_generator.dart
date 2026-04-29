import 'dart:math';
import '../models/block_model.dart';

class ChallengeGenerator {
  static final _rng = Random();

  static MiniChallenge generate(int level) {
    final types = MiniChallengeType.values;
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case MiniChallengeType.math: return _mathChallenge(level);
      case MiniChallengeType.word: return _wordChallenge();
      case MiniChallengeType.pattern: return _patternChallenge();
      case MiniChallengeType.sequence: return _sequenceChallenge(level);
    }
  }

  static MiniChallenge _mathChallenge(int level) {
    int a, b, answer;
    String question;
    if (level <= 2) {
      a = _rng.nextInt(20) + 1; b = _rng.nextInt(20) + 1;
      answer = a + b; question = '$a + $b = ?';
    } else if (level <= 4) {
      a = _rng.nextInt(15) + 5; b = _rng.nextInt(10) + 1;
      answer = a * b; question = '$a × $b = ?';
    } else {
      a = _rng.nextInt(20) + 10; b = _rng.nextInt(10) + 2;
      answer = a * b - _rng.nextInt(5);
      question = '${a} × ${b} - ${a * b - answer} = ?';
    }
    final options = _generateNumOptions(answer, 4);
    return MiniChallenge(
      type: MiniChallengeType.math, question: question,
      options: options, correctIndex: options.indexOf(answer.toString()),
      bonusPoints: 50 + level * 10, timeSeconds: max(8, 15 - level),
    );
  }

  static List<String> _generateNumOptions(int correct, int count) {
    final opts = <int>{correct};
    while (opts.length < count) opts.add(correct + _rng.nextInt(21) - 10);
    final list = opts.toList()..shuffle();
    return list.map((e) => e.toString()).toList();
  }

  static MiniChallenge _wordChallenge() {
    const challenges = [
      {'q': 'What is the OPPOSITE of "Ancient"?', 'opts': ['Modern','Old','Historic','Aged'], 'a': 0},
      {'q': 'Which word means "Very Happy"?', 'opts': ['Melancholy','Elated','Anxious','Weary'], 'a': 1},
      {'q': 'SYNONYM of "Brave"?', 'opts': ['Timid','Cowardly','Courageous','Afraid'], 'a': 2},
      {'q': 'ANTONYM of "Generous"?', 'opts': ['Kind','Giving','Charitable','Stingy'], 'a': 3},
      {'q': 'Which word is spelled correctly?', 'opts': ['Recieve','Receive','Receve','Recieve'], 'a': 1},
      {'q': '"Ephemeral" means?', 'opts': ['Permanent','Short-lived','Colorful','Loud'], 'a': 1},
      {'q': 'SYNONYM of "Verbose"?', 'opts': ['Silent','Wordy','Brief','Concise'], 'a': 1},
    ];
    final c = challenges[_rng.nextInt(challenges.length)];
    return MiniChallenge(
      type: MiniChallengeType.word, question: c['q'] as String,
      options: List<String>.from(c['opts'] as List),
      correctIndex: c['a'] as int, bonusPoints: 60, timeSeconds: 12,
    );
  }

  static MiniChallenge _patternChallenge() {
    const challenges = [
      {'q': '2, 4, 8, 16, __?', 'opts': ['24','32','20','18'], 'a': 1},
      {'q': '1, 4, 9, 16, __?', 'opts': ['20','25','23','22'], 'a': 1},
      {'q': '3, 6, 12, 24, __?', 'opts': ['36','48','30','42'], 'a': 1},
      {'q': '1, 1, 2, 3, 5, 8, __?', 'opts': ['12','13','11','14'], 'a': 1},
      {'q': '10, 9, 7, 4, __?', 'opts': ['2','0','1','-1'], 'a': 1},
      {'q': '🔴🔵🔴🔵🔴__?', 'opts': ['🔴','🔵','🟢','🟡'], 'a': 1},
      {'q': '⭐⭐🌙⭐⭐🌙__?', 'opts': ['🌙','⭐','☀️','💫'], 'a': 0},
    ];
    final c = challenges[_rng.nextInt(challenges.length)];
    return MiniChallenge(
      type: MiniChallengeType.pattern, question: c['q'] as String,
      options: List<String>.from(c['opts'] as List),
      correctIndex: c['a'] as int, bonusPoints: 70, timeSeconds: 12,
    );
  }

  static MiniChallenge _sequenceChallenge(int level) {
    const challenges = [
      {'q': 'Which comes NEXT?\nMonday → Tuesday → Wednesday → ?', 'opts': ['Friday','Thursday','Saturday','Sunday'], 'a': 1},
      {'q': 'Complete the sequence:\nJan → Mar → May → ?', 'opts': ['June','August','July','April'], 'a': 2},
      {'q': 'A → C → E → G → ?', 'opts': ['H','I','J','K'], 'a': 1},
      {'q': 'Z → Y → X → W → ?', 'opts': ['U','V','T','S'], 'a': 1},
      {'q': 'Spring → Summer → Autumn → ?', 'opts': ['Rain','Winter','Snow','Cold'], 'a': 1},
    ];
    final c = challenges[_rng.nextInt(challenges.length)];
    return MiniChallenge(
      type: MiniChallengeType.sequence, question: c['q'] as String,
      options: List<String>.from(c['opts'] as List),
      correctIndex: c['a'] as int, bonusPoints: 55, timeSeconds: 13,
    );
  }
}