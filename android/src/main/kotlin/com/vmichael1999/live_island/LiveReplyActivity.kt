package com.vmichael1999.live_island

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.text.InputType
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout

/**
 * Cuadro de texto de un botón de respuesta en línea (`LiveButton.reply`).
 *
 * La notificación de un Live Update (Android 16+) no dibuja el campo de texto
 * nativo (`RemoteInput`), así que el botón abre este cuadro, que es igual en
 * todas las versiones. Lo escrito llega a `LiveIsland.onReply`.
 */
class LiveReplyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val buttonId = intent.getStringExtra(EXTRA_BUTTON_ID)
        if (buttonId == null) {
            finish()
            return
        }
        val input = EditText(this).apply {
            hint = intent.getStringExtra(EXTRA_HINT)
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or
                InputType.TYPE_TEXT_FLAG_MULTI_LINE
            maxLines = 4
        }
        val pad = (20 * resources.displayMetrics.density).toInt()
        val box = FrameLayout(this).apply { setPadding(pad, pad / 2, pad, 0); addView(input) }

        // Tema del dispositivo (Material en Android recientes), no el antiguo de diálogos.
        AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Light_Dialog_Alert)
            .setTitle(intent.getStringExtra(EXTRA_TITLE))
            .setView(box)
            .setPositiveButton(android.R.string.ok) { _, _ ->
                val text = input.text.toString().trim()
                if (text.isNotEmpty()) {
                    LiveIslandPlugin.deliverAction(this, PendingAction(buttonId, text))
                }
            }
            .setNegativeButton(android.R.string.cancel, null)
            .setOnDismissListener { finish() }
            .create()
            .also { dialog ->
                dialog.window?.setSoftInputMode(android.view.WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
                dialog.show()
                input.requestFocus()
                (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
                    .showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
            }
    }

    companion object {
        const val EXTRA_BUTTON_ID = "buttonId"
        const val EXTRA_HINT = "hint"
        const val EXTRA_TITLE = "title"
    }
}
