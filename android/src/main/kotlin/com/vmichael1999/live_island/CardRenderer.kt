package com.vmichael1999.live_island

import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.Gravity
import android.widget.RemoteViews
import org.json.JSONObject
import kotlin.math.roundToInt

/**
 * Dibuja el árbol de componentes del diseño como `RemoteViews` (estilo `card`):
 * filas, columnas, textos, imágenes, cajas y, como imagen, barras y gráficas.
 * Pide Android 12 (API 31): usa `setViewLayoutWidth` y `setColorStateList`.
 */
class CardRenderer(
    private val context: Context,
    private val store: LiveStore,
    private val activityId: String,
    private val accent: Int,
    private val state: LiveState,
    private val nowMillis: Long = System.currentTimeMillis(),
) {
    private val pkg = context.packageName
    private val density = context.resources.displayMetrics.density
    private val dark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    /** Color por defecto de un ícono sin color propio: se lee sobre el fondo del sistema. */
    private val inkColor get() = if (dark) 0xFFFFFFFF.toInt() else 0xDD000000.toInt()

    fun render(root: JSONObject): RemoteViews {
        val holder = RemoteViews(pkg, R.layout.live_island_card_col_fill)
        build(root, parentIsRow = false)?.let { holder.addView(R.id.live_island_box, it) }
        return holder
    }

    private fun px(pt: Double) = (pt * density).roundToInt()

    // ------------------------------------------------------------------ nodos

    private fun build(n: JSONObject, parentIsRow: Boolean): RemoteViews? = when (n.optString("t")) {
        "row" -> container(n, horizontal = true, parentIsRow)
        "col" -> container(n, horizontal = false, parentIsRow)
        "stack" -> stack(n)
        "padding" -> padding(n, parentIsRow)
        "box" -> box(n, parentIsRow)
        "if" -> (if (CardLogic.condition(n.optJSONObject("when"), state)) n.optJSONObject("then") else n.optJSONObject("else"))
            ?.let { build(it, parentIsRow) }
        "text", "countdown", "stopwatch", "relative" -> text(n)
        "metric" -> metric(n)
        "icon" -> icon(n)
        "image" -> image(n)
        "avatar" -> avatar(n)
        "bar", "segments" -> bitmapView(CardBitmaps.bar(n, state, accent, ::visualBitmap), fill = true)
        "split" -> bitmapView(CardBitmaps.split(n, state), fill = true)
        "spark" -> bitmapView(CardBitmaps.spark(n, state, accent), fill = true)
        "path" -> bitmapView(CardBitmaps.path(n, state, accent, ::visualBitmap), fill = true)
        "gauge" -> bitmapView(CardBitmaps.gauge(n, state, accent), fill = false)
        "ring" -> bitmapView(CardBitmaps.ring(n, state, accent), fill = false)
        // Los botones salen como acciones de la notificación, no dentro de la tarjeta.
        else -> null
    }

    private fun container(n: JSONObject, horizontal: Boolean, parentIsRow: Boolean): RemoteViews {
        val layout = when {
            horizontal && !parentIsRow -> R.layout.live_island_card_row
            horizontal -> R.layout.live_island_card_row_wrap
            !parentIsRow -> R.layout.live_island_card_col_fill
            else -> R.layout.live_island_card_col
        }
        val rv = RemoteViews(pkg, layout)
        val align = n.optString("align")
        val gravity = if (horizontal) {
            Gravity.START or when (align) { "start" -> Gravity.TOP; "end" -> Gravity.BOTTOM; else -> Gravity.CENTER_VERTICAL }
        } else {
            Gravity.TOP or when (align) { "center" -> Gravity.CENTER_HORIZONTAL; "end" -> Gravity.END; else -> Gravity.START }
        }
        rv.setInt(R.id.live_island_box, "setGravity", gravity)
        val gap = n.optDouble("gap", if (horizontal) 8.0 else 2.0)
        val items = LiveJson.array(n, "c")
        var first = true
        for (item in items) {
            if (item.optString("t") == "spacer") {
                // Con tamaño: un hueco fijo; sin tamaño: ocupa lo que sobra.
                if (item.has("size")) addGap(rv, horizontal, item.optDouble("size"))
                else rv.addView(R.id.live_island_box, RemoteViews(pkg, R.layout.live_island_card_spacer))
                first = false
                continue
            }
            val child = build(item, parentIsRow = horizontal) ?: continue
            if (!first && gap > 0) addGap(rv, horizontal, gap)
            rv.addView(R.id.live_island_box, child)
            first = false
        }
        return rv
    }

    private fun addGap(parent: RemoteViews, horizontal: Boolean, gapPt: Double) {
        val g = RemoteViews(pkg, R.layout.live_island_card_gap)
        if (Build.VERSION.SDK_INT >= 31) {
            if (horizontal) g.setViewLayoutWidth(R.id.live_island_gap, gapPt.toFloat(), TypedValue.COMPLEX_UNIT_DIP)
            else g.setViewLayoutHeight(R.id.live_island_gap, gapPt.toFloat(), TypedValue.COMPLEX_UNIT_DIP)
        }
        parent.addView(R.id.live_island_box, g)
    }

    private fun stack(n: JSONObject): RemoteViews {
        val rv = RemoteViews(pkg, R.layout.live_island_card_stack)
        for (c in LiveJson.array(n, "c")) build(c, parentIsRow = false)?.let { rv.addView(R.id.live_island_box, it) }
        return rv
    }

    private fun padding(n: JSONObject, parentIsRow: Boolean): RemoteViews {
        val rv = RemoteViews(pkg, if (parentIsRow) R.layout.live_island_card_col else R.layout.live_island_card_col_fill)
        val all = n.optDouble("all", 0.0)
        val h = n.optDouble("h", all)
        val v = n.optDouble("v", all)
        rv.setViewPadding(
            R.id.live_island_box,
            px(n.optDouble("left", h)), px(n.optDouble("top", v)),
            px(n.optDouble("right", h)), px(n.optDouble("bottom", v)),
        )
        n.optJSONObject("child")?.let { c -> build(c, parentIsRow)?.let { rv.addView(R.id.live_island_box, it) } }
        return rv
    }

    private fun box(n: JSONObject, parentIsRow: Boolean): RemoteViews {
        val fixed = n.has("size")
        val fill = !parentIsRow && !fixed
        val bucket = CardLogic.radiusBucket(if (n.has("radius")) n.optDouble("radius") else null)
        val color: Int? = LiveJson.str(n, "color")?.let { LiveSpec.parseColor(it) }
            ?: if (n.has("tint")) (accent and 0x00FFFFFF) or ((n.optDouble("tint") * 255).toInt() shl 24) else null
        val layout = if (color == null) {
            R.layout.live_island_card_box
        } else when (bucket) {
            8 -> if (fill) R.layout.live_island_card_box_fill_8 else R.layout.live_island_card_box_8
            16 -> if (fill) R.layout.live_island_card_box_fill_16 else R.layout.live_island_card_box_16
            20 -> if (fill) R.layout.live_island_card_box_fill_20 else R.layout.live_island_card_box_20
            28 -> if (fill) R.layout.live_island_card_box_fill_28 else R.layout.live_island_card_box_28
            99 -> if (fill) R.layout.live_island_card_box_fill_99 else R.layout.live_island_card_box_99
            else -> if (fill) R.layout.live_island_card_box_fill_12 else R.layout.live_island_card_box_12
        }
        val rv = RemoteViews(pkg, layout)
        if (color != null && Build.VERSION.SDK_INT >= 31) {
            rv.setColorStateList(R.id.live_island_box, "setBackgroundTintList", ColorStateList.valueOf(color))
        }
        if (fixed && Build.VERSION.SDK_INT >= 31) {
            val s = n.optDouble("size").toFloat()
            rv.setViewLayoutWidth(R.id.live_island_box, s, TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutHeight(R.id.live_island_box, s, TypedValue.COMPLEX_UNIT_DIP)
        }
        // Una caja que ocupa todo el ancho deja que su contenido también lo ocupe.
        n.optJSONObject("child")?.let { c -> build(c, parentIsRow = !fill)?.let { rv.addView(R.id.live_island_box, it) } }
        return rv
    }

    // ------------------------------------------------------------------ texto

    private fun text(n: JSONObject): RemoteViews {
        val t = n.optString("t")
        val size = n.optDouble("size", 15.0).toFloat()
        val muted = n.optBoolean("muted", false)
        val color: Int? = LiveJson.str(n, "color")?.let { LiveSpec.parseColor(it) }
            ?: if (n.optBoolean("accent", false)) accent else null
        val gravity = when (n.optString("align")) { "center" -> Gravity.CENTER_HORIZONTAL; "end" -> Gravity.END; else -> Gravity.START }

        if (t == "countdown" || t == "stopwatch") {
            val rv = RemoteViews(pkg, R.layout.live_island_card_chrono)
            val at = LiveJson.date(state[n.optString("bind")])
            if (at != null) {
                val base = SystemClock.elapsedRealtime() + (at - nowMillis)
                rv.setChronometer(R.id.live_island_chrono, if (t == "countdown") base else SystemClock.elapsedRealtime() - (nowMillis - at), null, true)
                rv.setChronometerCountDown(R.id.live_island_chrono, t == "countdown")
            }
            rv.setTextViewTextSize(R.id.live_island_chrono, TypedValue.COMPLEX_UNIT_SP, size)
            color?.let { rv.setTextColor(R.id.live_island_chrono, it) }
            return rv
        }

        val content = if (t == "relative") {
            LiveJson.date(state[n.optString("bind")])?.let { CardLogic.relative(it, nowMillis) } ?: ""
        } else CardLogic.textOf(n, state)
        val rv = RemoteViews(pkg, if (muted && color == null) R.layout.live_island_card_text_muted else R.layout.live_island_card_text)
        val span = SpannableString(content)
        val bold = CardLogic.isBold(if (n.has("w")) n.optInt("w") else null)
        val italic = n.optBoolean("i", false)
        if (bold || italic) {
            val style = when { bold && italic -> Typeface.BOLD_ITALIC; bold -> Typeface.BOLD; else -> Typeface.ITALIC }
            span.setSpan(StyleSpan(style), 0, span.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        span.setSpan(AbsoluteSizeSpan(size.roundToInt(), true), 0, span.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        color?.let { span.setSpan(ForegroundColorSpan(it), 0, span.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE) }
        rv.setTextViewText(R.id.live_island_text, span)
        rv.setInt(R.id.live_island_text, "setGravity", gravity)
        if (n.has("lines")) rv.setInt(R.id.live_island_text, "setMaxLines", n.optInt("lines"))
        return rv
    }

    private fun metric(n: JSONObject): RemoteViews {
        val v = LiveJson.text(state[n.optString("bind")])
        val unit = LiveJson.str(n, "unit")?.let { " $it" } ?: ""
        return text(JSONObject().put("t", "text").put("text", v + unit).put("size", 22).put("w", 700))
    }

    // ------------------------------------------------------------------ imágenes

    /** Bitmap de un ícono, imagen o avatar; [tint] lo pinta de blanco (sobre el círculo del tracker). */
    private fun visualBitmap(v: JSONObject?, tint: Boolean): Bitmap? {
        if (v == null) return null
        val bmp: Bitmap? = when (v.optString("t")) {
            "icon" -> LiveJson.str(v, "android")?.let { store.bitmap(activityId, IconRef.Asset(it), accent) }
            "image" -> store.bitmap(activityId, IconRef.Image(v.optString("img")), accent)
            "avatar" -> avatarBitmap(v, 120)
            else -> null
        }
        return if (bmp != null && tint && v.optString("t") == "icon") tinted(bmp, 0xFFFFFFFF.toInt()) else bmp
    }

    private fun tinted(b: Bitmap, color: Int): Bitmap {
        val out = Bitmap.createBitmap(b.width, b.height, Bitmap.Config.ARGB_8888)
        Canvas(out).drawBitmap(b, 0f, 0f, Paint(Paint.ANTI_ALIAS_FLAG).apply { colorFilter = PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN) })
        return out
    }

    private fun shaped(b: Bitmap, shape: String, sidePx: Int): Bitmap {
        val out = Bitmap.createBitmap(sidePx, sidePx, Bitmap.Config.ARGB_8888)
        val c = Canvas(out)
        val radius = when (shape) { "circle" -> sidePx / 2f; "square" -> sidePx * .12f; else -> sidePx * .26f }
        val scale = minOf(sidePx.toFloat() / b.width, sidePx.toFloat() / b.height)
        val w = b.width * scale
        val h = b.height * scale
        val rect = RectF((sidePx - w) / 2, (sidePx - h) / 2, (sidePx + w) / 2, (sidePx + h) / 2)
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        c.drawRoundRect(rect, radius, radius, p)
        p.xfermode = android.graphics.PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        c.drawBitmap(b, null, rect, p)
        return out
    }

    private fun avatarBitmap(n: JSONObject, sidePx: Int): Bitmap? {
        LiveJson.str(n, "img")?.let { id ->
            return store.bitmap(activityId, IconRef.Image(id), accent)?.let { shaped(it, "circle", sidePx) }
        }
        val initials = LiveJson.str(n, "bind")?.let { LiveJson.text(state[it]) } ?: n.optString("text")
        return LiveStore.initialsBitmap(initials, accent, sidePx)
    }

    private fun imageView(bmp: Bitmap, widthPt: Float?, heightPt: Float?, fill: Boolean = false): RemoteViews {
        val rv = RemoteViews(pkg, if (fill) R.layout.live_island_card_image_fill else R.layout.live_island_card_image)
        rv.setImageViewBitmap(R.id.live_island_image, bmp)
        if (Build.VERSION.SDK_INT >= 31) {
            widthPt?.let { rv.setViewLayoutWidth(R.id.live_island_image, it, TypedValue.COMPLEX_UNIT_DIP) }
            heightPt?.let { rv.setViewLayoutHeight(R.id.live_island_image, it, TypedValue.COMPLEX_UNIT_DIP) }
        }
        return rv
    }

    private fun bitmapView(bmp: Bitmap, fill: Boolean): RemoteViews =
        imageView(bmp, if (fill) null else bmp.width / CardBitmaps.PX, null, fill)

    private fun image(n: JSONObject): RemoteViews? {
        val src = store.bitmap(activityId, IconRef.Image(n.optString("img")), accent) ?: return null
        val fixedH = if (n.has("h")) n.optDouble("h").toFloat() else null
        if (fixedH != null) return imageView(src, null, fixedH)
        val size = n.optDouble("size", 24.0).toFloat()
        val shaped = shaped(src, n.optString("shape").ifEmpty { "rounded" }, px(size.toDouble()) * 2)
        return imageView(shaped, size, size)
    }

    private fun avatar(n: JSONObject): RemoteViews? {
        val size = n.optDouble("size", 22.0).toFloat()
        val bmp = avatarBitmap(n, px(size.toDouble()) * 2) ?: return null
        return imageView(bmp, size, size)
    }

    private fun icon(n: JSONObject): RemoteViews? {
        val path = LiveJson.str(n, "android") ?: return null
        val src = store.bitmap(activityId, IconRef.Asset(path), accent) ?: return null
        val color = LiveJson.str(n, "color")?.let { LiveSpec.parseColor(it) } ?: if (n.optBoolean("accent", false)) accent else inkColor
        val size = n.optDouble("size", 20.0).toFloat()
        return imageView(tinted(src, color), size, size)
    }
}
