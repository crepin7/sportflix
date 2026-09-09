plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crepin.sportflix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Exclut appcompat qui contient #6680cbc4 invalide pour AAPT2 9.1
    // media_kit / webview n'en ont pas besoin au runtime pour le HLS
    configurations.all {
        exclude(group = "androidx.appcompat", module = "appcompat")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.crepin.sportflix"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
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
