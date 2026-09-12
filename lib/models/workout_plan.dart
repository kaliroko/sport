/// 训练计划模型
library;

import 'package:metamorphosis_checkin/utils/constants.dart';

enum PlanDifficulty { beginner, intermediate, advanced }

class WorkoutPlan {
  final String id;
  final String name;
  final String description;
  final int durationDays; // 7 or 30
  final PlanDifficulty difficulty;
  final Map<int, List<MovementConfig>> dailySchedule; // dayIndex -> movements

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.durationDays,
    required this.difficulty,
    required this.dailySchedule,
  });

  /// 取第 [dayIndex] 天（0 基）的训练动作。
  ///
  /// 关键修复：原实现直接用 `dailySchedule[dayIndex]`，而「腹肌撕裂者 30天」
  /// 这类计划的日程表只有 7 项，第 8 天起取到 null 后，调用方会**静默回退到
  /// 新手减脂计划的第 0 天** —— 页面显示「腹肌撕裂者」，实际做的却是
  /// 标准俯卧撑 / 深蹲 / 平板支撑。
  /// 现在按日程表长度取模循环，且任何回退都只发生在本计划内部。
  List<MovementConfig> movementsForDay(int dayIndex) {
    if (dailySchedule.isEmpty) return const <MovementConfig>[];
    final int normalized = dayIndex % dailySchedule.length;
    return dailySchedule[normalized] ??
        dailySchedule[0] ??
        const <MovementConfig>[];
  }

  /// 是否用户自建计划（自建计划不允许被覆盖写回内置常量）
  bool get isCustom => id.startsWith('custom_');
}

// ─── 内置训练计划 ─────────────────────────────────────────────────────────────

class WorkoutPlans {
  WorkoutPlans._();

  static final List<WorkoutPlan> all = <WorkoutPlan>[
    planBeginnerFatLoss,
    planAbsShredder,
    planIntermediateStrength,
    plan30DayTransformation,
  ];

  /// 全部内置动作（按名字去重，保持首次出现顺序）。
  /// 供「自定义训练计划」的动作库选择器使用。
  static List<MovementConfig> get allMovements {
    final result = <MovementConfig>[];
    final seen = <String>{};

    void addAll(List<MovementConfig> list) {
      for (final m in list) {
        if (seen.add(m.name)) result.add(m);
      }
    }

    addAll(AppConstants.strengthMovements);
    for (final plan in all) {
      for (final day in plan.dailySchedule.values) {
        addAll(day);
      }
    }
    return result;
  }

  /// 动作名 → 动作定义。自定义计划的日程表里存的是动作名，
  /// 需要通过这张表还原成完整的 MovementConfig。
  static Map<String, MovementConfig> get movementByName => {
        for (final m in allMovements) m.name: m,
      };

  static const WorkoutPlan planBeginnerFatLoss = WorkoutPlan(
    id: 'beginner_fat_loss',
    name: '新手减脂 7天',
    description: '适合零基础，低强度有氧+基础力量，培养运动习惯',
    durationDays: 7,
    difficulty: PlanDifficulty.beginner,
    dailySchedule: {
      0: _beginnerDay1,
      1: _beginnerDay2,
      2: _beginnerDay1,
      3: _beginnerDay3,
      4: _beginnerDay1,
      5: _beginnerDay2,
      6: _beginnerDay3,
    },
  );

  static const WorkoutPlan planAbsShredder = WorkoutPlan(
    id: 'abs_shredder',
    name: '腹肌撕裂者 30天',
    description: '每天15分钟核心训练，第1-2周打基础，第3-4周加强度',
    durationDays: 30,
    difficulty: PlanDifficulty.intermediate,
    dailySchedule: {
      0: _absCore,
      1: _absOblique,
      2: _absUpper,
      3: _absLower,
      4: _absCore,
      5: _absOblique,
      6: _absRest,
    },
  );

  static const WorkoutPlan planIntermediateStrength = WorkoutPlan(
    id: 'intermediate_strength',
    name: '塑形进阶 7天',
    description: '有一定基础后提升强度，加入更多复合动作',
    durationDays: 7,
    difficulty: PlanDifficulty.advanced,
    dailySchedule: {
      0: _advancedDay1,
      1: _advancedDay2,
      2: _advancedDay1,
      3: _advancedDay3,
      4: _advancedDay1,
      5: _advancedDay2,
      6: _advancedDay3,
    },
  );

  static final WorkoutPlan plan30DayTransformation = WorkoutPlan(
    id: '30day_transform',
    name: '30天蜕变计划',
    description: '四周周期化递进：适应 → 强化 → 塑形 → 冲刺',
    durationDays: 30,
    difficulty: PlanDifficulty.intermediate,
    dailySchedule: _build30DaySchedule(),
  );

