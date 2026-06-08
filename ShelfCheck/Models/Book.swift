import Foundation
import SwiftData

@Model
final class Book {
    var isbn13: String
    var isbn10: String?
    var title: String
    var authors: [String]
    var publisher: String?
    var publishYear: Int?
    var pageCount: Int?
    var language: String?
    var coverURL: String?
    @Attribute(.externalStorage) var coverData: Data?
    var tags: [String]
    var shelfLocation: String?
    var addedDate: Date
    var isRead: Bool
    var isLent: Bool
    var lentTo: String?
    var lentDate: Date?
    var notes: String?

    init(isbn13: String, title: String, authors: [String], publisher: String? = nil, publishYear: Int? = nil, pageCount: Int? = nil, language: String? = nil, coverURL: String? = nil, isbn10: String? = nil) {
        self.isbn13 = isbn13
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishYear = publishYear
        self.pageCount = pageCount
        self.language = language
        self.coverURL = coverURL
        self.isbn10 = isbn10
        self.tags = []
        self.addedDate = Date()
        self.isRead = false
        self.isLent = false
    }
}
