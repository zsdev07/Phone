package zx.offical.phone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Handles notification action buttons (Answer / Decline / End).
 */
class CallActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_ANSWER  = "zx.offical.phone.ACTION_ANSWER"
        const val ACTION_DECLINE = "zx.offical.phone.ACTION_DECLINE"
        const val ACTION_END     = "zx.offical.phone.ACTION_END"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_ANSWER  -> PhoneInCallService.answerCurrentCall()
            ACTION_DECLINE,
            ACTION_END     -> PhoneInCallService.endCurrentCall()
        }
    }
}
