import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book
    @State private var isEditing = false
    @State private var newTag = ""
    @State private var showLentSheet = false
    @State private var lentPersonName = ""
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    infoSection
                    tagsSection
                    lendingSection
                    notesSection
                }
                .padding()
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            .sheet(isPresented: $showLentSheet) {
                lendingSheet
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            if let coverURL = book.coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.shelfGreen.opacity(0.15))
                            .frame(width: 90, height: 130)
                            .overlay {
                                Image(systemName: "book")
                                    .font(.title)
                                    .foregroundStyle(Color.shelfGreen)
                            }
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.shelfGreen.opacity(0.15))
                    .frame(width: 90, height: 130)
                    .overlay {
                        Image(systemName: "book")
                            .font(.title)
                            .foregroundStyle(Color.shelfGreen)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.title3.bold())
                if !book.authors.isEmpty {
                    Text(book.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let publisher = book.publisher {
                    Text(publisher)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let year = book.publishYear {
                        Text(String(year))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.shelfGreen.opacity(0.1))
                            .foregroundStyle(Color.shelfGreen)
                            .clipShape(Capsule())
                    }
                    if let pages = book.pageCount {
                        Text("\(pages) pages")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("ISBN-13", value: book.isbn13)
            if let isbn10 = book.isbn10 {
                LabeledContent("ISBN-10", value: isbn10)
            }
            if let language = book.language {
                LabeledContent("Language", value: language)
            }
            LabeledContent("Added", value: book.addedDate.formatted(date: .abbreviated, time: .omitted))
        }
        .font(.subheadline)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline.bold())

            FlowLayout(spacing: 8) {
                ForEach(book.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.caption)
                        if isEditing && purchaseManager.isProUser {
                            Button {
                                book.tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }

                if isEditing && purchaseManager.isProUser {
                    HStack(spacing: 4) {
                        TextField("Add tag", text: $newTag)
                            .font(.caption)
                            .textFieldStyle(.plain)
                            .frame(width: 80)
                            .onSubmit { addTag() }
                        Button { addTag() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var lendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lending")
                .font(.subheadline.bold())

            if book.isLent {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Lent to \(book.lentTo ?? "someone")")
                            .font(.subheadline)
                        if let date = book.lentDate {
                            Text("Since \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Return") {
                        book.isLent = false
                        book.lentTo = nil
                        book.lentDate = nil
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.shelfGreen)
                }
            } else {
                Button {
                    if purchaseManager.isProUser {
                        showLentSheet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Lend This Book", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.subheadline.bold())

            if isEditing {
                TextEditor(text: Binding(
                    get: { book.notes ?? "" },
                    set: { book.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(book.notes ?? "No notes")
                    .font(.subheadline)
                    .foregroundStyle(book.notes == nil ? .secondary : .primary)
            }
        }
    }

    private var lendingSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Who are you lending this book to?")
                    .font(.headline)

                TextField("Name", text: $lentPersonName)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle("Lend Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showLentSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lend") {
                        book.isLent = true
                        book.lentTo = lentPersonName
                        book.lentDate = Date()
                        showLentSheet = false
                    }
                    .disabled(lentPersonName.isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, !book.tags.contains(tag) else { return }
        book.tags.append(tag)
        newTag = ""
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + rowHeight), positions)
    }
}
