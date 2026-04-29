abstract class GameEvent {}

class GameStarted extends GameEvent {}
class GamePaused extends GameEvent {}
class GameResumed extends GameEvent {}
class GameRestarted extends GameEvent {}
class GameTicked extends GameEvent {}
class BlockMoveLeft extends GameEvent {}
class BlockMoveRight extends GameEvent {}
class BlockRotate extends GameEvent {}
class BlockDrop extends GameEvent {}
class FlashRowsCleared extends GameEvent {}

class ChallengeAnswered extends GameEvent {
  final int selectedIndex;
  ChallengeAnswered(this.selectedIndex);
}