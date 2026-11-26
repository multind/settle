# 安顿 Settle「GTD 使用指南分层提示」设计

日期：2026-11-26
状态：设计已批准（用户逐节确认，本节为落地 spec）
前置：分支 `milestone-1`，HEAD `6289bf8`，工作区干净，测试 201/201 全绿，analyze 0 error（3 warning / 63 info 旧基线）

## Goal（目标）

为安顿 Settle 引入「GTD 使用指南分层提示」：三个互补单元——① **PageRuleHint**（每页空状态从单行文案升级为「图标 + 标题 + 该页纪律」的复用组件，把 GTD 使用纪律带到用户最需要它的空状态时刻）；② **OnboardingCard**（首次启动的引导卡，三条铁律 + 每日动作 + 跳完整指南，关闭后经 `gtd_guide_seen` 标记不再出现）；③ **GtdGuidePage**（完整指南页，作为侧边栏第 12 个导航目的地，含三条铁律 / 每天固定动作 / 各清单使用规则 / 注意事项四个分区）。全部文案走 l10n 中英双语，视觉遵循既有 Things 3 极简规范（纯底 + 1px hairline + 圆角 8，零阴影）。灵感来自用户微信笔记 GTD 模板（7 清单 + 三条铁律 + 12 条注意事项），本次把同级别「使用纪律」沉淀进应用界面。

## Non-Goals（非目标）

- **不做定时提醒**：应用内到点提醒（ReminderService）已存在，本功能不新增任何提醒能力；引导/指南文案中只「提示用户」纪律，不实现调度（留 M3）。
- **不改 ReminderService / 数据层 schema**：不新增数据表、不迁移数据、不加表字段。持久化仅 1 个 SharedPreferences bool key。
- **不改既有导航索引语义**：只**追加** `_navSpecs` 第 12 项（index 11，置于设置之后），不动既有 0..10 的索引、`_digitKeys` 9 项与 Ctrl+0 映射。
- **不做每页独立首次引导**：引导卡全局一次（`gtd_guide_seen`），不做「每页各自首次进入才提示」。
- **不改品牌/视觉体系**：不新增主题 token、不改 AppTokens、不改圆角/主色/字体；新组件全部复用现有 token。
- **不改历史文档**：`docs/superpowers/plans/**`、`docs/superpowers/specs/**` 历史记录保持原样。

## Context（上下文 / 现状盘点）

### 1. 现有空态文案（6 个 key，12 处使用）

各页空态目前是 `Center(child: Text(l10n.xxxEmpty))` 单行文案，无图标无纪律说明：

| l10n key | 文案（zh / en） | 使用页 |
|---|---|---|
| `emptyInbox` | 收件箱是空的，在上方写下第一条想法。 / Inbox is empty. Capture your first thought above. | inbox_page.dart（页级空态） |
| `todayEmpty` | 今日无安排 / Nothing scheduled today. | today_page.dart（页级空态） |
| `anytimeEmpty` | 没有随时可做的任务 / No tasks anytime. | anytime_page.dart（页级空态） |
| `upcomingEmpty` | 没有未来安排 / No upcoming tasks. | upcoming_page.dart（页级空态） |
| `logbookEmpty` | 暂无完成记录 / No completed tasks yet. | logbook_page.dart（页级空态，未搜索时） |
| `emptyTasks` | 这里还没有内容。 / Nothing here yet. | review_page.dart、someday_page.dart、projects_page.dart（页级 + 项目卡内）、contexts_page.dart、waiting_page.dart |

另有 `logbookSearchEmpty`（「无匹配任务 / No matching tasks.」）用于日志搜索无匹配——**保留**。

### 2. `_navSpecs` 与快捷键结构（responsive_shell.dart）

- `_navSpecs` 为 11 项 `const List<_NavSpec>`（index 0..10）：收件箱 0 / 今日 1 / 即将 2 / 随时 3 / 将来也许 4 / 项目 5 / 情境 6 / 等待 7 / 日志 8 / 回顾 9 / 设置 10。
- `_pages` 为 `static const List<Widget>`（11 项，与 `_navSpecs` 一一对应）。
- 快捷键派生关系（**追加后必须保持的约束**）：
  - `_digitKeys` = `digit1..digit9` 共 9 项；循环 `for n in 0..8` 取 `_navSpecs[n]` → Ctrl/Cmd+1..9 = 收件箱..日志（index 0..8）。
  - Ctrl/Cmd+0 = `_navSpecs[_digitKeys.length]` = `_navSpecs[9]` = 回顾。
  - **推论：第 12 项必须追加在 `_navSpecs[10]`（设置）之后（index 11）**。任何插入 index ≤ 9 的修改都会平移 `_navSpecs[9]` 与 1..9 映射，破坏 Ctrl+0/1..9 快捷键。
