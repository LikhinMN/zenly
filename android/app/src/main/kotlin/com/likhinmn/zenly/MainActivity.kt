package com.likhinmn.zenly

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.likhinmn.zenly/ime_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setGroqToken") {
                val token = call.argument<String>("token")
                if (token != null) {
                    try {
                        val masterKey = MasterKey.Builder(context)
                            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                            .build()
                        val sharedPreferences = EncryptedSharedPreferences.create(
                            context,
                            "ime_secret_prefs",
                            masterKey,
                            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                        )
                        sharedPreferences.edit().putString("groq_token", token).apply()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Token is null", null)
                }
            } else if (call.method == "openIMESettings") {
                try {
                    val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to open IME settings", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureOverlayEngine()
    }

    private fun ensureOverlayEngine() {
        if (FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_ID) == null) {
            val group = FlutterEngineGroup(applicationContext)
            val entryPoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "overlayMain"
            )
            val engine = group.createAndRunEngine(applicationContext, entryPoint)
            FlutterEngineCache.getInstance().put(OVERLAY_ENGINE_ID, engine)
        }
    }

    private companion object {
        const val OVERLAY_ENGINE_ID = "myCachedEngine"
    }
}