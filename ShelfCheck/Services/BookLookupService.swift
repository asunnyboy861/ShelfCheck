import Foundation

actor BookLookupService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func lookup(isbn: String) async throws -> BookMetadata {
        do {
            return try await lookupOpenLibrary(isbn: isbn)
        } catch {
            do {
                return try await lookupGoogleBooks(isbn: isbn)
            } catch {
                return BookMetadata(title: "ISBN: \(isbn)", authors: [], publisher: nil, publishYear: nil, pageCount: nil, coverURL: nil, isbn10: nil)
            }
        }
    }

    private func lookupOpenLibrary(isbn: String) async throws -> BookMetadata {
        let url = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bookData = json?["ISBN:\(isbn)"] as? [String: Any] else {
            throw LookupError.notFound
        }

        let title = bookData["title"] as? String ?? "Unknown"
        let authors = (bookData["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
        let publisher = (bookData["publishers"] as? [[String: Any]])?.first?["name"] as? String
        let publishYear = (bookData["publish_date"] as? String).flatMap { extractYear(from: $0) }
        let pageCount = bookData["number_of_pages"] as? Int
        let coverURL = (bookData["cover"] as? [String: Any])?["medium"] as? String
        let isbn10List = (bookData["identifiers"] as? [String: Any])?["isbn_10"] as? [String]
        let isbn10 = isbn10List?.first

        return BookMetadata(title: title, authors: authors, publisher: publisher, publishYear: publishYear, pageCount: pageCount, coverURL: coverURL, isbn10: isbn10)
    }

    private func lookupGoogleBooks(isbn: String) async throws -> BookMetadata {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        let url = URL(string: urlString)!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let items = json?["items"] as? [[String: Any]], let first = items.first,
              let volumeInfo = first["volumeInfo"] as? [String: Any] else {
            throw LookupError.notFound
        }

        let title = volumeInfo["title"] as? String ?? "Unknown"
        let authors = volumeInfo["authors"] as? [String] ?? []
        let publisher = volumeInfo["publisher"] as? String
        let publishYear = (volumeInfo["publishedDate"] as? String).flatMap { extractYear(from: $0) }
        let pageCount = volumeInfo["pageCount"] as? Int
        let coverURLString = (volumeInfo["imageLinks"] as? [String: Any])?["thumbnail"] as? String
        let coverURL = coverURLString?.replacingOccurrences(of: "http://", with: "https://")
        let industryIdentifiers = volumeInfo["industryIdentifiers"] as? [[String: Any]]
        let isbn10 = industryIdentifiers?.first(where: { $0["type"] as? String == "ISBN_10" })?["identifier"] as? String

        return BookMetadata(title: title, authors: authors, publisher: publisher, publishYear: publishYear, pageCount: pageCount, coverURL: coverURL, isbn10: isbn10)
    }

    private func extractYear(from dateStr: String) -> Int? {
        let components = dateStr.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for comp in components {
            if let year = Int(comp), year > 1000, year < 2100 {
                return year
            }
        }
        return nil
    }

    enum LookupError: Error {
        case notFound
    }
}
