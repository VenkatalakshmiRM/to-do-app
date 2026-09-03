import 'package:app_links/app_links.dart';

abstract final class AuthDeepLinkConfig {
  static const scheme = 'com.venkatalakshmi.campustodo';
  static const host = 'auth-callback';
  static const redirectUrl = '$scheme://$host';
}

class AuthDeepLinkService {
  AuthDeepLinkService({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  Stream<Uri> get links => _appLinks.uriLinkStream;

  static bool isPasswordRecoveryLink(Uri uri) {
    if (uri.scheme != AuthDeepLinkConfig.scheme ||
        uri.host != AuthDeepLinkConfig.host) {
      return false;
    }

    final parameters = <String, String>{...uri.queryParameters};
    if (uri.fragment.isNotEmpty) {
      try {
        parameters.addAll(Uri.splitQueryString(uri.fragment));
      } on FormatException {
        return false;
      }
    }
    return parameters['type'] == 'recovery';
  }
}
