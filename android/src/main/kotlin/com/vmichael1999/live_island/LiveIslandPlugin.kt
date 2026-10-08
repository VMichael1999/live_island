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

/** Puente Dart ↔ notificaciones de Android (Live Updates en Android 16+). */
class LiveIslandPlugin :
    FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var actions: EventChannel
    private lateinit var push: EventChannel
    private lateinit var context: Context
    private lateinit var live: LiveActivities
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: Result? = null

    private val nm get() = context.getSystemService(NotificationManager::class.java)

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        live = LiveActivities(context)
        channel = MethodChannel(b.binaryMessenger, "live_island").also { it.setMethodCallHandler(this) }
        actions = EventChannel(b.binaryMessenger, "live_island/actions").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    actionSink = events
                    // Las acciones que llegaron con la app cerrada se entregan ahora.
                    flushActions(context)
                }
                override fun onCancel(arguments: Any?) { actionSink = null }
            })
        }
        push = EventChannel(b.binaryMessenger, "live_island/push").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { pushSink = events }
                override fun onCancel(arguments: Any?) { pushSink = null }
            })
        }
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        actions.setStreamHandler(null)
        push.setStreamHandler(null)
        actionSink = null
        pushSink = null
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
                "areEnabled" -> result.success(live.areEnabled())
                "requestPermission" -> requestPermission(result)
                "activeActivities" -> result.success(live.activeIds())
                "openPromotionSettings" -> result.success(openPromotionSettings())
                "start" -> result.success(
                    live.start(
                        JSONObject(call.argument<String>("layout") ?: throw LiveException("bad_arguments", "Falta layout.")),
                        LiveJson.state(JSONObject(call.argument<String>("state") ?: "{}")),
                        call.argument<String>("deepLink"),
                        images(call),
                    ),
                )
                "registerLayout" -> {
                    live.registerLayout(
                        call.argument<String>("name") ?: throw LiveException("bad_arguments", "Falta name."),
                        JSONObject(call.argument<String>("layout") ?: throw LiveException("bad_arguments", "Falta layout.")),
                        images(call),
                    )
                    result.success(null)
                }
                "update" -> {
                    live.update(
                        call.argument<String>("id") ?: throw LiveException("bad_arguments", "Falta id."),
                        LiveJson.state(JSONObject(call.argument<String>("state") ?: "{}")),
                    )
                    result.success(null)
                }
                "end" -> {
                    live.end(
                        call.argument<String>("id") ?: return result.success(null),
                        call.argument<String>("state")?.let { LiveJson.state(JSONObject(it)) },
                        call.argument<String>("dismiss") ?: "default",
                        call.argument<Number>("dismissAfter")?.toDouble() ?: 0.0,
                    )
                    result.success(null)
                }
                "handlePush" -> {
                    val data = call.argument<Map<String, Any?>>("data") ?: emptyMap()
                    result.success(LiveIslandPush.handle(context, data.mapValues { it.value?.toString() }))
                }
                else -> result.notImplemented()
            }
        } catch (e: LiveException) {
            result.error(e.code, e.message, null)
        } catch (e: Exception) {
            result.error("failed", e.message ?: e.toString(), null)
        }
    }

    private fun images(call: MethodCall): List<ImagePayload> =
        (call.argument<List<Map<String, Any?>>>("images") ?: emptyList()).map {
            ImagePayload(
                it["id"] as String, it["bytes"] as ByteArray,
                (it["maxWidth"] as? Number)?.toInt() ?: 138, (it["maxHeight"] as? Number)?.toInt() ?: 138,
            )
        }

    // --- permisos ------------------------------------------------------------

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

    companion object {
        private const val REQUEST_NOTIFICATIONS = 7301
        private var actionSink: EventChannel.EventSink? = null
        private var pushSink: EventChannel.EventSink? = null
        private val main = Handler(Looper.getMainLooper())

        /** Un botón de la notificación fue tocado: se guarda y se entrega a Dart en cuanto escuche. */
        fun deliverAction(context: Context, buttonId: String) {
            LiveActionQueue(context.applicationContext).add(buttonId)
            flushActions(context.applicationContext)
        }

        private fun flushActions(context: Context) {
            main.post {
                val sink = actionSink ?: return@post
                LiveActionQueue(context).drain().forEach { sink.success(it) }
            }
        }

        /** Avisa a Dart de una actividad que empezó por push. */
        internal fun emitStarted(activityId: String) {
            main.post { pushSink?.success(mapOf("type" to "started", "activityId" to activityId)) }
        }
    }
}

/**
 * Punto de entrada para los push de FCM, sin depender de Firebase. Llámalo
 * desde el `FirebaseMessagingService` de tu app (o usa `LiveIsland.handlePush`
 * en Dart):
 *
 * ```kotlin
 * override fun onMessageReceived(message: RemoteMessage) {
 *     LiveIslandPush.handle(applicationContext, message.data)
 * }
 * ```
 */
object LiveIslandPush {
    /** Ejecuta el mensaje si es de live_island. Devuelve el id de la actividad afectada o `null`. */
    @JvmStatic
    fun handle(context: Context, data: Map<String, String?>): String? {
        val id = LiveActivities(context.applicationContext).handlePush(data)
        if (id != null && LivePush.parse(data) is PushCommand.Start) LiveIslandPlugin.emitStarted(id)
        return id
    }
}
