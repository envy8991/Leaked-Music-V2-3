import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let isFileURL: Bool
    @State private var uiImage: UIImage?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?
    let fallback: AnyView

    init(url: URL?, isFileURL: Bool = false, fallback: AnyView = AnyView(Color.gray.opacity(0.3))) {
        self.url = url
        self.isFileURL = isFileURL
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
            } else {
                fallback
            }
        }
        .onAppear { loadImageIfNeeded() }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
        .onChange(of: url) { newURL in
            uiImage = nil
            isLoading = false
            loadTask?.cancel()
            loadTask = nil
            loadImageIfNeeded(urlOverride: newURL)
        }
    }

    private func loadImageIfNeeded(urlOverride: URL? = nil) {
        let actualURL = urlOverride ?? url
        guard let unwrappedURL = actualURL, uiImage == nil, loadTask == nil else { return }

        if isFileURL || unwrappedURL.isFileURL {
            loadImageFromFileURL(unwrappedURL)
        } else {
            loadImageFromNetworkURL(unwrappedURL)
        }
    }

    private func loadImageFromFileURL(_ localURL: URL) {
        isLoading = true
        loadTask = Task {
            do {
                let data = try Data(contentsOf: localURL)
                try Task.checkCancellation()
                let image = UIImage(data: data)
                await MainActor.run {
                    self.uiImage = image
                    self.isLoading = false
                    self.loadTask = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("Failed to load image from file: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.loadTask = nil
                }
            }
        }
    }

    private func loadImageFromNetworkURL(_ remoteURL: URL) {
        let nsURL = remoteURL as NSURL
        if let cached = ImageCache.shared.image(for: nsURL) {
            uiImage = cached
            return
        }

        isLoading = true
        loadTask = Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                try Task.checkCancellation()
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode),
                      let downloadedImage = UIImage(data: data)
                else {
                    throw URLError(.badServerResponse)
                }
                ImageCache.shared.store(downloadedImage, for: nsURL)
                await MainActor.run {
                    self.uiImage = downloadedImage
                    self.isLoading = false
                    self.loadTask = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("Failed to download image:", error)
                await MainActor.run {
                    self.isLoading = false
                    self.loadTask = nil
                }
            }
        }
    }
}
