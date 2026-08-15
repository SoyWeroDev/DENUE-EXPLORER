import Foundation

enum SyncError: Error {
    case invalidURL
    case linkExpired
    case unzipFailed(status: Int32)
}

extension SyncError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL proporcionada no es valida."
        case .linkExpired:
            return "El servidor de INEGI devolvio una pagina web en lugar de un ZIP. Verifica que el enlace DENUE_BULK_DOWNLOAD_URL en tu .env siga vigente."
        case .unzipFailed(let status):
            return "Fallo la extraccion del archivo ZIP. Codigo de terminacion: \(status)."
        }
    }
}

final class SyncManager {
    static let shared = SyncManager()
    
    private init() {}
    
    func downloadAndUnzipDENUE(from urlString: String) async throws -> URL {
        let cleanURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: cleanURLString) else {
            throw SyncError.invalidURL
        }
        
        // Descarga el archivo directamente a una ubicacion temporal en disco (baja memoria RAM)
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }
        
        // INEGI devuelve un falso "200 OK" mostrando una pagina HTML cuando su link caduca o cambia.
        // Verificamos el Content-Type para prevenir mandar a extraer un HTML creyendo que es un ZIP.
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
           contentType.contains("text/html") {
            try? FileManager.default.removeItem(at: tempURL)
            throw SyncError.linkExpired
        }
        
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // Extraemos en una subcarpeta 'RawData' para separar los CSV de nuestra base de datos SQLite
        let targetDirectory = appSupportURL.appendingPathComponent("DENUEExplorer").appendingPathComponent("RawData", isDirectory: true)
        
        if !fileManager.fileExists(atPath: targetDirectory.path) {
            try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        // El comando unzip nativo falla (error 9) si el archivo no termina en .zip
        // Movemos el archivo temporal (.tmp) a un archivo con la extension correcta.
        let zipURL = appSupportURL.appendingPathComponent("DENUEExplorer").appendingPathComponent("denue_temp.zip")
        try? fileManager.removeItem(at: zipURL)
        try fileManager.moveItem(at: tempURL, to: zipURL)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        
        // El flag -o se utiliza para sobrescribir archivos existentes de forma automatica y evitar bloqueos
        process.arguments = [
            "-o",
            zipURL.path,
            "-d",
            targetDirectory.path
        ]
        
        // Evitar el bloqueo del thread cooperativo y soportar cancelacion de tarea nativa
        let status: Int32 = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { p in
                    continuation.resume(returning: p.terminationStatus)
                }
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            if process.isRunning {
                process.terminate()
            }
        }
        
        // Eliminar el archivo ZIP temporal para liberar espacio en disco
        try? fileManager.removeItem(at: zipURL)
        
        if status != 0 {
            if Task.isCancelled {
                // Limpieza automatica: Si se cancelo la extraccion a la mitad, 
                // eliminamos el directorio para no dejar archivos residuales corruptos.
                try? fileManager.removeItem(at: targetDirectory)
                throw CancellationError()
            }
            throw SyncError.unzipFailed(status: status)
        }
        
        return targetDirectory
    }
}
