import Foundation

extension AniListAPI {
    // MARK: - Anime Detail Methods
    
    func getAnimeDetails(id: Int, completion: @escaping (Anime?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($id: Int) {
              Media(id: $id, type: ANIME) {
                id
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
                bannerImage
                description
                episodes
                duration
                status
                season
                seasonYear
                format
                startDate {
                  year
                  month
                  day
                }
                endDate {
                  year
                  month
                  day
                }
                genres
                tags {
                  id
                  name
                  rank
                  isAdult
                }
                studios {
                  nodes {
                    id
                    name
                    isAnimationStudio
                  }
                }
                staff {
                  edges {
                    role
                    node {
                      id
                      name {
                        full
                      }
                    }
                  }
                }
                averageScore
                popularity
                meanScore
                favourites
                trending
                rankings {
                  rank
                  type
                  context
                  year
                  season
                }
                nextAiringEpisode {
                  airingAt
                  timeUntilAiring
                  episode
                }
                relations {
                  edges {
                    id
                    relationType
                    node {
                      id
                      title {
                        romaji
                        english
                      }
                      type
                      format
                      coverImage {
                        large
                      }
                    }
                  }
                }
                characters(sort: ROLE, perPage: 10) {
                  edges {
                    node {
                      id
                      name {
                        full
                      }
                      image {
                        medium
                      }
                    }
                    role
                    voiceActors(language: JAPANESE) {
                      id
                      name {
                        full
                      }
                      image {
                        medium
                      }
                    }
                  }
                }
                externalLinks {
                  id
                  url
                  site
                  type
                }
                streamingEpisodes {
                  title
                  thumbnail
                  url
                  site
                }
                trailer {
                  id
                  site
                  thumbnail
                }
                recommendations(sort: RATING_DESC, perPage: 5) {
                  nodes {
                    mediaRecommendation {
                      id
                      title {
                        romaji
                        english
                      }
                      coverImage {
                        large
                      }
                    }
                  }
                }
                isAdult
              }
            }
            """,
            "variables": ["id": id]
        ]
        
        fetchSingleData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func getAnimeRankings(id: Int, completion: @escaping (Anime?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($id: Int) {
              Media(id: $id, type: ANIME) {
                id
                title {
                  romaji
                  english
                  native
                }
                coverImage {
                  large
                }
                popularity
                averageScore
                rankings {
                  rank
                  type
                  context
                  allTime
                  season
                  year
                }
              }
            }
            """,
            "variables": ["id": id]
        ]
        
        guard let url = URL(string: apiURL) else {
            print("❌ Error: Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: graphqlQuery)
        } catch {
            print("❌ Error: Could not encode query JSON")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Error: No data received")
                completion(nil)
                return
            }
            
            do {
                // Define local response structure to avoid conflicts
                struct LocalAnimeRankingResponse: Codable {
                    let data: LocalMediaRanking
                }
                
                struct LocalMediaRanking: Codable {
                    let Media: Anime
                }
                
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(LocalAnimeRankingResponse.self, from: data)
                
                let mediaData = decodedResponse.data.Media
                
                // Debug output for rankings specifically
                print("🏆 Rankings information for anime ID \(mediaData.id):")
                if let rankings = mediaData.rankings {
                    print("- Found \(rankings.count) rankings")
                    
                    for (index, rank) in rankings.enumerated() {
                        print("  • Ranking \(index + 1): Type=\(rank.type), Rank=#\(rank.rank), Context=\(rank.context)")
                    }
                    
                    // Look specifically for popularity ranking
                    if let popularRank = rankings.first(where: { $0.type == "POPULAR" }) {
                        print("  ★ POPULAR rank = #\(popularRank.rank)")
                    } else {
                        print("  ⚠️ No POPULAR ranking found!")
                    }
                } else {
                    print("- No rankings data found!")
                }
                
                // Make sure to complete on main thread
                DispatchQueue.main.async {
                    completion(decodedResponse.data.Media)
                }
            } catch {
                print("❌ JSON Decoding Error:", error)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response (first 500 chars): \(String(responseString.prefix(500)))")
                }
                completion(nil)
            }
        }.resume()
    }
    
    func searchAnime(query: String, completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($search: String) {
              Page(perPage: 10) {
                media(search: $search, type: ANIME) {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                  }
                  bannerImage
                  description
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  startDate {
                    year
                    month
                    day
                  }
                  endDate {
                    year
                    month
                    day
                  }
                  genres
                  tags {
                    id
                    name
                    category
                    isAdult
                  }
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  staff {
                    edges {
                      role
                      node {
                        id
                        name {
                          full
                        }
                      }
                    }
                  }
                  averageScore
                  popularity
                  meanScore
                  favourites
                  rankings {
                    rank
                    type
                    context
                    year
                    season
                  }
                  nextAiringEpisode {
                    airingAt
                    timeUntilAiring
                    episode
                  }
                  relations {
                    edges {
                      id
                      relationType
                      node {
                        id
                        title {
                          romaji
                          english
                        }
                        type
                        format
                        coverImage {
                          large
                        }
                      }
                    }
                  }
                  characters(sort: ROLE, perPage: 6) {
                    edges {
                      node {
                        id
                        name {
                          full
                        }
                        image {
                          medium
                        }
                      }
                      role
                      voiceActors(language: JAPANESE) {
                        id
                        name {
                          full
                        }
                        image {
                          medium
                        }
                      }
                    }
                  }
                  externalLinks {
                    id
                    url
                    site
                    type
                  }
                  streamingEpisodes {
                    title
                    thumbnail
                    url
                    site
                  }
                  trailer {
                    id
                    site
                    thumbnail
                  }
                  recommendations(sort: RATING_DESC, perPage: 5) {
                    nodes {
                      mediaRecommendation {
                        id
                        title {
                          romaji
                          english
                        }
                        coverImage {
                          large
                        }
                      }
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": ["search": query]
        ]
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
}
