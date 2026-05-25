// 这个库是为了在iOS上使用CupertinoPageTransitionsBuilder，flutter新版已经分离出来了，不要删
import 'package:flutter/cupertino.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/pages/home_page.dart';
import 'package:bugaoshan/pages/wizard/eula_gate_page.dart';
import 'package:bugaoshan/pages/wizard/wizard_page.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/widgets/eula_content.dart';
import 'package:bugaoshan/widgets/route/router_utils.dart';
import 'package:system_theme/system_theme.dart';
import 'l10n/app_localizations.dart';

const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

const _appBarTheme = AppBarTheme(
  toolbarHeight: 48,
  centerTitle: true,
  scrolledUnderElevation: 0,
);

const _navigationBarTheme = NavigationBarThemeData(height: 64);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppConfigProvider _appConfig = getIt<AppConfigProvider>();
  ImageStream? _bgImageStream;
  ImageStreamListener? _bgImageListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = _appConfig.backgroundImagePath.value;
      if (path == null) return;
      try {
        if (!mounted) return;
        final file = File(path);
        // 使用屏幕逻辑像素与 devicePixelRatio 计算目标解码尺寸，避免缓存全分辨率大图
        final mq = MediaQuery.of(context);
        final dpr = mq.devicePixelRatio;
        final widthPx = (mq.size.width * dpr).round();
        final heightPx = (mq.size.height * dpr).round();

        // 为避免强制拉伸，仅指定屏幕的长边作为目标尺寸，保持原始宽高比
        final longSide = widthPx >= heightPx ? widthPx : heightPx;
        final provider = (widthPx >= heightPx)
            ? ResizeImage(FileImage(file), width: longSide)
            : ResizeImage(FileImage(file), height: longSide);
        // 通过 ImageStream 监听完成并在 dispose 中移除监听，避免与 Widget 生命周期脱钩造成内存泄漏
        _bgImageStream = provider.resolve(
          ImageConfiguration(devicePixelRatio: dpr),
        );
        _bgImageListener = ImageStreamListener(
          (_, __) {
            try {
              _bgImageStream?.removeListener(_bgImageListener!);
            } catch (_) {}
            _bgImageStream = null;
            _bgImageListener = null;
          },
          onError: (_, __) {
            try {
              _bgImageStream?.removeListener(_bgImageListener!);
            } catch (_) {}
            _bgImageStream = null;
            _bgImageListener = null;
          },
        );
        _bgImageStream?.addListener(_bgImageListener!);
      } catch (_) {
        // ignore precache/resolve errors
      }
    });
  }

  @override
  void dispose() {
    if (_bgImageStream != null && _bgImageListener != null) {
      try {
        _bgImageStream!.removeListener(_bgImageListener!);
      } catch (_) {}
      _bgImageStream = null;
      _bgImageListener = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _appConfig.locale,
        _appConfig.themeColor,
        _appConfig.themeColorMode,
      ]),
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        locale: _appConfig.locale.value,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.bugaoshan,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: ValueListenableBuilder<int>(
          valueListenable: _appConfig.acceptedEulaVersion,
          builder: (_, eulaVersion, _) {
            if (eulaVersion < currentEulaVersion) {
              return const EulaGatePage();
            }
            return ValueListenableBuilder<bool>(
              valueListenable: _appConfig.firstLaunchWizardCompleted,
              builder: (_, completed, _) =>
                  completed ? const HomePage() : const WizardPage(),
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final seedColor = _appConfig.themeColorMode.value == ThemeColorMode.system
        ? SystemTheme.accentColor.accent
        : _appConfig.themeColor.value;
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: _appBarTheme,
      navigationBarTheme: _navigationBarTheme,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),
    );
  }
}
