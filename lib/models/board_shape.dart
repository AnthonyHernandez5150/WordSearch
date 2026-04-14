import 'dart:math' as math;

class BoardShapeDefinition {
  const BoardShapeDefinition({
    required this.id,
    required this.label,
    required List<String> mask,
    required this.maxWords,
  }) : _mask = mask;

  final String id;
  final String label;
  final int maxWords;
  final List<String> _mask;

  int sizeFor(int baseSize) {
    return _mask.length;
  }

  bool containsCell(int row, int col, int size) {
    if (row < 0 || row >= _mask.length || col < 0 || col >= _mask[row].length) {
      return false;
    }
    return _mask[row][col] == '#';
  }

  int activeCellCount(int size) {
    int count = 0;
    for (final String row in _mask) {
      for (final String cell in row.split('')) {
        if (cell == '#') {
          count++;
        }
      }
    }
    return count;
  }

  int recommendedMaxWords(int size, int availableWords) {
    final int densityCap = math.max(4, activeCellCount(size) ~/ 8);
    return math.min(availableWords, math.min(maxWords, densityCap));
  }
}

class BoardShapeCatalog {
  const BoardShapeCatalog._();

  static const List<BoardShapeDefinition> all = <BoardShapeDefinition>[
    BoardShapeDefinition(
      id: 'heart',
      label: 'Heart',
      maxWords: 8,
      mask: <String>[
        '..###.###..',
        '.#########.',
        '###########',
        '###########',
        '.#########.',
        '..#######..',
        '...#####...',
        '....###....',
        '.....#.....',
        '...........',
        '...........',
      ],
    ),
    BoardShapeDefinition(
      id: 'diamond',
      label: 'Diamond',
      maxWords: 8,
      mask: <String>[
        '.....#.....',
        '....###....',
        '...#####...',
        '..#######..',
        '.#########.',
        '###########',
        '.#########.',
        '..#######..',
        '...#####...',
        '....###....',
        '.....#.....',
      ],
    ),
    BoardShapeDefinition(
      id: 'shield',
      label: 'Shield',
      maxWords: 8,
      mask: <String>[
        '..#######..',
        '.#########.',
        '###########',
        '###########',
        '###########',
        '.#########.',
        '.#########.',
        '..#######..',
        '..#######..',
        '...#####...',
        '....###....',
      ],
    ),
    BoardShapeDefinition(
      id: 'flower',
      label: 'Flower',
      maxWords: 7,
      mask: <String>[
        '...##.##...',
        '..#######..',
        '..#######..',
        '...##.##...',
        '###########',
        '###########',
        '...##.##...',
        '..#######..',
        '..#######..',
        '...##.##...',
        '.....#.....',
      ],
    ),
    BoardShapeDefinition(
      id: 'butterfly',
      label: 'Butterfly',
      maxWords: 7,
      mask: <String>[
        '##.......##',
        '###.....###',
        '.###...###.',
        '..#######..',
        '...#####...',
        '....###....',
        '...#####...',
        '..#######..',
        '.###...###.',
        '###.....###',
        '##.......##',
      ],
    ),
    BoardShapeDefinition(
      id: 'tree',
      label: 'Tree',
      maxWords: 7,
      mask: <String>[
        '.....#.....',
        '....###....',
        '...#####...',
        '..#######..',
        '.#########.',
        '...#####...',
        '...#####...',
        '...#####...',
        '...#####...',
        '....###....',
        '....###....',
      ],
    ),
    BoardShapeDefinition(
      id: 'crown',
      label: 'Crown',
      maxWords: 7,
      mask: <String>[
        '#...#.#...#',
        '##.##.##.##',
        '###########',
        '.#########.',
        '..#######..',
        '..#######..',
        '..#######..',
        '..#######..',
        '..#######..',
        '...........',
        '...........',
      ],
    ),
    BoardShapeDefinition(
      id: 'moon',
      label: 'Moon',
      maxWords: 7,
      mask: <String>[
        '....#####..',
        '..########.',
        '.##########',
        '.####......',
        '#####......',
        '#####......',
        '#####......',
        '.####......',
        '.##########',
        '..########.',
        '....#####..',
      ],
    ),
  ];

  static BoardShapeDefinition get initial => byId('heart');

  static BoardShapeDefinition byId(String id) {
    return all.firstWhere(
      (BoardShapeDefinition shape) => shape.id == id,
      orElse: () => all.first,
    );
  }
}
