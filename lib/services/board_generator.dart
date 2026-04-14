import 'dart:math';

import '../models/cell_pos.dart';
import '../models/difficulty.dart';
import '../models/generated_board.dart';
import '../models/puzzle_definition.dart';

class BoardGenerator {
  const BoardGenerator._();

  static GeneratedBoard generate(
    PuzzleDefinition puzzle, {
    required int version,
    Difficulty difficulty = Difficulty.explorer,
  }) {
    final _DifficultyProfile profile = _DifficultyProfile.forDifficulty(
      difficulty,
    );
    final Set<CellPos> activeCells = _activeCellsFor(puzzle);
    final List<String> words = <String>[...puzzle.words]
      ..sort((String a, String b) => b.length.compareTo(a.length));

    for (int attempt = 0; attempt < profile.attempts; attempt++) {
      final Random random = Random(
        puzzle.name.hashCode ^
            (puzzle.size * 31) ^
            (version * 997) ^
            (attempt * 7919) ^
            difficulty.index,
      );
      final List<List<String?>> draft = List<List<String?>>.generate(
        puzzle.size,
        (_) => List<String?>.filled(puzzle.size, null),
        growable: false,
      );
      final Map<String, List<CellPos>> paths = <String, List<CellPos>>{};
      final Map<_Direction, int> directionUse = <_Direction, int>{};
      bool success = true;

      for (final String word in words) {
        final List<_PlacementCandidate> candidates = <_PlacementCandidate>[];

        for (final _Direction direction in _Direction.values) {
          final List<CellPos> starts = _candidateStarts(
            puzzle.size,
            word.length,
            direction,
            activeCells,
          )..shuffle(random);

          for (final CellPos start in starts) {
            final List<CellPos> path = _buildPath(
              start,
              direction,
              word.length,
            );
            if (!_pathIsActive(path, activeCells) ||
                !_canPlace(path, word, draft)) {
              continue;
            }
            candidates.add(
              _PlacementCandidate(
                direction: direction,
                path: path,
                score: _placementScore(
                  path: path,
                  word: word,
                  draft: draft,
                  size: puzzle.size,
                  direction: direction,
                  directionUse: directionUse,
                  shaped: puzzle.isShaped,
                  random: random,
                  profile: profile,
                ),
              ),
            );
          }
        }

        if (candidates.isEmpty) {
          success = false;
          break;
        }

        candidates.sort((_PlacementCandidate a, _PlacementCandidate b) {
          return b.score.compareTo(a.score);
        });
        final int pickWindow = min(profile.pickWindow, candidates.length);
        final _PlacementCandidate placement =
            candidates[random.nextInt(pickWindow)];
        _placeWord(placement.path, word, draft);
        paths[word] = placement.path;
        directionUse.update(
          placement.direction,
          (int value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      if (!success) {
        continue;
      }

      if (profile.decoyCount > 0) {
        _placeDecoys(
          words: words,
          draft: draft,
          size: puzzle.size,
          activeCells: activeCells,
          random: random,
          profile: profile,
        );
      }

      const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final List<List<String>> filled = List<List<String>>.generate(
        puzzle.size,
        (int row) => List<String>.generate(puzzle.size, (int col) {
          final CellPos cell = CellPos(row, col);
          if (!activeCells.contains(cell)) {
            return '';
          }
          return draft[row][col] ?? alphabet[random.nextInt(alphabet.length)];
        }, growable: false),
        growable: false,
      );

      return GeneratedBoard(
        cells: filled,
        paths: paths,
        activeCells: activeCells,
      );
    }

    throw StateError('Unable to generate a board for ${puzzle.name}.');
  }

  static double _placementScore({
    required List<CellPos> path,
    required String word,
    required List<List<String?>> draft,
    required int size,
    required _Direction direction,
    required Map<_Direction, int> directionUse,
    required bool shaped,
    required Random random,
    required _DifficultyProfile profile,
  }) {
    final int overlap = _overlapCount(path, word, draft);
    final int directionCount = directionUse[direction] ?? 0;
    final int extraOverlap = max(0, overlap - profile.freeOverlap);
    final int newCells = word.length - overlap;
    double score = random.nextDouble();

    score += min(overlap, profile.freeOverlap) * profile.overlapReward;
    score -= extraOverlap * (shaped ? 1.4 : profile.extraOverlapPenalty);
    score += newCells * profile.newCellReward;
    score += _separationScore(path, draft, size) * profile.spreadWeight;
    score -= _neighborPressure(path, draft) * profile.neighborPenalty;
    score += _directionScore(direction, profile);
    score -= directionCount * profile.directionRepeatPenalty;
    score -= _outerBandRatio(path, size) * profile.outerBandPenalty;

    final CellPos start = path.first;
    final CellPos end = path.last;
    if (_isEdgeCell(start, size)) {
      score -= shaped
          ? profile.edgeStartPenalty * 0.4
          : profile.edgeStartPenalty;
    }
    if (_isEdgeCell(end, size)) {
      score -= shaped ? profile.edgeEndPenalty * 0.4 : profile.edgeEndPenalty;
    }
    if (_isOuterBandCell(start, size)) {
      score -= shaped
          ? profile.outerStartPenalty * 0.45
          : profile.outerStartPenalty;
    }

    if ((direction.isHorizontal || direction.isVertical) &&
        word.length >= size - 1) {
      score -= profile.longStraightPenalty;
    }

    final double centerDistance = _centerDistance(path, size);
    score -= centerDistance * profile.centerDistancePenalty;

    return score;
  }

  static double _directionScore(
    _Direction direction,
    _DifficultyProfile profile,
  ) {
    double score = 0;
    if (direction == _Direction.down) {
      score -= profile.downPenalty;
    }
    if (direction == _Direction.right) {
      score -= profile.rightPenalty;
    }
    if (direction.isVertical) {
      score -= profile.verticalPenalty;
    }
    if (direction.isDiagonal) {
      score += profile.diagonalBonus;
    }
    if (direction.isReverse) {
      score += profile.reverseBonus;
    }
    if (direction.isBackwardDiagonal) {
      score += profile.backwardsDiagonalBonus;
    }
    return score;
  }

  static int _overlapCount(
    List<CellPos> path,
    String word,
    List<List<String?>> draft,
  ) {
    int overlap = 0;
    for (int i = 0; i < word.length; i++) {
      final CellPos cell = path[i];
      if (draft[cell.row][cell.col] == word[i]) {
        overlap++;
      }
    }
    return overlap;
  }

  static double _separationScore(
    List<CellPos> path,
    List<List<String?>> draft,
    int size,
  ) {
    final List<CellPos> occupied = <CellPos>[];
    for (int row = 0; row < draft.length; row++) {
      for (int col = 0; col < draft[row].length; col++) {
        if (draft[row][col] != null) {
          occupied.add(CellPos(row, col));
        }
      }
    }
    if (occupied.isEmpty) {
      return 0;
    }

    final double pathRow =
        path.fold<double>(0, (double total, CellPos cell) {
          return total + cell.row;
        }) /
        path.length;
    final double pathCol =
        path.fold<double>(0, (double total, CellPos cell) {
          return total + cell.col;
        }) /
        path.length;
    double nearestDistance = double.infinity;
    for (final CellPos cell in occupied) {
      final double distance =
          (cell.row - pathRow).abs() + (cell.col - pathCol).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
      }
    }

    return min(nearestDistance, size / 2);
  }

  static int _neighborPressure(List<CellPos> path, List<List<String?>> draft) {
    final Set<CellPos> pathCells = path.toSet();
    int pressure = 0;
    for (final CellPos cell in path) {
      for (int rowDelta = -1; rowDelta <= 1; rowDelta++) {
        for (int colDelta = -1; colDelta <= 1; colDelta++) {
          if (rowDelta == 0 && colDelta == 0) {
            continue;
          }
          final int row = cell.row + rowDelta;
          final int col = cell.col + colDelta;
          if (row < 0 ||
              row >= draft.length ||
              col < 0 ||
              col >= draft[row].length) {
            continue;
          }
          final CellPos neighbor = CellPos(row, col);
          if (!pathCells.contains(neighbor) && draft[row][col] != null) {
            pressure++;
          }
        }
      }
    }
    return pressure;
  }

  static bool _isEdgeCell(CellPos cell, int size) {
    return cell.row == 0 ||
        cell.col == 0 ||
        cell.row == size - 1 ||
        cell.col == size - 1;
  }

  static bool _isOuterBandCell(CellPos cell, int size) {
    return cell.row < 2 ||
        cell.col < 2 ||
        cell.row >= size - 2 ||
        cell.col >= size - 2;
  }

  static double _outerBandRatio(List<CellPos> path, int size) {
    int outerCells = 0;
    for (final CellPos cell in path) {
      if (_isOuterBandCell(cell, size)) {
        outerCells++;
      }
    }
    return outerCells / path.length;
  }

  static double _centerDistance(List<CellPos> path, int size) {
    final double center = (size - 1) / 2;
    double total = 0;
    for (final CellPos cell in path) {
      total += (cell.row - center).abs() + (cell.col - center).abs();
    }
    return total / path.length;
  }

  static List<CellPos> _candidateStarts(
    int size,
    int length,
    _Direction direction,
    Set<CellPos> activeCells,
  ) {
    final List<CellPos> starts = <CellPos>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final CellPos start = CellPos(row, col);
        if (!activeCells.contains(start)) {
          continue;
        }
        final int endRow = row + direction.rowDelta * (length - 1);
        final int endCol = col + direction.colDelta * (length - 1);
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
          continue;
        }
        starts.add(start);
      }
    }
    return starts;
  }

  static Set<CellPos> _activeCellsFor(PuzzleDefinition puzzle) {
    if (puzzle.shape == null) {
      return <CellPos>{
        for (int row = 0; row < puzzle.size; row++)
          for (int col = 0; col < puzzle.size; col++) CellPos(row, col),
      };
    }

    final Set<CellPos> activeCells = <CellPos>{};
    for (int row = 0; row < puzzle.size; row++) {
      for (int col = 0; col < puzzle.size; col++) {
        if (puzzle.shape!.containsCell(row, col, puzzle.size)) {
          activeCells.add(CellPos(row, col));
        }
      }
    }
    return activeCells;
  }

  static bool _pathIsActive(List<CellPos> path, Set<CellPos> activeCells) {
    for (final CellPos cell in path) {
      if (!activeCells.contains(cell)) {
        return false;
      }
    }
    return true;
  }

  static List<CellPos> _buildPath(
    CellPos start,
    _Direction direction,
    int length,
  ) {
    return List<CellPos>.generate(
      length,
      (int index) => CellPos(
        start.row + direction.rowDelta * index,
        start.col + direction.colDelta * index,
      ),
      growable: false,
    );
  }

  static bool _canPlace(
    List<CellPos> path,
    String word,
    List<List<String?>> draft,
  ) {
    for (int i = 0; i < word.length; i++) {
      final CellPos cell = path[i];
      final String? existing = draft[cell.row][cell.col];
      if (existing != null && existing != word[i]) {
        return false;
      }
    }
    return true;
  }

  static void _placeWord(
    List<CellPos> path,
    String word,
    List<List<String?>> draft,
  ) {
    for (int i = 0; i < word.length; i++) {
      final CellPos cell = path[i];
      draft[cell.row][cell.col] = word[i];
    }
  }

  static void _placeDecoys({
    required List<String> words,
    required List<List<String?>> draft,
    required int size,
    required Set<CellPos> activeCells,
    required Random random,
    required _DifficultyProfile profile,
  }) {
    final Set<String> realWords = words.toSet();
    final List<String> decoys = _decoysForWords(words, realWords)
      ..shuffle(random);
    int placed = 0;

    for (final String decoy in decoys) {
      if (placed >= profile.decoyCount) {
        return;
      }

      final List<_PlacementCandidate> candidates = <_PlacementCandidate>[];
      for (final _Direction direction in _Direction.values) {
        final List<CellPos> starts = _candidateStarts(
          size,
          decoy.length,
          direction,
          activeCells,
        )..shuffle(random);
        for (final CellPos start in starts) {
          final List<CellPos> path = _buildPath(start, direction, decoy.length);
          if (!_pathIsActive(path, activeCells) ||
              !_canPlace(path, decoy, draft)) {
            continue;
          }
          candidates.add(
            _PlacementCandidate(
              direction: direction,
              path: path,
              score: _decoyScore(
                path: path,
                draft: draft,
                size: size,
                direction: direction,
                profile: profile,
                random: random,
              ),
            ),
          );
        }
      }

      if (candidates.isEmpty) {
        continue;
      }
      candidates.sort((_PlacementCandidate a, _PlacementCandidate b) {
        return b.score.compareTo(a.score);
      });
      _placeWord(candidates.first.path, decoy, draft);
      placed++;
    }
  }

  static double _decoyScore({
    required List<CellPos> path,
    required List<List<String?>> draft,
    required int size,
    required _Direction direction,
    required _DifficultyProfile profile,
    required Random random,
  }) {
    double score = random.nextDouble();
    score += _directionScore(direction, profile) * 0.65;
    score += _separationScore(path, draft, size) * profile.spreadWeight * 0.5;
    score -= _outerBandRatio(path, size) * profile.outerBandPenalty * 0.55;
    score -= _occupiedCount(path, draft) * 0.6;
    return score;
  }

  static int _occupiedCount(List<CellPos> path, List<List<String?>> draft) {
    int count = 0;
    for (final CellPos cell in path) {
      if (draft[cell.row][cell.col] != null) {
        count++;
      }
    }
    return count;
  }

  static List<String> _decoysForWords(
    List<String> words,
    Set<String> realWords,
  ) {
    final Set<String> decoys = <String>{};
    for (final String word in words) {
      if (word.length < 4) {
        continue;
      }

      for (int index = 0; index < word.length - 1; index++) {
        if (word[index] == word[index + 1]) {
          continue;
        }
        final List<String> letters = word.split('');
        final String temp = letters[index];
        letters[index] = letters[index + 1];
        letters[index + 1] = temp;
        final String decoy = letters.join();
        if (!realWords.contains(decoy)) {
          decoys.add(decoy);
        }
      }

      final int vowelIndex = word.indexOf(RegExp('[AEIOU]'));
      if (vowelIndex != -1) {
        for (final String vowel in const <String>['A', 'E', 'I', 'O', 'U']) {
          if (vowel == word[vowelIndex]) {
            continue;
          }
          final String decoy =
              word.substring(0, vowelIndex) +
              vowel +
              word.substring(vowelIndex + 1);
          if (!realWords.contains(decoy)) {
            decoys.add(decoy);
          }
        }
      }
    }
    return decoys.toList(growable: false);
  }
}

