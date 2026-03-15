import SwiftUI

struct CreateSecretView: View {
    @StateObject private var viewModel = CreateSecretViewModel()
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Secret") {
                    TextEditor(text: $viewModel.secretText)
                        .frame(minHeight: 120)
                        .focused($isEditorFocused)
                        .overlay(alignment: .topLeading) {
                            if viewModel.secretText.isEmpty {
                                Text("Enter your secret note or password…")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Expiration") {
                    Picker("Expires after", selection: $viewModel.selectedExpire) {
                        ForEach(ExpireDuration.allCases) { duration in
                            Text(duration.label).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Access") {
                    Stepper(
                        "Max reads: \(viewModel.maxReads)",
                        value: $viewModel.maxReads,
                        in: 1...100
                    )
                }

                Section {
                    Button {
                        isEditorFocused = false
                        Task { await viewModel.submit() }
                    } label: {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Create Secret Link")
                                    .bold()
                                Spacer()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.secretText.isEmpty)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Secret")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isEditorFocused = false }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .navigationDestination(isPresented: Binding(
                get: { viewModel.createdResult != nil },
                set: { if !$0 { viewModel.createdResult = nil } }
            )) {
                if let result = viewModel.createdResult {
                    SecretCreatedView(created: result) {
                        viewModel.createdResult = nil
                        viewModel.secretText = ""
                    }
                }
            }
        }
    }
}
