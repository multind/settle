# 安顿 Settle 全量改名（产品化收尾）

日期：2026-11-26
状态：设计已批准（用户确认：直接改，不迁移数据）
前置：v0.3 收官后，分支 `milestone-1`，HEAD `f11ea65`，工作区干净，测试 200/200 全绿，analyze 0 error

## Goal（目标）

将产品从开发代号 `gtd_app`（GTD App）正式更名为 **安顿 Settle**（中文显示名「安顿」、
英文 "Settle"），完成一次**全量改名**：Flutter 包名、Dart import 前缀、Android
namespace/applicationId、Windows 窗口标题与 exe 版本资源、Inno Setup 安装包身份、
应用数据目录、应用内品牌展示点全部一次性改到位，并验证改名后 Windows 发布链路
（build → 测试 → analyze → 安装包 → 首启数据目录）完整可用。数据目录**直接换新、
不迁移**：旧库 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db` 保持原样不动，新库从空开始。

## Non-Goals（非目标）

- **不改功能**：M2/M3 全部功能、UI 结构、交互、数据库 schema 均不动。
- **不迁移旧数据**：旧 SQLite 库、旧 shared_preferences、旧 secure storage 一律不迁移、
  不删除（当前无人使用，直接冷启动新路径）。
- **不做 Android 发布**：本轮仅 Windows 桌面（Inno Setup）；Android 只把包名/label
  一次改对，不构建不发布。
- **不改代码签名 / 商店分发 / 自动更新**：沿用现有「不签名」策略。
- **不改历史文档**：`docs/superpowers/plans/`、`docs/superpowers/specs/`、
  `test/acceptance/milestone1_checklist.md` 中的历史记录保持原样。
- **不改品牌图标**：沿用 `windows/runner/resources/app_icon.ico`。
- **不重命名 GitHub 仓库**：目标仓库 `multind/settle` 为发布去向，不属于本仓库改动。

## Context（上下文 / 影响面盘点）

### 现网身份现状（改名前的完整盘点）

经全仓 grep（`gtd_app` / `dev.gtd` / `GTD` 三组模式）核实，`gtd_app` 在源码中共
**814 处**出现（含 build 产物与历史文档），按类别拆解如下：

| # | 类别 | 位置 | 计数 | 处理 |
|---|---|---|---|---|
| 1 | pubspec 包名 | `pubspec.yaml` | 1 | 改 `settle_app` |
| 2 | Dart import 前缀 | `lib/` 169 处 + `test/` 108 处 | 277 | 机械替换 `package:gtd_app/` → `package:settle_app/` |
| 3 | 数据库文件名 | `lib/data/app_database.dart` | 1 | 改 `settle_app.db` |
| 4 | 品牌展示面（非 import） | `app.dart`（`GtdApp` ×2、`title: 'GTD'`）、`responsive_shell.dart`（品牌字 `'GTD'` + 注释）、l10n `appTitle`（2 arb + 3 生成文件）、`main.dart`（`GtdApp`） | 9 处 Dart + 2 处 arb | 改 l10n 键 + 品牌字 + 类名 |
| 5 | Windows exe 身份 | `windows/CMakeLists.txt`（2）、`windows/runner/main.cpp`（1）、`windows/runner/Runner.rc`（6 值） | 9 | 改 BINARY_NAME / 窗口标题 / 版本资源 |
| 6 | Inno Setup 安装包 | `windows/installer/setup.iss`（6 行含 gtd/GTD，另含 AppId 更换） | 7 行 | 改 AppName/Publisher/ExeName/AppId/DirName/输出名/注释 |
| 7 | Android 身份 | `android/app/build.gradle.kts`（2）、`AndroidManifest.xml`（label） | 3 | 改 namespace/applicationId/label |
| 8 | 备份格式标识（盘点发现） | `export_service.dart`（`'app': 'gtd'` ×2 + `GTD backup` 错误文案）、`backup_file_gateway.dart`（对话框 + 文件名前缀） | 5 | 改 `settle` / `Settle backup` |
| 9 | 测试断言（盘点发现） | `export_service_test.dart`（3）、`settings_page_test.dart`（2）、`widget_utils.dart`（2：fake 路径 + `GtdApp` 注释）、`migration_test.dart`（2）、`app_smoke_test.dart`（`GtdApp` ×2） | 11 | 同步改断言/夹具 |
| 10 | 用户/发布文档 | `docs/release/windows.md`（4）、`README.md`（1） | 5 | 改发布文档 + README |
| — | **不改**：历史计划/规格文档（`docs/superpowers/`）、`test/acceptance/milestone1_checklist.md`、`build/`、`.dart_tool/`、`windows/flutter/ephemeral/`（插件 symlink）、`dist/`（gitignore）、`.superpowers/`（gitignore） | — | — | 保持原样 |

### 关键机制：Windows 数据目录从哪来

`getApplicationSupportDirectory()`（path_provider）在 Windows 上返回
`%APPDATA%\<CompanyName>\<ProductName>`，其中 CompanyName/ProductName 来自
exe 的版本资源（`windows/runner/Runner.rc`）。当前 = `%APPDATA%\dev.gtd\gtd_app\`，
再拼接 `app_database.dart` 硬编码的 `gtd_app.db`，得 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db`
（与 `docs/release/windows.md` 记载一致）。

