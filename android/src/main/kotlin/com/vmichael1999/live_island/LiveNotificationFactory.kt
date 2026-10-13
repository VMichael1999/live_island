package com.vmichael1999.live_island

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle

/** Cómo termina una actividad que se deja visible un tiempo. */
data class EndInfo(val timeoutMillis: Long)

/** Cuenta de tiempos del fin programado (función pura, para poder probarla). */
object LiveTimeout {
    /** Milisegundos que faltan hasta [endAtMillis]; `null` si no hay fin o ya pasó. */
    fun remaining(endAtMillis: Long?, nowMillis: Long): Long? =
        endAtMillis?.let { it - nowMillis }?.takeIf { it > 0 }
}

/**
 * Convierte un [LiveSpec] en una `Notification` con estilos nativos: nunca
 * `RemoteViews`, para que Android 16+ la promueva a Live Update.
 */
class LiveNotificationFactory(private val context: Context, private val store: LiveStore) {

    fun ensureChannel() {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            // Importancia mayor que "mínima": requisito para promover a Live Update.
            NotificationChannel(CHANNEL_ID, "Actividades en vivo", NotificationManager.IMPORTANCE_DEFAULT).apply {
                setShowBadge(false)
                setSound(null, null)
            },
        )
    }

    private fun ensureAlertChannel() {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(ALERT_CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(ALERT_CHANNEL_ID, "Avisos de actividades en vivo", NotificationManager.IMPORTANCE_HIGH)
                .apply { setShowBadge(false) },
        )
    }

    fun build(
        activity: StoredActivity,
        spec: LiveSpec,
        end: EndInfo? = null,
        alert: Boolean = false,
    ): Notification {
        ensureChannel()
        if (alert) ensureAlertChannel()
        val id = activity.id
        // El aviso usa otro canal (con sonido): el sonido de un canal no se puede cambiar después.
        val b = Notification.Builder(context, if (alert) ALERT_CHANNEL_ID else CHANNEL_ID)

        // Íconos
        b.setSmallIcon(smallIcon(id, spec))
        spec.largeIcon?.let { store.bitmap(id, it, spec.accent) }?.let { b.setLargeIcon(it) }

        // Texto
        b.setContentTitle(spec.title).setContentText(spec.text)
        spec.subText?.let { b.setSubText(it) }
        b.setColor(spec.accent).setColorized(spec.colorized)
        // Con aviso vuelve a sonar y a salir como emergente; el resto de las actualizaciones, no.
        b.setOnlyAlertOnce(!alert)
        b.setOngoing(end == null)
        b.setCategory(Notification.CATEGORY_PROGRESS)
        if (end != null) {
            b.setTimeoutAfter(end.timeoutMillis)
        } else {
            // Fin programado: el sistema retira la notificación a esa hora, con la app abierta o no.
            LiveTimeout.remaining(activity.endAtMillis, System.currentTimeMillis())?.let { b.setTimeoutAfter(it) }
        }

        // Cuenta regresiva en el encabezado (y en el chip, si es de cuenta regresiva).
        spec.countdownEnd?.let {
            b.setWhen(it).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
        }

        // Intents
        b.setContentIntent(contentIntent(activity))
        b.setDeleteIntent(broadcast(activity, LiveActionReceiver.ACTION_DELETE, null, 0))
        spec.actions.forEachIndexed { i, a ->
            val icon = a.icon?.let { store.bitmap(id, it, spec.accent) }?.let { Icon.createWithBitmap(it) }
            // Respuesta en línea: el botón abre un cuadro de texto. El campo nativo
            // (RemoteInput) no se dibuja en la notificación de un Live Update.
            val pi = if (a.replyHint != null) replyIntent(activity, a, i + 1)
            else broadcast(activity, LiveActionReceiver.ACTION_BUTTON, a.id, i + 1)
            b.addAction(Notification.Action.Builder(icon, a.label, pi).build())
        }

        // Progreso
        val progress = spec.progress
        if (progress != null) {
            if (Build.VERSION.SDK_INT >= 36) {
                b.setStyle(progressStyle(id, spec, progress))
            } else {
                // Por debajo de Android 16: barra estándar, sin chip.
                b.setProgress(progress.max, progress.progress, false)
            }
        }

        if (Build.VERSION.SDK_INT >= 36 && end == null) {
            // Chip de la barra de estado: texto corto. El de cuenta regresiva sale del cronómetro.
            (spec.chip as? Chip.Text)?.let { b.setShortCriticalText(it.shown) }
            // Pide la promoción a Live Update (Notification.Builder#setRequestPromotedOngoing,
            // que en el SDK 36.1 solo escribe este extra).
            if (spec.promotable) {
                b.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true) })
            }
        }
        return b.build()
    }

    private fun smallIcon(id: String, spec: LiveSpec): Icon {
        val bmp = spec.smallIcon?.let { store.bitmap(id, it, spec.accent) }
        // Android pinta el ícono pequeño como silueta de un color (usa el canal alfa).
        return if (bmp != null) Icon.createWithBitmap(bmp)
        else Icon.createWithResource(context, context.applicationInfo.icon)
    }

    @android.annotation.SuppressLint("NewApi")
    private fun progressStyle(id: String, spec: LiveSpec, p: ProgressSpec): Notification.Style {
        val style = Notification.ProgressStyle().setStyledByProgress(true).setProgress(p.progress)
        val fill = p.color ?: spec.accent
        style.setProgressSegments(p.segments.map { Notification.ProgressStyle.Segment(it).setColor(fill) })
        if (p.points.isNotEmpty()) {
            val dot = p.pointColor ?: fill
            style.setProgressPoints(p.points.map { Notification.ProgressStyle.Point(it).setColor(dot) })
        }
        fun icon(ref: IconRef?) = ref?.let { store.bitmap(id, it, spec.accent) }?.let { Icon.createWithBitmap(it) }
        icon(p.tracker)?.let { style.setProgressTrackerIcon(it) }
        icon(p.start)?.let { style.setProgressStartIcon(it) }
        icon(p.end)?.let { style.setProgressEndIcon(it) }
        return style
    }

    private fun contentIntent(activity: StoredActivity): PendingIntent {
        val intent = activity.deepLink?.let {
            Intent(Intent.ACTION_VIEW, Uri.parse(it)).setPackage(context.packageName)
        } ?: context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: Intent()
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            context, activity.notificationId * 10, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Abre el cuadro de texto de un botón de respuesta en línea. */
    private fun replyIntent(activity: StoredActivity, a: ActionSpec, slot: Int): PendingIntent {
        val intent = Intent(context, LiveReplyActivity::class.java)
            .putExtra(LiveReplyActivity.EXTRA_BUTTON_ID, a.id)
            .putExtra(LiveReplyActivity.EXTRA_HINT, a.replyHint)
            .putExtra(LiveReplyActivity.EXTRA_TITLE, a.label)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
        return PendingIntent.getActivity(
            context, activity.notificationId * 10 + 1 + slot, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun broadcast(
        activity: StoredActivity,
        action: String,
        buttonId: String?,
        slot: Int,
    ): PendingIntent {
        val intent = Intent(context, LiveActionReceiver::class.java).setAction(action)
            .putExtra(LiveActionReceiver.EXTRA_ACTIVITY_ID, activity.id)
            .putExtra(LiveActionReceiver.EXTRA_BUTTON_ID, buttonId)
        return PendingIntent.getBroadcast(
            context, activity.notificationId * 10 + 1 + slot, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    companion object {
        const val CHANNEL_ID = "live_island"
        const val ALERT_CHANNEL_ID = "live_island_alerts"
        const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"
    }
}
