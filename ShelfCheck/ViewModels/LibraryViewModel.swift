import Foundation
import SwiftData

@Observable
final class LibraryViewModel {
    var searchText = ""
    var selectedTag: String?
    var sortOrder: SortOrder = .addedDate
    var showingAddSheet = false
    var bookToDelete: Book?
    var showingDeleteAlert = false

    enum SortOrder: String, CaseIterable {
        case addedDate = "Added Date"
        case title = "Title"
        case author = "Author"
        case year = "Year"
    }

    func allTags(from books: [Book]) -> [String] {
        var tags = Set<String>()
        for book in books {
            for tag in book.tags {
                tags.insert(tag)
            }
        }
        return tags.sorted()
    }

    func filteredBooks(from books: [Book]) -> [Book] {
        var result = books

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.authors.joined(separator: " ").lowercased().contains(query) ||
                $0.isbn13.contains(query) ||
                ($0.isbn10 ?? "").contains(query) ||
                ($0.publisher ?? "").lowercased().contains(query)
            }
        }

        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        switch sortOrder {
        case .addedDate: result.sort { $0.addedDate > $1.addedDate }
        case .title: result.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .author: result.sort { $0.authors.first?.lowercased() ?? "" < $1.authors.first?.lowercased() ?? "" }
        case .year: result.sort { ($0.publishYear ?? 0) > ($1.publishYear ?? 0) }
        }

        return result
    }

    func deleteBook(_ book: Book, context: ModelContext) {
        context.delete(book)
        try? context.save()
    }

    func toggleRead(_ book: Book) {
        book.isRead.toggle()
    }

    func toggleLent(_ book: Book, to person: String?) {
        book.isLent.toggle()
        if book.isLent {
            book.lentTo = person
            book.lentDate = Date()
        } else {
            book.lentTo = nil
            book.lentDate = nil
        }
    }

    func addTag(_ tag: String, to book: Book) {
        if !book.tags.contains(tag) {
            book.tags.append(tag)
        }
    }

    func removeTag(_ tag: String, from book: Book) {
        book.tags.removeAll { $0 == tag }
    }
}
