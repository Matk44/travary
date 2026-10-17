package com.travary.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The countdown widget's side of the app (lib/data/countdown_widget_bridge.dart):
 * the folder the widget reads, asking it to draw again, whether it's on the
 * home screen, and asking the launcher to place it. Dart writes the files.
 */
object CountdownWidgetChannel {
    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "travary/countdown_widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "folder" -> result.success(CountdownWidgetData.folder(app).path)
                "reload" -> {
                    CountdownWidgetProvider.reload(app)
                    result.success(null)
                }
                "status" -> result.success(status(app))
                "pin" -> result.success(pin(app))
                else -> result.notImplemented()
            }
        }
    }

    private fun provider(context: Context) = ComponentName(context, CountdownWidgetProvider::class.java)

    private fun canPin(manager: AppWidgetManager) =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.isRequestPinAppWidgetSupported

    /** Whether a countdown is on a home screen, and whether the launcher can be asked to place one. */
    private fun status(context: Context): Map<String, Boolean> {
        val manager = AppWidgetManager.getInstance(context)
        return mapOf(
            "supported" to true,
            "added" to manager.getAppWidgetIds(provider(context)).isNotEmpty(),
            "canPin" to canPin(manager),
        )
    }

    /** Asks the launcher to place the widget: it shows its own dialog, and the traveller may say no. */
    private fun pin(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        if (!canPin(manager)) return false
        return try {
            manager.requestPinAppWidget(provider(context), null, null)
        } catch (_: Exception) {
            false
        }
    }
}