class _DifficultyProfile {
  const _DifficultyProfile({
    required this.attempts,
    required this.pickWindow,
    required this.freeOverlap,
    required this.overlapReward,
    required this.extraOverlapPenalty,
    required this.newCellReward,
    required this.spreadWeight,
    required this.neighborPenalty,
    required this.directionRepeatPenalty,
    required this.outerBandPenalty,
    required this.edgeStartPenalty,
    required this.edgeEndPenalty,
    required this.outerStartPenalty,
    required this.longStraightPenalty,
    required this.centerDistancePenalty,
    required this.rightPenalty,
    required this.downPenalty,
    required this.verticalPenalty,
    required this.diagonalBonus,
    required this.reverseBonus,
    required this.backwardsDiagonalBonus,
    required this.decoyCount,
  });

  final int attempts;
  final int pickWindow;
  final int freeOverlap;
  final double overlapReward;
  final double extraOverlapPenalty;
  final double newCellReward;
  final double spreadWeight;
  final double neighborPenalty;
  final double directionRepeatPenalty;
  final double outerBandPenalty;
  final double edgeStartPenalty;
  final double edgeEndPenalty;
  final double outerStartPenalty;
  final double longStraightPenalty;
  final double centerDistancePenalty;
  final double rightPenalty;
  final double downPenalty;
  final double verticalPenalty;
  final double diagonalBonus;
  final double reverseBonus;
  final double backwardsDiagonalBonus;
  final int decoyCount;

