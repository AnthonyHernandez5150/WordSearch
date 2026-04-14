import '../models/difficulty.dart';
import '../models/puzzle_definition.dart';

String formatDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatBoardSummary(Difficulty difficulty, PuzzleDefinition puzzle) {
  return '${puzzle.size} x ${puzzle.size} board  |  ${puzzle.wordCount} words  |  ${difficulty.paceLabel}';
}