- 窄屏底部栏 5 项（inNarrow 4 项 + 更多槽位）、「更多」抽屉（inMore 6 项）、FAB 显隐（collectFab）全部由 `_navSpecs` 派生；`_labelOf` 是 l10n key → 文本的集中 switch。
- 相关 doc 注释需同步：`_NavSpec.index`（0..10）、`_SwitchViewIntent`（0..10）、`_navSpecs` 注释（11 项 / 抽屉 6 项 / 覆盖 11 页）、类注释（侧边栏 11 项）。

### 3. shared_preferences 使用点

- `main.dart`：`SharedPreferences.getInstance()` 后经 `sharedPreferencesProvider` override 注入（`lib/data/providers.dart`），`Provider<SharedPreferences>`，测试经 `SharedPreferences.setMockInitialValues({})` mock。
- 既有用法：`settings_controller.dart` 读写 `'locale'` 字符串 key。
- **本功能沿用同款模式**：新增 bool key `gtd_guide_seen`，无新表、无迁移、无新依赖。

### 4. l10n 现状

- 双 arb 模板（`app_en.arb` 为 template）+ `flutter gen-l10n` 生成 3 个文件（`app_localizations.dart` / `_en` / `_zh`），生成文件入库随改随提交。
- 现有 key 约 132 个，中英双语齐备；空态相关 key 见第 1 节。
- 测试：`l10n_smoke_test.dart` 已覆盖 nav 字符串双语冒烟。

## Proposed Architecture（架构决策）

### A. 分层混合三单元总览

```
lib/features/guide/            ← 新 feature 模块（三个单元同属「使用指南」功能）
├── page_rule_hint.dart        ← 单元一：PageRuleHint（空状态复用组件）
├── onboarding_card.dart       ← 单元二：OnboardingCard（首次引导卡）
└── gtd_guide_page.dart        ← 单元三：GtdGuidePage（完整指南页，导航 index 11）
```

组件放置决策：**新建 `lib/features/guide/` 模块**，而非塞进 `lib/app/glass.dart`。理由：`lib/app/` 只承载外壳/主题/视觉原语（glass.dart 是容器与按钮等「样式组件」），而 PageRuleHint / OnboardingCard / GtdGuidePage 是同属「使用指南」的**内容组件**（l10n 语义、引导流程、导航目的地），归入同一 feature 模块可发现性最好，且与其他 feature（inbox/today/…）并列符合仓库目录约定。跨 feature import（各页 import `features/guide/page_rule_hint.dart`）与现状一致（各页已 import `features/task/task_list_view.dart`、`app/glass.dart`）。

### B. 单元一：PageRuleHint（空状态规则提示）

**组件签名**（放 `lib/features/guide/page_rule_hint.dart`）：

```dart
class PageRuleHint extends StatelessWidget {
  const PageRuleHint({
    super.key,
    required this.icon,      // 页面图标（复用导航图标，与侧边栏视觉一致）
    required this.title,     // 纪律标题（l10n 已解析字符串，页面传入）
    required this.message,   // 纪律正文（l10n 已解析字符串，页面传入）
  });
}
```

- **渲染**：居中列——图标（40px，`tokens.muted`）→ 标题（15px w600，`tokens.text`）→ 正文（13px，`tokens.muted`，textAlign.center，maxWidth ~340）。整体 `Center(child: PageRuleHint(...))` 作为页面空态，是既有 `Center(child: Text(...))` 的**等位替换**（结构不变、布局风险最低）。
- **根节点加 `Key('page_rule_hint')`**，供测试通用断言。
- **接入方式**：10 个页面各自把 `Center(child: Text(l10n.xxxEmpty))` 替换为 `Center(child: PageRuleHint(icon: <nav 图标>, title: l10n.ruleXxxTitle, message: l10n.ruleXxxMessage))`。图标沿用 `_navSpecs` 同款（inbox_outlined / today / event_outlined / all_inclusive_outlined / nights_stay_outlined / folder_outlined / place_outlined / hourglass_empty / book_outlined / history）。

**10 页接入点清单（页面 → 图标 → 内容映射，文案全文见「内容文案」节）**：

