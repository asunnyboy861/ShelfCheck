import SwiftUI

struct ContactSupportView: View {
    @State private var selectedSubject: SubjectOption = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var submitResult: SubmitResult?
    @State private var showSuccessAlert = false

    private let backendURL = "https://feedback-board.iocompile67692.workers.dev"

    enum SubjectOption: String, CaseIterable {
        case general = "General"
        case featureSuggestion = "Feature Suggestion"
        case bugReport = "Bug Report"
        case usageQuestion = "Usage Question"
        case performanceIssue = "Performance Issue"
        case uiImprovement = "UI Improvement"
        case other = "Other"

        var icon: String {
            switch self {
            case .general: return "message"
            case .featureSuggestion: return "lightbulb"
            case .bugReport: return "ladybug"
            case .usageQuestion: return "questionmark.circle"
            case .performanceIssue: return "gauge.with.dots.needle.67percent"
            case .uiImprovement: return "paintbrush"
            case .other: return "ellipsis"
            }
        }
    }

    enum SubmitResult: Equatable {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(SubjectOption.allCases, id: \.self) { option in
                        subjectTile(option)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                if selectedSubject == .other {
                    TextField("Custom subject", text: $customSubject)
                }
            } header: {
                Text("Subject")
            }

            Section {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            }

            Section {
                TextEditor(text: $message)
                    .frame(minHeight: 120)
            } header: {
                Text("Message")
            }

            Section {
                Button {
                    submitFeedback()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 22)
                    } else {
                        Text("Submit Feedback")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 22)
                    }
                }
                .listRowBackground(Color.shelfGreen)
                .foregroundStyle(.white)
                .disabled(isSubmitting || name.isEmpty || email.isEmpty || message.isEmpty)
            }
        }
        .navigationTitle("Contact Support")
        .alert("Thank You!", isPresented: $showSuccessAlert) {
            Button("OK") {
                if submitResult != nil { resetForm() }
            }
        } message: {
            Text(submitResult == .success ? "Your feedback has been sent successfully." : "Failed to send feedback. Please try again later.")
        }
    }

    private func subjectTile(_ option: SubjectOption) -> some View {
        let isSelected = selectedSubject == option
        return Button {
            selectedSubject = option
        } label: {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.title3)
                Text(option.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.shelfGreen.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color.shelfGreen : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.shelfGreen : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func submitFeedback() {
        isSubmitting = true
        let subject = selectedSubject == .other ? customSubject : selectedSubject.rawValue

        let body: [String: String] = [
            "name": name,
            "email": email,
            "subject": subject,
            "message": message,
            "app_name": "ShelfCheck"
        ]

        guard let url = URL(string: "\(backendURL)/api/feedback") else {
            isSubmitting = false
            submitResult = .failure("Invalid URL")
            showSuccessAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    submitResult = .failure(error.localizedDescription)
                } else if let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          json["success"] as? Bool == true {
                    submitResult = .success
                } else {
                    submitResult = .failure("Server error")
                }
                showSuccessAlert = true
            }
        }.resume()
    }

    private func resetForm() {
        name = ""
        email = ""
        message = ""
        customSubject = ""
        selectedSubject = .general
        submitResult = nil
    }
}
