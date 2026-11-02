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

    plugins.withId("com.android.library") {
        @Suppress("UNCHECKED_CAST")
        val androidExt = project.extensions.getByName("android")

        // Fix namespace for old packages that don't declare it (e.g. isar_flutter_libs)
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
