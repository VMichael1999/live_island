import SwiftUI
import UIKit

/// Dibuja un nodo del contrato. Es la implementación en SwiftUI de las reglas
/// de `docs/contract/README.md` (la referencia es la vista previa de Flutter).
enum LiveRenderer {
    /// [slot] es el tamaño de la zona donde va (íconos, imágenes y avatares sin
    /// `size`); [iconSize] el glifo si es un ícono.
    static func render(_ n: LNode, _ c: LiveCtx, slot: CGFloat? = nil, iconSize: CGFloat? = nil,
                       align: String? = nil, horizontal: Bool = false) -> AnyView {
        switch n.t {
        case "row": return row(n, c)
        case "col": return column(n, c)
        case "stack":
            return AnyView(ZStack(alignment: stackAlignment(n.string("align"))) {
                ForEach(Array(n.children.enumerated()), id: \.offset) { _, ch in render(ch, c) }
            })
        case "spacer":
            if let s = n.double("size") { return AnyView(Color.clear.frame(width: s, height: s)) }
            return AnyView(Spacer(minLength: 0))
        case "padding": return padding(n, c)
        case "box": return box(n, c)
        case "if":
            let branch = c.evaluate(n.node("when") ?? LNode(d: [:])) ? n.node("then") : n.node("else")
            guard let b = branch else { return AnyView(EmptyView()) }
            return render(b, c, slot: slot, iconSize: iconSize, align: align, horizontal: horizontal)
        case "text", "countdown", "stopwatch", "relative": return text(n, c, inherited: align)
        case "icon": return icon(n, c, size: n.double("size") ?? iconSize ?? slot ?? 20,
                                 color: iconColor(n, c))
        case "image": return image(n, c, size: n.double("size") ?? slot ?? 24)
        case "avatar": return avatar(n, c, size: n.double("size") ?? slot ?? 22)
        case "bar": return bar(n, c)
        case "ring": return ring(n, c, slot: slot)
        case "segments": return segments(n, c)
        case "metric": return metric(n, c)
        case "button" where c.island, "toggle" where c.island:
            return AnyView(EmptyView())
        case "button": return button(label: n.string("label") ?? "", icon: n.node("icon"), id: n.string("id"), c)
        case "toggle": return button(label: n.string("label") ?? n.string("id") ?? "", icon: n.node("icon"), id: n.string("id"), c)
        default: return AnyView(EmptyView())
        }
    }

    // MARK: estructura

    private static func vAlign(_ a: String?) -> VerticalAlignment {
        switch a { case "start": return .top; case "end": return .bottom; default: return .center }
    }

    private static func hAlign(_ a: String?) -> HorizontalAlignment {
        switch a { case "end": return .trailing; case "center": return .center; default: return .leading }
    }

    private static func stackAlignment(_ a: String?) -> Alignment {
        switch a { case "start": return .leading; case "end": return .trailing; default: return .center }
    }

