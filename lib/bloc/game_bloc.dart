import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_model.dart';
import '../utils/challenge_generator.dart';
import 'game_event.dart';
export 'game_event.dart';
export 'game_state.dart';

class GameBloc extends Bloc<GameEvent, BBGameState> {
  static const int _cols = 10;
  static const int _rows = 20;
  static const int _challengeEvery = 5;

  Timer? _dropTimer;
  final _rng = Random();

  GameBloc(int highScore) : super(BBGameState.initial(highScore)) {
    on<GameStarted>(_onStarted);
    on<GamePaused>(_onPaused);
    on<GameResumed>(_onResumed);
    on<GameRestarted>(_onRestarted);
    on<GameTicked>(_onTicked);
    on<BlockMoveLeft>(_onMoveLeft);
    on<BlockMoveRight>(_onMoveRight);
    on<BlockRotate>(_onRotate);
    on<BlockDrop>(_onDrop);
    on<ChallengeAnswered>(_onChallengeAnswered);
    on<FlashRowsCleared>(_onFlashRowsCleared);
  }

  Duration _dropInterval(int level) =>
      Duration(milliseconds: max(120, 600 - (level - 1) * 60));

  ActiveBlock _randomBlock() {
    final type = BlockType.values[_rng.nextInt(BlockType.values.length)];
    return ActiveBlock(type: type, row: 0, col: 3);
  }

  bool _isValid(BBGameState s, ActiveBlock block) {
    for (final cell in block.absoluteCells) {
      final r = cell[0], c = cell[1];
      if (r < 0 || r >= _rows || c < 0 || c >= _cols) return false;
      if (s.board[r][c] != null) return false;
    }
    return true;
  }

  List<List<Color?>> _placeBlock(BBGameState s, ActiveBlock block) {
    final board = s.board.map((row) => List<Color?>.from(row)).toList();
    for (final cell in block.absoluteCells) board[cell[0]][cell[1]] = block.color;
    return board;
  }

  ({List<List<Color?>> board, List<int> cleared}) _clearLines(List<List<Color?>> board) {
    final cleared = <int>[];
    final newBoard = <List<Color?>>[];
    for (int r = 0; r < _rows; r++) {
      if (board[r].every((c) => c != null)) cleared.add(r);
      else newBoard.add(List<Color?>.from(board[r]));
    }
    while (newBoard.length < _rows) newBoard.insert(0, List.filled(_cols, null));
    return (board: newBoard, cleared: cleared);
  }

  int _lineScore(int lines, int level, int combo) {
    const base = [0, 100, 300, 500, 800];
    return (base[min(lines, 4)] * level) + (combo > 1 ? combo * 20 : 0);
  }

  void _startDropTimer() {
    _dropTimer?.cancel();
    _dropTimer = Timer.periodic(_dropInterval(state.level), (_) {
      if (state.status == GameStatus.playing) add(GameTicked());
    });
  }

