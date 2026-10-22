import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The Play upload key: android/key.properties (never committed) names the
// keystore and its passwords. See https://flutter.dev/to/reference-keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasUploadKey = keystorePropertiesFile.exists()

// Release builds take RevenueCat's keys and live flight lookup when the
// flutter command didn't pass them, so a plain `flutter build appbundle`
// makes the same app as tool/build_release.sh. Without the keys the app
// refuses to start (see bootstrap); here the build fails instead.
//
// Flutter's Gradle plugin reads the Dart defines from the `dart-defines`
// property (each KEY=value in base64, joined by commas) once this script has
// run. Defines already passed stay as they are, every entry of
// config/revenuecat.local.json that's missing is added (as
// --dart-define-from-file would), and debug and profile builds are left
// alone. iOS does the same in tool/xcode_dart_defines.sh.
// It lives here rather than in its own applied script: release builds'
// lint can't read a standalone .gradle.kts and fails the build.
val releaseBuild = gradle.startParameter.taskNames.any { it.contains("Release") }
if (releaseBuild) {
    val passed = findProperty("dart-defines")?.toString().orEmpty().split(",").filter { it.isNotEmpty() }
    val defined = passed.map { String(Base64.getDecoder().decode(it)) }.associate { it.substringBefore("=") to it.substringAfter("=") }
    val added = mutableListOf<String>()
    if ("TRAVARY_REVENUECAT_ANDROID_KEY" !in defined && defined["TRAVARY_BACKEND"] != "demo") {
        val keys = rootProject.file("../config/revenuecat.local.json")
        if (!keys.exists()) {
            throw GradleException("config/revenuecat.local.json is missing: a release build needs RevenueCat's public SDK keys, or the app refuses to start (see CLAUDE.md, Premium).")
        }
        val json = groovy.json.JsonSlurper().parse(keys) as Map<*, *>
        if (json["TRAVARY_REVENUECAT_ANDROID_KEY"]?.toString()?.startsWith("goog_") != true) {
            throw GradleException("config/revenuecat.local.json has no Android key (goog_…).")
        }
        json.forEach { (name, value) -> if (name.toString() !in defined) added += "$name=$value" }
    }
    if ("TRAVARY_FLIGHT_LOOKUP" !in defined) added += "TRAVARY_FLIGHT_LOOKUP=true"
    if (added.isNotEmpty()) {
        extra["dart-defines"] = (passed + added.map { Base64.getEncoder().encodeToString(it.toByteArray()) }).joinToString(",")
    }
}

android {
    namespace = "com.travary.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (reminders) needs newer Java APIs on old Androids.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.travary.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties (a fresh checkout), release builds fall
            // back to the debug key so `flutter run --release` still works;
            // Google Play rejects those, so build store uploads with the key.
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("android/key.properties not found: release build is signed with the DEBUG key (Google Play will reject it).")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