**推论**：新数据路径不是靠移动目录实现的，而是由三处协同决定：
1. `Runner.rc` CompanyName `dev.gtd` → `dev.settle`；
2. `Runner.rc` ProductName `gtd_app` → `settle_app`；
3. `app_database.dart` 文件名 `gtd_app.db` → `settle_app.db`。
三处必须同一次改完，否则会落到「新目录 + 旧文件名」或「旧目录」的错位状态。
Windows 下 shared_preferences 同样写在该目录下（自动随迁，无数据则无影响）；
Android 的 applicationSupportDirectory 由 applicationId 推导（`/data/data/dev.settle.settle_app/...`），
随包名自动变更。

### 显示名现状

- Windows 窗口标题：`main.cpp` 初值 `L"gtd_app"` → Flutter 首帧后用
  `MaterialApp.onGenerateTitle`（l10n `appTitle`）覆盖，当前两语言均为 `GTD`。
- 应用内品牌：侧边栏 `_BrandMark` 硬编码 `'GTD'`；无「关于」页（已核实
  `settings_page.dart` 无 about/版本区块）；FAB 为收集按钮、不承载品牌名。
- Android launcher label：`android:label="gtd_app"`。
- 备份导出：文件对话框「Export GTD backup」、默认文件名 `gtd_backup_<ts>.json`、
  JSON 内 `"app":"gtd"` 格式标识。

## Proposed Architecture（架构决策）

### A. 命名映射（唯一事实源）

| 维度 | 改前 | 改后 |
|---|---|---|
| 中文显示名 | —（无） | **安顿** |
| 英文显示名 | GTD | **Settle** |
| Flutter 包名 / import 前缀 | `gtd_app` / `package:gtd_app/` | `settle_app` / `package:settle_app/` |
| Android namespace / applicationId | `dev.gtd.gtd_app` | `dev.settle.settle_app` |
| Windows exe 名（BINARY_NAME） | `gtd_app.exe` | `settle_app.exe` |
| 数据目录 | `%APPDATA%\dev.gtd\gtd_app\gtd_app.db` | `%APPDATA%\dev.settle\settle_app\settle_app.db` |
| 安装包 | `gtd_app-setup-{v}.exe` / `{autopf}\gtd_app` | `settle_app-setup-{v}.exe` / `{autopf}\Settle` |
| 安装程序显示名 | `gtd_app` / publisher `gtd` | `Settle` / publisher `Settle` |

### B. import 前缀替换策略（决策点 1）

**采用「全仓机械替换 + 编译门禁」**：

