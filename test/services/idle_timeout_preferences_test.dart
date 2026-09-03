import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_task_hub/services/idle_timeout_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults idle auto-logout to enabled and persists changes', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await IdleTimeoutPreferences.loadEnabled(), isTrue);
    await IdleTimeoutPreferences.saveEnabled(false);
    expect(await IdleTimeoutPreferences.loadEnabled(), isFalse);
  });
}
