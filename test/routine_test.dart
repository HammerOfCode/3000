import 'package:flutter_test/flutter_test.dart';
import 'package:gym_ready/equipment_page.dart';
import 'package:gym_ready/routine.dart';

void main() {
  test('each selected area is covered at every level and time limit', () {
    const selections = [
      {BodyArea.chest, BodyArea.back},
      {BodyArea.legs, BodyArea.arms, BodyArea.core},
      {BodyArea.chest, BodyArea.back, BodyArea.shoulders, BodyArea.arms},
      fullBodyAreas,
    ];
    for (final areas in selections) {
      for (final level in Experience.values) {
        for (final minutes in [15, 25, 40]) {
          final routine = buildRoutine(
            areas: areas,
            available: {},
            minutes: minutes,
            experience: level,
          );
          expect(routine.map((item) => item.movement.area).toSet(), areas);
          for (final item in routine) {
            expect(item.exercise.equipment, isEmpty);
          }
        }
      }
    }
  });

  test('generator rejects selections outside the two to four area limit', () {
    for (final areas in [
      <BodyArea>{},
      {BodyArea.chest},
      {...fullBodyAreas, BodyArea.arms},
    ]) {
      expect(
        () => buildRoutine(
          areas: areas,
          available: {},
          minutes: 25,
          experience: Experience.beginner,
        ),
        throwsArgumentError,
      );
    }
  });

  test('equipment requiring two items checks both before recommending it', () {
    List<RoutineItem> chest(Set<Equipment> available) => buildRoutine(
      areas: {BodyArea.chest, BodyArea.core},
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
      areas: fullBodyAreas,
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
          setsPerExercise(minutes, experience, areaCount: 2),
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

  test('new catalog machines affect matching workout recommendations', () {
    const machines = {Equipment.hackSquat, Equipment.abCrunch};
    final routine = buildRoutine(
      areas: {BodyArea.legs, BodyArea.core},
      available: machines,
      minutes: 15,
      experience: Experience.beginner,
    );
    expect(
      routine.map((item) => item.exercise.name),
      containsAll(['Hack squat', 'Machine ab crunch']),
    );
    expect(
      routine.every((item) => item.exercise.isAvailable(machines)),
      isTrue,
    );
  });
}
