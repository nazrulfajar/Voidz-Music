import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The keystore can live outside the repo. Resolution order:
// 1. -Pvoidz.keystore.properties=/path/to/key.properties
// 2. VOIDZ_KEYSTORE_PROPERTIES environment variable
// 3. android/key.properties (legacy/local default)
val keystorePropertiesPath =
    providers.gradleProperty("voidz.keystore.properties").orNull
        ?: System.getenv("VOIDZ_KEYSTORE_PROPERTIES")

val keystorePropertiesFile = if (keystorePropertiesPath != null) {
    File(keystorePropertiesPath)
} else {
    rootProject.file("key.properties")
}

val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// Resolve storeFile relative to key.properties, not relative to android/app.
val keystoreBaseDir =
    keystorePropertiesFile.absoluteFile.parentFile ?: rootProject.projectDir
val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.let { path ->
    val candidate = File(path)
    if (candidate.isAbsolute) candidate else File(keystoreBaseDir, path)
}

val hasReleaseSigning = keystorePropertiesFile.exists() &&
    releaseStoreFile?.exists() == true &&
    keystoreProperties.getProperty("storePassword") != null &&
    keystoreProperties.getProperty("keyPassword") != null &&
    keystoreProperties.getProperty("keyAlias") != null

android {
    namespace = "io.github.nazrulfajar.voidzmusic"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.nazrulfajar.voidzmusic"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 34
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        noCompress += listOf("imy", "so", "pem", "json")
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Debug signing is only a placeholder for local tooling. The
            // release task below fails hard when no real keystore is configured.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }
    .configureEach {
        doFirst {
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Set " +
                        "-Pvoidz.keystore.properties=/path/to/key.properties, " +
                        "VOIDZ_KEYSTORE_PROPERTIES=/path/to/key.properties, " +
                        "or create android/key.properties."
                )
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
