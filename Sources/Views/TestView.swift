import SwiftUI

enum AppState {
    case idle
    case loading
    case success(String)
    case error(String)
}

struct TestView: View {
    @State private var token: String = ""
    @State private var state: AppState = .idle
    
    var body: some View {
        VStack(spacing: 24) {
            Text("INEGI API Smoke Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            SecureField("Ingresa el Token de INEGI", text: $token)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)
            
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
            .disabled(token.isEmpty || isLoading)
            
            Divider()
            
            Group {
                switch state {
                case .idle:
                    Text("Ingresa tu token y presiona el botón para iniciar la prueba.")
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
                        Text("Error de Conexión")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(32)
    }
    
    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    @MainActor
    private func testConnection() async {
        state = .loading
        do {
            let result = try await NetworkManager.shared.testINEGIConnection(token: token)
            let limit = 1000
            let trimmedResult = String(result.prefix(limit))
            let displayResult = result.count > limit ? trimmedResult + "\n\n... (Resultados truncados, se recibieron \(result.count) caracteres en total)" : trimmedResult
            state = .success(displayResult)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
