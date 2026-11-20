import 'package:integration_test/integration_test.dart';

import '../test/machine_viewer_360_test.dart' as machine_viewer;
import '../test/routine_ai_test.dart' as routine_ai;
import '../test/routine_test.dart' as routine;
import '../test/widget_test.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  routine.main();
  routine_ai.main();
  app.main();
  machine_viewer.main();
}
