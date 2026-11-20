import 'commons_photos.dart';
import 'equipment_page.dart';

enum BodyArea {
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core');

  const BodyArea(this.label);
  final String label;
}

const minTargetAreas = 2;
const maxTargetAreas = 4;
const fullBodyAreas = {
  BodyArea.legs,
  BodyArea.chest,
  BodyArea.back,
  BodyArea.core,
};

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
  const Exercise(
    this.name, {
    this.equipment = const {},
    this.perSide = false,
    this.photo,
  });

  final String name;
  final Set<Equipment> equipment;
  final bool perSide;
  final CommonsPhoto? photo;

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
    Exercise(
      'Leg press',
      equipment: {Equipment.legPress},
      photo: CommonsPhoto.legPress,
    ),
    Exercise(
      'Hack squat',
      equipment: {Equipment.hackSquat},
      photo: CommonsPhoto.hackSquat,
    ),
    Exercise(
      'Leg extension',
      equipment: {Equipment.legExtension},
      photo: CommonsPhoto.legExtension,
    ),
    Exercise('Dumbbell goblet squat', equipment: {Equipment.dumbbells}),
    Exercise('Bodyweight squat', photo: CommonsPhoto.bodyweightSquat),
    Exercise('Wall-supported squat'),
    Exercise('Sit-to-stand squat', equipment: {Equipment.bench}),
  ]),
  Movement(BodyArea.chest, [
    Exercise(
      'Machine chest press',
      equipment: {Equipment.chestPress},
      photo: CommonsPhoto.chestPress,
    ),
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
    Exercise(
      'Seated cable row',
      equipment: {Equipment.cable},
      photo: CommonsPhoto.cableRow,
    ),
    Exercise('Dumbbell bent-over row', equipment: {Equipment.dumbbells}),
    Exercise('Prone W raise'),
    Exercise('Reverse snow angel'),
  ]),
  Movement(BodyArea.core, [
    Exercise('Machine ab crunch', equipment: {Equipment.abCrunch}),
    Exercise('Dead bug', perSide: true),
    Exercise('Heel tap', perSide: true),
    Exercise('Supine march', perSide: true),
  ]),
  Movement(BodyArea.shoulders, [
    Exercise(
      'Machine shoulder press',
      equipment: {Equipment.shoulderPress},
      photo: CommonsPhoto.shoulderPress,
    ),
    Exercise(
      'Standing dumbbell shoulder press',
      equipment: {Equipment.dumbbells},
    ),
    Exercise('Wall slide'),
    Exercise('Prone Y raise'),
  ]),
  Movement(BodyArea.arms, [
    Exercise('Machine biceps curl', equipment: {Equipment.bicepsCurl}),
    Exercise('Dumbbell biceps curl', equipment: {Equipment.dumbbells}),
    Exercise('Band biceps curl', equipment: {Equipment.band}),
    Exercise('Self-resisted biceps curl', perSide: true),
    Exercise('Self-resisted hammer curl', perSide: true),
  ]),
  Movement(BodyArea.legs, [
    Exercise('Dumbbell Romanian deadlift', equipment: {Equipment.dumbbells}),
    Exercise(
      'Lying leg curl',
      equipment: {Equipment.legCurl},
      photo: CommonsPhoto.lyingLegCurl,
    ),
    Exercise('Seated leg curl', equipment: {Equipment.seatedLegCurl}),
    Exercise('Floor glute bridge'),
    Exercise('Bodyweight good morning'),
  ]),
  Movement(BodyArea.chest, [
    Exercise('Pec deck fly', equipment: {Equipment.pecDeck}),
    Exercise('Chest press with band around back', equipment: {Equipment.band}),
    Exercise('Incline push-up', equipment: {Equipment.bench}),
    Exercise('Standing palm press'),
    Exercise('Wide wall push-up'),
  ]),
  Movement(BodyArea.back, [
    Exercise(
      'Lat pulldown',
      equipment: {Equipment.pulldown},
      photo: CommonsPhoto.latPulldown,
    ),
    Exercise('Assisted pull-up', equipment: {Equipment.assistedPullUp}),
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
    Exercise('Machine rear delt fly', equipment: {Equipment.rearDeltFly}),
    Exercise('Dumbbell lateral raise', equipment: {Equipment.dumbbells}),
    Exercise('Band lateral raise', equipment: {Equipment.band}),
    Exercise('Prone T raise'),
    Exercise('Side-lying arm raise', perSide: true),
  ]),
  Movement(BodyArea.arms, [
    Exercise(
      'Machine triceps extension',
      equipment: {Equipment.tricepsExtension},
    ),
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
  required Set<BodyArea> areas,
  required Set<Equipment> available,
  required int minutes,
  required Experience experience,
}) {
  if (areas.length < minTargetAreas || areas.length > maxTargetAreas) {
    throw ArgumentError.value(areas, 'areas', 'Select 2 to 4 target areas.');
  }
  final sets = setsPerExercise(minutes, experience, areaCount: areas.length);
  final secondsPerExercise = sets * (45 + experience.restSeconds);
  final count = (minutes * 60) ~/ secondsPerExercise;
  return movements
      .where((movement) => areas.contains(movement.area))
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
  required int areaCount,
}) {
  if (minutes <= 15) return 2;
  if (areaCount == minTargetAreas) return minutes >= 40 ? 4 : 3;
  return experience == Experience.intermediate ? 3 : 2;
}
