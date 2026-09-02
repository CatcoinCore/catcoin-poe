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
    val projectPath = project.projectDir.absolutePath
    val rootPath = rootProject.projectDir.absolutePath
    val isDifferentDrive = projectPath.length > 2 && rootPath.length > 2 && !projectPath.substring(0, 2).equals(rootPath.substring(0, 2), ignoreCase = true)
    
    if (isDifferentDrive) {
        val driveConfigBuildDir = java.io.File(System.getProperty("java.io.tmpdir"), "flutter_catcoin_build_tmp/" + project.name)
        project.layout.buildDirectory.set(driveConfigBuildDir)
    } else {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidExt = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        if (androidExt.namespace == null) {
            androidExt.namespace = project.group.toString()
        }
    }
}
