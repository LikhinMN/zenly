package com.likhinmn.zenly.ime

import android.Manifest
import android.content.pm.PackageManager
import android.inputmethodservice.InputMethodService
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.likhinmn.zenly.R

import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.ImageButton
import android.graphics.Color
import android.widget.FrameLayout
import android.widget.ProgressBar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class KeyboardState {
    IDLE, LISTENING, PROCESSING, SUCCESS, ERROR
}

class ZenlyIME : InputMethodService() {

    private lateinit var keyboardView: View
    private lateinit var statusText: TextView
    private lateinit var micButtonContainer: FrameLayout
    private lateinit var loadingSpinner: ProgressBar
    private lateinit var waveformView: WaveformView

    private var currentState = KeyboardState.IDLE

    private lateinit var audioRecorderHelper: AudioRecorderHelper
    private lateinit var groqApiClient: GroqApiClient

    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate() {
        super.onCreate()
        audioRecorderHelper = AudioRecorderHelper(this)
        groqApiClient = GroqApiClient(this)
    }

    override fun onCreateInputView(): View {
        keyboardView = layoutInflater.inflate(R.layout.keyboard_view, null)
        statusText = keyboardView.findViewById(R.id.status_text)
        micButtonContainer = keyboardView.findViewById(R.id.mic_button_container)
        loadingSpinner = keyboardView.findViewById(R.id.loading_spinner)
        waveformView = keyboardView.findViewById(R.id.waveform_view)

        micButtonContainer.setOnClickListener {
            if (!hasMicPermission()) {
                setState(KeyboardState.ERROR, "Open Zenly app to grant mic permission")
                return@setOnClickListener
            }

            if (currentState == KeyboardState.LISTENING) {
                stopRecordingAndTranscribe()
            } else {
                startRecording()
            }
        }

        keyboardView.findViewById<ImageButton>(R.id.key_backspace).setOnClickListener {
            currentInputConnection?.deleteSurroundingText(1, 0)
        }

        keyboardView.findViewById<ImageButton>(R.id.key_space).setOnClickListener {
            currentInputConnection?.commitText(" ", 1)
        }

        keyboardView.findViewById<ImageButton>(R.id.key_enter).setOnClickListener {
            val info = currentInputEditorInfo
            val actionId = info.imeOptions and EditorInfo.IME_MASK_ACTION
            if (actionId == EditorInfo.IME_ACTION_NONE || actionId == EditorInfo.IME_ACTION_UNSPECIFIED) {
                currentInputConnection?.commitText("\n", 1)
            } else {
                currentInputConnection?.performEditorAction(actionId)
            }
        }

        keyboardView.findViewById<ImageButton>(R.id.key_switch_ime).setOnClickListener {
            try {
                val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                val token = window.window?.attributes?.token
                if (token != null) {
                    imm.switchToNextInputMethod(token, false)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        setState(KeyboardState.IDLE)
        return keyboardView
    }

    private fun setState(state: KeyboardState, message: String? = null) {
        currentState = state
        when (state) {
            KeyboardState.IDLE -> {
                statusText.text = message ?: "tap to record"
                statusText.setTextColor(Color.parseColor("#555555"))
                waveformView.visibility = View.INVISIBLE
                waveformView.setListening(false)
                loadingSpinner.visibility = View.INVISIBLE
                micButtonContainer.visibility = View.VISIBLE
                micButtonContainer.animate().scaleX(1f).scaleY(1f).setDuration(200).start()
                micButtonContainer.setBackgroundResource(R.drawable.mic_bg)
            }
            KeyboardState.LISTENING -> {
                statusText.text = message ?: "Listening..."
                statusText.setTextColor(Color.parseColor("#E0E0E0"))
                waveformView.visibility = View.VISIBLE
                waveformView.setListening(true)
                loadingSpinner.visibility = View.INVISIBLE
                micButtonContainer.visibility = View.VISIBLE
                micButtonContainer.animate().scaleX(1.1f).scaleY(1.1f).setDuration(200).start()
                micButtonContainer.setBackgroundResource(R.drawable.mic_bg_recording)
            }
            KeyboardState.PROCESSING -> {
                statusText.text = message ?: "Transcribing..."
                statusText.setTextColor(Color.parseColor("#E0E0E0"))
                waveformView.visibility = View.INVISIBLE
                waveformView.setListening(false)
                micButtonContainer.visibility = View.INVISIBLE
                loadingSpinner.visibility = View.VISIBLE
            }
            KeyboardState.SUCCESS -> {
                statusText.text = message ?: "Success"
                statusText.setTextColor(Color.parseColor("#4CAF50"))
                waveformView.visibility = View.INVISIBLE
                waveformView.setListening(false)
                loadingSpinner.visibility = View.INVISIBLE
                micButtonContainer.visibility = View.VISIBLE
                micButtonContainer.animate().scaleX(1f).scaleY(1f).setDuration(200).start()
                micButtonContainer.setBackgroundResource(R.drawable.mic_bg)
                
                coroutineScope.launch {
                    delay(1200)
                    if (currentState == KeyboardState.SUCCESS) setState(KeyboardState.IDLE)
                }
            }
            KeyboardState.ERROR -> {
                statusText.text = message ?: "Error"
                statusText.setTextColor(Color.parseColor("#D32F2F"))
                waveformView.visibility = View.INVISIBLE
                waveformView.setListening(false)
                loadingSpinner.visibility = View.INVISIBLE
                micButtonContainer.visibility = View.VISIBLE
                micButtonContainer.animate().scaleX(1f).scaleY(1f).setDuration(200).start()
                micButtonContainer.setBackgroundResource(R.drawable.mic_bg)
                
                coroutineScope.launch {
                    delay(2000)
                    if (currentState == KeyboardState.ERROR) setState(KeyboardState.IDLE)
                }
            }
        }
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startRecording() {
        setState(KeyboardState.LISTENING)

        audioRecorderHelper.startRecording(
            onAmplitude = { amp ->
                coroutineScope.launch {
                    if (currentState == KeyboardState.LISTENING) {
                        waveformView.updateAmplitude(amp)
                    }
                }
            },
            onSilenceAutoStop = {
                coroutineScope.launch {
                    stopRecordingAndTranscribe()
                }
            }
        )
    }

    private fun stopRecordingAndTranscribe() {
        if (currentState != KeyboardState.LISTENING) return
        setState(KeyboardState.PROCESSING)
        
        val isValid = audioRecorderHelper.stopRecording()
        val file = audioRecorderHelper.currentFile

        if (!isValid || file == null || !file.exists()) {
            setState(KeyboardState.ERROR, "Audio too short/quiet")
            return
        }

        coroutineScope.launch {
            try {
                val transcript = withContext(Dispatchers.IO) {
                    groqApiClient.transcribe(file)
                }
                
                if (transcript.isNotBlank()) {
                    injectText("$transcript ")
                    setState(KeyboardState.SUCCESS, "Ready")
                } else {
                    setState(KeyboardState.ERROR, "No speech detected")
                }
            } catch (e: Exception) {
                setState(KeyboardState.ERROR, "Error: ${e.message}")
            }
        }
    }

    private fun injectText(transcript: String) {
        val inputConnection = currentInputConnection
        inputConnection?.commitText(transcript, 1)
    }
}
