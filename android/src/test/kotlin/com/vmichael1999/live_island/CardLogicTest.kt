package com.vmichael1999.live_island

import org.json.JSONObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** La parte de la tarjeta (`style: card`) que no necesita Android. */
class CardLogicTest {
    private fun cond(json: String, state: LiveState) = CardLogic.condition(JSONObject(json), state)

    @Test
    fun `las condiciones comparan numeros y textos`() {
        assertTrue(cond("""{"bind":"etapa","eq":1}""", mapOf("etapa" to 1.0)))
        assertFalse(cond("""{"bind":"etapa","eq":1}""", mapOf("etapa" to 2.0)))
        assertTrue(cond("""{"bind":"e","eq":"listo"}""", mapOf("e" to "listo")))
        assertTrue(cond("""{"bind":"e","neq":"listo"}""", mapOf("e" to "x")))
        assertTrue(cond("""{"bind":"p","gt":0.5}""", mapOf("p" to 0.7)))
        assertFalse(cond("""{"bind":"p","lt":0.5}""", mapOf("p" to 0.7)))
        assertTrue(cond("""{"bind":"p","gte":0.7}""", mapOf("p" to 0.7)))
        assertTrue(cond("""{"bind":"p","lte":0.7}""", mapOf("p" to 0.7)))
        assertFalse(cond("""{"bind":"falta","gt":0}""", emptyMap()))
    }

    @Test
    fun `truthy distingue vacio, cero y falso`() {
        assertTrue(cond("""{"bind":"a","truthy":true}""", mapOf("a" to "x")))
        assertFalse(cond("""{"bind":"a","truthy":true}""", mapOf("a" to "")))
        assertFalse(cond("""{"bind":"a","truthy":true}""", mapOf("a" to 0.0)))
        assertFalse(cond("""{"bind":"a","truthy":true}""", mapOf("a" to false)))
        assertTrue(cond("""{"bind":"a","truthy":false}""", mapOf("a" to null)))
    }

    @Test
    fun `el texto sale del campo, del literal o de la plantilla`() {
        val state = mapOf("a" to "Lions", "n" to 3.0)
        assertEquals("Lions", CardLogic.textOf(JSONObject("""{"t":"text","bind":"a"}"""), state))
        assertEquals("Hola", CardLogic.textOf(JSONObject("""{"t":"text","text":"Hola"}"""), state))
        assertEquals("Lions 3", CardLogic.textOf(JSONObject("""{"t":"text","fmt":"{a} {n}"}"""), state))
    }

    @Test
    fun `el tiempo relativo habla en minutos`() {
        assertEquals("en 5 min", CardLogic.relative(5 * 60_000L + 1000, 0))
        assertEquals("hace 2 min", CardLogic.relative(0, 2 * 60_000L + 1000))
        assertEquals("ahora", CardLogic.relative(10_000, 0))
    }

    @Test
    fun `las esquinas se ajustan a las disponibles`() {
        assertEquals(12, CardLogic.radiusBucket(null))
        assertEquals(8, CardLogic.radiusBucket(6.0))
        assertEquals(16, CardLogic.radiusBucket(15.0))
        assertEquals(28, CardLogic.radiusBucket(30.0))
        assertEquals(99, CardLogic.radiusBucket(60.0))
    }

    @Test
    fun `el peso 600 o mas es negrita`() {
        assertTrue(CardLogic.isBold(600))
        assertTrue(CardLogic.isBold(800))
        assertFalse(CardLogic.isBold(500))
        assertFalse(CardLogic.isBold(null))
    }

    @Test
    fun `la serie de la grafica se lee del texto`() {
        assertEquals(listOf(10.0, 12.5, 11.0), CardBitmaps.parseSeries("10, 12.5,x,11"))
        assertEquals(emptyList(), CardBitmaps.parseSeries(null))
    }

    @Test
    fun `style card toma android card o la tarjeta de bloqueo propia`() {
        fun layout(android: String, lock: String = """{"t":"text","text":"bloqueo"}""") = JSONObject(
            """{"v":1,"theme":{"accent":"#1F6FEB"},"regions":{"lockScreen":$lock},"android":$android}""",
        )
        // Sin android.card usa la tarjeta de bloqueo.
        val a = LiveSpec.from(layout("""{"style":"card","title":{"text":"T"}}"""), emptyMap())
        assertNotNull(a.card)
        assertEquals("bloqueo", a.card!!.expanded.optString("text"))
        assertEquals(a.card!!.expanded, a.card!!.collapsed)
        // android.card y cardCollapsed mandan.
        val b = LiveSpec.from(
            layout("""{"style":"card","title":{"text":"T"},"card":{"t":"text","text":"grande"},"cardCollapsed":{"t":"text","text":"chica"}}"""),
            emptyMap(),
        )
        assertEquals("grande", b.card!!.expanded.optString("text"))
        assertEquals("chica", b.card!!.collapsed.optString("text"))
        // Sin style card no hay tarjeta; con {same:expanded} y sin android.card tampoco.
        assertNull(LiveSpec.from(layout("""{"title":{"text":"T"}}"""), emptyMap()).card)
        assertNull(LiveSpec.from(layout("""{"style":"card","title":{"text":"T"}}""", """{"same":"expanded"}"""), emptyMap()).card)
    }
}
