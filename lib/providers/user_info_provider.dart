import 'package:flutter/foundation.dart';
import 'package:bugaoshan/services/api/wfw_api_service.dart';
import 'package:bugaoshan/services/auth/auth_state.dart';
import 'package:bugaoshan/services/auth/scu_auth.dart';
import 'package:bugaoshan/services/auth/scu_exceptions.dart';

/// 用户信息标签 Provider（单例）
///
/// 自动监听 [ScuAuth] 登录状态：
/// - 登录成功 → 自动 fetch 标签
/// - 登出 → 自动 clear
/// - 加载失败 → 停止，等用户点重试
class UserInfoProvider extends ChangeNotifier {
  final ScuAuth _scuAuth;
  final WfwApiService _wfwApi;

  UserInfoProvider(this._scuAuth, this._wfwApi) {
    _scuAuth.addListener(_onAuthChanged);
  }

  List<Map<String, dynamic>>? _labels;
  bool _loading = false;
  bool _error = false;

  List<Map<String, dynamic>>? get labels => _labels;
  bool get loading => _loading;
  bool get error => _error;
  bool get hasData => _labels != null;

  void _onAuthChanged() {
    if (_scuAuth.state == AuthState.ready) {
      // 登录成功，自动获取标签
      fetchLabels();
    } else if (_scuAuth.state == AuthState.unknown) {
      // 登出，清空数据
      clear();
    }
  }

  Future<void> fetchLabels() async {
    if (_loading) return;
    if (!_scuAuth.isReady) return;

    _loading = true;
    _error = false;
    notifyListeners();

    try {
      _labels = await _wfwApi.fetchProfileLabels();
      _error = false;
    } on UnauthenticatedException {
      _error = true;
    } catch (e) {
      _error = true;
    }
    _loading = false;
    notifyListeners();
  }

  void retry() {
    _error = false;
    fetchLabels();
  }

  void clear() {
    _labels = null;
    _error = false;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _scuAuth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
