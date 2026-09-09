import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crepin.sportflix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

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

// Patch tous les values.xml contenant #6680cbc4 avant AAPT2
tasks.matching { it.name.contains("merge") && it.name.contains("Resources") }.configureEach {
    doFirst {
        val home = System.getProperty("user.home")
        val cache = File("$home/.gradle/caches")
        if (cache.exists()) {
            cache.walkTopDown().forEach { f ->
                if (f.isFile && f.name == "values.xml") {
                    val txt = f.readText()
                    if (txt.contains("#6680cbc4") || txt.contains("#6680CBC4")) {
                        f.writeText(txt.replace("#6680cbc4", "#80000000").replace("#6680CBC4", "#80000000"))
                        println("Patched ${f.path}")
                    }
                }
            }
        }
        val mergedBase = File("${project.layout.buildDirectory.get().asFile.path}/intermediates")
        if (mergedBase.exists()) {
            mergedBase.walkTopDown().forEach { f ->
                if (f.isFile && f.name == "values.xml") {
                    val txt = f.readText()
                    if (txt.contains("#6680cbc4") || txt.contains("#6680CBC4")) {
                        f.writeText(txt.replace("#6680cbc4", "#80000000").replace("#6680CBC4", "#80000000"))
                        println("Patched merged ${f.path}")
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
