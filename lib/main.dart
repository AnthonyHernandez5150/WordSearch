import 'dart:math';

import 'package:flutter/material.dart';

const Color _ink = Color(0xFF142033);
const Color _teal = Color(0xFF0E5D74);
const Color _gold = Color(0xFFF0A33B);
const Color _cream = Color(0xFFF6F1E8);
const Color _mist = Color(0xFFE9F0F5);
const Color _sage = Color(0xFF8CB19D);
const Color _coral = Color(0xFFE57A58);

void main() {
  runApp(const MyApp());
}

enum Difficulty { calm, explorer, expert }

class PuzzleDefinition {
  const PuzzleDefinition({
    required this.name,
    required this.size,
    required this.words,
    required this.tip,
  });

  final String name;
  final int size;
  final List<String> words;
  final String tip;
}

const Map<Difficulty, PuzzleDefinition> _puzzles = <Difficulty, PuzzleDefinition>{
  Difficulty.calm: PuzzleDefinition(
    name: 'Starter Lounge',
    size: 6,
    words: <String>[
      'PUZZLE',
      'SEARCH',
      'LETTER',
      'PLAYER',
      'BOARDS',
      'RIDDLE',
    ],
    tip: 'Tap and drag to trace words in any straight line.',
  ),
  Difficulty.explorer: PuzzleDefinition(
    name: 'Atlas Lounge',
    size: 8,
    words: <String>[
      'SEARCH',
      'PUZZLE',
      'WORD',
      'PLAY',
      'FIND',
      'CLUE',
      'TRACE',
      'LINE',
    ],
    tip: 'Drag across the board to reveal words hidden inside filler letters.',
  ),
  Difficulty.expert: PuzzleDefinition(
    name: 'Night Sprint',
    size: 10,
    words: <String>[
      'CROSSWORDS',
      'DISCOVERY',
      'LIGHTSPEED',
      'QUICKTRACE',
      'BRAINSTORM',
      'HIDDENPATH',
      'LETTERFIND',
      'SEARCHGRID',
      'PUZZLEMODE',
      'VICTORYRUN',
    ],
    tip: 'Longer diagonals and fuller boards reward a clean, deliberate drag.',
  ),
};

extension DifficultyMeta on Difficulty {
  String get label => switch (this) {
    Difficulty.calm => 'Calm',
    Difficulty.explorer => 'Explorer',
    Difficulty.expert => 'Expert',
  };

  String get summary => switch (this) {
    Difficulty.calm => '6 x 6 board  |  8 words  |  No timer',
    Difficulty.explorer => '8 x 8 board  |  12 words  |  6 min focus',
    Difficulty.expert => '10 x 10 board  |  16 words  |  4 min sprint',
  };

  String get description => switch (this) {
    Difficulty.calm => 'Soft starts and readable boards for easy puzzle nights.',
    Difficulty.explorer => 'Balanced daily play with diagonals, variety, and pace.',
    Difficulty.expert => 'Dense boards, tighter routes, and faster clears.',
  };

  IconData get icon => switch (this) {
    Difficulty.calm => Icons.spa_rounded,
    Difficulty.explorer => Icons.explore_rounded,
    Difficulty.expert => Icons.bolt_rounded,
  };

  Color get accent => switch (this) {
    Difficulty.calm => _sage,
    Difficulty.explorer => _gold,
    Difficulty.expert => _coral,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.light,
    ).copyWith(
      primary: _teal,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: _ink,
      surface: Colors.white,
      onSurface: _ink,
    );

    return MaterialApp(
      title: 'WordSearch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _cream,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontFamily: 'serif',
            fontSize: 44,
            fontWeight: FontWeight.w700,
            height: 0.98,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: _ink),
          bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: _ink),
        ),
      ),
      home: const WordSearchHomePage(),
    );
  }
}

class WordSearchHomePage extends StatefulWidget {
  const WordSearchHomePage({super.key});

