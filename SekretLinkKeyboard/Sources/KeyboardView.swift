import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    let onNextKeyboard: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            composeArea
            Divider()
            optionsRow
            Divider()
            actionRow
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Compose area

    private var composeArea: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.secretText.isEmpty {
                Text("Type your secret here…")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            TextEditor(text: $viewModel.secretText)
                .frame(minHeight: 80, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    // MARK: - Options row

    private var optionsRow: some View {
        HStack(spacing: 12) {
            expirationPicker
            Spacer()
            maxReadsControl
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var expirationPicker: some View {
        HStack(spacing: 4) {
            Text("Expires:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Expires", selection: $viewModel.selectedExpire) {
                ForEach(ExpireDuration.allCases) { duration in
                    Text(duration.label).tag(duration)
                }
            }
            .pickerStyle(.menu)
            .font(.caption)
            .tint(Theme.accent)
        }
    }

    private var maxReadsControl: some View {
        HStack(spacing: 6) {
            Text("Reads:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                if viewModel.maxReads > 1 { viewModel.maxReads -= 1 }
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(viewModel.maxReads > 1 ? Theme.accent : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.maxReads <= 1)

            Text("\(viewModel.maxReads)")
                .font(.caption.monospacedDigit())
                .frame(minWidth: 20)

            Button {
                if viewModel.maxReads < 100 { viewModel.maxReads += 1 }
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(viewModel.maxReads < 100 ? Theme.accent : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.maxReads >= 100)
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack {
            nextKeyboardButton
            Spacer()
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            createButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var nextKeyboardButton: some View {
        Button(action: onNextKeyboard) {
            Image(systemName: "globe")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button {
            Task { await viewModel.createSekretLink() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("Create Sekret Link")
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(buttonBackground)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading || viewModel.secretText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var buttonBackground: some ShapeStyle {
        if viewModel.isLoading || viewModel.secretText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AnyShapeStyle(Color.secondary)
        }
        return AnyShapeStyle(LinearGradient(
            colors: [Theme.gradientMid, Theme.gradientDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
}
