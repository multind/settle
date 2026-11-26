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
