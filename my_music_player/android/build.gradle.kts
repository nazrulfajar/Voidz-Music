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
    plugins.withId("com.android.library") {
        val androidExt = project.extensions.getByName("android")

        // Fix namespace for old packages that don't declare it
        // (e.g. isar_flutter_libs).
        try {
            val getNamespace = androidExt.javaClass.getMethod("getNamespace")
            val currentNs = getNamespace.invoke(androidExt) as? String
            if (currentNs == null || currentNs.isEmpty()) {
                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                val ns = if (project.group.toString().isNotEmpty() && project.group.toString() != "unspecified")
                    project.group.toString()
                else
                    "dev.flutter." + project.name.replace("-", "_")
                setNamespace.invoke(androidExt, ns)
            }
        } catch (_: Exception) {}
    }
}

subprojects {
    afterEvaluate {
        plugins.withId("com.android.library") {
            val androidExt = project.extensions.getByName("android")

            // AGP checks AAR metadata against each library's compileSdk. Some
            // plugins (isar_flutter_libs 3.1.0+1) still declare compileSdk 30,
            // which fails on CI even though the app compiles against 36.
            // afterEvaluate makes this win over the plugin's build.gradle.
            try {
                val setCompileSdk = androidExt.javaClass.methods.firstOrNull {
                    (it.name == "setCompileSdk" || it.name == "setCompileSdkVersion") &&
                        it.parameterTypes.size == 1 &&
                        (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                            it.parameterTypes[0] == Integer::class.javaObjectType)
                }
                setCompileSdk?.invoke(androidExt, 36)
            } catch (_: Exception) {}
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
