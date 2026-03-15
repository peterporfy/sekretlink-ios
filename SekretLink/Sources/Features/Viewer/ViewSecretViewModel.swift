import Foundation

@MainActor
final class ViewSecretViewModel: ObservableObject {
    @Published var urlText = ""
    @Published var isLoading = false
    @Published var revealedSecret: String?
    @Published var errorMessage: String?
    @Published var parsedURL: ParsedSecretURL?

    private let api = SecretAPIService()
    private let crypto = CryptoService()

    func loadURL(_ url: URL) {
        if let parsed = SecretURLParser.parse(url) {
            parsedURL = parsed
            urlText = url.absoluteString
        } else {
            errorMessage = "This doesn't look like a valid sekret.link URL."
        }
    }

    func parseManualURL() {
        // Build a proper URL — handle the fragment which may have been stripped
        guard let url = URL(string: urlText) else {
            errorMessage = "Invalid URL"
            return
        }
        guard let parsed = SecretURLParser.parse(url) else {
            errorMessage = "This doesn't look like a valid sekret.link URL.\nExpected: https://sekret.link/view/{id}#{key}&{password}"
            return
        }
        parsedURL = parsed
    }

    func revealSecret() async {
        guard let parsed = parsedURL else { return }

        isLoading = true
        errorMessage = nil

        do {
            let secret = try await api.getSecret(uuid: parsed.uuid, key: parsed.serverKey)
            let plaintext = try crypto.decrypt(secret.data, password: parsed.clientPassword)
            revealedSecret = plaintext
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func reset() {
        urlText = ""
        parsedURL = nil
        revealedSecret = nil
        errorMessage = nil
    }
}
