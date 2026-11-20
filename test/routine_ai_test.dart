import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_ready/routine.dart';
import 'package:gym_ready/routine_ai.dart';
import 'package:gym_ready/workout_page.dart';

class _TestAi implements RoutineAi {
  _TestAi({this.installed = true, this.response = '{"choices":[2,2,1,1]}'});

  final bool installed;
  final String response;
  int generations = 0;
  int downloads = 0;

  @override
  bool get supported => true;

  @override
  Future<bool> hasModel() async => installed;

  @override
  Future<void> downloadModel(void Function(double) onProgress) async {
    downloads++;
    onProgress(1);
  }

  @override
  Future<String> generate(String prompt) async {
    generations++;
    return response;
  }
}

Future<void> _openWorkout(WidgetTester tester, _TestAi ai) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WorkoutPage(available: {}, ai: ai),
      ),
    ),
  );
  for (final area in ['Chest', 'Back']) {
    await tester.tap(find.text(area));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(target, 100);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  final baseline = buildRoutine(
    areas: {BodyArea.chest, BodyArea.back},
    available: {},
    minutes: 15,
    experience: Experience.beginner,
  );

  test(
    'AI can choose an available alternative within each existing slot',
    () async {
      final routine = await chooseAiRoutine(
        baseline: baseline,
        available: {},
        experience: Experience.beginner,
        minutes: 15,
        generate: (prompt) async {
          expect(prompt, contains('Wall push-up'));
          expect(prompt, isNot(contains('Machine chest press')));
          return '{"choices":[2,2,1,1]}';
        },
      );
      expect(routine?.first.exercise.name, 'Wall push-up');
      expect(routine?[1].exercise.name, 'Reverse snow angel');
      expect(
        routine?.map((item) => item.movement),
        baseline.map((item) => item.movement),
      );
    },
  );

  test('AI results with missing or unknown choices are rejected', () async {
    for (final response in [
      '{"choices":[1]}',
      '{"choices":[3,1,1,1]}',
      'Try a machine chest press.',
    ]) {
      final routine = await chooseAiRoutine(
        baseline: baseline,
        available: {},
        experience: Experience.beginner,
        minutes: 15,
        generate: (_) async => response,
      );
      expect(routine, isNull);
    }
  });

  testWidgets('the toggle selects the regular builder or Gemma', (
    tester,
  ) async {
    final ai = _TestAi();
    await _openWorkout(tester, ai);
    await _tap(tester, 'Build routine');
    expect(find.text('Knee push-up'), findsOneWidget);
    expect(ai.generations, 0);

    final toggle = find.text('Use AI');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await _tap(tester, 'Build routine');
    expect(find.text('Wall push-up'), findsOneWidget);
    expect(find.text('Exercise choices by Gemma'), findsOneWidget);
    expect(ai.generations, 1);
  });

  testWidgets('missing model offers a download and keeps the regular builder', (
    tester,
  ) async {
    final ai = _TestAi(installed: false);
    await _openWorkout(tester, ai);
    await _tap(tester, 'Use AI');
    expect(find.text('Download Gemma · 2.4 GiB'), findsOneWidget);
    await _tap(tester, 'Build routine');
    expect(
      find.text('Gemma is unavailable. Used the regular builder.'),
      findsOneWidget,
    );
    expect(ai.generations, 0);
    expect(ai.downloads, 0);
  });

  testWidgets('invalid AI output falls back to the regular routine', (
    tester,
  ) async {
    final ai = _TestAi(response: '{"choices":[999]}');
    await _openWorkout(tester, ai);
    await _tap(tester, 'Use AI');
    await _tap(tester, 'Build routine');
    expect(find.text('Knee push-up'), findsOneWidget);
    expect(
      find.text('Gemma could not finish. Used the regular builder.'),
      findsOneWidget,
    );
    expect(ai.generations, 1);
  });
}