  /// 「30天蜕变计划」的完整 30 天日程。
  ///
  /// 原实现只写了 7 天，而 `durationDays` 是 30 —— 第 8 天起
  /// `dailySchedule[dayIndex]` 取到 null，调用方静默回退到别的计划
  /// （详见 WorkoutPlan.movementsForDay 的注释）。
  /// 这里补齐 30 天，并做成真正的周期化递进而不是简单重复。
  static Map<int, List<MovementConfig>> _build30DaySchedule() {
    final template = <List<MovementConfig>>[
      // 第 1 周 · 适应期
      _beginnerDay1, _beginnerDay2, _beginnerDay3, _beginnerDay1, _beginnerDay2, _absCore, _absRest,
      // 第 2 周 · 强化
      _beginnerDay1, _advancedDay1, _beginnerDay3, _advancedDay2, _beginnerDay2, _absOblique, _absRest,
      // 第 3 周 · 塑形
      _advancedDay1, _advancedDay2, _advancedDay3, _advancedDay1, _absUpper, _advancedDay2, _absRest,
      // 第 4 周 · 冲刺
      _advancedDay1, _advancedDay2, _advancedDay3, _advancedDay1, _advancedDay2, _advancedDay3, _absRest,
      // 第 29、30 天 · 主动恢复与收尾
      _absRest, _absLower,
    ];
    return {
      for (var i = 0; i < template.length; i++) i: template[i],
    };
  }

  // ─── 训练内容定义 ────────────────────────────────────────────────────────────
  static const List<MovementConfig> _beginnerDay1 = [
    MovementConfig(
      name: '标准俯卧撑', targetMuscle: '胸、肩、三头肌',
      description: '身体成直线，下降至胸部接近地面',
      commonMistakes: ['塌腰', '撅臀'], week1: '3组×8个', week3: '3组×12个',
      week5: '3组×15个', week7: '3组×20个', type: MovementType.reps, restTime: '60秒',
    ),
    MovementConfig(
      name: '深蹲', targetMuscle: '腿、臀',
      description: '膝盖与脚尖方向一致，下蹲至大腿平行地面',
      commonMistakes: ['膝盖内扣', '弯腰'], week1: '3组×15个', week3: '3组×20个',
      week5: '3组×25个', week7: '3组×30个', type: MovementType.reps, restTime: '45秒',
    ),
    MovementConfig(
      name: '平板支撑', targetMuscle: '核心',
      description: '不塌腰、不撅臀，保持自然呼吸',
      commonMistakes: ['塌腰', '憋气'], week1: '3组×30秒', week3: '3组×40秒',
      week5: '3组×50秒', week7: '3组×60秒', type: MovementType.duration, restTime: '45秒',
    ),
  ];

  static const List<MovementConfig> _beginnerDay2 = [
    MovementConfig(
      name: '登山跑', targetMuscle: '核心、心肺',
      description: '俯卧撑姿势交替提膝，保持核心收紧',
      commonMistakes: ['臀部过高', '节奏过快'], week1: '3组×20秒', week3: '3组×30秒',
      week5: '3组×40秒', week7: '3组×50秒', type: MovementType.duration, restTime: '30秒',
    ),
    MovementConfig(
      name: '开合跳', targetMuscle: '全身、心肺',
      description: '手脚协调开合，保持轻快节奏',
      commonMistakes: ['膝盖内扣', '落地过重'], week1: '3组×30次', week3: '3组×40次',
      week5: '3组×50次', week7: '3组×60次', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '高抬腿', targetMuscle: '核心、心肺',
      description: '原地快速交替抬腿至腰部高度',
      commonMistakes: ['身体后仰', '落地过重'], week1: '3组×20秒', week3: '3组×30秒',
      week5: '3组×40秒', week7: '3组×50秒', type: MovementType.duration, restTime: '30秒',
    ),
  ];

  static const List<MovementConfig> _beginnerDay3 = [
    MovementConfig(
      name: '靠墙静蹲', targetMuscle: '大腿',
      description: '背部贴墙，大腿与地面平行，膝盖不超过脚尖',
      commonMistakes: ['膝盖超过脚尖', '身体下滑'], week1: '3组×30秒', week3: '3组×40秒',
      week5: '3组×50秒', week7: '3组×60秒', type: MovementType.duration, restTime: '45秒',
    ),
    MovementConfig(
      name: '臀桥', targetMuscle: '臀、核心',
      description: '仰卧抬臀至身体成直线，顶峰收缩1秒',
      commonMistakes: ['腰部过度拱起', '幅度不够'], week1: '3组×15个', week3: '3组×20个',
      week5: '3组×25个', week7: '3组×30个', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '俯卧撑（跪姿）', targetMuscle: '胸、肩、三头肌',
      description: '膝盖着地做俯卧撑，身体保持直线',
      commonMistakes: ['塌腰', '肘部外展'], week1: '3组×6个', week3: '3组×10个',
      week5: '3组×12个', week7: '3组×15个', type: MovementType.reps, restTime: '45秒',
    ),
  ];