- 对 `lib/` 与 `test/` 下全部 `*.dart` 执行 `package:gtd_app/` → `package:settle_app/`
  纯文本替换（277 处）。安全性依据：grep 已证实在 Dart 源码中 `gtd_app` 除 import
  前缀外仅剩 1 处（`app_database.dart` 的 DB 文件名），不存在误伤面；
  替换后 `flutter pub get` 重建 `.dart_tool/package_config.json`。
- **不做逐文件人工核对**：277 处无差异、无歧义，人工核对性价比低且易漏。
- 门禁：`flutter analyze` 0 error（任何漏改必然产生 `URI 不存在` 编译错误，
  analyzer 全量覆盖）。

### C. AppId 保留与否（决策点 2）

**采用「更换新 GUID」**，新值 `49571859-C0F3-42B4-96BE-9F2832C8B373`
（Inno 写法 `{{49571859-C0F3-42B4-96BE-9F2832C8B373}`）。

理由：
- 现无真实用户（已确认），唯一潜在「旧安装」是开发机上的 0.1.1 测试安装；
- 保留旧 AppId 且把 `DefaultDirName` 从 `{autopf}\gtd_app` 改为 `{autopf}\Settle`
  时，Inno 的升级路径会在新目录安装、但**旧目录文件成为孤儿残留**（旧版本
  uninstaller 被替换后不再跟踪旧目录），反而制造脏状态；
- 更换 AppId = 完全干净的品牌断代，符合「全量改名」语义；代价仅是
  「如有 0.1.1 旧安装需先在系统『应用和功能』中手动卸载」——零用户前提下无成本。
- 配套：发布说明中注明旧版 gtd_app 需先卸载。

### D. 窗口标题 / 显示名（决策点 3）

- **`main.cpp` 初值**：`L"Settle"`（ASCII 安全，避免 C++ 源文件编码/宽字符
  转义风险；首帧后即被本地化标题覆盖）。
- **运行时标题（l10n）**：复用现有 `appTitle` 键（zh `安顿` / en `Settle`），
  作为**唯一事实源**：
  - `MaterialApp.title` 兜底 → `'Settle'`；
  - `MaterialApp.onGenerateTitle` 保持 `appTitle`（zh 环境窗口标题显示「安顿」）；
  - 侧边栏 `_BrandMark` 由硬编码 `'GTD'` 改为 `l10n.appTitle`（zh 显示「安顿」、
    en 显示「Settle」）。
- **不新增 `appName` 键**：`appTitle` 语义恰好是「窗口/应用标题」，改名后
  复用即可，避免两个键并存造成显示不一致。
- **Android label**：`android:label="Settle"`（ASCII 安全；本轮不发布 Android，
  不引入 `values-zh` 多语言 label，留待 Android 里程碑按 l10n 深化）。

### E. 数据目录（决策点 4，用户已确认）

- 新库路径：`%APPDATA%\dev.settle\settle_app\settle_app.db`（由 Runner.rc
  CompanyName/ProductName + DB 文件名三处协同实现，见 Context）。
- 旧库 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db`：**不动、不删、不迁移**。

### F. 备份格式标识（决策点 5，盘点新增）

- JSON 格式标识 `'app': 'gtd'` → `'app': 'settle'`（`version` 保持 1）。
- 导出对话框「Export GTD backup」→「Export Settle backup」；
  默认文件名 `gtd_backup_*.json` → `settle_backup_*.json`；
  错误文案「Not a valid GTD backup」→「Not a valid Settle backup」。
- 代价：gtd_app 0.1.1 时代导出的旧备份 JSON 将无法再导入（标识不符）。
  依据「无人使用 + 与不迁移决策一致的干净断代」接受此代价；
  同步更新相关测试断言与夹具。

### G. 类名与注释

- `GtdApp` → `SettleApp`（`app.dart` 定义 + `main.dart` 引用 + `app_smoke_test.dart`
  引用共 3 处代码、另 1 处注释），避免代码中残留旧品牌类名。
- 方法论概念注释（`anytime_page.dart` 等处「GTD 概念」）**保留**：
  GTD 是方法论名，非本产品品牌，不属于改名对象。
- `test/data/migration_test.dart` 的 `createTemp('gtd_migration_test')`、
  `widget_utils.dart` 的 `/fake/gtd_backup.json` 为测试局部标识，随改名一并
  换成 `settle_*` 保持全仓一致性（无功能影响）。

## Files To Change（文件改动清单）

逐项列出「改前 → 改后」；import 替换类（277 处）不逐行展开，按文件组说明。

### Dart 源码（lib/ + test/ 全量 import 替换）

`lib/`（169 处）与 `test/`（108 处）全部 `*.dart`：
`import 'package:gtd_app/...'` → `import 'package:settle_app/...'`。

### 包与元数据

| 文件 | 改前 | 改后 |
|---|---|---|
| `pubspec.yaml` | `name: gtd_app` | `name: settle_app` |
| `pubspec.yaml` | `description: "A new Flutter project."` | `description: "安顿 Settle — 本地优先的 GTD 个人任务管理应用"` |
| `README.md` | `# gtd_app` / `A new Flutter project.` | `# 安顿 Settle` / 一句话产品简介 |

