import SwiftUI

/// Fondo sobre el que se dibuja un componente (igual que `LiveTone` en Dart).
enum LiveTone { case dark, light, accent }

struct LiveStyle {
    let tone: LiveTone
    let accent: Color
    var mutedAlpha: Double = 0.68

    var isLight: Bool { tone == .light }
    var isAccent: Bool { tone == .accent }

    var fg: Color { isLight ? Color(white: 0.067) : .white }
    var muted: Color { fg.opacity(mutedAlpha) }
    /// Color de lo marcado `accent`: blanco sobre fondo de acento.
    var accentOnSurface: Color { isAccent ? .white : accent }

    var trackBg: Color { isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.2) }
    var fill: Color { isAccent ? .white : accent }
    var trackerBg: Color { isAccent ? .white : accent }
    var trackerFg: Color { isAccent ? accent : .white }
    var endIcon: Color { isLight ? Color(white: 0.2) : .white }
    var pendingDot: Color { isLight ? .white : Color(white: 0.11) }
    var stageMuted: Color { isLight ? Color.black.opacity(0.55) : Color.white.opacity(0.6) }
    var stageStrong: Color { isLight ? Color(white: 0.067) : .white }

    /// Fondo y texto del botón [index] (0 = principal).
    func button(_ index: Int) -> (Color, Color) {
        if isAccent {
            return index == 0 ? (.white, accent) : (Color.white.opacity(0.22), .white)
        }
        if isLight {
            return index == 0 ? (accent, .white) : (Color.black.opacity(0.08), Color(white: 0.067))
        }
        return index == 0 ? (accent, .white) : (Color.white.opacity(0.14), .white)
    }
}

/// Todo lo que hace falta para dibujar un nodo.
final class LiveCtx {
    let doc: LiveLayoutDoc
    let values: [String: LiveValue]
    let style: LiveStyle
    /// `true` en la isla expandida: no dibuja botones. Tocar la isla siempre
    /// abre la app, así que ahí no tienen función (ver docs/design/DESVIACIONES.md).
    let island: Bool

    init(doc: LiveLayoutDoc, values: [String: LiveValue], style: LiveStyle, island: Bool = false) {
        self.doc = doc
        self.values = values
        self.style = style
        self.island = island
    }

    /// Posición del botón [id] entre los botones del diseño (0 = principal).
    /// Sale del orden del árbol, no de cuántas veces se dibuje: SwiftUI puede
    /// evaluar una vista varias veces.
    func buttonIndex(_ id: String?) -> Int {
        guard let id = id else { return 0 }
        return doc.buttonOrder.firstIndex(of: id) ?? 0
    }

    func text(of bind: String?) -> String { bind.flatMap { values[$0]?.text } ?? "" }

    /// Plantilla `{campo}`.
    func format(_ fmt: String) -> String {
        var out = ""
        var i = fmt.startIndex
        while i < fmt.endIndex {
            if fmt[i] == "{", let close = fmt[i...].firstIndex(of: "}") {
                let key = String(fmt[fmt.index(after: i)..<close])
                out += values[key]?.text ?? ""
                i = fmt.index(after: close)
            } else {
                out.append(fmt[i])
                i = fmt.index(after: i)
            }
        }
        return out
    }

    /// Evalúa `{bind, eq|neq|gt|gte|lt|lte|truthy}`.
    func evaluate(_ c: LNode) -> Bool {
        let v = values[c.string("bind") ?? ""] ?? .null
        if c.has("truthy") { return v.isTruthy }
        if let eq = c.d["eq"] { return Self.same(v, eq) }
        if let ne = c.d["neq"] { return !Self.same(v, ne) }
        guard let n = v.number else { return false }
        if let x = c.double("gt") { return n > x }
        if let x = c.double("gte") { return n >= x }
        if let x = c.double("lt") { return n < x }
        if let x = c.double("lte") { return n <= x }
        return false
    }

    private static func same(_ v: LiveValue, _ other: Any) -> Bool {
        if let n = other as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() { return v.number == n.doubleValue }
        if let n = other as? NSNumber { return v.isTruthy == n.boolValue }
        if let s = other as? String { return v.text == s }
        return false
    }
}
