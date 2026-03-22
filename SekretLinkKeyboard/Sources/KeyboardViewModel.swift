import Foundation

@MainActor
final class KeyboardViewModel: ObservableObject {
    @Published var secretText = ""
    @Published var selectedExpire: ExpireDuration = .oneDay
    @Published var maxReads = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdURL: String?

    private let api = SecretAPIService()
    private let crypto = CryptoService()
    private let onInsert: (String) -> Void

    init(onInsert: @escaping (String) -> Void) {
        self.onInsert = onInsert
    }

    func createSekretLink() async {
        let text = secretText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Type your secret first"
            return
        }

        isLoading = true
        errorMessage = nil
        createdURL = nil

        do {
            let password = try crypto.generatePassword()
            let encrypted = try crypto.encrypt(text, password: password)
            let secret = try await api.createSecret(encrypted, expire: selectedExpire.rawValue, maxReads: maxReads)

            guard let key = secret.key else {
                throw SecretAPIService.APIError.invalidResponse
            }

            let url = "https://sekret.link/view/\(secret.uuid)#\(key)&\(password)"
            createdURL = url
            onInsert(url)
            secretText = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
