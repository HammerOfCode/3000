import 'dart:convert';

import 'equipment_page.dart';
import 'routine.dart';

abstract interface class RoutineAi {
  bool get supported;
  Future<bool> hasModel();
  Future<void> downloadModel(void Function(double) onProgress);
  Future<String> generate(String prompt);
}

Future<List<RoutineItem>?> chooseAiRoutine({
  required List<RoutineItem> baseline,
  required Set<Equipment> available,
  required Experience experience,
  required int minutes,
  required Future<String> Function(String prompt) generate,
}) async {
  final options = [
    for (final item in baseline)
      item.movement.options
          .where((exercise) => exercise.isAvailable(available))
          .toList(),
  ];
  final slots = [
    for (final (index, choices) in options.indexed)
      {
        'slot': index + 1,
        'area': baseline[index].movement.area.label,
        'options': {
          for (final (choice, exercise) in choices.indexed)
            '${choice + 1}': '${exercise.name} (${exercise.equipmentLabel})',
        },
      },
  ];
  final response = (await generate(
    'Choose exercises for a ${experience.label} workout of up to $minutes '
    'minutes. Select one option for each of the ${slots.length} numbered '
    'slots. Prefer exercises that suit the experience level and use available '
    'equipment where useful. Return only a JSON object with the key "choices". '
    'Its value must be an array of exactly ${slots.length} integers. Each '
    'integer is the option ID for the corresponding slot, in slot order. '
    'Slots: ${jsonEncode(slots)}',
  )).trim();
  final fenced = RegExp(
    r'^\x60{3}(?:json)?\s*([\s\S]*?)\s*\x60{3}$',
  ).firstMatch(response);
  final Object? decoded;
  try {
    decoded = jsonDecode(fenced?.group(1) ?? response);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic> || decoded.length != 1) return null;
  final picks = decoded['choices'];
  if (picks is! List || picks.length != baseline.length) return null;

  final routine = <RoutineItem>[];
  for (final (index, choice) in picks.indexed) {
    if (choice is! int || choice < 1 || choice > options[index].length) {
      return null;
    }
    routine.add(
      RoutineItem(baseline[index].movement, options[index][choice - 1]),
    );
  }
  return routine;
}
