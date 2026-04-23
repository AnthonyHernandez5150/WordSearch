import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_colors.dart';
import '../app/formatters.dart';
import '../controllers/game_controller.dart';
import '../models/board_shape.dart';
import '../models/board_style.dart';
import '../models/difficulty.dart';
import '../models/paused_puzzle_snapshot.dart';
import '../models/puzzle_definition.dart';
import '../models/session_snapshot.dart';
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
        final Difficulty dailyDifficulty = controller.dailyDifficulty;
        final PuzzleDefinition selectedTopic = controller.selectedTopicFor(
          selectedDifficulty,
        );
        final PuzzleDefinition configuredPuzzle = controller
            .configuredPuzzleFor(selectedDifficulty);
        final PuzzleDefinition dailyPuzzle = controller.configuredDailyPuzzle();
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
        final bool dailyCleared = controller.isDailyClearedToday;
        final BoardStyle selectedBoardStyle = controller.selectedBoardStyle;
        final BoardShapeDefinition selectedShape = controller.selectedShape;
        final List<BoardShapeDefinition> shapes = controller.availableShapes;
        final SessionSnapshot snapshot = controller.snapshot;
        final PausedPuzzleSnapshot? pausedPuzzle = controller.pausedPuzzle;

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
                                    snapshot: snapshot,
                                    pausedPuzzle: pausedPuzzle,
                                    helpEnabled: controller.helpEnabled,
                                    soundEnabled: controller.soundEnabled,
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
                                    onSoundChanged: controller.setSoundEnabled,
                                    onResumePaused: pausedPuzzle == null
                                        ? null
                                        : () => _resumePausedPuzzle(
                                            context,
                                            pausedPuzzle,
                                          ),
                                    onNewGame: () => _openPuzzle(
                                      context,
                                      difficulty: selectedDifficulty,
                                      puzzle: configuredPuzzle,
                                      helpEnabled: controller.helpEnabled,
                                    ),
                                    onDaily: () => _openPuzzle(
                                      context,
                                      difficulty: dailyDifficulty,
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
    GameFeedback.soft();
    controller.clearPausedPuzzle();
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

  void _resumePausedPuzzle(
    BuildContext context,
    PausedPuzzleSnapshot pausedPuzzle,
  ) {
    GameFeedback.resume();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PuzzlePage(
            controller: controller,
            difficulty: pausedPuzzle.difficulty,
            puzzle: pausedPuzzle.requestedPuzzle,
            helpEnabled: pausedPuzzle.helpEnabled,
            daily: pausedPuzzle.daily,
            resumeSnapshot: pausedPuzzle,
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
    required this.snapshot,
    required this.pausedPuzzle,
    required this.helpEnabled,
    required this.soundEnabled,
    required this.dailyCleared,
    required this.selectedWordCount,
    required this.wordCounts,
    required this.onSelectBoardStyle,
    required this.onSelectShape,
    required this.onSelectTopic,
    required this.onSelectDifficulty,
    required this.onSelectWordCount,
    required this.onHelpChanged,
    required this.onSoundChanged,
    required this.onResumePaused,
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
  final SessionSnapshot snapshot;
  final PausedPuzzleSnapshot? pausedPuzzle;
  final bool helpEnabled;
  final bool soundEnabled;
  final bool dailyCleared;
  final int selectedWordCount;
  final List<int> wordCounts;
  final ValueChanged<BoardStyle> onSelectBoardStyle;
  final ValueChanged<BoardShapeDefinition> onSelectShape;
  final ValueChanged<PuzzleDefinition> onSelectTopic;
  final ValueChanged<Difficulty> onSelectDifficulty;
  final ValueChanged<int> onSelectWordCount;
  final ValueChanged<bool> onHelpChanged;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback? onResumePaused;
  final VoidCallback onNewGame;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = topics.indexWhere(
      (PuzzleDefinition topic) => topic.name == selectedTopic.name,
    );
    final int rotationPosition = selectedIndex == -1 ? 1 : selectedIndex + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const _BrandIcon(size: 54),
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
        if (pausedPuzzle != null && onResumePaused != null) ...<Widget>[
          _ResumePausedCard(
            snapshot: pausedPuzzle!,
            onResume: onResumePaused!,
            accent: difficulty.accent,
          ),
          const SizedBox(height: 22),
        ],
        _StreakPanel(snapshot: snapshot),
        const SizedBox(height: 22),
        _SectionLabel(label: 'Puzzle rotation'),
        const SizedBox(height: 10),
        DropdownButtonFormField<PuzzleDefinition>(
          initialValue: selectedTopic,
          dropdownColor: wtSurfaceElevated,
          iconEnabledColor: Colors.white,
          decoration: _fieldDecoration('Choose a puzzle pack'),
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
        const SizedBox(height: 8),
        Text(
          'Regular play: board $rotationPosition of ${topics.length} in ${difficulty.label}. Next board keeps moving through this rotation.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xB8F5F7FB),
            height: 1.3,
          ),
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
            decoration: _fieldDecoration('Choose a shape'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: <Widget>[
              _SettingsToggleRow(
                title: 'Hints',
                subtitle: helpEnabled
                    ? 'On during play'
                    : 'Off for a clean run',
                value: helpEnabled,
                accent: difficulty.accent,
                onChanged: onHelpChanged,
              ),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              _SettingsToggleRow(
                title: 'Sound effects',
                subtitle: soundEnabled
                    ? 'Clicks and win sounds on'
                    : 'Quiet mode on',
                value: soundEnabled,
                accent: wtCyan,
                onChanged: onSoundChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _DailyTrailNote(dailyCleared: dailyCleared),
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
                  dailyCleared ? 'Daily done' : 'Daily Trail',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      hintText: hintText,
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

class _DailyTrailNote extends StatelessWidget {
  const _DailyTrailNote({required this.dailyCleared});

  final bool dailyCleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: wtCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: wtCyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            dailyCleared
                ? Icons.verified_rounded
                : Icons.calendar_today_rounded,
            color: wtCyan,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dailyCleared
                  ? 'Daily Trail cleared. Regular boards still rotate below.'
                  : 'Daily Trail is one shared puzzle each day, separate from the regular board rotation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xCCF5F7FB),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumePausedCard extends StatelessWidget {
  const _ResumePausedCard({
    required this.snapshot,
    required this.onResume,
    required this.accent,
  });

  final PausedPuzzleSnapshot snapshot;
  final VoidCallback onResume;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pause_circle_filled_rounded,
              color: wtWhite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Paused game waiting',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: wtWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.activePuzzle.name} | ${snapshot.difficulty.label} | ${formatDuration(snapshot.elapsed)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xBFF5F7FB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onResume,
            style: FilledButton.styleFrom(
              backgroundColor: wtWhite,
              foregroundColor: wsInk,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xCCFFFFFF)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: accent,
            onChanged: (bool nextValue) {
              GameFeedback.tap();
              onChanged(nextValue);
            },
          ),
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final double outerRadius = size * 0.33;
    final double innerRadius = size * 0.24;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        gradient: const LinearGradient(
          colors: <Color>[wtMint, wtCyan, wtBlue, wtPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: wtCyan.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: wsInk.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.09),
          child: Image.asset(
            'assets/branding/wordtrail_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.snapshot});

  final SessionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final int dailyStreak = snapshot.currentDailyStreak;
    final String headline = dailyStreak > 0
        ? '$dailyStreak ${_dayLabel(dailyStreak)} trail'
        : 'Start today';
    final String subtitle = dailyStreak > 0
        ? 'Finish tomorrow\'s Daily Trail to keep it alive.'
        : 'Clear the Daily Trail to begin your streak.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: wtSurfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x26F5F7FB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: wtCyan.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: wtTrailGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: wtWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: wtWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xA8F5F7FB),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ProgressPill(
                label: 'Best ${snapshot.bestDailyStreak}d',
                accent: wtMint,
              ),
              _ProgressPill(
                label: 'Clean ${snapshot.cleanStreak}',
                accent: wtCyan,
              ),
              _ProgressPill(
                label: '${snapshot.boardsCleared} boards',
                accent: wtPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dayLabel(int count) => count == 1 ? 'day' : 'days';
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: wtWhite,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
