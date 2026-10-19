package com.vmichael1999.live_island

import org.json.JSONObject
import kotlin.math.abs

/**
 * La parte de la tarjeta (`style: card`) que no necesita Android: evaluar
 * condiciones, resolver textos y elegir esquinas. La dibuja [CardRenderer].
 */
object CardLogic {
    /** `{bind, eq|neq|gt|gte|lt|lte|truthy}` del contrato. */
    fun condition(c: JSONObject?, state: LiveState): Boolean {
        if (c == null) return false
        val v = state[c.optString("bind")]
        fun cmp(key: String): Double? = if (c.has(key)) c.optDouble(key) else null
        return when {
            c.has("eq") -> same(v, c.get("eq"))
            c.has("neq") -> !same(v, c.get("neq"))
            c.has("gt") -> (LiveJson.number(v) ?: return false) > cmp("gt")!!
            c.has("gte") -> (LiveJson.number(v) ?: return false) >= cmp("gte")!!
            c.has("lt") -> (LiveJson.number(v) ?: return false) < cmp("lt")!!
            c.has("lte") -> (LiveJson.number(v) ?: return false) <= cmp("lte")!!
            c.has("truthy") -> truthy(v) == c.optBoolean("truthy", true)
            else -> false
        }
    }

    private fun same(a: Any?, b: Any?): Boolean {
        val x = LiveJson.number(a)
        val y = LiveJson.number(b)
        if (x != null && y != null && a !is Boolean && b !is Boolean) return abs(x - y) < 1e-9
        return LiveJson.text(a) == LiveJson.text(b)
    }

    private fun truthy(v: Any?): Boolean = when (v) {
        null -> false
        is Boolean -> v
        is Number -> v.toDouble() != 0.0
        is String -> v.isNotEmpty() && v != "false" && v != "0"
        else -> true
    }

    /** El texto de un nodo `text` (enlazado, literal o plantilla). */
    fun textOf(node: JSONObject, state: LiveState): String {
        LiveJson.str(node, "fmt")?.let { return LiveJson.format(it, state) }
        LiveJson.str(node, "text")?.let { return it }
        LiveJson.str(node, "bind")?.let { return LiveJson.text(state[it]) }
        return ""
    }

    /** «en 5 min», «hace 2 min» para un nodo `relative`. */
    fun relative(targetMillis: Long, nowMillis: Long): String {
        val minutes = (targetMillis - nowMillis) / 60_000
        return when {
            minutes > 0 -> "en $minutes min"
            minutes < 0 -> "hace ${-minutes} min"
            else -> "ahora"
        }
    }

    /** La esquina de las disponibles (8, 12, 16, 20, 28 o 99 = cápsula) más cercana. */
    fun radiusBucket(radius: Double?): Int {
        val r = radius ?: return 12
        if (r >= 40) return 99
        return listOf(8, 12, 16, 20, 28).minByOrNull { abs(it - r) } ?: 12
    }

    /** Peso de la fuente → ¿negrita? (600 o más). */
    fun isBold(weight: Int?): Boolean = (weight ?: 400) >= 600
}
