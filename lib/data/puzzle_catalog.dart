import '../models/difficulty.dart';
import '../models/puzzle_definition.dart';

class PuzzleCatalog {
  const PuzzleCatalog._();

  // Curated built-in packs stay in Dart for now so startup remains synchronous
  // and bad puzzle data is caught by debug assertions before release builds.
  static final Map<Difficulty, List<PuzzleDefinition>> _catalog =
      <Difficulty, List<PuzzleDefinition>>{
        Difficulty.calm: _calmPuzzles,
        Difficulty.explorer: _explorerPuzzles,
        Difficulty.expert: _expertPuzzles,
      };

  static List<PuzzleDefinition> allFor(Difficulty difficulty) {
    _debugValidateCatalog();
    return List<PuzzleDefinition>.unmodifiable(_puzzlesFor(difficulty));
  }

  static PuzzleDefinition byIndex(Difficulty difficulty, int index) {
    final List<PuzzleDefinition> boards = _puzzlesFor(difficulty);
    return boards[index % boards.length];
  }

  static PuzzleDefinition nextFor(
    Difficulty difficulty,
    PuzzleDefinition current,
  ) {
    final List<PuzzleDefinition> boards = _puzzlesFor(difficulty);
    final int currentIndex = boards.indexWhere(
      (PuzzleDefinition puzzle) => puzzle.name == current.name,
    );
    final int nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % boards.length;
    return boards[nextIndex];
  }

  static PuzzleDefinition dailyFor(Difficulty difficulty, DateTime date) {
    return byIndex(difficulty, _dayNumber(date));
  }

  static List<PuzzleDefinition> _puzzlesFor(Difficulty difficulty) {
    final List<PuzzleDefinition>? puzzles = _catalog[difficulty];
    if (puzzles == null || puzzles.isEmpty) {
      throw StateError('No puzzles configured for difficulty: $difficulty');
    }
    return puzzles;
  }

