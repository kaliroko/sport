pluginManagement {
    // 优先从环境变量读取 Flutter SDK 路径（CI 环境使用）
    val flutterSdkPath = run {
        val envFlutterSdk = System.getenv("FLUTTER_ROOT")
        if (envFlutterSdk != null) {
            envFlutterSdk
        } else {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val localFlutterSdk = properties.getProperty("flutter.sdk")
            check(localFlutterSdk != null) { "Flutter SDK not found. Set FLUTTER_ROOT env or define flutter.sdk in local.properties." }
            localFlutterSdk
        }
    }

    plugins {
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
}

include(":app")