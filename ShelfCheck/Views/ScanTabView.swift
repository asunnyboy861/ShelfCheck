import SwiftUI
import SwiftData

struct ScanTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var scanViewModel = ScanViewModel()
    @State private var purchaseManager = PurchaseManager()
    @AppStorage("isContinuousScan") private var isContinuous = false
    @State private var isTorchOn = false
    @State private var showResult = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            ScannerView(
                onScan: { isbn in
                    scanViewModel.setModelContext(modelContext)
                    scanViewModel.handleScan(isbn, modelContext: modelContext)
                    withAnimation { showResult = true }
                },
                isContinuous: $isContinuous,
                isTorchOn: $isTorchOn
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    torchButton
                    continuousButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                if showResult {
                    scanResultCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
    }

    private var torchButton: some View {
        Button {
            isTorchOn.toggle()
        } label: {
            Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    private var continuousButton: some View {
        Button {
            isContinuous.toggle()
        } label: {
            Image(systemName: isContinuous ? "barcode.viewfinder" : "qrcode.viewfinder")
                .font(.title2)
                .foregroundStyle(isContinuous ? Color.shelfGreen : .white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    private var scanResultCard: some View {
        VStack(spacing: 12) {
            if let status = scanViewModel.duplicateStatus {
                statusHeader(status)

                if let meta = scanViewModel.bookMetadata {
                    bookInfoSection(meta)
                } else if scanViewModel.isLookingUp {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 40)
                }

                actionButtons(status)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 15)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func statusHeader(_ status: DuplicateStatus) -> some View {
        switch status {
        case .owned(let book):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Already Owned")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(book.title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(Color.shelfRed)

        case .maybeOwned(let books):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Possible Duplicate")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(books.first?.title ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(Color.shelfAmber)

        case .newBook:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                Text("New Book")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .foregroundStyle(Color.shelfGreen)
        }
    }

    @ViewBuilder
    private func bookInfoSection(_ meta: BookMetadata) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meta.title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
            if !meta.authors.isEmpty {
                Text(meta.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            if let publisher = meta.publisher {
                Text(publisher)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func actionButtons(_ status: DuplicateStatus) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    showResult = false
                    scanViewModel.resetScan()
                }
            } label: {
                Text("Dismiss")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if case .newBook = status {
                Button {
                    let bookCount = (try? modelContext.fetchCount(FetchDescriptor<Book>())) ?? 0
                    if purchaseManager.canAddBook(currentCount: bookCount) {
                        scanViewModel.addBook(modelContext: modelContext)
                        withAnimation {
                            showResult = false
                            scanViewModel.resetScan()
                        }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Text("Add to Shelf")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.shelfGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if case .maybeOwned = status {
                Button {
                    let bookCount = (try? modelContext.fetchCount(FetchDescriptor<Book>())) ?? 0
                    if purchaseManager.canAddBook(currentCount: bookCount) {
                        scanViewModel.addBook(modelContext: modelContext)
                        withAnimation {
                            showResult = false
                            scanViewModel.resetScan()
                        }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Text("Add Anyway")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.shelfAmber)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