| 索引 | 页面 | 图标 | 标题 key | 正文 key |
|---|---|---|---|---|
| 0 | 收件箱 inbox | `Icons.inbox_outlined` | `ruleInboxTitle` | `ruleInboxMessage` |
| 1 | 今日 today | `Icons.today` | `ruleTodayTitle` | `ruleTodayMessage` |
| 2 | 即将 upcoming | `Icons.event_outlined` | `ruleUpcomingTitle` | `ruleUpcomingMessage` |
| 3 | 随时 anytime | `Icons.all_inclusive_outlined` | `ruleAnytimeTitle` | `ruleAnytimeMessage` |
| 4 | 将来也许 someday | `Icons.nights_stay_outlined` | `ruleSomedayTitle` | `ruleSomedayMessage` |
| 5 | 项目 projects | `Icons.folder_outlined` | `ruleProjectsTitle` | `ruleProjectsMessage` |
| 6 | 情境 contexts | `Icons.place_outlined` | `ruleContextsTitle` | `ruleContextsMessage` |
| 7 | 等待 waiting | `Icons.hourglass_empty` | `ruleWaitingTitle` | `ruleWaitingMessage` |
| 8 | 日志 logbook | `Icons.book_outlined` | `ruleLogbookTitle` | `ruleLogbookMessage` |
| 9 | 回顾 review | `Icons.history` | `ruleReviewTitle` | `ruleReviewMessage` |

**保留不动**：项目卡内「无任务」小字 `emptyTasks`（项目卡片内 rows.isEmpty 的内联提示，非页级空态）；日志搜索无匹配 `logbookSearchEmpty`；各页 loading/error 分支。

### C. 单元二：OnboardingCard（首次引导）

**持久化**：SharedPreferences bool key **`gtd_guide_seen`**（命名沿用 `locale` 的 kebab 风格）。默认缺省 = false（未看过 → 展示）。

**挂载位置（外壳层，不遮挡 FAB/导航）**：在外壳 `Scaffold.body` 中，页面内容列改为：

```
wide:  Row[ sidebar, Expanded(_pageColumn()) ]
narrow: _pageColumn()
_pageColumn() = _showGuideCard
    ? Column[ Padding(OnboardingCard), Expanded(_pages[_index]) ]
    : _pages[_index]
```

- 卡片以 **in-flow 布局**置于内容列顶部（页面 Scaffold 之上、全局 FAB 与底部 NavigationBar 之外），从布局上**杜绝遮挡**任何 FAB/导航元素。
- 位置说明（决策点）：卡片位于页面 **AppBar 之上**（窗口内容区最顶部，视觉为可关闭的顶部横幅）；首启默认停收件箱页，卡片显示在收件箱标题上方。若要求卡片位于各页 AppBar 之下，需要 10 页各自注入（改动面大），本轮不做（见开放问题）。

**状态与读写时机**（`_ResponsiveShellState`）：

- `bool _showGuideCard = false;`
- `initState`：`_showGuideCard = !(ref.read(sharedPreferencesProvider).getBool('gtd_guide_seen') ?? false);` —— prefs 实例在 `main()` 已 `getInstance()` 完毕并注入，读取**同步**无异步窗口；`ConsumerState.initState` 允许 `ref.read`。
- **关闭（右上角 ×）** → `_dismissGuideCard()`：`setState(_showGuideCard=false)` + `prefs.setBool('gtd_guide_seen', true)`（fire-and-forget）。
- **「查看完整指南 →」CTA** → `_openGuide()`：同样置 `gtd_guide_seen=true` + 隐藏卡片 + `_switchTo(11)`。**决策点：CTA 视为「已看过」**——用户已主动进入完整指南，卡片不再滞留；否则卡片会悬在指南页上方造成冗余。

**形态**：Things 3 极简——`GlassContainer(cardSolid, borderColor: stroke, radius 8, 零阴影)`（复用现有组件与 token）；标题行（`onboardingTitle`）+ 右上角 `×`（`Key('onboarding_close')`）；内容两段：三条铁律（复用 `ironRule1..3` + 组标题 `guideSectionLaws`）+ 每天固定动作（复用 `dailyAction1..3` + 组标题 `guideSectionDaily`）；底部 CTA（`Key('onboarding_open_guide')`）。

### D. 单元三：GtdGuidePage（指南页）

`lib/features/guide/gtd_guide_page.dart`，`const GtdGuidePage()`，自身 Scaffold + AppBar(title: `l10n.navGuide`)，body 为 ListView，四个分区卡片（每区 = 组标题（muted 12 w600，复用 `_groupTitle` 样式）+ GlassContainer 卡片，Things 3 纯底 + hairline + radius 8）：

