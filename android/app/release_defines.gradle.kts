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
import java.util.Base64

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
