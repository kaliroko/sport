# 功能路线图（Feature Roadmap）

> 本文件记录「自律」App 的功能规划与已知技术债，按优先级和实现成本排序。
> 每项都标注了**涉及的代码位置**，方便直接开工。

---

## ✅ 已完成

### 打卡 / 首页

| 项 | 说明 |
|---|---|
| 水目标统一 | 原来 300 / 2000 / 1500 三个数字互相矛盾，现在统一从 `AppConstants.waterGoalMl` 派生 |
| 晨起温水可打卡 | `daily_check_ins` 新增 `water_morning` 列（DB v4 + 幂等迁移），此前该任务卡永远无法勾选 |
| 「今日完成」计数正确 | 原来最多只能显示 8/10，且「勾完所有任务」的庆祝判定是死代码 |
| 饮水卡片重做 | 点第 N 杯 = 记为 N 杯，封顶 1500ml，可回退；修掉「一喝就满格」和标签错算（250 显示成 200） |
| 一键完成 | 原来只置 8 个 bool，完成率停在 80%，按钮不消失 |
| 自定义习惯 | 增删后真正刷新列表（`refresh()` 原来只 notify 不查库）；修掉图标选择器点了就关弹窗 |
| 进度环可见 | `AnimationController` 初值 0 导致 `ScaleTransition` 把环缩到不可见 |
| 禁欲打卡（独立追踪） | `daily_check_ins` 新增 `abstinence` 列（DB v6）。**刻意不计入**完成率/环形图，也不会被「一键完成」顺带打上，拥有独立的连续天数统计 |
| 「最佳连续」修正 | `getBestStreak` 原来只按下标累加、不校验日期连续性，1 月 1 日与 1 月 10 日会被算成「连续 2 天」 |

### 训练 / 记录

| 项 | 说明 |
|---|---|
| **训练可记录** | 新增按组写入 `workout_logs`。此前该表全项目无任何写入点，导致记录页四张图表永远是空的 |
| 每组打卡 | 点「完成这一组」写入一条日志，一组一行（`SUM(reps)` = 总次数，`MAX(duration_seconds)` = 最长单次） |
| 组间休息倒计时 | `Timer.periodic` 实现并可取消（原来是 `Future.delayed` 递归，页面销毁后仍会 setState） |
| 计时型动作 | 倒计时结束自动记为完成一组 |
| 今日训练进度 | 顶部进度条显示 `已完成组数 / 总组数`，数据由今日日志派生 → 切 Tab、重启都不丢 |
| 自动同步打卡 | 所有动作做满组数后自动勾上首页「运动完成」 |
| 卡路里修正 | 原来把「3组×15个」的 15 当作 **15 分钟**，数值严重虚高 |

---

## P1 — 建议下一步（高价值 / 低成本）

### 1. 补打卡与历史日期切换
**为什么**：README 宣称支持「补打卡」，但首页硬编码 `service.todayDate`，历史记录完全无法编辑。用户漏打一天就永久留下污点，直接影响连续打卡动力。

- 首页顶部日期条做成可点，弹日期选择器
- `CheckInService` 增加 `selectedDate` 状态，`_loadTodayCheckIn()` 改为 `_loadCheckIn(date)`
- 需要限制不能补未来日期；建议允许补最近 7 天

**涉及**：`check_in_service.dart`、`home_screen.dart:108`（日期条）、`check_in_repository.dart`（已有按日期查询能力）

### 2. 训练历史列表
**为什么**：现在训练完就"消失"了，用户看不到自己练过什么，成就感断裂。

- 记录页增加「训练历史」卡片：按日期倒序列出 `exerciseName + 组数×次数`
- 数据已在 `workout_logs`，直接 `getAllWorkoutLogs()` 分组即可

**涉及**：`stats_screen.dart`、`workout_repository.dart`

### 3. 体重/围度录入入口 + 真实折线图
**为什么**：`body_measurements` 表和 `MeasurementRepository` 都已存在，但**没有任何 UI 可以录入**，所以统计页的「体重趋势」只能显示当前体重。

- 记录页加「记录身体数据」按钮 → 弹窗录入体重/腰围/胸围/臂围
- 把简化版体重卡片换成真实 `fl_chart` 折线图
- 这是解锁徽章 `metamorphosis_complete`（腰围减少 ≥2cm）的前提

**涉及**：`stats_screen.dart:210`（`_WeightTrendChart` 目前是简化版）、`measurement_repository.dart`（已就绪但无人调用）

### 4. 提醒设置持久化
**为什么**：`_showReminderDialog` 里的开关是局部变量，关掉弹窗就丢；而且 `scheduleWaterReminder` 用的是**一次性**通知，不会每天重复。

- 用 `shared_preferences`（或新建 settings 表）保存开关与时间
- `zonedSchedule` 补上 `matchDateTimeComponents: DateTimeComponents.time` 才会每天重复

