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

if fallos.isEmpty {
    print("Swift: \(total) casos de conformidad, todos bien.")
} else {
    print("Swift: \(fallos.count) de \(total) casos fallan:")
    fallos.forEach { print("  - \($0)") }
    exit(1)
}
