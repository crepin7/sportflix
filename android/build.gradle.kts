allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force Start.io 5.3.1 (dernière compatible compileSdk 36)
allprojects {
    configurations.all {
        resolutionStrategy {
            force("com.startapp:inapp-sdk:5.3.1")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
