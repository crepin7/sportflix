import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crepin.sportflix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    configurations.all {
        resolutionStrategy {
            force("androidx.appcompat:appcompat:1.7.0")
        }
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

// One-shot fix: AAPT2 9.x refuse #6680cbc4 (8-digit ARGB) d'appcompat
// On patch le cache Gradle et le merged dir avant compilation
tasks.matching { it.name.contains("merge") && it.name.contains("Resources") }.configureEach {
    doFirst {
        val home = System.getProperty("user.home")
        val cache = File("$home/.gradle/caches")
        if (cache.exists()) {
            cache.walkTopDown().forEach { f ->
                if (f.isFile && f.name == "values.xml" && f.path.contains("appcompat")) {
                    val txt = f.readText()
                    if (txt.contains("#6680cbc4")) {
                        f.writeText(txt.replace("#6680cbc4", "#80000000"))
                        println("Patched appcompat color in ${f.path}")
                    }
                }
            }
        }
        // aussi le dossier merged s'il existe déjà
        val mergedDir = File("${project.layout.buildDirectory.get().asFile.path}/intermediates")
        if (mergedDir.exists()) {
            mergedDir.walkTopDown().forEach { f ->
                if (f.isFile && f.name == "values.xml") {
                    val txt = f.readText()
                    if (txt.contains("#6680cbc4")) {
                        f.writeText(txt.replace("#6680cbc4", "#80000000"))
                        println("Patched merged values.xml ${f.path}")
                    }
                }
            }
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
