import Foundation

struct InegiBusiness: Codable {
    let CLEE: String
    let Nombre: String
    let Razon_social: String
    let Latitud: String
    let Longitud: String
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case timeout
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: 
            return "La URL de la API es invalida."
        case .invalidResponse: 
            return "La respuesta del servidor no es valida o fallo al procesar los datos."
        case .requestFailed(let statusCode): 
            return "La solicitud fallo con codigo de estado HTTP: \(statusCode)."
        case .timeout: 
            return "Tiempo de espera agotado. El servidor del INEGI no respondio en 10 segundos."
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
        request.timeoutInterval = 10
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            throw error
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let businesses = try decoder.decode([InegiBusiness].self, from: data)
        
        return "Validacion exitosa: Se lograron decodificar \(businesses.count) empresas empatando perfectamente con la estructura esperada."
    }
}
