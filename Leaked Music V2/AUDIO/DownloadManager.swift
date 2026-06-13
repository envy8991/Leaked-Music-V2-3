import Foundation
import SwiftUI
import FirebaseFirestore

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    // Internal storage uses our plain DownloadedSong struct.
    @Published private var downloadedSongsData: [DownloadedSong] = [] {
        didSet { saveDownloadedSongs() }
    }
    
    // Expose an array of Song for the UI.
    var downloadedSongs: [Song] {
        downloadedSongsData.map { $0.toSong() }
    }
    
    // Key for persistence.
    private let downloadsKey = "DownloadedSongsKey"
    
    private init() {
        loadDownloadedSongs()
    }
    
    /// Downloads both the audio and (if available) the artwork for a song.
    func downloadSong(song: Song, completion: @escaping (Result<Song, Error>) -> Void) {
        // Validate remote audio URL.
        guard let remoteAudioURL = URL(string: song.audioURL) else {
            completion(.failure(DownloadError.invalidURL))
            return
        }
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(.failure(DownloadError.unableToAccessDocuments))
            return
        }
        
        // Determine a destination for the audio file.
        let audioFileName = (song.id ?? UUID().uuidString) + ".mp3"
        let audioDestinationURL = documentsURL.appendingPathComponent(audioFileName)
        
        // If the audio file already exists locally, update the song's audioURL.
        if fileManager.fileExists(atPath: audioDestinationURL.path) {
            var updatedSong = song
            updatedSong.audioURL = audioDestinationURL.absoluteString
            // Also, if artwork exists locally, update artworkURL.
            if let _ = song.artworkURL,
               let localArtworkURL = localArtworkURL(for: song, in: documentsURL),
               fileManager.fileExists(atPath: localArtworkURL.path) {
                updatedSong.artworkURL = localArtworkURL.absoluteString
            }
            if !downloadedSongsData.contains(where: { $0.id == song.id }) {
                downloadedSongsData.append(DownloadedSong(from: updatedSong))
            }
            completion(.success(updatedSong))
            return
        }
        
        // Use a dispatch group to download audio and artwork concurrently.
        let group = DispatchGroup()
        var updatedSong = song  // This will be updated with local file URLs.
        var encounteredError: Error?
        
        // Download the audio.
        group.enter()
        let audioTask = URLSession.shared.downloadTask(with: remoteAudioURL) { tempURL, response, error in
            if let error = error {
                encounteredError = error
                group.leave()
                return
            }
            guard let tempURL = tempURL else {
                encounteredError = DownloadError.noData
                group.leave()
                return
            }
            do {
                try fileManager.copyItem(at: tempURL, to: audioDestinationURL)
                updatedSong.audioURL = audioDestinationURL.absoluteString
            } catch {
                encounteredError = error
            }
            group.leave()
        }
        audioTask.resume()
        
        // Download artwork if available.
        if let artworkURLString = song.artworkURL, let remoteArtworkURL = URL(string: artworkURLString) {
            group.enter()
            let artworkFileName = "artwork_" + (song.id ?? UUID().uuidString) + ".jpg"
            let artworkDestinationURL = documentsURL.appendingPathComponent(artworkFileName)
            if fileManager.fileExists(atPath: artworkDestinationURL.path) {
                updatedSong.artworkURL = artworkDestinationURL.absoluteString
                group.leave()
            } else {
                let artworkTask = URLSession.shared.dataTask(with: remoteArtworkURL) { data, response, error in
                    if let data = data {
                        do {
                            try data.write(to: artworkDestinationURL)
                            updatedSong.artworkURL = artworkDestinationURL.absoluteString
                        } catch {
                            print("Artwork saving error: \(error.localizedDescription)")
                        }
                    }
                    group.leave()
                }
                artworkTask.resume()
            }
        }
        
        // When all downloads finish...
        group.notify(queue: .main) {
            if let error = encounteredError {
                completion(.failure(error))
            } else {
                // If the song has a valid ID, update its downloadCount in Firestore.
                if let songID = song.id {
                    let db = Firestore.firestore()
                    db.collection("songs").document(songID).updateData([
                        "downloadCount": FieldValue.increment(Int64(1))
                    ]) { err in
                        if let err = err {
                            print("Error updating download count: \(err.localizedDescription)")
                        } else {
                            print("Download count incremented for song \(songID)")
                        }
                    }
                }
                
                // Append the updated song info to our local list.
                self.downloadedSongsData.append(DownloadedSong(from: updatedSong))
                completion(.success(updatedSong))
            }
        }
    }
    
    /// Removes the downloaded audio and artwork files (if they exist) and updates the persisted list.
    func removeDownloadedSong(song: Song) {
        let fileManager = FileManager.default
        
        // Remove audio file.
        if let audioURL = URL(string: song.audioURL), audioURL.isFileURL, fileManager.fileExists(atPath: audioURL.path) {
            do {
                try fileManager.removeItem(at: audioURL)
            } catch {
                print("Error removing audio file: \(error.localizedDescription)")
            }
        }
        
        // Remove artwork file if available.
        if let artworkURLString = song.artworkURL,
           let artworkURL = URL(string: artworkURLString),
           artworkURL.isFileURL,
           fileManager.fileExists(atPath: artworkURL.path) {
            do {
                try fileManager.removeItem(at: artworkURL)
            } catch {
                print("Error removing artwork file: \(error.localizedDescription)")
            }
        }
        
        if let index = downloadedSongsData.firstIndex(where: { $0.id == song.id }) {
            downloadedSongsData.remove(at: index)
        }
        print("\(song.title) removed from downloads.")
    }
    
    /// Helper method to compute a local artwork file URL for a song.
    private func localArtworkURL(for song: Song, in documentsURL: URL) -> URL? {
        let artworkFileName = "artwork_" + (song.id ?? UUID().uuidString) + ".jpg"
        return documentsURL.appendingPathComponent(artworkFileName)
    }
    
    // MARK: - Persistence
    
    private func saveDownloadedSongs() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(downloadedSongsData)
            UserDefaults.standard.set(data, forKey: downloadsKey)
        } catch {
            print("Failed to save downloaded songs: \(error)")
        }
    }
    
    private func loadDownloadedSongs() {
        guard let data = UserDefaults.standard.data(forKey: downloadsKey) else { return }
        do {
            let decoder = JSONDecoder()
            let songs = try decoder.decode([DownloadedSong].self, from: data)
            self.downloadedSongsData = songs
        } catch {
            print("Failed to load downloaded songs: \(error)")
        }
    }
    
    enum DownloadError: Error {
        case invalidURL
        case unableToAccessDocuments
        case noData
    }
}
