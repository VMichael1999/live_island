package com.vmichael1999.live_island

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * Los textos que cada preset muestra con sus datos de ejemplo
 * (`doc/contract/resolved_texts.json`, generado por Dart): Kotlin recorre el
 * mismo JSON con su lógica y debe dar la misma lista.
 */
class LiveResolvedTextsTest {
    private val presets = JSONObject(File("../doc/contract/resolved_texts.json").readText()).getJSONArray("presets")

    private fun walk(n: Any?, state: LiveState, out: MutableList<String>) {
        when (n) {
            is JSONArray -> for (i in 0 until n.length()) walk(n.opt(i), state, out)
            is JSONObject -> {
                val t = n.optString("t")
                if (t == "if") {
                    val ok = CardLogic.condition(n.optJSONObject("when"), state)
                    walk(if (ok) n.opt("then") else n.opt("else"), state, out)
                    return
                }
                if (t == "text") out += CardLogic.textOf(n, state)
                for (k in n.keys()) if (k != "when") walk(n.opt(k), state, out)
            }
        }
    }

    @Test
    fun `cada preset resuelve los mismos textos que Dart`() {
        val fallos = (0 until presets.length()).mapNotNull { i ->
            val p = presets.getJSONObject(i)
            val state = LiveJson.state(p.getJSONObject("state"))
            val got = mutableListOf<String>().also { walk(p.getJSONObject("layout"), state, it) }.sorted()
            val want = p.getJSONArray("texts").let { a -> (0 until a.length()).map { a.getString(it) } }
            if (got == want) null else "${p.getString("name")}: esperaba $want y dio $got"
        }
        assertTrue(fallos.isEmpty(), fallos.joinToString("\n"))
    }
}
