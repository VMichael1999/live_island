package com.vmichael1999.live_island

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.util.UUID
import kotlin.math.abs

/** Error con un código estable que llega a Dart como `LiveIslandException.code`. */
class LiveException(val code: String, message: String) : Exception(message)

/** Una imagen que envía Dart, ya con su límite de reducción. */
class ImagePayload(val id: String, val bytes: ByteArray, val maxWidth: Int, val maxHeight: Int)

/**
 * Las operaciones sobre actividades: las usan el canal de métodos y los push
 * (`LiveIslandPush`), así que ambos hacen exactamente lo mismo.
 */
class LiveActivities(private val context: Context) {
    val store = LiveStore(context)
    private val factory = LiveNotificationFactory(context, store)
    private val nm get() = context.getSystemService(NotificationManager::class.java)

    /** Notificaciones permitidas y, en Android 16+, promovidas. */
    fun areEnabled(): Boolean {
        if (!nm.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 36 || nm.canPostPromotedNotifications()
    }

    private fun requireNotifications() {
        if (!nm.areNotificationsEnabled()) {
            throw LiveException(
                "disabled",
                "El usuario desactivó las notificaciones de esta app. Pide el permiso con LiveIsland.requestPermission().",
            )
        }
    }

    /** Ids de las actividades cuya notificación sigue visible. */
    fun activeIds(): List<String> {
        val active = nm.activeNotifications.map { it.id }.toSet()
        return store.allIds().filter { store.load(it)?.notificationId in active }
    }

    private fun newIds(): Pair<String, Int> {
        val id = UUID.randomUUID().toString()
        return id to abs(id.hashCode() % 1_000_000) + 1000
    }

    fun registerLayout(name: String, layout: JSONObject, images: List<ImagePayload>) {
        store.createTemplate(name, layout)
        images.forEach { store.saveTemplateImage(name, it.id, it.bytes, it.maxWidth, it.maxHeight) }
    }

    fun start(layout: JSONObject, state: LiveState, deepLink: String?, images: List<ImagePayload>): String {
        requireNotifications()
        val (id, notificationId) = newIds()
        store.create(id, notificationId, layout, state, deepLink)
        images.forEach { store.saveImage(id, it.id, it.bytes, it.maxWidth, it.maxHeight) }
        cleanup(id)
        post(store.load(id)!!)
        return id
    }

    /** Inicia una actividad con un diseño guardado con [registerLayout]. */
    fun startFromTemplate(template: String, state: LiveState, deepLink: String?): String {
        requireNotifications()
        val (id, notificationId) = newIds()
        if (!store.instantiate(template, id, notificationId, state, deepLink)) {
            throw LiveException("template_not_found", "No hay un diseño registrado con el nombre \"$template\". Llama a LiveIsland.registerLayout.")
        }
        cleanup(id)
        post(store.load(id)!!)
        return id
    }

    /** Limpia lo que quedó de actividades que ya no tienen notificación. */
    private fun cleanup(newId: String) {
        val active = nm.activeNotifications.map { it.id }.toSet()
        store.deleteAllExcept((listOf(newId) + store.allIds().filter { store.load(it)?.notificationId in active }).toSet())
    }

    private fun post(a: StoredActivity, end: EndInfo? = null) {
        nm.notify(a.notificationId, factory.build(a, LiveSpec.from(a.layout, a.state), end))
    }

    fun update(id: String, changes: LiveState) {
        val a = store.load(id) ?: throw LiveException("not_found", "No existe una actividad con ese id (¿ya terminó?).")
        if (a.dismissed) throw LiveException("dismissed", "El usuario cerró la notificación; no se vuelve a publicar.")
        val merged = LiveJson.merge(a.state, changes)
        store.saveState(id, merged)
        post(a.copy(state = merged))
    }

    fun end(id: String, changes: LiveState?, dismiss: String, afterSeconds: Double) {
        val a = store.load(id) ?: return
        val state = changes?.let { LiveJson.merge(a.state, it) } ?: a.state
        if (dismiss == "after") {
            // Se deja visible un tiempo con su último estado y luego desaparece.
            val ms = (afterSeconds * 1000).toLong()
            store.saveState(id, state)
            post(a.copy(state = state), EndInfo(ms))
            Handler(Looper.getMainLooper()).postDelayed({ store.delete(id) }, ms + 1000)
        } else {
            nm.cancel(a.notificationId)
            store.delete(id)
        }
    }

    /** Ejecuta un mensaje de FCM. Devuelve el id de la actividad afectada; `null` si no era de live_island. */
    fun handlePush(data: Map<String, String?>): String? = when (val cmd = LivePush.parse(data)) {
        null -> null
        is PushCommand.Start -> startFromTemplate(cmd.template, cmd.state, cmd.deepLink)
        is PushCommand.Update -> cmd.id.also { update(it, cmd.state) }
        is PushCommand.End -> cmd.id.also { end(it, cmd.state, cmd.dismiss, cmd.dismissAfterSeconds) }
    }
}
