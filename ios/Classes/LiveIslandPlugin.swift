import Flutter
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

public class LiveIslandPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_island", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(LiveIslandPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "areEnabled", "requestPermission":
            result(LiveActivities.areEnabled())
        case "openPromotionSettings":
            result(false)
        case "start":
            LiveActivities.start(args, result)
        case "update":
            LiveActivities.update(args, result)
        case "end":
            LiveActivities.end(args, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private func fail(_ result: FlutterResult, _ code: String, _ message: String) {
    result(FlutterError(code: code, message: message, details: nil))
}

/// Puente con ActivityKit.
enum LiveActivities {
    static func areEnabled() -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) { return ActivityAuthorizationInfo().areActivitiesEnabled }
        #endif
        return false
    }

    // MARK: start

    static func start(_ args: [String: Any], _ result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else {
            return fail(result, "unsupported", "Las Live Activities requieren iOS 16.1 o superior.")
        }
        guard LiveStorage.appGroup != nil else {
            return fail(result, "not_configured",
                        "Falta el App Group. Ejecuta `dart run live_island:setup` y vuelve a compilar.")
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return fail(result, "disabled", "El usuario desactivó las Live Activities para esta app.")
        }
        guard let layoutText = args["layout"] as? String,
              var layout = (try? JSONSerialization.jsonObject(with: Data(layoutText.utf8))) as? [String: Any],
              let stateText = args["state"] as? String,
              let state = (try? JSONSerialization.jsonObject(with: Data(stateText.utf8))) as? [String: Any]
        else { return fail(result, "bad_arguments", "layout y state deben ser JSON válido.") }

        let layoutId = UUID().uuidString
        guard let dir = LiveStorage.directory(for: layoutId, create: true) else {
            return fail(result, "not_configured", "No se pudo abrir el App Group.")
        }

        // Imágenes: se reducen al tamaño con que se muestran y se copian al App Group.
        var manifest = layout["images"] as? [String: Any] ?? [:]
        for item in args["images"] as? [[String: Any]] ?? [] {
            guard let id = item["id"] as? String,
                  let bytes = item["bytes"] as? FlutterStandardTypedData,
                  let out = LiveImages.reduce(bytes.data,
                                              maxWidth: CGFloat((item["maxWidth"] as? NSNumber)?.doubleValue ?? 138),
                                              maxHeight: CGFloat((item["maxHeight"] as? NSNumber)?.doubleValue ?? 138))
            else { continue }
            let file = "\(id).png"
            try? out.png.write(to: dir.appendingPathComponent(file))
            manifest[id] = ["file": file, "w": out.width, "h": out.height]
        }
        if !manifest.isEmpty { layout["images"] = manifest }
        guard let layoutData = try? JSONSerialization.data(withJSONObject: layout),
              (try? layoutData.write(to: dir.appendingPathComponent("layout.json"))) != nil
        else { return fail(result, "storage", "No se pudo guardar el diseño en el App Group.") }

        // Limpia diseños de actividades que ya no existen.
        LiveStorage.removeAll(except: Set(Activity<LiveIslandAttributes>.activities.map { $0.attributes.layoutId } + [layoutId]))

        let attributes = LiveIslandAttributes(layoutId: layoutId, deepLink: args["deepLink"] as? String)
        let content = LiveIslandAttributes.ContentState(values: LiveValue.dictionary(from: state))
        let stale = (args["staleAfter"] as? NSNumber).map { Date().addingTimeInterval($0.doubleValue) }
        let relevance = (args["relevance"] as? NSNumber)?.doubleValue ?? 0

        do {
            let activity: Activity<LiveIslandAttributes>
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: content, staleDate: stale, relevanceScore: relevance),
                    pushType: nil)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: content, pushType: nil)
            }
            result(activity.id)
        } catch {
            LiveStorage.removeDirectory(for: layoutId)
            fail(result, "start_failed", "\(error)")
        }
        #else
        fail(result, "unsupported", "ActivityKit no está disponible.")
        #endif
    }

    // MARK: update / end

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private static func find(_ id: String) -> Activity<LiveIslandAttributes>? {
        Activity<LiveIslandAttributes>.activities.first { $0.id == id }
    }
    #endif

    static func update(_ args: [String: Any], _ result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return fail(result, "unsupported", "Requiere iOS 16.1.") }
        guard let id = args["id"] as? String, let activity = find(id) else {
            return fail(result, "not_found", "No existe una actividad con ese id (¿ya terminó?).")
        }
        guard let stateText = args["state"] as? String,
              let state = (try? JSONSerialization.jsonObject(with: Data(stateText.utf8))) as? [String: Any]
        else { return fail(result, "bad_arguments", "state debe ser JSON válido.") }

        // El estado que llega se mezcla con el anterior: solo viajan los campos que cambian.
        var values = activity.contentState.values
        for (k, v) in LiveValue.dictionary(from: state) { values[k] = v }
        let content = LiveIslandAttributes.ContentState(values: values)
        let stale = (args["staleAfter"] as? NSNumber).map { Date().addingTimeInterval($0.doubleValue) }
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: content, staleDate: stale))
            } else {
                await activity.update(using: content)
            }
            result(nil)
        }
        #else
        fail(result, "unsupported", "ActivityKit no está disponible.")
        #endif
    }

    static func end(_ args: [String: Any], _ result: @escaping FlutterResult) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return fail(result, "unsupported", "Requiere iOS 16.1.") }
        guard let id = args["id"] as? String, let activity = find(id) else { return result(nil) }
        let policy: ActivityUIDismissalPolicy
        let immediate = (args["dismiss"] as? String) == "immediate"
        switch args["dismiss"] as? String {
        case "immediate": policy = .immediate
        case "after":
            let secs = (args["dismissAfter"] as? NSNumber)?.doubleValue ?? 0
            policy = .after(Date().addingTimeInterval(secs))
        default: policy = .default
        }
        var values = activity.contentState.values
        if let stateText = args["state"] as? String,
           let state = (try? JSONSerialization.jsonObject(with: Data(stateText.utf8))) as? [String: Any] {
            for (k, v) in LiveValue.dictionary(from: state) { values[k] = v }
        }
        let content = LiveIslandAttributes.ContentState(values: values)
        let layoutId = activity.attributes.layoutId
        Task {
            if #available(iOS 16.2, *) {
                await activity.end(ActivityContent(state: content, staleDate: nil), dismissalPolicy: policy)
            } else {
                await activity.end(using: content, dismissalPolicy: policy)
            }
            // Si se cierra ya, el diseño no hace falta. Si no, se limpia en el próximo start().
            if immediate { LiveStorage.removeDirectory(for: layoutId) }
            result(nil)
        }
        #else
        fail(result, "unsupported", "ActivityKit no está disponible.")
        #endif
    }
}

enum LiveImages {
    /// Reduce la imagen para que quepa en [maxWidth] × [maxHeight] sin deformarla
    /// ni agrandarla. El Widget Extension tiene poca memoria (~30 MB).
    static func reduce(_ data: Data, maxWidth: CGFloat, maxHeight: CGFloat)
        -> (png: Data, width: Int, height: Int)? {
        guard let src = UIImage(data: data), src.size.width > 0, src.size.height > 0 else { return nil }
        // `size` está en puntos; con scale 1 equivale a píxeles.
        let px = CGSize(width: src.size.width * src.scale, height: src.size.height * src.scale)
        let k = min(maxWidth / px.width, maxHeight / px.height, 1)
        let target = CGSize(width: max(1, (px.width * k).rounded()), height: max(1, (px.height * k).rounded()))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let img = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            src.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let png = img.pngData() else { return nil }
        return (png, Int(target.width), Int(target.height))
    }
}