  static const List<MovementConfig> _absCore = [
    MovementConfig(
      name: '卷腹', targetMuscle: '上腹',
      description: '腰部始终贴地，肩胛骨抬离地面即可',
      commonMistakes: ['抱头猛拉', '腰部离地'], week1: '3组×15个', week3: '3组×20个',
      week5: '3组×25个', week7: '3组×30个', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '平板支撑', targetMuscle: '核心',
      description: '不塌腰、不撅臀，保持自然呼吸',
      commonMistakes: ['塌腰', '憋气'], week1: '3组×40秒', week3: '3组×50秒',
      week5: '3组×60秒', week7: '3组×70秒', type: MovementType.duration, restTime: '45秒',
    ),
    MovementConfig(
      name: '仰卧举腿', targetMuscle: '下腹',
      description: '双腿伸直抬起至垂直，下放时脚不触地',
      commonMistakes: ['腿部弯曲', '腰部离地'], week1: '3组×10个', week3: '3组×12个',
      week5: '3组×15个', week7: '3组×20个', type: MovementType.reps, restTime: '30秒',
    ),
  ];

  static const List<MovementConfig> _absOblique = [
    MovementConfig(
      name: '俄罗斯转体', targetMuscle: '腹斜肌',
      description: '坐姿屈膝，双手持物左右转动躯干',
      commonMistakes: ['腰部离地', '转动不够'], week1: '3组×16次', week3: '3组×20次',
      week5: '3组×24次', week7: '3组×30次', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '侧支撑', targetMuscle: '腹斜肌',
      description: '侧卧用前臂和脚支撑，身体成直线',
      commonMistakes: ['臀部下沉', '身体扭转'], week1: '3组×20秒/侧', week3: '3组×30秒/侧',
      week5: '3组×40秒/侧', week7: '3组×50秒/侧', type: MovementType.duration, restTime: '30秒',
    ),
    MovementConfig(
      name: '自行车卷腹', targetMuscle: '腹斜肌、上腹',
      description: '仰卧交替肘触对侧膝盖，缓慢控制',
      commonMistakes: ['头部用力拉扯', '速度过快'], week1: '3组×12次/侧', week3: '3组×16次/侧',
      week5: '3组×20次/侧', week7: '3组×24次/侧', type: MovementType.reps, restTime: '30秒',
    ),
  ];

  static const List<MovementConfig> _absUpper = [
    MovementConfig(
      name: '卷腹', targetMuscle: '上腹',
      description: '腰部始终贴地，肩胛骨抬离地面即可',
      commonMistakes: ['抱头猛拉', '腰部离地'], week1: '3组×20个', week3: '3组×25个',
      week5: '3组×30个', week7: '3组×35个', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '反向卷腹', targetMuscle: '上腹',
      description: '仰卧屈膝，用腹部力量将膝盖抬向胸部',
      commonMistakes: ['用手拉腿', '速度过快'], week1: '3组×12个', week3: '3组×15个',
      week5: '3组×18个', week7: '3组×20个', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '悬垂举腿（辅助）', targetMuscle: '上腹',
      description: '双手抓杆，用腹部力量将腿抬起',
      commonMistakes: ['摆动借力', '腰部过度拱起'], week1: '3组×8个', week3: '3组×10个',
      week5: '3组×12个', week7: '3组×15个', type: MovementType.reps, restTime: '45秒',
    ),
  ];

  static const List<MovementConfig> _absLower = [
    MovementConfig(
      name: '仰卧举腿', targetMuscle: '下腹',
      description: '双腿伸直抬起至垂直，下放时脚不触地',
      commonMistakes: ['腿部弯曲', '腰部离地'], week1: '3组×12个', week3: '3组×15个',
      week5: '3组×18个', week7: '3组×20个', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: 'V字支撑', targetMuscle: '下腹',
      description: '仰卧同时抬起双腿和上半身，形成V字',
      commonMistakes: ['膝盖弯曲', '颈部用力'], week1: '3组×8个', week3: '3组×10个',
      week5: '3组×12个', week7: '3组×15个', type: MovementType.reps, restTime: '45秒',
    ),
    MovementConfig(
      name: '登山跑', targetMuscle: '下腹、核心',
      description: '俯卧撑姿势交替提膝，保持核心收紧',
      commonMistakes: ['臀部过高', '节奏过快'], week1: '3组×30秒', week3: '3组×40秒',
      week5: '3组×50秒', week7: '3组×60秒', type: MovementType.duration, restTime: '30秒',
    ),
  ];

