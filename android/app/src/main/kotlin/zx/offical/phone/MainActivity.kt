package zx.offical.phone

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telecom.TelecomManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CALL_CHANNEL       = "zx.offical.phone/call"
        const val CALL_STATE_CHANNEL = "zx.offical.phone/call_state"
        const val CALL_REQUEST_CODE  = 101
    }

    private var callStateEventSink: EventChannel.EventSink? = null
    private var pendingNumber: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel: stream call state to Dart ───────────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_STATE_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                callStateEventSink = events

                // Hook into InCallService callbacks
                PhoneInCallService.onCallStateChanged = { state, number, _ ->
                    runOnUiThread {
                        callStateEventSink?.success(mapOf(
                            "state"  to state,
                            "number" to (number ?: ""),
                        ))
                    }
                }
            }
            override fun onCancel(arguments: Any?) {
                callStateEventSink = null
                PhoneInCallService.onCallStateChanged = null
            }
        })

        // ── MethodChannel: actions ────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "makeCall" -> {
                    val number = call.argument<String>("number")
                    if (number.isNullOrBlank()) {
                        result.error("INVALID_NUMBER", "Number cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    val sanitized = sanitizeNumber(number)
                    if (hasCallPermission()) {
                        dialNumber(sanitized)
                        result.success(true)
                    } else {
                        pendingNumber = sanitized
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CALL_PHONE),
                            CALL_REQUEST_CODE
                        )
                        result.success(false)
                    }
                }

                "hasCallPermission"     -> result.success(hasCallPermission())

                "requestCallPermission" -> {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.CALL_PHONE),
                        CALL_REQUEST_CODE
                    )
                    result.success(null)
                }

                "isDefaultDialer"     -> result.success(isDefaultDialer())

                "requestDefaultDialer" -> {
                    requestDefaultDialer()
                    result.success(null)
                }

                "openDialerFallback" -> {
                    val number = call.argument<String>("number") ?: ""
                    startActivity(Intent(Intent.ACTION_DIAL).apply {
                        data = Uri.parse("tel:${sanitizeNumber(number)}")
                    })
                    result.success(true)
                }

                // ── In-call controls ──────────────────────────────────────
                "endCall"   -> {
                    PhoneInCallService.endCurrentCall()
                    result.success(true)
                }
                "answerCall" -> {
                    PhoneInCallService.answerCurrentCall()
                    result.success(true)
                }
                "holdCall"  -> {
                    PhoneInCallService.holdCurrentCall()
                    result.success(true)
                }
                "unholdCall" -> {
                    PhoneInCallService.unholdCurrentCall()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // If launched from active call notification, show in-call screen
        if (intent?.getBooleanExtra("show_incall", false) == true) {
            callStateEventSink?.success(mapOf("state" to "restore_incall", "number" to ""))
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_REQUEST_CODE &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            pendingNumber?.let { dialNumber(it) }
        }
        pendingNumber = null
    }

    private fun sanitizeNumber(number: String) =
        number.replace(Regex("[^+0-9*#]"), "")

    private fun hasCallPermission() =
        ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) ==
                PackageManager.PERMISSION_GRANTED

    private fun dialNumber(number: String) {
        startActivity(Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$number")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
    }

    private fun isDefaultDialer(): Boolean {
        val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
        return telecom.defaultDialerPackage == packageName
    }

    private fun requestDefaultDialer() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            (getSystemService(TELECOM_SERVICE) as TelecomManager)
                .requestDefaultDialer(packageName)
        } else {
            startActivity(Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(
                    TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME,
                    packageName
                )
            })
        }
    }
}
