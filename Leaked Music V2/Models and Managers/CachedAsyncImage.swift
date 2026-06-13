import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let isFileURL: Bool // Add this flag
    @State private var uiImage: UIImage?
    @State private var isLoading = false
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
        .onAppear {
            loadImageIfNeeded()
        }
        // ** NEW: onChange to re-fetch if URL changes **
        .onChange(of: url) { newURL in
            guard let newURL = newURL else {
                uiImage = nil
                return
            }
            // Clear previous image and reload
            uiImage = nil
            isLoading = false
            loadImageIfNeeded(urlOverride: newURL)
        }
    }

    private func loadImageIfNeeded(urlOverride: URL? = nil) {
        // We'll either use urlOverride if passed, or default to self.url
        let actualURL = urlOverride ?? url
        guard let unwrappedURL = actualURL else { return }

        if isFileURL {
            loadImageFromFileURL(unwrappedURL)
        } else {
            loadImageFromNetworkURL(unwrappedURL)
        }
    }

    private func loadImageFromFileURL(_ localURL: URL) {
        do {
            let data = try Data(contentsOf: localURL)
            if let image = UIImage(data: data) {
                self.uiImage = image
            } else {
                print("Failed to create image from file data.")
            }
        } catch {
            print("Failed to load image from file: \(error)")
        }
    }

    private func loadImageFromNetworkURL(_ remoteURL: URL) {
        let nsURL = remoteURL as NSURL
        // Check cache
        if let cached = ImageCache.shared.image(for: nsURL) {
            uiImage = cached
            return
        }

        isLoading = true
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw URLError(.badServerResponse)
                }
                if let downloadedImage = UIImage(data: data) {
                    ImageCache.shared.store(downloadedImage, for: nsURL)
                    uiImage = downloadedImage
                }
            } catch {
                print("Failed to download image:", error)
            }
            isLoading = false
        }
    }
}
