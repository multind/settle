# Milestone 1: GTD 核心地基 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付规格 §8.1 的里程碑 1 —— 一个纯本地、无 AI 的 GTD 应用地基：Flutter 手机+桌面响应式壳、Drift 本地库（6 实体+关联表）、收件箱快速收集、手动理清、项目/情境/等待/将来也许视图、手动回顾、设置页（语言切换+JSON 导出/恢复）与中英双语骨架。

**Architecture:** 三层解耦（界面层 → GTD 核心层 → 数据层）。界面只调用 Repository/Service（经 Riverpod Provider 注入，无全局单例）；GTD 核心层含领域枚举、状态流转规则与理清用例（ClarifyService），不依赖任何 AI 代码；数据层为 Drift/SQLite，schemaVersion=1 并建立迁移步骤机制，为 M2 加表留缝。响应式由 `LayoutBuilder` 600px 断点切换：窄屏底部导航 5 项（收件箱/今日/项目/回顾/设置），宽屏 NavigationRail 8 项（收件箱/今日/项目/情境/等待/将来也许/回顾/设置）。

**Tech Stack:** Flutter (Dart 3) + Drift/SQLite + Riverpod + flutter_localizations/ARB（中英）+ shared_preferences（语言设置）+ file_picker（备份文件选择）+ flutter_secure_storage（仅依赖接入，M2 使用）+ path_provider。无任何 AI 依赖、无网络依赖（HTTP 包不引入）。

---

## 环境假设（本计划编写时的检测结果）

- 仓库 `D:\Project\gtd-project`：已 git init，规格已提交（c5ef1f8）；`.gitignore` 尚未提交（任务 1 处理）。
- **Flutter/Dart SDK 未安装**（`flutter`、`dart` 命令均不存在）。任务 2 负责安装。
- Node v22 已安装（与本计划无关，仅环境记录）。
- Windows 10/11，PowerShell。所有命令均为 PowerShell 语法。
- `winget` 假定可用（Windows 10 1809+ / 11 自带）。若机器缺 Visual Studio/Android 工具链，任务 3 用 winget 安装。

## File Structure（M1 落盘清单）

```
lib/
  main.dart                              # 入口：异步打开 DB/SharedPreferences，注入 ProviderScope
  app/
    app.dart                             # GtdApp：MaterialApp + 主题 + 本地化 delegates
    theme.dart                           # buildAppTheme()：Material 3 种子色
    responsive_shell.dart                # LayoutBuilder 600px 断点：NavigationRail / NavigationBar + 全局 FAB
  core/
    enums.dart                           # 领域枚举 + 存储名映射（spec §5.1 字符串值）
    models/
      task_draft.dart                    # TaskDraft 值对象（Task 表单/创建的载体）
      clarify_decision.dart              # ClarifyDecision sealed 类（task/project/delete）
    workflow/
      clarify_service.dart               # 理清用例：InboxItem → Task/Project/删除（§5.2 流转）
  data/
    tables.dart                          # Drift 表定义 + AppDatabase（schemaVersion、种子情境、迁移入口）
    app_database.dart                    # openAppDatabase()：文件连接工厂
    migrations/
      migration_steps.dart               # 迁移步骤注册表（M1 为空，机制就位）
    repositories/
      inbox_repository.dart              # InboxItem CRUD + markClarified
      task_repository.dart               # Task CRUD + 状态流转规则 + 标签绑定
      project_repository.dart            # Project CRUD + 级联删除任务
      context_repository.dart            # Context CRUD + 删除置空 task.context_id
      tag_repository.dart                # Tag CRUD + 删除解绑
      review_repository.dart             # Review CRUD
    export_service.dart                  # 全库 JSON 导出/恢复
    providers.dart                       # databaseProvider / sharedPreferencesProvider / 各 Repository Provider
  features/
    inbox/
      inbox_page.dart                    # 收件箱列表（原文/来源徽标/状态）
      quick_collect_bar.dart             # 顶部常驻快速收集框
      collect_dialog.dart                # 全局快速收集对话框（shell FAB 复用）
      clarify_dialog.dart                # 理清向导（行动/项目/删除）
    task/
      task_form_fields.dart              # Task 全字段表单（澄清与编辑复用）
      task_edit_dialog.dart              # 编辑既有 Task
    today/
      today_page.dart                    # 下一步行动列表（优先级/截止日排序）
    projects/
      projects_page.dart                 # 项目列表 + 卡片下任务
      project_dialog.dart                # 新建/编辑项目
    contexts/
      contexts_page.dart                 # 情境管理
    waiting/
      waiting_page.dart                  # status=waiting 过滤视图
    someday/
      someday_page.dart                  # status=someday 过滤视图
    review/
      review_page.dart                   # 手动回顾（总结+统计）
    settings/
      settings_page.dart                 # 语言切换 / 备份导出恢复 / AI 占位
      settings_controller.dart           # SettingsController（StateNotifier<LocaleSelection>）
      backup_file_gateway.dart           # BackupFileGateway 抽象 + FilePicker 实现
  i18n/
    l10n/app_en.arb                      # 英文文案
    l10n/app_zh.arb                      # 中文文案
l10n.yaml                                # gen-l10n 配置
test/
  test_utils.dart                        # createTestDatabase()（内存库 + Windows sqlite3.dll override）
  data/
    enums_test.dart
    database_test.dart
    migration_test.dart
    inbox_repository_test.dart
    project_repository_test.dart
    context_repository_test.dart
    tag_repository_test.dart
    task_repository_test.dart
    review_repository_test.dart
    clarify_service_test.dart
    export_service_test.dart
    providers_test.dart
  widget/
    widget_utils.dart                    # TestEnv：内存库 + mock prefs + FakeBackupGateway
    l10n_smoke_test.dart
    quick_collect_test.dart
    inbox_page_test.dart
    task_form_fields_test.dart
    task_edit_dialog_test.dart
    clarify_dialog_test.dart
    today_page_test.dart
    projects_page_test.dart
    contexts_page_test.dart
    waiting_someday_test.dart
    review_page_test.dart
    responsive_shell_test.dart
    settings_page_test.dart
    app_smoke_test.dart
  acceptance/
    milestone1_checklist.md              # 验收走查清单（规格 §8.1 十项）
tool/windows/sqlite3.dll                 # 测试用原生库（下载，gitignore）
```

每文件单一职责；`core/` 无任何 flutter/UI 依赖，`data/` 无任何 UI 依赖，`features/` 只依赖 Provider 注入的 Repository。

---

## Phase A：环境准备与脚手架

### Task 1: 提交 .gitignore（仓库收尾）

**Files:**
- Commit: `.gitignore`

- [ ] **Step 1: 查看仓库状态**

Run: `git status --short`
Expected: 输出包含 `?? .gitignore`（未跟踪）。

- [ ] **Step 2: 提交 .gitignore**

```powershell
git add .gitignore
git commit -m "chore: 提交 .gitignore（Flutter/Dart/密钥忽略规则）"
```
Expected: 提交成功，`git log --oneline` 显示新提交。

### Task 2: 检查并安装 Flutter SDK

**Files:**
- Modify: 系统 PATH（PowerShell 会话级即可；如需持久化见说明）

- [ ] **Step 1: 检查 Flutter 是否已安装**

Run: `flutter --version`
Expected: 若输出版本号（如 `Flutter 3.x.x`）→ 本任务已完成，跳到 Task 3。若报 `无法将“flutter”项识别为 cmdlet…CommandNotFoundException` → 继续 Step 2。

- [ ] **Step 2: 克隆 Flutter stable 到 C:\flutter**

```powershell
git clone -b stable https://github.com/flutter/flutter.git C:\flutter
```
Expected: 输出 `Receiving objects: 100%` 且 `C:\flutter\bin` 存在。

- [ ] **Step 3: 将 flutter 加入当前会话 PATH 并触发首次下载**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter config --no-analytics
flutter --version
```
Expected: `flutter --version` 输出 Dart SDK 版本与 Flutter 版本号（首次运行会自动下载 Dart SDK，等待完成即可）。

- [ ] **Step 4: 验证**

Run: `where.exe flutter`
Expected: 输出 `C:\flutter\bin\flutter`。若希望所有新终端可用，追加系统 PATH：`[Environment]::SetEnvironmentVariable("Path", $env:PATH + ";C:\flutter\bin", "User")`（可选，不影响本计划后续任务——每个任务都在当前会话执行）。

- [ ] **Step 5: Commit（无代码变更，本步跳过）** — 环境步骤不产生仓库变更，直接进入 Task 3。

### Task 3: flutter doctor 检查并补齐 Windows 桌面与 Android 工具链

**Files:**
- None（纯环境）

- [ ] **Step 1: 运行 flutter doctor**

Run: `flutter doctor`
Expected: 逐项检查。重点关注：
- `[√] Flutter`（Channel stable）
- `[√] Windows Version`
- `[√] Visual Studio`（Windows 桌面构建需要 VS 2022 + “使用 C++ 的桌面开发”工作负载）
- `[√] Android toolchain`（Android SDK / cmdline-tools）

若以上均打勾 → 本任务完成，进入 Task 4。缺失项按以下分支补齐。

- [ ] **Step 2（若 Visual Studio 缺失）: 用 winget 安装 VS 2022 Build Tools（含 C++ 桌面负载）**

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --includeRecommended"
```
Expected: 安装完成（此步耗时较长，可能 5–20 分钟）。重新运行 `flutter doctor`，`[√] Visual Studio` 打勾。

- [ ] **Step 3（若 Android toolchain 缺失）: 安装 Android Studio（含 SDK）**

```powershell
winget install Google.AndroidStudio --silent --accept-package-agreements --accept-source-agreements
```
Expected: 安装完成。首次运行 Android Studio 会安装 SDK（也可手动点开一次让它初始化）。

- [ ] **Step 4: 接受 Android 许可证并确认 SDK 路径**

```powershell
flutter doctor --android-licenses
```
按提示输入 `y` 接受所有许可证。若 SDK 未被 flutter 识别，指定路径：
```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
```
Expected: `flutter doctor` 中 `[√] Android toolchain` 打勾。

- [ ] **Step 5: 最终确认**

Run: `flutter doctor`
Expected: Windows 桌面与 Android 两条工具链均为 `[√]`。若某平台工具链仍缺失，记录在验收走查清单（Task 35）中作为已知限制，不阻塞其余任务。

### Task 4: 准备测试用 sqlite3.dll（Windows 主机跑 Drift 内存库必需）

**Files:**
- Create: `tool/windows/sqlite3.dll`（下载产物，加入 .gitignore）
- Modify: `.gitignore`

说明：`flutter test` 在宿主机 VM 运行，Drift 的 `NativeDatabase.memory()` 需要宿主可加载的 sqlite3.dll；`sqlite3_flutter_libs` 只在 App 运行时生效，对测试无效。故下载官方 dll 并由 `test/test_utils.dart` 显式加载（Task 10 使用）。

- [ ] **Step 1: 修改 .gitignore 忽略该 dll**

```powershell
Add-Content -Path .gitignore -Value "`n# 测试用原生库（下载产物）`ntool/windows/"
```
Expected: `.gitignore` 末尾新增两行。若上面单行命令因引号问题失败，直接用编辑工具把以下内容追加到 `.gitignore` 末尾：

```text

# 测试用原生库（下载产物）
tool/windows/
```

- [ ] **Step 2: 下载官方 sqlite3.dll（Windows x64，版本 3.46.1，URL 历史保留可稳定获取）**

```powershell
New-Item -ItemType Directory -Force -Path tool\windows | Out-Null
Invoke-WebRequest -Uri "https://www.sqlite.org/2024/sqlite-dll-win-x64-3460100.zip" -OutFile "$env:TEMP\sqlite-dll.zip"
Expand-Archive -Path "$env:TEMP\sqlite-dll.zip" -DestinationPath "$env:TEMP\sqlite-dll" -Force
Copy-Item "$env:TEMP\sqlite-dll\sqlite3.dll" tool\windows\sqlite3.dll
Remove-Item "$env:TEMP\sqlite-dll.zip", "$env:TEMP\sqlite-dll" -Recurse -Force
```
Expected: `tool\windows\sqlite3.dll` 存在，大小约 1.9 MB。若下载失败（URL 404），到 https://www.sqlite.org/download.html 取当前 Windows x64 dll zip，调整上述 URL 后重跑。

- [ ] **Step 3: 验证 dll 可加载**

Run: `Get-Item tool\windows\sqlite3.dll | Select-Object Length`
Expected: `Length` 输出为 `19xxxxx` 数量级（非 0）。

- [ ] **Step 4: Commit**

```powershell
git add .gitignore
git commit -m "chore: 忽略测试用 sqlite3.dll 下载目录"
```
Expected: 提交成功（dll 本身不提交）。

### Task 5: flutter create 脚手架（android + windows）

**Files:**
- Create: 全部脚手架（`pubspec.yaml`、`analysis_options.yaml`、`android/`、`windows/`、`lib/main.dart` 等）

- [ ] **Step 1: 生成脚手架（当前目录，项目名 gtd_app，仅 android+windows，空模板）**

```powershell
flutter create . --project-name gtd_app --org dev.gtd --platforms android,windows --empty
```
Expected: 输出 `All done!`，目录下出现 `android/`、`windows/`、`lib/main.dart`、`pubspec.yaml`。规格文档与计划文件不会被覆盖。

- [ ] **Step 2: 删除可能生成的示例测试（若存在）**

```powershell
if (Test-Path test\widget_test.dart) { Remove-Item test\widget_test.dart }
```
Expected: 无输出（或已删除）。

- [ ] **Step 3: 拉取依赖**

Run: `flutter pub get`
Expected: 输出 `Got dependencies!`（无报错）。

- [ ] **Step 4: 首次 Windows 桌面构建验证**

Run: `flutter build windows --debug`
Expected: 输出 `Built build\windows\x64\runner\Debug\gtd_app.exe`。若报缺少 Visual Studio 工具链，回到 Task 3 Step 2。

- [ ] **Step 5: 首次 Android 构建验证**

Run: `flutter build apk --debug`
Expected: 输出 `Built build\app\outputs\flutter-apk\app-debug.apk`。若 Gradle 下载慢属正常，等待完成即可。

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "chore: flutter create 脚手架（android+windows，空模板）"
```
Expected: 提交成功，`flutter analyze` 无 error（空模板下应为零告警或仅 lint 提示）。

---

## Phase B：i18n 骨架与数据层（TDD）

### Task 6: 声明 pubspec 依赖并验证解析

**Files:**
- Modify: `pubspec.yaml`（dependencies / dev_dependencies 段）

- [ ] **Step 1: 覆写 pubspec.yaml 的 dependencies 与 dev_dependencies 段**

把 `pubspec.yaml` 中 `dependencies:` 到文件尾（`flutter:` 段之前）整段替换为：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  flutter_riverpod: ^2.5.1
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
  file_picker: ^8.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.20.0
  build_runner: ^2.4.11

flutter:
  uses-material-design: true
  generate: true
