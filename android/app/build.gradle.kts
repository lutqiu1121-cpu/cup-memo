plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Deliberately below `flutter.minSdkVersion` (24): the project targets API 23.
val cupMemoMinSdk = 23

android {
    namespace = "com.cupmemo.app"
    // Pinned explicitly: this machine only has the android-37 platform and
    // build-tools 37.0.0 installed.
    compileSdk = 37
    // Pinned to the Flutter default so that the Flutter Gradle plugin does not
    // have to inject its "download the NDK" CMake stub (which requires an
    // x86_64 cmake binary that does not exist on an arm64 build host).
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cupmemo.app"
        // API 23 (Android 6.0) as required by the brief. Written through a
        // constant because Flutter's `MinSdkVersionMigration` rewrites any
        // literal `minSdk = <17..23>` back to `flutter.minSdkVersion` (24).
        // `flutter_secure_storage` is pinned to 10.x for the same reason:
        // 11.x declares minSdk 24 and would raise the merged value.
        minSdk = cupMemoMinSdk
        targetSdk = 37
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO(release): add a real signing config before publishing.
            // Signing with the debug keys for now, so `flutter build apk --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
