# GTD App Windows 桌面发布安装包（v0.1.1）

日期：2026-11-25
状态：已批准（用户确认设计）
前置：里程碑 1（GTD 核心地基）已收官，HEAD `1d98d07`，工作区干净

## 1. 背景与目标

里程碑 1 已完成 Windows 桌面 **debug** 构建并人工走查视觉达标。本 spec 将应用发布为
可分发的 **Windows 安装包**：双击 `setup.exe` 安装，带开始菜单/桌面快捷方式与卸载程序。

## 2. 决策记录（用户逐项确认）

| 决策点 | 结论 |
|---|---|
| 目标平台 | 仅 Windows 桌面（Android APK 继续暂缓） |
| 安装包形态 | exe 安装程序（Inno Setup 6） |
| 代码签名 | 不签名（首启 SmartScreen 提示"未知发布者"，属预期） |
| 应用名/版本 | `gtd_app` / `0.1.1` |
| 应用图标 | 现有 `windows/runner/resources/app_icon.ico`（正式品牌图标留待后续里程碑） |
| 范围外 | 签名、MSIX/商店、Android、自动更新、品牌图标 |

## 3. 方案取舍（exe 安装程序工具）

- **Inno Setup 6（采用）**：免费、成熟、脚本驱动、单一 setup.exe 产物，内置快捷方式/
  卸载/版本信息支持。
- NSIS：功能相当，脚本更底层，图标与卸载集成需更多手工配置。
- WiX/MSIX：微软官方格式，面向商店/企业分发，证书签名流程繁琐，与本需求冲突。

## 4. 详细设计

### 4.1 版本号

`pubspec.yaml`：`version: 0.1.0+1` → `version: 0.1.1+2`（语义版本递增 + build 号递增）。

### 4.2 Release 构建

```powershell
flutter build windows --release
```

产物：`build\windows\x64\runner\Release\`（gtd_app.exe + 插件 DLL + data）。

### 4.3 Inno Setup 6 安装（打包机环境，一次性的）

- 下载官方 Inno Setup 6 安装包（走代理 `127.0.0.1:10808`）。
- 静默安装至默认位置，编译器为 `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`。
- 属开发机工具，不进项目依赖；装完后用 vswhere/文件系统验证 `ISCC.exe` 存在。

### 4.4 打包脚本 `windows/installer/setup.iss`

- `AppName=gtd_app`、`AppVersion=0.1.1`、`AppPublisher=gtd`
- `DefaultDirName={autopf}\gtd_app`
- `ArchitecturesAllowed=x64compatible`、`ArchitecturesInstallIn64BitMode=x64compatible`
- `OutputDir=..\..\dist`、`OutputBaseFilename=gtd_app-setup-0.1.1`
- `SetupIconFile=..\runner\resources\app_icon.ico`
- 快捷方式：开始菜单（`{group}\gtd_app.lnk`）+ 桌面（`{userdesktop}\gtd_app.lnk`）
- `UninstallDisplayIcon` 指向安装目录 exe
- `[Files]`：`Source: ..\..\build\windows\x64\runner\Release\*; DestDir: {app}; Flags: recursesubdirs`
- `[Languages]` 固定 `compiler:Languages\ChineseSimplified.isl`（简体中文安装界面，无需多余语言）

### 4.5 产物

`dist\gtd_app-setup-0.1.1.exe`（版本 0.1.1 的安装包）。

### 4.6 验证流程（安装→启动→卸载）

1. 静默安装：`dist\gtd_app-setup-0.1.1.exe /VERYSILENT /DIR=<临时目录> /SUPPRESSMSGBOXES`
2. 确认 `<临时目录>\gtd_app.exe` 存在且插件 DLL 齐全
3. 启动 exe，25s 后确认进程存活、主窗口标题 `gtd_app`、无崩溃（复用里程碑 1 冒烟方法）
4. 卸载：`/VERYSILENT` 卸载后确认安装目录已清空
5. 复核安装器在默认路径（`{autopf}\gtd_app`）也生成快捷方式与卸载入口（改走默认路径再静默装一次并检查 `Start Menu`/`Desktop` 快捷方式与 `Uninstall` 注册表项存在）

### 4.7 仓库内容

- 新增：`windows/installer/setup.iss`、`dist/` 说明（.gitignore 已有 build/，`dist/` 忽略或
  保留说明文件——采用：`dist/` 入 .gitignore，脚本与文档入库）
- 修改：`pubspec.yaml`（版本号）
- 新增文档：`docs/release/windows.md`（发布步骤：构建→打包→产物路径→分发注意事项含
  SmartScreen 提示说明）

## 5. 测试策略

本任务以**流程验证**为主（安装/启动/卸载冒烟），无新增单元测试；全量回归
`flutter test` 需保持 96/96 全绿（版本号变更不影响测试）。

## 6. 范围外（明确不做）

- 代码签名与证书
- MSIX / 应用商店
- Android APK（用户暂缓）
- 品牌图标设计
- 自动更新
