import 'package:flutter/foundation.dart';
import 'package:bugaoshan/services/auth/scu_auth.dart';
import 'package:bugaoshan/services/auth/cookie_client.dart';

/// 教务系统认证（第2层）
///
/// zhjw.scu.edu.cn 的 SSO 预热已在 [ScuAuth.bindSession] 中完成，
/// 共享同一个 CookieClient。
///
/// 监听 [ScuAuth] 状态变化并转发通知，Provider 可通过 addListener 感知。
class ZhjwAuth extends ChangeNotifier {
  final ScuAuth _scuAuth;
  ZhjwAuth(this._scuAuth) {
    _scuAuth.addListener(notifyListeners);
  }

  /// 获取已认证的教务系统 CookieClient。
  ///
  /// 如果 SCU 认证失败，[UnauthenticatedException] 自动穿透。
  Future<CookieClient> getClient() => _scuAuth.getClient();

  @override
  void dispose() {
    _scuAuth.removeListener(notifyListeners);
    super.dispose();
  }
}
