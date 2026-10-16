package com.travary.app.widget

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The countdown widget's side of the app (lib/data/countdown_widget_bridge.dart):
 * the folder the widget reads, and asking it to draw again. Dart writes the files.
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
                else -> result.notImplemented()
            }
        }
    }
}
