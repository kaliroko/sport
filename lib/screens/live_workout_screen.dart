/// 实时监督训练页
///
/// 核心规则：**打卡必须等计时跑完才算数**。
/// 每个动作的每一组都会跑一个计时窗口，计时结束才写入 workout_logs；
/// 中途「跳过本组」不会写日志，因此不计入打卡。
///
/// 其它行为：
///   · 按顺序逐个动作、逐组推进，不用自己记住做到哪了
///   · 计时型动作用目标秒数（平板支撑 40 秒）；次数型按每次约 3 秒折算窗口
///   · 每组完成自动进入组间休息，休息结束自动开始下一组
///   · 全程语音播报，做平板支撑时不用抬头看屏幕
///   · 重新进入时从「没做完的那一组」继续 —— 进度由数据库派生
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/models/workout_log.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/services/tts_service.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/workout_plan_service.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/utils/workout_target.dart';
import 'package:metamorphosis_checkin/widgets/app_background.dart';
import 'package:provider/provider.dart';

enum _Phase { working, resting, finished }

class LiveWorkoutScreen extends StatefulWidget {
  final List<MovementConfig> movements;

  /// 指定从第几个动作开始。为 null 时从「第一个还没做满的动作」继续。
  /// 训练页点击某张卡片进来时就会传这个值。
  final int? initialIndex;

  const LiveWorkoutScreen({
    super.key,
    required this.movements,
    this.initialIndex,
  });

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  int _exerciseIndex = 0;
  int _setIndex = 1;
  _Phase _phase = _Phase.working;
  int _remaining = 0;
  Timer? _timer;
  bool _started = false;

  int get _week => context.read<UserProfileService>().profile?.currentWeek ?? 1;

  MovementConfig get _movement => widget.movements[_exerciseIndex];
  SetTarget get _target =>
      parseSetTarget(_movement, weekConfigFor(_movement, _week));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WorkoutService>().init().then((_) {
        if (!mounted) return;
        _resumeFromProgress();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  /// 恢复进度：优先用调用方指定的动作，否则找第一个还没做满的动作
  void _resumeFromProgress() {
    final workoutService = context.read<WorkoutService>();

    final int? startAt = widget.initialIndex;
    if (startAt != null && startAt >= 0 && startAt < widget.movements.length) {
      final m = widget.movements[startAt];
      final target = parseSetTarget(m, weekConfigFor(m, _week));
      final done = workoutService.completedSetsFor(m.name);
      if (done < target.sets) {
        setState(() {
          _exerciseIndex = startAt;
          _setIndex = done + 1;
        });
        _beginWorking();
        return;
      }
    }

    for (var i = 0; i < widget.movements.length; i++) {
      final m = widget.movements[i];
      final target = parseSetTarget(m, weekConfigFor(m, _week));
      final done = workoutService.completedSetsFor(m.name);
      if (done < target.sets) {
        setState(() {
          _exerciseIndex = i;
          _setIndex = done + 1;
        });
        _beginWorking();
        return;
      }
    }
    setState(() => _phase = _Phase.finished);
  }

  // ─── 流程控制 ──────────────────────────────────────────────────────────────

  void _beginWorking() {
    _timer?.cancel();
    final target = _target;
    final seconds = target.perSetSeconds;

    setState(() {
      _phase = _Phase.working;
      _started = true;
      _remaining = seconds;
    });

    final dose = target.isDuration ? '保持 ${target.seconds} 秒' : '${target.reps} 个';
    TtsService.instance.speak('${_movement.name}，第 $_setIndex 组，$dose，开始');

    // 打卡只在计时跑完之后发生
    _startTimer(
      seconds: seconds,
      onDone: _completeSet,
      announceLastThree: true,
    );
  }

  void _beginRest() {
    _timer?.cancel();
    final rest = _target.restSeconds;
    setState(() {
      _phase = _Phase.resting;
      _remaining = rest;
    });
    TtsService.instance.speak('休息 $rest 秒');
    _startTimer(
      seconds: rest,
      onDone: () {
        if (!mounted) return;
        setState(() => _setIndex++);
        _beginWorking();
      },
      announceLastThree: true,
    );
  }

  void _startTimer({
    required int seconds,
    required VoidCallback onDone,
    bool announceLastThree = false,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
        onDone();
        return;
      }
      setState(() => _remaining--);
      if (announceLastThree && _remaining <= 3) {
        TtsService.instance.speak('$_remaining');
      }
    });
  }

