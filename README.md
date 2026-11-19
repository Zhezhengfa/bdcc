# 简易个人记账本（本地数据存储版）

一个完全离线、数据只保存在手机本地的 Flutter 记账 App，用于演示 **shared_preferences / sqflite / 文件存储** 三种本地存储方式。

> 课程：移动软件开发 · 第 10 课「本地数据存储」
> 技术栈：Flutter + Material 3，无后端、无网络请求、无状态管理库

---

## 功能

| 页面 | 内容 |
|---|---|
| 首页 | 本月收入 / 支出 / 结余统计卡，记账记录列表（按时间倒序），右下角 FAB「记一笔」 |
| 详情页 | 金额大字展示，收支类型 / 备注 / 记录时间 / 创建时间四行，底部「编辑」「删除」 |
| 个人中心 | 头像与昵称，深色模式开关、数据导出、关于、清空本地数据，底部版本号 |

---

## 三种本地存储链路

| 存储方式 | 存储内容 | 键 / 表 / 文件 | 界面入口 |
|---|---|---|---|
| shared_preferences | 深色模式开关 | `isDarkMode`（bool） | 个人中心 · 深色模式开关 |
| sqflite (SQLite) | 记账流水 | 表 `book_record` | 首页列表、详情页、清空本地数据 |
| 文件存储 | 全量记录导出 | `record_export.json`（文档目录） | 个人中心 · 数据导出 |

### 数据库表 `book_record`

```sql
CREATE TABLE book_record(
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  type     INTEGER NOT NULL,   -- 0 支出，1 收入
  amount   REAL    NOT NULL,
  remark   TEXT,
  createAt TEXT    NOT NULL    -- yyyy-MM-dd HH:mm:ss
);

CREATE INDEX idx_record_createAt ON book_record(createAt DESC);
```

`createAt` 统一用 `yyyy-MM-dd HH:mm:ss` 字符串，保证字符串排序等价于时间排序，按月统计可直接用 `createAt LIKE '2026-11%'`。

---

## 项目结构

```
lib/
├── main.dart                 # 入口：主题初始化 + MaterialApp
├── models/
│   └── record.dart           # Record 模型 + toMap / fromMap
├── db/
│   └── db_helper.dart        # 数据库单例：建表、CRUD、搜索、统计、迁移
├── services/
│   ├── theme_service.dart    # shared_preferences 主题读写
│   └── file_service.dart     # 文件导出 / 文本读写
├── utils/
│   └── date_util.dart        # 时间格式化
└── pages/
    ├── home_page.dart        # 首页
    ├── detail_page.dart      # 详情页
    └── profile_page.dart     # 个人中心
```

分层职责：`pages` 只负责渲染与交互，`db` / `services` 封装存储细节并对外暴露 `Future` 接口，`models` 负责 Map 与对象的转换，`utils` 放通用逻辑。

---

## 运行

```bash
flutter pub get
flutter run                # Android / iOS 真机或模拟器
flutter run -d windows     # Windows 桌面（已适配 sqflite FFI）
```

依赖：

```yaml
sqflite: ^2.4.1
shared_preferences: ^2.3.4
path_provider: ^2.1.5
path: ^1.9.1
sqflite_common_ffi: 2.3.3   # 仅桌面端调试用
sqlite3: ^2.4.0             # 与上面的 ffi 版本配套
```

> 桌面端 sqflite 没有原生实现，`main()` 中在 Windows 平台切换到 `databaseFactoryFfi`；Android / iOS 上该分支不执行，仍走原生 sqflite。

---

## 关键实现要点

- **主题持久化**：`shared_preferences` 不在 `build` 中同步读取，而是在 `initState` 里异步加载并用 `?? false` 兜底，避免首次读取返回 `null` 导致开关失效。
- **数据库调用**：所有 sqflite 操作均 `await`，UI 只在拿到结果后 `setState`。
- **条件查询**：搜索与筛选全部使用 `whereArgs` 参数化，杜绝 SQL 字符串拼接。
- **版本迁移**：`openDatabase(version: 1)` 配合 `onCreate` 建表、`onUpgrade` 预留迁移逻辑。
- **文件存储**：写 `getApplicationDocumentsDirectory()` 持久目录，不使用临时目录；文件读写均 `try/catch` 捕获 `FileSystemException`，读前先 `exists()`。
- **敏感数据**：本项目不存密码与 token；如后续扩展账号体系，应改用 `flutter_secure_storage`，禁止明文落盘。

---

## 演示路径

1. 首页展示本月统计与记账列表（数据来自 SQLite）
2. 点 FAB 新增一笔记录 → 列表即时刷新 → 关闭重开 App，记录仍在
3. 进入个人中心打开深色模式 → 关闭重开，主题仍生效
4. 点「数据导出」→ 提示导出路径，文档目录下生成 `record_export.json`
5. 点「清空本地数据」→ 列表清空，重开 App 仍为空
