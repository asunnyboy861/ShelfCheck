import Foundation
import SwiftData

@Observable
final class ScanViewModel {
    var scannedISBN: String?
    var duplicateStatus: DuplicateStatus?
    var bookMetadata: BookMetadata?
    var isLookingUp = false
    var lookupError: String?
    var isAddingBook = false
    var addSuccess = false
    var lastScannedISBN: String?

    private let lookupService = BookLookupService()

    func handleScan(_ isbn: String, modelContext: ModelContext) {
        let normalized = isbn.normalizeISBN()
        guard normalized != lastScannedISBN else { return }
        lastScannedISBN = normalized
        scannedISBN = normalized
        duplicateStatus = nil
        bookMetadata = nil
        lookupError = nil

        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.isbn13 == normalized })
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if let exact = existing.first {
            duplicateStatus = .owned(exact)
            return
        }

        let allBooks = (try? modelContext.fetch(FetchDescriptor<Book>())) ?? []
        let fuzzyMatches = findFuzzyMatches(isbn: normalized, in: allBooks)
        if !fuzzyMatches.isEmpty {
            duplicateStatus = .maybeOwned(fuzzyMatches)
        } else {
            duplicateStatus = .newBook
        }

        lookupMetadata(for: normalized)
    }

    func resetScan() {
        lastScannedISBN = nil
        scannedISBN = nil
        duplicateStatus = nil
        bookMetadata = nil
        lookupError = nil
        isAddingBook = false
        addSuccess = false
    }

    func addBook(modelContext: ModelContext) {
        guard let isbn = scannedISBN else { return }
        isAddingBook = true

        let book: Book
        if let meta = bookMetadata {
            book = Book(isbn13: isbn, title: meta.title, authors: meta.authors, publisher: meta.publisher, publishYear: meta.publishYear, pageCount: meta.pageCount, coverURL: meta.coverURL, isbn10: meta.isbn10)
        } else {
            book = Book(isbn13: isbn, title: "Unknown Title", authors: [])
        }

        modelContext.insert(book)
        try? modelContext.save()
        addSuccess = true
        isAddingBook = false
    }

    private func lookupMetadata(for isbn: String) {
        isLookingUp = true
        Task {
            do {
                let meta = try await lookupService.lookup(isbn: isbn)
                await MainActor.run {
                    self.bookMetadata = meta
                    self.isLookingUp = false
                }
            } catch {
                await MainActor.run {
                    self.lookupError = error.localizedDescription
                    self.isLookingUp = false
                }
            }
        }
    }

    private func findFuzzyMatches(isbn: String, in books: [Book]) -> [Book] {
        guard let meta = bookMetadata else { return [] }
        return books.filter { existing in
            let titleDist = String.levenshtein(existing.title.normalizeTitle(), meta.title.normalizeTitle())
            let titleThreshold = max(meta.title.normalizeTitle().count, existing.title.normalizeTitle().count) / 3
            if titleDist <= max(titleThreshold, 2) {
                let authorMatch = existing.authors.contains { existingAuthor in
                    meta.authors.contains { metaAuthor in
                        existingAuthor.normalizeAuthor() == metaAuthor.normalizeAuthor()
                    }
                }
                if authorMatch { return true }
            }
            return false
        }
    }
}
