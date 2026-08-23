package com.example.music_player

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "equalizer_channel"
    private var equalizerPlugin: EqualizerPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        equalizerPlugin = EqualizerPlugin()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        try {
                            // Initialize equalizer
                            val equalizer = android.media.audiofx.Equalizer(0, sessionId)
                            equalizer.setEnabled(true)
                            result.success(equalizer.numberOfBands)
                        } catch (e: Exception) {
                            result.error("INIT_ERROR", e.message, null)
                        }
                    }
                    "setBandLevel" -> {
                        val band = call.argument<Int>("band") ?: 0
                        val level = call.argument<Int>("level") ?: 0
                        try {
                            // Implementation via plugin
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BAND_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