### 应用身份与品牌（lib/）

| 文件 | 改前 | 改后 |
|---|---|---|
| `lib/app/app.dart` | `class GtdApp` / `const GtdApp` / `title: 'GTD'` | `class SettleApp` / `const SettleApp` / `title: 'Settle'` |
| `lib/main.dart` | `const GtdApp()` | `const SettleApp()` |
| `lib/app/responsive_shell.dart` | `_BrandMark` 内 `'GTD'`（及注释） | `AppLocalizations.of(context)!.appTitle`（及注释同步） |
| `lib/i18n/l10n/app_zh.arb` | `"appTitle": "GTD"` | `"appTitle": "安顿"` |
| `lib/i18n/l10n/app_en.arb` | `"appTitle": "GTD"` | `"appTitle": "Settle"` |
| `lib/i18n/l10n/app_localizations*.dart`（3 个生成文件） | `appTitle => 'GTD'` | 编辑 arb 后 `flutter gen-l10n` 重新生成（不改手写） |
| `lib/data/app_database.dart` | `gtd_app.db` | `settle_app.db` |

### 备份格式（lib/）

| 文件 | 改前 | 改后 |
|---|---|---|
| `lib/data/export_service.dart` | `'app': 'gtd'`（导出 + 导入校验两处）、`'Not a valid GTD backup'` | `'app': 'settle'`、`'Not a valid Settle backup'` |
| `lib/features/settings/backup_file_gateway.dart` | `'Export GTD backup'`、`'gtd_backup_...'` | `'Export Settle backup'`、`'settle_backup_...'` |

### Windows 原生（windows/）

| 文件 | 改前 | 改后 |
|---|---|---|
| `windows/CMakeLists.txt` | `project(gtd_app ...)`、`set(BINARY_NAME "gtd_app")` | `project(settle_app ...)`、`set(BINARY_NAME "settle_app")` |
| `windows/runner/main.cpp` | `window.Create(L"gtd_app", ...)` | `window.Create(L"Settle", ...)` |
| `windows/runner/Runner.rc` | `CompanyName "dev.gtd"`、`FileDescription/InternalName/OriginalFilename/ProductName` = `gtd_app(.exe)`、`LegalCopyright ... dev.gtd` | `dev.settle`、`settle_app(.exe)`、`... dev.settle`（OriginalFilename → `settle_app.exe`） |

### Inno Setup（windows/installer/setup.iss）

| 行 | 改前 | 改后 |
|---|---|---|
| `#define MyAppName` | `"gtd_app"` | `"Settle"` |
| `#define MyAppPublisher` | `"gtd"` | `"Settle"` |
| `#define MyAppExeName` | `"gtd_app.exe"` | `"settle_app.exe"` |
| `AppId` | `{{9F8E2C31-5A1D-4C0B-9E6A-2B7D4F3A8C21}`（旧 GUID） | `{{49571859-C0F3-42B4-96BE-9F2832C8B373}` |
| `DefaultDirName` | `{autopf}\gtd_app` | `{autopf}\Settle` |
| `OutputBaseFilename` | `gtd_app-setup-{#MyAppVersion}` | `settle_app-setup-{#MyAppVersion}` |
| 首行注释 | `; GTD App Windows 安装脚本` | `; 安顿 Settle Windows 安装脚本` |

