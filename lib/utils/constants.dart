/// 应用常量配置
library;

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/models/daily_quote.dart';

// 学校类型枚举
enum SchoolType { commute, boarder }

// 训练类型
enum WorkoutType { strength, cardio, stretch, rest }

// 动作类型
enum MovementType { reps, duration }

// 强度等级
enum Intensity { easy, moderate, hard, exhausting }

// 每日任务配置
class TaskConfig {
  final String id;
  final String name;
  final String description;
  final String icon;

  const TaskConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

// 动作配置
class MovementConfig {
  final String name;
  final String targetMuscle;
  final String description;
  final List<String> commonMistakes;
  final String week1;
  final String week3;
  final String week5;
  final String week7;
  final MovementType type;
  final String restTime;

  const MovementConfig({
    required this.name,
    required this.targetMuscle,
    required this.description,
    required this.commonMistakes,
    required this.week1,
    required this.week3,
    required this.week5,
    required this.week7,
    required this.type,
    required this.restTime,
  });
}

// 食物配置
class FoodConfig {
  final String name;
  final String category;
  final String description;

  const FoodConfig({
    required this.name,
    required this.category,
    this.description = '',
  });
}

// 成就徽章
class BadgeConfig {
  final String id;
  final String name;
  final String icon;
  final String condition;

  const BadgeConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.condition,
  });
}

class AppConstants {
  AppConstants._();

  // 每日必做清单
  static const List<TaskConfig> dailyTasks = [
    TaskConfig(
      id: 'water_morning',
      name: '晨起温水',
      description: '起床后立即喝300ml温水',
      icon: '💧',
    ),
    TaskConfig(
      id: 'face_massage_morning',
      name: '早晨脸部按摩',
      description: '指关节从下巴沿下颌骨推到耳后',
      icon: '😊',
    ),
    TaskConfig(
      id: 'breakfast_healthy',
      name: '健康早餐',
      description: '1个鸡蛋 + 1杯牛奶/豆浆 + 主食',
      icon: '🍳',
    ),
    TaskConfig(
      id: 'lunch_controlled',
      name: '午餐控油',
      description: '一拳头米饭 + 一掌心蛋白质 + 两拳头蔬菜',
      icon: '🥗',
    ),
    TaskConfig(
      id: 'water_2l',
      name: '喝水2L',
      description: '全天累计喝2000ml水',
      icon: '🚰',
    ),
    TaskConfig(
      id: 'no_snacks',
      name: '不吃零食饮料',
      description: '禁止辣条、饼干、奶茶、可乐',
      icon: '🚫',
    ),
    TaskConfig(
      id: 'dinner_controlled',
      name: '晚餐控制',
      description: '七分饱，不吃夜宵',
      icon: '🌙',
    ),
    TaskConfig(
      id: 'workout_done',
      name: '运动完成',
      description: '完成今日训练计划',
      icon: '💪',
    ),
    TaskConfig(
      id: 'face_massage_night',
      name: '睡前脸部按摩',
      description: '睡前再次按摩下颌线',
      icon: '😴',
    ),
    TaskConfig(
      id: 'sleep_before_23',
      name: '23点前睡',
      description: '保证充足睡眠，促进恢复',
      icon: '🛏️',
    ),
  ];

  // 力量训练动作（周一、三、五）
  static const List<MovementConfig> strengthMovements = [
    MovementConfig(
      name: '标准俯卧撑',
      targetMuscle: '胸、肩、三头肌',
      description: '身体成直线，下降至胸部接近地面',
      commonMistakes: ['塌腰', '撅臀', '肘部外展过大'],
      week1: '3组×10个',
      week3: '3组×15个',
      week5: '3组×20个',
      week7: '3组×25个',
      type: MovementType.reps,
      restTime: '60秒',
    ),
    MovementConfig(
      name: '深蹲',
      targetMuscle: '腿、臀',
      description: '膝盖与脚尖方向一致，下蹲至大腿平行地面',
      commonMistakes: ['膝盖内扣', '弯腰', '脚跟贴起'],
      week1: '3组×20个',
      week3: '3组×25个',
      week5: '3组×30个',
      week7: '3组×35个',
      type: MovementType.reps,
      restTime: '45秒',
    ),
    MovementConfig(
      name: '平板支撑',
      targetMuscle: '核心',
      description: '不塌腰、不撅臀，保持自然呼吸',
      commonMistakes: ['塌腰', '撅臀', '憋气'],
      week1: '3组×40秒',
      week3: '3组×50秒',
      week5: '3组×60秒',
      week7: '3组×70秒',
      type: MovementType.duration,
      restTime: '45秒',
    ),
    MovementConfig(
      name: '卷腹',
      targetMuscle: '上腹',
      description: '腰部始终贴地，肩胛骨抬离地面即可',
      commonMistakes: ['抱头猛拉', '腰部离地', '速度过快'],
      week1: '3组×15个',
      week3: '3组×20个',
      week5: '3组×25个',
      week7: '3组×30个',
      type: MovementType.reps,
      restTime: '30秒',
    ),
    MovementConfig(
      name: '仰卧举腿',
      targetMuscle: '下腹',
      description: '双腿伸直抬起至垂直，下放时脚不触地',
      commonMistakes: ['腿部弯曲', '腰部离地', '借力'],
      week1: '3组×10个',
      week3: '3组×12个',
      week5: '3组×15个',
      week7: '3组×20个',
      type: MovementType.reps,
      restTime: '30秒',
    ),
    MovementConfig(
      name: '靠墙静蹲',
      targetMuscle: '大腿',
      description: '大腿与地面平行，膝盖不超过脚尖',
      commonMistakes: ['膝盖超过脚尖', '大腿不够水平', '身体下滑'],
      week1: '3组×40秒',
      week3: '3组×50秒',
      week5: '3组×60秒',
      week7: '3组×70秒',
      type: MovementType.duration,
      restTime: '45秒',
    ),
    MovementConfig(
      name: '提踵',
      targetMuscle: '小腿',
      description: '脚跟抬至最高，缓慢下放',
      commonMistakes: ['速度过快', '幅度不够', '身体摇晃'],
      week1: '3组×30个',
      week3: '3组×35个',
      week5: '3组×40个',
      week7: '3组×45个',
      type: MovementType.reps,
      restTime: '30秒',
    ),
  ];

