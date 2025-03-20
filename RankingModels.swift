import Foundation

// Common models used throughout the app
struct PairwiseComparisonPair: Codable, Hashable {
    let firstItemId: Int
    let secondItemId: Int
    let timestamp: Date
    
    init(firstItemId: Int, secondItemId: Int) {
        self.firstItemId = firstItemId
        self.secondItemId = secondItemId
        self.timestamp = Date()
    }
}

struct PairwiseSessionInfo: Codable {
    let category: String
    let pairwiseItems: [PairwiseComparisonPair]
    let currentPairIndex: Int
    let winCounts: [Int: Int]
    let activeRankingItemIds: [Int]
    let timestamp: Date
    
    init(category: String, pairwiseItems: [PairwiseComparisonPair], currentPairIndex: Int, winCounts: [Int: Int], activeRankingItemIds: [Int]) {
        self.category = category
        self.pairwiseItems = pairwiseItems
        self.currentPairIndex = currentPairIndex
        self.winCounts = winCounts
        self.activeRankingItemIds = activeRankingItemIds
        self.timestamp = Date()
    }
}

struct LibraryItemInfo: Codable {
    let mediaId: Int
    let isAnime: Bool
    let title: String
    let coverImageURL: String
    let status: String
    let progress: Int
    let score: Double
    let startDate: Date?
    let endDate: Date?
    let isRewatch: Bool
    let rewatchCount: Int
    let timestamp: Date
    
    // Convert to RankingItem
    func toRankingItem() -> RankingItem {
        return RankingItem(
            id: mediaId,
            title: title,
            coverImage: coverImageURL,
            status: status,
            isAnime: isAnime,
            rank: 0,  // Default rank, will be updated later
            score: score,
            startDate: startDate,
            endDate: endDate,
            isRewatch: isRewatch,
            rewatchCount: rewatchCount,
            progress: progress,
            summary: nil,
            genres: nil
        )
    }
}

// Constants for UserDefaults keys
enum PairwiseKeys {
    static let hasSavedSession = "com.powerscale.hasSavedRankingSession"
    static let rankingCategory = "com.powerscale.savedRankingCategory"
    static let currentPairIndex = "com.powerscale.savedCurrentPairIndex"
    static let winCounts = "com.powerscale.savedWinCounts"
    static let pairwiseItems = "com.powerscale.savedPairwiseItems"
    static let activeRankingItems = "com.powerscale.activeRankingItems"
    static let savedPairwiseSession = "com.powerscale.savedPairwiseSession"
    static let libraryItems = "com.powerscale.libraryItems"
}

// Define other shared models here
struct PairwiseSession {
    let category: String
    let items: [RankingItem]
    let currentPairIndex: Int
    let winCounts: [Int: Int]
}

