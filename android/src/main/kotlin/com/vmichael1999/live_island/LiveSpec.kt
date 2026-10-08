package com.vmichael1999.live_island

import org.json.JSONObject
import kotlin.math.floor
import kotlin.math.roundToInt

/** Una imagen o ícono que el traductor pide a la tienda. */
sealed class IconRef {
    /** Imagen propia del diseño (id en `layout.images`). */
    data class Image(val id: String) : IconRef()

    /** PNG de Android de un `LiveIcon` (ruta del asset). */
    data class Asset(val path: String) : IconRef()

    /** Círculo de acento con iniciales. */
    data class Initials(val text: String) : IconRef()
}

/** Lo que muestra el chip de la barra de estado. */
sealed class Chip {
    object None : Chip()

    /** Solo el ícono pequeño. */
    object IconOnly : Chip()

    /** Texto corto (`setShortCriticalText`). */
    data class Text(val shown: String) : Chip()

    /** Cuenta regresiva en vivo (cronómetro del sistema). */
    data class Countdown(val endMillis: Long) : Chip()
}

data class ActionSpec(val id: String, val label: String, val icon: IconRef?)

data class ProgressSpec(
    val max: Int,
    val progress: Int,
    /** Largo de cada tramo; suman [max]. */
    val segments: List<Int>,
    /** Posiciones de los puntos (de 0 a [max]). */
    val points: List<Int>,
    /** Etapa actual, para el encabezado. */
    val stage: String?,
    val tracker: IconRef?,
    val start: IconRef?,
    val end: IconRef?,
)

/**
 * La notificación de Android descrita sin clases de Android: es lo que prueban
 * los tests unitarios y lo que [LiveNotificationFactory] convierte en
 * `Notification`.
 */
