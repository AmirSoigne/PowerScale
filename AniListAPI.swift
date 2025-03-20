import Foundation

class AniListAPI {
    static let shared = AniListAPI()
    let apiURL = "https://graphql.anilist.co"
    
    private init() {}
    
    // MARK: - Core API Methods
    
    func fetchData(graphqlQuery: [String: Any], completion: @escaping ([Anime]?) -> Void) {
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
                struct LocalAnimeSearchResponse: Codable {
                    let data: LocalAnimePage
                }
                
                struct LocalAnimePage: Codable {
                    let Page: LocalMediaPage
                }
                
                struct LocalMediaPage: Codable {
                    let media: [Anime]
                }
                
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(LocalAnimeSearchResponse.self, from: data)
                
                // Add debugging for the first search result
                if let firstItem = decodedResponse.data.Page.media.first {
                    let mediaType = firstItem.episodes != nil ? "Anime" : "Manga"
                    print("✅ First \(mediaType) search result: \(firstItem.title.romaji ?? "Unknown")")
                    
                    // Add studio information debugging
                    print("- Studio data present: \(firstItem.studios != nil)")
                    if let studios = firstItem.studios?.nodes {
                        print("- Number of studios: \(studios.count)")
                        for studio in studios {
                            print("  • \(studio.name) (Animation studio: \(studio.isAnimationStudio ?? false))")
                        }
                    } else {
                        print("- No studio data in response")
                    }
                    
                    print("- Has characters: \(firstItem.characters?.edges?.count ?? 0) characters")
                    print("- Has relations: \(firstItem.relations?.edges?.count ?? 0) related media")
                    if mediaType == "Anime" {
                        print("- Has streaming episodes: \(firstItem.streamingEpisodes?.count ?? 0) episodes")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(decodedResponse.data.Page.media)
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
    
    func fetchSingleData(graphqlQuery: [String: Any], completion: @escaping (Anime?) -> Void) {
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
                struct LocalAnimeDetailResponse: Codable {
                    let data: LocalMediaDetail
                }
                
                struct LocalMediaDetail: Codable {
                    let Media: Anime
                }
                
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(LocalAnimeDetailResponse.self, from: data)
                
                // Add debugging - check what data was received
                let mediaData = decodedResponse.data.Media
                let mediaType = mediaData.episodes != nil ? "Anime" : "Manga"
                
                print("✅ \(mediaType) API Response Fields:")
                print("- Has studios: \(mediaData.studios != nil)")
                print("- Has staff: \(mediaData.staff != nil)")
                print("- Has characters: \(mediaData.characters?.edges?.count ?? 0) characters")
                print("- Has relations: \(mediaData.relations?.edges?.count ?? 0) related media")
                print("- Has external links: \(mediaData.externalLinks?.count ?? 0) links")
                print("- Has recommendations: \(mediaData.recommendations?.nodes?.count ?? 0) recommendations")
                
                // Add the detailed studio information as requested
                print("🎬 API Response for ID \(mediaData.id):")
                print("- Title: \(mediaData.title.romaji ?? "Unknown")")
                print("- Studio data present: \(mediaData.studios != nil)")
                if let studios = mediaData.studios?.nodes {
                    print("- Number of studios: \(studios.count)")
                    for studio in studios {
                        print("  • \(studio.name) (Animation studio: \(studio.isAnimationStudio ?? false))")
                    }
                } else {
                    print("- No studio data in response")
                }
                
                if let studioData = mediaData.studios {
                    print("📋 Studio data structure:")
                    print("- Has nodes: \(studioData.nodes != nil)")
                    print("- Studios count: \(studioData.nodes?.count ?? 0)")
                    
                    // Print raw studio data if possible
                    if let nodes = studioData.nodes {
                        print("- Studio names: \(nodes.map { $0.name }.joined(separator: ", "))")
                    }
                }
                
                if mediaType == "Anime" {
                    print("- Has streaming episodes: \(mediaData.streamingEpisodes?.count ?? 0) episodes")
                    print("- Has trailer: \(mediaData.trailer != nil)")
                }
                
                // Check specifically for rankings data
                if let rankings = mediaData.rankings, !rankings.isEmpty {
                    print("🏆 Rankings information:")
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
                    print("❌ No rankings data found in the response!")
                }
                
                DispatchQueue.main.async {
                    completion(decodedResponse.data.Media)
                }
            } catch {
                print("❌ JSON Decoding Error:", error)
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response (first 500 chars): \(String(responseString.prefix(500)))")
                }
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    func getCurrentSeasonAndYear() -> (String, Int) {
        let currentDate = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        
        let season: String
        switch month {
        case 1, 2, 3:
            season = "WINTER"
        case 4, 5, 6:
            season = "SPRING"
        case 7, 8, 9:
            season = "SUMMER"
        case 10, 11, 12:
            season = "FALL"
        default:
            season = "WINTER"
        }
        
        return (season, year)
    }
    
    func getNextSeasonAndYear() -> (String, Int) {
        let (currentSeason, currentYear) = getCurrentSeasonAndYear()
        
        var nextSeason: String
        var nextYear = currentYear
        
        switch currentSeason {
        case "WINTER":
            nextSeason = "SPRING"
        case "SPRING":
            nextSeason = "SUMMER"
        case "SUMMER":
            nextSeason = "FALL"
        case "FALL":
            nextSeason = "WINTER"
            nextYear += 1
        default:
            nextSeason = "SPRING"
        }
        
        return (nextSeason, nextYear)
    }
}
