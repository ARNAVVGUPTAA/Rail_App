allprojects {
    repositories {
        google()
        mavenCentral()
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

// Disable only geolocator_android lint tasks (they cause false positives for POST_NOTIFICATIONS)
subprojects {
    if (name == "geolocator_android") {
        tasks.configureEach {
            if (name.startsWith("lint")) {
                enabled = false
            }
        }
    }
}

// Keep app tests, disable unit tests in other Android plugin subprojects to avoid flaky plugin tests
subprojects {
    if (name != "app") {
        tasks.withType<Test>().configureEach {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
