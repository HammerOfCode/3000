import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_ready/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> preferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> signIn(WidgetTester tester, SharedPreferences prefs) async {
  await tester.pumpWidget(GymReadyApp(preferences: prefs));
  await tester.enterText(find.byType(TextFormField).at(0), 'user');
  await tester.enterText(find.byType(TextFormField).at(1), 'user');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('machine search and My gym use the saved equipment checklist', (
    tester,
  ) async {
    final prefs = await preferences();
    await signIn(tester, prefs);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();

    final search = find.widgetWithText(TextField, 'Search machines or gear');
    final hackSquat = find.widgetWithText(
      CheckboxListTile,
      'Hack squat machine',
    );
    await tester.enterText(search, 'hack squat');
    await tester.pumpAndSettle();
    expect(hackSquat, findsOneWidget);
    expect(
      find.descendant(of: hackSquat, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(find.text('Dumbbells'), findsNothing);
    await tester.ensureVisible(hackSquat);
    await tester.tap(hackSquat);
    await tester.pumpAndSettle();
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('My gym'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(hackSquat).value, isTrue);
    expect(find.text('Dumbbells'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await signIn(tester, prefs);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My gym'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(hackSquat).value, isTrue);
  });

  testWidgets('a workout photo can be opened from the exercise row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await signIn(tester, await preferences());
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build routine'));
    await tester.pumpAndSettle();

    final photo = find.byTooltip('View Bodyweight squat photo');
    expect(photo, findsOneWidget);
    await tester.tap(photo);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.byType(Image)),
      findsOneWidget,
    );
    final repDb = find.text('Exercise data by RepDB (repdb.co)');
    if (repDb.evaluate().isEmpty) {
      expect(find.textContaining('Wikimedia Commons'), findsOneWidget);
      expect(find.textContaining('CC BY'), findsOneWidget);
    } else {
      expect(repDb, findsOneWidget);
    }
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
  });

  testWidgets('workout picker requires two areas and allows up to four', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await signIn(tester, await preferences());
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    final buildButton = find.widgetWithText(FilledButton, 'Build routine');
    FilledButton build() => tester.widget<FilledButton>(buildButton);
    FilterChip area(String label) =>
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));
    Future<void> pick(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(build().onPressed, isNull);
    await pick('Chest');
    expect(build().onPressed, isNull);
    await pick('Back');
    expect(build().onPressed, isNotNull);
    expect(area('Chest').selected, isTrue);
    expect(area('Back').selected, isTrue);
    await pick('Legs');
    await pick('Core');
    expect(area('Shoulders').onSelected, isNull);
    expect(area('Shoulders').selected, isFalse);
    await pick('Core');
    expect(area('Shoulders').onSelected, isNotNull);
    await pick('Shoulders');
    expect(area('Shoulders').selected, isTrue);
    expect(area('Arms').onSelected, isNull);
    await pick('Shoulders');
    await pick('Legs');
    await pick('Back');
    expect(build().onPressed, isNull);

    await pick('Full body');
    expect(area('Chest').selected, isTrue);
    expect(area('Back').selected, isTrue);
    expect(area('Legs').selected, isTrue);
    expect(area('Core').selected, isTrue);
    expect(build().onPressed, isNotNull);
  });

  testWidgets('mock login rejects invalid credentials and opens the app', (
    tester,
  ) async {
    final prefs = await preferences();
    await tester.pumpWidget(GymReadyApp(preferences: prefs));
    expect(find.text('3000'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Use the demo ID and password.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'user');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Your measurements'), findsOneWidget);
  });

  testWidgets('profile validates and restores measurements after reopening', (
    tester,
  ) async {
    final prefs = await preferences();
    await signIn(tester, prefs);
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive number.'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), '175');
    await tester.enterText(find.byType(TextFormField).at(1), '72.5');
    await tester.enterText(find.byType(TextFormField).at(2), '31');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Build a workout'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await signIn(tester, prefs);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('175'), findsOneWidget);
    expect(find.text('72.5'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('equipment starts empty and availability survives reopening', (
    tester,
  ) async {
    final prefs = await preferences();
    await signIn(tester, prefs);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    final dumbbells = find.widgetWithText(CheckboxListTile, 'Dumbbells');
    expect(tester.widget<CheckboxListTile>(dumbbells).value, isFalse);
    await tester.tap(dumbbells);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(dumbbells).value, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await signIn(tester, prefs);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(dumbbells).value, isTrue);
  });

  testWidgets('chest workout can swap a dumbbell exercise for a floor option', (
    tester,
  ) async {
    final prefs = await preferences();
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await signIn(tester, prefs);
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Dumbbells'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build routine'));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('Dumbbell bent-over row'), findsOneWidget);
    await tester.tap(find.byTooltip('Swap Dumbbell floor press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knee push-up').last);
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsNothing);
    expect(find.text('Knee push-up'), findsOneWidget);
  });

  testWidgets(
    'a named machine stays in the inventory and enables matching exercises',
    (tester) async {
      final prefs = await preferences();
      tester.view.physicalSize = const Size(412, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await signIn(tester, prefs);
      await tester.tap(find.text('Equipment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add equipment'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Gym station A');
      await tester.tap(find.text('Inventory only'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest press machine').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save equipment'));
      await tester.pumpAndSettle();
      expect(find.text('Gym station A'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await signIn(tester, prefs);
      await tester.tap(find.text('Equipment'));
      await tester.pumpAndSettle();
      expect(find.text('Gym station A'), findsOneWidget);
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build routine'));
      await tester.pumpAndSettle();
      expect(find.text('Machine chest press'), findsOneWidget);
      await tester.tap(find.text('Equipment'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Gym station A'));
      await tester.pumpAndSettle();
      expect(find.text('Gym station A'), findsNothing);
    },
  );
}
