package com.metamorphosis.checkin

import io.flutter.embedding.android.FlutterApplication

/**
 * 自定义 Application 类。
 * 继承 FlutterApplication 以提供 Flutter 引擎初始化所需的基础能力。
 *
 * 注意：不能在 Manifest 中直接使用 io.flutter.embedding.android.FlutterApplication，
 * 因为 R8 在 --obfuscate 模式下会将未被代码直接引用的 Flutter 框架类从 dex 中剔除，
 * 导致 ClassNotFoundException。本类通过 Java/Kotlin 引用 FlutterApplication，
 * 确保 R8 保留该类及其依赖。
 */
class FlutterApp : FlutterApplication()
