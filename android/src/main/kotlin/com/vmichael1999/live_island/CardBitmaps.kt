package com.vmichael1999.live_island

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.RectF
import org.json.JSONObject
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Dibujos de la tarjeta (`style: card`) que `RemoteViews` no puede hacer con
 * vistas: barras, anillos, gráficas, medidores y rutas. Se pintan en un
 * `Bitmap` de 340 pt de ancho (a 3 px por pt) que la tarjeta ajusta a su ancho.
 */
object CardBitmaps {
    const val PX = 3f
    const val WIDTH_PT = 340

    private fun paint(color: Int, style: Paint.Style = Paint.Style.FILL, stroke: Float = 0f) =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            this.style = style
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

    private fun style(node: JSONObject) = LiveJson.obj(node, "style")

    private fun color(o: JSONObject?, key: String, fallback: Int): Int =
        LiveJson.str(o, key)?.let { LiveSpec.parseColor(it) } ?: fallback

    private fun num(o: JSONObject?, key: String, fallback: Double): Double =
        if (o != null && o.has(key) && !o.isNull(key)) o.optDouble(key, fallback) else fallback

    private fun value(node: JSONObject, state: LiveState): Float =
        (LiveJson.number(state[node.optString("bind")]) ?: 0.0).coerceIn(0.0, 1.0).toFloat()

    private fun withAlpha(c: Int, a: Float): Int = (c and 0x00FFFFFF) or ((a * 255).toInt() shl 24)

    /** Posición `t` de una curva cuadrática de [p0] a [p2] con control [p1]. */
    private fun quad(p0: Pair<Float, Float>, p1: Pair<Float, Float>, p2: Pair<Float, Float>, t: Float): Pair<Float, Float> {
        val u = 1 - t
        return Pair(
            u * u * p0.first + 2 * u * t * p1.first + t * t * p2.first,
            u * u * p0.second + 2 * u * t * p1.second + t * t * p2.second,
        )
    }

    private fun dashed(c: Canvas, path: Path, p: Paint, dash: Float, gap: Float) {
        val m = PathMeasure(path, false)
        var d = 0f
        while (d < m.length) {
            val seg = Path()
            m.getSegment(d, min(d + dash, m.length), seg, true)
            c.drawPath(seg, p)
            d += dash + gap
        }
    }

    /** Ícono del extremo o del tracker, ya tintado y a [sizePt] de alto. */
    private fun scaled(b: Bitmap, heightPt: Float): Bitmap {
        val h = (heightPt * PX).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(b, max(1, b.width * h / b.height), h, true)
    }

    // ------------------------------------------------------------------ barra

