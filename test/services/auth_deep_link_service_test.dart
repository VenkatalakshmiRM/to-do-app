import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/services/auth_deep_link_service.dart';

void main() {
  test('recognizes password recovery callbacks in query or fragment', () {
    expect(
      AuthDeepLinkService.isPasswordRecoveryLink(
        Uri.parse(
          'com.venkatalakshmi.campustodo://auth-callback?type=recovery',
        ),
      ),
      isTrue,
    );
    expect(
      AuthDeepLinkService.isPasswordRecoveryLink(
        Uri.parse(
          'com.venkatalakshmi.campustodo://auth-callback#access_token=x&type=recovery',
        ),
      ),
      isTrue,
    );
  });

  test('does not route confirmation or unrelated links to password reset', () {
    expect(
      AuthDeepLinkService.isPasswordRecoveryLink(
        Uri.parse('com.venkatalakshmi.campustodo://auth-callback?type=signup'),
      ),
      isFalse,
    );
    expect(
      AuthDeepLinkService.isPasswordRecoveryLink(
        Uri.parse('https://example.com?type=recovery'),
      ),
      isFalse,
    );
  });
}
