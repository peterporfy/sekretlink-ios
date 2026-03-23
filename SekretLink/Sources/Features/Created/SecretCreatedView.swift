import SwiftUI

struct SecretCreatedView: View {
    let created: CreatedSecret
    let onDone: () -> Void

    @State private var showShareSheet = false
    @State private var showDestroyConfirm = false
    @State private var showNewSecretConfirm = false
    @State private var isDestroying = false
    @State private var destroyError: String?
    @State private var isDestroyed = false

    private let api = SecretAPIService()

    var body: some View {
        Form {
            Section("Share Link") {
                Text(created.shareURL)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.sekret800)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
            .listRowBackground(Theme.sekret100)

            Section {
                // Primary CTA
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Share via…", systemImage: "square.and.arrow.up")
                            .bold()
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .listRowBackground(Theme.sekret600)

                CopyButton(text: created.shareURL, label: "Copy Link")
            }

            if let expire = created.expire {
                Section("Details") {
                    LabeledContent("Expires") {
                        Text(expire, style: .relative)
                            .foregroundStyle(Theme.sekret700)
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
                            HStack { ProgressView(); Text("Destroying…") }
                        } else {
                            Label("Destroy Now", systemImage: "trash")
                        }
                    }
                    .disabled(isDestroying || created.deleteKey.isEmpty)
                }
            } footer: {
                Text("Destroying immediately deletes the secret so nobody can read it.")
            }

            Section {
                Button {
                    if isDestroyed {
                        onDone()
                    } else {
                        showNewSecretConfirm = true
                    }
                } label: {
                    Label("New Secret", systemImage: "plus.circle")
                        .foregroundStyle(Theme.sekret600)
                }
            }
        }
        .navigationTitle("Link Created")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onDone)
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
            Button("Destroy", role: .destructive) { Task { await destroySecret() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The secret will be permanently deleted and the link will stop working.")
        }
        .confirmationDialog(
            "Start a new secret?",
            isPresented: $showNewSecretConfirm,
            titleVisibility: .visible
        ) {
            Button("New Secret", role: .destructive) { onDone() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current secret is still alive and accessible via the link — but once you leave this screen you won't be able to see the link again.")
        }
        .alert("Error", isPresented: Binding(
            get: { destroyError != nil },
            set: { if !$0 { destroyError = nil } }
        )) {
            Button("OK") { destroyError = nil }
        } message: {
            Text(destroyError ?? "")
        }
        .tint(Theme.accent)
    }

    private func destroySecret() async {
        isDestroying = true
        do {
            try await api.deleteSecret(uuid: created.uuid, key: created.key, deleteKey: created.deleteKey)
            isDestroyed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { onDone() }
        } catch {
            destroyError = error.localizedDescription
        }
        isDestroying = false
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