1. **① 三条铁律**：3 行（`ironRule1..3`）。
2. **② 每天固定动作**：3 行（`dailyAction1..3`）。
3. **③ 各清单使用规则**：6 张小卡——收件箱 / 今日 / 等待 / 项目 / 将来也许 / 即将（设计稿中「日程表」即应用内「即将」页，文案用应用内名称）。每卡 = 图标 + `rule*Title` + `rule*Message`（**同空态文案**）+ 一句示例（`guideExample*`）。
4. **④ 注意事项**：4 行（`guideNote1..4`），从 deepseek 12 条提炼适配应用：应用内提醒不可依赖系统级 / 重要截止日日历双保险 / 每周回顾不能省 / 数据可导出 JSON 备份。

指南页**无页面级 FAB**；作为导航目的地时由外壳控制全局收集 FAB 显隐（见 E）。

### E. 导航接入（`_navSpecs` 第 12 项，index 11）

在 `_navSpecs` **末尾追加**（唯一正确位置，见 Context 第 2 节约束）：

```dart
_NavSpec(
  index: 11,
  icon: Icons.menu_book_outlined,
  selectedIcon: Icons.menu_book_outlined,
  labelKey: 'navGuide',
  collectFab: false,
  group: _NavGroup.system,
  inMore: true,      // 进窄屏「更多」抽屉
),
```

派生影响（全部自动正确，无需手改三处渲染）：

