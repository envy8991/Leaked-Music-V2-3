import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct SongUploadView: View {
    @ObservedObject var viewModel: UploadViewModel
    let selectedArtist: Artist
    let selectedAlbum: Album

    @State private var selectedFileURLs: [URL] = []
    @State private var showFilePicker = false
    @State private var songTitles: [String] = []
    @State private var isFeatured: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Selected Album")) {
                Text(selectedAlbum.title).font(.headline)
                Text("by \(selectedArtist.name)").font(.subheadline)
            }

            Section(header: Text("Select Songs")) {
                Button("Choose Songs") {
                    showFilePicker = true
                }
                if !selectedFileURLs.isEmpty {
                    Text("\(selectedFileURLs.count) files selected")
                }
            }

            if !selectedFileURLs.isEmpty {
                Section(header: Text("Song Titles")) {
                    ForEach(0..<selectedFileURLs.count, id: \.self) { index in
                        TextField("Song Title \(index + 1)", text: Binding(
                            get: { songTitles.indices.contains(index) ? songTitles[index] : "" },
                            set: { newValue in
                                if songTitles.indices.contains(index) {
                                    songTitles[index] = newValue
                                } else {
                                    songTitles.append(newValue)
                                }
                            }
                        ))
                    }
                }

                Section {
                    Toggle("Featured Album Songs", isOn: $isFeatured)
                }

                Section {
                    Button("Upload Songs") {
                        print("Uploading files: \(selectedFileURLs)")
                        viewModel.uploadSongsToAlbum(selectedArtist: selectedArtist, selectedAlbum: selectedAlbum, fileURLs: selectedFileURLs, songTitles: songTitles, isFeatured: isFeatured) { success in
                            if success {
                                selectedFileURLs = []
                                songTitles = []
                                isFeatured = false
                            }
                        }
                    }
                    .disabled(selectedFileURLs.isEmpty || viewModel.isUploading)
                    if viewModel.isUploading {
                        ProgressView(value: viewModel.overallProgress)
                    }
                }
            }
        }
        .navigationTitle("Add Songs")
        .fileImporter(isPresented: $showFilePicker,
                      allowedContentTypes: [.audio, .mp3, .mpeg4Audio],
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                var copiedURLs: [URL] = []
                var titles: [String] = []
                
                // Process each original URL from the file picker
                for originalURL in urls {
                    if originalURL.startAccessingSecurityScopedResource() {
                        defer { originalURL.stopAccessingSecurityScopedResource() }
                        
                        // Step 1: Parse metadata from the original URL
                        let asset = AVAsset(url: originalURL)
                        var songTitle: String?
                        
                        // Check common metadata for a title
                        let commonTitleItems = asset.commonMetadata.filter { $0.commonKey == .commonKeyTitle }
                        if let titleItem = commonTitleItems.first, let title = titleItem.value as? String {
                            songTitle = title
                        }
                        
                        // If no common title, check other metadata formats
                        if songTitle == nil {
                            for format in asset.availableMetadataFormats {
                                for item in asset.metadata(forFormat: format) {
                                    if let key = item.key as? String,
                                       ["title", "song", "©nam", "tit2"].contains(key.lowercased()),
                                       let titleValue = item.value as? String {
                                        songTitle = titleValue
                                        break
                                    }
                                }
                                if songTitle != nil { break }
                            }
                        }
                        
                        // Step 2: Fallback to original file name if no metadata
                        if songTitle == nil {
                            songTitle = originalURL.deletingPathExtension().lastPathComponent
                        }
                        
                        // Add the title to the list
                        titles.append(songTitle ?? "Track \(titles.count + 1)")
                        
                        // Step 3: Copy the file to a temporary location for upload
                        do {
                            let tempDir = FileManager.default.temporaryDirectory
                            let uniqueFilename = UUID().uuidString + "_" + originalURL.lastPathComponent
                            let copiedFileURL = tempDir.appendingPathComponent(uniqueFilename)
                            
                            try FileManager.default.copyItem(at: originalURL, to: copiedFileURL)
                            copiedURLs.append(copiedFileURL)
                            print("Copied file from: \(originalURL) to: \(copiedFileURL)")
                        } catch {
                            print("Error copying file: \(error.localizedDescription)")
                            viewModel.errorMessage = AppError(message: "Error copying file: \(error.localizedDescription)")
                            return
                        }
                    } else {
                        print("Could not access security scoped resource for \(originalURL)")
                        viewModel.errorMessage = AppError(message: "Could not access selected file: \(originalURL.lastPathComponent)")
                        return
                    }
                }
                
                // Update state with copied URLs and song titles
                selectedFileURLs = copiedURLs
                songTitles = titles
                
            case .failure(let error):
                viewModel.errorMessage = AppError(message: "Error selecting files: \(error.localizedDescription)")
            }
        }
        .onAppear {
            viewModel.selectedAlbum = selectedAlbum
        }
    }
}
