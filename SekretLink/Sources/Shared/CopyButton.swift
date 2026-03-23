import SwiftUI

/// A button that copies `text` to the clipboard and briefly shows "Copied!" feedback.
struct CopyButton: View {
    let text: String
    let label: String

    @State private var isCopied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
        } label: {
            Label(
                isCopied ? "Copied!" : label,
                systemImage: isCopied ? "checkmark" : "doc.on.doc"
            )
            .foregroundStyle(isCopied ? Theme.sekret700 : Theme.sekret600)
        }
    }
}
