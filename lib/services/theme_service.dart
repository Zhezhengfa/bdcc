// lib/services/theme_service.dart
// shared_preferences：深色模式开关
// 规避 EX21：不在 build 里同步读 SP，必须 initState 异步加载 + ?? 默认值兜底

import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _kDark = 'isDarkMode';

  /// 异步读取，必须 await；默认 false（浅色）兜底
  Future<bool> loadDark() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kDark) ?? false;
  }

  /// 写入后必须 await
  Future<void> saveDark(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDark, value);
  }
}
