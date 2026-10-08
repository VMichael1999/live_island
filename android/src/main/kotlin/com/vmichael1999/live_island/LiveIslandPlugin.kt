package com.vmichael1999.live_island

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.util.UUID
import kotlin.math.abs

/** Puente Dart ↔ notificaciones de Android (Live Updates en Android 16+). */
class LiveIslandPlugin :
    FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var actions: EventChannel
    private lateinit var context: Context
    private lateinit var store: LiveStore
    private lateinit var factory: LiveNotificationFactory
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: Result? = null

    private val nm get() = context.getSystemService(NotificationManager::class.java)

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        store = LiveStore(context)
        factory = LiveNotificationFactory(context, store)
        channel = MethodChannel(b.binaryMessenger, "live_island").also { it.setMethodCallHandler(this) }
        actions = EventChannel(b.binaryMessenger, "live_island/actions").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
                override fun onCancel(arguments: Any?) { sink = null }
            })
        }
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        actions.setStreamHandler(null)
        sink = null
    }

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        activity = b.activity
        binding = b
        b.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)
    override fun onDetachedFromActivity() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "areEnabled" -> result.success(areEnabled())
                "requestPermission" -> requestPermission(result)
                "openPromotionSettings" -> result.success(openPromotionSettings())
                "start" -> start(call, result)
                "update" -> update(call, result)
                "end" -> end(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message ?: e.toString(), null)
        }
    }

    // --- permisos ------------------------------------------------------------

    /** Notificaciones permitidas y, en Android 16+, promovidas. */
    private fun areEnabled(): Boolean {
        if (!nm.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 36 || nm.canPostPromotedNotifications()
    }

    private fun requestPermission(result: Result) {
        val granted = Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        val act = activity
        if (granted || act == null) return result.success(nm.areNotificationsEnabled())
        pendingPermission?.error("superseded", "Otra solicitud de permiso reemplazó a esta.", null)
        pendingPermission = result
        act.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(code: Int, perms: Array<out String>, results: IntArray): Boolean {
        if (code != REQUEST_NOTIFICATIONS) return false
        pendingPermission?.success(results.isNotEmpty() && results[0] == PackageManager.PERMISSION_GRANTED)
        pendingPermission = null
        return true
    }

    /** Ajustes de "notificaciones promovidas" (Android 16+); si no existen, los de notificaciones. */
    private fun openPromotionSettings(): Boolean {
        val pkg = context.packageName
        val candidates = if (Build.VERSION.SDK_INT >= 36) {
            listOf(Intent("android.settings.MANAGE_APP_PROMOTED_NOTIFICATIONS").setData(Uri.parse("package:$pkg")))
        } else emptyList()
        val fallback = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
        for (intent in candidates + fallback) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try { context.startActivity(intent); return Build.VERSION.SDK_INT >= 36 } catch (_: Exception) {}
        }
        return false
    }

    // --- actividades ---------------------------------------------------------

    private fun start(call: MethodCall, result: Result) {
        if (!nm.areNotificationsEnabled()) {
            return result.error("disabled", "El usuario desactivó las notificaciones de esta app. " +
                "Pide el permiso con LiveIsland.requestPermission().", null)
        }
        val layout = JSONObject(call.argument<String>("layout") ?: return result.error("bad_arguments", "Falta layout.", null))
        val state = LiveJson.state(JSONObject(call.argument<String>("state") ?: "{}"))
        val id = UUID.randomUUID().toString()
        val notificationId = abs(id.hashCode() % 1_000_000) + 1000

        store.create(id, notificationId, layout, state, call.argument<String>("deepLink"))
        for (img in call.argument<List<Map<String, Any?>>>("images") ?: emptyList()) {
            store.saveImage(
                id, img["id"] as String, img["bytes"] as ByteArray,
                (img["maxWidth"] as? Number)?.toInt() ?: 138, (img["maxHeight"] as? Number)?.toInt() ?: 138,
            )
        }
        // Limpia lo que quedó de actividades que ya no tienen notificación.
        val active = nm.activeNotifications.map { it.id }.toSet()
        store.deleteAllExcept(
            (listOf(id) + store.allIds().filter { store.load(it)?.notificationId in active }).toSet(),
        )
        post(store.load(id)!!)
        result.success(id)
    }

    private fun post(a: StoredActivity, end: EndInfo? = null) {
        val spec = LiveSpec.from(a.layout, a.state)
        nm.notify(a.notificationId, factory.build(a, spec, end))
    }

    private fun update(call: MethodCall, result: Result) {
        val id = call.argument<String>("id") ?: return result.error("bad_arguments", "Falta id.", null)
        val a = store.load(id) ?: return result.error("not_found", "No existe una actividad con ese id (¿ya terminó?).", null)
        if (a.dismissed) return result.error("dismissed", "El usuario cerró la notificación; no se vuelve a publicar.", null)
        val merged = LiveJson.merge(a.state, LiveJson.state(JSONObject(call.argument<String>("state") ?: "{}")))
        store.saveState(id, merged)
        post(a.copy(state = merged))
        result.success(null)
    }

    private fun end(call: MethodCall, result: Result) {
        val id = call.argument<String>("id") ?: return result.success(null)
        val a = store.load(id) ?: return result.success(null)
        val state = call.argument<String>("state")?.let { LiveJson.merge(a.state, LiveJson.state(JSONObject(it))) } ?: a.state
        when (call.argument<String>("dismiss")) {
            "after" -> {
                // Se deja visible un tiempo con su último estado y luego desaparece.
                val ms = ((call.argument<Number>("dismissAfter")?.toDouble() ?: 0.0) * 1000).toLong()
                store.saveState(id, state)
                post(a.copy(state = state), EndInfo(ms))
                Handler(Looper.getMainLooper()).postDelayed({ store.delete(id) }, ms + 1000)
            }
            else -> {
                nm.cancel(a.notificationId)
                store.delete(id)
            }
        }
        result.success(null)
    }

    companion object {
        private const val REQUEST_NOTIFICATIONS = 7301
        private var sink: EventChannel.EventSink? = null

        /** Reenvía a Dart el id de un botón tocado en la notificación. */
        fun emitAction(buttonId: String) {
            Handler(Looper.getMainLooper()).post { sink?.success(buttonId) }
        }
    }
}
