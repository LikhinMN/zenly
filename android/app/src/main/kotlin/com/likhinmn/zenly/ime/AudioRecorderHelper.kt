package com.likhinmn.zenly.ime

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

class AudioRecorderHelper(private val context: Context) {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null

    private val sampleRate = 16000
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat) * 2

    private val vadHelper = VADHelper(sampleRate = sampleRate)

    var currentFile: File? = null
    private var pcmFile: File? = null

    fun startRecording(onAmplitude: (Float) -> Unit, onSilenceAutoStop: () -> Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return
        }

        audioRecord = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize)
        
        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            return
        }

        pcmFile = File(context.cacheDir, "temp_recording.pcm")
        vadHelper.reset()
        isRecording = true

        audioRecord?.startRecording()

        recordingThread = Thread {
            val os = FileOutputStream(pcmFile)
            val buffer = ShortArray(bufferSize)

            while (isRecording) {
                val readSize = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (readSize > 0) {
                    val byteBuffer = ByteBuffer.allocate(readSize * 2)
                    byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
                    byteBuffer.asShortBuffer().put(buffer, 0, readSize)
                    os.write(byteBuffer.array())

                    var maxAmp = 0
                    for (i in 0 until readSize) {
                        val absVal = Math.abs(buffer[i].toInt())
                        if (absVal > maxAmp) maxAmp = absVal
                    }
                    onAmplitude(maxAmp.toFloat())

                    vadHelper.processBuffer(buffer, readSize) {
                        if (isRecording) {
                            onSilenceAutoStop()
                        }
                    }
                }
            }
            os.close()

            // Convert PCM to WAV
            currentFile = File(context.cacheDir, "temp_recording.wav")
            pcmToWav(pcmFile!!, currentFile!!)
        }
        recordingThread?.start()
    }

    fun stopRecording(): Boolean {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        recordingThread?.join()

        return vadHelper.isChunkValid()
    }

    private fun pcmToWav(pcmFile: File, wavFile: File) {
        val pcmData = pcmFile.readBytes()
        val randomAccessFile = RandomAccessFile(wavFile, "rw")
        randomAccessFile.setLength(0)

        randomAccessFile.writeBytes("RIFF")
        randomAccessFile.writeInt(Integer.reverseBytes(36 + pcmData.size))
        randomAccessFile.writeBytes("WAVE")
        randomAccessFile.writeBytes("fmt ")
        randomAccessFile.writeInt(Integer.reverseBytes(16)) // Subchunk1Size
        randomAccessFile.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // AudioFormat
        randomAccessFile.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // NumChannels
        randomAccessFile.writeInt(Integer.reverseBytes(sampleRate)) // SampleRate
        randomAccessFile.writeInt(Integer.reverseBytes(sampleRate * 2)) // ByteRate
        randomAccessFile.writeShort(java.lang.Short.reverseBytes(2.toShort()).toInt()) // BlockAlign
        randomAccessFile.writeShort(java.lang.Short.reverseBytes(16.toShort()).toInt()) // BitsPerSample
        randomAccessFile.writeBytes("data")
        randomAccessFile.writeInt(Integer.reverseBytes(pcmData.size))
        randomAccessFile.write(pcmData)
        randomAccessFile.close()
    }
}
