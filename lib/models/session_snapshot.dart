import 'difficulty.dart';

class VictoryRecord {
  const VictoryRecord({
    required this.puzzleName,
    required this.difficulty,
    required this.elapsed,
    required this.hintsUsed,
    required this.finishedAt,
    required this.daily,
  });

  final String puzzleName;
  final Difficulty difficulty;
  final Duration elapsed;
  final int hintsUsed;
  final DateTime finishedAt;
  final bool daily;
}

class SessionSnapshot {
  const SessionSnapshot({
    required this.boardsCleared,
    required this.cleanStreak,
    required this.totalHintsUsed,
    required this.bestTimes,
    required this.recentVictories,
  });

  final int boardsCleared;
  final int cleanStreak;
  final int totalHintsUsed;
  final Map<Difficulty, Duration> bestTimes;
  final List<VictoryRecord> recentVictories;

  Duration? bestTimeFor(Difficulty difficulty) => bestTimes[difficulty];
}

class VictoryOutcome {
  const VictoryOutcome({
    required this.record,
    required this.personalBest,
    required this.snapshot,
  });

  final VictoryRecord record;
  final bool personalBest;
  final SessionSnapshot snapshot;
}
