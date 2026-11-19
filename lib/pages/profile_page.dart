// lib/pages/profile_page.dart
// 个人中心：主题 Switch / 数据导出 / 关于 / 清空数据
// 三条存储链路在这里汇聚：
//   Switch → shared_preferences (ThemeService)
//   数据导出 → 文件存储 (FileService.exportRecords)
//   清空数据 → sqflite (DbHelper.clearAll)

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../services/file_service.dart';
import '../services/theme_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDark = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// EX21 规避：SP 必须在 initState 异步加载，绝不放到 build 里同步读
  Future<void> _load() async {
    final dark = await ThemeService.instance.loadDark();
    if (!mounted) return;
    setState(() {
      _isDark = dark;
      _loading = false;
    });
  }

  Future<void> _toggleDark(bool v) async {
    setState(() => _isDark = v);
    await ThemeService.instance.saveDark(v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('深色模式已保存，重启 App 后生效')),
    );
  }

  Future<void> _export() async {
    try {
      final list = await DbHelper.instance.queryAll();
      final path = await FileService.instance.exportRecords(
        list.map((r) => r.toMap()).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功 → $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空本地数据'),
        content: const Text('将删除 SQLite 里全部记账流水，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DbHelper.instance.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清空本地数据')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 用户信息区 Container / Row
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: const Icon(Icons.person, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('记账本用户',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text('本地数据存储演示',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ListTile ×4
                _buildSwitchTile(
                  leading: Icons.dark_mode,
                  title: '深色模式',
                  subtitle: 'shared_preferences 持久化',
                  value: _isDark,
                  onChanged: _toggleDark,
                ),

                _buildTile(
                  leading: Icons.folder,
                  title: '数据导出',
                  subtitle: '导出 JSON 到本地文档目录',
                  onTap: _export,
                ),

                _buildTile(
                  leading: Icons.info,
                  title: '关于',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: '记账本',
                    applicationVersion: '1.0.0',
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'shared_preferences：深色模式\n'
                        'sqflite：记账流水 CRUD / 搜索 / 统计\n'
                        '文件存储：JSON 导出',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                _buildTile(
                  leading: Icons.delete,
                  title: '清空本地数据',
                  onTap: _clearAll,
                ),

                // 底部版本号
                Padding(
                  padding:
                      const EdgeInsets.only(top: 32, bottom: 24),
                  child: Center(
                    child: Text(
                      'v1.0.0 · 本地数据存储演示',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTile({
    required IconData leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(leading, color: cs.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSwitchTile({
    required IconData leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(leading, color: cs.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
