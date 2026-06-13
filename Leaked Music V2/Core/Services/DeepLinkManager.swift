import Foundation

struct DeepLinkManager {
    /// Generates a deep link URL for a given song.
    static func generateSongDeepLink(for song: Song) -> URL? {
        guard let id = song.id else { return nil }
        return URL(string: "leakedmusicv2://song?id=\(id)")
    }
    
    /// Generates a deep link URL for a given album.
    static func generateAlbumDeepLink(for album: Album) -> URL? {
        guard let id = album.id else { return nil }
        return URL(string: "leakedmusicv2://album?id=\(id)")
    }
    
    /// Generates a deep link URL for a given playlist.
    static func generatePlaylistDeepLink(for playlist: Playlist) -> URL? {
        return URL(string: "leakedmusicv2://playlist?id=\(playlist.id)")
    }
}