    private static func row(_ n: LNode, _ c: LiveCtx) -> AnyView {
        let gap = n.double("gap") ?? 8
        let items = n.children
        // En la isla una fila solo de botones no se dibuja.
        if c.island, !items.isEmpty,
           items.allSatisfy({ $0.t == "button" || $0.t == "toggle" || $0.t == "spacer" }) {
            return AnyView(EmptyView())
        }
        return AnyView(HStack(alignment: vAlign(n.string("align")), spacing: gap) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, ch in
                render(ch, c, horizontal: true)
            }
        })
    }

    private static func column(_ n: LNode, _ c: LiveCtx) -> AnyView {
        let gap = n.double("gap") ?? 2
        let align = n.string("align")
        let items = n.children
        return AnyView(VStack(alignment: hAlign(align), spacing: gap) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, ch in
                render(ch, c, align: align)
            }
        })
    }

    private static func padding(_ n: LNode, _ c: LiveCtx) -> AnyView {
        guard let child = n.node("child") else { return AnyView(EmptyView()) }
        let all = n.double("all") ?? 0
        let h = n.double("h") ?? all, v = n.double("v") ?? all
        return AnyView(render(child, c).padding(EdgeInsets(
            top: n.double("top") ?? v, leading: n.double("left") ?? h,
            bottom: n.double("bottom") ?? v, trailing: n.double("right") ?? h)))
    }

    private static func box(_ n: LNode, _ c: LiveCtx) -> AnyView {
        let size = n.double("size")
        let radius = n.double("radius") ?? 0
        let fill: Color = n.string("color").map { Color(hex: $0) }
            ?? n.double("tint").map { c.style.accent.opacity($0) } ?? .clear
        let inner: AnyView = n.node("child").map {
            render($0, c, slot: size.map { $0 * 0.52 }, iconSize: size.map { $0 * 0.52 })
        } ?? AnyView(EmptyView())
        return AnyView(inner
            .frame(width: size.map { CGFloat($0) }, height: size.map { CGFloat($0) })
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill)))
    }

    // MARK: texto

    private static func weight(_ w: Int?) -> Font.Weight {
        switch w ?? 400 {
        case ..<150: return .ultraLight
        case ..<250: return .thin
        case ..<350: return .light
        case ..<450: return .regular
        case ..<550: return .medium
        case ..<650: return .semibold
        case ..<750: return .bold
        case ..<850: return .heavy
        default: return .black
        }
    }

    static func text(_ n: LNode, _ c: LiveCtx, inherited: String?) -> AnyView {
        let size = CGFloat(n.double("size") ?? 15)
        let counter = n.t == "countdown" || n.t == "stopwatch"
        let lines = n.int("lines") ?? 1
        let align = n.string("align") ?? inherited
        let color: Color = n.string("color").map { Color(hex: $0) }
            ?? (n.bool("accent") ? c.style.accentOnSurface : (n.bool("muted") ? c.style.muted : c.style.fg))
        let tabular = n.has("tabular") ? n.bool("tabular") : counter

        var view: Text
        var placeholder: String? = nil
        let date = c.values[n.string("bind") ?? ""]?.date
        switch n.t {
        case "countdown":
            if let end = date {
                let now = Date()
                view = Text(timerInterval: min(now, end)...end, pauseTime: nil, countsDown: true, showsHours: false)
                // Texto invisible del mismo ancho: el contador de SwiftUI ocupa todo
                // el ancho disponible y alargaba la isla.
                let minutes = Int(max(0, end.timeIntervalSince(now)) / 60)
                placeholder = String(repeating: "0", count: max(1, String(minutes).count)) + ":00"
            } else { view = Text("") }
        case "stopwatch":
            view = date.map { Text($0, style: .timer) } ?? Text("")
            placeholder = "00:00"
        case "relative":
            view = date.map { Text($0, style: .relative) } ?? Text("")
        default:
            if let fmt = n.string("fmt") { view = Text(c.format(fmt)) }
            else if let lit = n.string("text") { view = Text(lit) }
            else { view = Text(c.text(of: n.string("bind"))) }
        }

        func style(_ t: Text) -> Text {
            var out = t.font(.system(size: size, weight: weight(n.int("w")))).foregroundColor(color)
            if tabular { out = out.monospacedDigit() }
            return out
        }
        let textAlign: TextAlignment = align == "end" ? .trailing : (align == "center" ? .center : .leading)
        if let ph = placeholder {
            let frameAlign: Alignment = align == "end" ? .trailing : (align == "center" ? .center : .leading)
            return AnyView(style(Text(ph)).hidden()
                .overlay(style(view).lineLimit(1).multilineTextAlignment(textAlign), alignment: frameAlign)
                .fixedSize())
        }
        return AnyView(style(view)
            .lineLimit(lines)
            .multilineTextAlignment(textAlign)
            .fixedSize(horizontal: false, vertical: true))
    }

    // MARK: visuales

    private static func iconColor(_ n: LNode, _ c: LiveCtx) -> Color {
        if let hex = n.string("color") { return Color(hex: hex) }
        return n.bool("accent") ? c.style.accentOnSurface : c.style.fg
    }

    static func icon(_ n: LNode, _ c: LiveCtx, size: CGFloat, color: Color) -> AnyView {
        guard let sf = n.string("sf") else { return AnyView(EmptyView()) }
        return AnyView(Image(systemName: sf)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size))
    }

    static func image(_ n: LNode, _ c: LiveCtx, size: CGFloat, shape: String? = nil) -> AnyView {
        let s = shape ?? n.string("shape") ?? "rounded"
        let radius: CGFloat = s == "circle" ? size / 2 : (s == "square" ? size * 0.12 : (size * 0.26).rounded())
        guard let id = n.string("img"), let ui = c.doc.image(id) else {
            return AnyView(RoundedRectangle(cornerRadius: radius).fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size))
        }
        let cover = n.string("fit") == "cover"
        return AnyView(Image(uiImage: ui)
            .resizable()
            .aspectRatio(contentMode: cover ? .fill : .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous)))
    }

    static func avatar(_ n: LNode, _ c: LiveCtx, size: CGFloat, background: Color? = nil) -> AnyView {
        if let id = n.string("img"), c.doc.image(id) != nil {
            return image(LNode(d: ["t": "image", "img": id]), c, size: size, shape: "circle")
        }
        let initials = n.string("text") ?? c.text(of: n.string("bind"))
        return AnyView(Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: (size * 0.42).rounded(), weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(background ?? c.style.accent)))
    }

    // MARK: progreso

    private static func value(_ n: LNode, _ c: LiveCtx) -> Double {
        min(1, max(0, c.values[n.string("bind") ?? ""]?.number ?? 0))
    }

    private static func endView(_ n: LNode?, _ c: LiveCtx) -> AnyView? {
        guard let n = n else { return nil }
        switch n.t {
        case "icon": return icon(n, c, size: n.double("size") ?? 16, color: c.style.endIcon)
        case "image": return image(n, c, size: n.double("size") ?? 16)
        default: return nil
        }
    }

    private static func tracker(_ t: LNode?, _ c: LiveCtx, _ bs: BarStyle) -> AnyView? {
        guard let t = t, let v = t.node("visual") else { return nil }
        let st = c.style
        let size = bs.trackerSize ?? 26
        let k = size / 26
        func circle(_ inner: AnyView) -> AnyView {
            AnyView(inner
                .frame(width: size, height: size)
                .background(Circle().fill(bs.color ?? st.trackerBg))
                .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1))
        }
        if v.t == "icon" {
            return circle(icon(v, c, size: 15 * k, color: st.trackerFg))
        }
        if v.t == "image" {
            if (t.string("background") ?? "accentCircle") == "accentCircle" {
                return circle(image(v, c, size: 17 * k, shape: "square"))
            }
            let h = CGFloat(t.double("height") ?? 24)
            guard let id = v.string("img"), let ui = c.doc.image(id) else { return nil }
            return AnyView(Image(uiImage: ui).resizable().aspectRatio(contentMode: .fit)
                .frame(height: h).frame(maxWidth: 56)
                .shadow(color: .black.opacity(0.55), radius: 1, x: 0, y: 1))
        }
        return nil
    }

    /// Estilo opcional de la barra o el anillo (`style` del contrato).
    struct BarStyle {
        var height: CGFloat = 6
        var color: Color? = nil
        var trackColor: Color? = nil
        var gap: CGFloat = 4
        var radius: CGFloat? = nil
        var pointSize: CGFloat = 10
        var pointColor: Color? = nil
        var pointShape: String = "circle"
        var labelSize: CGFloat = 11.5
        var trackerSize: CGFloat? = nil
        var strokeWidth: CGFloat? = nil

        init(_ n: LNode) {
            guard let s = n.node("style") else { return }
            func hex(_ k: String) -> Color? { s.string(k).map { Color(hex: $0) } }
            if let h = s.double("h") { height = CGFloat(h); strokeWidth = CGFloat(h) }
            color = hex("color")
            trackColor = hex("trackColor")
            if let g = s.double("gap") { gap = CGFloat(g) }
            radius = s.double("radius").map { CGFloat($0) }
            if let p = s.double("pointSize") { pointSize = CGFloat(p) }
            pointColor = hex("pointColor")
            if let sh = s.string("pointShape") { pointShape = sh }
            if let l = s.double("labelSize") { labelSize = CGFloat(l) }
            trackerSize = s.double("trackerSize").map { CGFloat($0) }
        }
    }

    private static func barView(_ n: LNode, _ c: LiveCtx, labels: [String], segmented: Bool,
                                points: Bool, showLabels: Bool) -> AnyView {
        let bs = BarStyle(n)
        return AnyView(LiveBarView(value: value(n, c), labels: labels, segmented: segmented,
                                   points: points, showLabels: showLabels,
                                   tracker: tracker(n.node("tracker"), c, bs),
                                   start: endView(n.node("start"), c), end: endView(n.node("end"), c),
                                   style: c.style, bar: bs))
    }

    private static func bar(_ n: LNode, _ c: LiveCtx) -> AnyView {
        barView(n, c, labels: [], segmented: false, points: false, showLabels: true)
    }

    private static func segments(_ n: LNode, _ c: LiveCtx) -> AnyView {
        barView(n, c, labels: n.d["labels"] as? [String] ?? [], segmented: true,
                points: n.bool("points"), showLabels: n.d["showLabels"] as? Bool ?? true)
    }

    private static func ring(_ n: LNode, _ c: LiveCtx, slot: CGFloat?) -> AnyView {
        let size = CGFloat(n.double("size") ?? Double(slot ?? 40))
        let v = value(n, c)
        let bs = BarStyle(n)
        let stroke = bs.strokeWidth ?? 3
        let inner: AnyView = n.node("child").map { render($0, c, slot: 16, iconSize: 14) } ?? AnyView(EmptyView())
        return AnyView(ZStack {
            Circle().stroke(bs.trackColor ?? Color.white.opacity(0.22), lineWidth: stroke)
            Circle().trim(from: 0, to: v)
                .stroke(bs.color ?? c.style.fill, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            inner
        }
        .padding(stroke / 2)
        .frame(width: size, height: size))
    }

    private static func metric(_ n: LNode, _ c: LiveCtx) -> AnyView {
        let v = c.text(of: n.string("bind"))
        return AnyView(VStack(alignment: .leading, spacing: 0) {
            (Text(v).font(.system(size: 22, weight: .bold)).foregroundColor(c.style.fg)
                + Text(n.string("unit").map { " \($0)" } ?? "").font(.system(size: 13)).foregroundColor(c.style.muted))
            if let l = n.string("label") {
                Text(l).font(.system(size: 12)).foregroundColor(c.style.muted)
            }
        })
    }

    // MARK: botones (el comportamiento llega en la fase 5)

    private static func button(label: String, icon ic: LNode?, id: String?, _ c: LiveCtx) -> AnyView {
        let (bg, fg) = c.style.button(c.buttonIndex(id))
        let glyph: AnyView? = ic.flatMap { $0.t == "icon" ? icon($0, c, size: 15, color: fg) : ($0.t == "image" ? image($0, c, size: 15) : nil) }
        let pill = HStack(spacing: 6) {
            if let g = glyph { g }
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(fg).lineLimit(1)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().fill(bg))

        // iOS 17+: el botón ejecuta un App Intent y llega a Dart sin abrir la app.
        // Antes de iOS 17 se dibuja igual, pero sin acción.
        #if canImport(AppIntents)
        if #available(iOS 17.0, *), let id = id, !id.isEmpty {
            return AnyView(Button(intent: LiveIslandActionIntent(buttonId: id)) { pill }.buttonStyle(.plain))
        }
        #endif
        return AnyView(pill)
    }
}

