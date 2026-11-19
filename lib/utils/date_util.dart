// lib/utils/date_util.dart
// 时间格式化工具（纯 Dart，不依赖 intl）

/// 获取当前时间的 yyyy-MM-dd HH:mm:ss 字符串，用作 createAt
String nowIso() {
  final d = DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  final ss = d.second.toString().padLeft(2, '0');
  return '$y-$m-$dd $hh:$mm:$ss';
}

/// yyyy-MM-dd HH:mm
String fmtDateTime(String s) {
  if (s.length >= 16) return s.substring(0, 16);
  return s;
}

/// 判断是否本月（yyyy-MM 前缀相同）
bool isCurrentMonth(String createAt) {
  final d = DateTime.now();
  final prefix = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  return createAt.startsWith(prefix);
}
