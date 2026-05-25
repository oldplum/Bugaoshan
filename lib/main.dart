import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugaoshan/app.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/services/window_state_service.dart';
import 'package:system_theme/system_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bugaoshan/providers/app_info_provider.dart';

Future<void> main() async {
  try {
    await _initializeApp();
    runApp(MyApp());
  } catch (error, stackTrace) {
    debugPrint('Startup error: $error\n$stackTrace');
    runApp(const _StartupErrorApp());
  }
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    DartPluginRegistrant.ensureInitialized();
    if (_isDesktopPlatform) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  configureDependencies();
  await ensureBasicDependencies();

  // 清理下载的安装包（首次打开或更新后）。
  try {
    final prefs = getIt<SharedPreferences>();
    final appInfo = getIt<AppInfoProvider>();
    final currentVersion = appInfo.currentVersion;
    const keyLastInstalledVersion = 'last_installed_version';
    final lastVersion = prefs.getString(keyLastInstalledVersion);
    if (lastVersion != currentVersion) {
      try {
        final tempDir = await getTemporaryDirectory();
        final dir = Directory(tempDir.path);
        if (dir.existsSync()) {
          for (final ent in dir.listSync(recursive: false)) {
            if (ent is File) {
              final name = p.basename(ent.path).toLowerCase();
              if (name.endsWith('.apk') &&
                  (name.startsWith('bugaoshan_v') ||
                      name.startsWith('bugaoshan_update'))) {
                try {
                  ent.deleteSync();
                } catch (e) {
                  // ignore delete errors
                }
              }
            }
          }
        }
      } catch (e) {
        // ignore cleanup errors
      }
      prefs.setString(keyLastInstalledVersion, currentVersion);
    }
  } catch (e) {
    // ignore errors if DI not ready for some reason
  }

  // 桌面端记住窗口位置和大小，下次启动时恢复
  if (!kIsWeb && _isDesktopPlatform) {
    await WindowStateService.create(getIt<SharedPreferences>());
  }

  // 获取系统主题颜色
  SystemTheme.fallbackColor = Colors.blue;
  await SystemTheme.accentColor.load();
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Bugaoshan 启动失败', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
