import Foundation

final class EnvironmentManager {
    static let shared = EnvironmentManager()
    private var variables: [String: String] = [:]
    
    private init() {
        loadEnv()
    }
    
    private func loadEnv() {
        // En Xcode, el directorio de trabajo actual no es la raíz del proyecto.
        // Utilizamos la macro #file para obtener la ruta absoluta de este código fuente
        // y desde aquí subimos 3 niveles para llegar a la raíz del proyecto.
        let sourceFileURL = URL(fileURLWithPath: #file)
        let projectRoot = sourceFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let envPath = projectRoot.appendingPathComponent(".env")
        
        guard let content = try? String(contentsOf: envPath, encoding: .utf8) else {
            print("Advertencia: No se pudo leer el archivo .env en \(envPath.path)")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.isEmpty || cleanLine.hasPrefix("#") { continue }
            
            let parts = cleanLine.split(separator: "=", maxSplits: 1).map { String($0) }
            if parts.count == 2 {
                variables[parts[0]] = parts[1]
            }
        }
    }
    
    func get(_ key: String) -> String? {
        return variables[key]
    }
}
