# 安顿 Settle 全量改名实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将产品从开发代号 `gtd_app` 全量更名为 **安顿 Settle**：Flutter 包名/import、Android 包名、Windows exe 身份与版本资源、Inno 安装包身份、数据目录、应用内品牌、备份格式标识一次改到位，并验证 Windows 发布链路与数据目录断代完整可用（旧数据不迁移）。

**Architecture:** 全仓机械替换 import 前缀（277 处）+ `flutter analyze` 编译门禁兜底漏改；品牌展示面统一收敛到 l10n `appTitle`（zh 安顿 / en Settle）单一事实源；数据目录由「Runner.rc CompanyName/ProductName + DB 文件名」三处协同决定，同一里程碑内完成、由验证清单第 4 层兜底；Inno 安装包换新 GUID 干净断代。

**Tech Stack:** Flutter/Dart、drift、Windows（CMake + Win32 runner + Inno Setup 6）、Android Gradle。

**Spec:** `docs/superpowers/specs/2026-11-26-settle-rename-design.md`

**基线（已确认）：** 分支 `milestone-1`，HEAD `77f2a61`，工作区干净，测试 200/200 全绿，analyze 0 error。

**环境约定（每步命令沿用）：**
- 所有 flutter 命令前先设置 `$env:PATH = "C:\flutter\bin;$env:PATH"`。
- 若 `flutter pub get` 因网络失败，先执行：
  `$env:HTTP_PROXY = "http://127.0.0.1:10808"; $env:HTTPS_PROXY = "http://127.0.0.1:10808"` 再重试（代理端口 10808）。
- ISCC 固定路径 `"C:\Users\EDY\AppData\Local\Programs\Inno Setup 6\ISCC.exe"`。
- 提交一律新提交，**不使用 --amend**；commit message 遵循仓库风格（feat/refactor/docs + 中文描述）。

**关键依赖说明（跨 Task）：**
- Task 2 的 `settle_app.db`（`lib/data/app_database.dart`）与 Task 4 的 Runner.rc `CompanyName`/`ProductName`（`dev.settle`/`settle_app`）是数据目录 `%APPDATA%\dev.settle\settle_app\settle_app.db` 的三处协同原子组合——**两处改动在同一里程碑内完成即可，不强行同 Task**，由 Task 6 验证清单第 4 层显式核对新路径落盘 + 旧路径未动。
- Task 5 的 setup.iss 编译（ISCC）依赖 `flutter build windows --release` 产物（Sources 指向 `build\windows\x64\runner\Release\*`），故 ISCC 编译放在 Task 6。
- Task 2 中 `app_smoke_test.dart` 的 `GtdApp` 引用必须与 `app.dart` 类改名同 Task 提交，否则 `flutter analyze` 编译失败（类名不存在）。

---

### Task 1: pubspec + import 机械替换（277 处）+ 重建门禁

**Files:**
- Modify: `pubspec.yaml`（第 1-2 行）
- Modify: `lib/**/*.dart` 与 `test/**/*.dart`（`package:gtd_app/` → `package:settle_app/`，277 处机械替换）

- [x] **Step 1: 改 pubspec 包名与描述**

`pubspec.yaml` 第 1-2 行：

改前：
```yaml
name: gtd_app
description: "A new Flutter project."
```
改后：
```yaml
name: settle_app
description: "安顿 Settle — 本地优先的 GTD 个人任务管理应用"
```

- [x] **Step 2: 全仓机械替换 import 前缀**

在仓库根目录执行（UTF-8 无 BOM 读写，保护中文注释编码）：

```powershell
cd D:\Project\gtd-project
$enc = New-Object System.Text.UTF8Encoding($false)
$files = Get-ChildItem -Path lib, test -Recurse -Filter *.dart
foreach ($f in $files) {
  $text = [System.IO.File]::ReadAllText($f.FullName, $enc)
  if ($text.Contains('package:gtd_app/')) {
    $text = $text.Replace('package:gtd_app/', 'package:settle_app/')
    [System.IO.File]::WriteAllText($f.FullName, $text, $enc)
  }
}
```

Expected: 无报错；`git diff --stat` 显示约 60 个 Dart 文件变更（lib 33 + test 27 上下，以实际为准）。

