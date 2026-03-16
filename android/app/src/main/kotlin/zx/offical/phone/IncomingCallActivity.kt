package zx.offical.phone

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Full-screen activity shown on the lock screen when a call comes in.
 * Hosts a Flutter view that renders the incoming call UI.
 */
class IncomingCallActivity : FlutterActivity() {

    companion object {
        const val INCOMING_CHANNEL = "zx.offical.phone/incoming"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Show over lock screen
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val callerNumber = intent.getStringExtra("caller_number") ?: "Unknown"
        val callerName   = intent.getStringExtra("caller_name") ?: ""

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INCOMING_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCallerInfo" -> {
                    result.success(mapOf(
                        "number" to callerNumber,
                        "name"   to callerName,
                    ))
                }
                "answer" -> {
                    PhoneInCallService.answerCurrentCall()
                    // Switch to in-call screen in MainActivity
                    result.success(true)
                    finish()
                }
                "decline" -> {
                    PhoneInCallService.endCurrentCall()
                    result.success(true)
                    finish()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun getCachedEngineId(): String? = null
    override fun getDartEntrypointFunctionName(): String = "incomingCallMain"
}