（`DefaultGroupName={#MyAppName}` 自动变 `Settle`，快捷方式为
`{group}\Settle.lnk`、`{userdesktop}\Settle.lnk`。）

### Android（android/）

| 文件 | 改前 | 改后 |
|---|---|---|
| `android/app/build.gradle.kts` | `namespace = "dev.gtd.gtd_app"`、`applicationId = "dev.gtd.gtd_app"` | `dev.settle.settle_app`（两处） |
| `android/app/src/main/AndroidManifest.xml` | `android:label="gtd_app"` | `android:label="Settle"` |

### 测试（test/）

| 文件 | 改前 | 改后 |
|---|---|---|
| `test/data/export_service_test.dart` | `expect(map['app'], 'gtd')`；`'{"app":"gtd","version":99}'`；旧备份夹具 `'app': 'gtd'` | 全部 `'settle'`（夹具保留，仍验证缺字段兼容） |
| `test/widget/settings_page_test.dart` | `expect(map['app'], 'gtd')`；`pickedJson = '{"app":"gtd",...'` | 全部 `'settle'` |
| `test/widget/widget_utils.dart` | `'/fake/gtd_backup.json'`；注释提及 `GtdApp` | `'/fake/settle_backup.json'`；注释同步 |
| `test/data/migration_test.dart` | `createTemp('gtd_migration_test')`（2 处） | `createTemp('settle_migration_test')` |
| `test/widget/app_smoke_test.dart` | `const GtdApp()`、注释 | `const SettleApp()`、注释同步 |

### 发布文档（docs/）

| 文件 | 改动 |
|---|---|
| `docs/release/windows.md` | 全文同步：安装包名 `settle_app-setup-{v}.exe`、安装目录 `C:\Program Files\Settle`、exe `settle_app.exe`、数据路径 `%APPDATA%\dev.settle\settle_app\settle_app.db`；新增说明：旧 `gtd_app` 安装需先卸载、旧数据目录原样保留不迁移 |

### 明确不改

`docs/superpowers/plans/**`、`docs/superpowers/specs/**`（历史文档）、
`test/acceptance/milestone1_checklist.md`（历史验收记录）、`build/**`、`.dart_tool/**`、
`windows/flutter/ephemeral/**`（插件 symlink）、`dist/**`（gitignore，旧安装包
会被新安装包取代）。

## Testing Strategy（测试策略 / 验证清单）

验证分四层，全部通过才算改名完成：

1. **静态门禁**
   - `flutter pub get` 成功（重建 package_config）；
   - `flutter analyze` **0 error 0 warning**（漏改 import 必在此暴露）；
   - grep 审计：`lib/`、`test/`、`windows/`、`android/`、`pubspec.yaml`、
     `README.md`、`docs/release/windows.md` 中不再含 `gtd_app` / `dev.gtd` /
     `'GTD'` 品牌引用（历史文档 `docs/superpowers/**` 与
     `test/acceptance/milestone1_checklist.md` 除外）。
2. **全量回归**
   - `flutter test` **200/200 全绿**（含改名后的 export/import 断言、l10n 冒烟）。
3. **Windows 发布链路**
   - `flutter build windows --release` 产出
     `build\windows\x64\runner\Release\settle_app.exe`；
   - Inno 编译产出 `dist\settle_app-setup-{version}.exe`；
   - 静默安装冒烟：启动后进程存活、主窗口标题显示 `Settle`（英文环境，初始
     `main.cpp` 标题即 `Settle`）；切中文后标题变「安顿」。
