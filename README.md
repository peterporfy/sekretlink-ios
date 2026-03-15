# SekretLink iOS

A native iOS client for [sekret.link](https://sekret.link) — a secure, one-time secret sharing service.

> **Server:** [github.com/Ajnasz/sekret.link](https://github.com/Ajnasz/sekret.link) by [@Ajnasz](https://github.com/Ajnasz)
> **Web frontend:** [github.com/Ajnasz/sekret.link-ui](https://github.com/Ajnasz/sekret.link-ui) by [@Ajnasz](https://github.com/Ajnasz)

---

## Features

- **Create secrets** — Write a note or password, pick an expiration and read limit, and get a shareable one-time link
- **Open secrets** — Paste a `sekret.link` URL or tap a deep link to reveal the secret on-device
- **End-to-end encryption** — Secrets are AES-256-CBC encrypted on your device before being sent to the server; the decryption key never leaves the URL fragment (it is never sent to the server)
- **Deep links** — Opens `sekret.link` URLs in-app via Universal Links (`https://sekret.link/view/…`) or the custom scheme (`sekretlink://view/…`)
- **Fully native** — Built with SwiftUI and CommonCrypto; no third-party dependencies

---

## Requirements

| Tool | Version |
|------|---------|
| iOS | 16.0+ |
| Xcode | 15.0+ |
| [Tuist](https://tuist.io) | 4.x |

---

## Building

### 1. Install Tuist

```bash
curl -Ls https://install.tuist.io | bash
```

Or via Homebrew:

```bash
brew install tuist
```

### 2. Generate the Xcode project

```bash
cd sekretlink-ios
tuist generate
```

This creates `SekretLink.xcodeproj` (and `SekretLink.xcworkspace` if needed) from `Project.swift`.

### 3. Open in Xcode and run

```bash
open SekretLink.xcworkspace
```

Select a simulator or device and press **⌘R**.

---

## Development

- Source files live in `SekretLink/Sources/`
- Resources (Info.plist, entitlements, assets) are in `SekretLink/Resources/`
- After editing `Project.swift`, re-run `tuist generate` to regenerate the project
- The `Derived/` and `*.xcodeproj` / `*.xcworkspace` directories are git-ignored (Tuist regenerates them)

### Project structure

```
SekretLink/Sources/
├── App/                    # App entry point, root view
├── Features/
│   ├── Create/             # Create secret form + view model
│   ├── Created/            # Success screen with share/copy/destroy
│   └── Viewer/             # Open secret view + view model
├── Models/                 # Secret data model
├── Services/
│   ├── SecretAPIService    # REST API calls (URLSession)
│   └── CryptoService       # AES-256-CBC (CommonCrypto, OpenSSL-compatible)
└── Utilities/
    └── SecretURLParser     # Parse sekret.link URLs
```

---

## Deep Links

### Custom URL scheme (works out of the box)

The app registers the `sekretlink://` scheme. Test with:

```bash
xcrun simctl openurl booted "sekretlink://view/{UUID}#{Key}&{password}"
```

### Universal Links (`https://sekret.link/view/…`)

To intercept real `sekret.link` URLs, the server must host an [apple-app-site-association](https://developer.apple.com/documentation/xcode/supporting-associated-domains) file at `https://sekret.link/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["<TEAM_ID>.link.sekret.client"],
        "components": [
          { "/": "/view/*" }
        ]
      }
    ]
  }
}
```

Replace `<TEAM_ID>` with your Apple Developer Team ID.

---

## Encryption

This app is fully interoperable with the web frontend. Secrets are encrypted using **AES-256-CBC** in OpenSSL-compatible format (same as [crypto-js](https://github.com/brix/crypto-js)):

1. A random 32-byte key is generated and hex-encoded (64 chars)
2. The plaintext is encrypted: `Base64("Salted__" + salt + ciphertext)` with EVP_BytesToKey key derivation
3. Only the encrypted payload is sent to the server
4. The hex password is embedded in the share URL fragment (`#…`) — never sent to the server

---

## License

Apache-2.0 — see [LICENSE](LICENSE)
