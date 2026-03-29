plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") version "2.1.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.respos"
    compileSdk = 36  // Updated to support flutter_tts which requires SDK 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.respos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // Updated to support flutter_tts which requires minSdk 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }
    }
    
    packaging {
        resources {
            excludes += "/META-INF/**"
            excludes += "META-INF/**" 
            excludes += "**/LICENSE"
            excludes += "**/NOTICE"
            excludes += "**/DEPENDENCIES"
            excludes += "**/*.kotlin_module"
            excludes += "**/module-info.class"
        }
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.8.0")
        force("androidx.activity:activity-ktx:1.8.0")
    }
}

