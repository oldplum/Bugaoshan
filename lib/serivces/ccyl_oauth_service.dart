import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';

class CcylOAuthService {
  Future<String?> getOAuthCode() async {
    final auth = getIt<ScuAuthProvider>();
    if (auth.accessToken == null) return null;

    final client = await auth.service.bindSession();

    try {
      final response = await client.get(
        Uri.parse('https://typt.scu.edu.cn/oauth/authorize'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
        },
      );

      final body = response.body;

      if (body.contains('code=')) {
        final codeMatch = RegExp(r'code=([^&\s"<]+)').firstMatch(body);
        if (codeMatch != null) return codeMatch.group(1);
      }

      final bodyUri = _extractRedirectUri(body);
      if (bodyUri != null && bodyUri.contains('code=')) {
        final code = Uri.parse(bodyUri).queryParameters['code'];
        return code;
      }

      return null;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  String? _extractRedirectUri(String body) {
    final metaMatch = RegExp(
      r"""<meta[^>]+http-equiv=["']refresh["'][^>]+content=["'][^;]+;\s*url=([^"'>\s]+)""",
      caseSensitive: false,
    ).firstMatch(body);
    if (metaMatch != null) return metaMatch.group(1);

    final jsMatch = RegExp(
      r"""window\.location(?:\.href)?\s*=\s*["']([^"']+)["']""",
    ).firstMatch(body);
    if (jsMatch != null) return jsMatch.group(1);

    return null;
  }
}