    /** `bar` y `segments`: tramos, discontinua, puntos, marcadores, tracker e íconos de los extremos. */
    fun bar(node: JSONObject, state: LiveState, accent: Int, visual: (JSONObject?, Boolean) -> Bitmap?): Bitmap {
        val st = style(node)
        val h = num(st, "h", 6.0).toFloat()
        val fill = color(st, "color", accent)
        val track = color(st, "trackColor", 0x33808080)
        val radius = num(st, "radius", (h / 2).toDouble()).toFloat()
        val dashedTrack = st?.optBoolean("dashed", false) ?: false
        val gap = num(st, "gap", 4.0).toFloat()
        val pointSize = num(st, "pointSize", 10.0).toFloat()
        val v = value(node, state)

        val tracker = LiveJson.obj(node, "tracker")
        val trackerSize = num(st, "trackerSize", 26.0).toFloat()
        val trackerVisual = LiveJson.obj(tracker, "visual")
        val trackerImage = visual(trackerVisual, true)
        val bareTracker = tracker?.optString("background") == "none"
        val trackerH = if (tracker == null) 0f else if (bareTracker) num(tracker, "height", 24.0).toFloat() else trackerSize
        val start = visual(LiveJson.obj(node, "start"), false)?.let { scaled(it, 16f) }
        val end = visual(LiveJson.obj(node, "end"), false)?.let { scaled(it, 16f) }

        val endMarker = st?.optString("endMarker").orEmpty()
        // Íconos de etapa: gris mientras no llega la etapa y de color desde que llega.
        val stages = LiveJson.array(node, "stageIcons").map { s ->
            Pair(
                visual(LiveJson.obj(s, "pending"), false)?.let { scaled(it, pointSize) },
                visual(LiveJson.obj(s, "reached"), false)?.let { scaled(it, pointSize) },
            )
        }
        val heightPt = max(
            max(max(h, trackerH), if (start != null || end != null) 16f else h),
            max(if (endMarker.isEmpty()) 0f else pointSize, if (stages.isEmpty()) 0f else pointSize),
        ) + 2
        val bmp = Bitmap.createBitmap((WIDTH_PT * PX).toInt(), (heightPt * PX).toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val cy = bmp.height / 2f

        val inset = (trackerH / 2f) * PX
        var x0 = inset
        var x1 = bmp.width - inset
        if (start != null) { c.drawBitmap(start, x0, cy - start.height / 2f, null); x0 += start.width + 8 * PX }
        if (end != null) { x1 -= end.width + 8 * PX; c.drawBitmap(end, x1 + 8 * PX, cy - end.height / 2f, null) }
        // Con íconos de etapa, la mitad de cada extremo queda dentro del ancho.
        if (stages.isNotEmpty()) { x0 += pointSize * PX / 2; x1 -= pointSize * PX / 2 }

        // Con marcador final la barra termina donde empieza el marcador y el ícono
        // que avanza recorre hasta su centro.
        val mS = if (endMarker.isEmpty()) 0f else pointSize * PX
        val xTrack1 = x1 - mS
        val xTravel = x1 - mS / 2
        val vf = if (mS > 0f) min(1f, v * (xTravel - x0) / (xTrack1 - x0)) else v

        val labels = node.optJSONArray("labels")
        val segmented = node.optString("t") == "segments" && labels != null && labels.length() > 1
        val tracks = if (segmented) labels!!.length() - 1 else 1
        val gapPx = gap * PX
        // Con íconos de etapa los tramos terminan antes de cada ícono, también en los extremos.
        val edge = if (stages.isEmpty()) 0f else gapPx / 2
        val segW = (xTrack1 - x0 - edge * 2 - gapPx * (tracks - 1)) / tracks
        val hPx = h * PX
        for (i in 0 until tracks) {
            val sx = x0 + edge + i * (segW + gapPx)
            val f = if (segmented) ((vf - i.toFloat() / tracks) * tracks).coerceIn(0f, 1f) else vf
            val rect = RectF(sx, cy - hPx / 2, sx + segW, cy + hPx / 2)
            val r = radius * PX
            if (dashedTrack) {
                val done = sx + segW * f
                val line = Path().apply { moveTo(done, cy); lineTo(sx + segW, cy) }
                dashed(c, line, paint(track, Paint.Style.STROKE, hPx), max(hPx * 2.2f, 18f), max(hPx * 1.6f, 14f))
            } else {
                c.drawRoundRect(rect, r, r, paint(track))
            }
            if (f > 0f) c.drawRoundRect(RectF(sx, rect.top, sx + segW * f, rect.bottom), r, r, paint(fill))
        }

        // Puntos de etapa y marcadores
        val dotColor = color(st, "pointColor", fill)
        val shape = st?.optString("pointShape").orEmpty().ifEmpty { "circle" }
        val markerTexts = st?.optJSONArray("markerLabels")
        fun dot(px: Float, on: Boolean, sh: String = shape, label: String? = null) {
            val s = pointSize * PX
            val col = if (on) dotColor else track
            when (sh) {
                "target" -> {
                    val sw = s * .22f
                    c.drawCircle(px, cy, s / 2 - sw / 2, paint(col, Paint.Style.STROKE, sw))
                }
                "targetSquare" -> {
                    val sw = s * .22f
                    val r = s * .22f
                    c.drawRoundRect(RectF(px - s / 2 + sw / 2, cy - s / 2 + sw / 2, px + s / 2 - sw / 2, cy + s / 2 - sw / 2), r, r, paint(col, Paint.Style.STROKE, sw))
                }
                "ring" -> {
                    c.drawCircle(px, cy, s / 2, paint(withAlpha(col, .28f)))
                    c.drawCircle(px, cy, s * .22f, paint(col))
                }
                "square" -> c.drawRect(px - s / 2, cy - s / 2, px + s / 2, cy + s / 2, paint(col))
                "rounded" -> c.drawRoundRect(RectF(px - s / 2, cy - s / 2, px + s / 2, cy + s / 2), s / 3, s / 3, paint(col))
                else -> c.drawCircle(px, cy, s / 2, paint(col))
            }
            if (label != null) {
                val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFF111111.toInt()
                    textSize = pointSize * PX * .58f
                    typeface = Typeface.DEFAULT_BOLD
                    textAlign = Paint.Align.CENTER
                }
                c.drawText(label, px, cy + tp.textSize * .35f, tp)
            }
        }

        if (stages.isNotEmpty()) {
            stages.forEachIndexed { k, (pending, reached) ->
                val bm = if (k.toFloat() / tracks <= vf + 1e-6f) reached else pending
                if (bm != null) c.drawBitmap(bm, x0 + (xTrack1 - x0) * k / tracks - bm.width / 2f, cy - bm.height / 2f, null)
            }
        } else if (segmented && node.optBoolean("points", false)) {
            for (k in 0..tracks) dot(x0 + (xTrack1 - x0) * k / tracks, k.toFloat() / tracks <= vf + 1e-6f)
        }
        st?.optJSONArray("markers")?.let { a ->
            val ms = (0 until a.length()).map { a.getDouble(it).toFloat().coerceIn(0f, 1f) }.sorted()
            val next = ms.indexOfFirst { it > vf + 1e-6f }
            ms.forEachIndexed { i, m -> dot(x0 + (xTrack1 - x0) * m, next == -1 || i <= next, label = markerTexts?.optString(i)?.takeIf { it.isNotEmpty() }) }
        }
        if (mS > 0f) dot(xTrack1 + mS / 2, true, endMarker)

        // Ícono que avanza
        if (tracker != null) {
            val tx = x0 + (xTravel - x0) * v
            if (bareTracker) {
                trackerImage?.let { b -> scaled(b, trackerH).let { s -> c.drawBitmap(s, tx - s.width / 2f, cy - s.height / 2f, null) } }
            } else {
                val rr = trackerSize * PX / 2
                c.drawCircle(tx, cy + PX, rr, paint(0x59000000))
                c.drawCircle(tx, cy, rr, paint(fill))
                trackerImage?.let { b ->
                    val s = scaled(b, trackerSize * .58f)
                    c.drawBitmap(s, tx - s.width / 2f, cy - s.height / 2f, null)
                }
            }
        }
        return bmp
    }