```

（保留 `name: gtd_app`、`description:`、`publish_to: 'none'`、`version:`、`environment:` 段不动。`generate: true` 启用 gen-l10n 自动生成。）

- [ ] **Step 2: 拉取依赖**

Run: `flutter pub get`
Expected: 输出 `Got dependencies!`，无 version solving 冲突。

- [ ] **Step 3: 验证 secure_storage 依赖可解析（M1 仅接入，不写代码）**

Run: `flutter pub deps | Select-String "flutter_secure_storage"`
Expected: 输出含 `flutter_secure_storage` 行（版本号）。

- [ ] **Step 4: Commit**

```powershell
git add pubspec.yaml pubspec.lock
git commit -m "build: 声明 M1 依赖（drift/riverpod/secure_storage/localizations/file_picker）"
```
Expected: 提交成功。

### Task 7: l10n 配置与中英 ARB 骨架（先写失败测试）

**Files:**
- Create: `l10n.yaml`
- Create: `lib/i18n/l10n/app_en.arb`
- Create: `lib/i18n/l10n/app_zh.arb`
- Test: `test/widget/l10n_smoke_test.dart`

- [ ] **Step 1: 写失败测试（引用尚未生成的 AppLocalizations）**

`test/widget/l10n_smoke_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zh locale loads Chinese nav strings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(l10n.navInbox);
      }),
    ));
    expect(find.text('收件箱'), findsOneWidget);
    expect(AppLocalizations.of(tester.element(find.byType(Text)))!.navToday, '今日');
  });

  testWidgets('en locale loads English nav strings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        return Text(AppLocalizations.of(context)!.navInbox);
      }),
    ));
    expect(find.text('Inbox'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/l10n_smoke_test.dart`
Expected: FAIL，编译错误 `URI 不存在 package:gtd_app/i18n/l10n/app_localizations.dart`（生成的类还不存在）。

- [ ] **Step 3: 创建 l10n.yaml**

`l10n.yaml`：

```yaml
arb-dir: lib/i18n/l10n
template-arb-file: app_en.arb
output-localizations-file: app_localizations.dart
```

- [ ] **Step 4: 创建英文 ARB**

`lib/i18n/l10n/app_en.arb`：

```json
{
  "@@locale": "en",
  "appTitle": "GTD",
  "navInbox": "Inbox",
  "navToday": "Today",
  "navProjects": "Projects",
  "navContexts": "Contexts",
  "navWaiting": "Waiting",
  "navSomeday": "Someday",
  "navReview": "Review",
  "navSettings": "Settings",
  "quickCollectHint": "Capture something…",
  "collectAction": "Collect",
  "add": "Add",
  "save": "Save",
  "cancel": "Cancel",
  "delete": "Delete",
  "confirmDeleteTitle": "Delete?",
  "confirmDeleteBody": "This action cannot be undone.",
  "confirmDeleteInbox": "Permanently delete this inbox item?",
  "confirmDeleteProject": "Delete this project and all its tasks?",
  "sourceText": "Text",
  "sourceVoice": "Voice",
  "sourceShare": "Share",
  "sourceImage": "Image",
  "statusPending": "Pending",
  "statusClarified": "Clarified",
  "clarify": "Clarify",
  "emptyInbox": "Inbox is empty. Capture your first thought above.",
  "emptyTasks": "Nothing here yet.",
  "taskTitle": "Title",
  "taskNotes": "Notes",
  "taskDueDate": "Due date",
  "taskScheduled": "Scheduled",
  "taskEnergy": "Energy",
  "taskPriority": "Priority",
  "taskStatus": "Status",
  "taskWaitingOn": "Waiting on",
  "taskProject": "Project",
  "taskContext": "Context",
  "taskTags": "Tags",
  "noProject": "No project",
  "noContext": "No context",
  "statusNextAction": "Next action",
  "statusWaiting": "Waiting",
  "statusSomeday": "Someday",
  "statusDone": "Done",
  "decisionAction": "Turn into action",
  "decisionProject": "Turn into project",
  "decisionDelete": "Delete",
  "projectName": "Project name",
  "projectGoal": "Goal",
  "newProject": "New project",
  "editProject": "Edit project",
  "editTask": "Edit task",
  "markDone": "Done",
  "reopen": "Reopen",
  "reviewSummary": "Summary",
  "reviewDone": "Tasks done",
  "reviewNew": "New tasks",
  "reviewStalled": "Stalled",
  "saveReview": "Save review",
  "newReview": "New review",
  "language": "Language",
  "langSystem": "Follow system",
  "langZh": "中文",
  "langEn": "English",
  "exportBackup": "Export backup (JSON)",
  "importBackup": "Restore backup (JSON)",
  "exportedTo": "Backup exported",
  "importedFrom": "Backup restored",
  "backupInvalid": "Invalid backup file",
  "aiPlaceholder": "AI model config (available in M2)",
  "waitingOnRequired": "Waiting on is required for waiting tasks.",
  "todayTitle": "Today"
}
```

- [ ] **Step 5: 创建中文 ARB**

`lib/i18n/l10n/app_zh.arb`：

```json
{
  "@@locale": "zh",
  "appTitle": "GTD",
  "navInbox": "收件箱",
  "navToday": "今日",
  "navProjects": "项目",
  "navContexts": "情境",
  "navWaiting": "等待",
  "navSomeday": "将来也许",
  "navReview": "回顾",
  "navSettings": "设置",
  "quickCollectHint": "写下你要收集的事情…",
  "collectAction": "收集",
  "add": "添加",
  "save": "保存",
  "cancel": "取消",
  "delete": "删除",
  "confirmDeleteTitle": "确定删除？",
  "confirmDeleteBody": "此操作不可撤销。",
  "confirmDeleteInbox": "确定永久删除这条收件箱条目？",
  "confirmDeleteProject": "确定删除该项目及其下所有任务？",
  "sourceText": "文本",
  "sourceVoice": "语音",
  "sourceShare": "分享",
  "sourceImage": "图片",
  "statusPending": "待理清",
  "statusClarified": "已理清",
  "clarify": "理清",
  "emptyInbox": "收件箱是空的，在上方写下第一条想法。",
  "emptyTasks": "这里还没有内容。",
  "taskTitle": "标题",
  "taskNotes": "备注",
  "taskDueDate": "截止日",
  "taskScheduled": "计划时间",
  "taskEnergy": "精力",
  "taskPriority": "优先级",
  "taskStatus": "状态",
  "taskWaitingOn": "在等谁/等什么",
  "taskProject": "所属项目",
  "taskContext": "情境",
  "taskTags": "标签",
  "noProject": "无项目",
  "noContext": "无情境",
  "statusNextAction": "下一步",
  "statusWaiting": "等待",
  "statusSomeday": "将来也许",
  "statusDone": "完成",
  "decisionAction": "转为行动",
  "decisionProject": "转为项目",
  "decisionDelete": "删除",
  "projectName": "项目名称",
  "projectGoal": "目标/期望结果",
  "newProject": "新建项目",
  "editProject": "编辑项目",
  "editTask": "编辑任务",
  "markDone": "完成",
  "reopen": "重新打开",
  "reviewSummary": "总结",
  "reviewDone": "完成任务数",
  "reviewNew": "新增任务数",
  "reviewStalled": "搁置任务数",
  "saveReview": "保存回顾",
  "newReview": "新建回顾",
  "language": "语言",
  "langSystem": "跟随系统",
  "langZh": "中文",
  "langEn": "English",
  "exportBackup": "导出备份（JSON）",
  "importBackup": "恢复备份（JSON）",
  "exportedTo": "备份已导出",
  "importedFrom": "备份已恢复",
  "backupInvalid": "备份文件无效",
  "aiPlaceholder": "AI 模型配置（M2 启用）",
  "waitingOnRequired": "等待任务必须填写等待对象。",
  "todayTitle": "今日"
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/widget/l10n_smoke_test.dart`
Expected: PASS（`flutter test` 会自动触发 gen-l10n，生成 `package:gtd_app/i18n/l10n/app_localizations.dart`）。

- [ ] **Step 7: Commit**

```powershell
git add l10n.yaml lib/i18n pubspec.yaml
git commit -m "feat(i18n): 中英 ARB 骨架与 gen-l10n 配置"
```
Expected: 提交成功。

### Task 8: 核心领域枚举、TaskDraft 与 ClarifyDecision

**Files:**
- Create: `lib/core/enums.dart`
- Create: `lib/core/models/task_draft.dart`
- Create: `lib/core/models/clarify_decision.dart`
- Test: `test/data/enums_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/enums_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';

void main() {
  test('InboxStatus 存储名符合规格 §5.1', () {
    expect(InboxStatus.pending.storage, 'pending');
    expect(InboxStatus.clarified.storage, 'clarified');
    expect(InboxStatus.fromStorage('pending'), InboxStatus.pending);
    expect(InboxStatus.fromStorage('clarified'), InboxStatus.clarified);
  });

  test('TaskStatus 存储名符合规格 §5.1', () {
    expect(TaskStatus.nextAction.storage, 'next_action');
    expect(TaskStatus.waiting.storage, 'waiting');
    expect(TaskStatus.someday.storage, 'someday');
    expect(TaskStatus.done.storage, 'done');
    expect(TaskStatus.fromStorage('next_action'), TaskStatus.nextAction);
    expect(TaskStatus.fromStorage('waiting'), TaskStatus.waiting);
    expect(TaskStatus.fromStorage('someday'), TaskStatus.someday);
    expect(TaskStatus.fromStorage('done'), TaskStatus.done);
  });

  test('ProjectStatus 存储名符合规格 §5.1', () {
    expect(ProjectStatus.active.storage, 'active');
    expect(ProjectStatus.done.storage, 'done');
    expect(ProjectStatus.someday.storage, 'someday');
    expect(ProjectStatus.fromStorage('active'), ProjectStatus.active);
  });

  test('TaskSource 存储名符合规格 §5.1', () {
    expect(TaskSource.text.storage, 'text');
    expect(TaskSource.voice.storage, 'voice');
    expect(TaskSource.share.storage, 'share');
    expect(TaskSource.image.storage, 'image');
    expect(TaskSource.fromStorage('voice'), TaskSource.voice);
  });

  test('Energy/Priority 存储名', () {
    expect(EnergyLevel.low.storage, 'low');
    expect(EnergyLevel.medium.storage, 'medium');
    expect(EnergyLevel.high.storage, 'high');
    expect(PriorityLevel.low.storage, 'low');
    expect(PriorityLevel.high.storage, 'high');
    expect(EnergyLevel.fromStorage('medium'), EnergyLevel.medium);
  });

  test('LocaleSelection 与语言映射', () {
    expect(LocaleSelection.system.locale, isNull);
    expect(LocaleSelection.zh.locale, const Locale('zh'));
    expect(LocaleSelection.en.locale, const Locale('en'));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/enums_test.dart`
Expected: FAIL，编译错误（`enums.dart` 不存在）。

- [ ] **Step 3: 创建 lib/core/enums.dart**

```dart
import 'dart:ui' show Locale;

/// 领域枚举：存储值统一为 TEXT 枚举名（规格 §5.1）。
/// [storage] 是写入数据库的字符串；[fromStorage] 负责读取映射。
enum InboxStatus {
  pending('pending'),
  clarified('clarified');

  const InboxStatus(this.storage);
  final String storage;
  static InboxStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum TaskStatus {
  nextAction('next_action'),
  waiting('waiting'),
  someday('someday'),
  done('done');

  const TaskStatus(this.storage);
  final String storage;
  static TaskStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum ProjectStatus {
  active('active'),
  done('done'),
  someday('someday');

  const ProjectStatus(this.storage);
  final String storage;
  static ProjectStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum TaskSource {
  text('text'),
  voice('voice'),
  share('share'),
  image('image');

  const TaskSource(this.storage);
  final String storage;
  static TaskSource fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum EnergyLevel {
  low('low'),
  medium('medium'),
  high('high');

  const EnergyLevel(this.storage);
  final String storage;
  static EnergyLevel? fromStorageOrNull(String? value) =>
      value == null ? null : values.firstWhere((e) => e.storage == value);
}

enum PriorityLevel {
  low('low'),
  medium('medium'),
  high('high');

  const PriorityLevel(this.storage);
  final String storage;
  static PriorityLevel? fromStorageOrNull(String? value) =>
      value == null ? null : values.firstWhere((e) => e.storage == value);
}

/// 语言选择：system=跟随系统（locale 为 null）。
enum LocaleSelection {
  system(null),
  zh(Locale('zh')),
  en(Locale('en'));

  const LocaleSelection(this.locale);
  final Locale? locale;
}
```

- [ ] **Step 4: 创建 lib/core/models/task_draft.dart**

```dart
import 'package:gtd_app/core/enums.dart';

/// Task 创建/编辑表单的载体。所有字段可空，[title] 必填。
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.notes,
    this.status = TaskStatus.nextAction,
    this.waitingOn,
    this.dueDate,
    this.scheduled,
    this.energy,
    this.priority,
    this.projectId,
    this.contextId,
    this.tagIds = const {},
  });

  final String title;
  final String? notes;
  final TaskStatus status;
  final String? waitingOn;
  final DateTime? dueDate;
  final DateTime? scheduled;
  final EnergyLevel? energy;
  final PriorityLevel? priority;
  final int? projectId;
  final int? contextId;
  final Set<int> tagIds;
}
```

- [ ] **Step 5: 创建 lib/core/models/clarify_decision.dart**

```dart
import 'package:gtd_app/core/models/task_draft.dart';

/// 理清判定结果（规格 §5.2）：转 Task / 转 Project / 删除。
sealed class ClarifyDecision {}

class ClarifyToTask extends ClarifyDecision {
  const ClarifyToTask(this.draft);
  final TaskDraft draft;
}

class ClarifyToProject extends ClarifyDecision {
  const ClarifyToProject({required this.name, this.goal});
  final String name;
  final String? goal;
}

class ClarifyDelete extends ClarifyDecision {}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/data/enums_test.dart`
Expected: PASS（4 组枚举 + 1 组 LocaleSelection 全绿）。

- [ ] **Step 7: Commit**

```powershell
git add lib/core test/data/enums_test.dart
git commit -m "feat(core): 领域枚举存储映射、TaskDraft 与 ClarifyDecision"
```
Expected: 提交成功。

### Task 9: Drift 表定义（6 实体 + 关联表）+ AppDatabase + codegen

**Files:**
- Create: `lib/data/tables.dart`
- Create: `lib/data/app_database.dart`
- Create: `lib/data/migrations/migration_steps.dart`
- Test: `test/test_utils.dart`
- Test: `test/data/database_test.dart`

- [ ] **Step 1: 写失败测试（表与库尚未生成）**

`test/data/database_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('schemaVersion 为 1（迁移机制基线）', () {
    expect(db.schemaVersion, 1);
  });

  test('首次创建自动播种三个默认情境', () async {
    final contexts = await db.select(db.contexts).get();
    expect(contexts.map((c) => c.name).toList(), ['@电脑', '@外出', '@电话']);
  });

  test('tags.name 唯一约束生效', () async {
    await db.into(db.tags).insert(TagsCompanion.insert(name: '报告', color: '#1A73E8'));
    expect(
      () => db.into(db.tags).insert(TagsCompanion.insert(name: '报告', color: '#FF0000')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('tasks 表四个索引存在（规格 §5.1）', () async {
    final rows = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='tasks'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(
        ['idx_tasks_project', 'idx_tasks_context', 'idx_tasks_status', 'idx_tasks_due_date']));
  });

  test('插入 InboxItem 后可按 id 读回', () async {
    final id = await db.into(db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '写周报',
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
    final row = await (db.select(db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(row.rawText, '写周报');
    expect(row.status, 'pending');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/database_test.dart`
Expected: FAIL，编译错误（`test_utils.dart`、`tables.dart` 不存在）。

- [ ] **Step 3: 创建 test/test_utils.dart（Windows 宿主加载 sqlite3.dll + 内存库）**

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:sqlite3/open.dart';

/// Windows 宿主机加载 tool/windows/sqlite3.dll（flutter test 在宿主 VM 运行，
/// sqlite3_flutter_libs 对测试无效）。每个直接构造 AppDatabase 的测试文件
/// 都必须在 main() 开头调用 [setupSqliteHost]（Drift 原生库按测试 isolate 加载）。
void setupSqliteHost() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () {
      final dll = File('tool/windows/sqlite3.dll').absolute;
      return DynamicLibrary.open(dll.path);
    });
  }
}

/// 测试用内存数据库。
AppDatabase createTestDatabase() {
  setupSqliteHost();
  return AppDatabase(NativeDatabase.memory());
}
```

- [ ] **Step 4: 创建 lib/data/migrations/migration_steps.dart（迁移注册表，M1 为空）**

```dart
import 'package:drift/drift.dart';

/// 迁移步骤注册表：下标 n 对应 "从版本 n 升级到版本 n+1" 的步骤。
/// M1 schemaVersion = 1，无升级步骤；M2 起在此追加（如 references 表）。
final List<Future<void> Function(Migrator m)> migrationSteps = [];

/// 按版本区间依次执行迁移步骤。
Future<void> applyMigrations(Migrator m, int from, int to) async {
  for (var version = from; version < to; version++) {
    final step = migrationSteps[version - 1];
    if (step != null) {
      await step(m);
    }
  }
}
```

- [ ] **Step 5: 创建 lib/data/tables.dart（全部表 + AppDatabase）**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/data/migrations/migration_steps.dart';

class InboxItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get source => text()(); // text / voice / share / image
  TextColumn get aiHint => text().nullable()(); // M2
  TextColumn get promptVersion => text().nullable()(); // M2
  TextColumn get status => text()(); // pending / clarified
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text().nullable()();
  TextColumn get status => text()(); // active / done / someday
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class Contexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text()(); // 如 #1A73E8
}

@TableIndex(name: 'idx_tasks_project', columns: {#projectId})
@TableIndex(name: 'idx_tasks_context', columns: {#contextId})
@TableIndex(name: 'idx_tasks_status', columns: {#status})
@TableIndex(name: 'idx_tasks_due_date', columns: {#dueDate})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()(); // next_action / waiting / someday / done
  IntColumn get dueDate => integer().nullable()();
  IntColumn get scheduled => integer().nullable()();
  TextColumn get energy => text().nullable()(); // low / medium / high
  TextColumn get priority => text().nullable()(); // low / medium / high
  TextColumn get waitingOn => text().nullable()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get contextId => integer().nullable().references(Contexts, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class TaskTags extends Table {
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()(); // 当日起始毫秒
  TextColumn get summary => text().nullable()();
  TextColumn get stats => text().nullable()(); // {"done":n,"new":n,"stalled":n}
  TextColumn get aiReport => text().nullable()(); // M2
  IntColumn get createdAt => integer()();
}

@DriftDatabase(tables: [InboxItems, Tasks, Projects, Contexts, Tags, TaskTags, Reviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultContexts();
        },
        onUpgrade: (m, from, to) async {
          await applyMigrations(m, from, to);
        },
      );

  Future<void> _seedDefaultContexts() async {
    final existing = await (select(contexts)..limit(1)).get();
    if (existing.isNotEmpty) return;
    await into(contexts).insert(ContextsCompanion.insert(name: '@电脑', sort: const Value(0)));
    await into(contexts).insert(ContextsCompanion.insert(name: '@外出', sort: const Value(1)));
    await into(contexts).insert(ContextsCompanion.insert(name: '@电话', sort: const Value(2)));
  }
}
```

- [ ] **Step 6: 创建 lib/data/app_database.dart（文件连接工厂）**

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gtd_app/data/tables.dart';

/// 应用运行时的数据库连接（文件持久化）。
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}gtd_app.db');
  return AppDatabase(NativeDatabase(file));
}
```

- [ ] **Step 7: 生成 Drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 输出 `Succeeded after ...` 且生成 `lib/data/tables.g.dart`。

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/data/database_test.dart`
Expected: PASS（5 个测试全绿）。

- [ ] **Step 9: Commit**

```powershell
git add lib/data test/test_utils.dart test/data/database_test.dart
git commit -m "feat(data): Drift 六实体+关联表定义、AppDatabase、种子情境与迁移注册表"
```
Expected: 提交成功。

### Task 10: 迁移机制测试（schemaVersion 持久化往返）

**Files:**
- Test: `test/data/migration_test.dart`

- [ ] **Step 1: 写失败测试（验证建库→写数据→关闭→重开→数据仍在）**

`test/data/migration_test.dart`：

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  // 本文件直接构造 AppDatabase（不经 createTestDatabase），须显式加载宿主 dll。
  setupSqliteHost();

  test('v1 库关闭后重开数据保留，schemaVersion 不变（迁移机制基线）', () async {
    final dir = await Directory.systemTemp.createTemp('gtd_migration_test');
    final file = File('${dir.path}${Platform.pathSeparator}test.db');

    final db1 = AppDatabase(NativeDatabase(file));
    final id = await db1.into(db1.projects).insert(ProjectsCompanion.insert(
      name: '客户交付',
      status: 'active',
      createdAt: 1000,
      updatedAt: 1000,
    ));
    await db1.close();

    final db2 = AppDatabase(NativeDatabase(file));
    expect(db2.schemaVersion, 1);
    final row = await (db2.select(db2.projects)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, '客户交付');
    expect(row.status, 'active');
    await db2.close();

    await dir.delete(recursive: true);
  });

  test('迁移步骤表为空时 applyMigrations 幂等不报错', () async {
    final db = createTestDatabase();
    expect(db.schemaVersion, 1);
    await db.close();
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/migration_test.dart`
Expected: 编译失败或 FAIL（`test_utils.dart` 已存在时第一个测试因 sqlite3.dll 或 API 问题报错；若全部通过说明实现已满足，仍保留测试）。

- [ ] **Step 3: 最小实现**

说明：迁移机制（`AppDatabase.migration` 与 `applyMigrations`）已在 Task 9 就位；本任务无新增实现代码，仅验证。若 Step 2 显示测试通过，直接到 Step 4。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/migration_test.dart`
Expected: PASS（2 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add test/data/migration_test.dart
git commit -m "test(data): 迁移机制往返测试（重开库数据保留）"
```
Expected: 提交成功。

### Task 11: InboxRepository（TDD）

**Files:**
- Create: `lib/data/repositories/inbox_repository.dart`
- Test: `test/data/inbox_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/inbox_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late InboxRepository repo;
  setUp(() {
    db = createTestDatabase();
    repo = InboxRepository(db);
  });
  tearDown(() => db.close());

  test('add 创建 pending 条目并带时间戳', () async {
    final item = await repo.add(rawText: '写周报', source: TaskSource.text);
    expect(item.rawText, '写周报');
    expect(item.source, 'text');
    expect(item.status, 'pending');
    expect(item.createdAt, greaterThan(0));
    expect(item.updatedAt, greaterThan(0));
  });

  test('updateRawText 更新原文与 updatedAt', () async {
    final item = await repo.add(rawText: '旧', source: TaskSource.text);
    await repo.updateRawText(item.id, '新');
    final updated = await repo.byId(item.id);
    expect(updated!.rawText, '新');
    expect(updated.updatedAt, greaterThanOrEqualTo(item.updatedAt));
  });

  test('markClarified 置为 clarified', () async {
    final item = await repo.add(rawText: 'x', source: TaskSource.text);
    await repo.markClarified(item.id);
    expect((await repo.byId(item.id))!.status, 'clarified');
  });

  test('delete 硬删除', () async {
    final item = await repo.add(rawText: 'x', source: TaskSource.text);
    await repo.delete(item.id);
    expect(await repo.byId(item.id), isNull);
    expect(await db.select(db.inboxItems).get(), isEmpty);
  });

  test('watchAll 按创建时间倒序推送', () async {
    await repo.add(rawText: '先', source: TaskSource.text);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.add(rawText: '后', source: TaskSource.text);
    final rows = await repo.watchAll().first;
    expect(rows.map((e) => e.rawText).toList(), ['后', '先']);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/inbox_repository_test.dart`
Expected: FAIL，编译错误（`inbox_repository.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/repositories/inbox_repository.dart**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/tables.dart';

class InboxRepository {
  InboxRepository(this._db);
  final AppDatabase _db;

  Stream<List<InboxItem>> watchAll() => (_db.select(_db.inboxItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<InboxItem>> getAll() async => _db.select(_db.inboxItems).get();

  Future<InboxItem?> byId(int id) async =>
      (_db.select(_db.inboxItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<InboxItem> add({required String rawText, required TaskSource source}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: rawText,
      source: source.storage,
      status: InboxStatus.pending.storage,
      createdAt: now,
      updatedAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> updateRawText(int id, String rawText) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        rawText: Value(rawText),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markClarified(int id) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        status: Value(InboxStatus.clarified.storage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.inboxItems)..where((t) => t.id.equals(id))).go();
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/inbox_repository_test.dart`
Expected: PASS（5 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories/inbox_repository.dart test/data/inbox_repository_test.dart
git commit -m "feat(data): InboxRepository（收集、改原文、标已理清、硬删除）"
```
Expected: 提交成功。

### Task 12: ProjectRepository（含级联删除）（TDD）

**Files:**
- Create: `lib/data/repositories/project_repository.dart`
- Test: `test/data/project_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/project_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;
  late TaskRepository tasks;
  setUp(() {
    db = createTestDatabase();
    repo = ProjectRepository(db);
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create 默认 active 并带时间戳', () async {
    final p = await repo.create(name: '客户交付');
    expect(p.name, '客户交付');
    expect(p.status, 'active');
    expect(p.createdAt, greaterThan(0));
  });

  test('updateNameAndGoal 修改', () async {
    final p = await repo.create(name: 'A', goal: 'g1');
    await repo.updateNameAndGoal(p.id, name: 'B', goal: 'g2');
    expect((await repo.byId(p.id))!.name, 'B');
    expect((await repo.byId(p.id))!.goal, 'g2');
  });

  test('setStatus 流转 active→done→someday', () async {
    final p = await repo.create(name: 'A');
    await repo.setStatus(p.id, ProjectStatus.done);
    expect((await repo.byId(p.id))!.status, 'done');
    await repo.setStatus(p.id, ProjectStatus.someday);
    expect((await repo.byId(p.id))!.status, 'someday');
  });

  test('delete 级联删除其下 Task（规格 §5.2）', () async {
    final p = await repo.create(name: '客户交付');
    final t = await tasks.create(TaskDraft(title: '写初稿', projectId: p.id));
    expect(t.projectId, p.id);
    await repo.delete(p.id);
    expect(await db.select(db.projects).get(), isEmpty);
    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('delete 不影响无任务项目', () async {
    final p = await repo.create(name: '空项目');
    await repo.delete(p.id);
    expect(await db.select(db.projects).get(), isEmpty);
  });

  test('watchAll 推送全部项目', () async {
    await repo.create(name: 'A');
    final rows = await repo.watchAll().first;
    expect(rows, hasLength(1));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/project_repository_test.dart`
Expected: FAIL，编译错误（`project_repository.dart` 与 `task_repository.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/repositories/project_repository.dart**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/tables.dart';

class ProjectRepository {
  ProjectRepository(this._db);
  final AppDatabase _db;

  Stream<List<Project>> watchAll() =>
      (_db.select(_db.projects)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<List<Project>> getAll() async => _db.select(_db.projects).get();

  Future<Project?> byId(int id) async =>
      (_db.select(_db.projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Project> create({
    required String name,
    String? goal,
    ProjectStatus status = ProjectStatus.active,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.projects).insert(ProjectsCompanion.insert(
      name: name,
      goal: Value(goal),
      status: status.storage,
      createdAt: now,
      updatedAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> updateNameAndGoal(int id, {required String name, String? goal}) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        name: Value(name),
        goal: Value(goal),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setStatus(int id, ProjectStatus status) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        status: Value(status.storage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 硬删除 + 级联：先删该项目下所有 Task 的 tag 绑定与 Task 本身，再删项目。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final taskIds = (await (_db.select(_db.tasks)..where((t) => t.projectId.equals(id))).get())
          .map((t) => t.id)
          .toList();
      for (final taskId in taskIds) {
        await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(taskId))).go();
        await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
      }
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
    });
  }
}
```

- [ ] **Step 4: 创建 lib/data/repositories/task_repository.dart（Task 12 仅需 create 供级联测试；完整实现见 Task 15）**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/tables.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;

  Future<Task> create(TaskDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _assertWaitingOn(draft);
    final id = await _db.into(_db.tasks).insert(TasksCompanion.insert(
      title: draft.title,
      notes: Value(draft.notes),
      status: draft.status.storage,
      dueDate: Value(draft.dueDate?.millisecondsSinceEpoch),
      scheduled: Value(draft.scheduled?.millisecondsSinceEpoch),
      energy: Value(draft.energy?.storage),
      priority: Value(draft.priority?.storage),
      waitingOn: Value(draft.waitingOn),
      projectId: Value(draft.projectId),
      contextId: Value(draft.contextId),
      createdAt: now,
      updatedAt: now,
    ));
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
    return (await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle());
  }

  void _assertWaitingOn(TaskDraft draft) {
    if (draft.status == TaskStatus.waiting &&
        (draft.waitingOn == null || draft.waitingOn!.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/data/project_repository_test.dart`
Expected: PASS（6 个测试全绿）。

- [ ] **Step 6: Commit**

```powershell
git add lib/data/repositories test/data/project_repository_test.dart
git commit -m "feat(data): ProjectRepository 与 TaskRepository.create（级联删除基线）"
```
Expected: 提交成功。

### Task 13: ContextRepository（删除置空关联）（TDD）

**Files:**
- Create: `lib/data/repositories/context_repository.dart`
- Test: `test/data/context_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/context_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ContextRepository repo;
  late TaskRepository tasks;
  setUp(() {
    db = createTestDatabase();
    repo = ContextRepository(db);
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create 保存名称与图标', () async {
    final c = await repo.create(name: '@外出', icon: 'directions_walk');
    expect(c.name, '@外出');
    expect(c.icon, 'directions_walk');
  });

  test('update 修改名称/图标/排序', () async {
    final c = await repo.create(name: '@外出');
    await repo.update(c.id, name: '@车程', icon: 'directions_car', sort: 5);
    final updated = await repo.byId(c.id);
    expect(updated!.name, '@车程');
    expect(updated.icon, 'directions_car');
    expect(updated.sort, 5);
  });

  test('delete 后关联 Task 的 context_id 置空（规格 §5.2）', () async {
    final c = await repo.create(name: '@电话');
    final t = await tasks.create(TaskDraft(title: '打电话', contextId: c.id));
    expect(t.contextId, c.id);
    await repo.delete(c.id);
    expect(await db.select(db.contexts).get(), isEmpty);
    final after = await (db.select(db.tasks)..where((r) => r.id.equals(t.id))).getSingle();
    expect(after.contextId, isNull);
  });

  test('delete 无关联任务的情境', () async {
    final c = await repo.create(name: '@电脑');
    await repo.delete(c.id);
    expect(await db.select(db.contexts).get(), isEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/context_repository_test.dart`
Expected: FAIL，编译错误（`context_repository.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/repositories/context_repository.dart**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/data/tables.dart';

class ContextRepository {
  ContextRepository(this._db);
  final AppDatabase _db;

  Stream<List<Context>> watchAll() =>
      (_db.select(_db.contexts)..orderBy([(t) => OrderingTerm.asc(t.sort), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<Context>> getAll() async => _db.select(_db.contexts).get();

  Future<Context?> byId(int id) async =>
      (_db.select(_db.contexts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Context> create({required String name, String? icon}) async {
    final id = await _db.into(_db.contexts).insert(ContextsCompanion.insert(
      name: name,
      icon: Value(icon),
      sort: const Value(0),
    ));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? name, String? icon, int? sort}) async {
    await (_db.update(_db.contexts)..where((t) => t.id.equals(id))).write(ContextsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      icon: icon == null ? const Value.absent() : Value(icon),
      sort: sort == null ? const Value.absent() : Value(sort),
    ));
  }

  /// 硬删除 + 置空：先清空关联 Task 的 context_id，再删情境。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.contextId.equals(id))).write(
        TasksCompanion(
          contextId: const Value(null),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await (_db.delete(_db.contexts)..where((t) => t.id.equals(id))).go();
    });
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/context_repository_test.dart`
Expected: PASS（4 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories/context_repository.dart test/data/context_repository_test.dart
git commit -m "feat(data): ContextRepository（删除置空关联 Task）"
```
Expected: 提交成功。

### Task 14: TagRepository（唯一约束 + 删除解绑）（TDD）

**Files:**
- Create: `lib/data/repositories/tag_repository.dart`
- Test: `test/data/tag_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/tag_repository_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late TagRepository repo;
  late TaskRepository tasks;
  setUp(() {
    db = createTestDatabase();
    repo = TagRepository(db);
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create 保存名称与颜色', () async {
    final t = await repo.create(name: '客户', color: '#1A73E8');
    expect(t.name, '客户');
    expect(t.color, '#1A73E8');
  });

  test('同名标签被唯一约束拒绝', () async {
    await repo.create(name: '客户', color: '#1A73E8');
    expect(() => repo.create(name: '客户', color: '#FF0000'), throwsA(isA<SqliteException>()));
  });

  test('update 修改名称与颜色', () async {
    final t = await repo.create(name: '客户', color: '#1A73E8');
    await repo.update(t.id, name: '重点客户', color: '#FF0000');
    final after = await repo.byId(t.id);
    expect(after!.name, '重点客户');
    expect(after.color, '#FF0000');
  });

  test('delete 从所有 Task 解绑（规格 §5.2）', () async {
    final tag = await repo.create(name: '客户', color: '#1A73E8');
    final t = await tasks.create(TaskDraft(title: '写方案', tagIds: {tag.id}));
    final bound = await db.select(db.taskTags).get();
    expect(bound, hasLength(1));
    await repo.delete(tag.id);
    expect(await db.select(db.tags).get(), isEmpty);
    expect(await db.select(db.taskTags).get(), isEmpty);
    expect(await db.select(db.tasks).get(), hasLength(1)); // Task 本身保留
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/tag_repository_test.dart`
Expected: FAIL，编译错误（`tag_repository.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/repositories/tag_repository.dart**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/data/tables.dart';

class TagRepository {
  TagRepository(this._db);
  final AppDatabase _db;

  Stream<List<Tag>> watchAll() =>
      (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Tag>> getAll() async => _db.select(_db.tags).get();

  Future<Tag?> byId(int id) async =>
      (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tag> create({required String name, required String color}) async {
    final id = await _db.into(_db.tags).insert(TagsCompanion.insert(name: name, color: color));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? name, String? color}) async {
    await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(TagsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      color: color == null ? const Value.absent() : Value(color),
    ));
  }

  /// 硬删除 + 解绑：先删所有 task_tags 关联，再删标签。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((t) => t.tagId.equals(id))).go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    });
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/tag_repository_test.dart`
Expected: PASS（4 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories/tag_repository.dart test/data/tag_repository_test.dart
git commit -m "feat(data): TagRepository（唯一约束、删除解绑）"
```
Expected: 提交成功。

### Task 15: TaskRepository 完整实现（状态流转 + 标签/项目/情境绑定）（TDD）

**Files:**
- Modify: `lib/data/repositories/task_repository.dart`（替换为完整版）
- Test: `test/data/task_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/task_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late ProjectRepository projects;
  late ContextRepository contexts;
  late TagRepository tags;
  setUp(() {
    db = createTestDatabase();
    repo = TaskRepository(db);
    projects = ProjectRepository(db);
    contexts = ContextRepository(db);
    tags = TagRepository(db);
  });
  tearDown(() => db.close());

  test('create 全字段落库（规格 §5.1）', () async {
    final p = await projects.create(name: '客户交付');
    final c = await contexts.create(name: '@电脑');
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    final due = DateTime(2026, 11, 30);
    final task = await repo.create(TaskDraft(
      title: '写周报',
      notes: '先整理数据',
      status: TaskStatus.nextAction,
      dueDate: due,
      scheduled: due,
      energy: EnergyLevel.medium,
      priority: PriorityLevel.high,
      projectId: p.id,
      contextId: c.id,
      tagIds: {tag.id},
    ));
    expect(task.title, '写周报');
    expect(task.notes, '先整理数据');
    expect(task.status, 'next_action');
    expect(task.dueDate, due.millisecondsSinceEpoch);
    expect(task.scheduled, due.millisecondsSinceEpoch);
    expect(task.energy, 'medium');
    expect(task.priority, 'high');
    expect(task.projectId, p.id);
    expect(task.contextId, c.id);
    final bound = await repo.watchTags(task.id).first;
    expect(bound.map((t) => t.id).toList(), [tag.id]);
  });

  test('waiting 必须带 waitingOn，否则 ArgumentError（规格 §5.2）', () async {
    expect(() => repo.create(TaskDraft(title: 'x', status: TaskStatus.waiting)),
        throwsArgumentError);
    expect(
        () => repo.setStatus(0, TaskStatus.waiting), // id 不存在，先验约束
        throwsArgumentError);
  });

  test('状态流转：next_action→waiting→done→next_action（规格 §5.2）', () async {
    final t = await repo.create(TaskDraft(title: '跟进报销', status: TaskStatus.nextAction));
    await repo.setStatus(t.id, TaskStatus.waiting, waitingOn: '财务部');
    var row = (await repo.byId(t.id))!;
    expect(row.status, 'waiting');
    expect(row.waitingOn, '财务部');
    await repo.complete(t.id);
    row = (await repo.byId(t.id))!;
    expect(row.status, 'done');
    expect(row.waitingOn, isNull); // 离开 waiting 即清空
    await repo.reopen(t.id);
    expect((await repo.byId(t.id))!.status, 'next_action');
  });

  test('update 全字段覆盖并重建标签绑定', () async {
    final t = await repo.create(TaskDraft(title: '旧', status: TaskStatus.nextAction));
    final tagA = await tags.create(name: 'A', color: '#111111');
    final tagB = await tags.create(name: 'B', color: '#222222');
    await repo.update(t.id, TaskDraft(
      title: '新',
      status: TaskStatus.someday,
      priority: PriorityLevel.low,
      tagIds: {tagB.id},
    ));
    final row = (await repo.byId(t.id))!;
    expect(row.title, '新');
    expect(row.status, 'someday');
    expect(row.priority, 'low');
    final bound = await repo.watchTags(t.id).first;
    expect(bound.map((x) => x.id).toList(), [tagB.id]);
  });

  test('setProject / setContext 单独更新', () async {
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction));
    final p = await projects.create(name: 'P');
    final c = await contexts.create(name: '@外出');
    await repo.setProject(t.id, p.id);
    await repo.setContext(t.id, c.id);
    final row = (await repo.byId(t.id))!;
    expect(row.projectId, p.id);
    expect(row.contextId, c.id);
  });

  test('addTag / removeTag 维护绑定', () async {
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction));
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    await repo.addTag(t.id, tag.id);
    expect((await repo.watchTags(t.id).first), hasLength(1));
    await repo.removeTag(t.id, tag.id);
    expect((await repo.watchTags(t.id).first), isEmpty);
  });

  test('delete 硬删除并清理绑定', () async {
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction, tagIds: {tag.id}));
    await repo.delete(t.id);
    expect(await repo.byId(t.id), isNull);
    expect(await db.select(db.taskTags).get(), isEmpty);
  });

  test('watchByStatus / watchByProject / watchByContext 过滤', () async {
    final p = await projects.create(name: 'P');
    final c = await contexts.create(name: '@电脑');
    await repo.create(TaskDraft(title: 'a', status: TaskStatus.nextAction));
    await repo.create(TaskDraft(title: 'b', status: TaskStatus.waiting, waitingOn: 'x', projectId: p.id, contextId: c.id));
    expect(await repo.watchByStatus(TaskStatus.waiting).first, hasLength(1));
    expect(await repo.watchByProject(p.id).first, hasLength(1));
    expect(await repo.watchByContext(c.id).first, hasLength(1));
    expect(await repo.watchByStatus(TaskStatus.someday).first, isEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/task_repository_test.dart`
Expected: FAIL，编译错误（`update`/`setStatus`/`watchTags` 等方法尚不存在）。

- [ ] **Step 3: 将 task_repository.dart 整体替换为完整版**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/tables.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;

  Stream<List<Task>> watchAll() =>
      (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Stream<List<Task>> watchByStatus(TaskStatus status) =>
      (_db.select(_db.tasks)..where((t) => t.status.equals(status.storage))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByProject(int projectId) =>
      (_db.select(_db.tasks)..where((t) => t.projectId.equals(projectId))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByContext(int contextId) =>
      (_db.select(_db.tasks)..where((t) => t.contextId.equals(contextId))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<Task>> getAll() async => _db.select(_db.tasks).get();

  Future<Task?> byId(int id) async =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Task> create(TaskDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _assertWaitingOn(draft);
    final id = await _db.into(_db.tasks).insert(TasksCompanion.insert(
      title: draft.title,
      notes: Value(draft.notes),
      status: draft.status.storage,
      dueDate: Value(draft.dueDate?.millisecondsSinceEpoch),
      scheduled: Value(draft.scheduled?.millisecondsSinceEpoch),
      energy: Value(draft.energy?.storage),
      priority: Value(draft.priority?.storage),
      waitingOn: Value(draft.waitingOn),
      projectId: Value(draft.projectId),
      contextId: Value(draft.contextId),
      createdAt: now,
      updatedAt: now,
    ));
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
    return (await byId(id))!;
  }

  Future<void> update(int id, TaskDraft draft) async {
    _assertWaitingOn(draft);
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      title: Value(draft.title),
      notes: Value(draft.notes),
      status: Value(draft.status.storage),
      dueDate: Value(draft.dueDate?.millisecondsSinceEpoch),
      scheduled: Value(draft.scheduled?.millisecondsSinceEpoch),
      energy: Value(draft.energy?.storage),
      priority: Value(draft.priority?.storage),
      waitingOn: Value(draft.waitingOn),
      projectId: Value(draft.projectId),
      contextId: Value(draft.contextId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(id))).go();
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
  }

  /// 状态流转（规格 §5.2）：waiting 必须携带 waitingOn；离开 waiting 清空 waitingOn。
  Future<void> setStatus(int id, TaskStatus status, {String? waitingOn}) async {
    if (status == TaskStatus.waiting &&
        (waitingOn == null || waitingOn.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      status: Value(status.storage),
      waitingOn: Value(status == TaskStatus.waiting ? waitingOn : null),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> complete(int id) => setStatus(id, TaskStatus.done);

  Future<void> reopen(int id) => setStatus(id, TaskStatus.nextAction);

  Future<void> setProject(int id, int? projectId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      projectId: Value(projectId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setContext(int id, int? contextId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      contextId: Value(contextId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> addTag(int taskId, int tagId) async {
    await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tagId));
  }

  Future<void> removeTag(int taskId, int tagId) async {
    await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(taskId) & t.tagId.equals(tagId)))
        .go();
  }

  Stream<List<Tag>> watchTags(int taskId) {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.taskTags, _db.taskTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.taskTags.taskId.equals(taskId));
    return query.watch().map((rows) => rows.map((r) => r.readTable(_db.tags)).toList());
  }

  /// 硬删除 + 清理绑定。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(id))).go();
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    });
  }

  void _assertWaitingOn(TaskDraft draft) {
    if (draft.status == TaskStatus.waiting &&
        (draft.waitingOn == null || draft.waitingOn!.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/task_repository_test.dart`
Expected: PASS（7 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories/task_repository.dart test/data/task_repository_test.dart
git commit -m "feat(data): TaskRepository 全量（状态流转规则、标签/项目/情境绑定）"
```
Expected: 提交成功。

### Task 16: ReviewRepository（TDD）

**Files:**
- Create: `lib/data/repositories/review_repository.dart`
- Test: `test/data/review_repository_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/review_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;
  setUp(() {
    db = createTestDatabase();
    repo = ReviewRepository(db);
  });
  tearDown(() => db.close());

  test('create 保存日期/总结/统计 JSON', () async {
    final dayStart = DateTime(2026, 11, 23).millisecondsSinceEpoch;
    final r = await repo.create(
      date: dayStart,
      summary: '本周专注客户交付',
      stats: '{"done":3,"new":2,"stalled":1}',
    );
    expect(r.date, dayStart);
    expect(r.summary, '本周专注客户交付');
    expect(r.stats, '{"done":3,"new":2,"stalled":1}');
  });

  test('update 修改总结与统计', () async {
    final r = await repo.create(date: 1, summary: 'a', stats: '{"done":1,"new":0,"stalled":0}');
    await repo.update(r.id, summary: 'b', stats: '{"done":4,"new":1,"stalled":0}');
    final after = await repo.byId(r.id);
    expect(after!.summary, 'b');
    expect(after.stats, contains('"done":4'));
  });

  test('watchAll 按日期倒序', () async {
    await repo.create(date: 2, summary: '后');
    await repo.create(date: 1, summary: '先');
    final rows = await repo.watchAll().first;
    expect(rows.map((r) => r.summary).toList(), ['后', '先']);
  });

  test('delete 硬删除', () async {
    final r = await repo.create(date: 1, summary: 'x');
    await repo.delete(r.id);
    expect(await db.select(db.reviews).get(), isEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/review_repository_test.dart`
Expected: FAIL，编译错误（`review_repository.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/repositories/review_repository.dart**

```dart
import 'package:drift/drift.dart';
import 'package:gtd_app/data/tables.dart';

class ReviewRepository {
  ReviewRepository(this._db);
  final AppDatabase _db;

  Stream<List<Review>> watchAll() =>
      (_db.select(_db.reviews)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<List<Review>> getAll() async => _db.select(_db.reviews).get();

  Future<Review?> byId(int id) async =>
      (_db.select(_db.reviews)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Review> create({
    required int date,
    String? summary,
    String? stats,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.reviews).insert(ReviewsCompanion.insert(
      date: date,
      summary: Value(summary),
      stats: Value(stats),
      createdAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? summary, String? stats}) async {
    await (_db.update(_db.reviews)..where((t) => t.id.equals(id))).write(ReviewsCompanion(
      summary: summary == null ? const Value.absent() : Value(summary),
      stats: stats == null ? const Value.absent() : Value(stats),
    ));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.reviews)..where((t) => t.id.equals(id))).go();
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/review_repository_test.dart`
Expected: PASS（4 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/repositories/review_repository.dart test/data/review_repository_test.dart
git commit -m "feat(data): ReviewRepository（手动回顾总结与统计）"
```
Expected: 提交成功。

### Task 17: ClarifyService（理清用例，规格 §5.2）（TDD）

**Files:**
- Create: `lib/core/workflow/clarify_service.dart`
- Test: `test/data/clarify_service_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/clarify_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/clarify_decision.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/core/workflow/clarify_service.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ClarifyService service;
  late InboxRepository inbox;
  late TaskRepository tasks;
  late ProjectRepository projects;
  late InboxItem item;

  setUp(() {
    db = createTestDatabase();
    inbox = InboxRepository(db);
    tasks = TaskRepository(db);
    projects = ProjectRepository(db);
    service = ClarifyService(db, inbox, tasks, projects);
  });
  tearDown(() => db.close());

  Future<void> seedItem() async {
    item = await inbox.add(rawText: '写周报', source: TaskSource.text);
  }

  test('转 Task（下一步）：条目标 clarified 且创建 Task（规格 §5.2 路径①）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(title: '写周报')));
    expect((await inbox.byId(item.id))!.status, 'clarified');
    final rows = await db.select(db.tasks).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, '写周报');
    expect(rows.single.status, 'next_action');
  });

  test('转 Task（等待）：创建 waiting 任务并带 waitingOn（路径②）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(
      title: '跟进报销',
      status: TaskStatus.waiting,
      waitingOn: '财务部',
    )));
    final row = (await db.select(db.tasks).get()).single;
    expect(row.status, 'waiting');
    expect(row.waitingOn, '财务部');
    expect((await inbox.byId(item.id))!.status, 'clarified');
  });

  test('转 Task（将来也许）：创建 someday 任务（路径③）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(title: '学做饭', status: TaskStatus.someday)));
    expect((await db.select(db.tasks).get()).single.status, 'someday');
  });

  test('转 Project（active）并标 clarified（路径④）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToProject(name: '客户交付', goal: '完成季度交付'));
    final p = (await db.select(db.projects).get()).single;
    expect(p.name, '客户交付');
    expect(p.goal, '完成季度交付');
    expect(p.status, 'active');
    expect((await inbox.byId(item.id))!.status, 'clarified');
  });

  test('删除：条目硬删除且不产生 Task/Project（路径⑥）', () async {
    await seedItem();
    await service.clarify(item, ClarifyDelete());
    expect(await inbox.byId(item.id), isNull);
    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.projects).get(), isEmpty);
  });

  test('waiting 决策缺 waitingOn 抛 ArgumentError 且不标 clarified', () async {
    await seedItem();
    expect(
      () => service.clarify(item, ClarifyToTask(TaskDraft(title: 'x', status: TaskStatus.waiting))),
      throwsArgumentError,
    );
    expect((await inbox.byId(item.id))!.status, 'pending');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/clarify_service_test.dart`
Expected: FAIL，编译错误（`clarify_service.dart` 不存在）。

- [ ] **Step 3: 实现 lib/core/workflow/clarify_service.dart**

```dart
import 'package:gtd_app/core/models/clarify_decision.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';

/// 手动理清用例（规格 §5.2）：一条 InboxItem 判定为 Task / Project / 删除。
/// Task/Project 落库成功后将条目标为 clarified；删除则硬删条目。
class ClarifyService {
  ClarifyService(this._db, this._inbox, this._tasks, this._projects);

  final AppDatabase _db;
  final InboxRepository _inbox;
  final TaskRepository _tasks;
  final ProjectRepository _projects;

  Future<void> clarify(InboxItem item, ClarifyDecision decision) async {
    await _db.transaction(() async {
      switch (decision) {
        case ClarifyToTask(:final draft):
          await _tasks.create(draft);
        case ClarifyToProject(:final name, :final goal):
          await _projects.create(name: name, goal: goal);
        case ClarifyDelete():
          await _inbox.delete(item.id);
          return;
      }
      await _inbox.markClarified(item.id);
    });
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/clarify_service_test.dart`
Expected: PASS（6 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/core/workflow test/data/clarify_service_test.dart
git commit -m "feat(core): ClarifyService 理清用例（任务/等待/将来也许/项目/删除）"
```
Expected: 提交成功。

### Task 18: ExportService（全库 JSON 导出/恢复）（TDD）

**Files:**
- Create: `lib/data/export_service.dart`
- Test: `test/data/export_service_test.dart`

- [ ] **Step 1: 写失败测试**

`test/data/export_service_test.dart`：

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/export_service.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ExportService service;
  setUp(() {
    db = createTestDatabase();
    service = ExportService(db);
  });
  tearDown(() => db.close());

  Future<void> seedAll() async {
    final inbox = InboxRepository(db);
    final projects = ProjectRepository(db);
    final contexts = ContextRepository(db);
    final tags = TagRepository(db);
    final tasks = TaskRepository(db);
    final reviews = ReviewRepository(db);
    await inbox.add(rawText: '写周报', source: TaskSource.text);
    final p = await projects.create(name: '客户交付', goal: 'g');
    final c = await contexts.create(name: '@电脑');
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    await tasks.create(TaskDraft(
      title: '写初稿', status: TaskStatus.nextAction,
      projectId: p.id, contextId: c.id, tagIds: {tag.id},
    ));
    await reviews.create(date: 1, summary: 's', stats: '{"done":1,"new":0,"stalled":0}');
  }

  test('export 覆盖全部 6+1 实体', () async {
    await seedAll();
    final json = await service.exportJson();
    final map = jsonDecode(json) as Map<String, dynamic>;
    expect(map['app'], 'gtd');
    expect(map['version'], 1);
    expect(map['inbox_items'], hasLength(1));
    expect(map['projects'], hasLength(1));
    expect(map['contexts'], hasLength(4)); // 3 种子 + 1 新建
    expect(map['tags'], hasLength(1));
    expect(map['tasks'], hasLength(1));
    expect(map['task_tags'], hasLength(1));
    expect(map['reviews'], hasLength(1));
    final task0 = (map['tasks'] as List).first as Map<String, dynamic>;
    expect(task0['status'], 'next_action');
    expect(task0['projectId'], pIdFrom(map));
  });

  test('import 恢复全部数据（含 task_tags 关联）', () async {
    await seedAll();
    final json = await service.exportJson();
    // 清空所有表
    await db.delete(db.reviews).go();
    await db.delete(db.taskTags).go();
    await db.delete(db.tasks).go();
    await db.delete(db.tags).go();
    await db.delete(db.contexts).go();
    await db.delete(db.projects).go();
    await db.delete(db.inboxItems).go();
    await service.importJson(json);
    expect(await db.select(db.projects).get(), hasLength(1));
    expect(await db.select(db.tasks).get(), hasLength(1));
    expect(await db.select(db.taskTags).get(), hasLength(1));
    expect(await db.select(db.inboxItems).get(), hasLength(1));
    expect(await db.select(db.reviews).get(), hasLength(1));
    expect(await db.select(db.contexts).get(), hasLength(4));
  });

  test('import 拒绝非法备份', () async {
    expect(() => service.importJson('{"app":"x","version":1}'), throwsFormatException);
    expect(() => service.importJson('{"app":"gtd","version":99}'), throwsFormatException);
  });
}

int pIdFrom(Map<String, dynamic> map) {
  final projects = map['projects'] as List;
  return (projects.first as Map<String, dynamic>)['id'] as int;
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/export_service_test.dart`
Expected: FAIL，编译错误（`export_service.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/export_service.dart**

```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';

/// 全库 JSON 备份导出/恢复（规格 §9.2）。导出覆盖 6 实体 + task_tags 关联。
class ExportService {
  ExportService(this._db)
      : _inbox = InboxRepository(_db),
        _tasks = TaskRepository(_db),
        _projects = ProjectRepository(_db),
        _contexts = ContextRepository(_db),
        _tags = TagRepository(_db),
        _reviews = ReviewRepository(_db);

  final AppDatabase _db;
  final InboxRepository _inbox;
  final TaskRepository _tasks;
  final ProjectRepository _projects;
  final ContextRepository _contexts;
  final TagRepository _tags;
  final ReviewRepository _reviews;

  Future<String> exportJson() async {
    return jsonEncode({
      'app': 'gtd',
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'inbox_items': await _inbox.getAll(),
      'projects': await _projects.getAll(),
      'contexts': await _contexts.getAll(),
      'tags': await _tags.getAll(),
      'tasks': await _tasks.getAll(),
      'task_tags': await _db.select(_db.taskTags).get(),
      'reviews': await _reviews.getAll(),
    });
  }

  Future<void> importJson(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['app'] != 'gtd' || data['version'] != 1) {
      throw const FormatException('Not a valid GTD backup');
    }
    await _db.transaction(() async {
      await _db.delete(_db.reviews).go();
      await _db.delete(_db.taskTags).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.contexts).go();
      await _db.delete(_db.projects).go();
      await _db.delete(_db.inboxItems).go();

      for (final raw in data['projects'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.projects).insert(ProjectsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          goal: Value(m['goal'] as String?),
          status: Value(m['status'] as String),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['contexts'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.contexts).insert(ContextsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          icon: Value(m['icon'] as String?),
          sort: Value(m['sort'] as int),
        ));
      }
      for (final raw in data['tags'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.tags).insert(TagsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          color: Value(m['color'] as String),
        ));
      }
      for (final raw in data['tasks'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.tasks).insert(TasksCompanion(
          id: Value(m['id'] as int),
          title: Value(m['title'] as String),
          notes: Value(m['notes'] as String?),
          status: Value(m['status'] as String),
          dueDate: Value(m['dueDate'] as int?),
          scheduled: Value(m['scheduled'] as int?),
          energy: Value(m['energy'] as String?),
          priority: Value(m['priority'] as String?),
          waitingOn: Value(m['waitingOn'] as String?),
          projectId: Value(m['projectId'] as int?),
          contextId: Value(m['contextId'] as int?),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['task_tags'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(
          taskId: m['taskId'] as int,
          tagId: m['tagId'] as int,
        ));
      }
      for (final raw in data['inbox_items'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.inboxItems).insert(InboxItemsCompanion(
          id: Value(m['id'] as int),
          rawText: Value(m['rawText'] as String),
          source: Value(m['source'] as String),
          aiHint: Value(m['aiHint'] as String?),
          promptVersion: Value(m['promptVersion'] as String?),
          status: Value(m['status'] as String),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['reviews'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.reviews).insert(ReviewsCompanion(
          id: Value(m['id'] as int),
          date: Value(m['date'] as int),
          summary: Value(m['summary'] as String?),
          stats: Value(m['stats'] as String?),
          aiReport: Value(m['aiReport'] as String?),
          createdAt: Value(m['createdAt'] as int),
        ));
      }
    });
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/export_service_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/data/export_service.dart test/data/export_service_test.dart
git commit -m "feat(data): ExportService 全库 JSON 备份导出/恢复"
```
Expected: 提交成功。

### Task 19: Provider 注入层（无全局单例，规格 §4.3/§10）

**Files:**
- Create: `lib/data/providers.dart`

- [ ] **Step 1: 写失败测试（Provider 可解析所有仓库）**

`test/data/providers_test.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import '../test_utils.dart';

void main() {
  test('数据库与仓库 Provider 注入解析（override 内存库）', () {
    final db = createTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    expect(container.read(databaseProvider), same(db));
    expect(container.read(inboxRepositoryProvider), isA<InboxRepository>());
    expect(container.read(taskRepositoryProvider), isA<TaskRepository>());
    expect(container.read(projectRepositoryProvider), isA<ProjectRepository>());
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/data/providers_test.dart`
Expected: FAIL，编译错误（`providers.dart` 不存在）。

- [ ] **Step 3: 实现 lib/data/providers.dart（完整文件）**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/export_service.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据库实例由 main() 打开后 override 注入（无全局单例，M3 多账户可加作用域）。
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider 必须在 main/测试中 override');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 必须在 main/测试中 override');
});

final inboxRepositoryProvider = Provider<InboxRepository>(
    (ref) => InboxRepository(ref.watch(databaseProvider)));
final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(databaseProvider)));
final projectRepositoryProvider = Provider<ProjectRepository>(
    (ref) => ProjectRepository(ref.watch(databaseProvider)));
final contextRepositoryProvider = Provider<ContextRepository>(
    (ref) => ContextRepository(ref.watch(databaseProvider)));
final tagRepositoryProvider = Provider<TagRepository>(
    (ref) => TagRepository(ref.watch(databaseProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ReviewRepository(ref.watch(databaseProvider)));
final exportServiceProvider = Provider<ExportService>(
    (ref) => ExportService(ref.watch(databaseProvider)));
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/data/providers_test.dart`
Expected: PASS。

- [ ] **Step 5: 运行全部数据层测试**

Run: `flutter test test/data`
Expected: 所有数据层测试全绿（enums/database/migration/各 repository/clarify/export/providers）。

- [ ] **Step 6: Commit**

```powershell
git add lib/data/providers.dart test/data/providers_test.dart
git commit -m "feat(data): Riverpod Provider 注入层（Repository 无全局单例）"
```
Expected: 提交成功。

---

## Phase C：界面层（Widget 测试，规格 §11）

### Task 20: 备份文件网关与 Widget 测试基建

**Files:**
- Create: `lib/features/settings/backup_file_gateway.dart`
- Create: `test/widget/widget_utils.dart`

- [ ] **Step 1: 创建 lib/features/settings/backup_file_gateway.dart**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 备份文件读写抽象（Widget 测试替换为 Fake，规避 file_picker 插件缺失）。
abstract class BackupFileGateway {
  /// 保存 JSON 备份，返回保存路径；用户取消返回 null。
  Future<String?> saveBackup(String json);

  /// 选择并读取一个备份 JSON 文件内容；用户取消返回 null。
  Future<String?> pickBackupJson();
}

class FilePickerBackupGateway implements BackupFileGateway {
  @override
  Future<String?> saveBackup(String json) async {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Export GTD backup',
      fileName: 'gtd_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
  }

  @override
  Future<String?> pickBackupJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}

final backupFileGatewayProvider = Provider<BackupFileGateway>(
    (ref) => FilePickerBackupGateway());
```

- [ ] **Step 2: 创建 test/widget/widget_utils.dart**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/settings/backup_file_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';

class FakeBackupGateway implements BackupFileGateway {
  String? savedJson;
  String? pickedJson;

  @override
  Future<String?> saveBackup(String json) async {
    savedJson = json;
    return '/fake/gtd_backup.json';
  }

  @override
  Future<String?> pickBackupJson() async => pickedJson;
}

/// Widget 测试环境：内存库 + mock prefs + Fake 备份网关。
/// 注意：不 import app.dart（GtdApp 到 Task 33 才创建）；
/// 整应用测试在 app_smoke_test.dart 内自行用 [overrides] 组装 ProviderScope。
class TestEnv {
  TestEnv._(this.db, this.prefs);

  final AppDatabase db;
  final SharedPreferences prefs;
  final FakeBackupGateway backup = FakeBackupGateway();

  static Future<TestEnv> create() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return TestEnv._(createTestDatabase(), prefs);
  }

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        backupFileGatewayProvider.overrideWithValue(backup),
      ];

  /// 包单个页面（自带本地化 delegates）。
  Widget wrap(Widget home, {List<Override> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [...overrides, ...extraOverrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  Future<Map<String, dynamic>> decodeSavedJson() async =>
      jsonDecode(backup.savedJson!) as Map<String, dynamic>;
}
```

- [ ] **Step 3: 验证编译**

Run: `flutter analyze`
Expected: 无 error（`backup_file_gateway.dart`、`widget_utils.dart` 及生成的本地化类均可解析）。

- [ ] **Step 4: Commit**

```powershell
git add lib/features/settings/backup_file_gateway.dart test/widget/widget_utils.dart
git commit -m "test(widget): 备份网关抽象与 Widget 测试基建（TestEnv/Fake 网关）"
```
Expected: 提交成功。

### Task 21: 快速收集（QuickCollectBar + CollectDialog）（TDD）

**Files:**
- Create: `lib/features/inbox/quick_collect_bar.dart`
- Create: `lib/features/inbox/collect_dialog.dart`
- Test: `test/widget/quick_collect_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/quick_collect_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/features/inbox/collect_dialog.dart';
import 'package:gtd_app/features/inbox/quick_collect_bar.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('快速收集框：输入→添加→入库并提示（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectBarHost()));
    await tester.enterText(find.byKey(const Key('quick_collect_field')), '写周报');
    await tester.tap(find.byKey(const Key('quick_collect_button')));
    await tester.pumpAndSettle();
    expect(find.text('Collect'), findsOneWidget); // SnackBar 提示
    final rows = await env.db.select(env.db.inboxItems).get();
    expect(rows, hasLength(1));
    expect(rows.single.rawText, '写周报');
    expect(rows.single.source, 'text');
    expect(rows.single.status, 'pending');
  });

  testWidgets('空输入不产生条目', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectBarHost()));
    await tester.tap(find.byKey(const Key('quick_collect_button')));
    await tester.pump();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
  });

  testWidgets('全局收集对话框：从其他页 1 步收集（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectHost()));
    await tester.tap(find.byKey(const Key('open_collect')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collect_dialog_field')), '买牛奶');
    await tester.tap(find.byKey(const Key('collect_dialog_submit')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
    expect(find.byType(CollectDialog), findsNothing);
  });
}

/// 顶栏快速收集框宿主（InboxPage 在 Task 22 才创建，此处仅测 QuickCollectBar 本身）。
class _CollectBarHost extends StatelessWidget {
  const _CollectBarHost();
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Column(children: const [QuickCollectBar()]));
}

class _CollectHost extends StatelessWidget {
  const _CollectHost();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: const Key('open_collect'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CollectDialog(),
            ),
            child: const Text('open'),
          ),
        ),
      );
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/quick_collect_test.dart`
Expected: FAIL，编译错误（`quick_collect_bar.dart`、`collect_dialog.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/inbox/quick_collect_bar.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 收件箱顶部常驻快速收集框（规格 §7.1：只要求"写一句话"）。
class QuickCollectBar extends ConsumerStatefulWidget {
  const QuickCollectBar({super.key});

  @override
  ConsumerState<QuickCollectBar> createState() => _QuickCollectBarState();
}

class _QuickCollectBarState extends ConsumerState<QuickCollectBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(inboxRepositoryProvider).add(rawText: text, source: TaskSource.text);
    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.collectAction)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('quick_collect_field'),
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.quickCollectHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _collect(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('quick_collect_button'),
            icon: const Icon(Icons.add),
            tooltip: l10n.collectAction,
            onPressed: _collect,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 创建 lib/features/inbox/collect_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 全局快速收集对话框（shell FAB 复用，任意界面 1 步发起收集，规格 §7.3）。
class CollectDialog extends ConsumerStatefulWidget {
  const CollectDialog({super.key});

  @override
  ConsumerState<CollectDialog> createState() => _CollectDialogState();
}

class _CollectDialogState extends ConsumerState<CollectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(inboxRepositoryProvider).add(rawText: text, source: TaskSource.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.collectAction),
      content: TextField(
        key: const Key('collect_dialog_field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.quickCollectHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('collect_dialog_submit'),
          onPressed: _submit,
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/widget/quick_collect_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 6: Commit**

```powershell
git add lib/features/inbox test/widget/quick_collect_test.dart
git commit -m "feat(inbox): 快速收集框与全局收集对话框"
```
Expected: 提交成功。

### Task 22: 收件箱页面（列表 + 徽标 + 删除二次确认）（TDD）

**Files:**
- Create: `lib/features/inbox/inbox_page.dart`
- Test: `test/widget/inbox_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/inbox_page_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/features/inbox/inbox_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('列表显示原文、来源徽标与状态（验收②）', (tester) async {
    final env = await TestEnv.create();
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '写周报',
      source: 'text',
      status: 'pending',
      createdAt: 2,
      updatedAt: 2,
    ));
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '给客户回邮件',
      source: 'text',
      status: 'clarified',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const InboxPage()));
    expect(find.text('写周报'), findsOneWidget);
    expect(find.text('给客户回邮件'), findsOneWidget);
    expect(find.text('Text'), findsNWidgets(2));
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Clarified'), findsOneWidget);
  });

  testWidgets('删除走二次确认后硬删除（验收②/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: 'x',
      source: 'text',
      status: 'clarified',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const InboxPage()));
    await tester.tap(find.byKey(Key('delete_inbox_$id')));
    await tester.pumpAndSettle();
    // 先取消
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
    // 再确认删除
    await tester.tap(find.byKey(Key('delete_inbox_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_inbox')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
  });

  testWidgets('空收件箱显示空态', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const InboxPage()));
    expect(find.text('Inbox is empty. Capture your first thought above.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/inbox_page_test.dart`
Expected: FAIL，编译错误（`inbox_page.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/inbox/inbox_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/inbox/clarify_dialog.dart';
import 'package:gtd_app/features/inbox/quick_collect_bar.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(inboxRepositoryProvider.watchAll());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInbox)),
      body: Column(
        children: [
          const QuickCollectBar(),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rows) => rows.isEmpty
                  ? Center(child: Text(l10n.emptyInbox))
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _InboxTile(item: rows[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.item});
  final InboxItem item;

  String _sourceLabel(AppLocalizations l10n) =>
      switch (TaskSource.fromStorage(item.source)) {
        TaskSource.text => l10n.sourceText,
        TaskSource.voice => l10n.sourceVoice,
        TaskSource.share => l10n.sourceShare,
        TaskSource.image => l10n.sourceImage,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = item.status == InboxStatus.pending.storage;
    return ListTile(
      title: Text(item.rawText),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(_sourceLabel(l10n)), visualDensity: VisualDensity.compact),
          Chip(
            label: Text(isPending ? l10n.statusPending : l10n.statusClarified),
            visualDensity: VisualDensity.compact,
            backgroundColor: isPending ? Colors.amber.shade100 : Colors.green.shade100,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            TextButton(
              key: Key('clarify_${item.id}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              child: Text(l10n.clarify),
            ),
          IconButton(
            key: Key('delete_inbox_${item.id}'),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteInbox),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_inbox'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(inboxRepositoryProvider).delete(item.id);
    }
  }
}
```

说明：`ClarifyDialog` 在 Task 25 才创建，而本任务 Step 3 的 `inbox_page.dart` 已 import 它；因此在 Task 25 完成前，Step 4 运行测试会因 `clarify_dialog.dart` 缺失而编译失败。处理顺序：若 Step 4 编译失败，**先完成 Task 25（写测试→实现→测试通过→提交），再回来运行本任务 Step 4 与 Step 5**（两次提交分别保留）。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/inbox_page_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/inbox/inbox_page.dart test/widget/inbox_page_test.dart
git commit -m "feat(inbox): 收件箱列表页（来源徽标、状态、硬删除二次确认）"
```
Expected: 提交成功。

### Task 23: TaskFormFields（任务全字段表单）（TDD）

**Files:**
- Create: `lib/features/task/task_form_fields.dart`
- Test: `test/widget/task_form_fields_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/task_form_fields_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('标题必填校验；空标题 validate 返回 null（验收④）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.tap(find.byKey(const Key('validate_button')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isNull);
  });

  testWidgets('等待任务必须填等待对象（规格 §5.2）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.enterText(find.byKey(const Key('task_title_field')), '跟进报销');
    await tester.tap(find.byKey(const Key('task_status_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waiting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validate_button')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isNull);
    // 填上等待对象后可校验通过
    await tester.enterText(find.byKey(const Key('task_waiting_on_field')), '财务部');
    final draft = formKey.currentState!.validate();
    expect(draft, isNotNull);
    expect(draft!.status, TaskStatus.waiting);
    expect(draft.waitingOn, '财务部');
  });

  testWidgets('创建草稿携带全部字段（验收④）', (tester) async {
    final env = await TestEnv.create();
    final project = await env.db.into(env.db.projects).insert(
        ProjectsCompanion.insert(name: '客户交付', status: 'active', createdAt: 1, updatedAt: 1));
    final context = await env.db.into(env.db.contexts).insert(
        ContextsCompanion.insert(name: '@电脑', sort: const Value(0)));
    final tag = await env.db.into(env.db.tags).insert(
        TagsCompanion.insert(name: '客户', color: '#1A73E8'));
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.enterText(find.byKey(const Key('task_title_field')), '写方案');
    await tester.enterText(find.byKey(const Key('task_notes_field')), '备注');
    await tester.tap(find.byKey(const Key('task_priority_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('high').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_energy_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('medium').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_project_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客户交付').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_context_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('@电脑').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('tag_chip_$tag')));
    await tester.pumpAndSettle();
    final draft = formKey.currentState!.validate();
    expect(draft!.title, '写方案');
    expect(draft.notes, '备注');
    expect(draft.priority, PriorityLevel.high);
    expect(draft.energy, EnergyLevel.medium);
    expect(draft.projectId, project);
    expect(draft.contextId, context);
    expect(draft.tagIds, {tag});
  });
}

class _FormHost extends StatefulWidget {
  const _FormHost({required this.formKey});
  final GlobalKey<TaskFormFieldsState> formKey;
  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          children: [
            TaskFormFields(key: widget.formKey),
            FilledButton(
              key: const Key('validate_button'),
              onPressed: () => setState(() {}),
              child: const Text('validate'),
            ),
          ],
        ),
      );
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/task_form_fields_test.dart`
Expected: FAIL，编译错误（`task_form_fields.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/task/task_form_fields.dart**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/providers.dart';

/// Task 全字段表单（理清向导与编辑对话框复用；验收④：截止日/计划/精力/优先级/
/// 等待对象/项目/情境/标签）。
class TaskFormFields extends ConsumerStatefulWidget {
  const TaskFormFields({
    super.key,
    this.initial,
    this.initialTagIds = const {},
    this.allowStatusChange = true,
  });

  /// 编辑既有任务时的初始值；创建时传 null。
  final TaskDraft? initial;
  final Set<int> initialTagIds;

  /// 编辑场景禁止改状态（避免误把已完成任务改回等待）。
  final bool allowStatusChange;

  @override
  ConsumerState<TaskFormFields> createState() => TaskFormFieldsState();
}

class TaskFormFieldsState extends ConsumerState<TaskFormFields> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _waitingOn;
  late TaskStatus _status;
  DateTime? _dueDate;
  DateTime? _scheduled;
  EnergyLevel? _energy;
  PriorityLevel? _priority;
  int? _projectId;
  int? _contextId;
  final Set<int> _tagIds = {};

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _title = TextEditingController(text: d?.title ?? '');
    _notes = TextEditingController(text: d?.notes ?? '');
    _waitingOn = TextEditingController(text: d?.waitingOn ?? '');
    _status = d?.status ?? TaskStatus.nextAction;
    _dueDate = d?.dueDate;
    _scheduled = d?.scheduled;
    _energy = d?.energy;
    _priority = d?.priority;
    _projectId = d?.projectId;
    _contextId = d?.contextId;
    _tagIds.addAll(widget.initialTagIds);
  }

  @override
  void didUpdateWidget(TaskFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.initialTagIds, widget.initialTagIds)) {
      _tagIds
        ..clear()
        ..addAll(widget.initialTagIds);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _waitingOn.dispose();
    super.dispose();
  }

  /// 校验并返回草稿；校验失败返回 null。
  TaskDraft? validate() {
    if (!_formKey.currentState!.validate()) return null;
    return TaskDraft(
      title: _title.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      status: _status,
      waitingOn: _status == TaskStatus.waiting ? _waitingOn.text.trim() : null,
      dueDate: _dueDate,
      scheduled: _scheduled,
      energy: _energy,
      priority: _priority,
      projectId: _projectId,
      contextId: _contextId,
      tagIds: Set.of(_tagIds),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due ? (_dueDate ?? DateTime.now()) : (_scheduled ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (due) {
          _dueDate = picked;
        } else {
          _scheduled = picked;
        }
      });
    }
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus s) => switch (s) {
        TaskStatus.nextAction => l10n.statusNextAction,
        TaskStatus.waiting => l10n.statusWaiting,
        TaskStatus.someday => l10n.statusSomeday,
        TaskStatus.done => l10n.statusDone,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(projectRepositoryProvider.watchAll());
    final contexts = ref.watch(contextRepositoryProvider.watchAll());
    final tags = ref.watch(tagRepositoryProvider.watchAll());
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('task_title_field'),
            controller: _title,
            decoration: InputDecoration(labelText: l10n.taskTitle),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.taskTitle : null,
          ),
          if (widget.allowStatusChange)
            DropdownButtonFormField<TaskStatus>(
              key: const Key('task_status_field'),
              initialValue: _status,
              decoration: InputDecoration(labelText: l10n.taskStatus),
              items: [
                for (final s in TaskStatus.values)
                  DropdownMenuItem<TaskStatus>(value: s, child: Text(_statusLabel(l10n, s))),
              ],
              onChanged: (v) => setState(() => _status = v ?? TaskStatus.nextAction),
            ),
          if (_status == TaskStatus.waiting)
            TextFormField(
              key: const Key('task_waiting_on_field'),
              controller: _waitingOn,
              decoration: InputDecoration(labelText: l10n.taskWaitingOn),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.waitingOnRequired : null,
            ),
          TextFormField(
            key: const Key('task_notes_field'),
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.taskNotes),
            maxLines: 2,
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EnergyLevel?>(
                  key: const Key('task_energy_field'),
                  initialValue: _energy,
                  decoration: InputDecoration(labelText: l10n.taskEnergy),
                  items: [
                    const DropdownMenuItem<EnergyLevel?>(value: null, child: Text('-')),
                    for (final e in EnergyLevel.values)
                      DropdownMenuItem<EnergyLevel?>(value: e, child: Text(e.storage)),
                  ],
                  onChanged: (v) => setState(() => _energy = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PriorityLevel?>(
                  key: const Key('task_priority_field'),
                  initialValue: _priority,
                  decoration: InputDecoration(labelText: l10n.taskPriority),
                  items: [
                    const DropdownMenuItem<PriorityLevel?>(value: null, child: Text('-')),
                    for (final p in PriorityLevel.values)
                      DropdownMenuItem<PriorityLevel?>(value: p, child: Text(p.storage)),
                  ],
                  onChanged: (v) => setState(() => _priority = v),
                ),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.taskDueDate),
            trailing: Text(_dueDate == null
                ? '-'
                : '${_dueDate!.year}-${_dueDate!.month}-${_dueDate!.day}'),
            onTap: () => _pickDate(context, due: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.taskScheduled),
            trailing: Text(_scheduled == null
                ? '-'
                : '${_scheduled!.year}-${_scheduled!.month}-${_scheduled!.day}'),
            onTap: () => _pickDate(context, due: false),
          ),
          projects.when(
            data: (list) => DropdownButtonFormField<int?>(
              key: const Key('task_project_field'),
              initialValue: _projectId,
              decoration: InputDecoration(labelText: l10n.taskProject),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                for (final p in list) DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          contexts.when(
            data: (list) => DropdownButtonFormField<int?>(
              key: const Key('task_context_field'),
              initialValue: _contextId,
              decoration: InputDecoration(labelText: l10n.taskContext),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                for (final c in list) DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _contextId = v),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          tags.when(
            data: (list) => Wrap(
              spacing: 8,
              children: [
                for (final t in list)
                  FilterChip(
                    key: Key('tag_chip_${t.id}'),
                    label: Text(t.name),
                    selected: _tagIds.contains(t.id),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _tagIds.add(t.id);
                      } else {
                        _tagIds.remove(t.id);
                      }
                    }),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/task_form_fields_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/task/task_form_fields.dart test/widget/task_form_fields_test.dart
git commit -m "feat(task): TaskFormFields 全字段表单（含 waiting_on 校验）"
```
Expected: 提交成功。

### Task 24: TaskEditDialog（编辑既有任务）（TDD）

**Files:**
- Create: `lib/features/task/task_edit_dialog.dart`
- Test: `test/widget/task_edit_dialog_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/task_edit_dialog_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('编辑任务：改标题与优先级并保存（验收④）', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '旧标题',
      status: 'next_action',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(_EditHost(taskId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title_field')), '新标题');
    await tester.tap(find.byKey(const Key('task_priority_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('high').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_edit_save')));
    await tester.pumpAndSettle();
    final row = (await env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.title, '新标题');
    expect(row.priority, 'high');
    expect(row.status, 'next_action');
  });

  testWidgets('取消不改动数据', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '标题',
      status: 'next_action',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(_EditHost(taskId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title_field')), '不应保存');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final row = (await env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.title, '标题');
  });
}

class _EditHost extends ConsumerWidget {
  const _EditHost({required this.taskId});
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(taskRepositoryProvider);
    return Scaffold(
      body: FutureBuilder<Task?>(
        future: repo.byId(taskId),
        builder: (context, snapshot) {
          final task = snapshot.data;
          if (task == null) return const SizedBox.shrink();
          return Center(
            child: FilledButton(
              key: const Key('open_edit'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => TaskEditDialog(task: task),
              ),
              child: const Text('edit'),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/task_edit_dialog_test.dart`
Expected: FAIL，编译错误（`task_edit_dialog.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/task/task_edit_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';

/// 编辑既有 Task（从任务列表点击打开；状态不可改，改状态走完成/重开按钮）。
class TaskEditDialog extends ConsumerStatefulWidget {
  const TaskEditDialog({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends ConsumerState<TaskEditDialog> {
  final _formKey = GlobalKey<TaskFormFieldsState>();

  TaskDraft _initialDraft() {
    final t = widget.task;
    return TaskDraft(
      title: t.title,
      notes: t.notes,
      status: TaskStatus.fromStorage(t.status),
      waitingOn: t.waitingOn,
      dueDate: t.dueDate == null ? null : DateTime.fromMillisecondsSinceEpoch(t.dueDate!),
      scheduled: t.scheduled == null ? null : DateTime.fromMillisecondsSinceEpoch(t.scheduled!),
      energy: EnergyLevel.fromStorageOrNull(t.energy),
      priority: PriorityLevel.fromStorageOrNull(t.priority),
      projectId: t.projectId,
      contextId: t.contextId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagStream = ref.watch(taskRepositoryProvider.watchTags(widget.task.id));
    return StreamBuilder<List<Tag>>(
      stream: tagStream,
      builder: (context, snapshot) {
        final tagIds = snapshot.data?.map((x) => x.id).toSet() ?? const <int>{};
        return AlertDialog(
          title: Text(l10n.editTask),
          content: SingleChildScrollView(
            child: TaskFormFields(
              key: _formKey,
              initial: _initialDraft(),
              initialTagIds: tagIds,
              allowStatusChange: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('task_edit_save'),
              onPressed: () async {
                final draft = _formKey.currentState!.validate();
                if (draft == null) return;
                await ref.read(taskRepositoryProvider).update(widget.task.id, draft);
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/task_edit_dialog_test.dart`
Expected: PASS（2 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/task/task_edit_dialog.dart test/widget/task_edit_dialog_test.dart
git commit -m "feat(task): TaskEditDialog 编辑既有任务"
```
Expected: 提交成功。

### Task 25: ClarifyDialog（理清向导，规格 §7.2/§5.2）（TDD）

**Files:**
- Create: `lib/features/inbox/clarify_dialog.dart`
- Test: `test/widget/clarify_dialog_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/clarify_dialog_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/inbox/clarify_dialog.dart';
import 'widget_utils.dart';

void main() {
  Future<int> seedItem(TestEnv env, {String text = '写周报'}) async {
    return env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: text,
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('确认路径：转为行动→条目 clarified 且创建 next_action 任务（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title_field')), '写周报');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final item = (await env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'clarified');
    final tasks = await env.db.select(env.db.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, '写周报');
    expect(tasks.single.status, 'next_action');
  });

  testWidgets('转为项目→创建 active 项目并标 clarified（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env, text: '客户交付计划');
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn into project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clarify_project_name')), '客户交付');
    await tester.enterText(find.byKey(const Key('clarify_project_goal')), '完成交付');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final projects = await env.db.select(env.db.projects).get();
    expect(projects, hasLength(1));
    expect(projects.single.name, '客户交付');
    expect(projects.single.status, 'active');
    final item = (await env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'clarified');
  });

  testWidgets('删除路径→条目硬删除（验收③/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
  });

  testWidgets('取消路径→不产生任何写入（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.tasks).get(), isEmpty);
    expect(await env.db.select(env.db.projects).get(), isEmpty);
    final item = (await env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'pending');
  });

  testWidgets('转为等待任务必须填等待对象才能保存（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_status_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waiting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final item = (await env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'pending'); // 校验失败，未落库
    await tester.enterText(find.byKey(const Key('task_waiting_on_field')), '财务部');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    expect((await env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle().status, 'clarified');
    expect((await env.db.select(env.db.tasks).get()).single.waitingOn, '财务部');
  });
}

class _ClarifyHost extends ConsumerWidget {
  const _ClarifyHost({required this.itemId});
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FutureBuilder<InboxItem?>(
        future: ref.read(inboxRepositoryProvider).byId(itemId),
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) return const SizedBox.shrink();
          return Center(
            child: FilledButton(
              key: const Key('open_clarify'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              child: const Text('clarify'),
            ),
          );
        },
      ),
    );
  }
}
```
（测试文件头部 imports 已在上述代码块中完整给出，无需额外补充。）

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/clarify_dialog_test.dart`
Expected: FAIL，编译错误（`clarify_dialog.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/inbox/clarify_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/models/clarify_decision.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/core/workflow/clarify_service.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';

/// 理清向导（规格 §7.2）：行动 / 项目 / 删除 三选一，确认后走 ClarifyService。
class ClarifyDialog extends ConsumerStatefulWidget {
  const ClarifyDialog({super.key, required this.item});

  final InboxItem item;

  @override
  ConsumerState<ClarifyDialog> createState() => _ClarifyDialogState();
}

enum _Decision { task, project, delete }

class _ClarifyDialogState extends ConsumerState<ClarifyDialog> {
  _Decision _decision = _Decision.task;
  final _projectName = TextEditingController();
  final _projectGoal = TextEditingController();
  final _taskFormKey = GlobalKey<TaskFormFieldsState>();

  @override
  void dispose() {
    _projectName.dispose();
    _projectGoal.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final item = widget.item;
    final service = ClarifyService(
      ref.read(databaseProvider),
      ref.read(inboxRepositoryProvider),
      ref.read(taskRepositoryProvider),
      ref.read(projectRepositoryProvider),
    );
    switch (_decision) {
      case _Decision.task:
        final draft = _taskFormKey.currentState!.validate();
        if (draft == null) return;
        await service.clarify(item, ClarifyToTask(draft));
      case _Decision.project:
        final name = _projectName.text.trim();
        if (name.isEmpty) return;
        await service.clarify(
          item,
          ClarifyToProject(
            name: name,
            goal: _projectGoal.text.trim().isEmpty ? null : _projectGoal.text.trim(),
          ),
        );
      case _Decision.delete:
        await service.clarify(item, ClarifyDelete());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.clarify),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.rawText, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<_Decision>(
              key: const Key('clarify_decision'),
              segments: [
                ButtonSegment(value: _Decision.task, label: Text(l10n.decisionAction)),
                ButtonSegment(value: _Decision.project, label: Text(l10n.decisionProject)),
                ButtonSegment(value: _Decision.delete, label: Text(l10n.decisionDelete)),
              ],
              selected: {_decision},
              onSelectionChanged: (s) => setState(() => _decision = s.first),
            ),
            const SizedBox(height: 12),
            if (_decision == _Decision.task)
              TaskFormFields(key: _taskFormKey, initial: TaskDraft(title: widget.item.rawText))
            else if (_decision == _Decision.project) ...[
              TextField(
                key: const Key('clarify_project_name'),
                controller: _projectName,
                decoration: InputDecoration(labelText: l10n.projectName),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('clarify_project_goal'),
                controller: _projectGoal,
                decoration: InputDecoration(labelText: l10n.projectGoal),
              ),
            ] else
              Text(
                l10n.confirmDeleteInbox,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('clarify_confirm'),
          onPressed: _confirm,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/clarify_dialog_test.dart`
Expected: PASS（5 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/inbox/clarify_dialog.dart test/widget/clarify_dialog_test.dart
git commit -m "feat(inbox): 理清向导（行动/项目/删除三路径，经 ClarifyService 落库）"
```
Expected: 提交成功。

### Task 26: TodayPage（下一步行动列表）（TDD）

**Files:**
- Create: `lib/features/today/today_page.dart`
- Test: `test/widget/today_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/today_page_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/today/today_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority, int? dueDate}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
      dueDate: Value(dueDate),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('只显示 next_action，且按优先级高→低排序（规格 §7.2 今日视图）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '低优先级任务', 'next_action', priority: 'low');
    await insertTask(env, '高优先级任务', 'next_action', priority: 'high');
    await insertTask(env, '等待中的任务', 'waiting');
    await insertTask(env, '已完成', 'done');
    await tester.pumpWidget(env.wrap(const TodayPage()));
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['高优先级任务', '低优先级任务']);
    expect(find.text('等待中的任务'), findsNothing);
    expect(find.text('已完成'), findsNothing);
  });

  testWidgets('点击完成按钮将任务置为 done（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '写周报', 'next_action');
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.tap(find.byKey(Key('task_done_$id')));
    await tester.pumpAndSettle();
    final row = (await env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    expect(find.text('写周报'), findsNothing);
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const TodayPage()));
    expect(find.text('Nothing here yet.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/today_page_test.dart`
Expected: FAIL，编译错误（`today_page.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/today/today_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 今日页（M1）：下一步行动列表，按优先级→截止日排序。AI 建议卡片 M2 引入。
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(taskRepositoryProvider.watchByStatus(TaskStatus.nextAction));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          final sorted = [...rows]..sort((a, b) {
              final pa = _priorityIndex(a.priority);
              final pb = _priorityIndex(b.priority);
              if (pa != pb) return pa.compareTo(pb);
              final da = a.dueDate ?? 1 << 62;
              final db2 = b.dueDate ?? 1 << 62;
              return da.compareTo(db2);
            });
          if (sorted.isEmpty) return Center(child: Text(l10n.emptyTasks));
          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, i) => _TaskTile(task: sorted[i]),
          );
        },
      ),
    );
  }

  int _priorityIndex(String? p) => switch (p) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      subtitle: task.dueDate == null
          ? null
          : Text(DateTime.fromMillisecondsSinceEpoch(task.dueDate!)
              .toString()
              .substring(0, 10)),
      leading: IconButton(
        key: Key('task_done_${task.id}'),
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(task.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/today_page_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/today test/widget/today_page_test.dart
git commit -m "feat(today): 今日页（下一步行动，优先级/截止日排序，完成流转）"
```
Expected: 提交成功。

### Task 27: ProjectsPage + ProjectDialog（含级联删除二次确认）（TDD）

**Files:**
- Create: `lib/features/projects/projects_page.dart`
- Create: `lib/features/projects/project_dialog.dart`
- Test: `test/widget/projects_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/projects_page_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/projects/projects_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> seedProject(TestEnv env, String name) async {
    return env.db.into(env.db.projects).insert(ProjectsCompanion.insert(
      name: name,
      status: 'active',
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  Future<int> seedTask(TestEnv env, int projectId, String title) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: 'next_action',
      projectId: Value(projectId),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('项目卡片展示名称/目标/其下任务（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    final p = await seedProject(env, '客户交付');
    await seedTask(env, p, '写初稿');
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    expect(find.text('客户交付'), findsOneWidget);
    expect(find.text('写初稿'), findsOneWidget);
  });

  testWidgets('新建项目（FAB）→ 列表出现（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    await tester.tap(find.byKey(const Key('new_project_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('project_name_field')), '新项目');
    await tester.tap(find.byKey(const Key('project_save')));
    await tester.pumpAndSettle();
    expect(find.text('新项目'), findsOneWidget);
    expect(await env.db.select(env.db.projects).get(), hasLength(1));
  });

  testWidgets('删除项目走二次确认并级联删除任务（验收⑤/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final p = await seedProject(env, '客户交付');
    final t = await seedTask(env, p, '写初稿');
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    await tester.tap(find.byKey(Key('delete_project_$p')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.tasks).get(), hasLength(1));
    await tester.tap(find.byKey(Key('delete_project_$p')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_project')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.projects).get(), isEmpty);
    expect(await env.db.select(env.db.tasks).get(), isEmpty);
    expect(await env.db.select(env.db.taskTags).get(), isEmpty);
    expect(t, isPositive);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/projects_page_test.dart`
Expected: FAIL，编译错误（`projects_page.dart`、`project_dialog.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/projects/project_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';

/// 新建/编辑项目。
class ProjectDialog extends ConsumerStatefulWidget {
  const ProjectDialog({super.key, this.project});

  final Project? project;

  @override
  ConsumerState<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends ConsumerState<ProjectDialog> {
  late final TextEditingController _name;
  late final TextEditingController _goal;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project?.name ?? '');
    _goal = TextEditingController(text: widget.project?.goal ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(projectRepositoryProvider);
    final goal = _goal.text.trim().isEmpty ? null : _goal.text.trim();
    final p = widget.project;
    if (p == null) {
      await repo.create(name: name, goal: goal);
    } else {
      await repo.updateNameAndGoal(p.id, name: name, goal: goal);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.project == null ? l10n.newProject : l10n.editProject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('project_name_field'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.projectName),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('project_goal_field'),
            controller: _goal,
            decoration: InputDecoration(labelText: l10n.projectGoal),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('project_save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 创建 lib/features/projects/projects_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/projects/project_dialog.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 项目视图（验收⑤）：项目卡片 + 其下 Task。
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(projectRepositoryProvider.watchAll());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProjects)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_project_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const ProjectDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _ProjectCard(project: list[i]),
              ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(taskRepositoryProvider.watchByProject(project.id));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            key: Key('project_card_${project.id}'),
            title: Text(project.name),
            subtitle: project.goal == null ? null : Text(project.goal!),
            leading: Icon(
              project.status == 'done' ? Icons.task_alt : Icons.folder,
              color: project.status == 'done' ? Colors.green : null,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('edit_project_${project.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editProject,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ProjectDialog(project: project),
                  ),
                ),
                IconButton(
                  key: Key('delete_project_${project.id}'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDelete(context, ref, l10n),
                ),
              ],
            ),
          ),
          ...tasks.when(
            data: (rows) => rows.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l10n.emptyTasks),
                    ),
                  ]
                : [for (final t in rows) _taskTile(context, ref, l10n, t)],
            loading: () => const [],
            error: (_, __) => const [],
          ),
        ],
      ),
    );
  }

  Widget _taskTile(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, Task t) {
    return ListTile(
      dense: true,
      title: Text(t.title),
      trailing: IconButton(
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(t.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: t),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteProject),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_project'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(projectRepositoryProvider).delete(project.id);
    }
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/widget/projects_page_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 6: Commit**

```powershell
git add lib/features/projects test/widget/projects_page_test.dart
git commit -m "feat(projects): 项目视图与新建/编辑对话框（级联删除二次确认）"
```
Expected: 提交成功。

### Task 28: ContextsPage（情境管理）（TDD）

**Files:**
- Create: `lib/features/contexts/contexts_page.dart`
- Test: `test/widget/contexts_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/contexts_page_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/contexts/contexts_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('展示默认情境与新建情境（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    expect(find.text('@电脑'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new_context_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('context_name_field')), '@会议');
    await tester.tap(find.byKey(const Key('context_save')));
    await tester.pumpAndSettle();
    expect(find.text('@会议'), findsOneWidget);
  });

  testWidgets('删除情境后关联 Task 的 context_id 置空（验收⑤/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final c = (await env.db.select(env.db.contexts).get()).first; // @电脑
    final taskId = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '写方案',
      status: 'next_action',
      contextId: Value(c.id),
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    await tester.tap(find.byKey(Key('delete_context_${c.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_context')));
    await tester.pumpAndSettle();
    expect(find.text('@电脑'), findsNothing);
    final row = (await env.db.select(env.db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
    expect(row.contextId, isNull);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/contexts_page_test.dart`
Expected: FAIL，编译错误（`contexts_page.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/contexts/contexts_page.dart（完整版）**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';

/// 情境视图（验收⑤）：管理情境列表，删除时关联 Task 置空（§5.2）。
class ContextsPage extends ConsumerWidget {
  const ContextsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contexts = ref.watch(contextRepositoryProvider.watchAll());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navContexts)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_context_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _ContextDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: contexts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _ContextTile(context: list[i]),
              ),
      ),
    );
  }
}

class _ContextTile extends ConsumerWidget {
  const _ContextTile({required this.context});
  final Context context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(context.name),
      trailing: IconButton(
        key: Key('delete_context_${context.id}'),
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.delete,
        onPressed: () => _confirmDelete(context, ref, l10n),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_context'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(contextRepositoryProvider).delete(context.id);
    }
  }
}

class _ContextDialog extends ConsumerStatefulWidget {
  const _ContextDialog();

  @override
  ConsumerState<_ContextDialog> createState() => _ContextDialogState();
}

class _ContextDialogState extends ConsumerState<_ContextDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await ref.read(contextRepositoryProvider).create(name: name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.add),
      content: TextField(
        key: const Key('context_name_field'),
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.taskContext),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('context_save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/contexts_page_test.dart`
Expected: PASS（2 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/contexts test/widget/contexts_page_test.dart
git commit -m "feat(contexts): 情境管理页（新建/删除置空关联）"
```
Expected: 提交成功。

### Task 29: WaitingPage + SomedayPage（等待/将来也许过滤视图）（TDD）

**Files:**
- Create: `lib/features/waiting/waiting_page.dart`
- Create: `lib/features/someday/someday_page.dart`
- Test: `test/widget/waiting_someday_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/waiting_someday_test.dart`：

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/features/someday/someday_page.dart';
import 'package:gtd_app/features/waiting/waiting_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status, {String? waitingOn}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      waitingOn: Value(waitingOn),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('等待视图只显示 waiting 任务及其 waiting_on（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '跟进报销', 'waiting', waitingOn: '财务部');
    await insertTask(env, '写周报', 'next_action');
    await insertTask(env, '学做饭', 'someday');
    await tester.pumpWidget(env.wrap(const WaitingPage()));
    expect(find.text('跟进报销'), findsOneWidget);
    expect(find.text('财务部'), findsOneWidget);
    expect(find.text('写周报'), findsNothing);
    expect(find.text('学做饭'), findsNothing);
  });

  testWidgets('将来也许视图只显示 someday 任务（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '学做饭', 'someday');
    await insertTask(env, '写周报', 'next_action');
    await tester.pumpWidget(env.wrap(const SomedayPage()));
    expect(find.text('学做饭'), findsOneWidget);
    expect(find.text('写周报'), findsNothing);
  });

  testWidgets('等待任务完成按钮置 done（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '跟进报销', 'waiting', waitingOn: '财务部');
    await tester.pumpWidget(env.wrap(const WaitingPage()));
    await tester.tap(find.byKey(Key('task_done_$id')));
    await tester.pumpAndSettle();
    final row = (await env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    expect(row.waitingOn, isNull);
    expect(find.text('跟进报销'), findsNothing);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/waiting_someday_test.dart`
Expected: FAIL，编译错误（`waiting_page.dart`、`someday_page.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/waiting/waiting_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 等待视图（验收⑤）：tasks.status = waiting 的过滤视图 + waiting_on 展示（§5.3②）。
class WaitingPage extends ConsumerWidget {
  const WaitingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(taskRepositoryProvider.watchByStatus(TaskStatus.waiting));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navWaiting)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => _WaitingTile(task: rows[i]),
              ),
      ),
    );
  }
}

class _WaitingTile extends ConsumerWidget {
  const _WaitingTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      subtitle: task.waitingOn == null ? null : Text(task.waitingOn!),
      leading: IconButton(
        key: Key('task_done_${task.id}'),
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(task.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}
```

- [ ] **Step 4: 创建 lib/features/someday/someday_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 将来也许视图（验收⑤）：tasks.status = someday 的过滤视图。
class SomedayPage extends ConsumerWidget {
  const SomedayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(taskRepositoryProvider.watchByStatus(TaskStatus.someday));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSomeday)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => _SomedayTile(task: rows[i]),
              ),
      ),
    );
  }
}

class _SomedayTile extends ConsumerWidget {
  const _SomedayTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      leading: IconButton(
        key: Key('task_done_${task.id}'),
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(task.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/widget/waiting_someday_test.dart`
Expected: PASS（3 个测试全绿）。

- [ ] **Step 6: Commit**

```powershell
git add lib/features/waiting lib/features/someday test/widget/waiting_someday_test.dart
git commit -m "feat(views): 等待/将来也许过滤视图"
```
Expected: 提交成功。

### Task 30: ReviewPage（手动回顾：总结 + 统计）（TDD）

**Files:**
- Create: `lib/features/review/review_page.dart`
- Test: `test/widget/review_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/review_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/features/review/review_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('新建回顾：填总结与统计并保存（验收⑥）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ReviewPage()));
    await tester.tap(find.byKey(const Key('new_review_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('review_summary_field')), '本周专注客户交付');
    await tester.enterText(find.byKey(const Key('review_done_field')), '3');
    await tester.enterText(find.byKey(const Key('review_new_field')), '2');
    await tester.enterText(find.byKey(const Key('review_stalled_field')), '1');
    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.reviews).get();
    expect(rows, hasLength(1));
    expect(rows.single.summary, '本周专注客户交付');
    expect(rows.single.stats, '{"done":3,"new":2,"stalled":1}');
    expect(find.text('本周专注客户交付'), findsOneWidget);
    expect(find.text('D:3 N:2 S:1'), findsOneWidget);
  });

  testWidgets('统计非法输入不落库', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ReviewPage()));
    await tester.tap(find.byKey(const Key('new_review_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('review_done_field')), 'abc');
    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.reviews).get(), isEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/review_page_test.dart`
Expected: FAIL，编译错误（`review_page.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/review/review_page.dart**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';

/// 回顾页（验收⑥）：手动填写总结与统计并保存（每周一条）。
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviews = ref.watch(reviewRepositoryProvider.watchAll());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReview)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_review_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _ReviewDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => _ReviewTile(review: rows[i]),
              ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  String _dateLabel() {
    final d = DateTime.fromMillisecondsSinceEpoch(review.date);
    return '${d.year}-${d.month}-${d.day}';
  }

  String? _statsLabel() {
    if (review.stats == null) return null;
    try {
      final m = jsonDecode(review.stats!) as Map<String, dynamic>;
      return 'D:${m['done']} N:${m['new']} S:${m['stalled']}';
    } on FormatException {
      return review.stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsLabel();
    return ListTile(
      title: Text(_dateLabel()),
      subtitle: Text(review.summary ?? '-'),
      trailing: stats == null ? null : Text(stats),
    );
  }
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog();

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  final _summary = TextEditingController();
  final _done = TextEditingController();
  final _new = TextEditingController();
  final _stalled = TextEditingController();

  @override
  void dispose() {
    _summary.dispose();
    _done.dispose();
    _new.dispose();
    _stalled.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final done = int.tryParse(_done.text.trim());
    final created = int.tryParse(_new.text.trim());
    final stalled = int.tryParse(_stalled.text.trim());
    if (done == null || created == null || stalled == null) return;
    final now = DateTime.now();
    final dayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await ref.read(reviewRepositoryProvider).create(
          date: dayStart,
          summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
          stats: jsonEncode({'done': done, 'new': created, 'stalled': stalled}),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.newReview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('review_summary_field'),
              controller: _summary,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.reviewSummary),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('review_done_field'),
              controller: _done,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.reviewDone),
            ),
            TextField(
              key: const Key('review_new_field'),
              controller: _new,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.reviewNew),
            ),
            TextField(
              key: const Key('review_stalled_field'),
              controller: _stalled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.reviewStalled),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('review_save'),
          onPressed: _save,
          child: Text(l10n.saveReview),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/review_page_test.dart`
Expected: PASS（2 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/features/review test/widget/review_page_test.dart
git commit -m "feat(review): 手动回顾页（总结+统计 JSON 落库）"
```
Expected: 提交成功。

### Task 31: SettingsPage + SettingsController（语言切换 / 备份 / AI 占位）（TDD）

**Files:**
- Create: `lib/features/settings/settings_controller.dart`
- Create: `lib/features/settings/settings_page.dart`
- Test: `test/widget/settings_page_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/settings_page_test.dart`：

```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/settings/settings_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('语言切换写入偏好设置（验收⑦⑧）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'zh');
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'en');
  });

  testWidgets('导出触发 Fake 网关并保存全库 JSON（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: 'x',
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('export_backup_tile')));
    await tester.pumpAndSettle();
    final map = await env.decodeSavedJson();
    expect(map['app'], 'gtd');
    expect(map['inbox_items'], hasLength(1));
  });

  testWidgets('恢复：Fake 返回 JSON 后数据入库（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"gtd","version":1,"exported_at":1,'
        '"inbox_items":[],"projects":[],'
        '"contexts":[{"id":1,"name":"@电脑","icon":null,"sort":0}],'
        '"tags":[],"tasks":[],"task_tags":[],"reviews":[]}';
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.contexts).get(), hasLength(1));
  });

  testWidgets('恢复非法备份提示无效且不动数据（§9.1）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"x"}';
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid backup file'), findsOneWidget);
    expect(await env.db.select(env.db.contexts).get(), hasLength(3));
  });

  testWidgets('AI 模型配置为占位入口（M1 范围，规格 §8.1）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    expect(find.text('AI model config (available in M2)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/settings_page_test.dart`
Expected: FAIL，编译错误（`settings_page.dart`、`settings_controller.dart` 不存在）。

- [ ] **Step 3: 创建 lib/features/settings/settings_controller.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言设置：持久化到 SharedPreferences；默认跟随系统（locale=null）。
class SettingsController extends StateNotifier<LocaleSelection> {
  SettingsController(this._prefs) : super(LocaleSelection.system) {
    final saved = _prefs.getString('locale');
    if (saved != null) {
      state = LocaleSelection.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => LocaleSelection.system,
      );
    }
  }

  final SharedPreferences _prefs;

  Future<void> setLocale(LocaleSelection selection) async {
    state = selection;
    await _prefs.setString('locale', selection.name);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, LocaleSelection>(
  (ref) => SettingsController(ref.watch(sharedPreferencesProvider)),
);
```

- [ ] **Step 4: 创建 lib/features/settings/settings_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/features/settings/backup_file_gateway.dart';
import 'package:gtd_app/features/settings/settings_controller.dart';

/// 设置页（验收⑦⑧）：语言切换、全库 JSON 导出/恢复、AI 模型配置占位（M2 填充）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selection = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<LocaleSelection>(
              key: const Key('locale_dropdown'),
              value: selection,
              items: [
                DropdownMenuItem(
                  value: LocaleSelection.system,
                  child: Text(l10n.langSystem),
                ),
                const DropdownMenuItem(
                  value: LocaleSelection.zh,
                  child: Text('中文'),
                ),
                const DropdownMenuItem(
                  value: LocaleSelection.en,
                  child: Text('English'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsControllerProvider.notifier).setLocale(v);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.aiPlaceholder),
          ),
          const Divider(),
          ListTile(
            key: const Key('export_backup_tile'),
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l10n.exportBackup),
            onTap: () => _export(context, ref, l10n),
          ),
          ListTile(
            key: const Key('import_backup_tile'),
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l10n.importBackup),
            onTap: () => _import(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final json = await ref.read(exportServiceProvider).exportJson();
    final gateway = ref.read(backupFileGatewayProvider);
    final path = await gateway.saveBackup(json);
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportedTo)),
      );
    }
  }

  Future<void> _import(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final gateway = ref.read(backupFileGatewayProvider);
    final json = await gateway.pickBackupJson();
    if (json == null) return;
    try {
      await ref.read(exportServiceProvider).importJson(json);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importedFrom)),
        );
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupInvalid)),
        );
      }
    }
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/widget/settings_page_test.dart`
Expected: PASS（5 个测试全绿）。

- [ ] **Step 6: Commit**

```powershell
git add lib/features/settings test/widget/settings_page_test.dart
git commit -m "feat(settings): 设置页（语言切换/JSON 备份恢复/AI 占位入口）"
```
Expected: 提交成功。

### Task 32: ResponsiveShell（600px 断点两套布局 + 全局收集 FAB）（TDD）

**Files:**
- Create: `lib/app/responsive_shell.dart`
- Test: `test/widget/responsive_shell_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/responsive_shell_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('窄屏（<600）：底部导航 5 项，无侧边栏（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('宽屏（≥600）：侧边栏 8 项，无底部导航（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRailDestination), findsNWidgets(8));
  });

  testWidgets('侧边栏切到情境页并展示情境（验收①⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.tap(find.text('Contexts'));
    await tester.pumpAndSettle();
    expect(find.text('@电脑'), findsOneWidget);
  });

  testWidgets('非收件箱页全局 FAB 一步收集（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 先切到非收件箱页（今日），收件箱页本身不显示全局 FAB
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global_collect_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collect_dialog_field')), '给客户回邮件');
    await tester.tap(find.byKey(const Key('collect_dialog_submit')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/responsive_shell_test.dart`
Expected: FAIL，编译错误（`responsive_shell.dart` 不存在）。

- [ ] **Step 3: 创建 lib/app/responsive_shell.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/features/contexts/contexts_page.dart';
import 'package:gtd_app/features/inbox/collect_dialog.dart';
import 'package:gtd_app/features/inbox/inbox_page.dart';
import 'package:gtd_app/features/projects/projects_page.dart';
import 'package:gtd_app/features/review/review_page.dart';
import 'package:gtd_app/features/settings/settings_page.dart';
import 'package:gtd_app/features/someday/someday_page.dart';
import 'package:gtd_app/features/today/today_page.dart';
import 'package:gtd_app/features/waiting/waiting_page.dart';

/// 响应式外壳（规格 §7.1）：LayoutBuilder 600px 断点。
/// 宽屏：NavigationRail（8 项：收件箱/今日/项目/情境/等待/将来也许/回顾/设置）；
/// 窄屏：底部 NavigationBar（5 项：收件箱/今日/项目/回顾/设置）。
class ResponsiveShell extends ConsumerStatefulWidget {
  const ResponsiveShell({super.key});

  static const double breakpoint = 600;

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    InboxPage(),
    TodayPage(),
    ProjectsPage(),
    ContextsPage(),
    WaitingPage(),
    SomedayPage(),
    ReviewPage(),
    SettingsPage(),
  ];

  // 窄屏 5 项对应的 _pages 下标：收件箱/今日/项目/回顾/设置
  static const List<int> _narrowIndices = [0, 1, 2, 6, 7];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= ResponsiveShell.breakpoint;
        return Scaffold(
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: _railDestinations(l10n),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _pages[_index]),
                  ],
                )
              : _pages[_index],
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _narrowIndices.indexOf(_index),
                  onDestinationSelected: (i) =>
                      setState(() => _index = _narrowIndices[i]),
                  destinations: _barDestinations(l10n),
                ),
          floatingActionButton: _index != 0
              ? FloatingActionButton(
                  key: const Key('global_collect_fab'),
                  tooltip: l10n.collectAction,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const CollectDialog(),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  List<NavigationRailDestination> _railDestinations(AppLocalizations l10n) => [
        NavigationRailDestination(
          icon: const Icon(Icons.inbox_outlined),
          label: Text(l10n.navInbox),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.today),
          label: Text(l10n.navToday),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.folder_outlined),
          label: Text(l10n.navProjects),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.place_outlined),
          label: Text(l10n.navContexts),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.hourglass_empty),
          label: Text(l10n.navWaiting),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.nights_stay_outlined),
          label: Text(l10n.navSomeday),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.history),
          label: Text(l10n.navReview),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.navSettings),
        ),
      ];

  List<NavigationDestination> _barDestinations(AppLocalizations l10n) => [
        NavigationDestination(
          icon: const Icon(Icons.inbox_outlined),
          selectedIcon: const Icon(Icons.inbox),
          label: l10n.navInbox,
        ),
        NavigationDestination(
          icon: const Icon(Icons.today),
          selectedIcon: const Icon(Icons.today),
          label: l10n.navToday,
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: l10n.navProjects,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: l10n.navReview,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ];
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget/responsive_shell_test.dart`
Expected: PASS（4 个测试全绿）。

- [ ] **Step 5: Commit**

```powershell
git add lib/app/responsive_shell.dart test/widget/responsive_shell_test.dart
git commit -m "feat(app): 响应式外壳（600px 断点两套布局 + 全局收集 FAB）"
```
Expected: 提交成功。

### Task 33: 主题、应用入口与整应用冒烟（GtdApp + main）（TDD）

**Files:**
- Create: `lib/app/theme.dart`
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart`（覆写为空模板）
- Test: `test/widget/app_smoke_test.dart`

- [ ] **Step 1: 写失败测试**

`test/widget/app_smoke_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/app/app.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('整应用启动：默认英文，切换中文后导航文案变化（验收①⑧）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsWidgets); // 侧边栏 + 页面标题
    // 切到设置页
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets); // 语言切换生效
    expect(find.text('收件箱'), findsWidgets);
  });

  testWidgets('窄屏下底部导航五项导航可达（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet.'), findsOneWidget);
  });
}

/// 整应用测试宿主：ProviderScope 注入内存库/mock prefs/Fake 网关 + GtdApp。
Widget _app(TestEnv env) => ProviderScope(
      overrides: env.overrides,
      child: const GtdApp(),
    );
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widget/app_smoke_test.dart`
Expected: FAIL，编译错误（`app.dart`、`theme.dart` 不存在）。

- [ ] **Step 3: 创建 lib/app/theme.dart**

```dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8));
  return ThemeData(colorScheme: scheme, useMaterial3: true);
}
```

- [ ] **Step 4: 创建 lib/app/app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/features/settings/settings_controller.dart';

class GtdApp extends ConsumerWidget {
  const GtdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(settingsControllerProvider);
    return MaterialApp(
      title: 'GTD',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: selection.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: const ResponsiveShell(),
    );
  }
}
```

- [ ] **Step 5: 覆写 lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/app.dart';
import 'package:gtd_app/data/app_database.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const GtdApp(),
  ));
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/widget/app_smoke_test.dart`
Expected: PASS（2 个测试全绿）。

- [ ] **Step 7: Commit**

```powershell
git add lib/app lib/main.dart test/widget/app_smoke_test.dart
git commit -m "feat(app): 主题、GtdApp 入口与整应用冒烟（语言切换联动）"
```
Expected: 提交成功。

---

## Phase D：全量验证与验收

### Task 34: 全量测试套件与静态分析通过

**Files:**
- None（纯验证）

- [ ] **Step 1: 运行全量测试**

Run: `flutter test`
Expected: 输出 `All tests passed!`。若有失败，修复对应文件后重跑（每个 Task 均已独立绿，此处为回归确认）。

- [ ] **Step 2: 运行静态分析**

Run: `flutter analyze`
Expected: `No issues found!`。若为 lint 警告（如 unused import），按提示清理。

- [ ] **Step 3: 验证无 AI / 无网络依赖（规格 §4.2 不变量 1、验收⑨）**

Run: `Select-String -Path pubspec.yaml -Pattern "^\s+(http|dio|openai|anthropic):"`
Expected: 无输出（dependencies 段不含任何网络或 AI 客户端包）。

- [ ] **Step 4: Commit（若有分析清理变更）**

```powershell
git add -A
git commit -m "chore: 全量测试与静态分析清理"
```
Expected: 提交成功（若 Step 1-3 无变更则跳过本步）。

### Task 35: 验收走查清单文档（规格 §8.1 十项）

**Files:**
- Create: `test/acceptance/milestone1_checklist.md`

- [ ] **Step 1: 创建走查清单**

`test/acceptance/milestone1_checklist.md`：

```markdown
# Milestone 1 验收走查清单（规格 §8.1）

执行方式：Windows 桌面端 `flutter run -d windows`；手机端连接 Android 设备/模拟器后
`flutter run -d <device>`。断网场景：直接断开本机网络再走查（本应用无任何网络依赖，
本地照常）。每项勾选后打 `[x]`。

## 环境准备
- [ ] `flutter doctor` 中 Windows 与 Android 工具链可用
- [ ] `flutter build windows --debug` 与 `flutter build apk --debug` 均成功

## 1. 双端启动与断点布局
- [ ] 桌面端（宽屏）出现左侧 8 项侧边栏：收件箱/今日/项目/情境/等待/将来也许/回顾/设置
- [ ] 手机端（窄屏）出现底部 5 项导航：收件箱/今日/项目/回顾/设置
- [ ] 调整窗口宽度跨过 600px 断点，布局在侧边栏/底部导航间即时切换

## 2. 快速收集
- [ ] 收件箱顶部快速收集框输入一句话并提交，条目出现在列表（原文/来源徽标 Text/状态 Pending）
- [ ] 在非收件箱页（如今日页）点浮动 + 按钮，输入并提交，条目进入收件箱（1 步完成）

## 3. 手动理清（流转规则 §5.2）
- [ ] 理清为下一步行动：条目状态变为 Clarified，任务出现在今日页
- [ ] 理清为等待任务：必须填写等待对象，保存后出现在等待页并显示 waiting_on
- [ ] 理清为将来也许：任务出现在将来也许页
- [ ] 理清为项目：项目出现在项目页，条目标 Clarified
- [ ] 理清为删除：弹二次确认，确认后条目消失且不产生任何任务/项目

## 4. Task 全字段
- [ ] 创建/编辑任务可设置：标题、状态、等待对象、备注、截止日、计划时间、精力、优先级、项目、情境、标签
- [ ] 等待任务缺等待对象时保存被拦截（表单校验 + 数据层 ArgumentError）

## 5. 四个视图
- [ ] 项目页：项目卡片显示名称/目标/其下任务；删除项目二次确认后任务一并删除
- [ ] 情境页：默认 @电脑/@外出/@电话；删除情境后相关任务的情境变空
- [ ] 等待页：只显示 waiting 任务及等待对象；完成按钮将任务置 done
- [ ] 将来也许页：只显示 someday 任务

## 6. 手动回顾
- [ ] 回顾页新建回顾：填总结与 done/new/stalled 三个数字，保存后列表显示日期/总结/统计

## 7. 设置页
- [ ] 语言切换：跟随系统/中文/English 三档，切换后导航文案立即变化
- [ ] 导出备份：保存 JSON 文件，内容含 inbox_items/projects/contexts/tags/tasks/task_tags/reviews
- [ ] 恢复备份：选择导出的 JSON 后数据完整恢复（含任务-标签关联）
- [ ] 恢复非法 JSON 提示“备份文件无效”且不动现有数据
- [ ] “AI 模型配置（M2 启用）”占位入口存在且不可点

## 8. 双语骨架
- [ ] 切到中文后：导航、收集框、理清按钮、设置项均为中文
- [ ] 切回英文恢复正常英文文案

## 9. 纯本地/断网
- [ ] 断网状态启动应用并完整走一遍收集→理清→四个视图→回顾→导出，无异常、无报错

## 10. 自动化测试
- [ ] `flutter test` 全绿（数据层 + 界面层）
- [ ] `flutter analyze` 无 issue
```

- [ ] **Step 2: Commit**

```powershell
git add test/acceptance/milestone1_checklist.md
git commit -m "docs(acceptance): 里程碑 1 验收走查清单（规格 §8.1 十项）"
```
Expected: 提交成功。

### Task 36: 双端构建与离线走查（验收①⑨）

**Files:**
- None（纯验证）

- [ ] **Step 1: Windows 桌面构建**

Run: `flutter build windows --debug`
Expected: 输出 `Built build\windows\x64\runner\Debug\gtd_app.exe`。

- [ ] **Step 2: Android APK 构建**

Run: `flutter build apk --debug`
Expected: 输出 `Built build\app\outputs\flutter-apk\app-debug.apk`。

- [ ] **Step 3: 双端启动走查（对照 Task 35 清单人工执行）**

Run（桌面）: `flutter run -d windows`
Expected: 应用窗口启动，侧边栏 8 项可见。

Run（手机）: `flutter devices` 列出 Android 设备后执行 `flutter run -d <device-id>`
Expected: 应用在手机端启动，底部导航 5 项可见。

- [ ] **Step 4: 断网走查**

断开本机网络 → 重新 `flutter run -d windows` → 按 Task 35 清单第 9 项完整走一遍。
Expected: 收集/理清/视图/回顾/导出全部正常，无任何网络相关报错。

- [ ] **Step 5: 在走查清单勾选完成项**

把 `test/acceptance/milestone1_checklist.md` 中已完成项勾为 `[x]` 并提交：

```powershell
git add test/acceptance/milestone1_checklist.md
git commit -m "docs(acceptance): 里程碑 1 走查完成勾选"
```
Expected: 提交成功。若个别项未通过，修复对应 Task 后重跑并更新勾选。

### Task 37: 里程碑收尾确认

**Files:**
- None（纯验证）

- [ ] **Step 1: 最终全量回归**

Run: `flutter test` 与 `flutter analyze`
Expected: `All tests passed!` 与 `No issues found!`。

- [ ] **Step 2: 确认 git 工作区干净**

Run: `git status --short`
Expected: 无未提交变更（`tool/windows/` 已被忽略）。

- [ ] **Step 3: 里程碑总结提交（记录验收状态）**

```powershell
git log --oneline -5
```
Expected: 展示最近 5 条 feat/test/chore 提交，里程碑 1 全部任务已完成。


