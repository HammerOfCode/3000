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
  testWidgets('mock login rejects invalid credentials and opens the app', (
    tester,
  ) async {
    final prefs = await preferences();
    await tester.pumpWidget(GymReadyApp(preferences: prefs));
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
    await tester.tap(find.text('Build routine'));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsOneWidget);
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
