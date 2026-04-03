# SekretLink iOS — Claude Guide

Native iOS client for [sekret.link](https://sekret.link) one-time secret sharing, built with Tuist.

## Key Docs

- [`docs/PLAN.md`](docs/PLAN.md) — implementation status, API spec, encryption details, project structure, known gotchas

## Build

```bash
brew install tuist
tuist generate
open SekretLink.xcworkspace
```

## Tech Notes

- **Language:** Swift, SwiftUI, iOS 16+
- **Build system:** Tuist (`Project.swift`)
- **Crypto:** AES-256-CBC via CommonCrypto (no third-party deps), EVP_BytesToKey compatible with crypto-js
- **Deep links:** `sekretlink://` custom scheme (universal links pending server-side AASA file)
- **Dates:** Go RFC3339Nano — use `ISO8601DateFormatter` with `.withFractionalSeconds`
