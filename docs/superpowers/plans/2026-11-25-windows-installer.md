# Windows 桌面发布安装包 v0.1.1 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 gtd_app 发布为 Windows 桌面安装包 `dist\gtd_app-setup-0.1.1.exe`（Inno Setup，不签名）。

**Architecture:** 版本号升到 0.1.1+2 → `flutter build windows --release` 产出发布目录 → 静默安装 Inno Setup 6 编译器 → 用 `windows/installer/setup.iss` 打包 → 静默安装/启动冒烟/卸载三项验证 → 文档与脚本入库。

**Tech Stack:** Flutter 3.50 Windows release 构建、Inno Setup 6（ISCC.exe）、PowerShell 验证。

**Spec:** `docs/superpowers/specs/2026-11-25-windows-installer-design.md`

---

### Task 1: 版本号升级与回归确认

**Files:**
- Modify: `pubspec.yaml:4`
- Test: 全量 `flutter test`（96/96 基线）

- [ ] **Step 1: 修改版本号**

将 `pubspec.yaml` 第 4 行 `version: 0.1.0+1` 改为 `version: 0.1.1+2`。

```yaml
version: 0.1.1+2
```

- [ ] **Step 2: 全量回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（96/96 全绿，版本号变更不影响测试）。

- [ ] **Step 3: 提交**

```powershell
git add pubspec.yaml
git commit -m "build(version): 0.1.1+2（Windows 首个发布版）"
```

---

### Task 2: Release 构建

**Files:**
- 产物（gitignore 已忽略 build/）：`build\windows\x64\runner\Release\`

- [ ] **Step 1: 执行 release 构建**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
Get-Process gtd_app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
flutter build windows --release
```

Expected: `Built build\windows\x64\runner\Release\gtd_app.exe`。

- [ ] **Step 2: 产物完整性确认**

```powershell
Get-ChildItem build\windows\x64\runner\Release | Where-Object { $_.Name -match 'plugin' } | Select-Object Name
Get-Item build\windows\x64\runner\Release\gtd_app.exe | Select-Object Length, LastWriteTime
```

Expected: 插件 DLL（flutter_secure_storage_windows_plugin.dll、sqlite3_flutter_libs_plugin.dll 等）存在，gtd_app.exe 存在。若缺插件 DLL，报告（不擅自处理）。

---

### Task 3: 安装 Inno Setup 6（一次性的打包机工具）

- [ ] **Step 1: 下载并静默安装**

```powershell
$env:HTTP_PROXY="http://127.0.0.1:10808"; $env:HTTPS_PROXY="http://127.0.0.1:10808"
Invoke-WebRequest -Uri "https://files.jrsoftware.org/is/6/innosetup-6.4.3.exe" -OutFile "$env:TEMP\innosetup.exe"
Start-Process -FilePath "$env:TEMP\innosetup.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait
```

Expected: 无报错，安装完成。

- [ ] **Step 2: 验证编译器就位**

```powershell
Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
```

Expected: `True`。若未安装到默认路径，记录实际路径并用于后续命令。

- [ ] **Step 3: 清理安装包**

```powershell
Remove-Item "$env:TEMP\innosetup.exe" -ErrorAction SilentlyContinue
```

---

### Task 4: 编写打包脚本并产出安装包

**Files:**
- Create: `windows/installer/setup.iss`
- 产物（需确认 dist/ 忽略）：`dist\gtd_app-setup-0.1.1.exe`

- [ ] **Step 1: 创建 setup.iss**

创建 `windows/installer/setup.iss`，内容如下（完整可直接编译）：

```inno
; GTD App Windows 安装脚本 — Inno Setup 6
#define MyAppName "gtd_app"
#define MyAppVersion "0.1.1"
#define MyAppPublisher "gtd"
#define MyAppExeName "gtd_app.exe"

[Setup]
AppId={{9F8E2C31-5A1D-4C0B-9E6A-2B7D4F3A8C21}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\gtd_app
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=gtd_app-setup-{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent
```

