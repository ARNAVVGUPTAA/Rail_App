plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.railapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Use Java 21 for now, will auto-update when VERSION_24 becomes available
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        // For Java 24 when available: JavaVersion.VERSION_24
    }

    kotlinOptions {
        // Use Java 21 target for now, will auto-update when VERSION_24 becomes available  
        jvmTarget = JavaVersion.VERSION_21.toString()
        // For Java 24 when available: JavaVersion.VERSION_24.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.railapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
    checkReleaseBuilds = false
    abortOnError = false
    // Don't fail the app build for dependency lint
    checkDependencies = false
    // Disable specific noisy checks seen in dependencies
    disable += setOf("InvalidPackage", "MissingPermission")
    }
}

flutter {
    source = "../.."
}
