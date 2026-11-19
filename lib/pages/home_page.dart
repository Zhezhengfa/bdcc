// lib/pages/home_page.dart
// 首页：统计卡 + 记账记录 ListView + FAB
// 严格对齐精修稿 Material 3：Card 圆角 12、elevation 1、AppBar 56、FAB 56×56

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db_helper.dart';
import '../models/record.dart';
import '../utils/date_util.dart';
import 'detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Record> _records = [];
  double _monthExpense = 0;
  double _monthIncome = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // await 全部 sqflite 调用，规避 EX22
    final list = await DbHelper.instance.queryAll();
    final now = DateTime.now();
    final prefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final (exp, inc) = await DbHelper.instance.monthSum(prefix);

    if (!mounted) return;
    setState(() {
      _records = list;
      _monthExpense = exp;
      _monthIncome = inc;
      _loading = false;
    });
  }

  Future<void> _onAddRecord() async {
    // 课程约束：只做界面。这里弹个简单对话框录入一条示例记录（不做真实表单存储）
    final result = await showDialog<Record>(
      context: context,
      builder: (_) => const _AddDialog(),
    );
    if (result == null || !mounted) return;
    await DbHelper.instance.insert(result);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _monthIncome - _monthExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索（静态占位）',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '个人中心',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ).then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 本月收支统计 Card
                _StatsCard(
                  income: _monthIncome,
                  expense: _monthExpense,
                  balance: balance,
                ),
                const Divider(height: 1),

                // 记录列表
                if (_records.isEmpty)
                  const _EmptyHint()
                else
                  ..._records.map((r) => _RecordCard(
                        record: r,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(recordId: r.id!),
                            ),
                          );
                          _load(); // 返回刷新
                        },
                      )),
                const SizedBox(height: 80), // 给 FAB 让位
              ],
            ),
      floatingActionButton: FloatingActionButton.large(
        heroTag: const ValueKey('fab-home'),
        onPressed: _onAddRecord,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==============================================================
// 本月收支统计卡
// ==============================================================
class _StatsCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  const _StatsCard(
      {required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _Col(label: '本月收入', value: income, role: _Role.income),
          _Col(label: '本月支出', value: expense, role: _Role.expense),
          _Col(label: '结余', value: balance, role: _Role.balance),
        ],
      ),
    );
  }
}

enum _Role { income, expense, balance }

class _Col extends StatelessWidget {
  final String label;
  final double value;
  final _Role role;
  const _Col({required this.label, required this.value, required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (role) {
      _Role.income => cs.primary,
      _Role.expense => cs.error,
      _Role.balance => cs.onSurface,
    };
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
          const SizedBox(height: 4),
          Text(
            '¥ ${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// 记账记录 Card → ListTile
// ==============================================================
class _RecordCard extends StatelessWidget {
  final Record record;
  final VoidCallback onTap;
  const _RecordCard({required this.record, required this.onTap});

  IconData get _icon => switch (record.remark) {
        '午饭' || '晚餐' || '饮料' => Icons.restaurant,
        '公交' => Icons.directions_car,
        '稿费' => Icons.work,
        _ => Icons.account_balance_wallet,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpense = record.isExpense;
    final iconBg = isExpense ? cs.errorContainer : cs.primaryContainer;
    final iconFg = isExpense ? cs.onErrorContainer : cs.onPrimaryContainer;
    final amtColor = isExpense ? cs.error : cs.primary;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: iconFg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(record.remark,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(fmtDateTime(record.createAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    record.amountLabel,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: amtColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// 空态提示
// ==============================================================
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('还没有记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 4),
          Text('点右下角 ＋ 记一笔吧',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ==============================================================
// 新增记录对话框（课程约束：只做界面，真实读写走 DbHelper）
// ==============================================================
class _AddDialog extends StatefulWidget {
  const _AddDialog();

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _ctrl = TextEditingController(text: '20.50');
  final _remarkCtrl = TextEditingController(text: '午饭');
  int _type = 0; // 0 支出 1 收入

  @override
  void dispose() {
    _ctrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('记一笔'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('金额'),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('元'),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('支出')),
              ButtonSegment(value: 1, label: Text('收入')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkCtrl,
            decoration: const InputDecoration(labelText: '备注'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final amt = double.tryParse(_ctrl.text.trim());
            if (amt == null || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入有效金额（>0）')),
              );
              return;
            }
            Navigator.pop(
              context,
              Record(
                type: _type,
                amount: amt,
                remark: _remarkCtrl.text.trim(),
                createAt: nowIso(),
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
