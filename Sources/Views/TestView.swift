import SwiftUI

enum AppState {
    case idle
    case loading
    case success(String)
    case error(String)
}

struct TestView: View {
    @State private var state: AppState = .idle
    @State private var localDbMessage: String = "Esperando accion de SQLite..."
    @State private var isDownloading: Bool = false
    @State private var syncMessage: String = "Listo para descargar ZIP."
    @State private var downloadTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("INEGI API Smoke Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
                Task {
                    await testConnection()
                }
            }) {
                HStack {
                    Image(systemName: "network")
                    Text("Test API Connection")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading)
            
            Divider()
            
            Group {
                switch state {
                case .idle:
                    Text("Presiona el boton para leer el token del archivo .env e iniciar la prueba.")
                        .foregroundColor(.secondary)
                case .loading:
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Conectando con INEGI...")
                            .foregroundColor(.secondary)
                    }
                case .success(let result):
                    VStack(alignment: .trailing, spacing: 8) {
                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(result, forType: .string)
                        }) {
                            Label("Copiar JSON", systemImage: "doc.on.doc")
                        }
                        .padding(.top, 4)
                        
                        ScrollView {
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 150)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                case .error(let errorMessage):
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                        Text("Error de Conexion")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            Text("SQLite Local Test")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                Button("Insertar Mock Local") {
                    do {
                        try DatabaseManager.shared.insertSmokeTestBusiness()
                        localDbMessage = "Exito: Registro insertado correctamente."
                    } catch {
                        localDbMessage = "Error al insertar: \(error.localizedDescription)"
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Contar Registros") {
                    do {
                        let count = try DatabaseManager.shared.fetchBusinessCount()
                        localDbMessage = "Total de registros en DB: \(count)"
                    } catch {
                        localDbMessage = "Error al contar: \(error.localizedDescription)"
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Text(localDbMessage)
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            Divider()
            
            Text("Sincronizacion Masiva (Descarga y Unzip)")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: {
                if isDownloading {
                    downloadTask?.cancel()
                } else {
                    downloadTask = Task {
                        await startSync()
                    }
                }
            }) {
                HStack {
                    if isDownloading {
                        ProgressView().controlSize(.small)
                        Text("Cancelar Descarga")
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Descargar e Instalar Base de Datos DENUE")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isDownloading ? .red : .blue)
            
            Text(syncMessage)
                .foregroundColor(.secondary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
    
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    @MainActor
    private func testConnection() async {
        guard let token = EnvironmentManager.shared.get("INEGI_API_TOKEN") else {
            state = .error("No se encontro la variable INEGI_API_TOKEN en el archivo .env. Asegurate de crearlo en la raiz del proyecto.")
            return
        }
        
        state = .loading
        do {
            let result = try await NetworkManager.shared.testINEGIConnection(token: token)
            state = .success(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    @MainActor
    private func startSync() async {
        guard let url = EnvironmentManager.shared.get("DENUE_BULK_DOWNLOAD_URL") else {
            syncMessage = "Error: No se encontro DENUE_BULK_DOWNLOAD_URL en .env"
            return
        }
        
        isDownloading = true
        syncMessage = "Descargando ZIP masivo y extrayendo en 2do plano (puede tardar minutos)..."
        
        do {
            let extractedURL = try await SyncManager.shared.downloadAndUnzipDENUE(from: url)
            if !Task.isCancelled {
                syncMessage = "Exito! terminationStatus = 0.\nArchivos extraidos en:\n\(extractedURL.path)"
            }
        } catch is CancellationError {
            syncMessage = "Descarga cancelada por el usuario."
        } catch let urlError as URLError where urlError.code == .cancelled {
            syncMessage = "Descarga cancelada por el usuario."
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                syncMessage = "Descarga cancelada por el usuario."
            } else {
                syncMessage = "Error en sincronizacion: \(error.localizedDescription)"
            }
        }
        
        isDownloading = false
    }
}
