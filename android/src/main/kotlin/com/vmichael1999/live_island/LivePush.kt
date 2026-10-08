package com.vmichael1999.live_island

import org.json.JSONObject

/** Lo que un push le pide a una actividad. */
sealed class PushCommand {
    /** Inicia una actividad con un diseño guardado antes con `registerLayout`. */
    data class Start(val template: String, val state: LiveState, val deepLink: String?) : PushCommand()

    /** Cambia solo los campos indicados del estado. */
    data class Update(val id: String, val state: LiveState) : PushCommand()

    data class End(val id: String, val state: LiveState?, val dismiss: String, val dismissAfterSeconds: Double) :
        PushCommand()
}

/**
 * Formato de los mensajes de FCM (ver `docs/push.md`). Los datos de FCM son
 * texto, así que todo viaja en el campo `live_island` como JSON:
 *
 * `{"event":"update","id":"…","state":{"progreso":0.8}}`
 *
 * También se aceptan los campos sueltos (`event`, `id`, `template`, `state` como
 * JSON en texto, `dismiss`, `dismissAfter`, `deepLink`).
 */
object LivePush {
    const val KEY = "live_island"

    /** `null` si el mensaje no es de live_island; lanza si lo es pero está mal formado. */
    fun parse(data: Map<String, String?>): PushCommand? {
        val root: JSONObject = data[KEY]?.let { JSONObject(it) }
            ?: if (data.containsKey("event")) JSONObject().also { o ->
                data.forEach { (k, v) ->
                    if (v != null) o.put(k, if (k == "state") JSONObject(v) else v)
                }
            } else return null

        val state = root.optJSONObject("state")?.let { LiveJson.state(it) }
        fun need(key: String) = root.optString(key).takeIf { it.isNotEmpty() }
            ?: throw IllegalArgumentException("Falta \"$key\" en el push de live_island.")

        return when (val event = need("event")) {
            "start" -> PushCommand.Start(need("template"), state ?: emptyMap(), root.optString("deepLink").ifEmpty { null })
            "update" -> PushCommand.Update(need("id"), state ?: throw IllegalArgumentException("Falta \"state\" en el push de live_island."))
            "end" -> PushCommand.End(need("id"), state, root.optString("dismiss", "default"), root.optDouble("dismissAfter", 0.0))
            else -> throw IllegalArgumentException("Evento desconocido en el push de live_island: $event")
        }
    }
}
