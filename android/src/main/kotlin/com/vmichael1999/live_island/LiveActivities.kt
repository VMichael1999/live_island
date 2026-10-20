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
                "The user turned off notifications for this app. Ask for the permission with LiveIsland.requestPermission().",
            )
        }
    }

    /** Ids de las actividades cuya notificación sigue visible. */
    fun activeIds(): List<String> {
        val active = nm.activeNotifications.map { it.id }.toSet()
        return store.allIds().filter { store.load(it)?.notificationId in active }
    }

    /** Las actividades vivas con su id propio (`null` si no tienen). */
    fun activeInfos(): List<Map<String, Any?>> =
        activeIds().map { id -> mapOf("id" to id, "customId" to store.load(id)?.customId) }

    /** El id de la actividad viva con ese [customId], si existe. */
    fun findByCustomId(customId: String): String? =
        activeIds().firstOrNull { store.load(it)?.customId == customId }

    /** [ref] puede ser el id de la actividad o su id propio (los push usan cualquiera). */
    private fun resolve(ref: String): String =
        if (store.load(ref) != null) ref else findByCustomId(ref) ?: ref

    private fun newIds(): Pair<String, Int> {
        val id = UUID.randomUUID().toString()
        return id to abs(id.hashCode() % 1_000_000) + 1000
    }

    fun registerLayout(name: String, layout: JSONObject, images: List<ImagePayload>) {
        store.createTemplate(name, layout)
        images.forEach { store.saveTemplateImage(name, it.id, it.bytes, it.maxWidth, it.maxHeight) }
    }

    fun start(
        layout: JSONObject,
        state: LiveState,
        deepLink: String?,
        images: List<ImagePayload>,
        customId: String? = null,
    ): String {
        requireNotifications()
        // Con el mismo id propio no se crea otra: se actualiza la que ya existe.
        customId?.let { findByCustomId(it) }?.let { existing ->
            update(existing, state)
            return existing
        }
        val (id, notificationId) = newIds()
        store.create(id, notificationId, layout, state, deepLink, customId)
        images.forEach { store.saveImage(id, it.id, it.bytes, it.maxWidth, it.maxHeight) }
        cleanup(id)
        post(store.load(id)!!)
        return id
    }

    /** Inicia una actividad con un diseño guardado con [registerLayout]. */
    fun startFromTemplate(template: String, state: LiveState, deepLink: String?, customId: String? = null): String {
        requireNotifications()
        customId?.let { findByCustomId(it) }?.let { existing ->
            update(existing, state)
            return existing
        }
        val (id, notificationId) = newIds()
        if (!store.instantiate(template, id, notificationId, state, deepLink, customId)) {
            throw LiveException("template_not_found", "No design is registered with the name \"$template\". Call LiveIsland.registerLayout.")
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

    private fun post(a: StoredActivity, end: EndInfo? = null, alert: Boolean = false) {
        nm.notify(a.notificationId, factory.build(a, LiveSpec.from(a.layout, a.state), end, alert))
    }

    /** [alert] hace que esta actualización suene y salga como aviso emergente. */
    fun update(ref: String, changes: LiveState, alert: Boolean = false) {
        val id = resolve(ref)
        val a = store.load(id) ?: throw LiveException("not_found", "No activity exists with that id (did it already end?).")
        if (a.dismissed) throw LiveException("dismissed", "The user dismissed the notification; it is not posted again.")
        val merged = LiveJson.merge(a.state, changes)
        store.saveState(id, merged)
        post(a.copy(state = merged), alert = alert)
    }

    /** Termina todas las actividades vivas de la app. */
    fun endAll(dismiss: String = "immediate", afterSeconds: Double = 0.0) {
        activeIds().forEach { end(it, null, dismiss, afterSeconds) }
    }

    /**
     * Programa el fin: la notificación sigue viva y se puede actualizar, y el
     * sistema la retira a la hora indicada (`setTimeoutAfter`).
     */
    fun scheduleEnd(ref: String, afterSeconds: Double, changes: LiveState?) {
        val id = resolve(ref)
        val a = store.load(id) ?: throw LiveException("not_found", "No activity exists with that id (did it already end?).")
        val state = changes?.let { LiveJson.merge(a.state, it) } ?: a.state
        val endAt = System.currentTimeMillis() + (afterSeconds * 1000).toLong()
        store.saveState(id, state)
        store.saveEndAt(id, endAt)
        post(a.copy(state = state, endAtMillis = endAt))
        // Limpia lo guardado cuando la notificación ya se retiró.
        Handler(Looper.getMainLooper()).postDelayed({ if (id !in activeIds()) store.delete(id) }, (afterSeconds * 1000).toLong() + 2000)
    }

    fun end(ref: String, changes: LiveState?, dismiss: String, afterSeconds: Double) {
        val id = resolve(ref)
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
        is PushCommand.Start -> startFromTemplate(cmd.template, cmd.state, cmd.deepLink, cmd.customId)
        is PushCommand.Update -> cmd.id.also { update(it, cmd.state, cmd.alert) }
        is PushCommand.End -> cmd.id.also { end(it, cmd.state, cmd.dismiss, cmd.dismissAfterSeconds) }
    }
}
