package com.vmichael1999.live_island

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import kotlin.math.abs
import kotlin.math.floor

/** Estado de una actividad: valores simples (texto, número, booleano o nulo). */
typealias LiveState = Map<String, Any?>

/** Utilidades para leer el contrato JSON (`docs/contract/`) sin depender de Android. */
object LiveJson {
    fun state(json: JSONObject): LiveState {
        val out = LinkedHashMap<String, Any?>()
        for (k in json.keys()) out[k] = if (json.isNull(k)) null else json.get(k)
        return out
    }

    /** El estado que llega se mezcla con el anterior: solo viajan los campos que cambian. */
    fun merge(base: LiveState, changes: LiveState): LiveState = LinkedHashMap(base).also { it.putAll(changes) }

    fun text(v: Any?): String = when (v) {
        null -> ""
        is Double -> numberText(v)
        is Float -> numberText(v.toDouble())
        else -> v.toString()
    }

    private fun numberText(d: Double) =
        if (d == floor(d) && abs(d) < 1e15) d.toLong().toString() else d.toString()

    fun number(v: Any?): Double? = when (v) {
        is Number -> v.toDouble()
        is String -> v.toDoubleOrNull()
        is Boolean -> if (v) 1.0 else 0.0
        else -> null
    }

    /** Fecha ISO 8601 (UTC) en milisegundos. */
    fun date(v: Any?): Long? = (v as? String)?.let {
        try { Instant.parse(it).toEpochMilli() } catch (_: Exception) { null }
    }

    /** Plantilla `{campo}`. */
    fun format(fmt: String, state: LiveState): String =
        Regex("\\{([A-Za-z_][A-Za-z0-9_]*)\\}").replace(fmt) { text(state[it.groupValues[1]]) }

    fun obj(o: JSONObject?, key: String): JSONObject? = o?.optJSONObject(key)

    fun str(o: JSONObject?, key: String): String? =
        if (o == null || !o.has(key) || o.isNull(key)) null else o.optString(key)

    fun array(o: JSONObject?, key: String): List<JSONObject> {
        val a: JSONArray = o?.optJSONArray(key) ?: return emptyList()
        return (0 until a.length()).mapNotNull { a.optJSONObject(it) }
    }

    /** Este nodo y todos sus descendientes, en orden de aparición. */
    fun descendants(node: JSONObject?): List<JSONObject> {
        if (node == null) return emptyList()
        val out = arrayListOf(node)
        for (c in array(node, "c")) out += descendants(c)
        for (k in listOf("child", "then", "else", "tracker", "visual", "start", "end", "icon")) {
            node.optJSONObject(k)?.let { out += descendants(it) }
        }
        return out
    }

    /** Los nodos de la isla expandida, en el orden leading, center, trailing, bottom. */
    fun expandedNodes(layout: JSONObject): List<JSONObject> {
        val e = obj(obj(layout, "regions"), "expanded") ?: return emptyList()
        return listOf("leading", "center", "trailing", "bottom").flatMap { descendants(e.optJSONObject(it)) }
    }
}
