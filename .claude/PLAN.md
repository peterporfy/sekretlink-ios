# SekretLink iOS App

Native iOS client for [sekret.link](https://sekret.link) — open-source one-time secret sharing by [@Ajnasz](https://github.com/Ajnasz/sekret.link).

---

## Status

| Area | State | Notes |
|------|-------|-------|
| Tuist project scaffold | ✅ done | `Project.swift`, `Tuist/Config.swift`, iOS 16+ target |
| `.gitignore` | ✅ done | iOS + Tuist ignores |
| `README.md` | ✅ done | Credits, build steps, deep link docs |
| `Secret` model | ✅ done | `data` is optional (absent from POST response) |
| `CryptoService` | ✅ done | AES-256-CBC, CommonCrypto, crypto-js compatible |
| `SecretAPIService` | ✅ done | URLSession, RFC3339Nano date handling |
| `SecretURLParser` | ✅ done | Handles hex (64) and base62 (43) server keys |
| Create flow | ✅ done | TextEditor, segmented expiry, stepper max-reads |
| Keyboard dismiss | ✅ done | `scrollDismissesKeyboard`, Done toolbar button |
| Created screen | ✅ done | Auto-shows share sheet; "Share via…", Copy, Destroy |
| View/Open flow | ✅ done | URL paste, deep link, reveal + decrypt |
| Deep links | ✅ done | `applinks:sekret.link` entitlement + `sekretlink://` scheme |

---

## API

**Base URL:** `https://sekret.link/api/`

| Op | Method | Path | Body / Params |
|----|--------|------|---------------|
| Create | POST | `/api/` | body: encrypted text/plain; `?expire=1h\|24h\|168h\|720h&maxReads=N` |
| Read | GET | `/api/{UUID}/{Key}` | — |
| Delete | DELETE | `/api/{UUID}/{Key}/{DeleteKey}` | — |
| Extra key | GET | `/api/key/{UUID}/{Key}` | `?expire=&maxReads=` |

**Response differences:**
- POST create → fields: `UUID`, `Key`, `DeleteKey`, `Created`, `Expire`, `Accessed` (no `Data`)
- GET read → adds `Data` (encrypted), `ContentType`
- Dates are RFC3339Nano (Go format, may include nanoseconds)

---

## Encryption

Client-side, compatible with the web frontend ([sekret.link-ui](https://github.com/Ajnasz/sekret.link-ui)):

1. Generate 32 random bytes → hex-encode → 64-char password string
2. `AES.encrypt(plaintext, password)` → Base64(`"Salted__"` + 8-byte salt + ciphertext)
   - Key/IV derivation: EVP_BytesToKey (MD5, 1 iter): D1=MD5(pass+salt), D2=MD5(D1+pass+salt), D3=MD5(D2+pass+salt) → key=D1+D2 (32B), iv=D3 (16B)
3. POST encrypted string; get back UUID + server Key
4. Share URL: `https://sekret.link/view/{UUID}#{Key}&{password}` — fragment never reaches server

Implemented in `CryptoService.swift` using `CommonCrypto` (no third-party deps).

---

## Project Structure

```
sekretlink-ios/
├── Project.swift
├── Tuist/Config.swift
├── SekretLink/
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── SekretLinkApp.swift        @main, onOpenURL
│   │   │   └── ContentView.swift          TabView: Create / Open
│   │   ├── Features/
│   │   │   ├── Create/
│   │   │   │   ├── CreateSecretView.swift
│   │   │   │   └── CreateSecretViewModel.swift
│   │   │   ├── Created/
│   │   │   │   └── SecretCreatedView.swift   auto-shows UIActivityViewController
│   │   │   └── Viewer/
│   │   │       ├── ViewSecretView.swift
│   │   │       └── ViewSecretViewModel.swift
│   │   ├── Models/Secret.swift
│   │   ├── Services/
│   │   │   ├── SecretAPIService.swift     URLSession + RFC3339Nano date fix
│   │   │   └── CryptoService.swift        AES-256-CBC, EVP_BytesToKey
│   │   └── Utilities/SecretURLParser.swift  hex(64) + base62(43) key support
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Info.plist                     CFBundleURLSchemes: sekretlink
│       └── SekretLink.entitlements        applinks:sekret.link
├── .gitignore
└── README.md
```

---

## Known Gotchas

- **Server key length**: 64-char hex OR 43-char base62 (not 26-27 as the web app's loose regex implied)
- **`Data` field**: absent from POST create response, present only in GET read — model field must be optional
- **Date format**: Go marshals as `time.RFC3339Nano`; use `ISO8601DateFormatter` with `.withFractionalSeconds` option
- **Universal Links**: require `/.well-known/apple-app-site-association` on `sekret.link` server (not yet deployed); `sekretlink://` scheme works today

---

## Build

```bash
brew install tuist       # once
tuist generate           # creates SekretLink.xcodeproj
open SekretLink.xcworkspace
# ⌘R to run
```

## Test Deep Link

```bash
xcrun simctl openurl booted "sekretlink://view/{UUID}#{Key}&{password}"
```
