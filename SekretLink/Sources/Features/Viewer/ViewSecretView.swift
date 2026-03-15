import SwiftUI

struct ViewSecretView: View {
    @Binding var incomingURL: URL?
    @StateObject private var viewModel = ViewSecretViewModel()

    var body: some View {
        NavigationStack {
            Form {
                if let secret = viewModel.revealedSecret {
                    revealedSection(secret)
                } else if let parsed = viewModel.parsedURL {
                    readyToRevealSection(parsed)
                } else {
                    pasteSection
                }
            }
            .navigationTitle("Open Secret")
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: incomingURL) { url in
                if let url {
                    viewModel.reset()
                    viewModel.loadURL(url)
                    incomingURL = nil
                }
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Sections

    private var pasteSection: some View {
        Group {
            Section("Secret Link") {
                TextField("https://sekret.link/view/…", text: $viewModel.urlText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { viewModel.parseManualURL() }
            }

            Section {
                Button {
                    viewModel.parseManualURL()
                } label: {
                    HStack {
                        Spacer()
                        Text("Open Link")
                            .bold()
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .listRowBackground(
                    viewModel.urlText.isEmpty ? Theme.sekret600.opacity(0.5) : Theme.sekret600
                )
                .disabled(viewModel.urlText.isEmpty)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.sekret700)
                    Text("Paste a link you received from sekret.link. The secret can only be read once — after that the link stops working.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func readyToRevealSection(_ parsed: ParsedSecretURL) -> some View {
        Section("Ready to Reveal") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Secret ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(parsed.uuid)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.sekret800)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Theme.sekret100)

        Section {
            Button {
                Task { await viewModel.revealSecret() }
            } label: {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(.white)
                        Text("Fetching…").foregroundStyle(.white)
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Label("Reveal Secret", systemImage: "eye")
                            .bold()
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
            }
            .listRowBackground(viewModel.isLoading ? Theme.sekret600.opacity(0.7) : Theme.sekret600)
            .disabled(viewModel.isLoading)
        } footer: {
            Text("The secret will be fetched and decrypted on your device. This may consume the one-time read.")
        }

        Section {
            Button(role: .destructive) { viewModel.reset() } label: {
                Label("Clear", systemImage: "xmark.circle")
            }
        }
    }

    @ViewBuilder
    private func revealedSection(_ secret: String) -> some View {
        Section("Secret") {
            Text(secret)
                .font(.body)
                .foregroundStyle(Theme.sekret900)
                .textSelection(.enabled)
                .padding(.vertical, 4)
        }
        .listRowBackground(Theme.sekret50)

        Section {
            Button {
                UIPasteboard.general.string = secret
            } label: {
                Label("Copy Secret", systemImage: "doc.on.doc")
                    .foregroundStyle(Theme.sekret600)
            }
        }

        Section {
            Button(role: .destructive) { viewModel.reset() } label: {
                Label("Close & Clear", systemImage: "xmark.circle")
            }
        } footer: {
            Text("The secret has been revealed and is now gone. Clear it from this screen when you're done.")
        }
    }
}