  void _stopDropTimer() => _dropTimer?.cancel();

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brainblocks_hs', score);
  }

  void _onStarted(GameStarted event, Emitter<BBGameState> emit) {
    emit(state.copyWith(
      board: List.generate(_rows, (_) => List.filled(_cols, null)),
      activeBlock: _randomBlock(), nextBlock: _randomBlock(),
      score: 0, level: 1, linesCleared: 0, combo: 0, blocksPlaced: 0,
      status: GameStatus.playing, flashRows: [], clearChallenge: true,
    ));
    _startDropTimer();
  }

  void _onPaused(GamePaused event, Emitter<BBGameState> emit) {
    if (state.status != GameStatus.playing) return;
    _stopDropTimer();
    emit(state.copyWith(status: GameStatus.paused));
  }

  void _onResumed(GameResumed event, Emitter<BBGameState> emit) {
    if (state.status != GameStatus.paused) return;
    emit(state.copyWith(status: GameStatus.playing));
    _startDropTimer();
  }

  void _onRestarted(GameRestarted event, Emitter<BBGameState> emit) {
    _stopDropTimer();
    emit(state.copyWith(
      board: List.generate(_rows, (_) => List.filled(_cols, null)),
      activeBlock: _randomBlock(), nextBlock: _randomBlock(),
      score: 0, level: 1, linesCleared: 0, combo: 0, blocksPlaced: 0,
      status: GameStatus.playing, flashRows: [], clearChallenge: true,
    ));
    _startDropTimer();
  }

  void _onTicked(GameTicked event, Emitter<BBGameState> emit) {
    final block = state.activeBlock;
    if (block == null || state.status != GameStatus.playing) return;
    final moved = block.copyWith(row: block.row + 1);
    if (_isValid(state, moved)) emit(state.copyWith(activeBlock: moved));
    else _lockBlock(emit);
  }

  void _onMoveLeft(BlockMoveLeft event, Emitter<BBGameState> emit) {
    final block = state.activeBlock;
    if (block == null || state.status != GameStatus.playing) return;
    final moved = block.copyWith(col: block.col - 1);
    if (_isValid(state, moved)) emit(state.copyWith(activeBlock: moved));
  }

  void _onMoveRight(BlockMoveRight event, Emitter<BBGameState> emit) {
    final block = state.activeBlock;
    if (block == null || state.status != GameStatus.playing) return;
    final moved = block.copyWith(col: block.col + 1);
    if (_isValid(state, moved)) emit(state.copyWith(activeBlock: moved));
  }

  void _onRotate(BlockRotate event, Emitter<BBGameState> emit) {
    final block = state.activeBlock;
    if (block == null || state.status != GameStatus.playing) return;
    final rotated = block.copyWith(rotation: block.rotation + 1);
    if (_isValid(state, rotated)) {
      emit(state.copyWith(activeBlock: rotated));
    } else {
      for (final shift in [-1, 1, -2, 2]) {
        final kicked = rotated.copyWith(col: rotated.col + shift);
        if (_isValid(state, kicked)) { emit(state.copyWith(activeBlock: kicked)); return; }
      }
    }
  }

  void _onDrop(BlockDrop event, Emitter<BBGameState> emit) {
    var block = state.activeBlock;
    if (block == null || state.status != GameStatus.playing) return;
    while (_isValid(state, block!.copyWith(row: block.row + 1))) {
      block = block.copyWith(row: block.row + 1);
    }
    emit(state.copyWith(activeBlock: block));
    _lockBlock(emit);
  }

  void _lockBlock(Emitter<BBGameState> emit) {
    final block = state.activeBlock!;
    final newBoard = _placeBlock(state, block);
    final (:board, :cleared) = _clearLines(newBoard);
    final blocksPlaced = state.blocksPlaced + 1;

    int newScore = state.score, newCombo = state.combo;
    int newLines = state.linesCleared, newLevel = state.level;
    List<int> flashRows = [];

    if (cleared.isNotEmpty) {
      newCombo++;
      newScore += _lineScore(cleared.length, state.level, newCombo);
      newLines += cleared.length;
      newLevel = (newLines ~/ 10) + 1;
      flashRows = cleared;
    } else {
      newCombo = 0;
    }

    final nextBlock = state.nextBlock ?? _randomBlock();
    final newNext = _randomBlock();
    final gameOver = !_isValid(state.copyWith(board: board), nextBlock);

    if (gameOver) {
      _stopDropTimer();
      final hs = max(newScore, state.highScore);
      _saveHighScore(hs);
      emit(state.copyWith(
        board: board, clearActive: true, score: newScore,
        linesCleared: newLines, level: newLevel, combo: newCombo,
        highScore: hs, flashRows: flashRows, blocksPlaced: blocksPlaced,
        status: GameStatus.gameOver,
      ));
      return;
    }

    final triggerChallenge = cleared.isNotEmpty && blocksPlaced % _challengeEvery == 0;

    if (triggerChallenge) {
      _stopDropTimer();
      final challenge = ChallengeGenerator.generate(newLevel);
      emit(state.copyWith(
        board: board, activeBlock: nextBlock, nextBlock: newNext,
        score: newScore, linesCleared: newLines, level: newLevel, combo: newCombo,
        flashRows: flashRows, blocksPlaced: blocksPlaced,
        currentChallenge: challenge, status: GameStatus.miniChallenge,
      ));
    } else {
      emit(state.copyWith(
        board: board, activeBlock: nextBlock, nextBlock: newNext,
        score: newScore, linesCleared: newLines, level: newLevel,
        combo: newCombo, flashRows: flashRows, blocksPlaced: blocksPlaced,
      ));
    }
  }

  void _onChallengeAnswered(ChallengeAnswered event, Emitter<BBGameState> emit) {
    final challenge = state.currentChallenge;
    if (challenge == null) return;
    final correct = event.selectedIndex == challenge.correctIndex;
    final newScore = state.score + (correct ? challenge.bonusPoints : 0);
    final hs = max(newScore, state.highScore);
    emit(state.copyWith(
      score: newScore, highScore: hs, challengeCorrect: correct,
      status: GameStatus.playing, clearChallenge: true,
    ));
    _startDropTimer();
  }

  void _onFlashRowsCleared(FlashRowsCleared event, Emitter<BBGameState> emit) {
    emit(state.copyWith(flashRows: []));
  }

  @override
  Future<void> close() { _stopDropTimer(); return super.close(); }
}