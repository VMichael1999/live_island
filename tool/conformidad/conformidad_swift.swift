import Foundation

// Ejecuta doc/contract/conformance.json con la lógica real del renderer de iOS
// (LiveCtx.format y LiveCtx.evaluate). Lo compila y corre tool/conformidad_swift.sh.

let ruta = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "conformance.json"
guard let data = FileManager.default.contents(atPath: ruta),
      let casos = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    print("No se pudo leer \(ruta)")
    exit(2)
}

func contexto(_ state: [String: Any]) -> LiveCtx {
    LiveCtx(doc: LiveLayoutDoc(root: [:], dir: nil),
            values: LiveValue.dictionary(from: state),
            style: LiveStyle(tone: .dark, accent: .blue))
}

var total = 0
var fallos: [String] = []

for c in casos["format"] as? [[String: Any]] ?? [] {
    total += 1
    let got = contexto(c["state"] as? [String: Any] ?? [:]).format(c["fmt"] as? String ?? "")
    let esperado = c["expect"] as? String ?? ""
    if got != esperado { fallos.append("format · \(c["nombre"] ?? ""): esperaba «\(esperado)» y dio «\(got)»") }
}

for c in casos["condition"] as? [[String: Any]] ?? [] {
    total += 1
    let got = contexto(c["state"] as? [String: Any] ?? [:]).evaluate(LNode(d: c["cond"] as? [String: Any] ?? [:]))
    let esperado = (c["expect"] as? NSNumber)?.boolValue ?? false
    if got != esperado { fallos.append("condition · \(c["nombre"] ?? ""): esperaba \(esperado) y dio \(got)") }
}

// Los textos que cada preset muestra con sus datos de ejemplo
// (doc/contract/resolved_texts.json, generado por Dart): se recorre el mismo
// JSON con la lógica de iOS y debe dar la misma lista.
func recorrer(_ n: Any?, _ ctx: LiveCtx, _ out: inout [String]) {
    if let a = n as? [Any] {
        for e in a { recorrer(e, ctx, &out) }
    } else if let d = n as? [String: Any] {
        let node = LNode(d: d)
        if node.t == "if" {
            let ok = ctx.evaluate(LNode(d: d["when"] as? [String: Any] ?? [:]))
            recorrer(ok ? d["then"] : d["else"], ctx, &out)
            return
        }
        if node.t == "text" {
            if let f = node.string("fmt") { out.append(ctx.format(f)) }
            else if let t = node.string("text") { out.append(t) }
            else if let b = node.string("bind") { out.append(ctx.text(of: b)) }
            else { out.append("") }
        }
        for (k, v) in d where k != "when" { recorrer(v, ctx, &out) }
    }
}

if CommandLine.arguments.count > 2,
   let data = FileManager.default.contents(atPath: CommandLine.arguments[2]),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let presets = json["presets"] as? [[String: Any]] {
    for p in presets {
        total += 1
        let ctx = contexto(p["state"] as? [String: Any] ?? [:])
        var got: [String] = []
        recorrer(p["layout"], ctx, &got)
        got.sort()
        let want = (p["texts"] as? [String] ?? [])
        if got != want { fallos.append("preset \(p["name"] ?? ""): esperaba \(want) y dio \(got)") }
    }
}


if fallos.isEmpty {
    print("Swift: \(total) casos de conformidad, todos bien.")
} else {
    print("Swift: \(fallos.count) de \(total) casos fallan:")
    fallos.forEach { print("  - \($0)") }
    exit(1)
}
