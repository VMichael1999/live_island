package com.vmichael1999.live_island

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Una acción pendiente de entregar a Dart: un botón y, si fue una respuesta, su texto. */
data class PendingAction(val id: String, val text: String? = null) {
    /** Lo que viaja al canal de eventos: el id solo, o `{id, text}` en una respuesta. */
    fun toEvent(): Any = if (text == null) id else mapOf("id" to id, "text" to text)

    internal fun toStored(): Any = if (text == null) id else JSONObject().put("id", id).put("text", text)

    companion object {
        internal fun fromStored(raw: Any?): PendingAction? = when (raw) {
            is String -> PendingAction(raw)
            is JSONObject -> raw.optString("id").takeIf { it.isNotEmpty() }
                ?.let { PendingAction(it, if (raw.has("text")) raw.optString("text") else null) }
            else -> null
        }
    }
}

/**
 * Acciones de botones que aún no llegaron a Dart (la app estaba cerrada).
 * Se guardan en disco y se entregan cuando Dart empieza a escuchar.
 */
class LiveActionQueue(context: Context) {
    private val prefs = context.getSharedPreferences("live_island", Context.MODE_PRIVATE)

    @Synchronized
    fun add(action: PendingAction) {
        val a = JSONArray(prefs.getString(KEY, "[]"))
        a.put(action.toStored())
        prefs.edit().putString(KEY, a.toString()).apply()
    }

    @Synchronized
    fun drain(): List<PendingAction> {
        val a = JSONArray(prefs.getString(KEY, "[]"))
        if (a.length() == 0) return emptyList()
        prefs.edit().remove(KEY).apply()
        return (0 until a.length()).mapNotNull { PendingAction.fromStored(a.get(it)) }
    }

    private companion object {
        const val KEY = "pending_actions"
    }
}
