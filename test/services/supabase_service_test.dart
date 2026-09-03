import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('blank placeholder config leaves Supabase disabled safely', () async {
    final initialized = await SupabaseService.initialize();

    expect(initialized, isFalse);
    expect(SupabaseService.resolveConfig().isConfigured, isFalse);
  });
}
