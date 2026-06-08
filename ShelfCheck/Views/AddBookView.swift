import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isbn = ""
    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var year = ""
    @State private var pages = ""
    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var duplicateWarning: String?
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage("defaultShelfLocation") private var defaultShelfLocation = ""
    @State private var showPaywall = false

    private let lookupService = BookLookupService()

    var body: some View {
        NavigationStack {
            Form {
                Section("ISBN Lookup") {
                    HStack {
                        TextField("Enter ISBN-13 or ISBN-10", text: $isbn)
                            .keyboardType(.numberPad)
                        Button {
                            lookupISBN()
                        } label: {
                            if isLookingUp {
                                ProgressView()
                            } else {
                                Text("Lookup")
                            }
                        }
                        .disabled(isbn.isEmpty || isLookingUp)
                    }
                    if let error = lookupError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if let warning = duplicateWarning {
                        Text(warning)
                            .font(.caption)
                            .foregroundStyle(Color.shelfAmber)
                    }
                }

                Section("Book Details") {
                    TextField("Title *", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    HStack {
                        TextField("Year", text: $year)
                            .keyboardType(.numberPad)
                        TextField("Pages", text: $pages)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addBook() }
                        .disabled(title.isEmpty || isbn.isEmpty)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }

    private func lookupISBN() {
        isLookingUp = true
        lookupError = nil
        Task {
            do {
                let meta = try await lookupService.lookup(isbn: isbn.normalizeISBN())
                await MainActor.run {
                    title = meta.title
                    author = meta.authors.joined(separator: ", ")
                    publisher = meta.publisher ?? publisher
                    if let year = meta.publishYear { self.year = String(year) }
                    if let pages = meta.pageCount { self.pages = String(pages) }
                    isLookingUp = false
                }
            } catch {
                await MainActor.run {
                    lookupError = "Could not find book information"
                    isLookingUp = false
                }
            }
        }
    }

    private func addBook() {
        let bookCount = (try? modelContext.fetchCount(FetchDescriptor<Book>())) ?? 0
        guard purchaseManager.canAddBook(currentCount: bookCount) else {
            showPaywall = true
            return
        }

        let normalizedISBN = isbn.normalizeISBN()

        // Check for duplicate
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.isbn13 == normalizedISBN })
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if let existingBook = existing.first {
            duplicateWarning = "This book is already in your shelf: \(existingBook.title)"
            return
        }

        let book = Book(
            isbn13: normalizedISBN,
            title: title,
            authors: author.isEmpty ? [] : author.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            publisher: publisher.isEmpty ? nil : publisher,
            publishYear: Int(year),
            pageCount: Int(pages)
        )
        book.shelfLocation = defaultShelfLocation.isEmpty ? nil : defaultShelfLocation
        modelContext.insert(book)
        try? modelContext.save()
        dismiss()
    }
}
