package com.vmichael1999.live_island

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Recibe los toques en los botones de la notificación y el descarte por parte
 * del usuario (`setDeleteIntent`).
 */
class LiveActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val activityId = intent.getStringExtra(EXTRA_ACTIVITY_ID) ?: return
        when (intent.action) {
            // Si el usuario cierra la notificación no se vuelve a publicar.
            ACTION_DELETE -> LiveStore(context).markDismissed(activityId)
            ACTION_BUTTON -> intent.getStringExtra(EXTRA_BUTTON_ID)?.let { LiveIslandPlugin.deliverAction(context, it) }
        }
    }

    companion object {
        const val ACTION_DELETE = "com.vmichael1999.live_island.DELETE"
        const val ACTION_BUTTON = "com.vmichael1999.live_island.BUTTON"
        const val EXTRA_ACTIVITY_ID = "activityId"
        const val EXTRA_BUTTON_ID = "buttonId"
    }
}