  /// 计时结束 → 写入日志 = 完成打卡
  Future<void> _completeSet() async {
    _timer?.cancel();
    final workoutService = context.read<WorkoutService>();
    final target = _target;
    final movement = _movement;
    final now = DateTime.now();

    await workoutService.addLog(WorkoutLog(
      date: now.toIso8601String().split('T').first,
      workoutType: context.read<WorkoutPlanService>().getTodayWorkoutType(),
      exerciseName: movement.name,
      sets: 1,
      reps: target.reps,
      durationSeconds: target.seconds,
      note: '计时完成',
      createdAt: now,
    ));
    if (!mounted) return;

    final done = workoutService.completedSetsFor(movement.name);
    TtsService.instance.speak('${movement.name}，第 $done 组完成，已打卡');

    if (done >= target.sets) {
      _advanceExercise();
    } else {
      _beginRest();
    }
  }

  /// 提前结束 / 跳过本组：**不写日志，因此不计入打卡**，直接进入下一个动作
  void _skipCurrentSet() {
    _timer?.cancel();
    TtsService.instance.speak('本组已跳过，不计入打卡');
    _advanceExercise();
  }

  void _advanceExercise() {
    _timer?.cancel();
    final workoutService = context.read<WorkoutService>();
    for (var i = _exerciseIndex + 1; i < widget.movements.length; i++) {
      final m = widget.movements[i];
      final target = parseSetTarget(m, weekConfigFor(m, _week));
      if (workoutService.completedSetsFor(m.name) < target.sets) {
        setState(() {
          _exerciseIndex = i;
          _setIndex = workoutService.completedSetsFor(m.name) + 1;
        });
        _beginWorking();
        return;
      }
    }
    _finish();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _phase = _Phase.finished);
    TtsService.instance.speak('恭喜，今日训练全部完成');
    await context.read<CheckInService>().markWorkoutDone(true);
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() => _setIndex++);
    _beginWorking();
  }

  void _addRestTime() {
    setState(() => _remaining += 15);
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workoutService = context.watch<WorkoutService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('实时训练',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: !_started && _phase != _Phase.finished
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _phase == _Phase.finished
                  ? _buildFinished(context)
                  : _buildSession(context, workoutService),
        ),
      ],
    );
  }

  Widget _buildFinished(BuildContext context) {
    final workoutService = context.watch<WorkoutService>();
    final totalSets = workoutService.todaySetCount;
    final allDone = widget.movements.every((m) {
      final target = parseSetTarget(m, weekConfigFor(m, _week));
      return workoutService.completedSetsFor(m.name) >= target.sets;
    });

    return ListView(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
      children: [
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 40)),
        Center(child: Text(allDone ? '🎉' : '🕐', style: TextStyle(fontSize: ResponsiveUtils.scaleFont(context, 64)))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
        Center(child: Text(allDone ? '今日训练完成！' : '本次训练已结束',
            style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 24), fontWeight: FontWeight.bold))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
        Center(child: Text(
          allDone ? '已自动同步到首页「运动完成」打卡 ✅' : '还有动作没做满，可以再进来继续',
          textAlign: TextAlign.center,
          style: TextStyle(color: allDone ? AppTheme.successColor : AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13)),
        )),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 24)),
        GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
          child: Column(children: [
            Text('本次共完成 $totalSets 组',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
            ...widget.movements.map((m) {
              final target = parseSetTarget(m, weekConfigFor(m, _week));
              final done = workoutService.completedSetsFor(m.name);
              final ok = done >= target.sets;
              return Padding(
                padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 6)),
                child: Row(children: [
                  Icon(ok ? Icons.check_circle : Icons.remove_circle_outline,
                      color: ok ? AppTheme.successColor : AppTheme.textHint,
                      size: ResponsiveUtils.scaleIcon(context, 16)),
                  SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
                  Expanded(child: Text(m.name, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13)))),
                  Text('$done / ${target.sets} 组',
                      style: TextStyle(color: ok ? AppTheme.successColor : AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 12))),
                ]),
              );
            }),
          ]),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),
        GlassButton.custom(
          onTap: () => Navigator.of(context).pop(),
          width: double.infinity,
          height: ResponsiveUtils.scaleButtonHeight(context, 48),
          child: const Text('返回', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildSession(BuildContext context, WorkoutService workoutService) {
    final movement = _movement;
    final target = _target;
    final bool isResting = _phase == _Phase.resting;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scalePadding(context, 20),
        0,
        ResponsiveUtils.scalePadding(context, 20),
        ResponsiveUtils.bottomSafePadding(context),
      ),
      children: [
        Text('第 ${_exerciseIndex + 1} / ${widget.movements.length} 个动作',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
        Row(children: widget.movements.asMap().entries.map((e) {
          final t = parseSetTarget(e.value, weekConfigFor(e.value, _week));
          final done = workoutService.completedSetsFor(e.value.name);
          final finished = done >= t.sets;
          final current = e.key == _exerciseIndex;
          return Expanded(child: Container(
            margin: EdgeInsets.only(right: ResponsiveUtils.scaleSpacing(context, 4)),
            height: ResponsiveUtils.scaleSize(context, 6),
            decoration: BoxDecoration(
              color: finished
                  ? AppTheme.successColor
                  : (current ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(3),
            ),
          ));
        }).toList()),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

        GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
          child: Column(children: [
            Text(isResting ? '组间休息' : movement.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 22), fontWeight: FontWeight.bold)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 4)),
            Text(
              isResting
                  ? '下一个：${movement.name} 第 ${_setIndex + 1} 组'
                  : (target.isDuration ? '保持 ${target.seconds} 秒' : '完成 ${target.reps} 个'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13)),
            ),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

            Container(
              width: ResponsiveUtils.scaleSize(context, 170),
              height: ResponsiveUtils.scaleSize(context, 170),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isResting ? AppTheme.infoColor : AppTheme.primaryColor).withValues(alpha: 0.15),
                border: Border.all(color: isResting ? AppTheme.infoColor : AppTheme.primaryColor, width: 3),
              ),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$_remaining',
                    style: TextStyle(
                      color: isResting ? AppTheme.infoColor : AppTheme.primaryColor,
                      fontSize: ResponsiveUtils.scaleFont(context, 52),
                      fontWeight: FontWeight.bold,
                    )),
                Text(isResting ? '秒后开始' : '秒',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
              ])),
            ),

            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),
            Text('第 $_setIndex 组 / 共 ${target.sets} 组',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.w600)),

            if (!isResting) ...[
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
              Text('计时结束后自动完成打卡',
                  style: TextStyle(color: AppTheme.successColor, fontSize: ResponsiveUtils.scaleFont(context, 11))),
            ],
          ]),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

        // 操作区
        if (isResting)
          Row(children: [
            Expanded(child: GlassButton.custom(
              onTap: _skipRest,
              height: ResponsiveUtils.scaleButtonHeight(context, 48),
              child: const Text('跳过休息', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            )),
            SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
            Expanded(child: GlassButton.custom(
              onTap: _addRestTime,
              height: ResponsiveUtils.scaleButtonHeight(context, 48),
              child: const Text('+15 秒', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            )),
          ])
        else ...[
          // 计时进行中：不能手动打卡，避免"点一下就算完成"
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.scalePadding(context, 16)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Text('训练中…', style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 2)),
              Text('剩余 $_remaining 秒，结束后自动打卡',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
            ]),
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
          Center(child: TextButton(
            onPressed: _skipCurrentSet,
            child: Text('跳过本组（不计入打卡）',
                style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 12))),
          )),
        ],

        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
        GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('要领：${movement.description}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
            if (movement.commonMistakes.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
              Wrap(spacing: 6, runSpacing: 4, children: movement.commonMistakes.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('✗ $m', style: TextStyle(color: AppTheme.errorColor, fontSize: ResponsiveUtils.scaleFont(context, 10))),
              )).toList()),
            ],
          ]),
        ),
      ],
    );
  }
}
