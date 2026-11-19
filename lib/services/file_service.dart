// lib/services/file_service.dart
// 文件存储：导出 JSON + 方案文本保存
// 注意：业务数据一律写 getApplicationDocumentsDirectory（持久，卸载才清空），
//        不用 getTemporaryDirectory（系统随时清理）。
// 规避点：所有文件 IO 必须 await；try/catch 捕获 FileSystemException；
//         读文件前先 exists()；绝不裸 catch。

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  FileService._();
  static final FileService instance = FileService._();

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, name));
  }

  /// 读文本（文件不存在或 IO 异常返回空串，不崩溃）
  Future<String> readText(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return '';
      return await f.readAsString();
    } on FileSystemException {
      return '';
    }
  }

  /// 写文本
  Future<void> writeText(String name, String content) async {
    try {
      final f = await _file(name);
      await f.writeAsString(content);
    } on FileSystemException catch (e) {
      throw Exception('写入 $name 失败：${e.message}');
    }
  }

  /// 导出记账流水为 JSON
  Future<String> exportRecords(List<Map<String, dynamic>> data) async {
    final f = await _file('record_export.json');
    try {
      await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      return f.path; // 返回路径用于 SnackBar 提示
    } on FileSystemException catch (e) {
      throw Exception('导出失败：${e.message}');
    }
  }
}
