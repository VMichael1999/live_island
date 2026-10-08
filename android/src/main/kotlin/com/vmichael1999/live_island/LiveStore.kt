package com.vmichael1999.live_island

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import org.json.JSONObject
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Datos que se guardan de cada actividad (para reconstruir la notificación). */
data class StoredActivity(
    val id: String,
    val notificationId: Int,
    val layout: JSONObject,
    val state: LiveState,
    val deepLink: String?,
    val dismissed: Boolean,
)

/**
 * Guarda en disco el diseño, el estado y las imágenes de cada actividad:
 * `filesDir/live_island/<id>/`. Así una actualización (o un push) puede
 * reconstruir la notificación aunque el proceso se haya reiniciado.
 */
class LiveStore(private val context: Context) {
    private val root get() = File(context.filesDir, "live_island")
    private fun dir(id: String) = File(root, id)

    fun create(id: String, notificationId: Int, layout: JSONObject, state: LiveState, deepLink: String?) {
        val d = dir(id).apply { mkdirs() }
        File(d, "layout.json").writeText(layout.toString())
        File(d, "meta.json").writeText(
            JSONObject().put("notificationId", notificationId).put("deepLink", deepLink ?: JSONObject.NULL)
                .put("dismissed", false).toString(),
        )
        saveState(id, state)
    }

    fun saveState(id: String, state: LiveState) {
        File(dir(id), "state.json").writeText(JSONObject(state.mapValues { it.value ?: JSONObject.NULL }).toString())
    }

    fun load(id: String): StoredActivity? {
        val d = dir(id)
        if (!d.isDirectory) return null
        return try {
            val meta = JSONObject(File(d, "meta.json").readText())
            StoredActivity(
                id = id,
                notificationId = meta.getInt("notificationId"),
                layout = JSONObject(File(d, "layout.json").readText()),
                state = LiveJson.state(JSONObject(File(d, "state.json").readText())),
                deepLink = if (meta.isNull("deepLink")) null else meta.getString("deepLink"),
                dismissed = meta.optBoolean("dismissed", false),
            )
        } catch (_: Exception) {
            null
        }
    }

    fun markDismissed(id: String) {
        val f = File(dir(id), "meta.json")
        if (!f.exists()) return
        f.writeText(JSONObject(f.readText()).put("dismissed", true).toString())
    }

    fun delete(id: String) {
        dir(id).deleteRecursively()
    }

    /** Ids de todas las actividades guardadas. */
    fun allIds(): List<String> = root.listFiles()?.filter { it.isDirectory }?.map { it.name } ?: emptyList()

    /** Borra los diseños de actividades que ya no existen. */
    fun deleteAllExcept(keep: Set<String>) {
        root.listFiles()?.filter { it.name !in keep }?.forEach { it.deleteRecursively() }
    }

    // --- imágenes -----------------------------------------------------------

    private fun fileIn(d: File, key: String) = File(d, "img_" + key.replace(Regex("[^A-Za-z0-9]"), "_") + ".png")

    private fun fileFor(id: String, key: String) = fileIn(dir(id), key)

    // --- plantillas: diseños con nombre, para actividades que empiezan por push ---

    private val templates get() = File(context.filesDir, "live_island_templates")

    private fun templateDir(name: String) = File(templates, name.replace(Regex("[^A-Za-z0-9_-]"), "_"))

    /** Guarda (o reemplaza) la plantilla [name] con su diseño. */
    fun createTemplate(name: String, layout: JSONObject) {
        val d = templateDir(name)
        d.deleteRecursively()
        d.mkdirs()
        File(d, "layout.json").writeText(layout.toString())
    }

    fun saveTemplateImage(name: String, key: String, data: ByteArray, maxW: Int, maxH: Int) =
        writeImage(fileIn(templateDir(name), key), data, maxW, maxH)

    fun hasTemplate(name: String) = File(templateDir(name), "layout.json").exists()

    /** Crea la actividad [id] copiando el diseño y las imágenes de la plantilla [name]. */
    fun instantiate(name: String, id: String, notificationId: Int, state: LiveState, deepLink: String?): Boolean {
        val src = templateDir(name)
        if (!File(src, "layout.json").exists()) return false
        val layout = JSONObject(File(src, "layout.json").readText())
        create(id, notificationId, layout, state, deepLink)
        src.listFiles { f -> f.name.startsWith("img_") }?.forEach { it.copyTo(File(dir(id), it.name), overwrite = true) }
        return true
    }

    /** Reduce [data] para que quepa en [maxW] × [maxH] sin deformarla ni agrandarla y la guarda. */
    fun saveImage(id: String, key: String, data: ByteArray, maxW: Int, maxH: Int) =
        writeImage(fileFor(id, key), data, maxW, maxH)

    private fun writeImage(file: File, data: ByteArray, maxW: Int, maxH: Int) {
        val src = BitmapFactory.decodeByteArray(data, 0, data.size) ?: return
        val k = min(1.0, min(maxW.toDouble() / src.width, maxH.toDouble() / src.height))
        val w = max(1, (src.width * k).roundToInt())
        val h = max(1, (src.height * k).roundToInt())
        val out = if (w == src.width && h == src.height) src else Bitmap.createScaledBitmap(src, w, h, true)
        file.outputStream().use { out.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }

    /** Bitmap de una imagen o ícono del diseño, o de un avatar con iniciales. */
    fun bitmap(id: String, ref: IconRef, accent: Int): Bitmap? = when (ref) {
        is IconRef.Image -> decode(fileFor(id, ref.id))
        is IconRef.Asset -> decode(fileFor(id, ref.path))
        is IconRef.Initials -> initialsBitmap(ref.text, accent)
    }

    private fun decode(f: File): Bitmap? = if (f.exists()) BitmapFactory.decodeFile(f.path) else null

    companion object {
        /** Círculo de acento con iniciales blancas (ícono grande de un avatar sin foto). */
        fun initialsBitmap(text: String, accent: Int, size: Int = 138): Bitmap {
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val c = Canvas(bmp)
            val p = Paint(Paint.ANTI_ALIAS_FLAG)
            p.color = accent
            c.drawCircle(size / 2f, size / 2f, size / 2f, p)
            p.color = Color.WHITE
            p.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            p.textSize = size * 0.42f
            p.textAlign = Paint.Align.CENTER
            val y = size / 2f - (p.descent() + p.ascent()) / 2f
            c.drawText(text.ifEmpty { "?" }, size / 2f, y, p)
            return bmp
        }
    }
}
