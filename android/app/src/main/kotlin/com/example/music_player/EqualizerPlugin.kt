package com.example.music_player

import android.media.audiofx.Equalizer
import android.media.AudioManager
import android.media.MediaPlayer
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class EqualizerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var equalizer: Equalizer? = null
    private var audioSessionId: Int = 0

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "equalizer_channel")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> {
                val sessionId = call.argument<Int>("sessionId") ?: 0
                audioSessionId = sessionId
                try {
                    equalizer = Equalizer(0, audioSessionId)
                    equalizer?.setEnabled(true)
                    result.success(equalizer?.numberOfBands ?: 0)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            "setBandLevel" -> {
                val band = call.argument<Int>("band") ?: 0
                val level = call.argument<Int>("level") ?: 0
                try {
                    equalizer?.setBandLevel(band.toShort(), level.toShort())
                    result.success(true)
                } catch (e: Exception) {
                    result.error("BAND_ERROR", e.message, null)
                }
            }
            "setEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                try {
                    equalizer?.setEnabled(enabled)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ENABLE_ERROR", e.message, null)
                }
            }
            "release" -> {
                equalizer?.release()
                equalizer = null
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        equalizer?.release()
        equalizer = null
    }
}