data class LiveSpec(
    val title: String,
    val text: String,
    val subText: String?,
    val accent: Int,
    val colorized: Boolean,
    val chip: Chip,
    /** Fin de la cuenta regresiva, si el dato destacado es un contador. */
    val countdownEnd: Long?,
    val progress: ProgressSpec?,
    val actions: List<ActionSpec>,
    val largeIcon: IconRef?,
    /** Ícono pequeño; `null` = ícono de la app. */
    val smallIcon: IconRef?,
) {
    /**
     * Android solo promueve a Live Update si tiene título y no está
     * coloreada (docs/PROMPT.md §6).
     */
    val promotable: Boolean get() = !colorized && title.isNotEmpty()

    companion object {
        /** Máximo de acciones de una notificación. */
        const val MAX_ACTIONS = 3

        fun parseColor(hex: String): Int {
            val s = hex.removePrefix("#")
            val rgb = s.substring(0, 6).toLong(16).toInt()
            val a = if (s.length == 8) s.substring(6, 8).toInt(16) else 0xFF
            return (a shl 24) or rgb
        }

        /** Mismo criterio que `chipInfo` del HTML y que `check()` en Dart. */
        fun chipFor(text: String): Chip {
            val cps = text.codePoints().toArray()
            return when {
                text.isEmpty() || cps.size > 12 -> Chip.IconOnly
                cps.size > 7 -> Chip.Text(String(cps, 0, 6) + "…")
                else -> Chip.Text(text)
            }
        }

        fun from(layout: JSONObject, state: LiveState): LiveSpec {
            val theme = LiveJson.obj(layout, "theme")
            val accent = parseColor(LiveJson.str(theme, "accent") ?: "#1F6FEB")
            val regions = LiveJson.obj(layout, "regions")
            val android = LiveJson.obj(layout, "android")

            // Título: el de Android, más el dato destacado si es texto (no contador).
            val trailing = LiveJson.obj(regions, "compactTrailing")
            var title = textOf(LiveJson.obj(android, "title"), state)
            if (trailing != null && trailing.optString("t") == "text") {
                val hl = textOf(trailing, state)
                if (hl.isNotEmpty()) title = "$title · $hl"
            }
            val text = textOf(LiveJson.obj(android, "text"), state)

            // Cuenta regresiva del dato destacado.
            val countdownEnd =
                if (trailing?.optString("t") == "countdown") LiveJson.date(state[trailing.optString("bind")]) else null

            val chip = chipOf(LiveJson.obj(android, "chip"), state)

            val progressNode = LiveJson.obj(android, "progress")
                ?: LiveJson.expandedNodes(layout).firstOrNull { it.optString("t") in PROGRESS_TYPES }
            val progress = progressNode?.let { progressOf(it, state) }

            val actions = (
                if (android?.has("actions") == true) LiveJson.array(android, "actions")
                else LiveJson.expandedNodes(layout).filter { it.optString("t") == "button" }
                ).take(MAX_ACTIONS).map {
                ActionSpec(it.optString("id"), it.optString("label"), iconOf(LiveJson.obj(it, "icon")))
            }

            val leading = LiveJson.obj(LiveJson.obj(regions, "expanded"), "leading")
                ?: LiveJson.obj(regions, "compactLeading")
            val appLogo = LiveJson.obj(layout, "appLogo")
            val largeIcon: IconRef? = when {
                leading?.optString("t") == "avatar" -> avatarOf(leading, state)
                appLogo?.optString("t") == "image" -> IconRef.Image(appLogo.optString("img"))
                leading?.optString("t") == "image" -> IconRef.Image(leading.optString("img"))
                else -> null
            }

            // Ícono pequeño: silueta de un solo color (docs/PROMPT.md §5.1).
            val smallNode = LiveJson.obj(layout, "androidSmallIcon") ?: appLogo
            val smallIcon = iconOf(smallNode)

            return LiveSpec(
                title = title,
                text = text,
                subText = progress?.stage,
                accent = accent,
                colorized = android?.optBoolean("colorized", false) ?: false,
                chip = chip,
                countdownEnd = countdownEnd,
                progress = progress,
                actions = actions,
                largeIcon = largeIcon,
                smallIcon = smallIcon,
            )
        }

        private val PROGRESS_TYPES = setOf("bar", "ring", "segments")

        /** Texto de un nodo `text` o de un `{bind|fmt|text}` de Android. */
        fun textOf(node: JSONObject?, state: LiveState): String {
            if (node == null) return ""
            LiveJson.str(node, "fmt")?.let { return LiveJson.format(it, state) }
            LiveJson.str(node, "text")?.let { return it }
            LiveJson.str(node, "bind")?.let { return LiveJson.text(state[it]) }
            return ""
        }

        private fun chipOf(chip: JSONObject?, state: LiveState): Chip {
            if (chip == null) return Chip.None
            return when (chip.optString("t")) {
                "countdown" -> LiveJson.date(state[chip.optString("bind")])?.let { Chip.Countdown(it) } ?: Chip.IconOnly
                "text" -> chipFor(LiveJson.str(chip, "bind")?.let { LiveJson.text(state[it]) } ?: chip.optString("text"))
                else -> Chip.IconOnly
            }
        }

        private fun avatarOf(node: JSONObject, state: LiveState): IconRef {
            LiveJson.str(node, "img")?.let { return IconRef.Image(it) }
            val initials = LiveJson.str(node, "bind")?.let { LiveJson.text(state[it]) } ?: node.optString("text")
            return IconRef.Initials(initials)
        }

        fun iconOf(node: JSONObject?): IconRef? = when (node?.optString("t")) {
            "image" -> IconRef.Image(node.optString("img"))
            "icon" -> LiveJson.str(node, "android")?.let { IconRef.Asset(it) }
            else -> null
        }

        private fun progressOf(node: JSONObject, state: LiveState): ProgressSpec {
            val v = (LiveJson.number(state[node.optString("bind")]) ?: 0.0).coerceIn(0.0, 1.0)
            val labels = node.optJSONArray("labels")?.let { a -> (0 until a.length()).map { a.getString(it) } }
                ?: emptyList()
            val segmented = node.optString("t") == "segments" && labels.size > 1
            val n = if (segmented) labels.size - 1 else 1
            val max = SEGMENT * n
            val stage = if (segmented) labels[minOf(labels.size - 1, floor(v * (labels.size - 1) + 1e-6).toInt())] else null
            val points = if (segmented && node.optBoolean("points", false)) (0..n).map { it * SEGMENT } else emptyList()
            val tracker = LiveJson.obj(node, "tracker")
            return ProgressSpec(
                max = max,
                progress = (v * max).roundToInt(),
                segments = List(n) { SEGMENT },
                points = points,
                stage = stage,
                tracker = iconOf(LiveJson.obj(tracker, "visual")),
                start = iconOf(LiveJson.obj(node, "start")),
                end = iconOf(LiveJson.obj(node, "end")),
            )
        }

        private const val SEGMENT = 100
    }
}
