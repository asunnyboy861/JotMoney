import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubject = FeedbackSubject.general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var feedbackMessage: String?
    @State private var feedbackIsError = false

    private let maxMessageLength = 1000

    private var subjectValue: String {
        selectedSubject == .other
            ? (customSubject.isEmpty ? "Other" : customSubject)
            : selectedSubject.title
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && isValidEmail(email)
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && (selectedSubject != .other || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("What is this about?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(FeedbackSubject.gridCases) { subject in
                            subjectTile(subject)
                        }
                    }

                    subjectTile(FeedbackSubject.other, fullWidth: true)

                    if selectedSubject == .other {
                        TextField("Your topic", text: $customSubject)
                            .padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.textPrimary)
                            .accessibilityLabel("Custom subject")
                    }

                    fieldGroup(title: "Name") {
                        TextField("Your name", text: $name)
                            .textContentType(.name)
                            .accessibilityLabel("Your name")
                    }

                    fieldGroup(title: "Email") {
                        TextField("yourname@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("Your email address")
                    }

                    fieldGroup(title: "Message") {
                        TextField("Tell us what's on your mind…", text: $message, axis: .vertical)
                            .lineLimit(5...10)
                            .accessibilityLabel("Your message")
                        HStack {
                            Spacer()
                            Text("\(message.count) / \(maxMessageLength)")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    Button {
                        submit()
                    } label: {
                        HStack(spacing: 8) {
                            if isSending { ProgressView().tint(Color.black) }
                            Text(isSending ? "Sending…" : "Submit")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(enabled: canSubmit && !isSending))
                    .disabled(!canSubmit || isSending)
                    .accessibilityLabel("Submit feedback")

                    if let feedbackMessage {
                        Text(feedbackMessage)
                            .font(.caption)
                            .foregroundStyle(feedbackIsError ? Theme.warning : Theme.mint)
                    }

                    Text("We only use your email to respond to this feedback.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .onChange(of: message) { _, newValue in
                if newValue.count > maxMessageLength {
                    message = String(newValue.prefix(maxMessageLength))
                }
            }
        }
    }

    private func subjectTile(_ subject: FeedbackSubject, fullWidth: Bool = false) -> some View {
        let selected = selectedSubject == subject
        return Button {
            selectedSubject = subject
        } label: {
            VStack(spacing: 7) {
                Image(systemName: subject.symbol)
                    .font(.system(size: 17, weight: .semibold))
                Text(subject.title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(selected ? Color.black : Theme.textSecondary)
            .background(selected ? Theme.mint : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : Theme.separator, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.black.opacity(0.7))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(subject.title) subject")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func fieldGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            VStack(alignment: .leading, spacing: 6) {
                content()
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    private func submit() {
        guard canSubmit else { return }
        isSending = true
        feedbackMessage = nil
        let payload = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: subjectValue,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "JotMoney"
        )
        Task {
            do {
                try await FeedbackClient.send(payload)
                feedbackIsError = false
                feedbackMessage = "Thank you! Your feedback has been sent."
                name = ""
                email = ""
                message = ""
                selectedSubject = .general
                customSubject = ""
            } catch {
                feedbackIsError = true
                feedbackMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

enum FeedbackSubject: String, CaseIterable, Identifiable {
    case general
    case feature
    case bug
    case usage
    case performance
    case ui
    case other

    var id: String { rawValue }

    static var gridCases: [FeedbackSubject] {
        [.general, .feature, .bug, .usage, .performance, .ui]
    }

    var title: String {
        switch self {
        case .general: return "General"
        case .feature: return "Feature Suggestion"
        case .bug: return "Bug Report"
        case .usage: return "Usage Question"
        case .performance: return "Performance Issue"
        case .ui: return "UI Improvement"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .feature: return "lightbulb.fill"
        case .bug: return "ant.fill"
        case .usage: return "questionmark.circle.fill"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .ui: return "paintpalette.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

enum FeedbackClient {
    static let endpoint = URL(string: "https://msg.calcs.top/api/feedback")!

    static func send(_ payload: FeedbackRequest) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FeedbackError(message: "Something went wrong. Please try again.")
        }
        guard (200..<300).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let serverMessage = json["error"] as? String, !serverMessage.isEmpty {
                throw FeedbackError(message: serverMessage)
            }
            throw FeedbackError(message: "Something went wrong. Please try again.")
        }
    }
}

struct FeedbackError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
