# ==================== Flutter 核心保留规则 ====================
# Flutter 引擎相关类必须保留，否则 App 崩溃
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

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