import Foundation

struct RankingItem: Identifiable, Codable {
    let id: Int
    let title: String
    let coverImage: String
    let status: String
    let isAnime: Bool
    let rank: Int
    var score: Double
    let startDate: Date?
    let endDate: Date?
    let isRewatch: Bool
    let rewatchCount: Int
    let progress: Int
    let summary: String?
    let genres: [String]?
    
    // New property: Elo rating for pairwise comparisons, defaulting to 1500.
    var eloRating: Double

    // Default initializer with all parameters, including eloRating.
    init(id: Int, title: String, coverImage: String, status: String, isAnime: Bool,
         rank: Int = 0, score: Double = 0, startDate: Date? = nil, endDate: Date? = nil,
         isRewatch: Bool = false, rewatchCount: Int = 0, progress: Int = 0, summary: String? = nil,
         genres: [String]? = nil, eloRating: Double = 1500) {
        self.id = id
        self.title = title
        self.coverImage = coverImage
        self.status = status
        self.isAnime = isAnime
        self.rank = rank
        self.score = score
        self.startDate = startDate
        self.endDate = endDate
        self.isRewatch = isRewatch
        self.rewatchCount = rewatchCount
        self.progress = progress
        self.summary = summary
        self.genres = genres
        self.eloRating = eloRating
    }

    // Update the Anime conversion initializer, now including eloRating.
    init(from anime: Anime, status: String, isAnime: Bool, rank: Int = 0, score: Double = 0,
         startDate: Date? = nil, endDate: Date? = nil, isRewatch: Bool = false,
         rewatchCount: Int = 0, progress: Int = 0, eloRating: Double = 1500) {
        self.id = anime.id
        self.title = anime.title.english ?? anime.title.romaji ?? "Unknown"
        self.coverImage = anime.coverImage.large
        self.status = status
        self.isAnime = isAnime
        self.rank = rank
        self.score = score
        self.startDate = startDate
        self.endDate = endDate
        self.isRewatch = isRewatch
        self.rewatchCount = rewatchCount
        self.progress = progress
        self.summary = anime.description
        self.genres = anime.genres
        self.eloRating = eloRating
    }
    
    // Convert back to Anime (for API compatibility)
    func toAnime() -> Anime {
        return Anime(
            id: self.id,
            title: AnimeTitle(romaji: self.title, english: self.title, native: nil),
            coverImage: CoverImage(large: self.coverImage),
            description: self.summary ?? "",
            episodes: isAnime ? self.progress : nil,
            chapters: !isAnime ? self.progress : nil,
            volumes: nil,
            duration: nil,
            status: self.status,
            format: nil,
            season: nil,
            seasonYear: nil,
            isAdult: false,
            startDate: nil,
            endDate: nil,
            genres: self.genres,
            tags: nil,
            averageScore: nil,
            meanScore: nil,
            popularity: nil,
            favourites: nil,
            trending: nil,
            rankings: nil,
            studios: nil,
            producers: nil,
            staff: nil,
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
}

extension RankingItem {
    // Create a rewatch item from an original item.
    static func createRewatch(from item: RankingItem) -> RankingItem {
        let newRewatchCount = item.rewatchCount > 0 ? item.rewatchCount + 1 : 1
        
        return RankingItem(
            id: item.id,
            title: item.title,
            coverImage: item.coverImage,
            status: item.isAnime ? "Currently Watching" : "Currently Reading",
            isAnime: item.isAnime,
            rank: 0, // Reset rank for a rewatch
            score: 0, // Reset score for a rewatch
            startDate: Date(), // Start today
            endDate: nil, // Not completed yet
            isRewatch: true,
            rewatchCount: newRewatchCount,
            progress: 0, // Start at episode/chapter 0
            summary: item.summary,  // Carry over the summary
            genres: item.genres,
            eloRating: 1500         // New rewatch starts with default Elo rating
        )
    }
    
    // Complete a rewatch by setting its end date and status.
    static func completeRewatch(from rewatch: RankingItem, endDate: Date?) -> RankingItem {
        return RankingItem(
            id: rewatch.id,
            title: rewatch.title,
            coverImage: rewatch.coverImage,
            status: "Completed",
            isAnime: rewatch.isAnime,
            rank: rewatch.rank,
            score: rewatch.score,
            startDate: rewatch.startDate,
            endDate: endDate ?? Date(), // Use provided date or today
            isRewatch: true,
            rewatchCount: rewatch.rewatchCount,
            progress: rewatch.progress,
            summary: rewatch.summary,
            genres: rewatch.genres,
            eloRating: rewatch.eloRating  // Preserve existing Elo rating
        )
    }
    
    /// Composite Score combining the user's rating and ranking.
    /// - The user's rating (score) is assumed to be on a 0–10 scale (multiplied by 10).
    /// - The ranking factor is computed such that rank 1 gives 100, rank 2 gives 90, etc.
    /// - The two are combined using a weighted average (70% rating, 30% ranking).
    var compositeScore: Double {
        let normalizedRating = self.score * 10
        let rankingFactor = max(0, 100 - Double(self.rank - 1) * 10)
        let ratingWeight = 0.7
        let rankingWeight = 0.3
        return normalizedRating * ratingWeight + rankingFactor * rankingWeight
    }
}
