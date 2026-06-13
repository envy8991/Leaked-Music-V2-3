import AVFoundation
import MediaPlayer
import SwiftUI
import Combine

enum RepeatMode {
    case off
    case one
    case all
}

final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    // MARK: - Published Properties

    /// The currently playing song (if any).
    @Published var currentSong: Song? {
        didSet {
            // Whenever currentSong changes, update lock-screen info on main actor.
            Task { @MainActor in
                updateNowPlayingInfo()
            }
        }
    }

    /// Whether the player is playing audio right now.
    @Published var isPlaying: Bool = false

    /// An index that points into `playlist` for which song is playing.
    @Published var currentIndex: Int = 0

    /// The main array of songs currently enqueued for playback.
    @Published var playlist: [Song] = []

    /// The "canonical" version of the playlist. Used to restore order when shuffle is turned off.
    private var originalPlaylist: [Song] = []

    /// Shuffle on/off.
    @Published var isShuffleOn: Bool = false

    /// Current repeat mode: off, one, or all.
    @Published var repeatMode: RepeatMode = .off

    /// Current playback time in seconds.
    @Published var currentTime: Double = 0.0

    /// Duration of the current track in seconds.
    @Published var duration: Double = 1.0

    // MARK: - Private AVPlayer Stuff

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private weak var observerPlayer: AVPlayer?

    /// To track if we were playing prior to an audio interruption (e.g. phone call).
    private var wasPlayingBeforeInterruption = false

    // MARK: - Artwork Caching

    private var cachedArtwork: MPMediaItemArtwork?
    private var lastArtworkURL: String?

    // MARK: - Init / Deinit

    private init() {
        configureAudioSession()
        setupRemoteCommands()
        setupInterruptionHandling()
    }

    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Core Playback Methods

    /// Begin playback of a given song, optionally providing a new playlist + start index.
    /// - Parameters:
    ///   - song: The song to start playing immediately.
    ///   - newPlaylist: If non-empty, replaces the current queue with these songs.
    ///   - startIndex: If given, sets the currentIndex to that value.
    public func play(song: Song, in newPlaylist: [Song] = [], startIndex: Int? = nil) {
        // If we got a new playlist, set both the "live" and "original" versions.
        if !newPlaylist.isEmpty {
            playlist = newPlaylist
            originalPlaylist = newPlaylist
            currentIndex = startIndex ?? 0
        } else {
            // Otherwise, see if the song is already in our existing playlist.
            if let idx = playlist.firstIndex(where: { $0.id == song.id }) {
                currentIndex = idx
            } else {
                // If not in the playlist, reset to just this one track.
                playlist = [song]
                originalPlaylist = [song]
                currentIndex = 0
            }
        }
        // Actually load and play the new track
        loadAndPlay(song: playlist[currentIndex])
    }

    /// Pause playback if currently playing.
    public func pause() {
        player?.pause()
        isPlaying = false
        Task { @MainActor in
            updateNowPlayingInfo()
        }
    }

    /// Resume playback if there's a loaded track.
    public func resume() {
        guard let _ = currentSong else { return }
        player?.play()
        isPlaying = true
        Task { @MainActor in
            updateNowPlayingInfo()
        }
    }

    /// Toggle between play/pause for the currentSong.
    public func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    /// Move to the next track in the playlist based on repeat mode.
    public func next() {
        guard !playlist.isEmpty else { return }

        switch repeatMode {
        case .one:
            // "Repeat One": just replay the current track from time zero
            seek(to: 0.0)
            resume()

        case .all:
            moveToNextIndex(wrap: true)

        case .off:
            moveToNextIndex(wrap: false)
        }
    }

    /// Move to the previous track, if it exists.
    public func previous() {
        guard !playlist.isEmpty else { return }
        let newIndex = currentIndex - 1
        if newIndex >= 0 {
            currentIndex = newIndex
            loadAndPlay(song: playlist[currentIndex])
        }
    }

    // MARK: - Shuffle & Repeat

    public func toggleShuffle() {
        let wasOn = isShuffleOn
        isShuffleOn.toggle()

        if !wasOn && playlist.count > 1 {
            // Turn shuffle ON
            originalPlaylist = playlist

            // Keep the current song in place, shuffle the rest
            let current = playlist[currentIndex]
            var others = playlist
            others.remove(at: currentIndex)
            let shuffledRest = others.shuffled()

            playlist = [current] + shuffledRest
            currentIndex = 0
        } else if wasOn {
            // Turn shuffle OFF => restore originalPlaylist
            if let curr = currentSong {
                playlist = originalPlaylist
                if let idx = playlist.firstIndex(where: { $0.id == curr.id }) {
                    currentIndex = idx
                } else {
                    currentIndex = 0
                }
            } else {
                // No currentSong? Just restore original
                playlist = originalPlaylist
                currentIndex = 0
            }
        }
    }

    public func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .one
        case .one:
            repeatMode = .all
        case .all:
            repeatMode = .off
        }
        Task { @MainActor in
            updateNowPlayingInfo()
        }
    }

    // MARK: - "Play Next" Insertion

    /// Inserts a song right after the current track in the playlist.
    /// Does *not* immediately play that song, but ensures it will come up next.
    public func insertSongNext(_ song: Song) {
        // If we have no currentSong or the playlist is empty, just treat this as adding one track.
        guard let _ = currentSong, !playlist.isEmpty else {
            playlist = [song]
            currentSong = song
            currentIndex = 0
            isPlaying = false
            return
        }

        let insertionIndex = currentIndex + 1
        if insertionIndex <= playlist.count {
            playlist.insert(song, at: insertionIndex)
        } else {
            // If currentIndex is the last track, we append
            playlist.append(song)
        }
        // No immediate playback; it will start after the current track finishes or if the user presses "next".
    }

    // MARK: - Internal Methods

    /// Moves currentIndex forward by 1 or wraps if wrap=true. Calls `loadAndPlay` if valid.
    private func moveToNextIndex(wrap: Bool) {
        let nextIndex = currentIndex + 1
        if nextIndex < playlist.count {
            currentIndex = nextIndex
            loadAndPlay(song: playlist[currentIndex])
        } else if wrap, !playlist.isEmpty {
            // "Repeat All" => go back to start
            currentIndex = 0
            loadAndPlay(song: playlist[currentIndex])
        } else {
            // No more tracks => stop
            pause()
            currentSong = nil
        }
    }

    /// Fully load a new song into AVPlayer and start playback.
    private func loadAndPlay(song: Song) {
        // Remove old observer
        if let oldItem = player?.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: oldItem
            )
        }
        removeTimeObserver()

        currentSong = song

        guard let url = bestURL(for: song) else {
            // Could handle invalid URL error
            return
        }

        player = AVPlayer(url: url)

        // Observe finishing
        if let item = player?.currentItem {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )
        }
        setupTimeObserver()

        player?.play()
        isPlaying = true

        // If you want to store last-played in Firestore:
        SessionStore().updateLastPlayedSong(songTitle: song.title)
    }

    /// Check if there's a local file for the song. Otherwise use remote URL.
    private func bestURL(for song: Song) -> URL? {
        if let downloaded = DownloadManager.shared.downloadedSongs.first(where: { $0.id == song.id }),
           let localURL = URL(string: downloaded.audioURL),
           localURL.isFileURL,
           FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        } else {
            return URL(string: song.audioURL)
        }
    }

    @objc private func playerItemDidFinish() {
        next()
    }

    // MARK: - Seeking

    public func seek(to seconds: Double) {
        let clampedSeconds = min(max(seconds, 0), max(duration, 0))
        let time = CMTime(seconds: clampedSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time)
        currentTime = clampedSeconds
        Task { @MainActor in
            updateNowPlayingInfo()
        }
    }

    public func skipForward(_ seconds: Double = 15) {
        seek(to: currentTime + seconds)
    }

    public func skipBackward(_ seconds: Double = 15) {
        seek(to: currentTime - seconds)
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        guard let player = player else { return }
        removeTimeObserver()

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        observerPlayer = player
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }

            self.currentTime = time.seconds
            if let durationSeconds = self.player?.currentItem?.duration.seconds,
               durationSeconds.isFinite {
                self.duration = durationSeconds
            }

            // Hop onto the main actor to update now playing info
            Task { @MainActor in
                self.updateNowPlayingInfo()
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let obsPlayer = observerPlayer {
            obsPlayer.removeTimeObserver(token)
            timeObserverToken = nil
            observerPlayer = nil
        }
    }

    // MARK: - Audio Session & Interruptions

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Handle audio session errors if needed
        }
    }

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began
            if isPlaying {
                wasPlayingBeforeInterruption = true
                pause()
            } else {
                wasPlayingBeforeInterruption = false
            }

        case .ended:
            // Interruption ended: check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume), wasPlayingBeforeInterruption {
                    resume()
                }
            }
            wasPlayingBeforeInterruption = false

        @unknown default:
            break
        }
    }

    // MARK: - Remote Command Center

    private func setupRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
        cc.skipForwardCommand.preferredIntervals = [15]
        cc.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        cc.skipBackwardCommand.preferredIntervals = [15]
        cc.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
    }

    // MARK: - Now Playing Info

    /// Updates the lock-screen / control center info. Artwork is loaded asynchronously/cached.
    @MainActor
    private func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlaying: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        // Check if we have a new artwork URL
        if let artworkURL = song.artworkURL, artworkURL != lastArtworkURL {
            lastArtworkURL = artworkURL
            cachedArtwork = nil

            Task {
                if let newArtwork = await fetchArtwork(urlString: artworkURL) {
                    var updated = nowPlaying
                    updated[MPMediaItemPropertyArtwork] = newArtwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
                } else {
                    // If fetch fails, just set the basic info
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
                }
            }
        } else if let art = cachedArtwork {
            nowPlaying[MPMediaItemPropertyArtwork] = art
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
        }
    }

    /// Fetch album artwork asynchronously, storing it in your ImageCache (if you like).
    private func fetchArtwork(urlString: String) async -> MPMediaItemArtwork? {
        guard let url = URL(string: urlString) else { return nil }
        let nsURL = url as NSURL

        // If you've got a custom image cache, check it here.
        if let cachedImage = ImageCache.shared.image(for: nsURL) {
            let artwork = makeMPMediaItemArtwork(from: cachedImage)
            cachedArtwork = artwork
            return artwork
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return nil
            }
            if let image = UIImage(data: data) {
                ImageCache.shared.store(image, for: nsURL)
                let artwork = makeMPMediaItemArtwork(from: image)
                cachedArtwork = artwork
                return artwork
            }
        } catch {
            print("Failed to download image:", error)
        }
        return nil
    }

    private func makeMPMediaItemArtwork(from image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