4. **数据目录验证**
   - 首启后确认 `%APPDATA%\dev.settle\settle_app\settle_app.db` 已创建；
   - 确认 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db`（若存在）未被触碰/删除。

（Android 侧仅做一致性核对：`applicationId`/`namespace` 均已改
`dev.settle.settle_app`；可选 `flutter build apk --debug` 冒烟，不强制。）

## Risks And Mitigations（风险与缓解）

1. **import 替换漏改**（最可能的失败点）
   缓解：机械替换后以 `flutter analyze` 0 error 为硬门禁（漏改必然编译失败）；
   并以 grep 审计兜底（验证第 1 层）。
2. **陈旧构建产物 / package_config 残留旧名**导致诡异编译错误
   缓解：改名后先 `flutter clean` + `flutter pub get` 再 build；
   `.dart_tool/`、`build/` 不入库、可随时重建。
3. **数据目录错位**（Runner.rc 与 DB 文件名三处未同步）
   缓解：将三处改动（CompanyName、ProductName、`settle_app.db`）绑定为同一提交内
   的原子变更；验证清单第 4 层显式核对新路径落盘与旧路径未动。
4. **安装升级歧义**（旧 `{autopf}\gtd_app` 残留 / 新旧 AppId 并存）
   缓解：采用新 GUID + 发布说明注明先卸载旧版；`DefaultDirName` 同步改为
   `{autopf}\Settle` 避免目录重叠。
5. **备份格式断代**（旧 JSON 备份无法导入）
   缓解：已接受（零用户 + 干净断代）；测试夹具同步更新；发布说明不提旧备份兼容。

## Decision Summary（决策记录）

- **产品名**：中文「安顿」、英文 "Settle"；包名 `settle_app`；Android
  `dev.settle.settle_app`；exe `settle_app.exe`；安装目录 `{autopf}\Settle`。
- **import 策略**：全仓 277 处机械替换（lib 169 + test 108）+ analyze 门禁，不逐文件人工核对。
- **AppId**：更换新 GUID `{{49571859-C0F3-42B4-96BE-9F2832C8B373}`（干净断代；
  旧版需手动卸载）。
- **数据目录**：`%APPDATA%\dev.settle\settle_app\settle_app.db`，旧库不迁移不删除；
  由 Runner.rc CompanyName/ProductName + DB 文件名三处协同实现。
- **窗口标题**：`main.cpp` 初值 `L"Settle"`；运行时 l10n `appTitle`
  （zh 安顿 / en Settle）；`MaterialApp.title` 兜底 `'Settle'`。
- **显示名唯一事实源**：复用 `appTitle` 键，不新增 `appName`；`_BrandMark` 改用
  `l10n.appTitle`（zh 显示「安顿」）。
- **Android**：label `Settle`，本轮不发布、不引入 values-zh 多语言 label。
- **备份格式**：标识 `'gtd'` → `'settle'`（version 保持 1）；对话框/文件名/错误文案
  同步改 `Settle`；旧备份不再兼容（接受）。
- **类名**：`GtdApp` → `SettleApp`（3 处代码引用 + 1 处注释）；方法论「GTD 概念」注释保留。
- **历史文档**：`docs/superpowers/**` 与 `test/acceptance/milestone1_checklist.md` 不改。
- **版本号**：本次改名不升版（保持 `0.1.1+2`，与 `setup.iss` 的 `0.1.1` 一致）；
  正式发布打标时的升版另议（见开放问题）。

## 开放问题（Open Questions）

1. **发布版本号**：v0.3 功能已收官但 pubspec 仍为 `0.1.1+2`。本次改名不改号；
   正式对外发布（GitHub `multind/settle` 打标）时是否升到 `0.2.0`？留给发布计划决策。
2. **Android label 本地化**：当前 `android:label="Settle"` 单值；
   是否在 Android 里程碑引入 `values-zh` 使中文系统显示「安顿」？本轮不做。
3. **旧备份兼容**：已按「零用户」接受备份格式断代；若未来出现真实用户持有
   gtd_app 0.1.1 备份需要导入，可再加 `'settle'` 与 `'gtd'` 双标识兼容导入（本轮不做）。
