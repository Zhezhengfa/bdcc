// lib/models/record.dart
// 数据模型：Map ↔ Record，隔离数据库字段与 UI

class Record {
  final int? id;
  final int type;      // 0 = 支出，1 = 收入
  final double amount;
  final String remark;
  final String createAt; // yyyy-MM-dd HH:mm:ss，保证字符串排序等价于时间排序

  const Record({
    this.id,
    required this.type,
    required this.amount,
    required this.remark,
    required this.createAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'amount': amount,
        'remark': remark,
        'createAt': createAt,
      };

  factory Record.fromMap(Map<String, dynamic> m) => Record(
        id: m['id'] as int?,
        type: m['type'] as int,
        amount: (m['amount'] as num).toDouble(),
        remark: m['remark'] as String? ?? '',
        createAt: m['createAt'] as String,
      );

  bool get isExpense => type == 0;
  bool get isIncome => type == 1;

  /// 金额格式化：支出 "-¥ 20.50"，收入 "+¥ 200.00"
  String get amountLabel {
    final sign = isExpense ? '-' : '+';
    return '$sign ¥ ${amount.toStringAsFixed(2)}';
  }

  /// 仅金额（无符号）
  String get amountOnly => '¥ ${amount.toStringAsFixed(2)}';
}
