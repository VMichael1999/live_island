package com.vmichael1999.live_island

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

/** Formato de los mensajes de FCM (docs/push.md). */
class LivePushTest {
    private fun cmd(json: String) = LivePush.parse(mapOf("live_island" to json))

    @Test
    fun `un push que no es de live_island se ignora`() {
        assertNull(LivePush.parse(mapOf("otro" to "dato")))
        assertNull(LivePush.parse(emptyMap()))
    }

    @Test
    fun `update lleva el id y solo los campos que cambian`() {
        val c = cmd("""{"event":"update","id":"abc","state":{"progreso":0.8,"nombre":"Ana"}}""")
        c as PushCommand.Update
        assertEquals("abc", c.id)
        assertEquals(0.8, LiveJson.number(c.state["progreso"]))
        assertEquals("Ana", c.state["nombre"])
        assertEquals(setOf("progreso", "nombre"), c.state.keys)
    }

    @Test
    fun `start usa un diseno registrado y puede llevar deep link`() {
        val c = cmd("""{"event":"start","template":"taxi","state":{"titulo":"Hola"},"deepLink":"miapp://viaje/1"}""")
        assertEquals(PushCommand.Start("taxi", mapOf("titulo" to "Hola"), "miapp://viaje/1"), c)
        val sin = cmd("""{"event":"start","template":"taxi"}""") as PushCommand.Start
        assertEquals(emptyMap(), sin.state)
        assertNull(sin.deepLink)
    }

    @Test
    fun `end admite estado final y politica de cierre`() {
        val c = cmd("""{"event":"end","id":"abc","state":{"titulo":"Llegó"},"dismiss":"after","dismissAfter":300}""")
        assertEquals(PushCommand.End("abc", mapOf("titulo" to "Llegó"), "after", 300.0), c)
        val d = cmd("""{"event":"end","id":"abc"}""") as PushCommand.End
        assertEquals("default", d.dismiss)
        assertNull(d.state)
    }

    @Test
    fun `tambien se aceptan los campos sueltos de FCM`() {
        val c = LivePush.parse(mapOf("event" to "update", "id" to "abc", "state" to """{"progreso":1}"""))
        assertEquals(PushCommand.Update("abc", mapOf("progreso" to 1)), c)
    }

    @Test
    fun `un push mal formado explica que falta`() {
        assertFailsWith<IllegalArgumentException> { cmd("""{"event":"update","state":{"a":1}}""") }
        assertFailsWith<IllegalArgumentException> { cmd("""{"event":"update","id":"abc"}""") }
        assertFailsWith<IllegalArgumentException> { cmd("""{"event":"start"}""") }
        assertFailsWith<IllegalArgumentException> { cmd("""{"event":"explotar","id":"x"}""") }
        assertFailsWith<IllegalArgumentException> { cmd("""{"id":"x"}""") }
    }
}
