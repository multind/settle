# Milestone 1 验收走查清单（规格 §8.1）

执行方式：Windows 桌面端 `flutter run -d windows`；手机端连接 Android 设备/模拟器后
`flutter run -d <device>`。断网场景：直接断开本机网络再走查（本应用无任何网络依赖，
本地照常）。每项勾选后打 `[x]`。

**验证方式说明（2026-11-25 更新）：** 大部分功能项已由自动化测试（96/96 全绿）与
Windows 桌面真机启动冒烟 + 视觉截图（`build/windows/smoke3.png`）验证；标注
「真机待复核」的项因 Android 构建按用户要求暂缓、或涉及真实系统对话框/断网操作，
需后续人工补走。

## 环境准备
- [x] `flutter doctor` 中 Windows 与 Android 工具链可用（VS 2022 17.14.45、Android SDK 36 + JDK 21）
- [x] `flutter build windows --debug` 成功（`build\windows\x64\runner\Debug\gtd_app.exe`）；
      `flutter build apk --debug` **暂缓**（用户要求，2026-11-25，真机待复核）

## 1. 双端启动与断点布局
- [x] 桌面端（宽屏）出现左侧 8 项侧边栏：收件箱/今日/项目/情境/等待/将来也许/回顾/设置
      （截图 smoke3.png 确认 + responsive_shell_test）
- [x] 手机端（窄屏）出现底部 5 项导航：收件箱/今日/项目/回顾/设置（widget 测试 400px 布局断言；真机待复核）
- [x] 调整窗口宽度跨过 600px 断点，布局在侧边栏/底部导航间即时切换（widget 测试两态断言；真实拖拽窗口待复核）

## 2. 快速收集
- [x] 收件箱顶部快速收集框输入一句话并提交，条目出现在列表（原文/来源徽标 Text/状态 Pending）
      （quick_collect_test + 截图确认渐变收集框）
- [x] 在非收件箱页（如今日页）点浮动 + 按钮，输入并提交，条目进入收件箱（1 步完成）
      （quick_collect_test + responsive_shell_test）

## 3. 手动理清（流转规则 §5.2）
- [x] 理清为下一步行动：条目状态变为 Clarified，任务出现在今日页（clarify_dialog_test + clarify_service_test）
- [x] 理清为等待任务：必须填写等待对象，保存后出现在等待页并显示 waiting_on（同上）
- [x] 理清为将来也许：任务出现在将来也许页（同上）
- [x] 理清为项目：项目出现在项目页，条目标 Clarified（同上）
- [x] 理清为删除：弹二次确认，确认后条目消失且不产生任何任务/项目（同上）

## 4. Task 全字段
- [x] 创建/编辑任务可设置：标题、状态、等待对象、备注、截止日、计划时间、精力、优先级、项目、情境、标签
      （task_form_fields_test + task_edit_dialog_test）
- [x] 等待任务缺等待对象时保存被拦截（表单校验 + 数据层 ArgumentError）（task_form_fields_test + task_repository_test）

## 5. 四个视图
- [x] 项目页：项目卡片显示名称/目标/其下任务；删除项目二次确认后任务一并删除（projects_page_test）
- [x] 情境页：默认 @电脑/@外出/@电话；删除情境后相关任务的情境变空（contexts_page_test）
- [x] 等待页：只显示 waiting 任务及等待对象；完成按钮将任务置 done（waiting_someday_test）
- [x] 将来也许页：只显示 someday 任务（waiting_someday_test）

## 6. 手动回顾
- [x] 回顾页新建回顾：填总结与 done/new/stalled 三个数字，保存后列表显示日期/总结/统计（review_page_test）

## 7. 设置页
- [x] 语言切换：跟随系统/中文/English 三档，切换后导航文案立即变化（settings_page_test + app_smoke_test）
- [x] 导出备份：保存 JSON 文件，内容含 inbox_items/projects/contexts/tags/tasks/task_tags/reviews
      （settings_page_test Fake 网关验证 JSON 内容；真实文件对话框待复核）
- [x] 恢复备份：选择导出的 JSON 后数据完整恢复（含任务-标签关联）
      （settings_page_test + export_service_test；真实文件对话框待复核）
- [x] 恢复非法 JSON 提示"备份文件无效"且不动现有数据（settings_page_test）
- [x] "AI 模型配置（M2 启用）"占位入口存在且不可点（settings_page_test + 截图确认）

## 8. 双语骨架
- [x] 切到中文后：导航、收集框、理清按钮、设置项均为中文（app_smoke_test 切换中文断言）
- [x] 切回英文恢复正常英文文案（settings_page_test 切换回 English 断言）

## 9. 纯本地/断网
- [ ] 断网状态启动应用并完整走一遍收集→理清→四个视图→回顾→导出，无异常、无报错
      （待人工断网复走；本应用无网络依赖，规格 §4.2 不变量 1 已由 pubspec 检查确认无网络/AI 包）

## 10. 自动化测试
- [x] `flutter test` 全绿（数据层 + 界面层，96/96）
- [x] `flutter analyze` 无 error（58 条 issue 全为 SDK 级 material.dart 弃用 info 与 test/data 既有基线 warning，0 error）
