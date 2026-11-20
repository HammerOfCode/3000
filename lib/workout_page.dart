import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'commons_photos.dart';
import 'equipment_page.dart';
import 'gemma_routine_ai.dart';
import 'repdb_assets.dart';
import 'repdb_image.dart';
import 'routine.dart';
import 'routine_ai.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
    required this.available,
    this.ai = const GemmaRoutineAi(),
  });

  final Set<Equipment> available;
  final RoutineAi ai;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final Set<BodyArea> _areas = {};
  Experience _experience = Experience.beginner;
  int _minutes = 25;
  List<RoutineItem> _routine = [];
  bool _useAi = false;
  bool? _modelReady;
  double? _downloadProgress;
  String? _downloadError;
  bool _buildingAi = false;
  int _routineVersion = 0;
  String? _routineStatus;
  final _result = GlobalKey();

  @override
  void didUpdateWidget(covariant WorkoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.available, widget.available)) _clearRoutine();
  }

  void _update(VoidCallback change) => setState(() {
    change();
    _clearRoutine();
  });

  void _clearRoutine() {
    _routine = [];
    _routineStatus = null;
    _routineVersion++;
  }

  Future<void> _toggleAi(bool enabled) async {
    _update(() {
      _useAi = enabled;
      _downloadError = null;
      if (enabled && _downloadProgress == null) _modelReady = null;
    });
    if (!enabled || _downloadProgress != null) return;
    var ready = false;
    try {
      ready = await widget.ai.hasModel();
    } catch (_) {
      // A model check can fail if the device's app storage is unavailable.
    }
    if (mounted) setState(() => _modelReady = ready);
  }

  Future<void> _downloadModel() async {
    setState(() {
      _downloadProgress = 0;
      _downloadError = null;
    });
    try {
      await widget.ai.downloadModel((progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      });
      if (mounted) setState(() => _modelReady = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloadError =
              'Download failed. Try again or use the regular builder.';
          _modelReady = false;
        });
      }
    } finally {
      if (mounted) setState(() => _downloadProgress = null);
    }
  }

  Future<void> _buildRoutine() async {
    final baseline = buildRoutine(
      areas: _areas,
      available: widget.available,
      minutes: _minutes,
      experience: _experience,
    );
    if (!_useAi || _modelReady != true) {
      _showRoutine(
        baseline,
        status: _useAi
            ? 'Gemma is unavailable. Used the regular builder.'
            : null,
      );
      return;
    }

    setState(() {
      _clearRoutine();
      _buildingAi = true;
    });
    final version = _routineVersion;
    List<RoutineItem>? result;
    try {
      result = await chooseAiRoutine(
        baseline: baseline,
        available: widget.available,
        minutes: _minutes,
        experience: _experience,
        generate: widget.ai.generate,
      ).timeout(const Duration(seconds: 75));
    } catch (error) {
      if (kDebugMode) debugPrint('Gemma routine failed: $error');
    }
    if (!mounted) return;
    setState(() => _buildingAi = false);
    if (version != _routineVersion) return;
    _showRoutine(
      result ?? baseline,
      status: result == null
          ? 'Gemma could not finish. Used the regular builder.'
          : 'Exercise choices by Gemma',
    );
  }

  void _showRoutine(List<RoutineItem> routine, {String? status}) {
    setState(() {
      _routine = routine;
      _routineStatus = status;
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
    if (!mounted ||
        replacement == null ||
        index >= _routine.length ||
        _routine[index] != item) {
      return;
    }
    setState(() => _routine[index] = RoutineItem(item.movement, replacement));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final areaCount = _areas.length;
    final sets = setsPerExercise(_minutes, _experience, areaCount: areaCount);
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
        Text('Target areas', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Choose $minTargetAreas–$maxTargetAreas areas. $areaCount selected.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Full body'),
              onPressed: () => _update(() {
                _areas
                  ..clear()
                  ..addAll(fullBodyAreas);
              }),
            ),
            for (final area in BodyArea.values)
              FilterChip(
                label: Text(area.label),
                selected: _areas.contains(area),
                onSelected: _areas.contains(area) || areaCount < maxTargetAreas
                    ? (selected) => _update(() {
                        if (selected) {
                          _areas.add(area);
                        } else {
                          _areas.remove(area);
                        }
                      })
                    : null,
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
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use AI'),
          subtitle: Text(
            widget.ai.supported
                ? 'Choose exercises with on-device Gemma.'
                : 'Gemma requires a compatible 64-bit device.',
          ),
          value: _useAi,
          onChanged: widget.ai.supported ? _toggleAi : null,
        ),
        if (_useAi) ...[
          if (_downloadProgress case final progress?) ...[
            LinearProgressIndicator(value: progress),
            Text('Downloading Gemma · ${(progress * 100).round()}%'),
          ] else if (_modelReady == null)
            const Text('Checking for a downloaded model…')
          else if (_modelReady == false)
            OutlinedButton.icon(
              onPressed: _downloadModel,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Gemma · 2.4 GiB'),
            ),
          if (_downloadError case final error?) Text(error),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: areaCount >= minTargetAreas && (!_useAi || !_buildingAi)
              ? _buildRoutine
              : null,
          child: Text(
            _useAi && _buildingAi ? 'Building with Gemma…' : 'Build routine',
          ),
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
          if (_routineStatus case final status?) Text(status),
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
    final photo = exercise.photo;
    final alternatives = _alternatives(item);
    final reps = '${_experience.minReps}–${_experience.maxReps} reps';
    return RepDbImageChoice(
      asset: repDbAsset('flat', repDbExerciseImages[exercise.name]),
      builder: (context, illustration) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: illustration == null && photo == null
            ? null
            : _exercisePhoto(exercise.name, photo, illustration),
        title: Text(exercise.name),
        subtitle: Text(
          '${item.movement.area.label} · ${exercise.equipmentLabel}\n'
          '$reps${exercise.perSide ? ' per side' : ''}',
        ),
        isThreeLine: true,
        trailing: alternatives.isEmpty
            ? null
            : IconButton(
                tooltip: 'Swap ${exercise.name}',
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => _swap(index, alternatives),
              ),
      ),
    );
  }

  Widget _exercisePhoto(
    String name,
    CommonsPhoto? photo,
    String? illustration,
  ) {
    final radius = BorderRadius.circular(8);
    return Tooltip(
      message: 'View $name photo',
      child: InkWell(
        borderRadius: radius,
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(name),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  illustration ?? photo!.assetPath,
                  width: 340,
                  cacheWidth: illustration == null ? 960 : 512,
                ),
                const SizedBox(height: 12),
                if (illustration != null)
                  const RepDbCredit()
                else
                  SelectableText(photo!.credit),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: illustration == null
            ? CommonsThumbnail(photo!, size: 56)
            : ClipRRect(
                borderRadius: radius,
                child: Image.asset(
                  illustration,
                  width: 56,
                  height: 56,
                  cacheWidth: 168,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}
