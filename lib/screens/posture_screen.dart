/// 体态矫正页
///
/// 补上一个明显的断裂：通知里早就有「体态提醒：抬头挺胸，手机举高！」，
/// 但 App 里从来没有任何体态相关的训练内容。青少年圆肩、驼背、头前伸
/// 是这个产品定位里的核心场景之一。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/widgets/app_background.dart';

class _PostureMove {
  final String name;
  final String focus;
  final String howTo;
  final String dose;
  final int seconds; // > 0 为计时型，0 为次数型

  const _PostureMove({
    required this.name,
    required this.focus,
    required this.howTo,
    required this.dose,
    this.seconds = 0,
  });
}

class _PostureRoutine {
  final String title;
  final String subtitle;
  final IconData emoji;
  final List<_PostureMove> moves;
  const _PostureRoutine({required this.title, required this.subtitle, required this.emoji, required this.moves});
}

const List<_PostureRoutine> _routines = [
  _PostureRoutine(
    title: '课间 5 分钟',
    subtitle: '久坐之后立刻做，缓解圆肩与含胸',
    emoji: Icons.accessibility_new,
    moves: [
      _PostureMove(
        name: '胸椎伸展',
        focus: '打开胸腔 / 改善含胸',
        howTo: '坐直，双手抱头，手肘向两侧张开，吸气时胸口向上顶、上背轻轻后仰，呼气还原。不要用腰去代偿。',
        dose: '10 次',
      ),
      _PostureMove(
        name: '门框扩胸',
        focus: '胸小肌 / 肩前侧',
        howTo: '站在门框中间，前臂贴住门框与肩同高，身体缓慢前倾直到胸前有拉伸感，保持均匀呼吸。',
        dose: '30 秒 × 2',
        seconds: 30,
      ),
      _PostureMove(
        name: '收下巴（Chin Tuck）',
        focus: '头前伸 / 颈深屈肌',
        howTo: '坐直，下巴水平向后收（像做出双下巴），感受后颈拉长，保持 3 秒后放松。注意是「平移」不是低头。',
        dose: '12 次',
      ),
      _PostureMove(
        name: '墙壁天使',
        focus: '肩胛稳定性',
        howTo: '背靠墙，后脑、上背、臀贴墙，手臂贴墙做「举手投降」的上下滑动，全程手肘和手腕不离墙。',
        dose: '10 次',
      ),
    ],
  ),
  _PostureRoutine(
    title: '睡前 8 分钟',
    subtitle: '放松肩颈，改善含胸与颈部紧张',
    emoji: Icons.bedtime_outlined,
    moves: [
      _PostureMove(
        name: '猫牛式',
        focus: '脊柱灵活性',
        howTo: '四足跪姿，吸气塌腰抬头，呼气拱背低头，动作跟着呼吸走，不要抢速度。',
        dose: '10 次',
      ),
      _PostureMove(
        name: '婴儿式',
        focus: '背部 / 肩部放松',
        howTo: '跪坐，臀部坐向脚跟，手臂向前伸展贴地，额头放松，感受背部被拉开。',
        dose: '45 秒',
        seconds: 45,
      ),
      _PostureMove(
        name: '仰卧胸椎放松',
        focus: '上背僵硬',
        howTo: '仰卧，把卷起的毛巾垫在肩胛骨下方，双手抱头，缓慢呼吸让胸口自然打开。',
        dose: '60 秒',
        seconds: 60,
      ),
      _PostureMove(
        name: '颈部侧向拉伸',
        focus: '斜方肌上束',
        howTo: '坐直，右手轻扶头侧向左倒，左肩主动下沉，保持 20 秒后换边。力度要轻，不要猛拉。',
        dose: '20 秒 / 侧',
        seconds: 20,
      ),
    ],
  ),
];

class PostureScreen extends StatefulWidget {
  const PostureScreen({super.key});

  @override
  State<PostureScreen> createState() => _PostureScreenState();
}

class _PostureScreenState extends State<PostureScreen> {
  _PostureMove? _activeMove;
  int _remaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(_PostureMove move) {
    _timer?.cancel();
    setState(() {
      _activeMove = move;
      _remaining = move.seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _activeMove = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${move.name} 完成'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _activeMove = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('体态矫正', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.scalePadding(context, 16),
              0,
              ResponsiveUtils.scalePadding(context, 16),
              ResponsiveUtils.bottomSafePadding(context),
            ),
            children: [
              // 倒计时浮层（贴顶显示，不遮挡操作）
              if (_activeMove != null) ...[
                GlassCard(
                  padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
                  child: Row(children: [
                    const Icon(Icons.timer, color: AppTheme.warningColor),
                    SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_activeMove!.name, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 13))),
                      Text('$_remaining 秒', style: TextStyle(color: AppTheme.warningColor, fontSize: ResponsiveUtils.scaleFont(context, 22), fontWeight: FontWeight.bold)),
                    ])),
                    GlassButton.custom(
                      onTap: _stopTimer,
                      height: ResponsiveUtils.scaleButtonHeight(context, 40),
                      child: const Text('停止', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
              ],

              // 说明
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.accessibility_new, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 22)),
                    SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
                    Expanded(child: Text('为什么练体态', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 15), fontWeight: FontWeight.bold))),
                  ]),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  Text(
                    '长时间低头看手机、伏案写作业，会让胸肌变紧、上背变弱，'
                    '逐渐形成圆肩、驼背和头前伸。\n'
                    '体态矫正不需要大重量，关键是「每天做一点 + 日常保持」。',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12), height: 1.5),
                  ),
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              ..._routines.map((routine) => Padding(
                padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 16)),
                child: _RoutineCard(
                  routine: routine,
                  onStartTimed: _startTimer,
                ),
              )),

              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('日常保持小贴士', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  ...[
                    '手机举高到与视线齐平，不要低头刷',
                    '每坐 45 分钟起身活动 1 分钟',
                    '背包尽量双肩背，避免单侧受力',
                    '睡觉枕头不要过高，仰卧时颈部保持中立',
                  ].map((tip) => Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 4)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('· ', style: TextStyle(color: AppTheme.primaryColor)),
                      Expanded(child: Text(tip, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12), height: 1.4))),
                    ]),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final _PostureRoutine routine;
  final void Function(_PostureMove) onStartTimed;

  const _RoutineCard({required this.routine, required this.onStartTimed});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(routine.emoji, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 20)),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(routine.title, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 15), fontWeight: FontWeight.bold)),
            Text(routine.subtitle, style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
          ])),
        ]),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
        ...routine.moves.map((move) => Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(move.name, style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(move.dose, style: TextStyle(color: AppTheme.secondaryColor, fontSize: ResponsiveUtils.scaleFont(context, 10))),
              ),
            ]),
            const SizedBox(height: 2),
            Text(move.focus, style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 10))),
            const SizedBox(height: 4),
            Text(move.howTo, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12), height: 1.4)),
            if (move.seconds > 0) ...[
              const SizedBox(height: 6),
              GlassButton.custom(
                onTap: () => onStartTimed(move),
                height: ResponsiveUtils.scaleButtonHeight(context, 36),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.timer, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('开始计时', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        )),
      ]),
    );
  }
}
