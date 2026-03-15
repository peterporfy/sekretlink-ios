import SwiftUI

struct SecretCreatedView: View {
    let created: CreatedSecret
    let onDone: () -> Void

    @State private var isCopied = false
    @State private var showShareSheet = false
    @State private var showDestroyConfirm = false
    @State private var isDestroying = false
    @State private var destroyError: String?
    @State private var isDestroyed = false

    private let api = SecretAPIService()

    var body: some View {
        Form {
            Section("Share Link") {
                Text(created.shareURL)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }

            Section {
                // Primary CTA — native iOS share sheet
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Share via…", systemImage: "square.and.arrow.up")
                            .bold()
                        Spacer()
                    }
                }

                Button {
                    UIPasteboard.general.string = created.shareURL
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                } label: {
                    Label(
                        isCopied ? "Copied!" : "Copy Link",
                        systemImage: isCopied ? "checkmark" : "doc.on.doc"
                    )
                }
            }

            if let expire = created.expire {
                Section("Details") {
                    LabeledContent("Expires") {
                        Text(expire, style: .relative)
                    }
                }
            }

            Section {
                if isDestroyed {
                    Label("Secret destroyed", systemImage: "trash.fill")
                        .foregroundStyle(.secondary)
                } else {
                    Button(role: .destructive) {
                        showDestroyConfirm = true
                    } label: {
                        if isDestroying {
                            HStack {
                                ProgressView()
                                Text("Destroying…")
                            }
                        } else {
                            Label("Destroy Now", systemImage: "trash")
                        }
                    }
                    .disabled(isDestroying || created.deleteKey.isEmpty)
                }
            } footer: {
                Text("Destroying immediately deletes the secret so nobody can read it.")
            }
        }
        .navigationTitle("Link Created")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onDone)
            }
        }
        // Auto-show share sheet when the link is first created
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showShareSheet = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [created.shareURL])
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Destroy this secret?",
            isPresented: $showDestroyConfirm,
            titleVisibility: .visible
        ) {
            Button("Destroy", role: .destructive) {
                Task { await destroySecret() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The secret will be permanently deleted and the link will stop working.")
        }
        .alert("Error", isPresented: Binding(
            get: { destroyError != nil },
            set: { if !$0 { destroyError = nil } }
        )) {
            Button("OK") { destroyError = nil }
        } message: {
            Text(destroyError ?? "")
        }
    }

    private func destroySecret() async {
        isDestroying = true
        do {
            try await api.deleteSecret(
                uuid: created.uuid,
                key: created.key,
                deleteKey: created.deleteKey
            )
            isDestroyed = true
        } catch {
            destroyError = error.localizedDescription
        }
        isDestroying = false
    }
}

/// UIKit wrapper for UIActivityViewController — the native iOS share sheet.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