/// Barra continua o por etapas, con puntos, ícono que avanza y etiquetas.
struct LiveBarView: View {
    let value: Double
    let labels: [String]
    let segmented: Bool
    let points: Bool
    var showLabels: Bool = true
    let tracker: AnyView?
    let start: AnyView?
    let end: AnyView?
    let style: LiveStyle
    var bar: LiveRenderer.BarStyle = .init(LNode(d: [:]))

    private var hasStages: Bool { labels.count > 1 }
    private var labelsVisible: Bool { showLabels && hasStages && (segmented || points) }
    private var current: Int { min(labels.count - 1, Int(value * Double(labels.count - 1) + 1e-6)) }
    private var fill: Color { bar.color ?? style.fill }
    private var trackColor: Color { bar.trackColor ?? style.trackBg }
    private var radius: CGFloat { bar.radius ?? bar.height / 2 }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let s = start { s.opacity(0.9) }
                track.frame(height: bar.height)
                if let e = end { e.opacity(0.9) }
            }
            .frame(height: (start != nil || end != nil) ? max(16, bar.height) : bar.height)
            if labelsVisible {
                if labels.count > 3 { stageLine } else { stageLabels }
            }
        }
    }

    private var track: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let n = hasStages ? labels.count - 1 : 1
            let useSegs = segmented && hasStages
            ZStack(alignment: .leading) {
                HStack(spacing: bar.gap) {
                    ForEach(0..<(useSegs ? n : 1), id: \.self) { i in
                        let f = useSegs ? min(1, max(0, (value - Double(i) / Double(n)) * Double(n))) : value
                        segment(f)
                    }
                }
                if points && hasStages {
                    ForEach(0..<labels.count, id: \.self) { k in
                        let p = Double(k) / Double(labels.count - 1)
                        let done = p <= value + 1e-6
                        let doneColor = bar.pointColor ?? fill
                        LivePoint(shape: bar.pointShape, fill: done ? doneColor : style.pendingDot,
                                  border: done ? doneColor : trackColor)
                            .frame(width: bar.pointSize, height: bar.pointSize)
                            .position(x: CGFloat(p) * w, y: bar.height / 2)
                    }
                }
                if let t = tracker { t.position(x: CGFloat(value) * w, y: bar.height / 2) }
            }
            .frame(width: w, height: bar.height, alignment: .leading)
        }
    }

    private func segment(_ f: Double) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Rectangle().fill(trackColor)
                Rectangle().fill(fill).frame(width: g.size.width * CGFloat(f))
            }
        }
        .frame(height: bar.height)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    private var stageLine: some View {
        HStack {
            Text(labels[current]).font(.system(size: bar.labelSize, weight: .semibold))
                .foregroundColor(style.stageStrong).lineLimit(1)
            Spacer(minLength: 4)
            Text("Paso \(current + 1) de \(labels.count)").font(.system(size: bar.labelSize))
                .foregroundColor(style.stageMuted)
        }
    }

    private var stageLabels: some View {
        GeometryReader { g in
            ZStack {
                ForEach(0..<labels.count, id: \.self) { k in
                    let isCur = k == current
                    let t = Text(labels[k])
                        .font(.system(size: bar.labelSize, weight: isCur ? .semibold : .regular))
                        .foregroundColor(isCur ? style.stageStrong : style.stageMuted)
                        .lineLimit(1)
                    if k == 0 {
                        t.frame(width: g.size.width, alignment: .leading)
                    } else if k == labels.count - 1 {
                        t.frame(width: g.size.width, alignment: .trailing)
                    } else {
                        t.fixedSize().position(x: g.size.width * 0.5, y: (bar.labelSize + 4.5) / 2)
                    }
                }
            }
        }
        .padding(.leading, start != nil ? 24 : 0)
        .padding(.trailing, end != nil ? 24 : 0)
        .frame(height: bar.labelSize + 4.5)
    }
}

/// Punto de etapa: círculo, cuadrado o cuadrado redondeado, con borde de 2 pt.
struct LivePoint: View {
    let shape: String
    let fill: Color
    let border: Color

    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height)
            switch shape {
            case "square":
                Rectangle().fill(fill).overlay(Rectangle().strokeBorder(border, lineWidth: 2))
            case "rounded":
                RoundedRectangle(cornerRadius: r / 3).fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: r / 3).strokeBorder(border, lineWidth: 2))
            default:
                Circle().fill(fill).overlay(Circle().strokeBorder(border, lineWidth: 2))
            }
        }
    }
}