  static const List<MovementConfig> _absRest = [
    MovementConfig(
      name: '猫牛式伸展', targetMuscle: '核心、脊柱',
      description: '四足跪姿，吸气塌腰抬头，呼气拱背低头',
      commonMistakes: ['动作过快', '呼吸不畅'], week1: '3组×10次', week3: '3组×12次',
      week5: '3组×15次', week7: '3组×15次', type: MovementType.reps, restTime: '15秒',
    ),
    MovementConfig(
      name: '婴儿式拉伸', targetMuscle: '背部、核心',
      description: '跪坐俯身，手臂前伸，感受背部伸展',
      commonMistakes: ['臀部后移', '呼吸憋住'], week1: '3组×30秒', week3: '3组×30秒',
      week5: '3组×45秒', week7: '3组×45秒', type: MovementType.duration, restTime: '15秒',
    ),
  ];

  static const List<MovementConfig> _advancedDay1 = [
    MovementConfig(
      name: '标准俯卧撑', targetMuscle: '胸、肩、三头肌',
      description: '身体成直线，下降至胸部接近地面',
      commonMistakes: ['塌腰', '撅臀'], week1: '4组×15个', week3: '4组×20个',
      week5: '4组×25个', week7: '4组×30个', type: MovementType.reps, restTime: '60秒',
    ),
    MovementConfig(
      name: '弓箭步', targetMuscle: '腿、臀',
      description: '前后腿均呈90度，膝盖不超过脚尖',
      commonMistakes: ['膝盖内扣', '身体前倾'], week1: '3组×12次/侧', week3: '3组×15次/侧',
      week5: '3组×18次/侧', week7: '3组×20次/侧', type: MovementType.reps, restTime: '45秒',
    ),
    MovementConfig(
      name: '波比跳', targetMuscle: '全身',
      description: '俯卧撑后跳起，全程保持快节奏',
      commonMistakes: ['腰部塌陷', '跳起过低'], week1: '3组×8个', week3: '3组×10个',
      week5: '3组×12个', week7: '3组×15个', type: MovementType.reps, restTime: '60秒',
    ),
  ];

  static const List<MovementConfig> _advancedDay2 = [
    MovementConfig(
      name: '深蹲跳', targetMuscle: '腿、臀、心肺',
      description: '深蹲后爆发跳起，落地缓冲',
      commonMistakes: ['膝盖内扣', '落地无声'], week1: '3组×10个', week3: '3组×12个',
      week5: '3组×15个', week7: '3组×18个', type: MovementType.reps, restTime: '60秒',
    ),
    MovementConfig(
      name: '钻石俯卧撑', targetMuscle: '三头肌、胸',
      description: '双手拇指食指组成菱形，降低难度',
      commonMistakes: ['肘部外展', '塌腰'], week1: '3组×8个', week3: '3组×10个',
      week5: '3组×12个', week7: '3组×15个', type: MovementType.reps, restTime: '60秒',
    ),
    MovementConfig(
      name: '侧支撑转体', targetMuscle: '腹斜肌、核心',
      description: '侧支撑姿势，上方手臂穿越躯干下方',
      commonMistakes: ['臀部下沉', '转动幅度过大'], week1: '3组×8次/侧', week3: '3组×10次/侧',
      week5: '3组×12次/侧', week7: '3组×15次/侧', type: MovementType.reps, restTime: '45秒',
    ),
  ];

  static const List<MovementConfig> _advancedDay3 = [
    MovementConfig(
      name: '平板支撑交替触肩', targetMuscle: '核心、肩',
      description: '平板支撑姿势，交替用手触碰对侧肩膀',
      commonMistakes: ['臀部扭动', '腰部塌陷'], week1: '3组×16次', week3: '3组×20次',
      week5: '3组×24次', week7: '3组×30次', type: MovementType.reps, restTime: '45秒',
    ),
    MovementConfig(
      name: '仰卧单车', targetMuscle: '腹斜肌、上腹',
      description: '仰卧交替肘触对侧膝盖，保持节奏',
      commonMistakes: ['头部用力', '速度过快'], week1: '3组×20次', week3: '3组×24次',
      week5: '3组×30次', week7: '3组×36次', type: MovementType.reps, restTime: '30秒',
    ),
    MovementConfig(
      name: '超级人', targetMuscle: '下背、核心',
      description: '俯卧同时抬起双臂双腿，保持2秒后放下',
      commonMistakes: ['颈部过度后仰', '憋气'], week1: '3组×10个', week3: '3组×12个',
      week5: '3组×15个', week7: '3组×18个', type: MovementType.reps, restTime: '45秒',
    ),
  ];
}
