package com.travary.app.widget

import android.content.Context
import android.graphics.Color
import android.graphics.RectF
import org.json.JSONObject
import java.io.File
import java.time.LocalDate

/**
 * What the app wrote for the widget (lib/logic/countdown_widget.dart):
 * every day ahead, already worded, with each trip's art. The widget only
 * picks the day for the phone's date and draws it; it never words anything.
 */
class CountdownWidgetData(private val folder: File, private val json: JSONObject) {
    val traviUntilHour: Int = json.optInt("traviUntilHour", 12)

    /** The face for [date]: its day if the app wrote one, else the idle face. */
    fun faceOn(date: LocalDate): CountdownFace {
        val fonts = json.optJSONObject("fonts")
        val serif = file(fonts?.optStringOrNull("serif"))
        val sans = file(fonts?.optStringOrNull("sans"))
        val sansMedium = file(fonts?.optStringOrNull("sansMedium"))
        val day = json.optJSONObject("days")?.optJSONObject(date.toString())
        if (day != null) {
            val art = json.optJSONObject("trips")?.optJSONObject(day.optString("trip"))
                ?: json.getJSONObject("idle").getJSONObject("art")
            return CountdownFace(
                tripId = day.optStringOrNull("trip"),
                heading = day.optString("heading"),
                eyebrow = day.optString("eyebrow"),
                days = day.optString("days"),
                daysLabel = day.optString("daysLabel"),
                place = day.optString("place"),
                dates = day.optString("dates"),
                shortDates = day.optString("shortDates"),
                label = day.optString("label"),
                portrait = file(art.optStringOrNull("portrait")),
                landscape = file(art.optStringOrNull("landscape")),
                tag = file(art.optStringOrNull("tag")),
                linen = file(art.optStringOrNull("linen")),
                ink = colour(art.optString("ink"), CountdownFace.INK),
                paper = colour(art.optString("paper"), CountdownFace.PAPER),
                travi = still(day.optString("travi")),
                serif = serif, sans = sans, sansMedium = sansMedium,
            )
        }
        val idle = json.getJSONObject("idle")
        val art = idle.getJSONObject("art")
        return CountdownFace(
            tripId = idle.optStringOrNull("trip"),
            heading = idle.optString("heading"),
            eyebrow = idle.optString("eyebrow"),
            days = null,
            daysLabel = "",
            place = idle.optString("title"),
            dates = idle.optString("message"),
            shortDates = idle.optString("message"),
            label = idle.optString("label"),
            portrait = file(art.optStringOrNull("portrait")),
            landscape = file(art.optStringOrNull("landscape")),
            tag = file(art.optStringOrNull("tag")),
            linen = file(art.optStringOrNull("linen")),
            ink = colour(art.optString("ink"), CountdownFace.INK),
            paper = colour(art.optString("paper"), CountdownFace.PAPER),
            travi = still(idle.optString("travi")),
            serif = serif, sans = sans, sansMedium = sansMedium,
        )
    }

    private fun still(mood: String): TraviStill? {
        val still = json.optJSONObject("travi")?.optJSONObject(mood) ?: return null
        val file = file(still.optStringOrNull("file")) ?: return null
        val box = still.optJSONArray("box") ?: return null
        if (box.length() != 4) return null
        val left = box.getDouble(0).toFloat()
        val top = box.getDouble(1).toFloat()
        return TraviStill(
            file,
            RectF(left, top, left + box.getDouble(2).toFloat(), top + box.getDouble(3).toFloat()),
            json.optDouble("traviCanvas", 480.0).toFloat(),
        )
    }

    private fun file(name: String?): File? = name?.let { File(folder, it) }?.takeIf { it.isFile }

    companion object {
        /** The file shapes this widget knows. */
        private const val VERSION = 1

        /** The widget's folder in the app's own files; Dart writes it. */
        fun folder(context: Context): File = File(context.filesDir, "countdown_widget")

        fun load(context: Context): CountdownWidgetData? {
            val folder = folder(context)
            return try {
                val json = JSONObject(File(folder, "countdown.json").readText())
                if (json.optInt("version") != VERSION) null else CountdownWidgetData(folder, json)
            } catch (_: Exception) {
                null
            }
        }

        private fun colour(hex: String, fallback: Int): Int =
            try {
                Color.parseColor(hex)
            } catch (_: Exception) {
                fallback
            }
    }
}

/** Everything one day's widget draws: the words for that date, and the trip's art, ink and fonts. */
data class CountdownFace(
    /** The trip shown, opened by a tap; null opens Today. */
    val tripId: String?,
    val heading: String,
    val eyebrow: String,
    /** The large number; null when nothing is coming up ([place] and [dates] are then a title and a line). */
    val days: String?,
    val daysLabel: String,
    val place: String,
    val dates: String,
    val shortDates: String,
    val label: String,
    val portrait: File?,
    val landscape: File?,
    val tag: File?,
    val linen: File?,
    val ink: Int,
    val paper: Int,
    val travi: TraviStill?,
    val serif: File?,
    val sans: File?,
    val sansMedium: File?,
) {
    val link: String
        get() = tripId?.let { "travary://trip/${android.net.Uri.encode(it)}" } ?: "travary://today"

    companion object {
        val INK = Color.rgb(0x1C, 0x2A, 0x47)
        val PAPER = Color.rgb(0xF8, 0xF4, 0xEC)

        /** Before the app has written anything: a plain countdown with no art, asking to open the app. */
        val empty = CountdownFace(
            tripId = null, heading = "NEXT ADVENTURE", eyebrow = "NEXT TRIP", days = null, daysLabel = "",
            place = "Your next trip", dates = "Open Travary to start", shortDates = "Open Travary",
            label = "Trip countdown. Open Travary to start.",
            portrait = null, landscape = null, tag = null, linen = null, ink = INK, paper = PAPER,
            travi = null, serif = null, sans = null, sansMedium = null,
        )
    }
}

/** A cameo still and where it stands on its square canvas. */
data class TraviStill(val file: File, val box: RectF, val canvas: Float)

private fun JSONObject.optStringOrNull(key: String): String? =
    if (isNull(key) || !has(key)) null else optString(key).takeIf { it.isNotEmpty() }