- [x] **Step 3: 验证替换无残留**

```powershell
cd D:\Project\gtd-project
git grep -c "package:gtd_app/" -- lib test
```

Expected: 无输出（0 匹配；git grep 无匹配时退出码为 1，属预期）。此时 `git grep -c "gtd_app" -- lib test` 应仅剩 1 处：`lib/data/app_database.dart` 的数据库文件名（Task 2 处理）。

- [x] **Step 4: flutter clean + pub get 重建 package_config**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter clean
flutter pub get
```

Expected: `flutter clean` 输出 Deleting 各目录；`flutter pub get` 末尾输出 `Got dependencies!`。若 pub get 网络失败，先按「环境约定」设置代理重试。若 `pubspec.lock` 有变更属正常（一并提交）。

- [x] **Step 5: analyze 门禁（漏改即编译失败）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-Object -Last 3
```

Expected: 输出 `No issues found!`；若出现汇总行，必须为 0 error 且 0 warning（仅允许既有 SDK 弃用 info）。

- [x] **Step 6: 提交**

```powershell
cd D:\Project\gtd-project
git add pubspec.yaml pubspec.lock lib test
git commit -m "refactor(core): 包名 gtd_app→settle_app（pubspec + lib/test 277 处 import 机械替换）"
```

Expected: 提交成功，`git status --short` 无该批残留。

---

### Task 2: 品牌面（SettleApp 类名 + l10n appTitle + 品牌字 + DB 文件名）

**Files:**
- Modify: `lib/app/app.dart`（`GtdApp` ×2、`title: 'GTD'`）
- Modify: `lib/main.dart`（`GtdApp` ×1）
- Modify: `test/widget/app_smoke_test.dart`（注释 + `const GtdApp()`，与类改名同 Task 防编译失败）
- Modify: `lib/app/responsive_shell.dart`（`_BrandMark` 注释 + `'GTD'`）
- Modify: `lib/i18n/l10n/app_zh.arb`、`lib/i18n/l10n/app_en.arb`（`appTitle`）
- Regenerate: `lib/i18n/l10n/app_localizations.dart`、`app_localizations_en.dart`、`app_localizations_zh.dart`（`flutter gen-l10n`，不改手写）
- Modify: `lib/data/app_database.dart`（`gtd_app.db` → `settle_app.db`，与 Task 4 Runner.rc 构成数据目录三处协同）

- [x] **Step 1: 改 `lib/app/app.dart` 类名与兜底标题**

改前：
```dart
/// 整应用入口（规格 §7.1 / §7.4）：双主题跟随系统 + 响应式外壳。
class GtdApp extends ConsumerWidget {
  const GtdApp({super.key});
```
改后：
```dart
/// 整应用入口（规格 §7.1 / §7.4）：双主题跟随系统 + 响应式外壳。
class SettleApp extends ConsumerWidget {
  const SettleApp({super.key});
```
并将第 16 行 `title: 'GTD',` 改为 `title: 'Settle',`（`MaterialApp.title` 兜底，运行时标题由 `onGenerateTitle` → l10n `appTitle` 覆盖）。

- [x] **Step 2: 改 `lib/main.dart` 引用**

改前：`    child: const GtdApp(),`
改后：`    child: const SettleApp(),`

- [x] **Step 3: 改 `test/widget/app_smoke_test.dart` 引用与注释**

改前（第 43 行注释）：`/// 整应用测试宿主：ProviderScope 注入内存库/mock prefs/Fake 网关 + GtdApp。`
改后：`/// 整应用测试宿主：ProviderScope 注入内存库/mock prefs/Fake 网关 + SettleApp。`

改前（第 46 行）：`      child: const GtdApp(),`
改后：`      child: const SettleApp(),`

- [x] **Step 4: 改 `lib/app/responsive_shell.dart` 品牌字 `_BrandMark`**

改前（第 599 行注释）：
```dart
/// 品牌字「GTD」（preview `.brand`）：普通 `text` 粗体文字，无渐变。
```
改后：
```dart
/// 品牌字（preview `.brand`）：普通 `text` 粗体文字，无渐变；文案取 l10n appTitle（zh 安顿 / en Settle）。
```
改前（第 610 行）：
```dart
      child: Text(
        'GTD',
        style: TextStyle(
```
改后：
```dart
      child: Text(
        AppLocalizations.of(context)!.appTitle,
        style: TextStyle(
```
（`AppLocalizations` 已在文件第 10 行 import，无需新增。）

