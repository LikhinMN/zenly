package com.likhinmn.zenly.ime

class VADHelper(
    private val speechDbThreshold: Double = -50.0,
    private val minPeakDb: Double = -45.0,
    private val silenceStopDurationMs: Long = 1200L,
    private val sampleRate: Int = 16000
) {
    private var totalSpeechMs = 0L
    private var consecutiveSilenceMs = 0L
    private var peakDb = -120.0
    private var hasSpeechSegment = false

    fun processBuffer(buffer: ShortArray, readSize: Int, onSilenceDetected: () -> Unit) {
        var amplitude = 0
        for (i in 0 until readSize) {
            val absVal = Math.abs(buffer[i].toInt())
            if (absVal > amplitude) {
                amplitude = absVal
            }
        }

        val db = if (amplitude > 0) 20 * Math.log10(amplitude / 32767.0) else -120.0
        if (db > peakDb) peakDb = db

        // Time length of this buffer
        val bufferDurationMs = (readSize.toLong() * 1000L) / sampleRate

        if (db >= speechDbThreshold) {
            totalSpeechMs += bufferDurationMs
            consecutiveSilenceMs = 0L
            hasSpeechSegment = true
        } else {
            if (hasSpeechSegment) {
                consecutiveSilenceMs += bufferDurationMs
                if (consecutiveSilenceMs >= silenceStopDurationMs) {
                    onSilenceDetected()
                }
            }
        }
    }

    fun isChunkValid(): Boolean {
        // Based on Dart config: minSpeechMs = 1000, minPeakDb = -45
        return hasSpeechSegment && totalSpeechMs >= 1000L && peakDb >= minPeakDb
    }
    
    fun reset() {
        totalSpeechMs = 0L
        consecutiveSilenceMs = 0L
        peakDb = -120.0
        hasSpeechSegment = false
    }
}
