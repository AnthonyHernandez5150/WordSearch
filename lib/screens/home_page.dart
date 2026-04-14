import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_colors.dart';
import '../controllers/game_controller.dart';
import '../models/board_shape.dart';
import '../models/board_style.dart';
import '../models/difficulty.dart';
import '../models/puzzle_definition.dart';
import '../services/game_feedback.dart';
import '../widgets/glow_orb.dart';
import 'puzzle_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final Difficulty selectedDifficulty = controller.selectedDifficulty;
        final PuzzleDefinition selectedTopic = controller.selectedTopicFor(
          selectedDifficulty,
        );
        final PuzzleDefinition configuredPuzzle = controller
            .configuredPuzzleFor(selectedDifficulty);
        final PuzzleDefinition dailyPuzzle = controller
            .configuredDailyPuzzleFor(selectedDifficulty);
        final List<PuzzleDefinition> topics = controller.themesFor(
          selectedDifficulty,
        );
        final List<int> wordCounts = controller.wordCountOptionsFor(
          selectedDifficulty,
          puzzle: selectedTopic,
        );
        final int selectedWordCount = controller.wordCountFor(
          selectedDifficulty,
          puzzle: selectedTopic,
        );
        final bool dailyCleared = controller.isDailyCleared(selectedDifficulty);
        final BoardStyle selectedBoardStyle = controller.selectedBoardStyle;
        final BoardShapeDefinition selectedShape = controller.selectedShape;
        final List<BoardShapeDefinition> shapes = controller.availableShapes;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: wtAppBackgroundGradient),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  top: -60,
                  left: -32,
                  child: GlowOrb(color: Color(0x2872F5C8), size: 220),
                ),
                const Positioned(
                  right: -90,
                  top: 180,
                  child: GlowOrb(color: Color(0x2A9A5BFF), size: 270),
                ),
                AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: wtBackground,
                    systemNavigationBarIconBrightness: Brightness.light,
                  ),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                18,
                                20,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 12,
                                ),
                                child: IntrinsicHeight(
                                  child: _QuickSetupCard(
                                    difficulty: selectedDifficulty,
                                    boardStyle: selectedBoardStyle,
                                    selectedShape: selectedShape,
                                    selectedTopic: selectedTopic,
                                    configuredPuzzle: configuredPuzzle,
                                    topics: topics,
                                    shapes: shapes,
                                    helpEnabled: controller.helpEnabled,
                                    dailyCleared: dailyCleared,
                                    selectedWordCount: selectedWordCount,
                                    wordCounts: wordCounts,
                                    onSelectBoardStyle:
                                        controller.selectBoardStyle,
                                    onSelectShape: controller.selectShape,
                                    onSelectTopic: controller.selectTopic,
                                    onSelectDifficulty:
                                        controller.selectDifficulty,
                                    onSelectWordCount:
                                        controller.selectWordCount,
                                    onHelpChanged: controller.setHelpEnabled,
                                    onNewGame: () => _openPuzzle(
                                      context,
                                      difficulty: selectedDifficulty,
                                      puzzle: configuredPuzzle,
                                      helpEnabled: controller.helpEnabled,
                                    ),
                                    onDaily: () => _openPuzzle(
                                      context,
                                      difficulty: selectedDifficulty,
                                      puzzle: dailyPuzzle,
                                      helpEnabled: controller.helpEnabled,
                                      daily: true,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPuzzle(
    BuildContext context, {
    required Difficulty difficulty,
    required PuzzleDefinition puzzle,
    required bool helpEnabled,
    bool daily = false,
  }) {
    GameFeedback.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PuzzlePage(
            controller: controller,
            difficulty: difficulty,
            puzzle: puzzle,
            helpEnabled: helpEnabled,
            daily: daily,
          );
        },
      ),
    );
  }
}

class _QuickSetupCard extends StatelessWidget {
  const _QuickSetupCard({
    required this.difficulty,
    required this.boardStyle,
    required this.selectedShape,
    required this.selectedTopic,
    required this.configuredPuzzle,
    required this.topics,
    required this.shapes,
    required this.helpEnabled,
    required this.dailyCleared,
    required this.selectedWordCount,
    required this.wordCounts,
    required this.onSelectBoardStyle,
    required this.onSelectShape,
    required this.onSelectTopic,
    required this.onSelectDifficulty,
    required this.onSelectWordCount,
    required this.onHelpChanged,
    required this.onNewGame,
    required this.onDaily,
  });