- [x] **Step 5: 改两个 arb 的 appTitle**

`lib/i18n/l10n/app_zh.arb` 第 3 行：`"appTitle": "GTD",` → `"appTitle": "安顿",`
`lib/i18n/l10n/app_en.arb` 第 3 行：`"appTitle": "GTD",` → `"appTitle": "Settle",`

- [x] **Step 6: 重新生成 l10n（不改手写生成文件）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter gen-l10n
```

Expected: 输出含 `Generated`；`lib/i18n/l10n/app_localizations_en.dart` 第 13 行变为 `String get appTitle => 'Settle';`、`app_localizations_zh.dart` 变为 `=> '安顿';`、`app_localizations.dart` 文档注释 `/// **'GTD'**` 变为 `/// **'Settle'**`。若生成文件整体格式有 SDK 版本差异属正常，照常提交。

- [x] **Step 7: 改 `lib/data/app_database.dart` 数据库文件名**

改前（第 9 行）：
```dart
  final file = File('${dir.path}${Platform.pathSeparator}gtd_app.db');
```
改后：
```dart
  final file = File('${dir.path}${Platform.pathSeparator}settle_app.db');
```

> **数据目录三处协同说明**：本步（DB 文件名）与 Task 4 的 Runner.rc `CompanyName "dev.settle"` + `ProductName "settle_app"` 共同决定新路径 `%APPDATA%\dev.settle\settle_app\settle_app.db`。三处跨 Task 但同一里程碑完成，Task 6 第 4 层验证兜底核对。

- [x] **Step 8: analyze + 受影响测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-Object -Last 3
flutter test test/widget/l10n_smoke_test.dart test/widget/app_smoke_test.dart test/widget/responsive_shell_test.dart 2>&1 | Select-Object -Last 1
```

Expected: `No issues found!`（或仅 info）；`All tests passed!`。

- [x] **Step 9: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/app/app.dart lib/main.dart lib/app/responsive_shell.dart lib/i18n/l10n lib/data/app_database.dart test/widget/app_smoke_test.dart
git commit -m "feat(brand): 安顿 Settle 品牌落地（SettleApp 类名/l10n appTitle/_BrandMark/DB 文件名）"
```

---

### Task 3: 备份格式标识 + 测试断言同步

**Files:**
- Modify: `lib/data/export_service.dart`（3 处）
- Modify: `lib/features/settings/backup_file_gateway.dart`（2 处）
- Modify: `test/data/export_service_test.dart`（3 处断言/夹具）
- Modify: `test/widget/settings_page_test.dart`（2 处）
- Modify: `test/widget/widget_utils.dart`（fake 路径 + 注释）
- Modify: `test/data/migration_test.dart`（2 处 createTemp）

- [x] **Step 1: 改 `lib/data/export_service.dart` 格式标识与错误文案**

改前（第 31 行）：`      'app': 'gtd',`
改后：`      'app': 'settle',`

改前（第 46 行）：`    if (data['app'] != 'gtd' || data['version'] != 1) {`
改后：`    if (data['app'] != 'settle' || data['version'] != 1) {`

改前（第 47 行）：`      throw const FormatException('Not a valid GTD backup');`
改后：`      throw const FormatException('Not a valid Settle backup');`

- [x] **Step 2: 改 `lib/features/settings/backup_file_gateway.dart` 对话框与文件名**

改前（第 21 行）：`      dialogTitle: 'Export GTD backup',`
改后：`      dialogTitle: 'Export Settle backup',`

改前（第 22 行）：`      fileName: 'gtd_backup_${DateTime.now().millisecondsSinceEpoch}.json',`
改后：`      fileName: 'settle_backup_${DateTime.now().millisecondsSinceEpoch}.json',`

- [x] **Step 3: 改 `test/data/export_service_test.dart` 断言与夹具**

改前（第 46 行）：`    expect(map['app'], 'gtd');`
改后：`    expect(map['app'], 'settle');`

改前（第 82 行）：`    expect(() => service.importJson('{"app":"gtd","version":99}'), throwsFormatException);`
改后：`    expect(() => service.importJson('{"app":"settle","version":99}'), throwsFormatException);`

