package com.vmichael1999.live_island

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Los mismos casos que ejecutan Dart y Swift (`doc/contract/conformance.json`):
 * si una plataforma resuelve algo distinto, falla su prueba.
 */
class LiveConformanceTest {
    private val casos = JSONObject(File("../doc/contract/conformance.json").readText())

    private fun lista(k: String): List<JSONObject> {
        val a: JSONArray = casos.getJSONArray(k)
        return (0 until a.length()).map { a.getJSONObject(it) }
    }

    @Test
    fun `las plantillas campo se resuelven igual`() {
        val fallos = lista("format").mapNotNull { c ->
            val state = LiveJson.state(c.getJSONObject("state"))
            val got = LiveJson.format(c.getString("fmt"), state)
            if (got == c.getString("expect")) null else "${c.getString("nombre")}: esperaba «${c.getString("expect")}» y dio «$got»"
        }
        assertTrue(fallos.isEmpty(), fallos.joinToString("\n"))
    }

    @Test
    fun `las condiciones se evaluan igual`() {
        val fallos = lista("condition").mapNotNull { c ->
            val state = LiveJson.state(c.getJSONObject("state"))
            val got = CardLogic.condition(c.getJSONObject("cond"), state)
            if (got == c.getBoolean("expect")) null else "${c.getString("nombre")}: esperaba ${c.getBoolean("expect")} y dio $got"
        }
        assertTrue(fallos.isEmpty(), fallos.joinToString("\n"))
    }
}