  static _DifficultyProfile forDifficulty(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.calm => const _DifficultyProfile(
        attempts: 120,
        pickWindow: 9,
        freeOverlap: 2,
        overlapReward: 2.4,
        extraOverlapPenalty: 0.4,
        newCellReward: 0.05,
        spreadWeight: 0.15,
        neighborPenalty: 0.02,
        directionRepeatPenalty: 1.3,
        outerBandPenalty: -0.45,
        edgeStartPenalty: -0.8,
        edgeEndPenalty: -0.4,
        outerStartPenalty: -0.35,
        longStraightPenalty: 1.2,
        centerDistancePenalty: 0.0,
        rightPenalty: -2.2,
        downPenalty: -1.4,
        verticalPenalty: -0.3,
        diagonalBonus: -0.5,
        reverseBonus: -1.3,
        backwardsDiagonalBonus: -1.1,
        decoyCount: 0,
      ),
      Difficulty.explorer => const _DifficultyProfile(
        attempts: 160,
        pickWindow: 6,
        freeOverlap: 1,
        overlapReward: 1.5,
        extraOverlapPenalty: 1.5,
        newCellReward: 0.12,
        spreadWeight: 0.7,
        neighborPenalty: 0.12,
        directionRepeatPenalty: 3.0,
        outerBandPenalty: 1.6,
        edgeStartPenalty: 1.2,
        edgeEndPenalty: 0.7,
        outerStartPenalty: 1.0,
        longStraightPenalty: 3.2,
        centerDistancePenalty: 0.06,
        rightPenalty: 1.6,
        downPenalty: 2.7,
        verticalPenalty: 0.8,
        diagonalBonus: 2.2,
        reverseBonus: 2.0,
        backwardsDiagonalBonus: 1.8,
        decoyCount: 0,
      ),
      Difficulty.expert => const _DifficultyProfile(
        attempts: 220,
        pickWindow: 4,
        freeOverlap: 1,
        overlapReward: 0.8,
        extraOverlapPenalty: 3.8,
        newCellReward: 0.18,
        spreadWeight: 1.35,
        neighborPenalty: 0.26,
        directionRepeatPenalty: 4.4,
        outerBandPenalty: 4.8,
        edgeStartPenalty: 3.8,
        edgeEndPenalty: 1.7,
        outerStartPenalty: 4.0,
        longStraightPenalty: 7.0,
        centerDistancePenalty: 0.02,
        rightPenalty: 4.4,
        downPenalty: 7.8,
        verticalPenalty: 3.2,
        diagonalBonus: 5.2,
        reverseBonus: 4.8,
        backwardsDiagonalBonus: 5.8,
        decoyCount: 2,
      ),
    };
  }
}

class _PlacementCandidate {
  const _PlacementCandidate({
    required this.direction,
    required this.path,
    required this.score,
  });

  final _Direction direction;
  final List<CellPos> path;
  final double score;
}

class _Direction {
  const _Direction(this.rowDelta, this.colDelta);

  final int rowDelta;
  final int colDelta;

  bool get isHorizontal => rowDelta == 0;
  bool get isVertical => colDelta == 0;
  bool get isDiagonal => rowDelta != 0 && colDelta != 0;
  bool get isReverse => rowDelta < 0 || colDelta < 0;
  bool get isBackwardDiagonal => isDiagonal && isReverse;

  static const _Direction upLeft = _Direction(-1, -1);
  static const _Direction up = _Direction(-1, 0);
  static const _Direction upRight = _Direction(-1, 1);
  static const _Direction left = _Direction(0, -1);
  static const _Direction right = _Direction(0, 1);
  static const _Direction downLeft = _Direction(1, -1);
  static const _Direction down = _Direction(1, 0);
  static const _Direction downRight = _Direction(1, 1);

  static const List<_Direction> values = <_Direction>[
    upLeft,
    up,
    upRight,
    left,
    downLeft,
    downRight,
    right,
    down,
  ];
}
