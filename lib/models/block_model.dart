import 'package:flutter/material.dart';

enum BlockType { I, O, T, S, Z, L, J }
enum MiniChallengeType { math, word, pattern, sequence }
enum GameStatus { idle, playing, paused, miniChallenge, levelComplete, gameOver }

const Map<BlockType, List<List<List<int>>>> kRotations = {
  BlockType.I: [
    [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0]],
    [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0]],
  ],
  BlockType.O: [
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[1,0],[1,1]],
  ],
  BlockType.T: [
    [[0,1],[1,0],[1,1],[1,2]],
    [[0,0],[1,0],[2,0],[1,1]],
    [[1,0],[1,1],[1,2],[2,1]],
    [[0,1],[1,1],[2,1],[1,0]],
  ],
  BlockType.S: [
    [[0,1],[0,2],[1,0],[1,1]],
    [[0,0],[1,0],[1,1],[2,1]],
    [[0,1],[0,2],[1,0],[1,1]],
    [[0,0],[1,0],[1,1],[2,1]],
  ],
  BlockType.Z: [
    [[0,0],[0,1],[1,1],[1,2]],
    [[0,1],[1,0],[1,1],[2,0]],
    [[0,0],[0,1],[1,1],[1,2]],
    [[0,1],[1,0],[1,1],[2,0]],
  ],
  BlockType.L: [
    [[0,0],[1,0],[2,0],[2,1]],
    [[0,0],[0,1],[0,2],[1,0]],
    [[0,0],[0,1],[1,1],[2,1]],
    [[0,2],[1,0],[1,1],[1,2]],
  ],
  BlockType.J: [
    [[0,1],[1,1],[2,0],[2,1]],
    [[0,0],[1,0],[1,1],[1,2]],
    [[0,0],[0,1],[1,0],[2,0]],
    [[0,0],[0,1],[0,2],[1,2]],
  ],
};

const Map<BlockType, Color> kBlockColors = {
  BlockType.I: Color(0xFF00D4FF),
  BlockType.O: Color(0xFFFFD93D),
  BlockType.T: Color(0xFFAA60FF),
  BlockType.S: Color(0xFF6BCB77),
  BlockType.Z: Color(0xFFFF6B6B),
  BlockType.L: Color(0xFFFF9A3D),
  BlockType.J: Color(0xFF4ECDC4),
};

class ActiveBlock {
  final BlockType type;
  final int rotation;
  final int row;
  final int col;

  const ActiveBlock({required this.type, this.rotation = 0, this.row = 0, this.col = 3});

  List<List<int>> get cells => kRotations[type]![rotation % 4];
  Color get color => kBlockColors[type]!;
  List<List<int>> get absoluteCells => cells.map((c) => [row + c[0], col + c[1]]).toList();

  ActiveBlock copyWith({int? rotation, int? row, int? col}) =>
      ActiveBlock(type: type, rotation: rotation ?? this.rotation,
          row: row ?? this.row, col: col ?? this.col);
}

class MiniChallenge {
  final MiniChallengeType type;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int timeSeconds;
  final int bonusPoints;

  const MiniChallenge({
    required this.type, required this.question, required this.options,
    required this.correctIndex, this.timeSeconds = 15, this.bonusPoints = 50,
  });
}

class BBGameState {
  final List<List<Color?>> board;
  final ActiveBlock? activeBlock;
  final ActiveBlock? nextBlock;
  final int score;
  final int level;
  final int linesCleared;
  final GameStatus status;
  final MiniChallenge? currentChallenge;
  final int highScore;
  final int combo;
  final bool challengeCorrect;
  final List<int> flashRows;
  final int blocksPlaced;

  const BBGameState({
    required this.board, this.activeBlock, this.nextBlock,
    this.score = 0, this.level = 1, this.linesCleared = 0,
    this.status = GameStatus.idle, this.currentChallenge,
    this.highScore = 0, this.combo = 0, this.challengeCorrect = false,
    this.flashRows = const [], this.blocksPlaced = 0,
  });

  BBGameState copyWith({
    List<List<Color?>>? board, ActiveBlock? activeBlock, bool clearActive = false,
    ActiveBlock? nextBlock, int? score, int? level, int? linesCleared,
    GameStatus? status, MiniChallenge? currentChallenge, bool clearChallenge = false,
    int? highScore, int? combo, bool? challengeCorrect, List<int>? flashRows, int? blocksPlaced,
  }) => BBGameState(
    board: board ?? this.board,
    activeBlock: clearActive ? null : (activeBlock ?? this.activeBlock),
    nextBlock: nextBlock ?? this.nextBlock,
    score: score ?? this.score, level: level ?? this.level,
    linesCleared: linesCleared ?? this.linesCleared, status: status ?? this.status,
    currentChallenge: clearChallenge ? null : (currentChallenge ?? this.currentChallenge),
    highScore: highScore ?? this.highScore, combo: combo ?? this.combo,
    challengeCorrect: challengeCorrect ?? this.challengeCorrect,
    flashRows: flashRows ?? this.flashRows, blocksPlaced: blocksPlaced ?? this.blocksPlaced,
  );

  static BBGameState initial(int highScore) => BBGameState(
    board: List.generate(20, (_) => List.filled(10, null)), highScore: highScore,
  );
}