import 'difficulty.dart';
import 'generated_board.dart';
import 'puzzle_definition.dart';

class PausedPuzzleSnapshot {
  const PausedPuzzleSnapshot({
    required this.difficulty,
    required this.requestedPuzzle,
    required this.activePuzzle,
    required this.generatedBoard,
    required this.foundWords,
    required this.elapsed,
    required this.hintsUsed,
    required this.boardVersion,
    required this.helpEnabled,
    required this.daily,
  });

  final Difficulty difficulty;
  final PuzzleDefinition requestedPuzzle;
  final PuzzleDefinition activePuzzle;
  final GeneratedBoard generatedBoard;
  final Set<String> foundWords;
  final Duration elapsed;
  final int hintsUsed;
  final int boardVersion;
  final bool helpEnabled;
  final bool daily;
}