  // 绿灯食物
  static const List<FoodConfig> greenLightFoods = [
    FoodConfig(name: '水煮蛋', category: '蛋白质'),
    FoodConfig(name: '鸡胸肉', category: '蛋白质'),
    FoodConfig(name: '鱼', category: '蛋白质'),
    FoodConfig(name: '豆腐', category: '蛋白质'),
    FoodConfig(name: '虾仁', category: '蛋白质'),
    FoodConfig(name: '鸡蛋清', category: '蛋白质'),
    FoodConfig(name: '绿叶菜', category: '蔬菜'),
    FoodConfig(name: '西兰花', category: '蔬菜'),
    FoodConfig(name: '黄瓜', category: '蔬菜'),
    FoodConfig(name: '番茄', category: '蔬菜'),
    FoodConfig(name: '玉米', category: '主食'),
    FoodConfig(name: '红薯', category: '主食'),
    FoodConfig(name: '燕麦', category: '主食'),
    FoodConfig(name: '全麦面包', category: '主食'),
    FoodConfig(name: '无糖酸奶', category: '饮品'),
    FoodConfig(name: '牛奶', category: '饮品'),
    FoodConfig(name: '无糖豆浆', category: '饮品'),
  ];

  // 红灯食物
  static const List<FoodConfig> redLightFoods = [
    FoodConfig(name: '奶茶', category: '饮品'),
    FoodConfig(name: '可乐', category: '饮品'),
    FoodConfig(name: '薯片', category: '零食'),
    FoodConfig(name: '辣条', category: '零食'),
    FoodConfig(name: '泡面', category: '快餐'),
    FoodConfig(name: '炸鸡', category: '快餐'),
    FoodConfig(name: '炒饭', category: '主食'),
    FoodConfig(name: '油条', category: '早餐'),
    FoodConfig(name: '煎饼', category: '早餐'),
    FoodConfig(name: '手抓饼', category: '早餐'),
    FoodConfig(name: '蛋糕', category: '甜点'),
    FoodConfig(name: '饼干', category: '零食'),
    FoodConfig(name: '巧克力', category: '甜点'),
    FoodConfig(name: '糖果', category: '零食'),
    FoodConfig(name: '炸薯条', category: '快餐'),
    FoodConfig(name: '汉堡', category: '快餐'),
  ];

  // 成就徽章
  static const List<BadgeConfig> badges = [
    BadgeConfig(
      id: 'novice_start',
      name: '新手起步',
      icon: '🌱',
      condition: '完成第一天全部打卡任务',
    ),
    BadgeConfig(
      id: 'streak_7',
      name: '连续7天',
      icon: '🔥',
      condition: '连续7天打卡完成率≥80%',
    ),
    BadgeConfig(
      id: 'streak_30',
      name: '连续30天',
      icon: '⚡',
      condition: '连续30天打卡完成率≥80%',
    ),
    BadgeConfig(
      id: 'streak_60',
      name: '坚持60天',
      icon: '🏆',
      condition: '完成整个60天计划',
    ),
    BadgeConfig(
      id: 'pushup_master',
      name: '俯卧撑达人',
      icon: '💪',
      condition: '单组标准俯卧撑达到25个',
    ),
    BadgeConfig(
      id: 'plank_breakthrough',
      name: '平板支撑突破',
      icon: '🧘',
      condition: '单次平板支撑达到60秒',
    ),
    BadgeConfig(
      id: 'squat_warrior',
      name: '深蹲勇士',
      icon: '🦵',
      condition: '单组深蹲达到35个',
    ),
    BadgeConfig(
      id: 'cardio_star',
      name: '有氧之星',
      icon: '🏃',
      condition: '一周内完成3次有氧训练',
    ),
    BadgeConfig(
      id: 'early_bird',
      name: '早起鸟儿',
      icon: '🐦',
      condition: '连续7天在7:00前起床',
    ),
    BadgeConfig(
      id: 'sleep_expert',
      name: '睡眠达人',
      icon: '😴',
      condition: '连续7天在23:00前入睡',
    ),
    BadgeConfig(
      id: 'diet_discipline',
      name: '饮食自律',
      icon: '🥗',
      condition: '连续7天不吃零食饮料',
    ),
    BadgeConfig(
      id: 'metamorphosis_complete',
      name: '养成完成',
      icon: '🦋',
      condition: '60天后体重下降或腰围减少≥2cm',
    ),
  ];

  // 每周综合评分公式系数
  static const double checkInWeight = 0.5;
  static const double workoutWeight = 0.3;
  static const double dietWeight = 0.2;
}