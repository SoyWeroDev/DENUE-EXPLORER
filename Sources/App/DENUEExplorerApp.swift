import SwiftUI
import AppKit

@main
struct DENUEExplorerApp: App {
    init() {
        // Al correr desde un binario de Swift Package Manager (sin un bundle .app ni Info.plist),
        // macOS por defecto no asigna la política de interfaz correcta.
        // Esto fuerza a la app a ser 'regular' (con Dock y menús) y le da foco de teclado inmediato.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            TestView()
                .frame(width: 600, height: 400)
        }
        .windowResizability(.contentSize)
        .commands {
            TextEditingCommands()
        }
    }
}
