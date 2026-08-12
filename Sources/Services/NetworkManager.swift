import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "La URL de la API es inválida."
        case .invalidResponse: return "La respuesta del servidor no es válida o falló al procesar los datos."
        case .requestFailed(let statusCode): return "La solicitud falló con código de estado HTTP: \(statusCode)."
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func testINEGIConnection(token: String) async throws -> String {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = "https://www.inegi.org.mx/app/api/denue/v1/consulta/buscar/todos/20.6766,-103.3475/250/\(cleanToken)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15 // Timeout corto para la prueba de humo
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NetworkError.invalidResponse
        }
        
        return jsonString
    }
}
