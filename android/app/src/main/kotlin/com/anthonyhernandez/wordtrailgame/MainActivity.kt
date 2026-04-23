package com.anthonyhernandez.wordtrailgame

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var fallbackToneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROGRESS_CHANNEL
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(PROGRESS_PREFS, Context.MODE_PRIVATE)
            when (call.method) {
                "load" -> result.success(prefs.getString(PROGRESS_KEY, null))
                "save" -> {
                    val payload = call.arguments as? String
                    if (payload == null) {
                        result.error("bad_args", "Progress payload must be a string.", null)
                        return@setMethodCallHandler
                    }
                    prefs.edit().putString(PROGRESS_KEY, payload).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FEEDBACK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val event = call.argument<String>("event") ?: "soft"
                    playFeedbackSound(event)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        fallbackToneGenerator?.release()
        fallbackToneGenerator = null
        super.onDestroy()
    }

    private fun playFeedbackSound(event: String) {
        try {
            when (event) {
                "soft" -> playTone(doubleArrayOf(420.0), 34, 0.045)
                "pause" -> {
                    playTone(doubleArrayOf(360.0), 42, 0.055)
                    mainHandler.postDelayed({ playTone(doubleArrayOf(260.0), 44, 0.05) }, 44)
                }
                "resume" -> {
                    playTone(doubleArrayOf(260.0), 42, 0.05)
                    mainHandler.postDelayed({ playTone(doubleArrayOf(420.0), 46, 0.06) }, 42)
                }
                "hint" -> playTone(doubleArrayOf(560.0, 840.0), 96, 0.08)
                "success" -> {
                    playTone(doubleArrayOf(680.0, 1020.0), 78, 0.12)
                    mainHandler.postDelayed({
                        playTone(doubleArrayOf(920.0, 1380.0), 92, 0.11)
                    }, 64)
                }
                "celebrate" -> {
                    playTone(doubleArrayOf(523.25, 783.99), 92, 0.12)
                    mainHandler.postDelayed({
                        playTone(doubleArrayOf(659.25, 987.77), 104, 0.13)
                    }, 90)
                    mainHandler.postDelayed({
                        playTone(doubleArrayOf(783.99, 1174.66), 132, 0.13)
                    }, 188)
                    mainHandler.postDelayed({
                        playTone(doubleArrayOf(1046.5, 1567.98), 150, 0.09)
                    }, 306)
                }
                else -> playTone(doubleArrayOf(420.0), 34, 0.045)
            }
        } catch (_: RuntimeException) {
            playFallbackTone(event)
        } catch (_: IllegalStateException) {
            playFallbackTone(event)
        }
    }

    private fun playTone(frequencies: DoubleArray, durationMs: Int, volume: Double) {
        val sampleCount = max(1, SAMPLE_RATE * durationMs / 1000)
        val samples = ShortArray(sampleCount)
        val attackSamples = max(1.0, SAMPLE_RATE * 0.006)
        val releaseSamples = max(1.0, SAMPLE_RATE * 0.045)

        for (index in samples.indices) {
            val time = index.toDouble() / SAMPLE_RATE
            val attack = min(1.0, index / attackSamples)
            val release = min(1.0, (sampleCount - index) / releaseSamples)
            val envelope = min(attack, release)
            var mixed = 0.0
            for (frequency in frequencies) {
                mixed += sin(2.0 * PI * frequency * time)
            }
            mixed /= frequencies.size
            val value = (mixed * envelope * volume * Short.MAX_VALUE).toInt()
            samples[index] = value.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }

        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(samples.size * 2)
            .build()

        track.write(samples, 0, samples.size)
        track.play()
        mainHandler.postDelayed({
            try {
                track.stop()
            } catch (_: IllegalStateException) {
            }
            track.release()
        }, durationMs.toLong() + 90L)
    }

    private fun playFallbackTone(event: String) {
        val generator = fallbackToneGenerator ?: try {
            ToneGenerator(AudioManager.STREAM_MUSIC, FALLBACK_VOLUME).also {
                fallbackToneGenerator = it
            }
        } catch (_: RuntimeException) {
            null
        } ?: return

        when (event) {
            "success" -> generator.startTone(ToneGenerator.TONE_PROP_BEEP2, 80)
            "celebrate" -> generator.startTone(ToneGenerator.TONE_PROP_BEEP2, 140)
            "pause", "resume", "soft" -> generator.startTone(ToneGenerator.TONE_PROP_ACK, 35)
            "hint" -> generator.startTone(ToneGenerator.TONE_PROP_BEEP, 70)
            else -> generator.startTone(ToneGenerator.TONE_PROP_ACK, 35)
        }
    }

    companion object {
        private const val PROGRESS_CHANNEL = "com.anthonyhernandez.wordtrailgame/progress"
        private const val FEEDBACK_CHANNEL = "wordtrail/feedback"
        private const val PROGRESS_PREFS = "wordtrail_progress"
        private const val PROGRESS_KEY = "progress_json"
        private const val SAMPLE_RATE = 44100
        private const val FALLBACK_VOLUME = 52
    }
}