改前（第 124 行，旧备份夹具）：`      'app': 'gtd',`
改后：`      'app': 'settle',`
（夹具仍保留「缺新字段」语义，继续验证缺字段按缺省还原。）

- [x] **Step 4: 改 `test/widget/settings_page_test.dart`**

改前（第 36 行）：`    expect(map['app'], 'gtd');`
改后：`    expect(map['app'], 'settle');`

改前（第 42 行）：`    env.backup.pickedJson = '{"app":"gtd","version":1,"exported_at":1,'`
改后：`    env.backup.pickedJson = '{"app":"settle","version":1,"exported_at":1,'`

- [x] **Step 5: 改 `test/widget/widget_utils.dart` fake 路径与注释**

改前（第 18 行）：`    return '/fake/gtd_backup.json';`
改后：`    return '/fake/settle_backup.json';`

改前（第 26 行）：`/// 注意：不 import app.dart（GtdApp 到 Task 33 才创建）；`
改后：`/// 注意：不 import app.dart（SettleApp 由 app_smoke_test.dart 内自行组装）；`

- [x] **Step 6: 改 `test/data/migration_test.dart` createTemp（2 处）**

第 13 行与第 43 行均：`Directory.systemTemp.createTemp('gtd_migration_test')` → `Directory.systemTemp.createTemp('settle_migration_test')`（逐行替换，共 2 处）。

- [x] **Step 7: 受影响测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test test/data/export_service_test.dart test/widget/settings_page_test.dart test/data/migration_test.dart test/widget/app_smoke_test.dart 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`。

- [x] **Step 8: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/data/export_service.dart lib/features/settings/backup_file_gateway.dart test/data/export_service_test.dart test/widget/settings_page_test.dart test/widget/widget_utils.dart test/data/migration_test.dart
git commit -m "refactor(backup): 备份格式标识 gtd→settle（对话框/文件名/错误文案/测试断言同步）"
```

---

### Task 4: Windows 原生身份 + Android 身份

**Files:**
- Modify: `windows/CMakeLists.txt`（2 处）
- Modify: `windows/runner/main.cpp`（1 处）
- Modify: `windows/runner/Runner.rc`（6 值版本资源）
- Modify: `android/app/build.gradle.kts`（2 处）
- Modify: `android/app/src/main/AndroidManifest.xml`（1 处）
- Move + Modify: `android/app/src/main/kotlin/dev/gtd/gtd_app/MainActivity.kt` → `android/app/src/main/kotlin/dev/settle/settle_app/MainActivity.kt`（spec 盘点遗漏项：包路径必须随 namespace 同步，否则未来 Android 构建 `.MainActivity` 解析失败）

- [x] **Step 1: 改 `windows/CMakeLists.txt` 工程名与 exe 名**

改前（第 3 行）：`project(gtd_app LANGUAGES CXX)`
改后：`project(settle_app LANGUAGES CXX)`

改前（第 7 行）：`set(BINARY_NAME "gtd_app")`
改后：`set(BINARY_NAME "settle_app")`

（`windows/runner/CMakeLists.txt` 使用 `${BINARY_NAME}` 变量，无需改动。）

- [x] **Step 2: 改 `windows/runner/main.cpp` 窗口标题初值**

改前（第 30 行）：`  if (!window.Create(L"gtd_app", origin, size)) {`
改后：`  if (!window.Create(L"Settle", origin, size)) {`
（ASCII 安全；首帧后由 l10n `appTitle` 覆盖为 安顿/Settle。）

- [x] **Step 3: 改 `windows/runner/Runner.rc` 版本资源 6 值**

改前（第 92 行）：`            VALUE "CompanyName", "dev.gtd" "\0"`
改后：`            VALUE "CompanyName", "dev.settle" "\0"`

改前（第 93 行）：`            VALUE "FileDescription", "gtd_app" "\0"`
改后：`            VALUE "FileDescription", "settle_app" "\0"`

改前（第 95 行）：`            VALUE "InternalName", "gtd_app" "\0"`
改后：`            VALUE "InternalName", "settle_app" "\0"`

