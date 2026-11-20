import 'package:flutter_test/flutter_test.dart';
import 'package:gym_ready/equipment_page.dart';
import 'package:gym_ready/routine.dart';

void main() {
  test('every area, level and time limit has a bodyweight routine', () {
    for (final area in BodyArea.values) {
      for (final level in Experience.values) {
        for (final minutes in [15, 25, 40]) {
          final routine = buildRoutine(
            area: area,
            available: {},
            minutes: minutes,
            experience: level,
          );
          expect(routine, isNotEmpty);
          for (final item in routine) {
            expect(item.exercise.equipment, isEmpty);
            if (area != BodyArea.fullBody) expect(item.movement.area, area);
          }
        }
      }
    }
  });

  test('equipment requiring two items checks both before recommending it', () {
    List<RoutineItem> chest(Set<Equipment> available) => buildRoutine(
      area: BodyArea.chest,
      available: available,
      minutes: 15,
      experience: Experience.beginner,
    );
    expect(
      chest({Equipment.dumbbells}).first.exercise.name,
      'Dumbbell floor press',
    );
    expect(
      chest({Equipment.dumbbells, Equipment.bench}).first.exercise.name,
      'Dumbbell bench press',
    );
    expect(
      chest({Equipment.chestPress}).first.exercise.name,
      'Machine chest press',
    );
  });

  test('longer full-body routines include more exercises', () {
    List<RoutineItem> fullBody(int minutes) => buildRoutine(
      area: BodyArea.fullBody,
      available: {},
      minutes: minutes,
      experience: Experience.beginner,
    );
    expect(fullBody(15).length, lessThan(fullBody(25).length));
    expect(fullBody(25).length, lessThan(fullBody(40).length));
  });

  test('longer targeted routines adjust their training volume', () {
    for (final experience in Experience.values) {
      final volumes = [
        for (final minutes in [15, 25, 40])
          setsPerExercise(minutes, experience, area: BodyArea.chest),
      ];
      expect(volumes, [2, 3, 4]);
    }
  });

  test('every movement has a bodyweight alternative', () {
    for (final movement in movements) {
      final bodyweightOptions = movement.options.where(
        (exercise) => exercise.isAvailable({}),
      );
      expect(
        bodyweightOptions.length,
        greaterThanOrEqualTo(2),
        reason: movement.options.first.name,
      );
    }
  });
}
