import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.addedDate, order: .reverse) private var books: [Book]
    @State private var viewModel = LibraryViewModel()
    @State private var purchaseManager = PurchaseManager()
    @State private var showPaywall = false
    @State private var selectedBook: Book?
    @State private var exportItem: ExportItem?
    @State private var showExportSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    emptyState
                } else {
                    bookList
                }
            }
            .navigationTitle("My Shelf")
            .searchable(text: $viewModel.searchText, prompt: "Search by title, author, or ISBN")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        sortMenu
                        if purchaseManager.isProUser {
                            Button {
                                exportCSV()
                            } label: {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                        if !viewModel.selectedTag.isEmptyOrNil {
                            Button {
                                viewModel.selectedTag = nil
                            } label: {
                                Label("Clear Filter", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
            .sheet(item: $exportItem) { item in
                ActivityViewController(activityItems: [item.url])
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your Shelf is Empty", systemImage: "books.vertical")
        } description: {
            Text("Scan a book barcode to get started")
        }
    }

    private var bookList: some View {
        List(selection: $selectedBook) {
            let filtered = viewModel.filteredBooks(from: books)
            let limit = purchaseManager.isProUser ? filtered.count : min(filtered.count, purchaseManager.freeBookLimit)

            ForEach(Array(filtered.prefix(limit)), id: \.isbn13) { book in
                BookRowView(book: book)
                    .onTapGesture {
                        selectedBook = book
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteBook(book, context: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleRead(book)
                        } label: {
                            Label(book.isRead ? "Unread" : "Read", systemImage: book.isRead ? "book.closed" : "book.fill")
                        }
                        .tint(Color.shelfGreen)
                    }
            }

            if !purchaseManager.isProUser && books.count > purchaseManager.freeBookLimit {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Upgrade to Pro for Unlimited Books")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.shelfGreen)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var sortMenu: some View {
        Group {
            Section("Sort By") {
                ForEach(LibraryViewModel.SortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            if let coverURL = book.coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    default:
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.shelfGreen.opacity(0.15))
                            .frame(width: 50, height: 70)
                            .overlay {
                                Image(systemName: "book")
                                    .foregroundStyle(Color.shelfGreen)
                            }
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.shelfGreen.opacity(0.15))
                    .frame(width: 50, height: 70)
                    .overlay {
                        Image(systemName: "book")
                            .foregroundStyle(Color.shelfGreen)
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                if !book.authors.isEmpty {
                    Text(book.authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    if book.isRead {
                        Text("Read")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.shelfGreen.opacity(0.15))
                            .foregroundStyle(Color.shelfGreen)
                            .clipShape(Capsule())
                    }
                    if book.isLent {
                        Text("Lent")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.shelfAmber.opacity(0.15))
                            .foregroundStyle(Color.shelfAmber)
                            .clipShape(Capsule())
                    }
                    if !book.tags.isEmpty {
                        Text(book.tags.first ?? "")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            if book.isLent, let person = book.lentTo {
                Text(person)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension Optional where Wrapped == String {
    var isEmptyOrNil: Bool { self?.isEmpty ?? true }
}

extension LibraryView {
    func exportCSV() {
        guard let url = ExportService.exportToCSV(books: books) else { return }
        exportItem = ExportItem(url: url)
    }
}

struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
