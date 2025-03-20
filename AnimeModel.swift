import Foundation

// Represents an anime or manga object
struct Anime: Identifiable, Codable {
    let id: Int
    let title: AnimeTitle
    let coverImage: CoverImage
    let description: String?
    
    // Basic info
    let episodes: Int?
    let chapters: Int?
    let volumes: Int?
    let duration: Int?
    let status: String?
    let format: String?
    let season: String?
    let seasonYear: Int?
    let isAdult: Bool?
    
    // Dates
    let startDate: FuzzyDate?
    let endDate: FuzzyDate?
    
    // Tags and genres
    let genres: [String]?
    let tags: [Tag]?
    
    // Statistics
    let averageScore: Int?
    let meanScore: Int?
    let popularity: Int?
    let favourites: Int?
    let trending: Int?
    let rankings: [Ranking]?
    
    // Studios and producers
    let studios: StudioConnection?
    let producers: StudioConnection?
    
    // Staff (for manga creators)
    let staff: StaffConnection?
    
    // Related media
    let relations: MediaConnection?
    
    // Characters
    let characters: CharacterConnection?
    
    // External links and trailers
    let externalLinks: [ExternalLink]?
    let trailer: Trailer?
    let streamingEpisodes: [StreamingEpisode]?
    
    // Next airing episode
    let nextAiringEpisode: AiringSchedule?
    
    // Recommendations
    let recommendations: RecommendationConnection?
    
    // Extra images
    let bannerImage: String?
    
    // Sample Data for Previews
    static let sample = Anime(
        id: 1,
        title: AnimeTitle(romaji: "Naruto", english: "Naruto"),
        coverImage: CoverImage(large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx20-LxrhhIQyiE60.jpg"),
        description: "A young ninja seeks recognition and dreams of becoming Hokage.",
        episodes: 220,
        chapters: nil,
        volumes: nil,
        duration: 24,
        status: "Finished",
        format: "TV",
        season: "WINTER",
        seasonYear: 2023,
        isAdult: false,
        startDate: nil,
        endDate: nil,
        genres: ["Action", "Adventure"],
        tags: nil,
        averageScore: 85,
        meanScore: 86,
        popularity: 10000,
        favourites: 500,
        trending: 5,
        rankings: nil,
        studios: nil,
        producers: nil,
        staff: nil,  // Added the staff parameter
        relations: nil,
        characters: nil,
        externalLinks: nil,
        trailer: nil,
        streamingEpisodes: nil,
        nextAiringEpisode: nil,
        recommendations: nil,
        bannerImage: nil
    )
}

// Represents the title structure (Romaji & English)
struct AnimeTitle: Codable {
    let romaji: String?
    let english: String?
    let native: String?
    
    init(romaji: String?, english: String?, native: String? = nil) {
        self.romaji = romaji
        self.english = english
        self.native = native
    }
}

// Represents the cover image structure
struct CoverImage: Codable {
    let large: String
}

// Represents fuzzy dates (year, month, day might be null)
struct FuzzyDate: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
}

// Tag model
struct Tag: Codable, Identifiable {
    let id: Int
    let name: String
    let rank: Int?
    let isAdult: Bool?
}

// Ranking model
struct Ranking: Codable {
    let rank: Int
    let type: String
    let context: String
    let year: Int?
    let season: String?
}

// Studio/Producer connection
struct StudioConnection: Codable {
    let nodes: [Studio]?
}

struct Studio: Codable, Identifiable {
    let id: Int
    let name: String
    let isAnimationStudio: Bool?
}

// Staff connection for manga creators
struct StaffConnection: Codable {
    let edges: [StaffEdge]?
}

struct StaffEdge: Codable {
    let role: String
    let node: Staff
}

struct Staff: Codable, Identifiable {
    let id: Int
    let name: CharacterName
}

// Media connection for related anime/manga
struct MediaConnection: Codable {
    let edges: [MediaEdge]?
}

struct MediaEdge: Codable, Identifiable {
    let id: Int?
    let relationType: String?
    let node: MediaNode
}

struct MediaNode: Codable, Identifiable {
    let id: Int
    let title: AnimeTitle
    let type: String?
    let format: String?
    let coverImage: CoverImage
    let description: String?  // New property for summary
}


// Character connection
struct CharacterConnection: Codable {
    let edges: [CharacterEdge]?
}

struct CharacterEdge: Codable {
    let node: Character
    let role: String
    let voiceActors: [VoiceActor]?
}

struct Character: Codable, Identifiable {
    let id: Int
    let name: CharacterName
    let image: CharacterImage
}


struct CharacterName: Codable {
    let full: String
    let first: String?
    let last: String?
    let native: String? 
}

struct CharacterImage: Codable {
    let medium: String?
    let large: String?
    
    // Optional convenience property
    var bestAvailable: String {
        // Return medium if it exists, else large, else empty
        return medium ?? large ?? ""
    }
}


struct VoiceActor: Codable, Identifiable {
    let id: Int
    let name: CharacterName
    let image: CharacterImage
    let language: String? 
}

// External links
struct ExternalLink: Codable, Identifiable {
    let id: Int
    let url: String
    let site: String
    let type: String?
}

// Trailer
struct Trailer: Codable {
    let id: String?
    let site: String?
    let thumbnail: String?
}

// Streaming episodes
struct StreamingEpisode: Codable {
    let title: String?
    let thumbnail: String?
    let url: String?
    let site: String?
}

// Airing schedule
struct AiringSchedule: Codable {
    let airingAt: Int
    let timeUntilAiring: Int
    let episode: Int
}

// Recommendations
struct RecommendationConnection: Codable {
    let nodes: [RecommendationNode]?
}

struct RecommendationNode: Codable {
    let mediaRecommendation: MediaNode
}

// Response models
struct AnimeSearchResponse: Codable {
    let data: AnimePage
}

struct AnimePage: Codable {
    let Page: MediaPage
}

struct MediaPage: Codable {
    let media: [Anime]
}

struct AnimeDetailResponse: Codable {
    let data: MediaDetail
}

struct MediaDetail: Codable {
    let Media: Anime
}
