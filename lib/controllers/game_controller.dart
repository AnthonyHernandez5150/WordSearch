import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/puzzle_catalog.dart';
import '../models/board_shape.dart';
import '../models/board_style.dart';
import '../models/difficulty.dart';
import '../models/paused_puzzle_snapshot.dart';
import '../models/puzzle_definition.dart';
import '../models/session_snapshot.dart';
import '../services/game_feedback.dart';
import '../services/progress_store.dart';

class GameController extends ChangeNotifier {
  GameController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    GameFeedback.setSoundEnabled(_soundEnabled);
    unawaited(_loadProgress());
  }

  final DateTime Function() _clock;
  Difficulty _selectedDifficulty = Difficulty.explorer;
  BoardStyle _selectedBoardStyle = BoardStyle.classic;
  String _selectedShapeId = BoardShapeCatalog.initial.id;
  bool _helpEnabled = true;
  bool _soundEnabled = true;
  bool _disposed = false;
  int _boardsCleared = 0;
  int _cleanStreak = 0;
  int _currentDailyStreak = 0;
  int _bestDailyStreak = 0;
  int? _lastDailyCompletionDay;
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
  PausedPuzzleSnapshot? _pausedPuzzle;

  Difficulty get selectedDifficulty => _selectedDifficulty;
  Difficulty get dailyDifficulty => Difficulty.explorer;
  BoardStyle get selectedBoardStyle => _selectedBoardStyle;
  BoardShapeDefinition get selectedShape =>
      BoardShapeCatalog.byId(_selectedShapeId);
  List<BoardShapeDefinition> get availableShapes => BoardShapeCatalog.all;
  bool get helpEnabled => _helpEnabled;
  bool get soundEnabled => _soundEnabled;
  PausedPuzzleSnapshot? get pausedPuzzle => _pausedPuzzle;

  SessionSnapshot get snapshot => SessionSnapshot(
    boardsCleared: _boardsCleared,
    cleanStreak: _cleanStreak,
    currentDailyStreak: _visibleDailyStreak,
    bestDailyStreak: _bestDailyStreak,
    totalHintsUsed: _totalHintsUsed,
    bestTimes: Map<Difficulty, Duration>.unmodifiable(_bestTimes),
    recentVictories: List<VictoryRecord>.unmodifiable(_recentVictories),
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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
    unawaited(_saveProgress());
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
    unawaited(_saveProgress());
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
    unawaited(_saveProgress());
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
    return PuzzleCatalog.featuredDaily(_clock());
  }

  PuzzleDefinition configuredDailyPuzzle() {
    final PuzzleDefinition source = dailyPuzzleFor(dailyDifficulty);
    final int dailyWordCount = source.wordCount < 8 ? source.wordCount : 8;
    return source.copyWith(
      size: source.size,
      words: source.words.take(dailyWordCount).toList(growable: false),
      shape: null,
    );
  }

  bool get isDailyClearedToday {
    return _clearedDailyKeys.contains(_dailyKey(_clock()));
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
    unawaited(_saveProgress());
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
    unawaited(_saveProgress());
  }

  void setHelpEnabled(bool enabled) {
    if (_helpEnabled == enabled) {
      return;
    }
    _helpEnabled = enabled;
    notifyListeners();
    unawaited(_saveProgress());
  }

  void setSoundEnabled(bool enabled) {
    if (_soundEnabled == enabled) {
      return;
    }
    _soundEnabled = enabled;
    GameFeedback.setSoundEnabled(enabled);
    notifyListeners();
    unawaited(_saveProgress());
  }

  void savePausedPuzzle(PausedPuzzleSnapshot snapshot) {
    _pausedPuzzle = snapshot;
    notifyListeners();
  }

  void clearPausedPuzzle() {
    if (_pausedPuzzle == null) {
      return;
    }
    _pausedPuzzle = null;
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
    final DateTime finishedAt = _clock();
    final Duration? previousBest = _bestTimes[difficulty];
    final bool personalBest = previousBest == null || elapsed < previousBest;
    if (personalBest) {
      _bestTimes[difficulty] = elapsed;
    }

    final _DailyStreakUpdate dailyStreakUpdate = daily
        ? _recordDailyCompletion(finishedAt)
        : const _DailyStreakUpdate(advanced: false, newBest: false);

    _boardsCleared++;
    _totalHintsUsed += hintsUsed;
    _cleanStreak = hintsUsed == 0 ? _cleanStreak + 1 : 0;

    if (!daily) {
      final List<PuzzleDefinition> boards = PuzzleCatalog.allFor(difficulty);
      final int currentIndex = boards.indexWhere(
        (PuzzleDefinition item) => item.name == puzzle.name,
      );
      _featuredIndices[difficulty] = (currentIndex + 1) % boards.length;
    }

    if (daily) {
      _clearedDailyKeys.add(_dailyKey(finishedAt));
    }

    final VictoryRecord record = VictoryRecord(
      puzzleName: puzzle.name,
      difficulty: difficulty,
      elapsed: elapsed,
      hintsUsed: hintsUsed,
      finishedAt: finishedAt,
      daily: daily,
    );
    _recentVictories.insert(0, record);
    if (_recentVictories.length > 5) {
      _recentVictories.removeLast();
    }

    final SessionSnapshot nextSnapshot = snapshot;
    notifyListeners();
    unawaited(_saveProgress());
    return VictoryOutcome(
      record: record,
      personalBest: personalBest,
      dailyStreakAdvanced: dailyStreakUpdate.advanced,
      bestDailyStreakSet: dailyStreakUpdate.newBest,
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

  int get _visibleDailyStreak {
    final int? lastDay = _lastDailyCompletionDay;
    if (lastDay == null || _currentDailyStreak <= 0) {
      return 0;
    }
    final int today = _dayNumber(_clock());
    if (lastDay == today || lastDay == today - 1) {
      return _currentDailyStreak;
    }
    if (lastDay > today) {
      return _currentDailyStreak;
    }
    return 0;
  }

  _DailyStreakUpdate _recordDailyCompletion(DateTime completedAt) {
    final int today = _dayNumber(completedAt);
    final int? previousDay = _lastDailyCompletionDay;
    if (previousDay == today) {
      return const _DailyStreakUpdate(advanced: false, newBest: false);
    }

    if (previousDay == null || today > previousDay + 1 || today < previousDay) {
      _currentDailyStreak = 1;
    } else {
      _currentDailyStreak++;
    }
    _lastDailyCompletionDay = today;

    final bool newBest = _currentDailyStreak > _bestDailyStreak;
    if (newBest) {
      _bestDailyStreak = _currentDailyStreak;
    }
    return _DailyStreakUpdate(advanced: true, newBest: newBest);
  }

  Future<void> _loadProgress() async {
    final String? payload = await ProgressStore.load();
    if (payload == null || payload.isEmpty || _disposed) {
      return;
    }

    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) {
        return;
      }
      _applyProgress(decoded);
      if (!_disposed) {
        notifyListeners();
      }
    } on FormatException catch (error) {
      debugPrint('Unable to decode saved progress: $error');
    } on Object catch (error) {
      debugPrint('Unable to load saved progress: $error');
    }
  }

  Future<void> _saveProgress() async {
    final String payload = jsonEncode(_progressJson());
    await ProgressStore.save(payload);
  }

  void _applyProgress(Map<String, Object?> data) {
    _selectedDifficulty =
        _difficultyFromName(_readString(data['selectedDifficulty'])) ??
        _selectedDifficulty;
    _selectedBoardStyle =
        _boardStyleFromName(_readString(data['selectedBoardStyle'])) ??
        _selectedBoardStyle;
    final String? shapeId = _readString(data['selectedShapeId']);
    if (shapeId != null &&
        BoardShapeCatalog.all.any(
          (BoardShapeDefinition shape) => shape.id == shapeId,
        )) {
      _selectedShapeId = shapeId;
    }
    _helpEnabled = _readBool(data['helpEnabled'], fallback: _helpEnabled);
    _soundEnabled = _readBool(data['soundEnabled'], fallback: _soundEnabled);
    GameFeedback.setSoundEnabled(_soundEnabled);
    _boardsCleared = _readInt(data['boardsCleared']);
    _cleanStreak = _readInt(data['cleanStreak']);
    _currentDailyStreak = _readInt(data['currentDailyStreak']);
    _bestDailyStreak = _readInt(data['bestDailyStreak']);
    final int lastDailyCompletionDay = _readInt(
      data['lastDailyCompletionDay'],
      fallback: -1,
    );
    _lastDailyCompletionDay = lastDailyCompletionDay >= 0
        ? lastDailyCompletionDay
        : null;
    _totalHintsUsed = _readInt(data['totalHintsUsed']);

    _readDifficultyIntMap(
      data['selectedTopicIndices'],
      target: _selectedTopicIndices,
      clampToPuzzleCount: true,
    );
    _readDifficultyIntMap(
      data['selectedWordCounts'],
      target: _selectedWordCounts,
      clampToPuzzleCount: false,
    );
    _readDifficultyIntMap(
      data['featuredIndices'],
      target: _featuredIndices,
      clampToPuzzleCount: true,
    );

    _bestTimes
      ..clear()
      ..addAll(_readBestTimes(data['bestTimes']));

    _clearedDailyKeys
      ..clear()
      ..addAll(_readStringList(data['clearedDailyKeys']));

    _recentVictories
      ..clear()
      ..addAll(_readVictoryRecords(data['recentVictories']));
  }

  Map<String, Object?> _progressJson() {
    final List<String> clearedDailyKeys = _clearedDailyKeys.toList()..sort();
    return <String, Object?>{
      'version': 1,
      'selectedDifficulty': _selectedDifficulty.name,
      'selectedBoardStyle': _selectedBoardStyle.name,
      'selectedShapeId': _selectedShapeId,
      'helpEnabled': _helpEnabled,
      'soundEnabled': _soundEnabled,
      'boardsCleared': _boardsCleared,
      'cleanStreak': _cleanStreak,
      'currentDailyStreak': _currentDailyStreak,
      'bestDailyStreak': _bestDailyStreak,
      'lastDailyCompletionDay': _lastDailyCompletionDay,
      'totalHintsUsed': _totalHintsUsed,
      'selectedTopicIndices': _difficultyIntMapJson(_selectedTopicIndices),
      'selectedWordCounts': _difficultyIntMapJson(_selectedWordCounts),
      'featuredIndices': _difficultyIntMapJson(_featuredIndices),
      'bestTimes': <String, int>{
        for (final MapEntry<Difficulty, Duration> entry in _bestTimes.entries)
          entry.key.name: entry.value.inMilliseconds,
      },
      'clearedDailyKeys': clearedDailyKeys,
      'recentVictories': _recentVictories.map(_victoryJson).toList(),
    };
  }

  Map<String, int> _difficultyIntMapJson(Map<Difficulty, int> source) {
    return <String, int>{
      for (final Difficulty difficulty in Difficulty.values)
        difficulty.name: source[difficulty] ?? 0,
    };
  }

  Map<String, Object?> _victoryJson(VictoryRecord record) {
    return <String, Object?>{
      'puzzleName': record.puzzleName,
      'difficulty': record.difficulty.name,
      'elapsedMs': record.elapsed.inMilliseconds,
      'hintsUsed': record.hintsUsed,
      'finishedAt': record.finishedAt.toIso8601String(),
      'daily': record.daily,
    };
  }

  void _readDifficultyIntMap(
    Object? value, {
    required Map<Difficulty, int> target,
    required bool clampToPuzzleCount,
  }) {
    if (value is! Map) {
      return;
    }
    for (final Difficulty difficulty in Difficulty.values) {
      final int fallback = target[difficulty] ?? 0;
      int next = _readInt(value[difficulty.name], fallback: fallback);
      if (clampToPuzzleCount) {
        final int maxIndex = PuzzleCatalog.allFor(difficulty).length - 1;
        next = next.clamp(0, maxIndex).toInt();
      }
      target[difficulty] = next;
    }
  }

  Map<Difficulty, Duration> _readBestTimes(Object? value) {
    if (value is! Map) {
      return <Difficulty, Duration>{};
    }
    final Map<Difficulty, Duration> result = <Difficulty, Duration>{};
    for (final Difficulty difficulty in Difficulty.values) {
      final int milliseconds = _readInt(value[difficulty.name]);
      if (milliseconds > 0) {
        result[difficulty] = Duration(milliseconds: milliseconds);
      }
    }
    return result;
  }

  List<VictoryRecord> _readVictoryRecords(Object? value) {
    if (value is! List) {
      return <VictoryRecord>[];
    }
    final List<VictoryRecord> records = <VictoryRecord>[];
    for (final Object? item in value) {
      final VictoryRecord? record = _readVictoryRecord(item);
      if (record != null) {
        records.add(record);
      }
      if (records.length == 5) {
        break;
      }
    }
    return records;
  }

  VictoryRecord? _readVictoryRecord(Object? value) {
    if (value is! Map) {
      return null;
    }
    final Difficulty? difficulty = _difficultyFromName(
      _readString(value['difficulty']),
    );
    final String? puzzleName = _readString(value['puzzleName']);
    final String? finishedAtText = _readString(value['finishedAt']);
    final DateTime? finishedAt = finishedAtText == null
        ? null
        : DateTime.tryParse(finishedAtText);
    if (difficulty == null || puzzleName == null || finishedAt == null) {
      return null;
    }
    return VictoryRecord(
      puzzleName: puzzleName,
      difficulty: difficulty,
      elapsed: Duration(milliseconds: _readInt(value['elapsedMs'])),
      hintsUsed: _readInt(value['hintsUsed']),
      finishedAt: finishedAt,
      daily: _readBool(value['daily']),
    );
  }

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  Difficulty? _difficultyFromName(String? name) {
    for (final Difficulty difficulty in Difficulty.values) {
      if (difficulty.name == name) {
        return difficulty;
      }
    }
    return null;
  }

  BoardStyle? _boardStyleFromName(String? name) {
    for (final BoardStyle style in BoardStyle.values) {
      if (style.name == name) {
        return style;
      }
    }
    return null;
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return bool.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  String? _readString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  int _dayNumber(DateTime date) {
    return DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  String _dailyKey(DateTime date) {
    return 'daily-${date.year}-${date.month}-${date.day}';
  }
}

class _DailyStreakUpdate {
  const _DailyStreakUpdate({required this.advanced, required this.newBest});

  final bool advanced;
  final bool newBest;
}