改前（第 96 行）：`            VALUE "LegalCopyright", "Copyright (C) 2026 dev.gtd. All rights reserved." "\0"`
改后：`            VALUE "LegalCopyright", "Copyright (C) 2026 dev.settle. All rights reserved." "\0"`

改前（第 97 行）：`            VALUE "OriginalFilename", "gtd_app.exe" "\0"`
改后：`            VALUE "OriginalFilename", "settle_app.exe" "\0"`

改前（第 98 行）：`            VALUE "ProductName", "gtd_app" "\0"`
改后：`            VALUE "ProductName", "settle_app" "\0"`

> **数据目录三处协同说明**：本步 `CompanyName "dev.settle"` + `ProductName "settle_app"` 与 Task 2 的 `settle_app.db` 共同决定 `%APPDATA%\dev.settle\settle_app\settle_app.db`；Task 6 第 4 层验证兜底核对（新路径落盘 + 旧路径未动）。

- [x] **Step 4: Windows debug 构建门禁（提前暴露 C++/RC 编译错误）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter build windows --debug
```

Expected: 构建成功；`Test-Path build\windows\x64\runner\Debug\settle_app.exe` → `True`。

- [x] **Step 5: 提交 Windows 侧**

```powershell
cd D:\Project\gtd-project
git add windows/CMakeLists.txt windows/runner/main.cpp windows/runner/Runner.rc
git commit -m 'feat(windows): exe 身份改名 settle_app（BINARY_NAME/窗口标题 L"Settle"/版本资源 dev.settle）'
```
（消息用单引号包裹，PowerShell 双引号字符串不识别 `\"` 转义。）

- [x] **Step 6: 改 `android/app/build.gradle.kts` namespace 与 applicationId**

改前（第 8 行）：`    namespace = "dev.gtd.gtd_app"`
改后：`    namespace = "dev.settle.settle_app"`

改前（第 19 行）：`        applicationId = "dev.gtd.gtd_app"`
改后：`        applicationId = "dev.settle.settle_app"`

- [x] **Step 7: 改 `android/app/src/main/AndroidManifest.xml` label**

改前（第 3 行）：`        android:label="gtd_app"`
改后：`        android:label="Settle"`
（本轮不发布 Android、不引入 values-zh 多语言 label，留待 Android 里程碑。）

- [x] **Step 8: 移动并改写 MainActivity.kt 包路径**

```powershell
cd D:\Project\gtd-project
New-Item -ItemType Directory -Force android\app\src\main\kotlin\dev\settle\settle_app | Out-Null
git mv android/app/src/main/kotlin/dev/gtd/gtd_app/MainActivity.kt android/app/src/main/kotlin/dev/settle/settle_app/MainActivity.kt
Remove-Item android\app\src\main\kotlin\dev\gtd -Recurse -Force
```

再将 `android/app/src/main/kotlin/dev/settle/settle_app/MainActivity.kt` 第 1 行：
改前：`package dev.gtd.gtd_app`
改后：`package dev.settle.settle_app`

（manifest 中 `android:name=".MainActivity"` 相对 namespace 解析，包路径必须与 namespace 一致。）

- [x] **Step 9: Android 一致性门禁**

```powershell
cd D:\Project\gtd-project
git grep -n "gtd_app\|dev\.gtd" -- android
```

Expected: 无输出（0 匹配）。可选冒烟（不强制）：`flutter build apk --debug` 成功。

- [x] **Step 10: 提交 Android 侧**

```powershell
cd D:\Project\gtd-project
git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/dev/settle
git commit -m "refactor(android): 包名 dev.gtd.gtd_app→dev.settle.settle_app（含 MainActivity 包路径迁移）"
```

---

### Task 5: Inno Setup 安装包 + 发布文档 + README

**Files:**
- Modify: `windows/installer/setup.iss`（7 行）
- Modify: `docs/release/windows.md`（全文重写）
- Modify: `README.md`（全文重写）

- [x] **Step 1: 改 `windows/installer/setup.iss`（7 行）**

改前（第 1 行）：`; GTD App Windows 安装脚本 — Inno Setup 6`
改后：`; 安顿 Settle Windows 安装脚本 — Inno Setup 6`

改前（第 2 行）：`#define MyAppName "gtd_app"`
改后：`#define MyAppName "Settle"`

