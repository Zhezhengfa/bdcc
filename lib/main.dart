// lib/main.dart
// 入口：初始化 shared_preferences 读主题 → MaterialApp → HomePage
// EX21 规避：不在 build 里同步读 SP，initState 异步 load 后 setState

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/home_page.dart';
import 'services/theme_service.dart';

void main() {
  // 先确保 WidgetsBinding 初始化——否则 SystemChrome.setPreferredOrientations
  // 会抛 "Binding has not yet been initialized"
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面端（Windows）sqflite 没有原生实现，需切换到 FFI 工厂；
  // Android / iOS 上这段不会执行，仍走原生 sqflite
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 锁定竖屏（课程作业固定画布 375px 思路）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const _Root());
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  /// EX21 规避：ThemeService.loadDark 异步加载，绝不放到 build 里同步读
  Future<void> _loadTheme() async {
    // 延迟一帧，确保 WidgetsBinding 已 ready
    final dark = await ThemeService.instance.loadDark();
    if (!mounted) return;
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Material 3 默认 ColorScheme，seed = #6750A4
    final light = ColorScheme.fromSeed(
      seedColor: const Color(0xff6750A4),
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: const Color(0xff6750A4),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: light,
        scaffoldBackgroundColor: light.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: light.surface,
          foregroundColor: light.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: light.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: light.outlineVariant),
          ),
          margin: const EdgeInsets.all(8),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: dark,
        scaffoldBackgroundColor: dark.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: dark.surface,
          foregroundColor: dark.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: dark.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: dark.outlineVariant),
          ),
          margin: const EdgeInsets.all(8),
        ),
      ),
      home: const HomePage(),
    );
  }
}
