import Foundation

enum DuplicateStatus: Equatable {
    case owned(Book)
    case maybeOwned([Book])
    case newBook

    static func == (lhs: DuplicateStatus, rhs: DuplicateStatus) -> Bool {
        switch (lhs, rhs) {
        case (.newBook, .newBook): return true
        case (.owned(let a), .owned(let b)): return a.isbn13 == b.isbn13
        case (.maybeOwned(let a), .maybeOwned(let b)): return a.map(\.isbn13) == b.map(\.isbn13)
        default: return false
        }
    }
}

struct BookMetadata {
    let title: String
    let authors: [String]
    let publisher: String?
    let publishYear: Int?
    let pageCount: Int?
    let coverURL: String?
    let isbn10: String?
}