  static int _dayNumber(DateTime date) {
    final DateTime utcDay = DateTime.utc(date.year, date.month, date.day);
    return utcDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  static void _debugValidateCatalog() {
    assert(() {
      for (final Difficulty difficulty in Difficulty.values) {
        final List<PuzzleDefinition> puzzles = _puzzlesFor(difficulty);
        final Set<String> puzzleNames = <String>{};
        for (final PuzzleDefinition puzzle in puzzles) {
          assert(
            puzzleNames.add(puzzle.name),
            'Duplicate puzzle name in $difficulty: ${puzzle.name}',
          );
          assert(puzzle.size >= 4, '${puzzle.name} needs size at least 4');
          assert(
            puzzle.words.length >= 4,
            '${puzzle.name} needs at least 4 words',
          );
          final Set<String> words = <String>{};
          for (final String word in puzzle.words) {
            assert(word.isNotEmpty, '${puzzle.name} has an empty word');
            assert(
              word == word.toUpperCase(),
              '${puzzle.name} word must be uppercase: $word',
            );
            assert(
              RegExp(r'^[A-Z]+$').hasMatch(word),
              '${puzzle.name} word must use A-Z only: $word',
            );
            assert(
              word.length <= puzzle.size,
              '${puzzle.name} word is longer than board: $word',
            );
            assert(words.add(word), '${puzzle.name} has duplicate word: $word');
          }
        }
      }
      return true;
    }());
  }

  static const List<PuzzleDefinition> _calmPuzzles = <PuzzleDefinition>[
    PuzzleDefinition(
      name: 'Starter Lounge',
      headline: 'Warm-up rooms built for relaxed wins.',
      themeLine: 'Slow entry, clear words, and low-pressure swipes.',
      size: 8,
      words: <String>[
        'PUZZLE',
        'SEARCH',
        'LETTER',
        'PLAYER',
        'BOARDS',
        'RIDDLE',
        'TILES',
        'SOLVE',
        'QUEST',
        'FOCUS',
      ],
      tip: 'Trace calm, readable words without rushing the board.',
    ),
    PuzzleDefinition(
      name: 'Garden Glow',
      headline: 'A softer pack with breezy nature words.',
      themeLine: 'Petals, breeze, and quiet phone-play energy.',
      size: 8,
      words: <String>[
        'BLOOM',
        'PETAL',
        'BREEZE',
        'GARDEN',
        'SPRIG',
        'SUNNY',
        'MOSS',
        'LEAF',
        'ROOTS',
        'GLADE',
      ],
      tip:
          'Follow steady rows and diagonals while the filler letters stay friendly.',
    ),
    PuzzleDefinition(
      name: 'Coffee Break',
      headline: 'Short words and cozy rhythm for quick clears.',
      themeLine: 'Warm mugs, light snacks, and easy-repeat sessions.',
      size: 8,
      words: <String>[
        'LATTE',
        'MUGS',
        'TOAST',
        'COZY',
        'BEANS',
        'CREAM',
        'SUGAR',
        'CUP',
        'STEAM',
        'BISCUIT',
      ],
      tip: 'Perfect for one-thumb play and fast restarts between runs.',
    ),
    PuzzleDefinition(
      name: 'Rainy Desk',
      headline: 'Quiet focus words for a soft little reset.',
      themeLine: 'Pages, pencils, warm lamps, and rainy window glass.',
      size: 8,
      words: <String>[
        'PAPER',
        'PENCIL',
        'NOTES',
        'LAMP',
        'BOOKS',
        'QUIET',
        'RAIN',
        'DESK',
        'STUDY',
        'IDEAS',
      ],
      tip: 'A good calm board should feel readable before it feels clever.',
    ),
    PuzzleDefinition(
      name: 'Snack Table',
      headline: 'Small food words with friendly rhythm.',
      themeLine: 'Fruit, crackers, and quick clears without pressure.',
      size: 8,
      words: <String>[
        'APPLE',
        'BERRY',
        'MELON',
        'CHIPS',
        'SALSA',
        'HONEY',
        'PLATE',
        'JUICE',
        'BREAD',
        'SNACK',
      ],
      tip: 'Short familiar words keep the focus on flow, not squinting.',
    ),
  ];

  static const List<PuzzleDefinition> _explorerPuzzles = <PuzzleDefinition>[
    PuzzleDefinition(
      name: 'Atlas Lounge',
      headline: 'The balanced everyday board for repeat play.',
      themeLine: 'Clean geometry, diagonals, and a strong first session.',
      size: 10,
      words: <String>[
        'SEARCH',
        'PUZZLE',
        'WORD',
        'PLAY',
        'FIND',
        'CLUE',
        'TRACE',
        'LINE',
        'HIDDEN',
        'BOARD',
        'CLUES',
        'SEEKER',
      ],
      tip:
          'Drag across the board to reveal words hidden inside filler letters.',
    ),
    PuzzleDefinition(
      name: 'Neon Market',
      headline: 'More motion, more signage, more visual texture.',
      themeLine: 'Lanterns, stalls, ribbons, and bright city energy.',
      size: 10,
      words: <String>[
        'STALLS',
        'TOKENS',
        'LANTERN',
        'RIBBON',
        'FRUIT',
        'SPICES',
        'MARKET',
        'BARGAIN',
        'VENDOR',
        'CANOPY',
        'BAZAAR',
        'SIGNAGE',
      ],
      tip:
          'Explorer boards reward smooth diagonals and longer side-to-side drags.',
    ),
    PuzzleDefinition(
      name: 'Coastline Run',
      headline: 'A breezy pack with long edges and ocean words.',
      themeLine: 'Harbor lights, shells, compass lines, and sea air.',
      size: 10,
      words: <String>[
        'HARBOR',
        'SEASHELL',
        'TIDELINE',
        'COMPASS',
        'ANCHOR',
        'MARINER',
        'LIGHTS',
        'OCEAN',
        'DRIFT',
        'COVE',
        'BEACON',
        'SURF',
      ],
      tip: 'Watch for diagonals that skim the outer rim before cutting inward.',
    ),
    PuzzleDefinition(
      name: 'Metro Lines',
      headline: 'Transit words with a little more direction mixing.',
      themeLine: 'Stations, signals, tunnels, and late-night platforms.',
      size: 10,
      words: <String>[
        'METRO',
        'TUNNEL',
        'TRACK',
        'SIGNAL',
        'ROUTE',
        'TICKET',
        'PLATFORM',
        'RAILS',
        'COMMUTE',
        'STATION',
        'EXPRESS',
        'SUBWAY',
      ],
      tip: 'Medium words hide better when the board uses every direction.',
    ),
    PuzzleDefinition(
      name: 'Arcade Night',
      headline: 'Bright game-room words with quick visual hooks.',
      themeLine: 'Tokens, combos, pixels, prizes, and neon reflexes.',
      size: 10,
      words: <String>[
        'ARCADE',
        'TOKEN',
        'COMBO',
        'PIXEL',
        'PRIZE',
        'LEVEL',
        'BONUS',
        'PLAYER',
        'BUTTON',
        'CABINET',
        'LASER',
        'SCORE',
      ],
      tip: 'Explorer should surprise you sometimes, not fight you every swipe.',
    ),
  ];

  static const List<PuzzleDefinition> _expertPuzzles = <PuzzleDefinition>[
    PuzzleDefinition(
      name: 'Night Sprint',
      headline: 'Dense letter fields built for focused clears.',
      themeLine:
          'Mixed word lengths, sneaky diagonals, and one more run energy.',
      size: 13,
      words: <String>[
        'CROSSWORDS',
        'DISCOVER',
        'LIGHTS',
        'QUICK',
        'BRAIN',
        'HIDDEN',
        'TRACE',
        'GRID',
        'SCAN',
        'VICTORY',
        'HUNTER',
        'SPARK',
        'LOGIC',
        'FOCUS',
        'MAZE',
        'NERVE',
      ],
      tip:
          'Expert hides short and medium words inward instead of making every answer huge.',
    ),
    PuzzleDefinition(
      name: 'Signal Forge',
      headline: 'Harder grids with sharper, industrial word shapes.',
      themeLine: 'Power lines, sparks, short traps, and machine-room pressure.',
      size: 13,
      words: <String>[
        'BLACKOUT',
        'CIRCUIT',
        'OVERDRIVE',
        'FORGE',
        'VOLT',
        'WIRE',
        'PULSE',
        'SPARK',
        'LASER',
        'SHIFT',
        'GRID',
        'CODE',
        'POWER',
        'FUSE',
        'STATIC',
        'PLASMA',
      ],
      tip:
          'Expert boards should feel hidden, not merely stuffed with long words.',
    ),
    PuzzleDefinition(
      name: 'Deep Orbit',
      headline: 'A bigger pack with crisp sci-fi word shapes.',
      themeLine: 'Charts, telemetry, satellites, and quiet vacuum.',
      size: 13,
      words: <String>[
        'GRAVITY',
        'ECLIPSE',
        'COSMIC',
        'ORBIT',
        'MOON',
        'NOVA',
        'COMET',
        'QUASAR',
        'ASTRO',
        'SATURN',
        'NEBULA',
        'ROVER',
        'SOLAR',
        'METEOR',
        'STAR',
        'VOID',
      ],
      tip:
          'Short space words become tricky when they are reversed and tucked inward.',
    ),
    PuzzleDefinition(
      name: 'Cipher Vault',
      headline: 'Code-room words with decoy-friendly shapes.',
      themeLine: 'Locks, keys, codes, hashes, and words that almost match.',
      size: 13,
      words: <String>[
        'PASSWORD',
        'FIREWALL',
        'CIPHER',
        'VAULT',
        'TOKEN',
        'LOGIN',
        'CACHE',
        'HASH',
        'KEYS',
        'PROXY',
        'SCRIPT',
        'ROUTER',
        'PACKET',
        'TRACE',
        'CRYPT',
        'ALERT',
      ],
      tip:
          'This pack is built for hesitation: real words, near words, and hidden routes.',
    ),
    PuzzleDefinition(
      name: 'Shadow Garden',
      headline: 'Nature words that hide better than they look.',
      themeLine: 'Thorns, roots, moss, vines, and darker garden paths.',
      size: 13,
      words: <String>[
        'THICKET',
        'BRAMBLE',
        'CANOPY',
        'ROOT',
        'MOSS',
        'VINE',
        'FERN',
        'THORN',
        'BARK',
        'SPORE',
        'CLOVER',
        'MULCH',
        'SHADE',
        'BLOOM',
        'PETAL',
        'STEM',
      ],
      tip:
          'Tiny natural words can be harder than long ones when the board fights back.',
    ),
  ];
}
