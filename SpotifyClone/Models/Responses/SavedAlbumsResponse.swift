
import Foundation

struct LibraryAlbumResponse: Codable {
    let items: [UserAlbumResponse]
}

struct UserAlbumResponse: Codable {
    let album: Album
    let added_at: String
}
