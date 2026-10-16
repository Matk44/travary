package com.travary.app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import com.travary.app.MainActivity
import com.travary.app.R
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * Travary's home-screen countdown on Android: Today's postcard with the
 * luggage tag hung on it, counting down to the next trip, then the days
 * left on it. The app writes every day ahead (lib/logic/countdown_widget.dart);
 * this picks the day for the phone's date and draws it.
 *
 * Travi pops up each morning until `traviUntilHour`, and for a moment when
 * the tag is tapped; tapping anywhere else opens the trip. An alarm (not
 * one that wakes the phone) redraws it at midnight and when he ducks.
 */
class CountdownWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        drawInBackground(context, ids)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        drawInBackground(context, intArrayOf(id))
    }

    override fun onDisabled(context: Context) {
        alarms(context).cancel(tickIntent(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TAP -> {
                taps(context).edit().putLong(KEY_TAP_AT, System.currentTimeMillis()).apply()
                val result = goAsync()
                executor.execute {
                    try {
                        drawAll(context)
                    } finally {
                        // He ducks again after a moment; the receiver may live that long.
                        Handler(Looper.getMainLooper()).postDelayed({
                            executor.execute {
                                try {
                                    drawAll(context)
                                } finally {
                                    result.finish()
                                }
                            }
                        }, TAP_HOLD_MS + 50)
                    }
                }
            }
            ACTION_TICK, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> drawInBackground(context, null)
            else -> super.onReceive(context, intent)
        }
    }

    private fun drawInBackground(context: Context, ids: IntArray?) {
        val result = goAsync()
        executor.execute {
            try {
                if (ids == null) drawAll(context) else draw(context, ids)
            } finally {
                result.finish()
            }
        }
    }

    companion object {
        const val ACTION_TAP = "com.travary.app.widget.TRAVI"
        const val ACTION_TICK = "com.travary.app.widget.TICK"
        private const val KEY_TAP_AT = "tapAt"

        /** How long Travi stays up after a tap before he ducks. */
        private const val TAP_HOLD_MS = 4000L

        /** One drawing at a time, off the main thread. */
        private val executor = Executors.newSingleThreadExecutor()

        /** Redraws every Travary widget: the app wrote new days. */
        fun reload(context: Context) {
            executor.execute { drawAll(context.applicationContext) }
        }

        private fun drawAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            draw(context, manager.getAppWidgetIds(ComponentName(context, CountdownWidgetProvider::class.java)))
        }

        private fun draw(context: Context, ids: IntArray) {
            val data = CountdownWidgetData.load(context)
            val now = LocalDateTime.now()
            val face = data?.faceOn(now.toLocalDate()) ?: CountdownFace.empty
            val until = data?.traviUntilHour ?: 12
            val tapAt = taps(context).getLong(KEY_TAP_AT, 0)
            val tapped = System.currentTimeMillis() - tapAt in 0 until TAP_HOLD_MS
            val up = now.hour < until || tapped
            val manager = AppWidgetManager.getInstance(context)
            for (id in ids) {
                try {
                    manager.updateAppWidget(id, views(context, manager, id, face, up))
                } catch (_: Exception) {
                    // A launcher that refuses this size of bitmap keeps the last drawing.
                }
            }
            if (ids.isNotEmpty()) schedule(context, now, until)
        }

        private fun views(context: Context, manager: AppWidgetManager, id: Int, face: CountdownFace, up: Boolean): RemoteViews {
            val options = manager.getAppWidgetOptions(id)
            // Portrait: the narrower width, the taller height.
            val wDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 }?.toFloat() ?: 250f
            val hDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 }?.toFloat() ?: 110f
            val density = context.resources.displayMetrics.density
            val scale = CountdownWidgetRenderer.scaleFor(wDp, hDp, density)
            val size = CountdownStage.sizeFor(wDp, hDp)
            val stage = CountdownStage.of(size, wDp * scale, hDp * scale)
            val radius = cornerRadius(context) / density * scale
            val renderer = CountdownWidgetRenderer(face, stage, scale, radius)

            val views = RemoteViews(context.packageName, R.layout.countdown_widget)
            views.setImageViewBitmap(R.id.countdown_back, renderer.back())
            views.setImageViewBitmap(R.id.countdown_front, renderer.front())
            val travi = renderer.travi()
            if (travi != null) views.setImageViewBitmap(R.id.countdown_travi_up, travi)
            views.setDisplayedChild(R.id.countdown_travi, if (up && travi != null) 1 else 0)
            views.setContentDescription(R.id.countdown_root, face.label)

            val open = Intent(context, MainActivity::class.java)
                .setAction(Intent.ACTION_VIEW)
                .setData(Uri.parse(face.link))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            views.setOnClickPendingIntent(
                R.id.countdown_root,
                PendingIntent.getActivity(context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
            // The tag's card, padded in from the widget's edges, says hello to Travi.
            val card = stage.tagCard
            views.setViewPadding(
                R.id.countdown_tag_area,
                (card.left / scale * density).roundToInt(),
                (card.top / scale * density).roundToInt(),
                ((stage.width - card.right) / scale * density).roundToInt(),
                ((stage.height - card.bottom) / scale * density).roundToInt(),
            )
            val tap = Intent(context, CountdownWidgetProvider::class.java).setAction(ACTION_TAP)
            views.setOnClickPendingIntent(
                R.id.countdown_tag_hit,
                PendingIntent.getBroadcast(context, 0, tap, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
            return views
        }

        /** The launcher's widget corners on Android 12 and later, else 16dp. */
        private fun cornerRadius(context: Context): Float {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    return context.resources.getDimension(android.R.dimen.system_app_widget_background_radius)
                } catch (_: Exception) {
                    // Falls through.
                }
            }
            return 16 * context.resources.displayMetrics.density
        }

        /** Next: Travi ducking at [until] o'clock this morning, else the next midnight. */
        private fun schedule(context: Context, now: LocalDateTime, until: Int) {
            val today = now.toLocalDate()
            val next = if (now.hour < until) today.atTime(until, 0) else LocalDate.from(today).plusDays(1).atStartOfDay()
            val at = next.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli() + 1000
            alarms(context).set(AlarmManager.RTC, at, tickIntent(context))
        }

        private fun tickIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            Intent(context, CountdownWidgetProvider::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun alarms(context: Context) = context.getSystemService(AlarmManager::class.java)

        private fun taps(context: Context) = context.getSharedPreferences("countdown_widget", Context.MODE_PRIVATE)
    }
}
