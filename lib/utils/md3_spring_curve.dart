/// Material Design 3 物理弹簧曲线
/// 基于二阶阻尼弹簧振子方程求解，提供真实的物理弹性回弹效果
///
/// MD3 Spring 参数（参考 Material Design 3 规范）：
/// - 刚度 (stiffness): 约 180 N/m
/// - 阻尼 (damping):   约 10 N·s/m
/// - 质量 (mass):      1.0 kg
///
/// 运动方程: x''(t) = -(damping * x'(t) + stiffness * (x(t) - target)) / mass
library;

import 'dart:math';

/// MD3 物理弹簧曲线实现
/// 模拟真实弹簧的过冲（overshoot）+ 衰减振荡行为
class Md3SpringCurve extends Curve {
  /// 弹簧刚度系数（模拟值，单位：N/m 相对比例）
  final double stiffness;

  /// 阻尼系数（模拟值，单位：N·s/m 相对比例）
  final double damping;

  /// 弹簧质量（模拟值，单位：kg）
  final double mass;

  const Md3SpringCurve({
    this.stiffness = 180.0,
    this.damping = 10.0,
    this.mass = 1.0,
  });

  @override
  double transform(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;

    // 欠阻尼弹簧系统的解析解
    // x(t) = 1 - e^(-ζωt) * cos(ωd*t)
    // 其中 ζ = damping/(2*sqrt(stiffness*mass))  阻尼比
    //       ω = sqrt(stiffness/mass)             固有角频率
    //       ωd = ω*sqrt(1-ζ²)                     阻尼角频率

    final omega = sqrt(stiffness / mass);
    final zeta = damping / (2.0 * sqrt(stiffness * mass));

    if (zeta >= 1.0) {
      // 过阻尼或临界阻尼，无振荡，直接指数衰减
      return 1.0 - exp(-omega * t);
    } else if (zeta < 0.0) {
      // 负阻尼（不稳定），退化为线性
      return t.clamp(0.0, 1.0);
    }

    final omegaD = omega * sqrt(1.0 - zeta * zeta);
    final decay = zeta * omega;

    // 欠阻尼弹簧响应：e^(-decay*t) * (cos(ωd*t) + (decay/ωd)*sin(ωd*t))
    final oscillation = exp(-decay * t) *
        (cos(omegaD * t) + (decay / omegaD) * sin(omegaD * t));

    // 从目标值 1.0 衰减到终值
    return 1.0 - oscillation;
  }
}

/// 轻量弹簧曲线（低阻尼，明显过冲，适合点击反馈）
/// 对应 MD3 Tonal Button press 弹簧效果
class Md3LightSpring extends Md3SpringCurve {
  const Md3LightSpring()
      : super(stiffness: 250.0, damping: 8.0, mass: 0.8);
}

/// 标准弹簧曲线（适中阻尼，轻微过冲，适合页面转场）
/// 对应 MD3 Standard Easing 的弹簧近似
class Md3StandardSpring extends Md3SpringCurve {
  const Md3StandardSpring()
      : super(stiffness: 180.0, damping: 10.0, mass: 1.0);
}

/// 重弹簧曲线（高阻尼，较少过冲，适合大型组件动画）
/// 对应 MD3 Large Component 弹簧效果
class Md3HeavySpring extends Md3SpringCurve {
  const Md3HeavySpring()
      : super(stiffness: 120.0, damping: 12.0, mass: 1.5);
}