改前（第 4 行）：`#define MyAppPublisher "gtd"`
改后：`#define MyAppPublisher "Settle"`

改前（第 5 行）：`#define MyAppExeName "gtd_app.exe"`
改后：`#define MyAppExeName "settle_app.exe"`

改前（第 8 行）：`AppId={{9F8E2C31-5A1D-4C0B-9E6A-2B7D4F3A8C21}`
改后：`AppId={{49571859-C0F3-42B4-96BE-9F2832C8B373}`

改前（第 12 行）：`DefaultDirName={autopf}\gtd_app`
改后：`DefaultDirName={autopf}\Settle`

改前（第 18 行）：`OutputBaseFilename=gtd_app-setup-{#MyAppVersion}`
改后：`OutputBaseFilename=settle_app-setup-{#MyAppVersion}`

（`DefaultGroupName={#MyAppName}` 自动变 `Settle`；快捷方式随之 `Settle.lnk`。ISCC 编译验证在 Task 6——依赖 release 构建产物。）

- [x] **Step 2: 全文重写 `docs/release/windows.md`**

写入以下完整内容（覆盖原 28 行）：

```markdown
# Windows 桌面发布（安顿 Settle）

## 产物

- 安装包：`dist\settle_app-setup-0.1.1.exe`（Inno Setup 6.7.4，x64，不签名，机器级安装）
- 便携目录：`build\windows\x64\runner\Release\`（解压即用）

## 重新发布步骤

1. 升版：改 `pubspec.yaml` 的 `version`，并同步 `windows/installer/setup.iss` 的 `MyAppVersion`
2. `flutter build windows --release`
3. `& "C:\Users\EDY\AppData\Local\Programs\Inno Setup 6\ISCC.exe" windows\installer\setup.iss`
4. 产物出现在 `dist\`

## 分发注意事项

- 安装包**未做代码签名**：首次运行 Windows SmartScreen 提示"未知发布者"，
  需点"更多信息 → 仍要运行"。面向个人/内部分发可接受；若要消除提示需购买
  代码签名证书并重新签名。
- 安装为**机器级**（默认安装到 `C:\Program Files\Settle`，需要管理员权限；
  安装器会自动触发 UAC 提权）。卸载入口在系统「应用和功能」中。
- **旧版 gtd_app 需先卸载**：本版更换了全新安装标识（AppId），旧版
  `gtd_app-setup-0.1.1.exe` 的安装不会被自动升级，请先在「应用和功能」中
  卸载旧版再安装新版。
- 版本号在 `pubspec.yaml` 维护，打包脚本读取固定版本 `0.1.1`——升版时同步改
  `setup.iss` 的 `MyAppVersion`。

## 数据说明

- 应用数据落于 `%APPDATA%\dev.settle\settle_app\settle_app.db`（本地 SQLite，
  卸载安装包不删除用户数据）。
- 旧版数据目录 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db` **原样保留、不迁移不删除**：
  本次改名直接换新路径，旧数据冷启动弃用。
```

- [x] **Step 3: 全文重写 `README.md`**

写入以下完整内容（覆盖原 3 行）：

```markdown
# 安顿 Settle

本地优先的 GTD 个人任务管理应用（Flutter，Windows 桌面优先）。
```

- [x] **Step 4: setup.iss grep 门禁（纯改名产物零残留）**

```powershell
cd D:\Project\gtd-project
git grep -n "gtd_app\|dev\.gtd\|GTD" -- windows/installer/setup.iss
```

Expected: 无输出（0 匹配）。
> **门禁修正（协调者裁定，2026-11-26）**：计划 Step 2-3 指定的 windows.md/README 内容**必须**点名
> 旧版（「旧版 gtd_app 需先卸载」「旧库 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db` 原样保留」）与 GTD
> 方法论术语（README「本地优先的 GTD…」，spec 明确方法论名保留）——若对三文件统一执行 0 匹配门禁
> 将与强制内容自相矛盾。故门禁收窄为**纯改名产物 setup.iss 零残留**；docs 中旧版引用视为有意的
> 卸载/断代说明放行（Task 6 Step 3 审计已同步豁免 docs/release/windows.md）。

- [x] **Step 5: 提交（安装包 + 文档分开两个提交）**

