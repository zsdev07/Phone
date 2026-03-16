package zx.offical.phone

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.InCallService
import androidx.core.app.NotificationCompat

/**
 * PhoneInCallService — registered with Android's Telecom framework.
 *
 * Responsibilities:
 *  1. Track the active/incoming Call object
 *  2. Show a full-screen incoming call notification (lock-screen takeover)
 *  3. Expose call state changes to MainActivity via a singleton so the
 *     Flutter EventChannel can stream them to Dart
 */
class PhoneInCallService : InCallService() {

    companion object {
        const val CHANNEL_ID       = "phone_incall"
        const val NOTIF_ID_INCOMING = 1001
        const val NOTIF_ID_ACTIVE   = 1002

        // Singleton so MainActivity can reach the active call
        var currentCall: Call? = null
            private set

        var onCallStateChanged: ((String, String?, Call.Details?) -> Unit)? = null

        fun endCurrentCall() {
            currentCall?.disconnect()
        }

        fun answerCurrentCall() {
            currentCall?.answer(0)
        }

        fun holdCurrentCall() {
            currentCall?.hold()
        }

        fun unholdCurrentCall() {
            currentCall?.unhold()
        }
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            handleStateChange(call, state)
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        currentCall = call
        call.registerCallback(callCallback)
        handleStateChange(call, call.state)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        if (currentCall == call) currentCall = null
        onCallStateChanged?.invoke("disconnected", null, null)
        cancelNotifications()
    }

    private fun handleStateChange(call: Call, state: Int) {
        val callerName  = call.details?.callerDisplayName?.takeIf { it.isNotBlank() }
        val callerNumber = call.details?.handle?.schemeSpecificPart

        when (state) {
            Call.STATE_RINGING -> {
                onCallStateChanged?.invoke("ringing", callerNumber ?: callerName, call.details)
                showIncomingCallNotification(callerNumber, callerName)
                launchIncomingCallActivity(callerNumber, callerName)
            }
            Call.STATE_ACTIVE -> {
                onCallStateChanged?.invoke("active", callerNumber ?: callerName, call.details)
                cancelIncomingNotification()
                showActiveCallNotification(callerNumber, callerName)
            }
            Call.STATE_HOLDING -> {
                onCallStateChanged?.invoke("holding", callerNumber ?: callerName, call.details)
            }
            Call.STATE_DISCONNECTING,
            Call.STATE_DISCONNECTED -> {
                onCallStateChanged?.invoke("disconnected", null, null)
                cancelNotifications()
            }
            Call.STATE_DIALING,
            Call.STATE_CONNECTING -> {
                onCallStateChanged?.invoke("dialing", callerNumber ?: callerName, call.details)
            }
        }
    }

    // ── Incoming call full-screen activity ───────────────────────────────────
    private fun launchIncomingCallActivity(number: String?, name: String?) {
        val intent = Intent(this, IncomingCallActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("caller_number", number ?: "Unknown")
            putExtra("caller_name",   name ?: "")
        }
        startActivity(intent)
    }

    // ── Notifications ────────────────────────────────────────────────────────
    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val ch = NotificationChannel(
                    CHANNEL_ID,
                    "Phone Calls",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Incoming and active call notifications"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun showIncomingCallNotification(number: String?, name: String?) {
        ensureChannel()
        val label = name?.takeIf { it.isNotBlank() } ?: number ?: "Unknown"

        val answerIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, IncomingCallActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                putExtra("caller_number", number ?: "Unknown")
                putExtra("caller_name", name ?: "")
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val declineIntent = PendingIntent.getBroadcast(
            this, 1,
            Intent(this, CallActionReceiver::class.java).apply {
                action = CallActionReceiver.ACTION_DECLINE
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("Incoming call")
            .setContentText(label)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(answerIntent, true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declineIntent)
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()

        startForeground(NOTIF_ID_INCOMING, notification)
    }

    @SuppressLint("MissingPermission")
    private fun showActiveCallNotification(number: String?, name: String?) {
        ensureChannel()
        val label = name?.takeIf { it.isNotBlank() } ?: number ?: "Unknown"

        val openIntent = PendingIntent.getActivity(
            this, 2,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("show_incall", true)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val endIntent = PendingIntent.getBroadcast(
            this, 3,
            Intent(this, CallActionReceiver::class.java).apply {
                action = CallActionReceiver.ACTION_END
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("On a call")
            .setContentText(label)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setContentIntent(openIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "End", endIntent)
            .setOngoing(true)
            .build()

        startForeground(NOTIF_ID_ACTIVE, notification)
    }

    private fun cancelIncomingNotification() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.cancel(NOTIF_ID_INCOMING)
    }

    private fun cancelNotifications() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        val nm = getSystemService(NotificationManager::class.java)
        nm.cancel(NOTIF_ID_INCOMING)
        nm.cancel(NOTIF_ID_ACTIVE)
    }
}
