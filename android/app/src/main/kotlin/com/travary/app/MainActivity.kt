package com.travary.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// A FragmentActivity, so local_auth can show the fingerprint/face prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        dropUnreadableShare(intent)
        super.onCreate(savedInstanceState)
        createFlightChangesChannel()
    }

    override fun onNewIntent(intent: Intent) {
        dropUnreadableShare(intent)
        super.onNewIntent(intent)
    }

    // A file shared in that Travary isn't allowed to read (the sharing app
    // didn't grant it) would crash receive_sharing_intent as it copies it:
    // drop it instead, and the app just opens.
    private fun dropUnreadableShare(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        val uri = sharedUri(intent) ?: return
        val readable = try {
            contentResolver.openInputStream(uri)?.use { true } ?: false
        } catch (_: Exception) {
            false
        }
        if (!readable) intent.removeExtra(Intent.EXTRA_STREAM)
    }

    @Suppress("DEPRECATION")
    private fun sharedUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    // Flight alerts arrive on their own channel (the server sends to
    // "flight_changes"), high importance so a delay or cancellation pops up.
    private fun createFlightChangesChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "flight_changes",
            "Flight changes",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Delays, new times and cancellations for flights on your trips"
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