- [ ] **Step 2: 编译安装包**

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "D:\Project\gtd-project\windows\installer\setup.iss"
```

Expected: 输出 `Successfully compiled setup file` 且产物 `D:\Project\gtd-project\dist\gtd_app-setup-0.1.1.exe` 存在。若 ISCC 路径不同，用 Step 3 记录的实际路径。

- [ ] **Step 3: 确认产物**

```powershell
Get-Item D:\Project\gtd-project\dist\gtd_app-setup-0.1.1.exe | Select-Object Length, LastWriteTime
```

Expected: 文件存在（体积约 60-120MB，含 Flutter 引擎与 assets）。

- [ ] **Step 4: 提交脚本（产物不入库）**

先向 `.gitignore` 追加 `dist/`：

```gitignore
# 发布产物
dist/
```

```powershell
git add windows/installer/setup.iss .gitignore
git commit -m "build(installer): Inno Setup 打包脚本与 dist 忽略规则"
```

---

### Task 5: 安装包三连验证（静默安装→启动冒烟→卸载→默认路径复核）

**Files:**
- 无（纯流程验证）

- [ ] **Step 1: 静默安装到临时目录**

```powershell
$installer = "D:\Project\gtd-project\dist\gtd_app-setup-0.1.1.exe"
$tmp = "$env:TEMP\gtd_install_test"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Start-Process -FilePath $installer -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/DIR=$tmp" -Wait
Get-ChildItem $tmp | Select-Object Name
```

Expected: `gtd_app.exe` 及插件 DLL、data 目录均在 `$tmp` 下。

- [ ] **Step 2: 启动冒烟**

```powershell
$p = Start-Process -FilePath "$tmp\gtd_app.exe" -PassThru
Start-Sleep -Seconds 25
$p.Refresh()
"Alive=$(-not $p.HasExited) Title=$($p.MainWindowTitle)"
Stop-Process -Id $p.Id -Force
```

Expected: `Alive=True Title=gtd_app`（25 秒无崩溃、窗口正常）。

- [ ] **Step 3: 卸载验证**

```powershell
$uninstaller = Get-ChildItem $tmp -Filter "unins*.exe" | Select-Object -First 1 -ExpandProperty FullName
Start-Process -FilePath $uninstaller -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES" -Wait
Test-Path $tmp
```

Expected: `False`（安装目录已清空，卸载入口存在并可用）。

- [ ] **Step 4: 默认路径安装复核（快捷方式 + 卸载注册表）**

```powershell
Start-Process -FilePath "D:\Project\gtd-project\dist\gtd_app-setup-0.1.1.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES" -Wait
Test-Path "$env:ProgramFiles\gtd_app\gtd_app.exe"
Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\gtd_app\gtd_app.lnk"
Test-Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\gtd_app\gtd_app.lnk"
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\gtd_app_is1" -ErrorAction SilentlyContinue | Select-Object DisplayName, DisplayVersion
```

Expected: `$env:ProgramFiles\gtd_app\gtd_app.exe` 存在；开始菜单快捷方式存在（ProgramData 或 APPDATA 其一命中）；卸载注册表项 DisplayName=gtd_app、DisplayVersion=0.1.1。

- [ ] **Step 5: 清理测试安装**

```powershell
Start-Process -FilePath "$env:ProgramFiles\gtd_app\unins000.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES" -Wait
Test-Path "$env:ProgramFiles\gtd_app"
```

Expected: `False`。

---

### Task 6: 发布文档与最终提交

**Files:**
- Create: `docs/release/windows.md`
- 全量回归确认

- [ ] **Step 1: 编写发布文档**

创建 `docs/release/windows.md`：

```markdown
# Windows 桌面发布（gtd_app）

## 产物

- 安装包：`dist\gtd_app-setup-0.1.1.exe`（Inno Setup，x64，不签名）
- 便携目录：`build\windows\x64\runner\Release\`（解压即用）

## 重新发布步骤

1. `flutter build windows --release`
2. `"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer\setup.iss`
3. 产物出现在 `dist\`

## 分发注意事项

- 安装包**未做代码签名**：首次运行 Windows SmartScreen 提示"未知发布者"，
  需点"更多信息 → 仍要运行"。面向个人/内部分发可接受；若要消除提示需购买
  代码签名证书并重新签名。
- 版本号在 `pubspec.yaml` 维护，打包脚本读取固定版本 `0.1.1`——升版时同步改
  `setup.iss` 的 `MyAppVersion`。

## 数据说明

- 应用数据落于 `%APPDATA%\dev.gtd\gtd_app\gtd_app.db`（本地 SQLite，卸载安装包
  不删除用户数据）。
```

- [ ] **Step 2: 最终回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（96/96）。

- [ ] **Step 3: 提交**

```powershell
git add docs/release/windows.md
git commit -m "docs(release): Windows 发布说明（产物/步骤/SmartScreen 与数据说明）"
```

- [ ] **Step 4: 最终状态检查**

```powershell
git status --short
git log --oneline -6
```

Expected: 工作区干净；最近提交为 Task 1-4、6 的 4 个提交（Task 2/5 无提交）。

---

## 自审记录

- **Spec 覆盖**：§4.1→Task 1；§4.2→Task 2；§4.3→Task 3；§4.4/4.5→Task 4；§4.6→Task 5；§4.7/§5→Task 6。全部覆盖。
- **占位符扫描**：无 TBD/TODO；每步含完整命令与预期输出。
- **类型一致性**：ISCC 路径在 Task 3 验证、Task 4 使用并注明可能偏差；产物路径 `dist\gtd_app-setup-0.1.1.exe` 全程一致。
