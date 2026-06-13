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
        
        let group = DispatchGroup()
        let stateQueue = DispatchQueue(label: "com.leakedmusic.download-manager.state")
        var updatedSong = song
        var encounteredError: Error?

        func setErrorIfNeeded(_ error: Error) {
            stateQueue.sync {
                if encounteredError == nil {
                    encounteredError = error
                }
            }
        }

        func updateDownloadedSong(_ update: (inout Song) -> Void) {
            stateQueue.sync {
                update(&updatedSong)
            }
        }
        
        // Download the audio.
        group.enter()
        let audioTask = URLSession.shared.downloadTask(with: remoteAudioURL) { tempURL, response, error in
            if let error = error {
                setErrorIfNeeded(error)
                group.leave()
                return
            }
            guard let tempURL = tempURL else {
                setErrorIfNeeded(DownloadError.noData)
                group.leave()
                return
            }
            do {
                try fileManager.copyItem(at: tempURL, to: audioDestinationURL)
                updateDownloadedSong { $0.audioURL = audioDestinationURL.absoluteString }
            } catch {
                setErrorIfNeeded(error)
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
                updateDownloadedSong { $0.artworkURL = artworkDestinationURL.absoluteString }
                group.leave()
            } else {
                let artworkTask = URLSession.shared.dataTask(with: remoteArtworkURL) { data, response, error in
                    if let data = data {
                        do {
                            try data.write(to: artworkDestinationURL)
                            updateDownloadedSong { $0.artworkURL = artworkDestinationURL.absoluteString }
                        } catch {
                            setErrorIfNeeded(error)
                            Logger.log("Artwork saving error", error: error)
                        }
                    } else if let error {
                        setErrorIfNeeded(error)
                    }
                    group.leave()
                }
                artworkTask.resume()
            }
        }
        
        // When all downloads finish...
        group.notify(queue: .main) {
            let result: (Song, Error?) = stateQueue.sync { (updatedSong, encounteredError) }
            if let error = result.1 {
                completion(.failure(error))
            } else {
                // If the song has a valid ID, update its downloadCount in Firestore.
                if let songID = song.id {
                    let db = Firestore.firestore()
                    db.collection("songs").document(songID).updateData([
                        "downloadCount": FieldValue.increment(Int64(1))
                    ]) { err in
                        if let err = err {
                            Logger.log("Error updating download count", error: err)
                        } else {
                            Logger.log("Download count incremented for song \(songID)")
                        }
                    }
                }
                
                // Append the updated song info to our local list.
                if !self.downloadedSongsData.contains(where: { $0.id == result.0.id }) {
                    self.downloadedSongsData.append(DownloadedSong(from: result.0))
                }
                completion(.success(result.0))
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
                Logger.log("Error removing audio file", error: error)
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
                Logger.log("Error removing artwork file", error: error)
            }
        }
        
        if let index = downloadedSongsData.firstIndex(where: { $0.id == song.id }) {
            downloadedSongsData.remove(at: index)
        }
        Logger.log("\(song.title) removed from downloads.")
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
            Logger.log("Failed to save downloaded songs", error: error)
        }
    }
    
    private func loadDownloadedSongs() {
        guard let data = UserDefaults.standard.data(forKey: downloadsKey) else { return }
        do {
            let decoder = JSONDecoder()
            let songs = try decoder.decode([DownloadedSong].self, from: data)
            self.downloadedSongsData = songs
        } catch {
            Logger.log("Failed to load downloaded songs", error: error)
        }
    }
    
    enum DownloadError: Error {
        case invalidURL
        case unableToAccessDocuments
        case noData
    }
}