- **宽屏侧边栏**：12 项，「系统」组设置之后出现「GTD 指南」。
- **窄屏**：底部栏不变（inNarrow 未设，仍 5 项）；「更多」抽屉自动变 7 项（项目/情境/等待/日志/回顾/设置/**指南**）。
- **FAB 显隐**：`collectFab: false` → 指南页不显示全局收集 FAB（页面自身也无 FAB）。
- **快捷键无影响**：`_digitKeys` 9 项仍派生 `_navSpecs[0..8]`；Ctrl+0 = `_navSpecs[9]` = 回顾。追加 index 11 不触碰 0..9。**回归测试必须锁死 Ctrl+2（今日）/ Ctrl+9（日志）/ Ctrl+0（回顾）**。
- `_pages` 追加 `GtdGuidePage()`（index 11）；`_labelOf` 增加 `case 'navGuide' → l10n.navGuide`。
- 同步更新 doc 注释（`_NavSpec.index` 0..11、`_SwitchViewIntent` 0..11、`_navSpecs` 12 项 / 抽屉 7 项 / 覆盖 12 页、类注释 12 项）。

### F. 设置页入口与 `_pages` 结构调整

- **设置页新增入口**：「查看 GTD 指南」ListTile（`Key('settings_guide_tile')`，图标 `menu_book_outlined`，位于导出/恢复上方）。
- **导航方式（决策点）**：设置页通过**外壳注入回调**切到 index 11（`_switchTo(11)`，侧边栏高亮「GTD 指南」），与侧边栏/抽屉/引导卡 CTA 共用同一导航模型。为此：
  - `SettingsPage` 增加**必填参数** `required VoidCallback onOpenGuide`；
  - `_pages` 由 `static const List<Widget>` 改为 `late final List<Widget> _pages`（initState 构建，`SettingsPage(onOpenGuide: () => _switchTo(11))`）。索引语义、`_navSpecs[i] ↔ _pages[i]` 不变，仅去 const。
- **已否决方案**：设置页 `Navigator.push` 路由推入指南页——会引入「推入路由（带返回箭头、侧边栏不高亮）」与「外壳切页」两种不一致的导航形态，且覆盖侧边栏/FAB，弃用。

### G. l10n 策略（新增 45 / 删除 5 / 净增 40）

- **新增 45 个 key**（完整清单见「内容文案」节）：`navGuide` ×1、规则提示 `rule*Title`/`rule*Message` ×20、引导卡 ×9（`onboardingTitle`、`ironRule1..3`、`dailyAction1..3`、`onboardingOpenGuide`、`onboardingClose`）、指南页 ×14（`guideSection*` ×4、`guideExample*` ×6、`guideNote*` ×4）、`settingsGuide` ×1。
- **复用**：三条铁律/每日动作在引导卡与指南页共用同一组 key（不重复文案）；指南页 6 卡复用 `rule*Title/Message`（「同空态文案多一句示例」语义）。
- **删除 5 个被取代的旧空态 key**：`emptyInbox`、`todayEmpty`、`anytimeEmpty`、`upcomingEmpty`、`logbookEmpty`（全部页级空态被 PageRuleHint 取代）。`emptyTasks`（项目卡内）与 `logbookSearchEmpty` 保留。
- 流程：改 `app_en.arb` + `app_zh.arb` → `flutter gen-l10n` 重新生成 3 个 dart 文件并提交；删除 key 前先 grep 审计 `lib/`、`test/` 无残留引用。

## 内容文案（zh / en 完整草案）

### PageRuleHint 文案（20 key）

| key | zh | en |
|---|---|---|
| `ruleInboxTitle` | 只收集，不整理 | Collect, don't organize |
| `ruleInboxMessage` | 每条以动词开头，写清下一步动作。 | Start each item with a verb and state the next action. |
| `ruleTodayTitle` | 今日限量 1-3-5 | Today is 1-3-5 |
| `ruleTodayMessage` | 只放 1 件大任务、3 件中任务、5 件小任务，做完再放新的。 | Keep 1 big, 3 medium, and 5 small tasks. Add more only after finishing. |
| `ruleUpcomingTitle` | 只放硬时间 | Hard time only |
| `ruleUpcomingMessage` | 只放会议、截止等硬时间；把任务拖到日期头可安排开始日期。 | Keep meetings and deadlines here. Drag a task onto a date header to schedule it. |
| `ruleAnytimeTitle` | 随时可做 | Do anytime |
| `ruleAnytimeMessage` | 近期要做的、不必排到某一天的任务，放这里。 | Tasks you'll do soon, without a fixed day, live here. |
| `ruleSomedayTitle` | 以后再说 | Maybe later |
| `ruleSomedayMessage` | 现在不做、以后可能的事；每周回顾时看一次。 | Not now, maybe later — take a look during the weekly review. |
| `ruleProjectsTitle` | 项目要有下一步 | Every project needs a next action |
| `ruleProjectsMessage` | 每个项目必须有一个下一步动作；目标别写大词。 | Give each project a concrete next action and a specific goal. |
| `ruleContextsTitle` | 按场景过滤 | Filter by context |
| `ruleContextsMessage` | 按场景过滤（@工作 / @家…），到哪儿做哪样。 | Filter by place or mood — @work, @home — and do what fits where you are. |
| `ruleWaitingTitle` | 写清跟进日 | Set a follow-up date |
| `ruleWaitingMessage` | 每条等待都要写跟进日，否则会忘；每天扫一眼今天到跟进日的。 | Every waiting item needs a follow-up date; scan today's due follow-ups every day. |
| `ruleLogbookTitle` | 完成自动留存 | Done stays here |
| `ruleLogbookMessage` | 完成的记录自动留存；每周回顾时清点一遍。 | Completed tasks are kept automatically — count them at your weekly review. |
| `ruleReviewTitle` | 每周一次，20 分钟 | 20 minutes, every week |
| `ruleReviewMessage` | 清空收集箱、跟进等待、推进项目下一步、激活将来、检查硬时间冲突。 | Empty the inbox, follow up on waiting, advance projects, activate somedays, and check for hard-time conflicts. |

### 导航与设置入口（2 key）

| key | zh | en |
|---|---|---|
| `navGuide` | GTD 指南 | GTD Guide |
| `settingsGuide` | 查看 GTD 指南 | View GTD Guide |

### OnboardingCard 文案（9 key）

| key | zh | en |
|---|---|---|
| `onboardingTitle` | 欢迎使用安顿 | Welcome to Settle |
| `ironRule1` | 想到就写进收件箱 | Capture everything into the inbox |
| `ironRule2` | 两分钟能做完，立刻做 | Do it now if it takes two minutes |
| `ironRule3` | 今日清单限量 1-3-5 | Keep today to 1-3-5 |
| `dailyAction1` | 早上：看今日清单 | Morning: review Today |
| `dailyAction2` | 晚上：清空收集箱、勾完成、写下明日首要 | Evening: clear the inbox, check things off, set tomorrow's top task |
| `dailyAction3` | 周日：20 分钟回顾 | Sunday: 20-minute review |
| `onboardingOpenGuide` | 查看完整指南 → | View the full guide → |
| `onboardingClose` | 关闭 | Close |

### GtdGuidePage 文案（14 key）

| key | zh | en |
|---|---|---|
| `guideSectionLaws` | 三条铁律 | Three iron rules |
| `guideSectionDaily` | 每天固定动作 | A daily rhythm |
| `guideSectionLists` | 各清单使用规则 | How to use each list |
| `guideSectionNotes` | 注意事项 | Notes |
| `guideExampleInbox` | 例：「给客户回邮件，确认报价」 | e.g. “Email the client to confirm the quote” |
| `guideExampleToday` | 例：1 件大任务「写周报」+ 3 件中任务 + 5 件小任务 | e.g. 1 big “write the weekly report” + 3 medium + 5 small |
| `guideExampleWaiting` | 例：「等供应商报价，周五跟进」 | e.g. “Waiting on the vendor quote — follow up Friday” |
| `guideExampleProject` | 例：项目「搬家」，下一步是「联系搬家公司询价」 | e.g. project “Moving” → next action “call movers for a quote” |
| `guideExampleSomeday` | 例：「学吉他」「去冰岛」 | e.g. “learn guitar”, “visit Iceland” |
| `guideExampleUpcoming` | 例：周三 14:00 会议、周五提交截止 | e.g. Wednesday 14:00 meeting, Friday submission deadline |
| `guideNote1` | 提醒是应用内提示，重要的事请自己留意，别依赖系统级提醒。 | Reminders are in-app only — rely on your own attention for what matters. |
| `guideNote2` | 重要截止日建议在日历里也记一份，双保险。 | Keep important deadlines in your calendar too — belt and braces. |
| `guideNote3` | 每周回顾不能省，它是系统不失控的开关。 | Never skip the weekly review — it's what keeps the system under control. |
| `guideNote4` | 数据可以随时导出 JSON 备份。 | Export a JSON backup anytime. |

## Files To Change（文件改动清单）

### 新增文件

| 文件 | 内容 |
|---|---|
| `lib/features/guide/page_rule_hint.dart` | PageRuleHint 复用组件（icon + title + message，`Key('page_rule_hint')`） |
| `lib/features/guide/onboarding_card.dart` | OnboardingCard 组件（`Key('onboarding_card')` / `onboarding_close` / `onboarding_open_guide`），回调 `onDismiss` + `onOpenGuide` |
| `lib/features/guide/gtd_guide_page.dart` | GtdGuidePage：四分区指南页 |
| `test/widget/page_rule_hints_test.dart` | 10 页空态规则提示断言（见测试节） |
| `test/widget/onboarding_card_test.dart` | 引导卡首启/关闭/重开/CTA/不遮挡 FAB 断言 |
| `test/widget/gtd_guide_test.dart` | 指南页内容渲染（四分区）+ 设置入口导航（shell 级） |

### 修改文件

| 文件 | 改动 |
|---|---|
| `lib/app/responsive_shell.dart` | ① `_pages` 改 `late final` 实例列表（initState 构建，`SettingsPage(onOpenGuide: () => _switchTo(11))` + 追加 `GtdGuidePage()`）；② `_navSpecs` 追加 index 11；③ `_labelOf` 加 `navGuide`；④ OnboardingCard 挂载（`_pageColumn()` + `_showGuideCard` 状态 + `_dismissGuideCard`/`_openGuide`）；⑤ doc 注释同步（0..11 / 12 项 / 抽屉 7 项） |
| `lib/features/settings/settings_page.dart` | 新增必填 `onOpenGuide` 回调参数 + 「查看 GTD 指南」tile（`Key('settings_guide_tile')`） |
| `lib/features/inbox/inbox_page.dart` | 页级空态 → `PageRuleHint(ruleInbox*)` |
| `lib/features/today/today_page.dart` | 页级空态 → `PageRuleHint(ruleToday*)` |
| `lib/features/upcoming/upcoming_page.dart` | 页级空态 → `PageRuleHint(ruleUpcoming*)` |
| `lib/features/anytime/anytime_page.dart` | 页级空态 → `PageRuleHint(ruleAnytime*)` |
| `lib/features/someday/someday_page.dart` | 页级空态 → `PageRuleHint(ruleSomeday*)` |
| `lib/features/projects/projects_page.dart` | 页级空态 → `PageRuleHint(ruleProjects*)`；**项目卡内 `emptyTasks` 保留** |
| `lib/features/contexts/contexts_page.dart` | 页级空态 → `PageRuleHint(ruleContexts*)` |
| `lib/features/waiting/waiting_page.dart` | 页级空态 → `PageRuleHint(ruleWaiting*)` |
| `lib/features/logbook/logbook_page.dart` | 未搜索空态 → `PageRuleHint(ruleLogbook*)`；搜索无匹配 `logbookSearchEmpty` 保留 |
| `lib/features/review/review_page.dart` | 页级空态 → `PageRuleHint(ruleReview*)` |
| `lib/i18n/l10n/app_en.arb` / `app_zh.arb` | 新增 45 key、删除 5 key；`flutter gen-l10n` 重新生成 3 个 dart 文件 |
| `test/widget/responsive_shell_test.dart` | 侧边栏 12 项（`nav_item_11`）、抽屉 7 项（`nav_more_item_11`）、快捷键回归（Ctrl+9 日志 / Ctrl+0 回顾） |
| `test/widget/app_smoke_test.dart` | 回顾页空态断言由「Nothing here yet.」改为回顾规则文案 |
| `test/widget/settings_page_test.dart` | 5 处 `const SettingsPage()` → 带 `onOpenGuide: () {}` 构造；新增 tile 存在断言 |
| `test/widget/anytime_page_test.dart`（3 处）/ `inbox_page_test.dart`（1）/ `logbook_page_test.dart`（3）/ `today_page_test.dart`（2）/ `upcoming_page_test.dart`（2） | 旧空态字符串断言 → 对应 `rule*Message` 文案 |
| `test/widget/l10n_smoke_test.dart` | 新增 `navGuide` / 规则 key 双语冒烟 |

## Testing Strategy（测试策略）

### 1. 空态规则提示（`page_rule_hints_test.dart`）

- 对 10 个页面分别以空库 pump，断言页级空态显示对应 `rule*Title` + `rule*Message`（`Key('page_rule_hint')` 存在）。
- 情境页需先删掉种子 3 情境（`@电脑/@外出/@电话`）再断言空态；其余页默认空库即可。
- 中英双语各抽查一轮（locale zh / en）。

### 2. 引导卡（`onboarding_card_test.dart`，经 ResponsiveShell 整壳）

- **首启出现**：prefs 空 → 启动后 `onboarding_card` 可见（含 `ironRule1`、`dailyAction3`、CTA）。
- **关闭后不再出现**：点 `onboarding_close` → 卡片消失 + `env.prefs.getBool('gtd_guide_seen') == true`；重新 pump 新壳 → 卡片不出现。
- **预置标记**：`SharedPreferences.setMockInitialValues({'gtd_guide_seen': true})` → 卡片不出现。
- **CTA 跳转**：点 `onboarding_open_guide` → 卡片消失 + `GtdGuidePage` 可见 + flag 置位。
- **不遮挡 FAB**：卡片显示时切到今日页，断言 `global_collect_fab` 与 `onboarding_card` **同时可见**（in-flow 布局验证）。

### 3. 指南页导航与内容（`gtd_guide_test.dart` + 扩展 `responsive_shell_test.dart`）

- 宽屏侧边栏 12 项：`nav_item_11` 存在；点击 → `GtdGuidePage` 可见。
- 窄屏「更多」抽屉 7 项：`nav_more_item_11` 存在；点击 → `GtdGuidePage`。
- FAB 显隐：指南页无 `global_collect_fab`、无页面级 FAB。
- **快捷键回归（追加 index 11 后不受影响）**：Ctrl+2 → TodayPage、Ctrl+9 → LogbookPage、Ctrl+0 → ReviewPage；N 收集不受影响。
- **设置入口**：进设置页 → 点 `settings_guide_tile` → `GtdGuidePage` 可见 + 侧边栏 `nav_item_11` 选中高亮。
- 内容渲染：四分区标题（`guideSectionLaws/Daily/Lists/Notes`）+ 抽样断言一条铁律、一条规则、一条注意事项、一条示例（zh/en 各一轮）。

### 4. l10n 双语冒烟

- `l10n_smoke_test.dart` 扩展：zh/en 下 `navGuide`、`ruleInboxTitle/Message`、`onboardingOpenGuide` 取值正确。

### 5. 既有测试同步更新（断言随设计变化，非降级）

- 5 个页测试 + `app_smoke_test.dart` 的旧空态字符串 → 新规则文案（见 Files To Change）。
- `responsive_shell_test.dart` 侧边栏循环扩到 12、抽屉 7 项断言补 `nav_more_item_11`。

## Verification（验证清单）

1. `flutter gen-l10n` 成功（生成 3 个 dart 文件入库）。
2. `flutter analyze` **0 error**；新增代码 **0 warning**（既有 3 warning / 63 info 基线不动）。
3. `flutter test` 全绿：201 基线（含上述断言更新）+ 新增 `page_rule_hints_test` / `onboarding_card_test` / `gtd_guide_test`。
4. grep 审计：`lib/` 与 `test/` 无残留 `todayEmpty` / `anytimeEmpty` / `upcomingEmpty` / `emptyInbox` / `logbookEmpty` 引用。
5. 可选 Windows 手动冒烟：首启见引导卡 → × 关闭 → 重启不再出现；设置「查看 GTD 指南」直达指南页；切中文验证双语。

## Risks And Mitigations（风险与缓解）

1. **导航索引/快捷键被破坏**（指南插入位置不当 → Ctrl+0/1..9 平移）。
   缓解：指南**仅允许追加 index 11**（写死在 spec + 计划任务）；回归测试锁死 Ctrl+2（今日）/ Ctrl+9（日志）/ Ctrl+0（回顾）；`_digitKeys` 派生逻辑不动。
2. **10 页空态替换回归**（布局/文案/测试大面积变更）。
   缓解：PageRuleHint 是 `Center(Text)` 的**等位替换**（结构不变）；旧 key 删除前 grep 审计；既有空态断言在同一提交内同步更新；`emptyTasks`（项目卡内）与 `logbookSearchEmpty` 明确保留。
3. **引导卡遮挡或干扰既有交互**。
   缓解：in-flow Column 布局从结构上杜绝遮挡 FAB/底部导航；测试显式断言「卡片与 FAB 同时可见」；既有壳测试全部复跑防回归。
4. **l10n 再生成遗漏**（忘跑 `gen-l10n` → 新 key 运行时缺失）。
   缓解：计划第一步先改 arb + 跑 gen-l10n；l10n 冒烟覆盖新 key；`flutter analyze` 对漏跑生成文件的引用会报错。
5. **设置页构造签名变更牵连测试**。
   缓解：必填 `onOpenGuide` 参数 + 机械更新 `settings_page_test.dart` 5 处调用；壳测试走真实回调路径验证导航。

**回滚**：本功能纯增量（UI + l10n + 1 个 prefs bool key），无数据迁移、无 schema 变更。回滚 = 撤销本功能提交；`gtd_guide_seen` 残留 key 无副作用（未读即视为未看过）。

## Decision Summary（决策记录）

- **三单元同属新 feature 模块** `lib/features/guide/`（page_rule_hint / onboarding_card / gtd_guide_page），不塞 `lib/app/glass.dart`。
- **PageRuleHint**：等位替换 10 页页级空态（图标复用导航图标 + `rule*Title` + `rule*Message`）；项目卡内 `emptyTasks`、日志搜索 `logbookSearchEmpty` 保留。
- **OnboardingCard**：外壳内容列 **in-flow 顶部**（页面 AppBar 之上），`initState` 同步读 prefs；**× 与 CTA 均置 `gtd_guide_seen=true`**（CTA 视为已看过，同时 `_switchTo(11)`）。
- **持久化**：仅 1 个 bool key `gtd_guide_seen`，沿用 `locale` 读写模式。
- **指南页导航**：`_navSpecs` **仅追加 index 11**（设置之后，`inMore: true`、`collectFab: false`、无快捷键）；`_pages` 追加 `GtdGuidePage()`；`_labelOf` 加 `navGuide`；快捷键 1..9 / Ctrl+0 语义零变化（回归测试锁死）。
- **设置入口**：`SettingsPage` 必填 `onOpenGuide` 回调 + `_pages` 改 `late final` 实例列表（去 const，索引语义不变）；弃用 Navigator.push 方案。
- **l10n**：新增 45 key（规则 ×20 / 引导卡 ×9 / 指南页 ×14 / 导航与设置 ×2）、删除 5 个被取代旧空态 key、净增 40；三条铁律与每日动作在引导卡与指南页共用 key。
- **指南页 ③ 中「日程表」以应用内名称「即将」呈现**。
- **范围红线**：无定时提醒、无 schema 改动、无每页独立引导、无品牌/视觉体系改动、历史文档不改。

## 开放问题（Open Questions）

1. **引导卡位置**：卡片位于页面 AppBar 之上（外壳内容列顶部，视觉为顶部横幅）。若要求位于各页 AppBar 之下，需 10 页各自注入槽位（改动面大），留待后续版本评估。
2. **key 数量超估算**：新增 45 个 l10n key，高于最初「约 20」的估算——因每页规则需「标题 + 正文」两个 key（20 个），加上引导卡与指南页的完整内容 key。文案均已给出完整草案，超量源于设计粒度而非冗余。
3. **注意事项条数**：指南页 ④ 按已批准设计固定为 4 条（提醒/日历/回顾/备份）。deepseek 12 条中其余条目（如「清单不是收藏夹」）如需补充，可在不改变结构的前提下后续加 key，本轮不做。
