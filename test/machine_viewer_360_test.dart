import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_ready/equipment_page.dart';
import 'package:gym_ready/machine_model_view.dart';
import 'package:gym_ready/machine_viewer_360.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _poster = 'assets/commons/legPressMachine.jpg';
const _frames = ['assets/commons/legPress.jpg', _poster];
const _model = 'assets/models/leg_press_demo.glb';

Widget _host(Widget viewer) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, height: 280, child: viewer)),
  ),
);

void main() {
  void hideSeenHint() => SharedPreferences.setMockInitialValues({
    'machine-viewer.drag-hint.v1': true,
  });

  testWidgets('machine details open independently of the inventory checkbox', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EquipmentPage(
            available: const {},
            named: const [],
            onChanged: (_, _) =>
                fail('Opening details must not select a machine.'),
            onNamedChanged: null,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'smith machine');
    await tester.pumpAndSettle();
    expect(find.byType(MachineViewer360), findsNothing);
    await tester.tap(find.byTooltip('View Smith machine details'));
    await tester.pumpAndSettle();
    expect(find.byType(MachineViewer360), findsOneWidget);
    expect(find.text('Smith machine'), findsOneWidget);
  });

  testWidgets('the model takes precedence over a spin sequence', (
    tester,
  ) async {
    hideSeenHint();
    MachineModelView? renderer;
    var loaded = 0;
    await tester.pumpWidget(
      _host(
        MachineViewer360(
          modelSrc: _model,
          posterImage: _poster,
          spinFrames: _frames,
          autoRotate: false,
          onLoaded: () => loaded++,
          modelBuilder: (model) {
            renderer = model;
            return const Text('GLB renderer');
          },
        ),
      ),
    );
    expect(find.text('GLB renderer'), findsOneWidget);
    expect(find.byTooltip('Reset view'), findsNothing);
    renderer!.onLoaded();
    await tester.pump();
    expect(loaded, 1);
    expect(find.byTooltip('Reset view'), findsOneWidget);
  });

  testWidgets('the spin sequence wraps on drag and resets to its first frame', (
    tester,
  ) async {
    hideSeenHint();
    await tester.pumpWidget(
      _host(
        const MachineViewer360(
          posterImage: _poster,
          spinFrames: _frames,
          autoRotate: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final first = find.byKey(ValueKey(_frames.first));
    expect(first, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(first));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(ValueKey(_frames.last)), findsOneWidget);
    await gesture.up();
    await tester.tap(find.byTooltip('Reset view'));
    await tester.pumpAndSettle();
    expect(first, findsOneWidget);
  });

  testWidgets('the existing poster is shown for static equipment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MachineViewer360(posterImage: _poster)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(_poster)), findsOneWidget);
    expect(find.byTooltip('Reset view'), findsNothing);
  });

  testWidgets('a failed model falls back to its poster and reports the error', (
    tester,
  ) async {
    MachineModelView? renderer;
    Object? reported;
    await tester.pumpWidget(
      _host(
        MachineViewer360(
          modelSrc: _model,
          posterImage: _poster,
          onError: (error) => reported = error,
          modelBuilder: (model) {
            renderer = model;
            return const Text('GLB renderer');
          },
        ),
      ),
    );
    final failure = StateError('model could not load');
    renderer!.onError(failure);
    await tester.pumpAndSettle();
    expect(reported, same(failure));
    expect(find.text('GLB renderer'), findsNothing);
    expect(find.byKey(const ValueKey(_poster)), findsOneWidget);
    expect(find.text('360° view unavailable'), findsOneWidget);
  });

  testWidgets('a broken spin frame also returns to its poster', (tester) async {
    hideSeenHint();
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        MachineViewer360(
          posterImage: _poster,
          spinFrames: const [_poster, 'assets/does-not-exist.png'],
          onError: errors.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, hasLength(1));
    expect(find.text('360° view unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey(_poster)), findsOneWidget);
  });
}
