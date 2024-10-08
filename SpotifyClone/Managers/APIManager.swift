
import Foundation

final class APIManager {
    static let shared = APIManager()
    
    private init() { }
    
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum HTTPMethod: String {
        case GET
        case POST
        case DELETE
        case PUT
    }
    enum APIError: Error {
        case failedToGetData
    }
    private func createRequest(
        with url: URL?,
        type: HTTPMethod,
        completion: @escaping (URLRequest) -> Void
    ) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else { return }
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
    }
    
    //MARK: - Search
    
    func search(with query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        createRequest(with: URL(
            string: Constants.baseAPIURL + "/search?limit=10&type=album,artist,playlist,track&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
                      type: .GET) { request in
            print(request.url?.absoluteString ?? "none")
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(SearchResultResponse.self, from: data)
                    var searchResults: [SearchResult] = []
                    searchResults.append(contentsOf: result.tracks.items.compactMap({ .track(model: $0 )}))
                    searchResults.append(contentsOf: result.albums.items.compactMap({ .album(model: $0 )}))
                    searchResults.append(contentsOf: result.playlists.items.compactMap({ .playlist(model: $0 )}))
                    searchResults.append(contentsOf: result.artists.items.compactMap({ .artist(model: $0 )}))
                    
                    completion(.success(searchResults))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    
    
    //MARK: - Categories
    
    func getAllCategories(completion: @escaping(Result<CategoryResponse, Error>) -> Void) {
        createRequest(with: URL(string:Constants.baseAPIURL + "/browse/categories"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(CategoryResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }

            }
            task.resume()
        }
    }
    func getCategoryPlaylist(category: Category, completion: @escaping(Result<[Playlist], Error>) -> Void) {
        createRequest(with: URL(string:Constants.baseAPIURL + "/browse/categories/\(category.id)/playlists"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(CategoryPlaylistResponse.self, from: data)
                    let playlists = result.playlists.items
                    completion(.success(playlists))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    //MARK: Albums
    
    func getAlbumDetails(album: Album, completion: @escaping(Result<AlbumDetailsResponse,Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/albums/\(album.id)"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(AlbumDetailsResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }

            }
            task.resume()
        }
    }
    
    func getSavedAlbums(completion: @escaping (Result<[Album], Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/albums"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(LibraryAlbumResponse.self, from: data)
                    completion(.success(result.items.compactMap( { $0.album })))
                } catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    func saveAlbum(album: Album, completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/albums?ids=\(album.id)"), type: .PUT) { baseRequest in
            var request = baseRequest
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { data, response, err in
                guard let data = data,
                let code = (response as? HTTPURLResponse)?.statusCode
                else {
                    print(APIError.failedToGetData)
                    completion(false)
                    return
                }
                completion(code == 200)
            }
            task.resume()
        }
    }
    //MARK: - Playlists
    
    func getPlaylistDetails(playlist: Playlist, completion: @escaping(Result<PlaylistDetailsResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try JSONDecoder().decode(PlaylistDetailsResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }

            }
            task.resume()
        }
    }

    
    func getCurrentUserPlaylist(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/playlists/?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result  = try JSONDecoder().decode(LibraryPlaylistResponse.self, from: data)
                    completion(.success(result.items))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    func createPlaylist(with name: String, completion: @escaping (Bool) -> Void) {
        getCurrentUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                let urlString = Constants.baseAPIURL + "/users/\(profile.id)/playlists"
                self?.createRequest(with: URL(string: urlString), type: .POST, completion: { baseRequest in
                    var request = baseRequest
                    let json = [
                        "name": name
                    ]
                    request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
                    let task = URLSession.shared.dataTask(with: request) { data, _, err in
                        guard let data = data else {
                            print(APIError.failedToGetData)
                            completion(false)
                            return
                        }
                        do {
                            let result = try JSONSerialization.jsonObject(with: data)
                            if let response = result as? [String: Any], response["id"] as? String != nil {
                                print("Created")
                                completion(true)
                            } else {
                                completion(false)
                            }
                        } catch {
                            print(error)
                            completion(false)
                        }
                    }
                    task.resume()
                })
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    func addTrackToPlaylist(track: AudioTrack, playlist: Playlist, completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)/tracks"), type: .POST) { baseRequest in
            var request = baseRequest
            let json = [
                "uris": ["spotify:track:\(track.id)"]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try? JSONSerialization.jsonObject(with: data)
                    print(result)
                    if let response = result as? [String: Any],
                       response["snapshot_id"] as? String != nil {
                        completion(true)
                    } else {
                        completion(false)

                    }
                }
                catch {
                    print(error.localizedDescription)
                    completion(false)
                }

            }
            task.resume()
        }
    }
    func removeTrackFromPlaylist(track: AudioTrack, playlist: Playlist, completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)/tracks"), type: .DELETE) { baseRequest in
            var request = baseRequest
            let json: [String: Any] = [
                "tracks": [
                    [
                        "uri": "spotify:track:\(track.id)"
                        
                    ]
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try? JSONSerialization.jsonObject(with: data)
                    if let response = result as? [String: Any],
                       response["snapshot_id"] as? String != nil {
                        completion(true)
                    } else {
                        completion(false)

                    }
                }
                catch {
                    print(error.localizedDescription)
                    completion(false)
                }

            }
            task.resume()
        }
    }
    
    func unfollowPlaylist(playlist: Playlist, completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)/followers"), type: .DELETE) { baseRequest in
            var request = baseRequest
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    print(APIError.failedToGetData)
                    return
                }
                do {
                    let result = try? JSONSerialization.jsonObject(with: data)
                    completion(true)
                } catch {
                    print(error.localizedDescription)
                    completion(false)
                }
            }
            task.resume()
        }
    }
    
    // MARK: -Profile
    
    func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
    createRequest(with: URL(string: Constants.baseAPIURL + "/me"), type: .GET) { baseRequest in
        let task = URLSession.shared.dataTask(with: baseRequest) { data, _, err in
            guard let data = data, err == nil else {
                completion(.failure(APIError.failedToGetData))
                return
            }
            do {
                let result = try JSONDecoder().decode(UserProfile.self, from: data)
                completion(.success(result))
            } catch {
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
    
    // MARK: - Browse
    
    func getNewReleases(completion: @escaping (Result<NewReleasesResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/new-releases?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    func getFeaturedPlaylists(completion: @escaping (Result<FeaturedPlaylistsResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/featured-playlists?country=TR"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    func getRecommendedGenres(completion: @escaping (Result<RecommendedGenresResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/recommendations/available-genre-seeds"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(RecommendedGenresResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }

            }
            task.resume()
        }
    }
    
    func getRecommendations(genres: Set<String>, completion: @escaping (Result<RecommendationsResponse, Error>) -> Void) {
        let seeds = genres.joined(separator: ",")
        createRequest(with: URL(string: Constants.baseAPIURL + "/recommendations?limit=40&seed_genres=\(seeds)"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
}