```powershell
cd D:\Project\gtd-project
git add windows/installer/setup.iss
git commit -m "feat(installer): 安装包改名 Settle（新 AppId 49571859/目录 {autopf}\Settle/输出名 settle_app-setup）"
git add docs/release/windows.md README.md
git commit -m "docs(release): windows.md/README 同步安顿 Settle（旧版卸载说明 + 数据目录断代）"
```

---

### Task 6: 全量回归 + 四层验证

**Files:** 无新增改动（纯验证；若验证暴露问题，修复走独立提交）。

- [ ] **Step 1: 全量回归（验证层 2）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（基线 200/200，以实际输出计数为准，须全部通过）。

- [ ] **Step 2: 全仓 analyze（验证层 1）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-Object -Last 3
```

Expected: `No issues found!`；若出现汇总行，必须 0 error 且 0 warning（仅允许既有 SDK 弃用 info）。

- [ ] **Step 3: grep 审计（验证层 1）**

```powershell
cd D:\Project\gtd-project
git grep -n "gtd_app\|dev\.gtd" -- lib test windows android pubspec.yaml README.md ":(exclude)test/acceptance/milestone1_checklist.md" ":(exclude)docs/release/windows.md"
git grep -n "'GTD'\|GTD backup\|gtd_backup\|Export GTD" -- lib test windows android pubspec.yaml README.md ":(exclude)test/acceptance/milestone1_checklist.md" ":(exclude)docs/release/windows.md"
git status --short docs/superpowers test/acceptance/milestone1_checklist.md
```

Expected: 前两条命令均无输出（0 匹配；git grep 无匹配退出码为 1，属预期）；`docs/release/windows.md` 豁免——其中「旧版 gtd_app / gtd_app-setup-0.1.1.exe / dev.gtd\gtd_app\gtd_app.db」为 Task 5 指定的有意卸载/断代说明（协调者裁定，见 Task 5 Step 4 门禁修正）；README「GTD」为方法论术语（spec 明确保留），不匹配第二条模式。第三条仅允许显示本计划文件 `docs/superpowers/plans/2026-11-26-settle-rename.md`（计划文档自身的正常提交状态），历史计划/规格文档与 `milestone1_checklist.md` 必须零改动。

- [ ] **Step 4: release 构建（验证层 3）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter build windows --release
Test-Path build\windows\x64\runner\Release\settle_app.exe
```

Expected: 构建成功；`Test-Path` 输出 `True`。

- [ ] **Step 5: ISCC 编译安装包（验证层 3）**

```powershell
cd D:\Project\gtd-project
& "C:\Users\EDY\AppData\Local\Programs\Inno Setup 6\ISCC.exe" windows\installer\setup.iss
Test-Path dist\settle_app-setup-0.1.1.exe
```

Expected: 输出末尾含 `Successful compile of windows\installer\setup.iss`；`Test-Path` 输出 `True`。

- [ ] **Step 6: 静默安装 + 首启冒烟（验证层 3，半自动——UAC 可能需人工点「是」）**

```powershell
cd D:\Project\gtd-project
Start-Process -FilePath "dist\settle_app-setup-0.1.1.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait
Test-Path "C:\Program Files\Settle\settle_app.exe"
```

Expected: 安装完成；`Test-Path` 输出 `True`。注意：机器级安装触发 UAC 提权——若当前终端未提权且弹出 UAC 提示，需人工点「是」（或将本步放在管理员终端执行）。

- [ ] **Step 7: 首启验证窗口标题（验证层 3，半自动——标题随系统语言）**

```powershell
Start-Process "C:\Program Files\Settle\settle_app.exe"
Start-Sleep -Seconds 6
(Get-Process settle_app | Select-Object -First 1).MainWindowTitle
```

Expected: 进程存活、`MainWindowTitle` 非空；zh 系统为「安顿」、en 系统为「Settle」（首帧前初值来自 main.cpp `L"Settle"`）。随后人工冒烟（可选）：在应用内「设置」切语言，窗口标题随之在 安顿↔Settle 间切换。验证完执行 `Stop-Process -Name settle_app`。

- [ ] **Step 8: 数据目录验证（验证层 4，首启前先记录旧路径状态）**

