import Foundation

struct ExportService {
    static func exportToCSV(books: [Book]) -> URL? {
        var csv = "ISBN-13,Title,Authors,Publisher,Year,Pages,Tags,Shelf Location,Read,Lent,Lent To,Notes\n"

        for book in books {
            let authors = book.authors.joined(separator: "; ")
            let tags = book.tags.joined(separator: "; ")
            let title = book.title.replacingOccurrences(of: "\"", with: "\"\"")
            let publisher = (book.publisher ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let shelfLocation = (book.shelfLocation ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let notes = (book.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let lentTo = (book.lentTo ?? "").replacingOccurrences(of: "\"", with: "\"\"")

            csv += "\(book.isbn13),\"\(title)\",\"\(authors)\",\"\(publisher)\",\(book.publishYear ?? 0),\(book.pageCount ?? 0),\"\(tags)\",\"\(shelfLocation)\",\(book.isRead),\(book.isLent),\"\(lentTo)\",\"\(notes)\"\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ShelfCheck_Export_\(Date().timeIntervalSince1970).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
