import SwiftUI
import Combine

// Extension for UserDefaults to store ratings
extension UserDefaults {
    private enum Keys {
        static let mediaRatings = "com.powerscale.mediaRatings"
    }
    
    // Structure to store rating information
    struct RatingInfo: Codable {
        let mediaId: Int
        let isAnime: Bool
        let rating: Double
        let timestamp: Date
    }
    
    // Get all saved ratings
    func getSavedRatings() -> [RatingInfo] {
        guard let data = UserDefaults.standard.data(forKey: Keys.mediaRatings) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([RatingInfo].self, from: data)
        } catch {
            print("Error decoding ratings: \(error)")
            return []
        }
    }
    
    // Save a new rating
    func saveRating(mediaId: Int, isAnime: Bool, rating: Double) {
        var ratings = getSavedRatings()
        
        // Remove existing rating for this media if it exists
        ratings.removeAll { $0.mediaId == mediaId && $0.isAnime == isAnime }
        
        // Add the new rating
        let newRating = RatingInfo(
            mediaId: mediaId,
            isAnime: isAnime,
            rating: rating,
            timestamp: Date()
        )
        ratings.append(newRating)
        
        // Save back to UserDefaults
        do {
            let data = try JSONEncoder().encode(ratings)
            UserDefaults.standard.set(data, forKey: Keys.mediaRatings)
        } catch {
            print("Error encoding ratings: \(error)")
        }
    }
    
    // Get rating for a specific media item
    func getRating(mediaId: Int, isAnime: Bool) -> Double? {
        let ratings = getSavedRatings()
        return ratings.first { $0.mediaId == mediaId && $0.isAnime == isAnime }?.rating
    }
}

class AnimeDetailViewModel: ObservableObject {
    // Reference to the main data manager
    private let rankingManager = RankingManager.shared
    
    // Published properties that the view will observe
    @Published var userRating: Double = 0.0
    @Published var temporaryRating: Double = 0.0
    @Published var watchedEpisodes: Int = 0
    @Published var userStatus: String = ""
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil
    @Published var isRatingChanged: Bool = false
    @Published var isRewatch: Bool = false
    @Published var rewatchCount: Int = 0
    @Published var showRewatchHistory: Bool = false
    
    // The anime being displayed
    private let anime: Anime
    private let isAnime: Bool
    
    init(anime: Anime, isAnime: Bool) {
        self.anime = anime
        self.isAnime = isAnime
        
        // Clean up any duplicate or incorrectly numbered rewatches
        rankingManager.cleanupAndFixRewatches(id: anime.id, isAnime: isAnime)
        
        // Now initialize user data from Core Data
        initializeUserData()
        
        // If no rating was found in Core Data, check UserDefaults
        if userRating == 0 {
            if let savedRating = UserDefaults.standard.getRating(mediaId: anime.id, isAnime: isAnime) {
                userRating = savedRating
                temporaryRating = savedRating
            }
        }
    }
    
    // Computed properties
    var hasCompletedBefore: Bool {
        return userStatus == "Completed" || hasRewatches
    }
    
    var hasRewatches: Bool {
        return rankingManager.hasRewatches(id: anime.id, isAnime: isAnime)
    }
    
    var rewatchHistory: [RankingItem] {
        return rankingManager.getRewatches(id: anime.id, isAnime: isAnime)
    }
    
    var completedRewatches: [RankingItem] {
        return rankingManager.getCompletedRewatches(id: anime.id, isAnime: isAnime)
    }
    
    var totalEpisodes: Int {
        return anime.episodes ?? 0
    }
    
