import 'equipment_page.dart';

enum BodyArea {
  fullBody('Full body'),
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core');

  const BodyArea(this.label);
  final String label;
}

enum Experience {
  beginner('Beginner', 8, 12, 60),
  intermediate('Intermediate', 10, 15, 65);

  const Experience(this.label, this.minReps, this.maxReps, this.restSeconds);
  final String label;
  final int minReps;
  final int maxReps;
  final int restSeconds;
}

class Exercise {
  const Exercise(this.name, {this.equipment = const {}, this.perSide = false});

  final String name;
  final Set<Equipment> equipment;
  final bool perSide;

  bool isAvailable(Set<Equipment> available) =>
      available.containsAll(equipment);

  String get equipmentLabel => equipment.isEmpty
      ? 'Bodyweight'
      : equipment.map((e) => e.label).join(' + ');
}

class Movement {
  const Movement(this.area, this.options);
  final BodyArea area;
  final List<Exercise> options;
}

const movements = [
  Movement(BodyArea.legs, [
    Exercise('Leg press', equipment: {Equipment.legPress}),
    Exercise('Dumbbell goblet squat', equipment: {Equipment.dumbbells}),
    Exercise('Bodyweight squat'),
    Exercise('Wall-supported squat'),
    Exercise('Sit-to-stand squat', equipment: {Equipment.bench}),
  ]),
  Movement(BodyArea.chest, [
    Exercise('Machine chest press', equipment: {Equipment.chestPress}),
    Exercise(
      'Dumbbell bench press',
      equipment: {Equipment.dumbbells, Equipment.bench},
    ),
    Exercise('Dumbbell floor press', equipment: {Equipment.dumbbells}),
    Exercise('Knee push-up'),
    Exercise('Wall push-up'),
  ]),
  Movement(BodyArea.back, [
    Exercise('Seated machine row', equipment: {Equipment.row}),
    Exercise('Seated cable row', equipment: {Equipment.cable}),
    Exercise('Dumbbell bent-over row', equipment: {Equipment.dumbbells}),
    Exercise('Prone W raise'),
    Exercise('Reverse snow angel'),
  ]),
  Movement(BodyArea.core, [
    Exercise('Dead bug', perSide: true),
    Exercise('Heel tap', perSide: true),
    Exercise('Supine march', perSide: true),
  ]),
  Movement(BodyArea.shoulders, [
    Exercise('Machine shoulder press', equipment: {Equipment.shoulderPress}),
    Exercise(
      'Standing dumbbell shoulder press',
      equipment: {Equipment.dumbbells},
    ),
    Exercise('Wall slide'),
    Exercise('Prone Y raise'),
  ]),
  Movement(BodyArea.arms, [
    Exercise('Dumbbell biceps curl', equipment: {Equipment.dumbbells}),
    Exercise('Band biceps curl', equipment: {Equipment.band}),
    Exercise('Self-resisted biceps curl', perSide: true),
    Exercise('Self-resisted hammer curl', perSide: true),
  ]),
  Movement(BodyArea.legs, [
    Exercise('Dumbbell Romanian deadlift', equipment: {Equipment.dumbbells}),
    Exercise('Lying leg curl', equipment: {Equipment.legCurl}),
    Exercise('Floor glute bridge'),
    Exercise('Bodyweight good morning'),
  ]),
  Movement(BodyArea.chest, [
    Exercise('Chest press with band around back', equipment: {Equipment.band}),
    Exercise('Incline push-up', equipment: {Equipment.bench}),
    Exercise('Standing palm press'),
    Exercise('Wide wall push-up'),
  ]),
  Movement(BodyArea.back, [
    Exercise('Lat pulldown', equipment: {Equipment.pulldown}),
    Exercise('Cable straight-arm pulldown', equipment: {Equipment.cable}),
    Exercise('Scapular pull-up', equipment: {Equipment.pullUpBar}),
    Exercise('Prone floor pulldown'),
    Exercise('Prone swimmer'),
  ]),
  Movement(BodyArea.core, [
    Exercise('Bird dog', perSide: true),
    Exercise('Bent-knee side plank hip lift', perSide: true),
  ]),
  Movement(BodyArea.shoulders, [
    Exercise('Dumbbell lateral raise', equipment: {Equipment.dumbbells}),
    Exercise('Band lateral raise', equipment: {Equipment.band}),
    Exercise('Prone T raise'),
    Exercise('Side-lying arm raise', perSide: true),
  ]),
  Movement(BodyArea.arms, [
    Exercise('Cable triceps pushdown', equipment: {Equipment.cable}),
    Exercise(
      'Dumbbell overhead triceps extension',
      equipment: {Equipment.dumbbells},
    ),
    Exercise('Close-grip wall push-up'),
    Exercise('Close-grip knee push-up'),
  ]),
  Movement(BodyArea.legs, [
    Exercise(
      'Dumbbell reverse lunge',
      equipment: {Equipment.dumbbells},
      perSide: true,
    ),
    Exercise('Bodyweight reverse lunge', perSide: true),
    Exercise('Supported split squat', perSide: true),
  ]),
];

class RoutineItem {
  const RoutineItem(this.movement, this.exercise);

  final Movement movement;
  final Exercise exercise;
}

List<RoutineItem> buildRoutine({
  required BodyArea area,
  required Set<Equipment> available,
  required int minutes,
  required Experience experience,
}) {
  final sets = setsPerExercise(minutes, experience, area: area);
  final secondsPerExercise = sets * (45 + experience.restSeconds);
  final count = (minutes * 60) ~/ secondsPerExercise;
  return movements
      .where((movement) => area == BodyArea.fullBody || movement.area == area)
      .take(count)
      .map(
        (movement) => RoutineItem(
          movement,
          movement.options.firstWhere(
            (exercise) => exercise.isAvailable(available),
          ),
        ),
      )
      .toList();
}

int setsPerExercise(
  int minutes,
  Experience experience, {
  required BodyArea area,
}) {
  if (minutes <= 15) return 2;
  if (area != BodyArea.fullBody) return minutes >= 40 ? 4 : 3;
  return experience == Experience.intermediate ? 3 : 2;
}
