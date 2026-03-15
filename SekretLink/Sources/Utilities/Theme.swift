import SwiftUI

/// Color palette sourced from the sekret.link web frontend (tailwind.config.js).
/// https://github.com/Ajnasz/sekret.link-ui
enum Theme {
    // MARK: - Sekret palette

    /// sekret-50  #fdf6fb — near-white tinted background
    static let sekret50  = Color(hex: 0xfdf6fb)
    /// sekret-100 #fbecf8 — light section fill
    static let sekret100 = Color(hex: 0xfbecf8)
    /// sekret-200 #f7d7f1
    static let sekret200 = Color(hex: 0xf7d7f1)
    /// sekret-300 #efb8e2 — soft accent / icon tint
    static let sekret300 = Color(hex: 0xefb8e2)
    /// sekret-400 #e58dd0
    static let sekret400 = Color(hex: 0xe58dd0)
    /// sekret-500 #d560b8
    static let sekret500 = Color(hex: 0xd560b8)
    /// sekret-600 #b33f94 — primary action / tint colour
    static let sekret600 = Color(hex: 0xb33f94)
    /// sekret-700 #98337b
    static let sekret700 = Color(hex: 0x98337b)
    /// sekret-800 #7d2b65
    static let sekret800 = Color(hex: 0x7d2b65)
    /// sekret-900 #672853
    static let sekret900 = Color(hex: 0x672853)
    /// sekret-950 #430f32 — darkest; used as deep background
    static let sekret950 = Color(hex: 0x430f32)

    // MARK: - Semantic aliases

    /// App tint / primary interactive colour
    static let accent      = sekret600
    /// Gradient start (top-left corner of the icon)
    static let gradientDark  = sekret950
    /// Gradient end (bottom-right corner of the icon)
    static let gradientMid   = sekret700
}

// MARK: - Convenience init

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >>  8) & 0xff) / 255
        let b = Double( hex        & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
