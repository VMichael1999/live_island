package com.vmichael1999.live_island

import org.json.JSONObject
import java.io.File
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Qué estilo, qué flags y si es promovible, sin necesitar Android. */
class LiveSpecTest {
    private fun example(name: String) =
        JSONObject(File("../docs/contract/examples/$name.layout.json").readText())

    private fun state(name: String) =
        LiveJson.state(JSONObject(File("../docs/contract/examples/$name.state.json").readText()))

    private fun layout(android: String, regions: String = "{}", extra: String = "") =
        JSONObject("""{"v":1,"theme":{"accent":"#1F6FEB"},"regions":$regions,"android":$android$extra}""")

    // --- taxi (completo) -----------------------------------------------------

    @Test
    fun `taxi se traduce a ProgressStyle con tramos, puntos, tracker y acciones`() {
        val spec = LiveSpec.from(example("taxi"), state("taxi"))

        assertEquals("Tu conductor está en camino", spec.title)
        assertEquals("Toyota Yaris gris · ABC-123 · Carlos M.", spec.text)
        assertTrue(spec.promotable)
        assertFalse(spec.colorized)
        assertEquals(0xFF1F6FEB.toInt(), spec.accent)

        // Cuenta regresiva: el chip y el encabezado salen del mismo cronómetro.
        val end = Instant.parse("2026-10-04T15:06:00Z").toEpochMilli()
        assertEquals(end, spec.countdownEnd)
        assertEquals(Chip.Countdown(end), spec.chip)

        // Tres etapas = dos tramos de 100, avance 0,45 y un punto por etapa.
        val p = spec.progress!!
        assertEquals(200, p.max)
        assertEquals(90, p.progress)
        assertEquals(listOf(100, 100), p.segments)
        assertEquals(listOf(0, 100, 200), p.points)
        assertEquals("Asignado", p.stage)
        assertEquals(p.stage, spec.subText)
        assertEquals(IconRef.Image("auto"), p.tracker)
        assertEquals(IconRef.Asset("assets/live/mappin.png"), p.end)
        assertNull(p.start)

        assertEquals(listOf("llamar", "compartir"), spec.actions.map { it.id })
        assertEquals(IconRef.Asset("assets/live/phone.png"), spec.actions[0].icon)

        assertEquals(IconRef.Initials("CM"), spec.largeIcon)
        assertEquals(IconRef.Image("logo_silueta"), spec.smallIcon)
    }

    @Test
    fun `el avance mueve el tracker y la etapa actual`() {
        val layout = example("taxi")
        fun at(v: Double) = LiveSpec.from(layout, LiveJson.merge(state("taxi"), mapOf("progreso" to v))).progress!!
        assertEquals(0, at(0.0).progress)
        assertEquals("En camino", at(0.5).stage)
        assertEquals(100, at(0.5).progress)
        assertEquals("Llegó", at(1.0).stage)
        assertEquals(200, at(1.0).progress)
        // Fuera de rango se acota.
        assertEquals(200, at(4.0).progress)
    }

    // --- marcador (sin barra, dato en texto) -----------------------------------

    @Test
    fun `un dato destacado de texto se agrega al titulo y el chip es texto`() {
        val spec = LiveSpec.from(example("score"), state("score"))
        assertEquals("Lima FC 2 – 1 Callao SC · 78'", spec.title)
        assertEquals(Chip.Text("2–1"), spec.chip)
        assertNull(spec.progress)
        assertNull(spec.countdownEnd)
        assertTrue(spec.actions.isEmpty())
        assertEquals(IconRef.Asset("assets/live/trophy.png"), spec.smallIcon)
        assertNull(spec.largeIcon)
    }

    // --- promoción -----------------------------------------------------------

    @Test
    fun `colorized impide la promocion`() {
        val l = layout("""{"title":{"text":"Hola"},"colorized":true}""")
        assertFalse(LiveSpec.from(l, emptyMap()).promotable)
    }

