import 'package:bugaoshan/services/auth/scu_auth.dart';
import 'package:bugaoshan/services/auth/cookie_client.dart';

/// 微服务认证（第2层）
///
/// wfw.scu.edu.cn 通过 SCU SSO session 认证（CookieClient），
/// 与教务系统共享同一个 SSO session。
class WfwAuth {
  final ScuAuth _scuAuth;
  WfwAuth(this._scuAuth);

  /// 获取已认证的 CookieClient（SSO session）。
  ///
  /// wfw.scu.edu.cn 使用与教务系统相同的 SSO session，
  /// 在 ScuAuth.bindSession() 中已预热。
  Future<CookieClient> getClient() => _scuAuth.getClient();
}