    var cleanedDescription: String {
        guard let description = anime.description else { return "No description available." }
        
        // Remove HTML tags and source references
        var cleaned = description
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<i>", with: "")
            .replacingOccurrences(of: "</i>", with: "")
            .replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
        
        // Remove source tags like (Source: Wikipedia) or (Written by:...)
        let sourcePatterns = [
            "(Source: .*?\\))",
            "(Source:.*?$)",
            "\\(Source:.*?\\)",
            "\\[Source:.*?\\]",
            "\\[Written by:.*?\\]",
            "\\(Written by:.*?\\)"
        ]
        
        for pattern in sourcePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    options: [],
                    range: NSRange(location: 0, length: cleaned.utf16.count),
                    withTemplate: ""
                )
            }
        }
        
        // Clean up trailing characters and whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for and remove trailing orphaned parentheses
        if cleaned.hasSuffix("(") {
            cleaned = String(cleaned.dropLast())
        }
        if cleaned.hasSuffix(")") && !cleaned.contains("(") {
            cleaned = String(cleaned.dropLast())
        }
        
        // Check for and remove trailing orphaned brackets
        if cleaned.hasSuffix("[") {
            cleaned = String(cleaned.dropLast())
        }
        if cleaned.hasSuffix("]") && !cleaned.contains("[") {
            cleaned = String(cleaned.dropLast())
        }
        
        // Final trim to remove any whitespace leftover from our cleanups
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Business logic methods
    func initializeUserData() {
        if let existingItem = findExistingItem() {
            userStatus = existingItem.status
            userRating = existingItem.score
            temporaryRating = existingItem.score  // Make sure both are set for consistency
            watchedEpisodes = existingItem.progress
            startDate = existingItem.startDate
            endDate = existingItem.endDate
            isRewatch = existingItem.isRewatch
            rewatchCount = existingItem.rewatchCount
        }
    }
    
    func findExistingItem() -> RankingItem? {
        return rankingManager.findExistingItem(id: anime.id, isAnime: isAnime)
    }
    
    func findOriginalCompletedItem() -> RankingItem? {
        if isAnime {
            return rankingManager.rankedAnime.first(where: { $0.id == anime.id && !$0.isRewatch })
        } else {
            return rankingManager.rankedManga.first(where: { $0.id == anime.id && !$0.isRewatch })
        }
    }
    
    func handleStatusSelection(status: String, startDate: Date?, endDate: Date?, isRewatch: Bool, rewatchCount: Int) {
        // Don't do anything for share action
        if status == "Share" { return }
        
        // Create a ranking item with all the information
        var rankingItem: RankingItem
        var progress = 0
        
        // For completion, automatically set progress to total episodes
        if status == "Completed" {
            progress = totalEpisodes
        }
        
        // Always use current date if startDate is nil
        let effectiveStartDate = startDate ?? Date()
        
        if isRewatch {
            if status == "Completed" {
                // Completing a rewatch
                if let currentRewatch = rankingManager.getCurrentRewatchItem(id: anime.id, isAnime: isAnime) {
                    rankingItem = RankingItem(
                        from: anime,
                        status: status,
                        isAnime: isAnime,
                        rank: 0,
                        score: userRating,
                        startDate: currentRewatch.startDate ?? effectiveStartDate, // Use existing or current date
                        endDate: endDate,
                        isRewatch: true,
                        rewatchCount: currentRewatch.rewatchCount,
                        progress: totalEpisodes
                    )
                    
                    // Complete the rewatch in the manager
                    rankingManager.completeRewatch(id: anime.id, isAnime: isAnime, endDate: endDate)
                } else {
                    // Shouldn't happen, but just in case
                    rankingItem = RankingItem(
                        from: anime,
                        status: status,
                        isAnime: isAnime,
                        startDate: effectiveStartDate, // Use current date
                        endDate: endDate,
                        isRewatch: true,
                        rewatchCount: rewatchCount,
                        progress: totalEpisodes
                    )
                }
            } else {
                // Starting a new rewatch
                rankingItem = RankingItem(
                    from: anime,
                    status: status,
                    isAnime: isAnime,
                    startDate: effectiveStartDate, // Use current date
                    endDate: nil,
                    isRewatch: true,
                    rewatchCount: rewatchCount,
                    progress: 0
                )
            }
        } else {
            // For normal items, create with the provided data
            rankingItem = RankingItem(
                from: anime,
                status: status,
                isAnime: isAnime,
                score: userRating, // Include the current rating
                startDate: effectiveStartDate, // Use current date if nil
                endDate: endDate,
                progress: progress
            )
        }
        
        // Add the item to the appropriate list
        rankingManager.addItem(
            rankingItem,
            category: isAnime ? "Anime" : "Manga"
        )
        
        // Update local state
        userStatus = status
        self.startDate = effectiveStartDate // Always use the effective start date
        self.endDate = endDate
        self.isRewatch = isRewatch
        self.rewatchCount = rewatchCount
        
        // For completion, set watched episodes to total
        if status == "Completed" {
            watchedEpisodes = totalEpisodes
        } else if status.starts(with: "Currently") {
            watchedEpisodes = 0
        }
    }
    
    func updateProgress() {
        rankingManager.updateProgress(
            id: anime.id,
            isAnime: isAnime,
            isRewatch: isRewatch,
            rewatchCount: rewatchCount,
            progress: watchedEpisodes
        )
    }
    
    func updateRating() {
        // Update the rating in the ranking manager (Core Data)
        rankingManager.updateRating(
            id: anime.id,
            isAnime: isAnime,
            isRewatch: isRewatch,
            rewatchCount: rewatchCount,
            rating: userRating
        )
        
        // Also save to UserDefaults for backup during development
        UserDefaults.standard.saveRating(
            mediaId: anime.id,
            isAnime: isAnime,
            rating: userRating
        )
        
        // Make sure temporary rating matches the saved one
        temporaryRating = userRating
        isRatingChanged = false
    }
    
    func handleStarTap(star: Int) {
        let fullStar = Double(star * 2)
        let halfStar = Double(star * 2 - 1)
        
        // Logic for half-stars
        if temporaryRating == fullStar {
            // Tapping a full star reduces it to half
            temporaryRating = halfStar
            isRatingChanged = true
        } else if temporaryRating == halfStar {
            // Tapping a half star removes the rating
            temporaryRating = halfStar - 1.0
            isRatingChanged = true
        } else if temporaryRating < halfStar {
            // Tapping a higher star than current sets it to full
            temporaryRating = fullStar
            isRatingChanged = true
        } else if temporaryRating > fullStar {
            // Tapping a lower star than current sets it to full
            temporaryRating = fullStar
            isRatingChanged = true
        } else {
            // Default case
            temporaryRating = fullStar
            isRatingChanged = true
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "Currently":
            return .blue
        case "Want":
            return .purple
        case "On":
            return .orange
        case "Lost":
            return .red
        default:
            return .gray
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