    @Test
    fun `sin titulo no se promueve`() {
        assertFalse(LiveSpec.from(layout("""{"title":{"bind":"t"}}"""), mapOf("t" to "")).promotable)
        assertFalse(LiveSpec.from(layout("{}"), emptyMap()).promotable)
        assertTrue(LiveSpec.from(layout("""{"title":{"bind":"t"}}"""), mapOf("t" to "Hola")).promotable)
    }

    // --- chip ---------------------------------------------------------------

    @Test
    fun `el chip sigue las reglas de 7, 12 caracteres`() {
        assertEquals(Chip.Text("B-027"), LiveSpec.chipFor("B-027"))
        assertEquals(Chip.Text("1234567"), LiveSpec.chipFor("1234567"))
        assertEquals(Chip.Text("123456…"), LiveSpec.chipFor("12345678"))
        assertEquals(Chip.Text("Llegan…"), LiveSpec.chipFor("Llegando ya"))
        assertEquals(Chip.IconOnly, LiveSpec.chipFor("1234567890123"))
        assertEquals(Chip.IconOnly, LiveSpec.chipFor(""))
        // Cuenta caracteres, no unidades UTF-16.
        assertEquals(Chip.Text("😀😀😀😀😀😀😀"), LiveSpec.chipFor("😀😀😀😀😀😀😀"))
    }

    @Test
    fun `el chip toma el texto de un campo del estado`() {
        val l = layout("""{"title":{"text":"T"},"chip":{"t":"text","text":"x","bind":"turno"}}""")
        assertEquals(Chip.Text("B-027"), LiveSpec.from(l, mapOf("turno" to "B-027")).chip)
    }

    @Test
    fun `sin chip o con chip de solo icono`() {
        assertEquals(Chip.None, LiveSpec.from(layout("""{"title":{"text":"T"}}"""), emptyMap()).chip)
        assertEquals(Chip.IconOnly,
            LiveSpec.from(layout("""{"title":{"text":"T"},"chip":{"t":"icon"}}"""), emptyMap()).chip)
    }

    // --- progreso -------------------------------------------------------------

    @Test
    fun `una barra es un solo tramo y sin puntos`() {
        val l = layout(
            """{"title":{"text":"T"}}""",
            """{"expanded":{"bottom":{"t":"col","c":[{"t":"bar","bind":"p"}]}}}""",
        )
        val p = LiveSpec.from(l, mapOf("p" to 0.4)).progress!!
        assertEquals(100, p.max)
        assertEquals(40, p.progress)
        assertEquals(listOf(100), p.segments)
        assertTrue(p.points.isEmpty())
        assertNull(p.stage)
    }

    @Test
    fun `el anillo se muestra como barra`() {
        val l = layout(
            """{"title":{"text":"T"}}""",
            """{"expanded":{"trailing":{"t":"ring","bind":"p","size":46}}}""",
        )
        val p = LiveSpec.from(l, mapOf("p" to 0.35)).progress!!
        assertEquals(listOf(100), p.segments)
        assertEquals(35, p.progress)
    }

    @Test
    fun `con mas de tres etapas la etapa actual va al encabezado`() {
        val l = layout(
            """{"title":{"text":"T"}}""",
            """{"expanded":{"bottom":{"t":"segments","bind":"p","labels":["Confirmado","Preparando","En camino","Entregado"],"points":true}}}""",
        )
        val p = LiveSpec.from(l, mapOf("p" to 0.62)).progress!!
        assertEquals(300, p.max)
        // 62 % con cuatro etapas: la segunda ("Paso 2 de 4" en el HTML).
        assertEquals("Preparando", p.stage)
        assertEquals(listOf(0, 100, 200, 300), p.points)
    }

