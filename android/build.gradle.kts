allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val externalBuildDir = providers.environmentVariable("DAPHNEX_BUILD_DIR").orNull
val newBuildDir: Directory =
    if (externalBuildDir.isNullOrBlank()) {
        rootProject.layout.buildDirectory.dir("../../build").get()
    } else {
        rootProject.layout.dir(providers.provider { file(externalBuildDir) }).get()
    }
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
