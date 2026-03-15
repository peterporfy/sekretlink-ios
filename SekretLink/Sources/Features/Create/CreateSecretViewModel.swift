import Foundation

enum ExpireDuration: String, CaseIterable, Identifiable {
    case oneHour = "1h"
    case oneDay = "24h"
    case oneWeek = "168h"
    case thirtyDays = "720h"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .thirtyDays: return "30 Days"
        }
    }
}

@MainActor
final class CreateSecretViewModel: ObservableObject {
    @Published var secretText = ""
    @Published var selectedExpire: ExpireDuration = .oneDay
    @Published var maxReads = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdResult: CreatedSecret?

    private let api = SecretAPIService()
    private let crypto = CryptoService()

    func submit() async {
        guard !secretText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Secret must not be empty"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let password = try crypto.generatePassword()
            let encrypted = try crypto.encrypt(secretText, password: password)
            let secret = try await api.createSecret(encrypted, expire: selectedExpire.rawValue, maxReads: maxReads)

            guard let key = secret.key else {
                throw SecretAPIService.APIError.invalidResponse
            }

            let shareURL = buildShareURL(uuid: secret.uuid, key: key, password: password)
            createdResult = CreatedSecret(
                uuid: secret.uuid,
                key: key,
                deleteKey: secret.deleteKey ?? "",
                shareURL: shareURL,
                expire: secret.expire
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildShareURL(uuid: String, key: String, password: String) -> String {
        "https://sekret.link/view/\(uuid)#\(key)&\(password)"
    }
}

struct CreatedSecret {
    let uuid: String
    let key: String
    let deleteKey: String
    let shareURL: String
    let expire: Date?
}
