import 'package:flutter/foundation.dart';

import '../data/puzzle_catalog.dart';
import '../models/board_shape.dart';
import '../models/board_style.dart';
import '../models/difficulty.dart';
import '../models/puzzle_definition.dart';
import '../models/session_snapshot.dart';

class GameController extends ChangeNotifier {
  GameController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  Difficulty _selectedDifficulty = Difficulty.explorer;
  BoardStyle _selectedBoardStyle = BoardStyle.classic;
  String _selectedShapeId = BoardShapeCatalog.initial.id;
  bool _helpEnabled = true;
  int _boardsCleared = 0;
  int _cleanStreak = 0;
  int _totalHintsUsed = 0;
  final Map<Difficulty, Duration> _bestTimes = <Difficulty, Duration>{};
  final List<VictoryRecord> _recentVictories = <VictoryRecord>[];
  final Map<Difficulty, int> _selectedTopicIndices = <Difficulty, int>{
    Difficulty.calm: 0,
    Difficulty.explorer: 0,
    Difficulty.expert: 0,
  };
  final Map<Difficulty, int> _selectedWordCounts = <Difficulty, int>{
    Difficulty.calm: 5,
    Difficulty.explorer: 8,
    Difficulty.expert: 10,
  };
  final Map<Difficulty, int> _featuredIndices = <Difficulty, int>{
    Difficulty.calm: 0,
    Difficulty.explorer: 0,
    Difficulty.expert: 0,
  };
  final Set<String> _clearedDailyKeys = <String>{};

  Difficulty get selectedDifficulty => _selectedDifficulty;
  BoardStyle get selectedBoardStyle => _selectedBoardStyle;
  BoardShapeDefinition get selectedShape =>
      BoardShapeCatalog.byId(_selectedShapeId);
  List<BoardShapeDefinition> get availableShapes => BoardShapeCatalog.all;
  bool get helpEnabled => _helpEnabled;

  SessionSnapshot get snapshot => SessionSnapshot(
    boardsCleared: _boardsCleared,
    cleanStreak: _cleanStreak,
    totalHintsUsed: _totalHintsUsed,
    bestTimes: Map<Difficulty, Duration>.unmodifiable(_bestTimes),
    recentVictories: List<VictoryRecord>.unmodifiable(_recentVictories),
  );

  void selectDifficulty(Difficulty difficulty) {
    if (_selectedDifficulty == difficulty) {
      return;
    }
    _selectedDifficulty = difficulty;
    _selectedWordCounts[difficulty] = _clampWordCount(
      difficulty,
      _selectedWordCounts[difficulty] ?? 4,
      puzzle: selectedTopicFor(difficulty),
    );
    notifyListeners();
  }

  void selectBoardStyle(BoardStyle style) {
    if (_selectedBoardStyle == style) {
      return;
    }
    _selectedBoardStyle = style;
    _selectedWordCounts[_selectedDifficulty] = _clampWordCount(
      _selectedDifficulty,
      _selectedWordCounts[_selectedDifficulty] ?? 4,
      puzzle: selectedTopicFor(_selectedDifficulty),
    );
    notifyListeners();
  }

  void selectShape(BoardShapeDefinition shape) {
    if (_selectedShapeId == shape.id) {
      return;
    }
    _selectedShapeId = shape.id;
    _selectedWordCounts[_selectedDifficulty] = _clampWordCount(
      _selectedDifficulty,
      _selectedWordCounts[_selectedDifficulty] ?? 4,
      puzzle: selectedTopicFor(_selectedDifficulty),
    );
    notifyListeners();
  }

  PuzzleDefinition featuredPuzzleFor(Difficulty difficulty) {
    return PuzzleCatalog.byIndex(difficulty, _featuredIndices[difficulty] ?? 0);
  }

  PuzzleDefinition selectedTopicFor(Difficulty difficulty) {
    return PuzzleCatalog.byIndex(
      difficulty,
      _selectedTopicIndices[difficulty] ?? 0,
    );
  }

  PuzzleDefinition dailyPuzzleFor(Difficulty difficulty) {
    return PuzzleCatalog.dailyFor(difficulty, _clock());
  }

  bool isDailyCleared(Difficulty difficulty) {
    return _clearedDailyKeys.contains(_dailyKey(difficulty, _clock()));
  }

  List<PuzzleDefinition> themesFor(Difficulty difficulty) {
    return PuzzleCatalog.allFor(difficulty);
  }

  List<int> wordCountOptionsFor(
    Difficulty difficulty, {
    PuzzleDefinition? puzzle,
  }) {
    final PuzzleDefinition source = puzzle ?? selectedTopicFor(difficulty);
    final int maximum = maxWordCountFor(difficulty, puzzle: source);
    final int minimum = minWordCountFor(difficulty, puzzle: source);
    return List<int>.generate(
      maximum - minimum + 1,
      (int index) => minimum + index,
      growable: false,
    );
  }

  int minWordCountFor(Difficulty difficulty, {PuzzleDefinition? puzzle}) {
    final PuzzleDefinition source = puzzle ?? selectedTopicFor(difficulty);
    final int maximum = maxWordCountFor(difficulty, puzzle: source);
    final int preferredMinimum = switch (difficulty) {
      Difficulty.calm => 4,
      Difficulty.explorer => 6,
      Difficulty.expert => 8,
    };
    return preferredMinimum.clamp(1, maximum);
  }

