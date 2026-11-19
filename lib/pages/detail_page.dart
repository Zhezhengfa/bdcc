// lib/pages/detail_page.dart
// 详情页：金额展示 + 信息 ListTile ×4 + 底部编辑/删除

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../models/record.dart';
import '../utils/date_util.dart';

class DetailPage extends StatefulWidget {
  final int recordId;
  const DetailPage({super.key, required this.recordId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Record? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DbHelper.instance.queryById(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = r;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DbHelper.instance.delete(widget.recordId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除')),
    );
    Navigator.pop(context);
  }

  Future<void> _edit() async {
    // 课程约束：界面演示。这里弹个编辑对话框，真实走 update
    if (_record == null) return;
    final result = await showDialog<Record>(
      context: context,
      builder: (_) => _EditDialog(record: _record!),
    );
    if (result == null) return;
    await DbHelper.instance.update(result);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已更新')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('记录详情'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const Center(child: Text('记录不存在'))
              : Column(
                  children: [
                    // 金额展示区 Container height 120
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 32),
                      height: 120,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _record!.isExpense ? '支出' : '收入',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _record!.amountLabel,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: _record!.isExpense ? cs.error : cs.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ListTile ×4
                    _InfoTile(title: '收支类型', trailing: _record!.isExpense ? '支出' : '收入'),
                    _InfoTile(title: '备注', trailing: _record!.remark.isEmpty ? '（无）' : _record!.remark),
                    _InfoTile(title: '记录时间', trailing: fmtDateTime(_record!.createAt)),
                    _InfoTile(title: '创建时间', trailing: _record!.createAt),

                    const Spacer(),

                    // 底部按钮 Row
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: _edit,
                                child: const Text('编辑'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cs.error,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  side: BorderSide(color: cs.outline),
                                ),
                                onPressed: _delete,
                                child: const Text('删除'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String trailing;
  const _InfoTile({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              trailing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// 编辑对话框（与新增结构一致，复用同一套 UI）
// ==============================================================
class _EditDialog extends StatefulWidget {
  final Record record;
  const _EditDialog({required this.record});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _ctrl;
  late final TextEditingController _remarkCtrl;
  late int _type;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.record.amount.toString());
    _remarkCtrl = TextEditingController(text: widget.record.remark);
    _type = widget.record.type;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('金额'),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _ctrl)),
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
            if (amt == null || amt <= 0) return;
            Navigator.pop(
              context,
              Record(
                id: widget.record.id,
                type: _type,
                amount: amt,
                remark: _remarkCtrl.text.trim(),
                createAt: widget.record.createAt,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
