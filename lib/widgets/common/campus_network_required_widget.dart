import 'package:flutter/material.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';

/// 教务系统（23:00-次日6:00）校外访问关闭。
bool isZhjwClosedAtNight() {
  final hour = DateTime.now().hour;
  return hour >= 23 || hour < 6;
}

/// 在 [errorKey] 的 catch 块中，根据当前时间判断是否需要显示校园网访问提示。
/// 返回 [nightKey]（当前时间在夜间）或 [errorKey]（其它时段）。
String campusNetworkErrorKey(
  String errorKey, {
  String nightKey = 'zhjwCampusNetworkRequiredAtNight',
}) {
  return isZhjwClosedAtNight() ? nightKey : errorKey;
}

/// 根据 errorKey 返回对应的本地化文字。
/// 每个页面/模块需自行扩展 `switch` 分支以支持各自的错误消息。
String getCampusNetworkErrorMessage(AppLocalizations l10n, String? errorKey) {
  switch (errorKey) {
    case 'zhjwCampusNetworkRequiredAtNight':
      return l10n.zhjwCampusNetworkRequiredAtNight;
    case 'sessionExpired':
      return l10n.sessionExpired;
    default:
      return l10n.loadFailed;
  }
}

/// 校园网访问提示组件（带重试按钮的 WifiOff 图标提示）。
class CampusNetworkRequiredWidget extends StatelessWidget {
  const CampusNetworkRequiredWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.iconSize = 48,
  });

  final String message;
  final VoidCallback onRetry;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: iconSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