  @override
  State<WordSearchHomePage> createState() => _WordSearchHomePageState();
}

class _WordSearchHomePageState extends State<WordSearchHomePage> {
  Difficulty _selected = Difficulty.explorer;

  void _showNotice(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is the next build step.')));
  }

  void _openPuzzle(Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PuzzlePage(
            difficulty: difficulty,
            puzzle: _puzzles[difficulty]!,
          );
        },
      ),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1A142033)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _teal),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _ink.withValues(alpha: 0.86),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1A142033)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 30,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyCard(Difficulty level) {
    final bool selected = level == _selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => setState(() => _selected = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? level.accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? level.accent : const Color(0x1F142033),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: level.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(level.icon, color: level.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(level.label, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          level.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _ink.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: level.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Selected',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _metric(level.summary.split('  |  ')[0], level.accent),
                  _metric(level.summary.split('  |  ')[1], level.accent),
                  _metric(level.summary.split('  |  ')[2], level.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool isWide) {
    const List<String> letters = <String>[
      'W', 'O', 'R', 'D',
      'N', 'S', 'E', 'A',
      'P', 'L', 'A', 'Y',
      'G', 'R', 'I', 'D',
      'Q', 'U', 'E', 'S',
    ];
    const Set<int> picked = <int>{0, 1, 2, 3, 10, 11, 14, 15};

    final Widget preview = Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x1CFFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Featured Grid',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: letters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (BuildContext context, int index) {
              final bool hit = picked.contains(index);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: hit ? _gold : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    letters[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: hit ? _ink : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Theme: Atlas Lounge',
            style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    final Widget copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const <Widget>[
            _HeroBadge(label: 'Daily drops'),
            _HeroBadge(label: 'Solo play'),
            _HeroBadge(label: 'Clean boards'),
          ],
        ),
        const SizedBox(height: 18),
        Text('WordSearch', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'A polished puzzle room for quick daily wins, slower evening sessions, and clean mobile play.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => _openPuzzle(_selected),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Start ${_selected.label}'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openPuzzle(Difficulty.explorer),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x80FFFFFF)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('Daily Challenge'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Selected mode: ${_selected.label}  |  ${_selected.summary}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xCCFFFFFF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF12233B), Color(0xFF0E5D74), Color(0xFF17304B)],
        ),
      ),
      child: isWide
          ? Row(children: <Widget>[Expanded(child: copy), const SizedBox(width: 24), preview])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[copy, const SizedBox(height: 22), Center(child: preview)],
            ),
    );
  }

  Widget _spotlightText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Tonight\'s Spotlight', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(
          'Build around themed boards, daily streaks, and collectible word packs so the home screen always feels alive.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: _ink.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _metric('Travel', _gold),
            _metric('Music', _gold),
            _metric('Nature', _gold),
            _metric('Food', _gold),
            _metric('Space', _gold),
          ],
        ),
      ],
    );
  }

  Widget _nextBuildCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11233A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Next up',
            style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Text(
            'Swipe selection and generators',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            'The board is playable now. The next layer is drag gestures, themed generators, and smarter word placement.',
            style: TextStyle(color: Color(0xCCFFFFFF), height: 1.45),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_cream, _mist, Color(0xFFE4F0E8)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(top: -72, left: -28, child: _GlowOrb(color: Color(0x44F0A33B), size: 220)),
            const Positioned(top: 220, right: -96, child: _GlowOrb(color: Color(0x3D8CB19D), size: 280)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _pill('Offline-ready', Icons.shield_rounded),
                              _pill('Daily boards', Icons.auto_awesome_rounded),
                              _pill('Quick sessions', Icons.phone_iphone_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF173653),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _hero(isWide),
                    const SizedBox(height: 26),
                    Text('Pick Tonight\'s Pace', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Each mode is tuned for phone-sized boards, fast restarts, and one-thumb play.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _ink.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...Difficulty.values.map(_difficultyCard),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        _stat('09', 'Streak', _gold),
                        const SizedBox(width: 12),
                        _stat('42', 'Boards', _sage),
                        const SizedBox(width: 12),
                        _stat('1:58', 'Best', _coral),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0x1A142033)),
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(child: _spotlightText(context)),
                                const SizedBox(width: 18),
                                Expanded(child: _nextBuildCard()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _spotlightText(context),
                                const SizedBox(height: 18),
                                _nextBuildCard(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.difficulty,
    required this.puzzle,
  });

  final Difficulty difficulty;
  final PuzzleDefinition puzzle;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late _GeneratedBoard _generated;
  final Set<String> _foundWords = <String>{};
  List<_CellPos> _selection = <_CellPos>[];
  _CellPos? _dragAnchor;
  int _boardVersion = 0;

  @override
  void initState() {
    super.initState();
    _buildFreshBoard();
  }

  void _buildFreshBoard() {
    _generated = _generateBoard(widget.puzzle, _boardVersion);
  }

  _GeneratedBoard _generateBoard(PuzzleDefinition puzzle, int version) {
    final List<String> words = <String>[...puzzle.words]
      ..sort((String a, String b) => b.length.compareTo(a.length));
    final List<_Direction> directions = _Direction.values;

    for (int attempt = 0; attempt < 40; attempt++) {
      final Random random = Random(
        puzzle.name.hashCode ^ (puzzle.size * 31) ^ (version * 997) ^ attempt,
      );
      final List<List<String?>> draft = List<List<String?>>.generate(
        puzzle.size,
        (_) => List<String?>.filled(puzzle.size, null),
        growable: false,
      );
      final Map<String, List<_CellPos>> paths = <String, List<_CellPos>>{};
      var success = true;

      for (final String word in words) {
        final List<_Direction> shuffledDirections = <_Direction>[
          ...directions,
        ]..shuffle(random);
        List<_CellPos>? placement;

        for (final _Direction direction in shuffledDirections) {
          final List<_CellPos> candidates =
              _candidateStarts(puzzle.size, word.length, direction)
                ..shuffle(random);

          for (final _CellPos start in candidates) {
            final List<_CellPos> path =
                _buildPath(start, direction, word.length);
            if (_canPlace(path, word, draft)) {
              placement = path;
              _placeWord(path, word, draft);
              break;
            }
          }

          if (placement != null) {
            break;
          }
        }

        if (placement == null) {
          success = false;
          break;
        }
        paths[word] = placement;
      }

      if (!success) {
        continue;
      }

      const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final List<List<String>> filled = List<List<String>>.generate(
        puzzle.size,
        (int row) => List<String>.generate(
          puzzle.size,
          (int col) =>
              draft[row][col] ?? alphabet[random.nextInt(alphabet.length)],
          growable: false,
        ),
        growable: false,
      );

      return _GeneratedBoard(cells: filled, paths: paths);
    }

    throw StateError('Unable to generate a board for ${puzzle.name}.');
  }

  String _selectionText(List<_CellPos> cells) {
    return cells
        .map(((_CellPos cell) => _generated.cells[cell.row][cell.col]))
        .join();
  }

  List<_CellPos> _candidateStarts(
    int size,
    int length,
    _Direction direction,
  ) {
    final List<_CellPos> starts = <_CellPos>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final int endRow = row + direction.rowDelta * (length - 1);
        final int endCol = col + direction.colDelta * (length - 1);
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
          continue;
        }
        starts.add(_CellPos(row, col));
      }
    }
    return starts;
  }

  List<_CellPos> _buildPath(
    _CellPos start,
    _Direction direction,
    int length,
  ) {
    return List<_CellPos>.generate(
      length,
      (int index) => _CellPos(
        start.row + direction.rowDelta * index,
        start.col + direction.colDelta * index,
      ),
      growable: false,
    );
  }

  bool _canPlace(
    List<_CellPos> path,
    String word,
    List<List<String?>> draft,
  ) {
    for (int i = 0; i < word.length; i++) {
      final _CellPos cell = path[i];
      final String? existing = draft[cell.row][cell.col];
      if (existing != null && existing != word[i]) {
        return false;
      }
    }
    return true;
  }

  void _placeWord(
    List<_CellPos> path,
    String word,
    List<List<String?>> draft,
  ) {
    for (int i = 0; i < word.length; i++) {
      final _CellPos cell = path[i];
      draft[cell.row][cell.col] = word[i];
    }
  }

  bool _samePath(List<_CellPos> a, List<_CellPos> b) {
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

  List<_CellPos> _reversedPath(List<_CellPos> path) {
    return path.reversed.toList(growable: false);
  }

  bool _isFoundCell(_CellPos cell) {
    return _foundWords.any(
      (String word) => _generated.paths[word]!.contains(cell),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _restart() {
    setState(() {
      _boardVersion++;
      _selection = <_CellPos>[];
      _dragAnchor = null;
      _foundWords.clear();
      _buildFreshBoard();
    });
  }

  _CellPos? _cellFromLocal(Offset localPosition, double boardSize) {
    final int size = _generated.cells.length;
    final double gap = 8;
    final double tile = (boardSize - gap * (size - 1)) / size;
    final double step = tile + gap;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > boardSize ||
        localPosition.dy > boardSize) {
      return null;
    }
    final int col =
        ((localPosition.dx / step).floor().clamp(0, size - 1)) as int;
    final int row =
        ((localPosition.dy / step).floor().clamp(0, size - 1)) as int;
    return _CellPos(row, col);
  }

  List<_CellPos> _lineTo(_CellPos start, _CellPos end) {
    final int rowDiff = end.row - start.row;
    final int colDiff = end.col - start.col;

    if (rowDiff == 0 && colDiff == 0) {
      return <_CellPos>[start];
    }

    final bool sameRow = rowDiff == 0;
    final bool sameCol = colDiff == 0;
    final bool diagonal = rowDiff.abs() == colDiff.abs();
    if (!sameRow && !sameCol && !diagonal) {
      return <_CellPos>[start];
    }

    final int rowStep = rowDiff.sign;
    final int colStep = colDiff.sign;
    final int distance = max(rowDiff.abs(), colDiff.abs());

    return List<_CellPos>.generate(
      distance + 1,
      (int index) => _CellPos(
        start.row + rowStep * index,
        start.col + colStep * index,
      ),
      growable: false,
    );
  }

  void _beginDrag(Offset localPosition, double boardSize) {
    final _CellPos? cell = _cellFromLocal(localPosition, boardSize);
    if (cell == null) {
      return;
    }
    setState(() {
      _dragAnchor = cell;
      _selection = <_CellPos>[cell];
    });
  }

  void _updateDrag(Offset localPosition, double boardSize) {
    final _CellPos? anchor = _dragAnchor;
    final _CellPos? cell = _cellFromLocal(localPosition, boardSize);
    if (anchor == null || cell == null) {
      return;
    }
    final List<_CellPos> nextSelection = _lineTo(anchor, cell);
    if (_samePath(nextSelection, _selection)) {
      return;
    }
    setState(() {
      _selection = nextSelection;
    });
  }

  String? _matchedWordForSelection() {
    for (final MapEntry<String, List<_CellPos>> entry
        in _generated.paths.entries) {
      if (_samePath(_selection, entry.value) ||
          _samePath(_selection, _reversedPath(entry.value))) {
        return entry.key;
      }
    }
    return null;
  }

  void _finishDrag() {
    final String? matchedWord = _matchedWordForSelection();
    if (matchedWord != null && !_foundWords.contains(matchedWord)) {
      setState(() {
        _foundWords.add(matchedWord);
        _selection = <_CellPos>[];
        _dragAnchor = null;
      });
      if (_foundWords.length == widget.puzzle.words.length) {
        _showSnack('Board cleared!');
      } else {
        _showSnack('Found $matchedWord');
      }
      return;
    }

    setState(() {
      _selection = <_CellPos>[];
      _dragAnchor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double boardSize = min(screenWidth - 48, 420).toDouble();
    final int wordsLeft = widget.puzzle.words.length - _foundWords.length;
    final double gap = 8;
    final int size = _generated.cells.length;
    final double tile = (boardSize - gap * (size - 1)) / size;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_cream, _mist, Color(0xFFE4F0E8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.puzzle.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.difficulty.label} mode',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _ink.withValues(alpha: 0.68),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Restart'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0x1A142033)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Find every hidden word',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.puzzle.tip,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _ink.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _StatusSummary(
                            label: '${_foundWords.length}/${widget.puzzle.words.length} found',
                            accent: widget.difficulty.accent,
                          ),
                          _StatusSummary(
                            label: '$wordsLeft left',
                            accent: _teal,
                          ),
                          _StatusSummary(
                            label: _selection.isEmpty
                                ? 'Tap and drag to begin'
                                : 'Trace: ${_selectionText(_selection)}',
                            accent: _gold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onPanDown: (DragDownDetails details) {
                      _beginDrag(details.localPosition, boardSize);
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      _updateDrag(details.localPosition, boardSize);
                    },
                    onPanEnd: (_) => _finishDrag(),
                    onPanCancel: () {
                      setState(() {
                        _selection = <_CellPos>[];
                        _dragAnchor = null;
                      });
                    },
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: Stack(
                        children: <Widget>[
                          for (int row = 0; row < size; row++)
                            for (int col = 0; col < size; col++)
                              Positioned(
                                left: col * (tile + gap),
                                top: row * (tile + gap),
                                width: tile,
                                height: tile,
                                child: Builder(
                                  builder: (BuildContext context) {
                                    final _CellPos cell = _CellPos(row, col);
                                    final bool selected = _selection.contains(cell);
                                    final bool found = _isFoundCell(cell);
                                    final Color background = found
                                        ? widget.difficulty.accent
                                        : selected
                                        ? _gold
                                        : const Color(0xFFFFFFFF);
                                    final Color textColor = found || selected
                                        ? (found ? Colors.white : _ink)
                                        : _ink;

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected || found
                                              ? background
                                              : const Color(0x1A142033),
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: const Color(0x12142033),
                                            blurRadius: found ? 16 : 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _generated.cells[row][col],
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: size >= 10 ? 18 : 22,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hidden words',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.puzzle.words.map((String word) {
                    final bool found = _foundWords.contains(word);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: found
                            ? widget.difficulty.accent
                            : Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: found
                              ? widget.difficulty.accent
                              : const Color(0x1A142033),
                        ),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          color: found ? Colors.white : _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_foundWords.length == widget.puzzle.words.length) ...<Widget>[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: widget.difficulty.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: widget.difficulty.accent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Board cleared',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nice work. You found every word on the ${widget.difficulty.label.toLowerCase()} board.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _ink.withValues(alpha: 0.74),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedBoard {
  const _GeneratedBoard({
    required this.cells,
    required this.paths,
  });

  final List<List<String>> cells;
  final Map<String, List<_CellPos>> paths;
}

class _Direction {
  const _Direction(this.rowDelta, this.colDelta);

  final int rowDelta;
  final int colDelta;

  static const List<_Direction> values = <_Direction>[
    _Direction(-1, -1),
    _Direction(-1, 0),
    _Direction(-1, 1),
    _Direction(0, -1),
    _Direction(0, 1),
    _Direction(1, -1),
    _Direction(1, 0),
    _Direction(1, 1),
  ];
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _ink.withValues(alpha: 0.86),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CellPos {
  const _CellPos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is _CellPos && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