```powershell
$oldDb = "$env:APPDATA\dev.gtd\gtd_app\gtd_app.db"
$oldBefore = Test-Path $oldDb
$oldStamp = if ($oldBefore) { (Get-Item $oldDb).LastWriteTimeUtc } else { $null }
# 首启（Step 7 已启动过应用）后核对：
$newExists = Test-Path "$env:APPDATA\dev.settle\settle_app\settle_app.db"
$oldAfter = Test-Path $oldDb
$oldStamp2 = if ($oldAfter) { (Get-Item $oldDb).LastWriteTimeUtc } else { $null }
"new_path_exists=$newExists"
"old_unchanged=$($oldAfter -eq $oldBefore -and $oldStamp2 -eq $oldStamp)"
```

Expected: `new_path_exists=True`（`%APPDATA%\dev.settle\settle_app\settle_app.db` 已创建）；`old_unchanged=True`（旧路径存在性未变、LastWriteTime 未变——旧库未被触碰/删除）。

- [ ] **Step 9: 工作区与提交记录确认**

```powershell
cd D:\Project\gtd-project
git status --short
git log --oneline -10
```

Expected: 工作区干净；改名各 Task 提交齐全（refactor(core) → feat(brand) → refactor(backup) → feat(windows) → refactor(android) → feat(installer) → docs(release)）。

> 可选收尾：移除测试安装 `& "C:\Program Files\Settle\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART`（保留安装亦可继续试用）。

---

## 自审记录

- **Spec 覆盖（10 类影响面）**：① pubspec → T1；② import 277 处 → T1；③ DB 文件名 → T2；④ 品牌展示面（app.dart/main.dart/_BrandMark/arb×2/生成文件）→ T2；⑤ Windows exe 身份（CMakeLists×2/main.cpp/Runner.rc 6 值）→ T4；⑥ Inno setup.iss 7 行 → T5；⑦ Android（gradle×2/manifest label）→ T4；⑧ 备份格式（export_service 3 处 + gateway 2 处）→ T3；⑨ 测试断言（export_service_test 3 / settings_page_test 2 / widget_utils 2 / migration_test 2 / app_smoke_test 2）→ T3（app_smoke_test 的 GtdApp 因编译依赖移入 T2）；⑩ 文档（windows.md/README）→ T5。四层验证 → T6。
- **盘点补充（spec 遗漏项）**：`android/app/src/main/kotlin/dev/gtd/gtd_app/MainActivity.kt` 的包路径与 `package` 声明随 namespace 一并迁移（T4 Step 8）——否则未来 Android 构建 `.MainActivity` 相对 namespace 解析失败，且 android/ 路径 grep 审计不过。
- **依赖修正**：app_smoke_test.dart 的 `GtdApp` → `SettleApp` 从 T3 移入 T2，与 `app.dart` 类改名同 Task——否则 T2 的 analyze 门禁会因类不存在而失败。
- **占位符扫描**：无 TBD/TODO/「实现 X」；所有文件改动给出完整改前/改后内容或完整新文件内容。
- **类型/标识一致性**：`SettleApp`（app.dart/main.dart/app_smoke_test）三处一致；`settle_app`（pubspec/import/DB 文件名/BINARY_NAME/版本资源/setup.iss）全链路一致；`dev.settle.settle_app`（gradle/Manifest/MainActivity 包路径）一致；备份标识 `'settle'`（export_service + 5 个测试文件断言）一致；l10n `appTitle` 复用为品牌唯一事实源（arb×2 + _BrandMark + MaterialApp.title 兜底 'Settle'）。
- **依赖说明**：T1 → T2/T4 前置（pub get 重建 package_config 后才可编译）；T2 与 T4 跨 Task 构成数据目录三处协同（T6 第 4 层兜底）；T5 setup.iss 编译依赖 T6 release 构建产物（ISCC 放 T6）；T4 Windows debug 构建门禁前置暴露 C++/RC 错误。
- **风险预案**：import 漏改 → analyze 0 error 硬门禁 + T6 grep 审计双兜底；陈旧构建产物 → T1 flutter clean + pub get；数据目录错位 → 三处协同同一里程碑 + T6 第 4 层显式核对；安装升级歧义 → 新 GUID + windows.md 注明先卸载旧版；备份断代 → 已接受（零用户），夹具同步更新。
