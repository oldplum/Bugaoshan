import 'package:bugaoshan/services/auth/scu_exceptions.dart';

/// API 请求自动重试包装。
///
/// 如果 [getClient] 抛出 [UnauthenticatedException]（认证失败），
/// 重试一次（getClient 内部会尝试 refresh）。
/// 第二次仍失败 → UnauthenticatedException 穿透到调用方。
Future<T> retryOnUnauthenticated<T, C>(
  Future<C> Function() getClient,
  Future<T> Function(C client) fn,
) async {
  try {
    final client = await getClient();
    return await fn(client);
  } on UnauthenticatedException {
    final client = await getClient();
    return await fn(client);
  }
}