  int maxWordCountFor(Difficulty difficulty, {PuzzleDefinition? puzzle}) {
    final PuzzleDefinition source = puzzle ?? selectedTopicFor(difficulty);
    final int difficultyCap = switch (difficulty) {
      Difficulty.calm => 6,
      Difficulty.explorer => 9,
      Difficulty.expert => 12,
    };
    final int available = source.wordCount.clamp(1, difficultyCap);
    if (_selectedBoardStyle == BoardStyle.classic) {
      return available;
    }
    final int shapedSize = selectedShape.sizeFor(source.size);
    return selectedShape.recommendedMaxWords(shapedSize, available);
  }

  int wordCountFor(Difficulty difficulty, {PuzzleDefinition? puzzle}) {
    final List<int> options = wordCountOptionsFor(difficulty, puzzle: puzzle);
    final int selected = _selectedWordCounts[difficulty] ?? options.last;
    return selected.clamp(options.first, options.last);
  }

  void selectTopic(PuzzleDefinition puzzle) {
    final List<PuzzleDefinition> puzzles = PuzzleCatalog.allFor(
      _selectedDifficulty,
    );
    final int nextIndex = puzzles.indexWhere(
      (PuzzleDefinition item) => item.name == puzzle.name,
    );
    if (nextIndex == -1) {
      return;
    }

    final int nextWordCount = wordCountFor(_selectedDifficulty, puzzle: puzzle);
    if (_selectedTopicIndices[_selectedDifficulty] == nextIndex &&
        _selectedWordCounts[_selectedDifficulty] == nextWordCount) {
      return;
    }

    _selectedTopicIndices[_selectedDifficulty] = nextIndex;
    _selectedWordCounts[_selectedDifficulty] = nextWordCount;
    notifyListeners();
  }

  void selectWordCount(int wordCount) {
    final PuzzleDefinition source = selectedTopicFor(_selectedDifficulty);
    final int nextWordCount = _clampWordCount(
      _selectedDifficulty,
      wordCount,
      puzzle: source,
    );
    if (_selectedWordCounts[_selectedDifficulty] == nextWordCount) {
      return;
    }
    _selectedWordCounts[_selectedDifficulty] = nextWordCount;
    notifyListeners();
  }

  void setHelpEnabled(bool enabled) {
    if (_helpEnabled == enabled) {
      return;
    }
    _helpEnabled = enabled;
    notifyListeners();
  }

  PuzzleDefinition configuredPuzzleFor(
    Difficulty difficulty, {
    PuzzleDefinition? puzzle,
  }) {
    final PuzzleDefinition source = puzzle ?? selectedTopicFor(difficulty);
    final int selectedWordCount = wordCountFor(difficulty, puzzle: source);
    final bool shaped = _selectedBoardStyle == BoardStyle.shaped;
    final BoardShapeDefinition? shape = shaped ? selectedShape : null;
    final int size = shaped ? selectedShape.sizeFor(source.size) : source.size;
    return source.copyWith(
      size: size,
      words: source.words.take(selectedWordCount).toList(growable: false),
      shape: shape,
    );
  }

  PuzzleDefinition configuredDailyPuzzleFor(Difficulty difficulty) {
    return configuredPuzzleFor(difficulty, puzzle: dailyPuzzleFor(difficulty));
  }

  PuzzleDefinition nextPuzzleFor(
    Difficulty difficulty,
    PuzzleDefinition current,
  ) {
    return PuzzleCatalog.nextFor(difficulty, current);
  }

  VictoryOutcome recordVictory({
    required Difficulty difficulty,
    required PuzzleDefinition puzzle,
    required Duration elapsed,
    required int hintsUsed,
    required bool daily,
  }) {
    final Duration? previousBest = _bestTimes[difficulty];
    final bool personalBest = previousBest == null || elapsed < previousBest;
    if (personalBest) {
      _bestTimes[difficulty] = elapsed;
    }

    _boardsCleared++;
    _totalHintsUsed += hintsUsed;
    _cleanStreak = hintsUsed == 0 ? _cleanStreak + 1 : 0;

    final List<PuzzleDefinition> boards = PuzzleCatalog.allFor(difficulty);
    final int currentIndex = boards.indexWhere(
      (PuzzleDefinition item) => item.name == puzzle.name,
    );
    _featuredIndices[difficulty] = (currentIndex + 1) % boards.length;

    if (daily) {
      _clearedDailyKeys.add(_dailyKey(difficulty, _clock()));
    }

    final VictoryRecord record = VictoryRecord(
      puzzleName: puzzle.name,
      difficulty: difficulty,
      elapsed: elapsed,
      hintsUsed: hintsUsed,
      finishedAt: _clock(),
      daily: daily,
    );
    _recentVictories.insert(0, record);
    if (_recentVictories.length > 5) {
      _recentVictories.removeLast();
    }

    final SessionSnapshot nextSnapshot = snapshot;
    notifyListeners();
    return VictoryOutcome(
      record: record,
      personalBest: personalBest,
      snapshot: nextSnapshot,
    );
  }

  int _clampWordCount(
    Difficulty difficulty,
    int wordCount, {
    PuzzleDefinition? puzzle,
  }) {
    final List<int> options = wordCountOptionsFor(difficulty, puzzle: puzzle);
    return wordCount.clamp(options.first, options.last);
  }

  String _dailyKey(Difficulty difficulty, DateTime date) {
    return '${difficulty.name}-${date.year}-${date.month}-${date.day}';
  }
}