    // ------------------------------------------------------------------ barra partida

    fun split(node: JSONObject, state: LiveState): Bitmap {
        val h = num(node, "h", 10.0).toFloat()
        val gap = num(node, "gap", 3.0).toFloat() * PX
        val r = num(node, "radius", (h / 2).toDouble()).toFloat() * PX
        val parts = LiveJson.array(node, "parts")
        val vals = parts.map { (LiveJson.number(state[it.optString("bind")]) ?: 0.0).coerceAtLeast(0.0) }
        val kept = parts.indices.filter { vals[it] > 0 }
        val bmp = Bitmap.createBitmap((WIDTH_PT * PX).toInt(), (h * PX).toInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val total = kept.sumOf { vals[it] }
        if (total <= 0) return bmp
        val room = bmp.width - gap * (kept.size - 1)
        var x = 0f
        for (i in kept) {
            val w = (room * (vals[i] / total)).toFloat()
            c.drawRoundRect(RectF(x, 0f, x + w, bmp.height.toFloat()), r, r, paint(color(parts[i], "color", 0xFFFFFFFF.toInt())))
            x += w + gap
        }
        return bmp
    }

    // ------------------------------------------------------------------ gráfica de línea

    fun spark(node: JSONObject, state: LiveState, accent: Int): Bitmap {
        val h = num(node, "h", 36.0).toFloat()
        val col = color(node, "color", accent)
        val lineW = num(node, "w", 2.0).toFloat() * PX
        val dot = node.optBoolean("dot", true)
        val fill = node.optBoolean("fill", true)
        val values = parseSeries(state[node.optString("bind")])
        val bmp = Bitmap.createBitmap((WIDTH_PT * PX).toInt(), (h * PX).toInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        if (values.size < 2) return bmp
        val c = Canvas(bmp)
        val lo = if (node.has("min")) node.optDouble("min") else values.min()
        var hi = if (node.has("max")) node.optDouble("max") else values.max()
        if (hi - lo < 1e-9) hi = lo + 1
        val pad = lineW + if (dot) 3.5f * PX else 0f
        val w = bmp.width - pad * 2
        val hh = bmp.height - pad * 2
        val pts = values.mapIndexed { i, v ->
            Pair(pad + w * i / (values.size - 1), pad + hh * (1 - ((v - lo) / (hi - lo)).coerceIn(0.0, 1.0)).toFloat())
        }
        val line = Path().apply {
            moveTo(pts[0].first, pts[0].second)
            for (i in 1 until pts.size) {
                val mx = (pts[i - 1].first + pts[i].first) / 2
                val my = (pts[i - 1].second + pts[i].second) / 2
                if (i == 1) lineTo(mx, my) else quadTo(pts[i - 1].first, pts[i - 1].second, mx, my)
            }
            lineTo(pts.last().first, pts.last().second)
        }
        if (fill) {
            val area = Path(line).apply { lineTo(pts.last().first, bmp.height.toFloat()); lineTo(pts[0].first, bmp.height.toFloat()); close() }
            c.drawPath(area, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = android.graphics.LinearGradient(0f, 0f, 0f, bmp.height.toFloat(), withAlpha(col, .35f), withAlpha(col, 0f), android.graphics.Shader.TileMode.CLAMP)
            })
        }
        c.drawPath(line, paint(col, Paint.Style.STROKE, lineW))
        if (dot) c.drawCircle(pts.last().first, pts.last().second, 3.5f * PX, paint(col))
        return bmp
    }

    fun parseSeries(raw: Any?): List<Double> =
        (raw as? String)?.split(',')?.mapNotNull { it.trim().toDoubleOrNull() } ?: emptyList()

    // ------------------------------------------------------------------ medidor, anillo y ruta

    fun gauge(node: JSONObject, state: LiveState, accent: Int): Bitmap {
        val st = style(node)
        val size = num(node, "size", 96.0).toFloat() * PX
        val sweep = num(node, "sweep", 180.0).coerceIn(90.0, 360.0).toFloat()
        val stroke = num(st, "h", 5.0).toFloat() * PX
        val fill = color(st, "color", accent)
        val track = color(st, "trackColor", 0x33808080)
        val knob = node.optBoolean("knob", true)
        val v = value(node, state)
        val pad = max(stroke / 2, if (knob) stroke * .9f else 0f) + PX
        val r = size / 2 - pad
        val half = sweep / 2
        val heightPx = (r * (1 - cos(half * PI / 180)) + pad * 2).toInt().coerceAtLeast(1)
        val bmp = Bitmap.createBitmap(size.toInt(), heightPx, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val oval = RectF(size / 2 - r, pad, size / 2 + r, pad + 2 * r)
        val startA = -90f - half
        val tp = paint(track, Paint.Style.STROKE, stroke)
        if (st?.optBoolean("dashed", false) == true) {
            dashed(c, Path().apply { addArc(oval, startA, sweep) }, tp, max(stroke * 1.4f, 15f), max(stroke * 1.2f, 12f))
        } else c.drawArc(oval, startA, sweep, false, tp)
        if (v > 0) c.drawArc(oval, startA, sweep * v, false, paint(fill, Paint.Style.STROKE, stroke))
        if (knob) {
            val a = (startA + sweep * v) * PI / 180
            c.drawCircle(size / 2 + (r * cos(a)).toFloat(), pad + r + (r * sin(a)).toFloat(), stroke * .9f, paint(fill))
        }
        return bmp
    }

    fun ring(node: JSONObject, state: LiveState, accent: Int): Bitmap {
        val st = style(node)
        val size = num(node, "size", 40.0).toFloat() * PX
        val stroke = num(st, "h", 3.0).toFloat() * PX
        val bmp = Bitmap.createBitmap(size.toInt(), size.toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val oval = RectF(stroke / 2, stroke / 2, size - stroke / 2, size - stroke / 2)
        c.drawArc(oval, 0f, 360f, false, paint(color(st, "trackColor", 0x33808080), Paint.Style.STROKE, stroke))
        c.drawArc(oval, -90f, 360f * value(node, state), false, paint(color(st, "color", accent), Paint.Style.STROKE, stroke))
        return bmp
    }

    fun path(node: JSONObject, state: LiveState, accent: Int, visual: (JSONObject?, Boolean) -> Bitmap?): Bitmap {
        val st = style(node)
        val h = num(node, "h", 44.0).toFloat()
        val curve = num(node, "curve", .55).coerceIn(0.0, 1.0).toFloat()
        val stroke = num(st, "h", 3.0).toFloat() * PX
        val fill = color(st, "color", accent)
        val track = color(st, "trackColor", 0x33808080)
        val dashedTrack = st?.let { if (it.has("dashed")) it.optBoolean("dashed") else true } ?: true
        val trackerSize = num(st, "trackerSize", 26.0).toFloat()
        val v = value(node, state)
        val bmp = Bitmap.createBitmap((WIDTH_PT * PX).toInt(), (h * PX).toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val inset = 14 * PX
        val p0 = Pair(inset, bmp.height - inset)
        val p2 = Pair(bmp.width - inset, bmp.height - inset)
        val p1 = Pair(bmp.width / 2f, p0.second - 2 * curve * (bmp.height - inset * 2))
        fun curvePath(a: Float, b: Float) = Path().apply {
            for (i in 0..48) {
                val q = quad(p0, p1, p2, a + (b - a) * i / 48)
                if (i == 0) moveTo(q.first, q.second) else lineTo(q.first, q.second)
            }
        }
        val rest = curvePath(v, 1f)
        if (dashedTrack) dashed(c, rest, paint(track, Paint.Style.STROKE, stroke), max(stroke * 2.2f, 18f), max(stroke * 1.8f, 15f))
        else c.drawPath(rest, paint(track, Paint.Style.STROKE, stroke))
        if (v > 0) c.drawPath(curvePath(0f, v), paint(fill, Paint.Style.STROKE, stroke))
        visual(LiveJson.obj(node, "start"), false)?.let { b -> scaled(b, 16f).let { c.drawBitmap(it, p0.first - it.width / 2f, p0.second - it.height / 2f, null) } }
        visual(LiveJson.obj(node, "end"), false)?.let { b -> scaled(b, 16f).let { c.drawBitmap(it, p2.first - it.width / 2f, p2.second - it.height / 2f, null) } }
        val tracker = LiveJson.obj(node, "tracker")
        if (tracker != null) {
            val at = quad(p0, p1, p2, v)
            val rr = trackerSize * PX / 2
            c.drawCircle(at.first, at.second + PX, rr, paint(0x59000000))
            c.drawCircle(at.first, at.second, rr, paint(fill))
            visual(LiveJson.obj(tracker, "visual"), true)?.let { b ->
                val s = scaled(b, trackerSize * .58f)
                c.drawBitmap(s, at.first - s.width / 2f, at.second - s.height / 2f, null)
            }
        }
        return bmp
    }
}
