# SekretLink iOS App — Implementation Plan

## Context

Building a native iOS client for [sekret.link](https://sekret.link) — a self-hosted, open-source secure secret-sharing service by [@Ajnasz](https://github.com/Ajnasz/sekret.link). The service lets users share one-time notes/passwords via links. This app lets iOS users create secrets and open `sekret.link` URLs directly on device instead of a browser.

The project directory `/home/user/sekretlink-ios` is a blank git repo on branch `claude/ios-sekret-client-eWuJe`.

---

## API & Encryption Summary (from source research)

**Base URL:** `https://sekret.link/api/`

| Operation | Method | Path | Params |
|-----------|--------|------|--------|
| Create | POST | `/api/` | body: text/plain (encrypted), `?expire=1h\|24h\|168h\|720h`, `?maxReads=N` |
| Read | GET | `/api/{UUID}/{Key}` | — |
| Delete | DELETE | `/api/{UUID}/{Key}/{DeleteKey}` | — |
| Extra key | GET | `/api/key/{UUID}/{Key}` | `?expire=`, `?maxReads=` |

**JSON response fields:** `UUID`, `Data`, `Key`, `DeleteKey`, `Created`, `Expire`, `Accessed`

**Encryption (must be compatible with the web frontend):**
- Generate 32 random bytes → hex-encode → 64-char hex string (the "password")
- Encrypt with AES-256-CBC, OpenSSL-compatible format (crypto-js compatible):
  - Random 8-byte salt
  - Key derivation via EVP_BytesToKey (MD5, 1 iteration): → 32-byte key + 16-byte IV
  - Output: Base64(`Salted__` + salt + ciphertext)
- Implemented via CommonCrypto (no third-party dependencies)

**Share URL format:** `https://sekret.link/view/{UUID}#{Key}&{password}`
- Fragment `#{Key}&{password}` is never sent to server
- `{Key}` = server-side decryption key (26–27 char lowercase alphanumeric)
- `{password}` = 64-char hex string (client-side AES passphrase)

---

## Project Structure

```
sekretlink-ios/
├── Project.swift                    # Tuist project definition
├── Tuist/
│   └── Config.swift                 # Tuist config (no extra dependencies)
├── SekretLink/
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── SekretLinkApp.swift  # @main, onOpenURL deep link handler
│   │   │   └── ContentView.swift    # TabView: Create / Open tabs
│   │   ├── Features/
│   │   │   ├── Create/
│   │   │   │   ├── CreateSecretView.swift
│   │   │   │   └── CreateSecretViewModel.swift
│   │   │   ├── Created/
│   │   │   │   └── SecretCreatedView.swift
│   │   │   └── Viewer/
│   │   │       ├── ViewSecretView.swift
│   │   │       └── ViewSecretViewModel.swift
│   │   ├── Models/
│   │   │   └── Secret.swift
│   │   ├── Services/
│   │   │   ├── SecretAPIService.swift   # URLSession API calls
│   │   │   └── CryptoService.swift      # CommonCrypto AES-256-CBC + EVP_BytesToKey
│   │   └── Utilities/
│   │       └── SecretURLParser.swift    # Parse sekret.link URL → (uuid, key, password)
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Info.plist                   # Custom URL scheme: sekretlink://
│       └── SekretLink.entitlements      # applinks:sekret.link (Universal Links)
├── .gitignore                           # iOS + Tuist ignores
└── README.md                            # App description, credits, build/dev info
```

---

## Implementation Steps

### 1. Tooling & Project Scaffold

**`Tuist/Config.swift`**
```swift
import ProjectDescription
let config = Config()
```

**`Project.swift`** — Tuist 4.x syntax, single app target:
- `destinations: .iOS`
- `deploymentTargets: .iOS("16.0")` — supports iOS 16 + 17
- `bundleId: "link.sekret.client"`
- Sources: `SekretLink/Sources/**`
- Resources: `SekretLink/Resources/**`
- Entitlements: `SekretLink/Resources/SekretLink.entitlements`
- No third-party Swift packages (CommonCrypto is a system library)

---

### 2. Models

**`Secret.swift`**
```swift
struct Secret: Codable {
    let uuid: String
    let data: String
    let created: Date
    var key: String?
    var expire: Date?
    var accessed: Date?
    var deleteKey: String?

    enum CodingKeys: String, CodingKey {
        case uuid = "UUID", data = "Data", created = "Created"
        case key = "Key", expire = "Expire"
        case accessed = "Accessed", deleteKey = "DeleteKey"
    }
}
```

---

### 3. CryptoService

Using `import CommonCrypto` only. No third-party libs.

```swift
final class CryptoService {
    // Generate 32-byte random hex password (64 chars) — matches web generatePassword()
    func generatePassword() -> String

    // AES-256-CBC encrypt, OpenSSL Salted__ format, Base64 output
    // Matches: AES.encrypt(data, password).toString() in crypto-js
    func encrypt(_ plaintext: String, password: String) throws -> String

    // AES-256-CBC decrypt from Base64 OpenSSL Salted__ format
    // Matches: AES.decrypt(data, password).toString(enc.Utf8) in crypto-js
    func decrypt(_ ciphertext: String, password: String) throws -> String

    // EVP_BytesToKey: MD5-based, OpenSSL-compatible key+IV derivation
    // key(32) + iv(16) = 48 bytes via D1=MD5(pass+salt), D2=MD5(D1+pass+salt), D3=MD5(D2+pass+salt)
    private func evpBytesToKey(password: Data, salt: Data) -> (key: Data, iv: Data)
}
```

---

### 4. SecretAPIService

```swift
final class SecretAPIService {
    let baseURL = URL(string: "https://sekret.link/api/")!

    func createSecret(_ encryptedData: String, expire: String, maxReads: Int) async throws -> Secret
    func getSecret(uuid: String, key: String) async throws -> Secret
    func deleteSecret(uuid: String, key: String, deleteKey: String) async throws
}
```

- `createSecret`: POST to baseURL, `Content-Type: text/plain`, `Accept: application/json`, body = encrypted string, query params `expire` and `maxReads`.
- `getSecret`: GET `{baseURL}{uuid}/{key}`, `Accept: application/json`.

---

### 5. SecretURLParser

```swift
struct ParsedSecretURL {
    let uuid: String
    let serverKey: String
    let clientPassword: String
}

struct SecretURLParser {
    // Parses: https://sekret.link/view/{UUID}#{Key}&{password}
    // Also handles: sekretlink://view/{UUID}#{Key}&{password}
    static func parse(_ url: URL) -> ParsedSecretURL?
}
```

---

### 6. Views

**`ContentView.swift`** — `TabView` with two tabs: "Create" and "Open"

**`CreateSecretView.swift`**
- `TextEditor` for secret input (multiline, native)
- `Picker` for expiration: 1 hour / 1 day / 1 week / 30 days
- `Stepper` for max reads (1–10, default 1)
- Submit `Button` → async → navigate to `SecretCreatedView`
- Error display via `.alert`

**`SecretCreatedView.swift`**
- Shows the full share URL in a selectable `Text`
- `ShareLink` (native iOS 16+) for share sheet
- Copy button using `UIPasteboard`
- "Destroy" button using `DeleteKey`

**`ViewSecretView.swift`**
- Default state: paste URL `TextField` + "Open" button
- Deep link received: auto-fills and shows reveal button
- "Reveal Secret" button → async fetch + decrypt → show in `Text` (selectable)
- Error states via `.alert`

**`SekretLinkApp.swift`**
```swift
@main struct SekretLinkApp: App {
    @State private var incomingURL: URL?

    var body: some Scene {
        WindowGroup {
            ContentView(incomingURL: $incomingURL)
                .onOpenURL { url in incomingURL = url }
        }
    }
}
```

---

### 7. Deep Link Setup

**Universal Links** (`SekretLink.entitlements`):
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:sekret.link</string>
</array>
```

**Custom URL scheme** (`Info.plist`) — works without server-side AASA file:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array><string>sekretlink</string></array>
    </dict>
</array>
```

Handle both in `SecretURLParser`: URLs with host `sekret.link` + path `/view/...` or scheme `sekretlink://`.

> **Note:** Universal Links require `/.well-known/apple-app-site-association` on the `sekret.link` server. The custom scheme `sekretlink://` works without server changes.

---

### 8. `.gitignore`

Standard iOS + Tuist ignores:
- Xcode: `*.xcodeproj/`, `*.xcworkspace/`, `xcuserdata/`, `DerivedData/`, `build/`, `*.ipa`, `*.dSYM*`
- Tuist-generated: `Derived/`, `.build/`, `*.xcodeproj`, `*.xcworkspace`
- macOS: `.DS_Store`

---

### 9. `README.md`

Contents:
- **What is this**: iOS client for [sekret.link](https://sekret.link)
- **Credits**: Server by [@Ajnasz](https://github.com/Ajnasz/sekret.link), frontend by [@Ajnasz](https://github.com/Ajnasz/sekret.link-ui)
- **Features list**
- **Requirements**: iOS 16+, Xcode 15+, [Tuist](https://tuist.io) 4.x
- **Build steps**: `brew install tuist` → `tuist generate` → open in Xcode
- **Development notes**: Edit sources, re-run `tuist generate` after `Project.swift` changes
- **Universal Links note**: AASA setup required for `sekret.link` deep links; custom scheme works out of the box

---

## Verification

1. `tuist generate && xcodebuild -scheme SekretLink -destination 'platform=iOS Simulator,name=iPhone 16'`
2. Create flow: enter secret → pick expiration → submit → copy URL
3. View flow: paste `https://sekret.link/view/...#...` URL → Open → Reveal → confirm secret
4. Deep link: `xcrun simctl openurl booted "sekretlink://view/{UUID}#{Key}&{password}"`
5. Cross-compatibility: create secret on web, open URL in iOS app (and vice versa)
