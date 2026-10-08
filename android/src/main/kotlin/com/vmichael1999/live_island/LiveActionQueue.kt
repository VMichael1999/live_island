package com.vmichael1999.live_island

import android.content.Context
import org.json.JSONArray

/**
 * Acciones de botones que aún no llegaron a Dart (la app estaba cerrada).
 * Se guardan en disco y se entregan cuando Dart empieza a escuchar.
 */
class LiveActionQueue(context: Context) {
    private val prefs = context.getSharedPreferences("live_island", Context.MODE_PRIVATE)

    @Synchronized
    fun add(id: String) {
        val a = JSONArray(prefs.getString(KEY, "[]"))
        a.put(id)
        prefs.edit().putString(KEY, a.toString()).apply()
    }

    @Synchronized
    fun drain(): List<String> {
        val a = JSONArray(prefs.getString(KEY, "[]"))
        if (a.length() == 0) return emptyList()
        prefs.edit().remove(KEY).apply()
        return (0 until a.length()).map { a.getString(it) }
    }

    private companion object {
        const val KEY = "pending_actions"
    }
}