    @Test
    fun `el progreso de android tiene prioridad sobre el de la isla`() {
        val l = layout(
            """{"title":{"text":"T"},"progress":{"t":"bar","bind":"a"}}""",
            """{"expanded":{"bottom":{"t":"bar","bind":"b"}}}""",
        )
        assertEquals(10, LiveSpec.from(l, mapOf("a" to 0.1, "b" to 0.9)).progress!!.progress)
    }

    @Test
    fun `el estilo de la barra da color a los tramos y a los puntos`() {
        val l = layout(
            """{"title":{"text":"T"}}""",
            """{"expanded":{"bottom":{"t":"segments","bind":"p","labels":["a","b","c"],"points":true,
                "style":{"color":"#C62828","pointColor":"#2E7D32","h":12,"gap":8,"labelSize":14}}}}""",
        )
        val p = LiveSpec.from(l, mapOf("p" to 0.5)).progress!!
        assertEquals(0xFFC62828.toInt(), p.color)
        assertEquals(0xFF2E7D32.toInt(), p.pointColor)
        // El grosor, el espacio y las etiquetas los decide Android: no cambian los tramos.
        assertEquals(listOf(100, 100), p.segments)
    }

    @Test
    fun `sin estilo los tramos usan el acento`() {
        val p = LiveSpec.from(example("taxi"), state("taxi")).progress!!
        assertNull(p.color)
        assertNull(p.pointColor)
    }

    @Test
    fun `sin puntos, sin marcador final y sin tracker no hay nada que dibujar`() {
        val l = layout(
            """{"title":{"text":"T"}}""",
            """{"expanded":{"bottom":{"t":"segments","bind":"p","labels":["a","b","c"],"showLabels":false}}}""",
        )
        val p = LiveSpec.from(l, mapOf("p" to 0.5)).progress!!
        assertTrue(p.points.isEmpty())
        assertNull(p.tracker)
        assertNull(p.end)
        assertNull(p.start)
    }

    // --- acciones y texto -----------------------------------------------------

    @Test
    fun `como maximo tres acciones`() {
        val buttons = (1..5).joinToString(",") { """{"t":"button","id":"b$it","label":"B$it"}""" }
        val l = layout("""{"title":{"text":"T"}}""", """{"expanded":{"bottom":{"t":"row","c":[$buttons]}}}""")
        assertEquals(listOf("b1", "b2", "b3"), LiveSpec.from(l, emptyMap()).actions.map { it.id })
    }

    @Test
    fun `las acciones de android reemplazan a los botones de la isla`() {
        val l = layout(
            """{"title":{"text":"T"},"actions":[{"t":"button","id":"solo","label":"Solo"}]}""",
            """{"expanded":{"bottom":{"t":"button","id":"otro","label":"Otro"}}}""",
        )
        assertEquals(listOf("solo"), LiveSpec.from(l, emptyMap()).actions.map { it.id })
    }

    @Test
    fun `la plantilla de texto sustituye los campos`() {
        val l = layout("""{"title":{"fmt":"{a} · {b}"}}""")
        assertEquals("x · 2", LiveSpec.from(l, mapOf("a" to "x", "b" to 2.0)).title)
    }

    // --- utilidades -------------------------------------------------------------

    @Test
    fun `LiveJson convierte numeros, fechas y mezcla estados`() {
        assertEquals("2", LiveJson.text(2.0))
        assertEquals("0.5", LiveJson.text(0.5))
        assertEquals("", LiveJson.text(null))
        assertEquals(1764000000000, LiveJson.date("2025-11-24T16:00:00.000Z"))
        assertNull(LiveJson.date("no es fecha"))
        assertEquals(mapOf("a" to 2, "b" to 3), LiveJson.merge(mapOf("a" to 1, "b" to 3), mapOf("a" to 2)))
    }

    @Test
    fun `parseColor acepta RRGGBB y RRGGBBAA`() {
        assertEquals(0xFF1F6FEB.toInt(), LiveSpec.parseColor("#1F6FEB"))
        assertEquals(0x801F6FEB.toInt(), LiveSpec.parseColor("#1F6FEB80"))
    }
}
