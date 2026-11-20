import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'equipment_page.dart';
import 'routine.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key, required this.available});

  final Set<Equipment> available;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  BodyArea _area = BodyArea.fullBody;
  Experience _experience = Experience.beginner;
  int _minutes = 25;
  List<RoutineItem> _routine = [];
  final _result = GlobalKey();

  @override
  void didUpdateWidget(covariant WorkoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.available, widget.available)) _routine = [];
  }

  void _update(VoidCallback change) => setState(() {
    change();
    _routine = [];
  });

  void _buildRoutine() {
    setState(() {
      _routine = buildRoutine(
        area: _area,
        available: widget.available,
        minutes: _minutes,
        experience: _experience,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _result.currentContext;
      if (resultContext != null) {
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 220),
        );
      }
    });
  }

  List<Exercise> _alternatives(RoutineItem item) => item.movement.options
      .where(
        (option) =>
            option != item.exercise && option.isAvailable(widget.available),
      )
      .toList();

  Future<void> _swap(int index, List<Exercise> alternatives) async {
    final item = _routine[index];
    final replacement = await showModalBottomSheet<Exercise>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Choose a replacement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final option in alternatives)
              ListTile(
                title: Text(option.name),
                subtitle: Text(option.equipmentLabel),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || replacement == null) return;
    setState(() => _routine[index] = RoutineItem(item.movement, replacement));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sets = setsPerExercise(_minutes, _experience, area: _area);
    final equipmentCount = widget.available.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Build a workout',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.checklist, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                equipmentCount == 0
                    ? 'Bodyweight only. Add gear in Equipment anytime.'
                    : '$equipmentCount equipment ${equipmentCount == 1 ? 'type' : 'types'} available',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Target area', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final area in BodyArea.values)
              ChoiceChip(
                label: Text(area.label),
                selected: _area == area,
                onSelected: (selected) {
                  if (selected) _update(() => _area = area);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Experience', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final level in Experience.values)
              ChoiceChip(
                label: Text(level.label),
                selected: _experience == level,
                onSelected: (selected) {
                  if (selected) _update(() => _experience = level);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Time limit', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final minutes in [15, 25, 40])
              ChoiceChip(
                label: Text('$minutes min'),
                selected: _minutes == minutes,
                onSelected: (selected) {
                  if (selected) _update(() => _minutes = minutes);
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _buildRoutine,
          child: const Text('Build routine'),
        ),
        if (_routine.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Your routine',
            key: _result,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${_routine.length} exercises · $sets sets each · ${_experience.restSeconds}s rest between sets',
          ),
          const SizedBox(height: 12),
          for (final (index, item) in _routine.indexed)
            _exerciseTile(index, item),
        ],
      ],
    );
  }

  Widget _exerciseTile(int index, RoutineItem item) {
    final exercise = item.exercise;
    final alternatives = _alternatives(item);
    final reps = '${_experience.minReps}–${_experience.maxReps} reps';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(exercise.name),
      subtitle: Text(
        '${exercise.equipmentLabel}\n$reps${exercise.perSide ? ' per side' : ''}',
      ),
      isThreeLine: true,
      trailing: alternatives.isEmpty
          ? null
          : IconButton(
              tooltip: 'Swap ${exercise.name}',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _swap(index, alternatives),
            ),
    );
  }
}
