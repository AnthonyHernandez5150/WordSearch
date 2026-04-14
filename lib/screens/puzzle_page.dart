import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/formatters.dart';
import '../controllers/game_controller.dart';
import '../models/cell_pos.dart';
import '../models/difficulty.dart';
import '../models/generated_board.dart';
import '../models/puzzle_definition.dart';
import '../models/session_snapshot.dart';
import '../services/board_generator.dart';
import '../services/game_feedback.dart';
import '../widgets/board_lattice_painter.dart';
import '../widgets/celebration_burst.dart';
import '../widgets/selection_path_painter.dart';
import '../widgets/status_chip.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.controller,
    required this.difficulty,
    required this.puzzle,
    required this.helpEnabled,
    required this.daily,
  });

  final GameController controller;
  final Difficulty difficulty;
  final PuzzleDefinition puzzle;
  final bool helpEnabled;
  final bool daily;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late GeneratedBoard _generated;
  late PuzzleDefinition _activePuzzle;
  final Set<String> _foundWords = <String>{};
  final Stopwatch _stopwatch = Stopwatch();
  final List<CellPos> _selection = <CellPos>[];
  CellPos? _dragAnchor;
  CellPos? _lockedDirection;
  Timer? _ticker;
  Timer? _messageTimer;
  Timer? _spotlightTimer;
  Timer? _rewardTimer;
  int _boardVersion = 0;
  int _hintsUsed = 0;
  String? _hintMessage;
  bool _showingWinSheet = false;
  bool _isProcessingMatch = false;
  bool _isShowingHint = false;
  bool _boardCompleted = false;
  bool _finalPulse = false;
  bool _advanceAfterVictorySheet = false;
  bool _homeAfterVictorySheet = false;
  Duration? _completedElapsed;
  String? _rewardText;
  int _rewardToken = 0;
  Set<CellPos> _spotlightCells = <CellPos>{};
  List<CellPos> _burstPath = <CellPos>[];

  @override
  void initState() {
    super.initState();
    _buildFreshBoard();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _messageTimer?.cancel();
    _spotlightTimer?.cancel();
    _rewardTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _buildFreshBoard() {
    final List<PuzzleDefinition> candidates = _generationCandidates(
      widget.puzzle,
    );
    for (final PuzzleDefinition candidate in candidates) {
      try {
        final GeneratedBoard generated = BoardGenerator.generate(
          candidate,
          version: _boardVersion,
          difficulty: widget.difficulty,
        );
        if (_isValidGeneratedBoard(generated, candidate)) {
          _generated = generated;
          _activePuzzle = candidate;
          return;
        }
      } on StateError {
        continue;
      }
    }

    final int fallbackWordCount = _minimumPlayableWordCount(widget.puzzle);
    final int fallbackSize = switch (widget.difficulty) {
      Difficulty.calm => max(8, widget.puzzle.size),
      Difficulty.explorer => max(10, widget.puzzle.size),
      Difficulty.expert => max(13, widget.puzzle.size),
    };
    final PuzzleDefinition emergencyFallback = widget.puzzle.copyWith(
      shape: null,
      size: fallbackSize,
      words: widget.puzzle.words
          .take(fallbackWordCount)
          .toList(growable: false),
    );
    final GeneratedBoard generated = BoardGenerator.generate(
      emergencyFallback,
      version: _boardVersion,
      difficulty: widget.difficulty,
    );
    if (!_isValidGeneratedBoard(generated, emergencyFallback)) {
      throw StateError('Generated fallback board is invalid.');
    }
    _generated = generated;
    _activePuzzle = emergencyFallback;
  }

  bool _isValidGeneratedBoard(
    GeneratedBoard generated,
    PuzzleDefinition puzzle,
  ) {
    if (generated.cells.length != puzzle.size ||
        generated.activeCells.isEmpty) {
      return false;
    }

    for (final List<String> row in generated.cells) {
      if (row.length != puzzle.size) {
        return false;
      }
    }

    for (final CellPos cell in generated.activeCells) {
      if (cell.row < 0 ||
          cell.row >= puzzle.size ||
          cell.col < 0 ||
          cell.col >= puzzle.size ||
          generated.cells[cell.row][cell.col].isEmpty) {
        return false;
      }
    }

    for (final String word in puzzle.words) {
      final List<CellPos>? path = generated.paths[word];
      if (path == null || path.length != word.length) {
        return false;
      }
      for (int i = 0; i < word.length; i++) {
        final CellPos cell = path[i];
        if (!generated.activeCells.contains(cell) ||
            cell.row < 0 ||
            cell.row >= puzzle.size ||
            cell.col < 0 ||
            cell.col >= puzzle.size ||
            generated.cells[cell.row][cell.col] != word[i]) {
          return false;
        }
      }
    }

    return true;
  }

  List<PuzzleDefinition> _generationCandidates(PuzzleDefinition puzzle) {
    final List<PuzzleDefinition> candidates = <PuzzleDefinition>[];
    final List<String> words = puzzle.words;
    final int minimum = _minimumPlayableWordCount(puzzle);

    for (int count = words.length; count >= minimum; count--) {
      candidates.add(
        puzzle.copyWith(words: words.take(count).toList(growable: false)),
      );
    }

    if (puzzle.shape != null) {
      for (int count = min(words.length, 7); count >= minimum; count--) {
        candidates.add(
          puzzle.copyWith(
            shape: null,
            size: max(10, puzzle.size),
            words: words.take(count).toList(growable: false),
          ),
        );
      }
    }

    return candidates;
  }

  int _minimumPlayableWordCount(PuzzleDefinition puzzle) {
    final int preferredMinimum = switch (widget.difficulty) {
      Difficulty.calm => 4,
      Difficulty.explorer => 6,
      Difficulty.expert => 8,
    };
    return min(preferredMinimum, puzzle.words.length);
  }

  void _startTimer() {
    _stopwatch
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  void _restartBoard() {
    GameFeedback.tap();
    setState(() {
      _boardVersion++;
      _foundWords.clear();
      _selection.clear();
      _dragAnchor = null;
      _lockedDirection = null;
      _hintsUsed = 0;
      _hintMessage = null;
      _showingWinSheet = false;
      _isProcessingMatch = false;
      _isShowingHint = false;
      _boardCompleted = false;
      _finalPulse = false;
      _advanceAfterVictorySheet = false;
      _homeAfterVictorySheet = false;
      _completedElapsed = null;
      _rewardText = null;
      _burstPath = <CellPos>[];
      _spotlightCells = <CellPos>{};
      _buildFreshBoard();
      _startTimer();
    });
    _announce('Fresh board ready');
  }

  String _selectionText(List<CellPos> cells) {
    return cells
        .map((CellPos cell) => _generated.cells[cell.row][cell.col])
        .join();
  }

  PuzzleDefinition get _puzzle => _activePuzzle;

  bool _samePath(List<CellPos> a, List<CellPos> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  List<CellPos> _reversedPath(List<CellPos> path) {
    return path.reversed.toList(growable: false);
  }

  CellPos? _stepForPath(List<CellPos> path) {
    if (path.length < 2) {
      return null;
    }
    final CellPos first = path.first;
    final CellPos second = path[1];
    return CellPos(
      (second.row - first.row).sign,
      (second.col - first.col).sign,
    );
  }

  int? _matchQuality(List<CellPos> selection, List<CellPos> path) {
    if (_samePath(selection, path) ||
        _samePath(selection, _reversedPath(path))) {
      return 0;
    }

    return null;
  }

  bool _isFoundCell(CellPos cell) {
    return _foundWords.any(
      (String word) => _generated.paths[word]!.contains(cell),
    );
  }

  bool _isActiveCell(CellPos cell) {
    return _generated.activeCells.contains(cell);
  }

  bool _isSpotlightCell(CellPos cell) {
    return _spotlightCells.contains(cell);
  }

  double _boardGap() => 1;

  double _tileSizeForBoard(double boardSize) {
    final int size = _generated.cells.length;
    final double gap = _boardGap();
    return (boardSize - gap * (size - 1)) / size;
  }

  Offset _cellCenter(CellPos cell, double tile, double gap) {
    return Offset(
      cell.col * (tile + gap) + tile / 2,
      cell.row * (tile + gap) + tile / 2,
    );
  }

  int _axisSign(double value) {
    if (value > 0) {
      return 1;
    }
    return -1;
  }

  CellPos? _cellFromLocal(Offset localPosition, double boardSize) {
    final int size = _generated.cells.length;
    final double gap = _boardGap();
    const double slop = 32;
    final double tile = _tileSizeForBoard(boardSize);
    final double step = tile + gap;
    if (localPosition.dx < -slop ||
        localPosition.dy < -slop ||
        localPosition.dx > boardSize + slop ||
        localPosition.dy > boardSize + slop) {
      return null;
    }
    final double clampedDx = localPosition.dx.clamp(0, boardSize);
    final double clampedDy = localPosition.dy.clamp(0, boardSize);
    final int col = ((clampedDx - tile / 2) / step).round().clamp(0, size - 1);
    final int row = ((clampedDy - tile / 2) / step).round().clamp(0, size - 1);
    final CellPos cell = CellPos(row, col);
    return _isActiveCell(cell) ? cell : null;
  }

  CellPos? _snapDirectionFromOffset(Offset delta, double step) {
    final double absDx = delta.dx.abs();
    final double absDy = delta.dy.abs();
    final int rowSign = _axisSign(delta.dy);
    final int colSign = _axisSign(delta.dx);

    if (max(absDx, absDy) < step * 0.22) {
      return null;
    }

    if (absDx <= step * 0.12) {
      return CellPos(rowSign, 0);
    }
    if (absDy <= step * 0.12) {
      return CellPos(0, colSign);
    }

    final double diagonalRatio = min(absDy, absDx) / max(absDy, absDx);
    if (diagonalRatio >= 0.34) {
      return CellPos(rowSign, colSign);
    }

    if (absDy > absDx) {
      return CellPos(rowSign, 0);
    }
    return CellPos(0, colSign);
  }

  int _maxStepsFrom(CellPos start, CellPos direction) {
    int steps = 0;
    int row = start.row;
    int col = start.col;
    final int size = _generated.cells.length;

    while (true) {
      final int nextRow = row + direction.row;
      final int nextCol = col + direction.col;
      if (nextRow < 0 ||
          nextRow >= size ||
          nextCol < 0 ||
          nextCol >= size ||
          !_isActiveCell(CellPos(nextRow, nextCol))) {
        return steps;
      }
      steps++;
      row = nextRow;
      col = nextCol;
    }
  }

  List<CellPos> _lineToPointer(
    CellPos start,
    Offset localPosition,
    double boardSize, {
    CellPos? forcedDirection,
  }) {
    final double gap = _boardGap();
    final double tile = _tileSizeForBoard(boardSize);
    final double step = tile + gap;
    final Offset startCenter = _cellCenter(start, tile, gap);
    final Offset delta = localPosition - startCenter;
    final CellPos? direction =
        forcedDirection ?? _snapDirectionFromOffset(delta, step);
    if (direction == null) {
      return <CellPos>[start];
    }

    final Offset axis = Offset(direction.col * step, direction.row * step);
    final double denominator = axis.dx * axis.dx + axis.dy * axis.dy;
    final double projectedSteps =
        ((delta.dx * axis.dx) + (delta.dy * axis.dy)) / denominator;
    int distance = (projectedSteps + 0.68).floor();
    if (distance < 0) {
      distance = 0;
    }
    final int maxDistance = _maxStepsFrom(start, direction);
    if (distance > maxDistance) {
      distance = maxDistance;
    }

    return List<CellPos>.generate(
      distance + 1,
      (int index) => CellPos(
        start.row + direction.row * index,
        start.col + direction.col * index,
      ),
      growable: false,
    );
  }

  double _projectedStepsForPointer(
    CellPos start,
    Offset localPosition,
    double boardSize,
    CellPos direction,
  ) {
    final double gap = _boardGap();
    final double tile = _tileSizeForBoard(boardSize);
    final double step = tile + gap;
    final Offset startCenter = _cellCenter(start, tile, gap);
    final Offset delta = localPosition - startCenter;
    final Offset axis = Offset(direction.col * step, direction.row * step);
    final double denominator = axis.dx * axis.dx + axis.dy * axis.dy;
    return ((delta.dx * axis.dx) + (delta.dy * axis.dy)) / denominator;
  }

  List<CellPos>? _magnetizedWordPath(
    CellPos start,
    Offset localPosition,
    double boardSize,
    CellPos direction,
  ) {
    final double projectedSteps = _projectedStepsForPointer(
      start,
      localPosition,
      boardSize,
      direction,
    );
    if (projectedSteps < 0.55) {
      return null;
    }

    double bestDistance = double.infinity;
    List<CellPos>? bestPath;

    for (final MapEntry<String, List<CellPos>> entry
        in _generated.paths.entries) {
      if (_foundWords.contains(entry.key)) {
        continue;
      }

      final List<List<CellPos>> orientations = <List<CellPos>>[
        entry.value,
        _reversedPath(entry.value),
      ];

      for (final List<CellPos> orientedPath in orientations) {
        if (orientedPath.first != start) {
          continue;
        }
        if (_stepForPath(orientedPath) != direction) {
          continue;
        }

        final double targetSteps = (orientedPath.length - 1).toDouble();
        final double distance = (projectedSteps - targetSteps).abs();
        final double tolerance = targetSteps >= 8
            ? 1.05
            : targetSteps >= 5
            ? 0.9
            : 0.72;
        if (distance <= tolerance && distance < bestDistance) {
          bestDistance = distance;
          bestPath = orientedPath;
        }
      }
    }

    return bestPath;
  }

  void _beginDrag(Offset localPosition, double boardSize) {
    if (_isProcessingMatch || _boardCompleted) {
      return;
    }
    final CellPos? cell = _cellFromLocal(localPosition, boardSize);
    if (cell == null) {
      return;
    }
    GameFeedback.tap();
    setState(() {
      _dragAnchor = cell;
      _lockedDirection = null;
      _selection
        ..clear()
        ..add(cell);
      _hintMessage = null;
    });
  }

  void _updateDrag(Offset localPosition, double boardSize) {
    if (_isProcessingMatch || _boardCompleted) {
      return;
    }
    final CellPos? anchor = _dragAnchor;
    if (anchor == null) {
      return;
    }
    final double tile = _tileSizeForBoard(boardSize);
    final double step = tile + _boardGap();
    final Offset anchorCenter = _cellCenter(anchor, tile, _boardGap());
    final Offset rawDelta = localPosition - anchorCenter;
    final CellPos? snappedDirection =
        _lockedDirection ?? _snapDirectionFromOffset(rawDelta, step);
    final List<CellPos> nextSelection = snappedDirection == null
        ? <CellPos>[anchor]
        : (_magnetizedWordPath(
                anchor,
                localPosition,
                boardSize,
                snappedDirection,
              ) ??
              _lineToPointer(
                anchor,
                localPosition,
                boardSize,
                forcedDirection: snappedDirection,
              ));
    if (_samePath(nextSelection, _selection)) {
      return;
    }
    setState(() {
      if (_lockedDirection == null &&
          snappedDirection != null &&
          nextSelection.length > 1) {
        _lockedDirection = snappedDirection;
      }
      _selection
        ..clear()
        ..addAll(nextSelection);
    });
  }

  String _praiseForFoundWord(String word) {
    const List<String> praise = <String>[
      'Nice!',
      'Great job!',
      'You got it!',
      'Well done!',
      'Good one!',
      'Sweet!',
      'Beautiful!',
      'Lovely!',
    ];
    final int index =
        (word.hashCode + _foundWords.length + _boardVersion).abs() %
        praise.length;
    return praise[index];
  }

  _SelectionMatch? _matchedSelection() {
    _SelectionMatch? bestMatch;
    for (final MapEntry<String, List<CellPos>> entry
        in _generated.paths.entries) {
      if (_foundWords.contains(entry.key)) {
        continue;
      }
      final int? quality = _matchQuality(_selection, entry.value);
      if (quality == null) {
        continue;
      }
      if (bestMatch == null || quality < bestMatch.quality) {
        bestMatch = _SelectionMatch(
          word: entry.key,
          path: entry.value,
          quality: quality,
        );
      }
    }
    return bestMatch;
  }

  Future<void> _finishDrag() async {
    if (_isProcessingMatch || _boardCompleted) {
      return;
    }

    final _SelectionMatch? match = _matchedSelection();
    if (match != null) {
      _isProcessingMatch = true;
      try {
        final String matchedWord = match.word;
        final List<CellPos> matchedPath = match.path;
        GameFeedback.success();
        setState(() {
          _foundWords.add(matchedWord);
          _selection.clear();
          _dragAnchor = null;
          _lockedDirection = null;
          _spotlightCells = matchedPath.toSet();
          _burstPath = matchedPath;
          _rewardText = _praiseForFoundWord(matchedWord);
          _rewardToken++;
        });
        _queueSpotlightClear();
        _queueRewardClear();
        _announce('Found $matchedWord');
        if (_foundWords.length == _puzzle.words.length) {
          await _completeBoard();
        } else {
          _showSnack('Found $matchedWord');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingMatch = false;
          });
        } else {
          _isProcessingMatch = false;
        }
      }
      return;
    }

    setState(() {
      _selection.clear();
      _dragAnchor = null;
      _lockedDirection = null;
    });
  }

  Future<void> _useHint() async {
    if (_isShowingHint || _isProcessingMatch || _boardCompleted) {
      return;
    }

    final Iterable<String> remainingWords = _puzzle.words.where(
      (String word) => !_foundWords.contains(word),
    );
    if (remainingWords.isEmpty) {
      return;
    }

    _isShowingHint = true;
    String hintWord = remainingWords.first;
    for (final String word in remainingWords.skip(1)) {
      if (word.length < hintWord.length) {
        hintWord = word;
      }
    }

    final List<CellPos>? hintPath = _generated.paths[hintWord];
    if (hintPath == null || hintPath.isEmpty) {
      _isShowingHint = false;
      _showSnack('Hint unavailable for this board.');
      return;
    }

    final CellPos start = hintPath.first;
    final String hintText = 'Hint: $hintWord starts at ${hintWord[0]}.';
    GameFeedback.hint();
    setState(() {
      _hintsUsed++;
      _selection
        ..clear()
        ..add(start);
      _dragAnchor = start;
      _lockedDirection = null;
      _spotlightCells = <CellPos>{start};
    });
    _queueSpotlightClear();
    _announce(hintText, clearAfter: const Duration(milliseconds: 2200));
    _showSnack(hintText);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      _isShowingHint = false;
      return;
    }
    setState(() {
      _selection.clear();
      _dragAnchor = null;
      _lockedDirection = null;
      _isShowingHint = false;
    });
  }

  Future<void> _completeBoard() async {
    if (_showingWinSheet || _boardCompleted) {
      return;
    }

    final Duration completedElapsed = _stopwatch.elapsed;
    _stopwatch.stop();
    _ticker?.cancel();
    GameFeedback.celebrate();
    final VictoryOutcome outcome = widget.controller.recordVictory(
      difficulty: widget.difficulty,
      puzzle: _puzzle,
      elapsed: completedElapsed,
      hintsUsed: _hintsUsed,
      daily: widget.daily,
    );
    final Set<CellPos> solvedCells = _generated.paths.values
        .expand((List<CellPos> path) => path)
        .toSet();

    setState(() {
      _boardCompleted = true;
      _completedElapsed = completedElapsed;
      _showingWinSheet = true;
      _advanceAfterVictorySheet = false;
      _homeAfterVictorySheet = false;
      _selection.clear();
      _dragAnchor = null;
      _lockedDirection = null;
      _finalPulse = true;
      _rewardText = 'Board mastered';
      _rewardToken++;
      _burstPath = solvedCells.toList(growable: false);
      _spotlightCells = solvedCells;
    });
    _announce('Board cleared', clearAfter: const Duration(milliseconds: 2600));
    _showSnack('Board cleared!');

    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) {
      return;
    }
    setState(() {
      _finalPulse = false;
      _rewardText = null;
      _burstPath = <CellPos>[];
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _VictorySheet(
          difficulty: widget.difficulty,
          puzzle: _puzzle,
          elapsed: completedElapsed,
          hintsUsed: _hintsUsed,
          personalBest: outcome.personalBest,
          cleanStreak: outcome.snapshot.cleanStreak,
          onNextBoard: () => _closeVictorySheetForNext(sheetContext),
          onBackHome: () => _closeVictorySheetForHome(sheetContext),
        );
      },
    );

    if (!mounted) {
      return;
    }
    final bool shouldAdvance = _advanceAfterVictorySheet;
    final bool shouldGoHome = _homeAfterVictorySheet;
    setState(() {
      _showingWinSheet = false;
      _advanceAfterVictorySheet = false;
      _homeAfterVictorySheet = false;
    });

    if (shouldAdvance) {
      _goToNextBoard();
    } else if (shouldGoHome) {
      _goBackHome();
    }
  }

  void _closeVictorySheetForNext(BuildContext sheetContext) {
    _advanceAfterVictorySheet = true;
    Navigator.of(sheetContext).pop();
  }

  void _closeVictorySheetForHome(BuildContext sheetContext) {
    _homeAfterVictorySheet = true;
    Navigator.of(sheetContext).pop();
  }

  void _goToNextBoard({BuildContext? sheetContext}) {
    GameFeedback.success();
    if (sheetContext != null) {
      _closeVictorySheetForNext(sheetContext);
      return;
    }
    final PuzzleDefinition nextPuzzle = widget.daily
        ? widget.controller.configuredPuzzleFor(
            widget.difficulty,
            puzzle: widget.controller.featuredPuzzleFor(widget.difficulty),
          )
        : widget.controller.configuredPuzzleFor(
            widget.difficulty,
            puzzle: widget.controller.nextPuzzleFor(widget.difficulty, _puzzle),
          );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PuzzlePage(
            controller: widget.controller,
            difficulty: widget.difficulty,
            puzzle: nextPuzzle,
            helpEnabled: widget.helpEnabled,
            daily: false,
          );
        },
      ),
    );
  }

  void _goBackHome({BuildContext? sheetContext}) {
    GameFeedback.tap();
    if (sheetContext != null) {
      _closeVictorySheetForHome(sheetContext);
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _announce(
    String text, {
    Duration clearAfter = const Duration(milliseconds: 1600),
  }) {
    _messageTimer?.cancel();
    setState(() {
      _hintMessage = text;
    });
    _messageTimer = Timer(clearAfter, () {
      if (!mounted || _selection.isNotEmpty) {
        return;
      }
      setState(() {
        _hintMessage = null;
      });
    });
  }

  void _queueSpotlightClear() {
    _spotlightTimer?.cancel();
    _spotlightTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _boardCompleted) {
        return;
      }
      setState(() {
        _spotlightCells = <CellPos>{};
      });
    });
  }

  void _queueRewardClear() {
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(milliseconds: 1550), () {
      if (!mounted || _boardCompleted) {
        return;
      }
      setState(() {
        _rewardText = null;
        _burstPath = <CellPos>[];
      });
    });
  }

  List<Offset> _selectionCenters(double tile, double gap) {
    return _selection
        .map((CellPos cell) => _cellCenter(cell, tile, gap))
        .toList(growable: false);
  }

  List<Offset> _burstCenters(double tile, double gap) {
    return _burstPath
        .map((CellPos cell) => _cellCenter(cell, tile, gap))
        .toList(growable: false);
  }

  double _tileFontSize(int size) {
    if (_puzzle.isShaped) {
      return size >= 12 ? 21 : 24;
    }
    if (size >= 13) {
      return 20.5;
    }
    if (size >= 11) {
      return 22;
    }
    if (size >= 9) {
      return 24.5;
    }
    return 27;
  }

  Widget _buildBoard(double boardSize) {
    final double gap = _boardGap();
    final int size = _generated.cells.length;
    final double tile = _tileSizeForBoard(boardSize);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          key: ValueKey<String>('${_puzzle.name}-$_boardVersion'),
          onPanDown: (DragDownDetails details) {
            _beginDrag(details.localPosition, boardSize);
          },
          onPanUpdate: (DragUpdateDetails details) {
            _updateDrag(details.localPosition, boardSize);
          },
          onPanEnd: (_) => _finishDrag(),
          onPanCancel: () {
            setState(() {
              _selection.clear();
              _dragAnchor = null;
              _lockedDirection = null;
            });
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: wtBoardGradient,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x30FFFFFF)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: Stack(
                  children: <Widget>[
                    CustomPaint(
                      size: Size.square(boardSize),
                      painter: BoardLatticePainter(
                        count: size,
                        gap: gap,
                        lineColor: _puzzle.isShaped
                            ? wtGrid.withValues(alpha: 0.95)
                            : wtGrid.withValues(alpha: 0.78),
                        activeCells: _puzzle.isShaped
                            ? _generated.activeCells
                            : null,
                      ),
                    ),
                    CustomPaint(
                      size: Size.square(boardSize),
                      painter: SelectionPathPainter(
                        points: _selectionCenters(tile, gap),
                        color: widget.difficulty.accent,
                        strokeWidth: tile * 0.92,
                        nodeRadius: tile * 0.31,
                      ),
                    ),

                    for (int row = 0; row < size; row++)
                      for (int col = 0; col < size; col++)
                        Positioned(
                          left: col * (tile + gap),
                          top: row * (tile + gap),
                          width: tile,
                          height: tile,
                          child: Builder(
                            builder: (BuildContext context) {
                              final CellPos cell = CellPos(row, col);
                              if (!_isActiveCell(cell)) {
                                return const SizedBox.shrink();
                              }
                              final bool selected = _selection.contains(cell);
                              final bool found = _isFoundCell(cell);
                              final bool spotlight = _isSpotlightCell(cell);
                              final Color background = found
                                  ? widget.difficulty.accent.withValues(
                                      alpha: 0.9,
                                    )
                                  : selected
                                  ? widget.difficulty.accent.withValues(
                                      alpha: 0.26,
                                    )
                                  : spotlight
                                  ? widget.difficulty.accent.withValues(
                                      alpha: 0.14,
                                    )
                                  : _puzzle.isShaped
                                  ? Colors.white.withValues(alpha: 0.045)
                                  : Colors.transparent;
                              final Color textColor = found
                                  ? Colors.white
                                  : const Color(0xFFF9FCFF);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                decoration: BoxDecoration(
                                  color: background,
                                  borderRadius: BorderRadius.circular(
                                    size >= 12 ? 6 : 8,
                                  ),
                                  border: Border.all(
                                    color: found || selected || spotlight
                                        ? widget.difficulty.accent.withValues(
                                            alpha: found ? 1 : 0.56,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _generated.cells[row][col],
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: _tileFontSize(size),
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      shadows: const <Shadow>[
                                        Shadow(
                                          color: Color(0x44000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    if (_finalPulse)
                      _FinalBoardPulse(
                        key: ValueKey<String>('final-pulse-$_rewardToken'),
                        color: widget.difficulty.accent,
                      ),
                    if (_burstPath.isNotEmpty)
                      _WordFoundBurst(
                        key: ValueKey<String>('word-burst-$_rewardToken'),
                        points: _burstCenters(tile, gap),
                        color: widget.difficulty.accent,
                        text: _rewardText,
                        finalBurst: _finalPulse,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: wtSurfaceElevated.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x32F5F7FB)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _goToNextBoard(),
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Next board'),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _goBackHome(),
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordBankPanel() {
    final List<String> orderedWords = <String>[..._puzzle.words]
      ..sort((String a, String b) {
        final bool aFound = _foundWords.contains(a);
        final bool bFound = _foundWords.contains(b);
        if (aFound == bFound) {
          return a.compareTo(b);
        }
        return aFound ? 1 : -1;
      });
    final List<String> leftColumn = <String>[];
    final List<String> rightColumn = <String>[];
    for (int index = 0; index < orderedWords.length; index++) {
      if (index.isEven) {
        leftColumn.add(orderedWords[index]);
      } else {
        rightColumn.add(orderedWords[index]);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: wtSurfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x30F5F7FB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Find these words',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: wtWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Reference list only. Drag on the board above.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0x99F5F7FB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CompactTag(
                label: '${_puzzle.words.length - _foundWords.length} left',
                accent: widget.difficulty.accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _WordBankColumn(
                      words: leftColumn,
                      foundWords: _foundWords,
                      accent: widget.difficulty.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WordBankColumn(
                      words: rightColumn,
                      foundWords: _foundWords,
                      accent: widget.difficulty.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _wordBankMinHeight() {
    final int count = _puzzle.words.length;
    if (count <= 6) {
      return 102;
    }
    if (count <= 8) {
      return 118;
    }
    if (count <= 10) {
      return 144;
    }
    return 168;
  }

  Widget _buildTopStatusBar() {
    final int remainingWords = _puzzle.words.length - _foundWords.length;
    final String? helperText = _boardCompleted
        ? 'Board complete. Review the board or keep moving.'
        : _selection.isNotEmpty
        ? 'Tracing ${_selectionText(_selection)}'
        : _hintMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _CompactTag(
              label: _boardCompleted ? 'Cleared' : '$remainingWords left',
              accent: widget.difficulty.accent,
            ),
            _CompactTag(
              label: formatDuration(_completedElapsed ?? _stopwatch.elapsed),
              accent: wsCoral,
            ),
            if (!widget.helpEnabled)
              const _CompactTag(label: 'Pure mode', accent: wsTeal),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: helperText == null
                ? const SizedBox.shrink()
                : Text(
                    helperText,
                    key: ValueKey<String>(helperText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double wordBankMinHeight = _wordBankMinHeight();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: wtAppBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _puzzle.isShaped
                            ? '${_puzzle.name}  |  ${_puzzle.shape!.label}  |  ${widget.difficulty.label}${widget.daily ? ' daily' : ''}'
                            : '${_puzzle.name}  |  ${widget.difficulty.label}${widget.daily ? ' daily' : ''}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (widget.helpEnabled) ...<Widget>[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            _boardCompleted ||
                                _isShowingHint ||
                                _isProcessingMatch
                            ? null
                            : _useHint,
                        tooltip: 'Hint',
                        icon: const Icon(Icons.lightbulb_rounded),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _restartBoard,
                      tooltip: 'Restart',
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTopStatusBar(),
                if (_boardCompleted) ...<Widget>[
                  const SizedBox(height: 8),
                  _buildCompletedActions(),
                ],
                const SizedBox(height: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double boardSize = min(
                            constraints.maxWidth,
                            max(
                              0,
                              constraints.maxHeight - wordBankMinHeight - 6,
                            ),
                          ).toDouble();
                          return Column(
                            children: <Widget>[
                              _buildBoard(boardSize),
                              const SizedBox(height: 6),
                              Expanded(child: _buildWordBankPanel()),
                            ],
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionMatch {
  const _SelectionMatch({
    required this.word,
    required this.path,
    required this.quality,
  });

  final String word;
  final List<CellPos> path;
  final int quality;
}

class _VictorySheet extends StatelessWidget {
  const _VictorySheet({
    required this.difficulty,
    required this.puzzle,
    required this.elapsed,
    required this.hintsUsed,
    required this.personalBest,
    required this.cleanStreak,
    required this.onNextBoard,
    required this.onBackHome,
  });

  final Difficulty difficulty;
  final PuzzleDefinition puzzle;
  final Duration elapsed;
  final int hintsUsed;
  final bool personalBest;
  final int cleanStreak;
  final VoidCallback onNextBoard;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: wtSurfaceElevated,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    right: -10,
                    top: -18,
                    child: CelebrationBurst(color: difficulty.accent),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: difficulty.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: difficulty.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Board cleared',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${puzzle.name} is done. This is the kind of loop we can keep polishing into a really satisfying mobile game.',
                style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  StatusChip(
                    label: 'Time ${formatDuration(elapsed)}',
                    accent: difficulty.accent,
                    textColor: Colors.white,
                  ),
                  StatusChip(
                    label: '$hintsUsed hints',
                    accent: wsTeal,
                    textColor: Colors.white,
                  ),
                  StatusChip(
                    label: personalBest ? 'New personal best' : 'Run saved',
                    accent: wsCoral,
                    textColor: Colors.white,
                  ),
                  StatusChip(
                    label: 'Clean streak $cleanStreak',
                    accent: wsGold,
                    textColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        GameFeedback.success();
                        onNextBoard();
                      },
                      child: const Text('Next board'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        GameFeedback.tap();
                        onBackHome();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x66FFFFFF)),
                      ),
                      child: const Text('Back home'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTag extends StatelessWidget {
  const _CompactTag({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WordBankColumn extends StatelessWidget {
  const _WordBankColumn({
    required this.words,
    required this.foundWords,
    required this.accent,
  });

  final List<String> words;
  final Set<String> foundWords;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: words.map((String word) {
        final bool found = foundWords.contains(word);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: found
                  ? accent.withValues(alpha: 0.18)
                  : wtWhite.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: found
                    ? accent.withValues(alpha: 0.72)
                    : const Color(0x22F5F7FB),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  found ? Icons.check_circle_rounded : Icons.search_rounded,
                  size: 15,
                  color: found ? accent : const Color(0x99F5F7FB),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: found ? accent : wtWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      decoration: found
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: accent,
                      decorationThickness: 2,
                    ),
                    child: Text(
                      _displayWord(word),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _displayWord(String word) {
    if (word.length <= 1) {
      return word;
    }
    return word[0] + word.substring(1).toLowerCase();
  }
}

class _WordFoundBurst extends StatelessWidget {
  const _WordFoundBurst({
    super.key,
    required this.points,
    required this.color,
    required this.text,
    required this.finalBurst,
  });

  final List<Offset> points;
  final Color color;
  final String? text;
  final bool finalBurst;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: finalBurst ? 2300 : 1250),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double progress, Widget? child) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: _WordFoundBurstPainter(
                        points: points,
                        color: color,
                        progress: progress,
                        finalBurst: finalBurst,
                      ),
                    ),
                    if (text != null)
                      _RewardTextBadge(
                        text: text!,
                        progress: progress,
                        finalBurst: finalBurst,
                        color: color,
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RewardTextBadge extends StatelessWidget {
  const _RewardTextBadge({
    required this.text,
    required this.progress,
    required this.finalBurst,
    required this.color,
  });

  final String text;
  final double progress;
  final bool finalBurst;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fadeOut = progress < 0.78
        ? 1
        : (1 - ((progress - 0.78) / 0.22)).clamp(0.0, 1.0).toDouble();
    final double scale = 0.86 + min(progress * 1.7, 1) * 0.16;
    final double lift = finalBurst ? 0 : -18 * progress;

    return Align(
      alignment: finalBurst ? Alignment.center : Alignment.topCenter,
      child: Transform.translate(
        offset: Offset(0, finalBurst ? 0 : 12 + lift),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: fadeOut,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: finalBurst ? 18 : 12,
                vertical: finalBurst ? 11 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xE607111F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.72)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: finalBurst ? 34 : 22,
                    spreadRadius: finalBurst ? 5 : 1,
                  ),
                ],
              ),
              child: Text(
                finalBurst ? text.toUpperCase() : text,
                style: TextStyle(
                  color: wtWhite,
                  fontSize: finalBurst ? 18 : 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: finalBurst ? 1.6 : 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordFoundBurstPainter extends CustomPainter {
  const _WordFoundBurstPainter({
    required this.points,
    required this.color,
    required this.progress,
    required this.finalBurst,
  });

  final List<Offset> points;
  final Color color;
  final double progress;
  final bool finalBurst;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final double fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final double strokeWidth = finalBurst ? 18 : 12;
    final Paint pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: (finalBurst ? 0.34 : 0.48) * fade);

    if (finalBurst) {
      for (final Offset point in _sparkAnchors()) {
        canvas.drawCircle(point, strokeWidth * 0.72, pathPaint);
      }
    } else if (points.length == 1) {
      canvas.drawCircle(points.first, strokeWidth, pathPaint);
    } else {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, pathPaint);
    }

    final List<Offset> anchors = _sparkAnchors();
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.16 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final Paint sparkPaint = Paint()..color = wtMint.withValues(alpha: fade);
    final Paint blueSparkPaint = Paint()
      ..color = wtCyan.withValues(alpha: fade);

    for (int anchorIndex = 0; anchorIndex < anchors.length; anchorIndex++) {
      final Offset anchor = anchors[anchorIndex];
      canvas.drawCircle(anchor, (finalBurst ? 24 : 16) * fade, glowPaint);

      for (int i = 0; i < 7; i++) {
        final double angle = (pi * 2 / 7) * i + anchorIndex * 0.45;
        final double distance = (finalBurst ? 44 : 26) * (0.18 + progress);
        final Offset sparkCenter =
            anchor + Offset(cos(angle) * distance, sin(angle) * distance);
        final double radius = (finalBurst ? 4.8 : 3.2) * fade;
        canvas.drawCircle(
          sparkCenter,
          radius,
          i.isEven ? sparkPaint : blueSparkPaint,
        );
      }
    }
  }

  List<Offset> _sparkAnchors() {
    if (points.length <= 4) {
      return points;
    }
    if (finalBurst) {
      final int step = max(1, (points.length / 8).ceil());
      final List<Offset> anchors = <Offset>[];
      for (int index = 0; index < points.length; index += step) {
        anchors.add(points[index]);
      }
      if (anchors.last != points.last) {
        anchors.add(points.last);
      }
      return anchors.take(9).toList(growable: false);
    }
    return <Offset>[points.first, points[points.length ~/ 2], points.last];
  }

  @override
  bool shouldRepaint(covariant _WordFoundBurstPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.finalBurst != finalBurst;
  }
}

class _FinalBoardPulse extends StatelessWidget {
  const _FinalBoardPulse({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2300),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double progress, Widget? child) {
                return CustomPaint(
                  painter: _FinalBoardPulsePainter(
                    color: color,
                    progress: progress,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FinalBoardPulsePainter extends CustomPainter {
  const _FinalBoardPulsePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.shortestSide * 0.78;
    final Paint washPaint = Paint()
      ..color = color.withValues(alpha: 0.16 * (1 - progress));
    canvas.drawRect(Offset.zero & size, washPaint);

    for (int i = 0; i < 3; i++) {
      final double phase = ((progress - i * 0.14) / 0.86)
          .clamp(0.0, 1.0)
          .toDouble();
      if (phase <= 0) {
        continue;
      }
      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + i.toDouble()
        ..color = color.withValues(alpha: 0.28 * (1 - phase));
      canvas.drawCircle(center, maxRadius * phase, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinalBoardPulsePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