  final Difficulty difficulty;
  final BoardStyle boardStyle;
  final BoardShapeDefinition selectedShape;
  final PuzzleDefinition selectedTopic;
  final PuzzleDefinition configuredPuzzle;
  final List<PuzzleDefinition> topics;
  final List<BoardShapeDefinition> shapes;
  final bool helpEnabled;
  final bool dailyCleared;
  final int selectedWordCount;
  final List<int> wordCounts;
  final ValueChanged<BoardStyle> onSelectBoardStyle;
  final ValueChanged<BoardShapeDefinition> onSelectShape;
  final ValueChanged<PuzzleDefinition> onSelectTopic;
  final ValueChanged<Difficulty> onSelectDifficulty;
  final ValueChanged<int> onSelectWordCount;
  final ValueChanged<bool> onHelpChanged;
  final VoidCallback onNewGame;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: wtWhite.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x2AF5F7FB)),
              ),
              child: Image.asset(
                'assets/branding/wordtrail_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Word',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: wtWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Trail',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: wtCyan,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find words. Follow the path.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0x99F5F7FB),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _HomeBrandStamp(),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Topic'),
        const SizedBox(height: 10),
        DropdownButtonFormField<PuzzleDefinition>(
          initialValue: selectedTopic,
          dropdownColor: wtSurfaceElevated,
          iconEnabledColor: Colors.white,
          decoration: _fieldDecoration(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          items: topics.map((PuzzleDefinition topic) {
            return DropdownMenuItem<PuzzleDefinition>(
              value: topic,
              child: Text(topic.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (PuzzleDefinition? value) {
            if (value == null) {
              return;
            }
            GameFeedback.tap();
            onSelectTopic(value);
          },
        ),
        const SizedBox(height: 22),
        _SectionLabel(label: 'Difficulty'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Difficulty.values.map((Difficulty item) {
            final bool selected = item == difficulty;
            return _SelectPill(
              label: item.label,
              icon: item.icon,
              accent: item.accent,
              selected: selected,
              onTap: () {
                GameFeedback.tap();
                onSelectDifficulty(item);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _SectionLabel(label: 'Board style'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: BoardStyle.values.map((BoardStyle item) {
            final bool selected = item == boardStyle;
            return _SelectPill(
              label: item.label,
              icon: item == BoardStyle.classic
                  ? Icons.grid_view_rounded
                  : Icons.interests_rounded,
              accent: item == BoardStyle.classic ? wtBlue : wtPurple,
              selected: selected,
              onTap: () {
                GameFeedback.tap();
                onSelectBoardStyle(item);
              },
            );
          }).toList(),
        ),
        if (boardStyle == BoardStyle.shaped) ...<Widget>[
          const SizedBox(height: 22),
          _SectionLabel(label: 'Shape'),
          const SizedBox(height: 10),
          DropdownButtonFormField<BoardShapeDefinition>(
            initialValue: selectedShape,
            dropdownColor: wtSurfaceElevated,
            iconEnabledColor: Colors.white,
            decoration: _fieldDecoration(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            items: shapes.map((BoardShapeDefinition shape) {
              return DropdownMenuItem<BoardShapeDefinition>(
                value: shape,
                child: Text(shape.label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (BoardShapeDefinition? value) {
              if (value == null) {
                return;
              }
              GameFeedback.tap();
              onSelectShape(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Shaped boards keep a readable grid and tune word counts to the silhouette.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xCCFFFFFF),
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _SectionLabel(label: 'Number of words'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: wordCounts.map((int count) {
            return _CountPill(
              count: count,
              selected: count == selectedWordCount,
              onTap: () {
                GameFeedback.tap();
                onSelectWordCount(count);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Hints',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      helpEnabled ? 'On during play' : 'Off for a clean run',
                      style: const TextStyle(color: Color(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: helpEnabled,
                activeThumbColor: difficulty.accent,
                onChanged: (bool value) {
                  GameFeedback.tap();
                  onHelpChanged(value);
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: onNewGame,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: wsInk,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('New game'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDaily,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x55FFFFFF)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: Icon(
                  dailyCleared
                      ? Icons.verified_rounded
                      : Icons.calendar_today_rounded,
                  size: 18,
                ),
                label: Text(
                  dailyCleared ? 'Daily cleared' : 'Daily puzzle',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      hintText: 'Choose a topic',
      hintStyle: const TextStyle(color: Color(0xB3FFFFFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x26FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: difficulty.accent, width: 1.4),
      ),
    );
  }
}

class _HomeBrandStamp extends StatelessWidget {
  const _HomeBrandStamp();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: <Color>[wtMint, wtCyan, wtBlue, wtPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: wtCyan.withValues(alpha: 0.22),
              blurRadius: 26,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: wsInk.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(
              'assets/branding/wordtrail_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: Colors.white),
    );
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : const Color(0x30FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: selected ? Colors.white : accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 1 : 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.white : const Color(0x30FFFFFF),
          ),
        ),
        child: Text(
          '$count words',
          style: TextStyle(
            color: selected ? wsInk : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
