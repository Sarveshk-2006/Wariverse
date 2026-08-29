package com.wariverse.mobile

import android.os.Build
import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wariverse.mobile/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendDirectSMS") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")

                if (!phoneNumber.isNullOrEmpty() && !message.isNullOrEmpty()) {
                    try {
                        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        if (smsManager != null) {
                            val parts = smsManager.divideMessage(message)
                            if (parts.size > 1) {
                                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                            } else {
                                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                            }
                            result.success(true)
                        } else {
                            result.error("SMS_MANAGER_NULL", "SmsManager system service is unavailable", null)
                        }
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone number or message is empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
