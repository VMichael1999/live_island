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

    fun build(activity: StoredActivity, spec: LiveSpec, end: EndInfo? = null): Notification {
        ensureChannel()
        val id = activity.id
        val b = Notification.Builder(context, CHANNEL_ID)

        // Íconos
        b.setSmallIcon(smallIcon(id, spec))
        spec.largeIcon?.let { store.bitmap(id, it, spec.accent) }?.let { b.setLargeIcon(it) }

        // Texto
        b.setContentTitle(spec.title).setContentText(spec.text)
        spec.subText?.let { b.setSubText(it) }
        b.setColor(spec.accent).setColorized(spec.colorized)
        b.setOnlyAlertOnce(true)
        b.setOngoing(end == null)
        b.setCategory(Notification.CATEGORY_PROGRESS)
        if (end != null) b.setTimeoutAfter(end.timeoutMillis)

        // Cuenta regresiva en el encabezado (y en el chip, si es de cuenta regresiva).
        spec.countdownEnd?.let {
            b.setWhen(it).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
        }

        // Intents
        b.setContentIntent(contentIntent(activity))
        b.setDeleteIntent(broadcast(activity, LiveActionReceiver.ACTION_DELETE, null, 0))
        spec.actions.forEachIndexed { i, a ->
            val icon = a.icon?.let { store.bitmap(id, it, spec.accent) }?.let { Icon.createWithBitmap(it) }
            val pi = broadcast(activity, LiveActionReceiver.ACTION_BUTTON, a.id, i + 1)
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
        style.setProgressSegments(p.segments.map { Notification.ProgressStyle.Segment(it).setColor(spec.accent) })
        if (p.points.isNotEmpty()) {
            style.setProgressPoints(p.points.map { Notification.ProgressStyle.Point(it).setColor(spec.accent) })
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

    private fun broadcast(activity: StoredActivity, action: String, buttonId: String?, slot: Int): PendingIntent {
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
        const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"
    }
}
