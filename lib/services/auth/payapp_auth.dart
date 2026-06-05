import 'package:bugaoshan/services/auth/scu_auth.dart';
import 'package:bugaoshan/services/auth/sso_relay_auth.dart';

/// 缴费平台认证（第2层）
///
/// payapp.scu.edu.cn 通过 SCU SSO 跳转获取 airWarrant cookie。
class PayAppAuth extends SsoRelayAuth {
  PayAppAuth(ScuAuth scuAuth)
    : super(scuAuth, 'https://payapp.scu.edu.cn/eleFees/oauth/airWarrant');
}