**涉及**：`profile_screen.dart:274`、`notification_service.dart:122`

### 5. 成就徽章真正生效
**为什么**：`AppConstants.badges` 定义了 12 枚徽章，`achievements` 表也建好了，但**没有任何解锁逻辑**，`badge_widget.dart` 也无人使用。

- 在 `CheckInService._notifyChange()` 后跑一次解锁检查
- 已解锁的落库到 `achievements`，首解锁弹庆祝

**涉及**：`constants.dart:281`（徽章定义）、`database.dart`（achievements 表）、`widgets/badge_widget.dart`（已就绪但未使用）

---

## P2 — 中期增强

### 6. 本周趋势报告 / 周报
自动生成「本周完成率 / 训练次数 / 总组数 / 饮水达标天数」，配一个分享图（`share_plus` 已引入）。周日晚上推送。

### 7. 照片对比
README 宣称的「每周日拍照对比」目前是占位。`body_measurements` 已有 `photo_front` / `photo_side` 字段，`image` 包也已引入。需要处理权限与文件存储。

### 8. 数据导出真正可用
`csv` / `pdf` / `file_picker` 三个依赖都已引入，但导出弹窗点下去只弹「功能开发中」。数据其实都在 SQLite 里，导出 CSV 是纯体力活。

### 9. 训练动作库扩充 + 自定义训练日
目前 4 套计划的 `dailySchedule` 是**编译期常量**，用户无法增删动作。可做成：
- 允许在计划里替换某个动作（例如没有单杠就换掉悬垂举腿）
- 允许自定义训练日顺序

### 10. 训练强度与 RPE 记录
`WorkoutLog.intensity` 字段已存在但永远写入默认值。让用户每组选「轻松/适中/吃力/力竭」，可用于后续的负荷建议。

---

## P3 — 差异化亮点

### 11. 智能计划调整
根据近期完成率与记录数据，自动建议"今天降低到 week3 强度"或"该加量了"。这是把现有数据用起来做闭环的关键。

### 12. 饮食日记
目前饮食页是**纯静态内容**（口诀、红绿灯清单）。可以加：
- 拍照/点选记录三餐
- 与打卡里的 `breakfast_healthy` / `lunch_controlled` 等字段联动
- 饮水与饮食数据合并出「热量收支」估算

### 13. 树洞 / 心情日记
`Mood` 枚举和 `note` 字段都已存在但 UI 极简。可做成心情 + 图文日记，配合趋势图看情绪与打卡的相关性。

### 14. 小组互相监督
需要后端（目前是纯本地应用）。可以先做"导出周报图片分享到微信群"这种轻量方案。

---

## 技术债（建议尽早处理）

| 项 | 位置 | 说明 |
|---|---|---|
| **切 Tab 丢状态** | `app.dart:104` | 5 个页面的 `AutomaticKeepAliveClientMixin` 在非懒加载列表里**完全没有效果**。要么改 `IndexedStack` 保留状态（但启动会同时构建 5 个页面），要么删掉这些无效 mixin。目前是"两头不靠" |
| **庆祝遮罩盖不住导航栏** | `home_screen.dart:293` | 遮罩在 Scaffold 的 `body` 里，导航栏层级更高。需把遮罩提到 `MainScreen`（用 `Overlay`） |
| **调试上传服务硬编码内网 IP** | `debug_upload_service.dart:12` | `192.168.1.100:8080`，且 `usesCleartextTraffic="false"` 会让 HTTP 请求在 release 包被系统拦截。这是面向用户的功能，建议整个移除或加开关 |
| **`vendor/` 补丁需登记** | `vendor/liquid_glass_widgets/.../glass_dialog.dart` | 打了「内容区可滚动」补丁。若将来从上游重新拉库，此改动会丢失 |
| **没有测试** | 全项目 | `flutter test` 在 CI 里是 `|| true`（失败也不阻塞）。至少应给 `DailyCheckIn.completionRate`、`check_in_repository.getConsecutiveDays`、`_parseSetTarget` 这几个纯函数加单测 |
| **`_showExportDialog` 等占位** | `profile_screen.dart:338` | 「云备份」直接弹提示说未开启，建议移除或明确标灰 |

---

## 建议的实施顺序

```
P1-2 训练历史   ─┐
P1-3 身体数据   ─┼─ 都用现成的表和 Repository，投入小、立刻有产出
P1-5 徽章解锁   ─┘

P1-1 补打卡     ── 体验缺口最大，但需要改状态管理，稍复杂

P1-4 提醒持久化 ── 用户能立刻感知，顺便修掉一次性通知的 bug

P2-6 周报       ── 留存利器，等 P1 数据齐全后做效果最好
```

**原则**：优先做"表已建好但没 UI / 有 UI 但没数据"的功能——这类改动成本最低，且能立刻让已有页面从"永远空着"变成"有内容"。
