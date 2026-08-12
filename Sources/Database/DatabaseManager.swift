import Foundation
import SQLite

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let db: Connection
    
    // Variables estaticas para el esquema de negocios
    static let businesses = Table("businesses")
    static let clee = Expression<String>("clee")
    static let nombre = Expression<String>("nombre")
    static let razonSocial = Expression<String>("razon_social")
    static let latitud = Expression<String>("latitud")
    static let longitud = Expression<String>("longitud")
    
    private init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let appDirectoryURL = appSupportURL.appendingPathComponent("DENUEExplorer", isDirectory: true)
            
            if !fileManager.fileExists(atPath: appDirectoryURL.path) {
                try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let databaseURL = appDirectoryURL.appendingPathComponent("denue_local.sqlite3")
            
            db = try Connection(databaseURL.path)
            
        } catch {
            fatalError("Fallo al inicializar la conexion a SQLite: \(error)")
        }
    }
    
    func createTables() throws {
        try db.run(Self.businesses.create(ifNotExists: true) { table in
            table.column(Self.clee, primaryKey: true)
            table.column(Self.nombre)
            table.column(Self.razonSocial)
            table.column(Self.latitud)
            table.column(Self.longitud)
        })
    }
    
    func insertSmokeTestBusiness() throws {
        let insert = Self.businesses.insert(
            Self.clee <- "TEST-000000001",
            Self.nombre <- "Empresa de Prueba Smoke Test",
            Self.razonSocial <- "Desarrollo y Pruebas S.A. de C.V.",
            Self.latitud <- "20.6766",
            Self.longitud <- "-103.3475"
        )
        try db.run(insert)
    }
    
    func fetchBusinessCount() throws -> Int {
        return try db.scalar(Self.businesses.count)
    }
}
