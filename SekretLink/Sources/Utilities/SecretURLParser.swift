import Foundation

/// Parsed components of a sekret.link secret URL.
struct ParsedSecretURL {
    /// Server-side UUID of the secret entry
    let uuid: String
    /// Server-side decryption key (26–27 char lowercase alphanumeric)
    let serverKey: String
    /// Client-side AES password (64-char hex string)
    let clientPassword: String
}

/// Parses sekret.link secret URLs into their components.
///
/// Supported formats:
/// - Universal Link:  `https://sekret.link/view/{UUID}#{Key}&{password}`
/// - Custom scheme:   `sekretlink://view/{UUID}#{Key}&{password}`
///
/// The fragment (`#{Key}&{password}`) is never sent to the server;
/// it carries the decryption keys client-side only.
enum SecretURLParser {

    static func parse(_ url: URL) -> ParsedSecretURL? {
        // Extract path and fragment — URLComponents handles the fragment correctly
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let isUniversalLink = url.host == "sekret.link"
        let isCustomScheme = url.scheme == "sekretlink"

        guard isUniversalLink || isCustomScheme else { return nil }

        // Path must be /view/{UUID}
        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard pathComponents.count >= 2, pathComponents[0] == "view" else { return nil }
        let uuid = pathComponents[1]
        guard !uuid.isEmpty else { return nil }

        // Fragment: {Key}&{password}
        guard let fragment = components.fragment, !fragment.isEmpty else { return nil }
        let parts = fragment.split(separator: "&", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }

        let serverKey = parts[0]
        let clientPassword = parts[1]

        // Validate server key: 26–27 lowercase alphanumeric chars
        guard isValidServerKey(serverKey) else { return nil }
        // Validate client password: 64 hex chars (32 bytes encoded)
        guard isValidClientPassword(clientPassword) else { return nil }

        return ParsedSecretURL(uuid: uuid, serverKey: serverKey, clientPassword: clientPassword)
    }

    // MARK: - Validation

    static func isValidServerKey(_ key: String) -> Bool {
        let len = key.count
        guard len >= 26 && len <= 27 else { return false }
        return key.allSatisfy { $0.isLowercase || $0.isNumber }
    }

    static func isValidClientPassword(_ password: String) -> Bool {
        guard password.count == 64 else { return false }
        return password.allSatisfy { $0.isHexDigit }
    }
}
