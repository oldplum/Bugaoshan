# 反向依赖修复计划

## 架构原则

```
ScuAuth (L3) → Auth (L2, ChangeNotifier) → Provider (监听 L2, 持有 L1)
```

- Provider 可以持有 API Service (L1) — 无状态工具
- Provider 可以持有 Auth (L2) — 有状态，监听变化
- Provider 不应跳过 L2 直接持有 ScuAuth (L3)（ScuAuthProvider 除外，它是认证控制器）
- Auth (L2) 是 ChangeNotifier，监听 ScuAuth 转发通知
- API Service 无状态，不参与通知链

## 待修复问题

| # | 问题 | 修复 |
|---|---|---|
| 1 | ZhjwAuth/WfwAuth/SsoRelayAuth 不是 ChangeNotifier | 改成 ChangeNotifier，监听 ScuAuth |
| 2 | UserInfoProvider 直接持有 ScuAuth (L3) | 改为监听 WfwAuth (L2) |
| 3 | ScuAuthProvider 持有 WfwApiService 调 fetchUserProfile | 移除，由 UserInfoProvider 通过 WfwAuth 自动触发 |
| 4 | CcylOAuthService 用 getIt<ScuAuth>() | 改为构造函数注入 |
| 5 | CcylAuth.reLogin() 隐式依赖 ScuAuth | 构造函数注入 ScuAuth，传给 CcylOAuthService |
| 6 | scu_login_page 直接调 ScuAuth.fetchCaptcha() | 改用 ScuAuthProvider.fetchCaptcha() |
| 7 | SecureStorageProvider 在 providers/ | 移到 utils/secure_storage.dart |

## 不在本次范围

- network_device_page / fitness_test_page 创建 API Service（后续 PR）

## 执行顺序

1. SecureStorageProvider → utils/secure_storage.dart
2. ZhjwAuth / WfwAuth / SsoRelayAuth → ChangeNotifier
3. CcylOAuthService → 构造函数注入 ScuAuth
4. CcylAuth → 注入 ScuAuth 传给 CcylOAuthService
5. ScuAuthProvider → 移除 WfwApiService
6. UserInfoProvider → 监听 WfwAuth 替代 ScuAuth
7. scu_login_page → ScuAuthProvider.fetchCaptcha()
8. 更新 injector.dart
9. dart analyze 验证
