import SwiftUI

struct QuickEntryBar: View {
    @Binding var text: String
    var isListening: Bool
    var onSubmit: () -> Void
    var onVoice: () -> Void
    var onReceipt: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mint)
                TextField("coffee 5.5", text: $text)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($focused)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit(onSubmit)
                    .accessibilityLabel("Quick entry")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(focused ? Theme.mint.opacity(0.6) : Theme.separator, lineWidth: 1)
            )

            iconButton(symbol: isListening ? "waveform" : "mic.fill", tint: isListening ? Theme.warning : Theme.textSecondary, label: "Voice entry", action: onVoice)
            iconButton(symbol: "doc.viewfinder", tint: Theme.textSecondary, label: "Scan a receipt", action: onReceipt)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Theme.background)
    }

    private func iconButton(symbol: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
