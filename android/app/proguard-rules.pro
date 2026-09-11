# ==================== Flutter 核心保留规则 ====================
# Flutter 引擎相关类必须保留，否则 App 崩溃
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# 我们的自定义 Application 类
-keep class com.metamorphosis.checkin.FlutterApp { *; }

# MainActivity 必须保留
-keep class com.metamorphosis.checkin.MainActivity { *; }

# ==================== Provider / ChangeNotifier 保留 ====================
-keepclassmembers class * extends ChangeNotifier {
    public *;
}
-keep class * implements ChangeNotifier { *; }

# ==================== SQLite / Drift 数据库保留 ====================
-keep class com.metamorphosis.checkin.database.** { *; }
-keep class com.metamorphosis.checkin.models.** { *; }

# ==================== JSON 序列化保留（model 字段不能混淆） ====================
-keep class com.metamorphosis.checkin.models.** { *; }
-keepclassmembers class com.metamorphosis.checkin.models.** {
    <fields>;
}

# ==================== 反射/注入保留 ====================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn kotlinx.coroutines.**

# ==================== 第三方库 ====================
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }
-keep class com.squareup.okhttp3.** { *; }

# ==================== 泛型信息保留（运行时反射用到） ====================
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes *Annotation*, SourceFile, LineNumberTable

# ==================== R8 混淆忽略规则 ====================
# 以下缺失类来自 Google Play Core，项目不使用 Split Install 功能，直接忽略
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
# Flutter DeferredComponents 在 Release 构建中不会触发，忽略相关警告
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
# 允许 R8 处理缺失类（不将其视为错误）
-dontnote com.google.android.play.core.splitinstall.**
