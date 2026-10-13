// swift-tools-version: 5.9
// Soporte de Swift Package Manager para Flutter. CocoaPods sigue funcionando con
// ../live_island.podspec; ambos leen las mismas fuentes de Sources/live_island.

import Foundation
import PackageDescription

// Flutter 3.38 o superior pone el paquete `FlutterFramework` junto al del plugin y
// pide depender de él; las versiones anteriores no lo generan y fallarían al
// resolverlo. Se enlaza solo si existe.
let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let flutterFrameworkDir = packageDir.deletingLastPathComponent().appendingPathComponent("FlutterFramework")
let hasFlutterFramework = FileManager.default.fileExists(atPath: flutterFrameworkDir.path)

let package = Package(
    name: "live_island",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "live-island", targets: ["live_island"])
    ],
    dependencies: hasFlutterFramework
        ? [.package(name: "FlutterFramework", path: "../FlutterFramework")]
        : [],
    targets: [
        .target(
            name: "live_island",
            dependencies: hasFlutterFramework
                ? [.product(name: "FlutterFramework", package: "FlutterFramework")]
                : [],
            resources: [
                // Manifiesto de privacidad: lee el UserDefaults del App Group (motivo 1C8F.1).
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                // ActivityKit y AppIntents solo existen desde iOS 16: se enlazan de forma débil
                // para que la app abra en iOS 15 (igual que `weak_frameworks` del podspec).
                .unsafeFlags(["-Xlinker", "-weak_framework", "-Xlinker", "ActivityKit"]),
                .unsafeFlags(["-Xlinker", "-weak_framework", "-Xlinker", "AppIntents"]),
            ]
        )
    ]
)
