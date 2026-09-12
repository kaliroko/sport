plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// ─── 自定义签名（强制）───────────────────────────────────────────────────────
// release 构建**必须**使用自定义密钥：不再回退到 debug 签名。
// debug 签名无法上架，也无法覆盖安装已发布版本，属于隐患，因此直接去掉。
//
// 密钥信息从 android/key.properties 读取（已加入 .gitignore）；
// CI 上由 GitHub Actions 从 Secrets 生成该文件。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use { reader ->
        keystoreProperties.load(reader)
    }
}

// 只在真的要出 release 包时校验，避免影响日常 debug 运行/热重载。
// 缺密钥就直接报错并给出修复指引，而不是悄悄用 debug 签名蒙混过去。
val isReleaseRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (isReleaseRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        """
        |──────────────────────────────────────────────────────────────
        |缺少 android/key.properties，release 构建必须使用自定义签名。
        |
        |请照 android/key.properties.example 创建该文件，内容形如：
        |    storePassword=你的密码
        |    keyPassword=你的密码
        |    keyAlias=upload
        |    storeFile=app/keystore.jks
        |
        |生成新密钥：
        |    keytool -genkeypair -v -keystore android/app/keystore.jks \
        |      -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
        |      -alias upload -storepass 你的密码 -keypass 你的密码 \
        |      -dname "CN=你的名字"
        |──────────────────────────────────────────────────────────────
        """.trimMargin()
    )
}

android {
    namespace = "com.metamorphosis.checkin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.metamorphosis.checkin"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            // 注意：这一段在**配置阶段**就会执行，对缺文件必须保持宽容 ——
            // 用 `keystoreProperties["keyAlias"] as String` 会在文件不存在时
            // 因 null 强转抛异常，连 debug 构建和热重载都会被拖垮。
            // 因此这里用 getProperty + 空串兜底；release 构建的强制校验
            // 已在上面的 isReleaseRequested 检查里完成，缺密钥会在那一步
            // 给出明确报错，不会悄悄退化成 debug 签名。
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            keystoreProperties.getProperty("storeFile")?.let { storeFile = file(it) }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // 强制使用自定义签名，不回退 debug
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:${rootProject.extra["kotlinVersion"]}")
}
