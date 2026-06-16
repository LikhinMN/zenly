package com.likhinmn.zenly.ime

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import kotlin.math.max

class WaveformView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#3C3489")
        strokeWidth = 10f
        strokeCap = Paint.Cap.ROUND
    }

    private val numBars = 8
    private val amplitudes = FloatArray(numBars) { 10f }
    private var isListening = false

    fun setListening(listening: Boolean) {
        isListening = listening
        if (!listening) {
            for (i in amplitudes.indices) amplitudes[i] = 10f
            invalidate()
        }
    }

    fun updateAmplitude(amplitude: Float) {
        if (!isListening) return
        
        for (i in 0 until numBars - 1) {
            amplitudes[i] = amplitudes[i + 1]
        }
        
        val normalized = (amplitude / 32767f) * height.toFloat() * 0.9f
        amplitudes[numBars - 1] = max(10f, normalized)
        
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        val w = width.toFloat()
        val h = height.toFloat()
        
        val barSpacing = w / (numBars + 1)
        val centerY = h / 2f
        
        for (i in 0 until numBars) {
            val x = barSpacing * (i + 1)
            val barHeight = amplitudes[i] / 2f
            canvas.drawLine(x, centerY - barHeight, x, centerY + barHeight, paint)
        }
    }
}
