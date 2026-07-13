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

// webview_flutter_android(카카오맵 플러그인이 의존)가 compileSdk >= 36을 요구.
// Flutter 3.44의 기본 compileSdk(35)를 쓰는 플러그인 서브프로젝트들을 36으로 강제.
// evaluationDependsOn(":app")로 이미 평가된 프로젝트는 afterEvaluate가 불가하므로 상태로 분기.
subprojects {
    val forceCompileSdk: Project.() -> Unit = {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
        }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
