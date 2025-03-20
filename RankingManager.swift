import Foundation
import CoreData
import Combine

// Extension for UserDefaults to store library items
extension UserDefaults {
    private enum Keys {
        static let libraryItems = "com.powerscale.libraryItems"
    }
    
    // Structure to store library item information
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
    
    // Save library item status
    func saveLibraryItem(from item: RankingItem) {
        var items = getSavedLibraryItems()
        
        // Remove existing entry for this item
        items.removeAll { $0.mediaId == item.id &&
                          $0.isAnime == item.isAnime &&
                          $0.isRewatch == item.isRewatch &&
                          $0.rewatchCount == item.rewatchCount }
        
        // Create new info
        let newInfo = LibraryItemInfo(
            mediaId: item.id,
            isAnime: item.isAnime,
            title: item.title,
            coverImageURL: item.coverImage,
            status: item.status,
            progress: item.progress,
            score: item.score,
            startDate: item.startDate,
            endDate: item.endDate,
            isRewatch: item.isRewatch,
            rewatchCount: item.rewatchCount,
            timestamp: Date()
        )
        
        // Add to list and save
        items.append(newInfo)
        saveLibraryItems(items)
    }
    
    private func saveLibraryItems(_ items: [LibraryItemInfo]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: Keys.libraryItems)
        } catch {
            print("Error encoding library items: \(error)")
        }
    }
    
    func getSavedLibraryItems() -> [LibraryItemInfo] {
        guard let data = UserDefaults.standard.data(forKey: Keys.libraryItems) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([LibraryItemInfo].self, from: data)
        } catch {
            print("Error decoding library items: \(error)")
            return []
        }
    }
    
    // Get all saved items for a specific category
    func getSavedLibraryItems(isAnime: Bool, status: String) -> [LibraryItemInfo] {
        return getSavedLibraryItems().filter {
            $0.isAnime == isAnime && $0.status == status
        }
    }
    
    // Get a specific item
    func getSavedLibraryItem(id: Int, isAnime: Bool, isRewatch: Bool = false, rewatchCount: Int = 0) -> LibraryItemInfo? {
        return getSavedLibraryItems().first {
            $0.mediaId == id &&
            $0.isAnime == isAnime &&
            $0.isRewatch == isRewatch &&
            $0.rewatchCount == rewatchCount
        }
    }
    
    // Update progress for a library item
    func updateLibraryItemProgress(id: Int, isAnime: Bool, isRewatch: Bool, rewatchCount: Int, progress: Int) {
        var items = getSavedLibraryItems()
        
        // Find and update the item
        if let index = items.firstIndex(where: {
            $0.mediaId == id &&
            $0.isAnime == isAnime &&
            $0.isRewatch == isRewatch &&
            $0.rewatchCount == rewatchCount
        }) {
            // Create a new item with updated progress
            let updatedItem = LibraryItemInfo(
                mediaId: items[index].mediaId,
                isAnime: items[index].isAnime,
                title: items[index].title,
                coverImageURL: items[index].coverImageURL,
                status: items[index].status,
                progress: progress,
                score: items[index].score,
                startDate: items[index].startDate,
                endDate: items[index].endDate,
                isRewatch: items[index].isRewatch,
                rewatchCount: items[index].rewatchCount,
                timestamp: Date()
            )
            
            // Replace the old item
            items[index] = updatedItem
            saveLibraryItems(items)
        }
    }
    
    // Keys for pairwise ranking data
    private enum PairwiseKeys {
        static let hasSavedSession = "com.powerscale.hasSavedRankingSession"
        static let rankingCategory = "com.powerscale.savedRankingCategory"
        static let currentPairIndex = "com.powerscale.savedCurrentPairIndex"
        static let winCounts = "com.powerscale.savedWinCounts"
        static let pairwiseItems = "com.powerscale.savedPairwiseItems"
        static let activeRankingItems = "com.powerscale.activeRankingItems"
    }
    
    // Structure to store each pair for comparison
    struct PairwiseComparisonPair: Codable {
        let firstItemId: Int
        let secondItemId: Int
        let timestamp: Date
        
        init(firstItemId: Int, secondItemId: Int) {
            self.firstItemId = firstItemId
            self.secondItemId = secondItemId
            self.timestamp = Date()
        }
    }
    
    // Structure to store session information
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
    
    // Save complete pairwise session to UserDefaults
    func savePairwiseSession(session: PairwiseSessionInfo) {
        do {
            // Encode the session info
            let data = try JSONEncoder().encode(session)
            
            // Save all components
            UserDefaults.standard.set(true, forKey: PairwiseKeys.hasSavedSession)
            UserDefaults.standard.set(session.category, forKey: PairwiseKeys.rankingCategory)
            UserDefaults.standard.set(session.currentPairIndex, forKey: PairwiseKeys.currentPairIndex)
            UserDefaults.standard.set(data, forKey: PairwiseKeys.pairwiseItems)
            
            print("✅ Saved pairwise session to UserDefaults")
        } catch {
            print("❌ Error encoding pairwise session: \(error)")
        }
    }
    
    // Get saved pairwise session from UserDefaults
    func getSavedPairwiseSession() -> PairwiseSessionInfo? {
        guard UserDefaults.standard.bool(forKey: PairwiseKeys.hasSavedSession),
              let category = UserDefaults.standard.string(forKey: PairwiseKeys.rankingCategory),
              let data = UserDefaults.standard.data(forKey: PairwiseKeys.pairwiseItems) else {
            return nil
        }
        
        do {
            let decodedSession = try JSONDecoder().decode(PairwiseSessionInfo.self, from: data)
            return decodedSession
        } catch {
            print("❌ Error decoding pairwise session: \(error)")
            return nil
        }
    }
    
    // Clear saved pairwise session
    func clearSavedPairwiseSession() {
        UserDefaults.standard.set(false, forKey: PairwiseKeys.hasSavedSession)
        UserDefaults.standard.removeObject(forKey: PairwiseKeys.rankingCategory)
        UserDefaults.standard.removeObject(forKey: PairwiseKeys.currentPairIndex)
        UserDefaults.standard.removeObject(forKey: PairwiseKeys.pairwiseItems)
        UserDefaults.standard.removeObject(forKey: PairwiseKeys.winCounts)
        UserDefaults.standard.removeObject(forKey: PairwiseKeys.activeRankingItems)
        
        print("✅ Cleared pairwise session from UserDefaults")
    }
}

public class RankingManager: ObservableObject {
    // Shared instance - making it public to ensure accessibility
    public static let shared = RankingManager()
    
    // Core Data manager reference
    let coreDataManager = CoreDataManager.shared
    
    // Published properties for status lists
    @Published var currentlyWatching: [RankingItem] = []
    @Published var currentlyReading: [RankingItem] = []
    @Published var rankedAnime: [RankingItem] = []
    @Published var rankedManga: [RankingItem] = []
    @Published var wantToWatch: [RankingItem] = []
    @Published var wantToRead: [RankingItem] = []
    @Published var onHoldAnime: [RankingItem] = []
    @Published var onHoldManga: [RankingItem] = []
    @Published var lostInterestAnime: [RankingItem] = []
    @Published var lostInterestManga: [RankingItem] = []
    @Published var favoriteAnime: [RankingItem] = []
    @Published var favoriteManga: [RankingItem] = []
    
    // Rewatch storage
    @Published var completedRewatchesAnime: [RankingItem] = []
    @Published var completedRewatchesManga: [RankingItem] = []
    
    // Pairwise comparison properties
    @Published var pairwiseComparison: [(RankingItem, RankingItem)] = []
    @Published var isPairwiseRankingActive: Bool = false
    @Published var currentPairIndex: Int = 0
    @Published var pairwiseCompleted: Bool = false
    @Published var activeRankingCategory: String = ""
    
    // Properties for saving pairwise ranking sessions
    @Published var hasSavedRankingSession: Bool = false
    @Published var savedRankingCategory: String = ""
    @Published var savedPairwiseComparison: [(RankingItem, RankingItem)] = []
    @Published var savedCurrentPairIndex: Int = 0
    @Published var savedWinCounts: [Int: Int] = [:]
    
    // Win counts for pairwise ranking
    var winCounts: [Int: Int] = [:]
    
    // Private initializer for singleton pattern
    private init() {
        loadAllDataFromCoreData()
        loadFromPersistentStorage()
    }
    
    // Modified addItem method to ensure items are only in one category at a time
    // and to save to UserDefaults for development backup
    func addItem(_ item: RankingItem, category: String) {
        // If this isn't a rewatch, remove any non-rewatch version of the item
        if !item.isRewatch {
            removeItemFromAllCategories(id: item.id, isAnime: item.isAnime, onlyNonRewatches: true)
        }
        
        // Add to the appropriate category
        if category == "Anime" {
            switch item.status {
            case "Currently Watching":
                // If this is a new rewatch, keep the original in the completed list
                if item.isRewatch {
                    // Just add to currently watching
                    currentlyWatching.append(item)
                } else {
                    // Remove from all categories and add to currently watching
                    removeItemFromAllCategories(id: item.id, isAnime: true)
                    currentlyWatching.append(item)
                }
                
            case "Completed":
                // Handle completed rewatches differently
                if item.isRewatch {
                    // Add to completed rewatches
                    completedRewatchesAnime.append(item)
                } else {
                    // Remove from all categories and add to completed
                    removeItemFromAllCategories(id: item.id, isAnime: true)
                    rankedAnime.append(item)
                }
                
            case "Want to Watch":
                removeItemFromAllCategories(id: item.id, isAnime: true)
                wantToWatch.append(item)
                
            case "On Hold":
                removeItemFromAllCategories(id: item.id, isAnime: true)
                onHoldAnime.append(item)
                
            case "Lost Interest":
                removeItemFromAllCategories(id: item.id, isAnime: true)
                lostInterestAnime.append(item)
                
            default:
                break
            }
        } else { // Manga category
            switch item.status {
            case "Currently Reading":
                // If this is a new rewatch, keep the original in the completed list
                if item.isRewatch {
                    // Just add to currently reading
                    currentlyReading.append(item)
                } else {
                    // Remove from all categories and add to currently reading
                    removeItemFromAllCategories(id: item.id, isAnime: false)
                    currentlyReading.append(item)
                }
                
            case "Completed":
                // Handle completed rewatches differently
                if item.isRewatch {
                    // Add to completed rewatches
                    completedRewatchesManga.append(item)
                } else {
                    // Remove from all categories and add to completed
                    removeItemFromAllCategories(id: item.id, isAnime: false)
                    rankedManga.append(item)
                }
                
            case "Want to Read":
                removeItemFromAllCategories(id: item.id, isAnime: false)
                wantToRead.append(item)
                
            case "On Hold":
                removeItemFromAllCategories(id: item.id, isAnime: false)
                onHoldManga.append(item)
                
            case "Lost Interest":
                removeItemFromAllCategories(id: item.id, isAnime: false)
                lostInterestManga.append(item)
                
            default:
                break
            }
        }
        
        // Also update Core Data
        updateCoreDataForItem(item)
        
        // Save to UserDefaults for development backup
        UserDefaults.standard.saveLibraryItem(from: item)
    }
    
    // Helper method to remove an item from all categories
    func removeItemFromAllCategories(id: Int, isAnime: Bool, onlyNonRewatches: Bool = false) {
        if isAnime {
            if onlyNonRewatches {
                // Only remove non-rewatch items
                currentlyWatching.removeAll { $0.id == id && !$0.isRewatch }
                rankedAnime.removeAll { $0.id == id && !$0.isRewatch }
                wantToWatch.removeAll { $0.id == id && !$0.isRewatch }
                onHoldAnime.removeAll { $0.id == id && !$0.isRewatch }
                lostInterestAnime.removeAll { $0.id == id && !$0.isRewatch }
            } else {
                // Remove all items with this id
                currentlyWatching.removeAll { $0.id == id }
                rankedAnime.removeAll { $0.id == id }
                completedRewatchesAnime.removeAll { $0.id == id }
                wantToWatch.removeAll { $0.id == id }
                onHoldAnime.removeAll { $0.id == id }
                lostInterestAnime.removeAll { $0.id == id }
            }
        } else {
            if onlyNonRewatches {
                // Only remove non-rewatch items
                currentlyReading.removeAll { $0.id == id && !$0.isRewatch }
                rankedManga.removeAll { $0.id == id && !$0.isRewatch }
                wantToRead.removeAll { $0.id == id && !$0.isRewatch }
                onHoldManga.removeAll { $0.id == id && !$0.isRewatch }
                lostInterestManga.removeAll { $0.id == id && !$0.isRewatch }
            } else {
                // Remove all items with this id
                currentlyReading.removeAll { $0.id == id }
                rankedManga.removeAll { $0.id == id }
                completedRewatchesManga.removeAll { $0.id == id }
                wantToRead.removeAll { $0.id == id }
                onHoldManga.removeAll { $0.id == id }
                lostInterestManga.removeAll { $0.id == id }
            }
        }
    }
    
    // Find if an item exists in any list
    func findExistingItem(id: Int, isAnime: Bool) -> RankingItem? {
        if isAnime {
            // Check anime lists
            if let item = currentlyWatching.first(where: { $0.id == id && !$0.isRewatch }) {
                return item
            }
            if let item = rankedAnime.first(where: { $0.id == id }) {
                return item
            }
            if let item = wantToWatch.first(where: { $0.id == id }) {
                return item
            }
            if let item = onHoldAnime.first(where: { $0.id == id }) {
                return item
            }
            if let item = lostInterestAnime.first(where: { $0.id == id }) {
                return item
            }
        } else {
            // Check manga lists
            if let item = currentlyReading.first(where: { $0.id == id && !$0.isRewatch }) {
                return item
            }
            if let item = rankedManga.first(where: { $0.id == id }) {
                return item
            }
            if let item = wantToRead.first(where: { $0.id == id }) {
                return item
            }
            if let item = onHoldManga.first(where: { $0.id == id }) {
                return item
            }
            if let item = lostInterestManga.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }
    
    // Find the current status of an item
    func getCurrentStatus(id: Int, isAnime: Bool) -> String {
        if isAnime {
            if currentlyWatching.contains(where: { $0.id == id && !$0.isRewatch }) {
                return "Currently Watching"
            }
            if rankedAnime.contains(where: { $0.id == id }) {
                return "Completed"
            }
            if wantToWatch.contains(where: { $0.id == id }) {
                return "Want to Watch"
            }
            if onHoldAnime.contains(where: { $0.id == id }) {
                return "On Hold"
            }
            if lostInterestAnime.contains(where: { $0.id == id }) {
                return "Lost Interest"
            }
        } else {
            if currentlyReading.contains(where: { $0.id == id && !$0.isRewatch }) {
                return "Currently Reading"
            }
            if rankedManga.contains(where: { $0.id == id }) {
                return "Completed"
            }
            if wantToRead.contains(where: { $0.id == id }) {
                return "Want to Read"
            }
            if onHoldManga.contains(where: { $0.id == id }) {
                return "On Hold"
            }
            if lostInterestManga.contains(where: { $0.id == id }) {
                return "Lost Interest"
            }
        }
        return ""
    }
    
    // Update progress for an item (including rewatches)
    // Also save to UserDefaults for development backup
    func updateProgress(id: Int, isAnime: Bool, isRewatch: Bool, rewatchCount: Int, progress: Int) {
        // Find the item to update
        var itemToUpdate: RankingItem?
        
        if isAnime {
            if isRewatch {
                itemToUpdate = currentlyWatching.first(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                })
            } else {
                itemToUpdate = currentlyWatching.first(where: { $0.id == id && !$0.isRewatch })
            }
        } else {
            if isRewatch {
                itemToUpdate = currentlyReading.first(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                })
            } else {
                itemToUpdate = currentlyReading.first(where: { $0.id == id && !$0.isRewatch })
            }
        }
        
        if let item = itemToUpdate {
            // Create updated item with new progress
            let updatedItem = RankingItem(
                from: item.toAnime(),
                status: item.status,
                isAnime: item.isAnime,
                rank: item.rank,
                score: item.score,
                startDate: item.startDate,
                endDate: item.endDate,
                isRewatch: item.isRewatch,
                rewatchCount: item.rewatchCount,
                progress: progress
            )
            
            // Remove old item
            if isAnime {
                if isRewatch {
                    currentlyWatching.removeAll(where: {
                        $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                    })
                } else {
                    currentlyWatching.removeAll(where: { $0.id == id && !$0.isRewatch })
                }
            } else {
                if isRewatch {
                    currentlyReading.removeAll(where: {
                        $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                    })
                } else {
                    currentlyReading.removeAll(where: { $0.id == id && !$0.isRewatch })
                }
            }
            
            // Add updated item
            if isAnime {
                currentlyWatching.append(updatedItem)
            } else {
                currentlyReading.append(updatedItem)
            }
            
            // Update in Core Data
            updateCoreDataForItem(updatedItem)
            
            // Update in UserDefaults for development backup
            UserDefaults.standard.updateLibraryItemProgress(
                id: id,
                isAnime: isAnime,
                isRewatch: isRewatch,
                rewatchCount: rewatchCount,
                progress: progress
            )
        }
    }
    
    // Update rating for an item
    func updateRating(id: Int, isAnime: Bool, isRewatch: Bool, rewatchCount: Int, rating: Double) {
        // Find the item to update
        var itemToUpdate: RankingItem?
        var listType: String = ""
        
        if isAnime {
            if isRewatch && rewatchCount > 0 {
                if let item = currentlyWatching.first(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                }) {
                    itemToUpdate = item
                    listType = "currentlyWatching"
                } else if let item = completedRewatchesAnime.first(where: {
                    $0.id == id && $0.rewatchCount == rewatchCount
                }) {
                    itemToUpdate = item
                    listType = "completedRewatchesAnime"
                }
            } else {
                // Check all anime lists
                if let item = currentlyWatching.first(where: { $0.id == id && !$0.isRewatch }) {
                    itemToUpdate = item
                    listType = "currentlyWatching"
                } else if let item = rankedAnime.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "rankedAnime"
                } else if let item = wantToWatch.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "wantToWatch"
                } else if let item = onHoldAnime.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "onHoldAnime"
                } else if let item = lostInterestAnime.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "lostInterestAnime"
                }
            }
        } else {
            // Similar logic for manga
            if isRewatch && rewatchCount > 0 {
                if let item = currentlyReading.first(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == rewatchCount
                }) {
                    itemToUpdate = item
                    listType = "currentlyReading"
                } else if let item = completedRewatchesManga.first(where: {
                    $0.id == id && $0.rewatchCount == rewatchCount
                }) {
                    itemToUpdate = item
                    listType = "completedRewatchesManga"
                }
            } else {
                // Check all manga lists
                if let item = currentlyReading.first(where: { $0.id == id && !$0.isRewatch }) {
                    itemToUpdate = item
                    listType = "currentlyReading"
                } else if let item = rankedManga.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "rankedManga"
                } else if let item = wantToRead.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "wantToRead"
                } else if let item = onHoldManga.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "onHoldManga"
                } else if let item = lostInterestManga.first(where: { $0.id == id }) {
                    itemToUpdate = item
                    listType = "lostInterestManga"
                }
            }
        }
        
        if let item = itemToUpdate {
            // Create updated item with new rating
            let updatedItem = RankingItem(
                id: item.id,
                title: item.title,
                coverImage: item.coverImage,
                status: item.status,
                isAnime: item.isAnime,
                rank: item.rank,
                score: rating,
                startDate: item.startDate,
                endDate: item.endDate,
                isRewatch: item.isRewatch,
                rewatchCount: item.rewatchCount,
                progress: item.progress
            )
            
            // Update the appropriate list
            updateItemInAppropriateList(item: updatedItem)
            
            // Update in Core Data - This is critical for persistence
            updateCoreDataForItem(updatedItem)
            
            // Save to UserDefaults for development backup
            UserDefaults.standard.saveLibraryItem(from: updatedItem)
        }
    }
    
    // Helper method to update item in the appropriate list
    private func updateItemInAppropriateList(item: RankingItem) {
        if item.isAnime {
            switch item.status {
            case "Completed":
                if let index = rankedAnime.firstIndex(where: { $0.id == item.id }) {
                    rankedAnime[index] = item
                }
            case "Currently Watching":
                if let index = currentlyWatching.firstIndex(where: {
                    $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount
                }) {
                    currentlyWatching[index] = item
                }
            case "On Hold":
                if let index = onHoldAnime.firstIndex(where: { $0.id == item.id }) {
                    onHoldAnime[index] = item
                }
            case "Lost Interest":
                if let index = lostInterestAnime.firstIndex(where: { $0.id == item.id }) {
                    lostInterestAnime[index] = item
                }
            case "Want to Watch":
                if let index = wantToWatch.firstIndex(where: { $0.id == item.id }) {
                    wantToWatch[index] = item
                }
            default:
                break
            }
        } else {
            // Similar logic for manga
            switch item.status {
            case "Completed":
                if let index = rankedManga.firstIndex(where: { $0.id == item.id }) {
                    rankedManga[index] = item
                }
            case "Currently Reading":
                if let index = currentlyReading.firstIndex(where: {
                    $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount
                }) {
                    currentlyReading[index] = item
                }
            case "On Hold":
                if let index = onHoldManga.firstIndex(where: { $0.id == item.id }) {
                    onHoldManga[index] = item
                }
            case "Lost Interest":
                if let index = lostInterestManga.firstIndex(where: { $0.id == item.id }) {
                    lostInterestManga[index] = item
                }
            case "Want to Read":
                if let index = wantToRead.firstIndex(where: { $0.id == item.id }) {
                    wantToRead[index] = item
                }
            default:
                break
            }
        }
    }
    
        // Enhanced method to save ranking session
            func saveRankingSession() {
                // Existing code to set properties
                hasSavedRankingSession = true
                savedRankingCategory = activeRankingCategory
                savedPairwiseComparison = pairwiseComparison
                savedCurrentPairIndex = currentPairIndex
                savedWinCounts = winCounts
                
                // New code to save to UserDefaults
                saveToPersistentStorage()
            }
            
            // Enhanced method to save to UserDefaults (updated version)
            func saveToPersistentStorage() {
                // Save basic session information
                UserDefaults.standard.set(hasSavedRankingSession, forKey: "hasSavedRankingSession")
                UserDefaults.standard.set(savedRankingCategory, forKey: "savedRankingCategory")
                UserDefaults.standard.set(savedCurrentPairIndex, forKey: "savedCurrentPairIndex")
                
                // Convert pairwise comparison to a saveable format
                if !savedPairwiseComparison.isEmpty {
                    var pairwisePairs = [UserDefaults.PairwiseComparisonPair]()
                    for (item1, item2) in savedPairwiseComparison {
                        pairwisePairs.append(UserDefaults.PairwiseComparisonPair(
                            firstItemId: item1.id,
                            secondItemId: item2.id
                        ))
                    }
                    
                    // Get IDs of all items involved in the ranking
                    var activeItemIds = Set<Int>()
                    for (item1, item2) in savedPairwiseComparison {
                        activeItemIds.insert(item1.id)
                        activeItemIds.insert(item2.id)
                    }
                    
                    // Create the session info
                    let sessionInfo = UserDefaults.PairwiseSessionInfo(
                        category: savedRankingCategory,
                        pairwiseItems: pairwisePairs,
                        currentPairIndex: savedCurrentPairIndex,
                        winCounts: savedWinCounts,
                        activeRankingItemIds: Array(activeItemIds)
                    )
                    
                    // Save to UserDefaults
                    UserDefaults.standard.savePairwiseSession(session: sessionInfo)
                } else {
                    // If there's no comparison data, just save the win counts
                    if let data = try? JSONEncoder().encode(savedWinCounts) {
                        UserDefaults.standard.set(data, forKey: "savedWinCounts")
                    }
                }
            }
            
            // Enhanced method to load from persistent storage
            func loadFromPersistentStorage() {
                // Load the basic session flags
                hasSavedRankingSession = UserDefaults.standard.bool(forKey: "hasSavedRankingSession")
                savedRankingCategory = UserDefaults.standard.string(forKey: "savedRankingCategory") ?? ""
                savedCurrentPairIndex = UserDefaults.standard.integer(forKey: "savedCurrentPairIndex")
                
                // Load win counts
                if let data = UserDefaults.standard.data(forKey: "savedWinCounts") {
                    if let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
                        savedWinCounts = decoded
                    }
                }
                
                // Try to load the full session info
                if hasSavedRankingSession, let session = UserDefaults.standard.getSavedPairwiseSession() {
                    print("📊 Loaded pairwise session from UserDefaults")
                    
                    // Reconstitute the pairwise comparison pairs using the item IDs
                    recreatePairwiseComparison(from: session)
                }
            }
            
            // Helper method to recreate the pairwise comparison from saved IDs
            private func recreatePairwiseComparison(from session: UserDefaults.PairwiseSessionInfo) {
                // Early exit if there are no pairs
                if session.pairwiseItems.isEmpty {
                    return
                }
                
                // First, create a dictionary of all items by ID for quick lookup
                var itemsById = [Int: RankingItem]()
                
                // The items could be in any list depending on their status
                // Anime lists
                for item in rankedAnime + currentlyWatching + wantToWatch + onHoldAnime + lostInterestAnime {
                    itemsById[item.id] = item
                }
                
                // Manga lists
                for item in rankedManga + currentlyReading + wantToRead + onHoldManga + lostInterestManga {
                    itemsById[item.id] = item
                }
                
                // Now recreate the pairwise comparisons
                savedPairwiseComparison = []
                
                for pair in session.pairwiseItems {
                    if let item1 = itemsById[pair.firstItemId],
                       let item2 = itemsById[pair.secondItemId] {
                        savedPairwiseComparison.append((item1, item2))
                    }
                }
                
                // Update the saved win counts
                savedWinCounts = session.winCounts
                
                // Log the recovery status
                print("📊 Recreated \(savedPairwiseComparison.count)/\(session.pairwiseItems.count) pairwise comparisons")
                
                // Make sure the current pair index is valid
                if savedCurrentPairIndex >= savedPairwiseComparison.count {
                    savedCurrentPairIndex = savedPairwiseComparison.count - 1
                    if savedCurrentPairIndex < 0 {
                        savedCurrentPairIndex = 0
                    }
                }
            }
            
            // Method to resume a saved session
            func resumeSavedSession() {
                if hasSavedRankingSession {
                    activeRankingCategory = savedRankingCategory
                    pairwiseComparison = savedPairwiseComparison
                    currentPairIndex = savedCurrentPairIndex
                    winCounts = savedWinCounts
                    isPairwiseRankingActive = true
                    pairwiseCompleted = false
                }
            }
            
            // Clear the saved session (enhanced version)
            func clearSavedSession() {
                hasSavedRankingSession = false
                savedRankingCategory = ""
                savedPairwiseComparison = []
                savedCurrentPairIndex = 0
                savedWinCounts = [:]
                
                // Clear in UserDefaults
                UserDefaults.standard.clearSavedPairwiseSession()
            }
            
            // Load all data from CoreData into the RankingManager
            func loadAllDataFromCoreData() {
                // Clear existing data
                currentlyWatching = []
                currentlyReading = []
                rankedAnime = []
                rankedManga = []
                wantToWatch = []
                wantToRead = []
                onHoldAnime = []
                onHoldManga = []
                lostInterestAnime = []
                lostInterestManga = []
                favoriteAnime = []
                favoriteManga = []
                completedRewatchesAnime = []
                completedRewatchesManga = []
                
                // Load anime lists from Core Data
                currentlyWatching = loadRankingItems(isAnime: true, status: "Currently Watching")
                rankedAnime = loadRankingItems(isAnime: true, status: "Completed", isRewatch: false)
                wantToWatch = loadRankingItems(isAnime: true, status: "Want to Watch")
                onHoldAnime = loadRankingItems(isAnime: true, status: "On Hold")
                lostInterestAnime = loadRankingItems(isAnime: true, status: "Lost Interest")
                completedRewatchesAnime = loadRankingItems(isAnime: true, status: "Completed", isRewatch: true)
                
                // Load manga lists from Core Data
                currentlyReading = loadRankingItems(isAnime: false, status: "Currently Reading")
                rankedManga = loadRankingItems(isAnime: false, status: "Completed", isRewatch: false)
                wantToRead = loadRankingItems(isAnime: false, status: "Want to Read")
                onHoldManga = loadRankingItems(isAnime: false, status: "On Hold")
                lostInterestManga = loadRankingItems(isAnime: false, status: "Lost Interest")
                completedRewatchesManga = loadRankingItems(isAnime: false, status: "Completed", isRewatch: true)
                
                // If any lists are empty, try loading from UserDefaults backup
                recoverFromUserDefaultsIfNeeded()
                
                // Note: Character loading is not implemented yet
                // When implemented, you would call a method like loadCharacters() here
            }

            // New method to recover lists from UserDefaults if Core Data is empty
            private func recoverFromUserDefaultsIfNeeded() {
                let savedItems = UserDefaults.standard.getSavedLibraryItems()
                if !savedItems.isEmpty {
                    print("📦 Found \(savedItems.count) items in UserDefaults backup")
                    
                    // Only recover lists that are empty
                    if currentlyWatching.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "Currently Watching" && !$0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Currently Watching items from backup")
                            currentlyWatching = recovered
                        }
                    }
                    
                    if rankedAnime.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "Completed" && !$0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Completed Anime items from backup")
                            rankedAnime = recovered
                        }
                    }
                    
                    if wantToWatch.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "Want to Watch"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Want to Watch items from backup")
                            wantToWatch = recovered
                        }
                    }
                    
                    if onHoldAnime.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "On Hold"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) On Hold Anime items from backup")
                            onHoldAnime = recovered
                        }
                    }
                    
                    if lostInterestAnime.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "Lost Interest"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Lost Interest Anime items from backup")
                            lostInterestAnime = recovered
                        }
                    }
                    
                    if completedRewatchesAnime.isEmpty {
                        let recovered = savedItems.filter {
                            $0.isAnime && $0.status == "Completed" && $0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Completed Rewatch Anime items from backup")
                            completedRewatchesAnime = recovered
                        }
                    }
                    
                    // Manga lists recovery
                    if currentlyReading.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "Currently Reading" && !$0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Currently Reading items from backup")
                            currentlyReading = recovered
                        }
                    }
                    
                    if rankedManga.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "Completed" && !$0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Completed Manga items from backup")
                            rankedManga = recovered
                        }
                    }
                    
                    if wantToRead.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "Want to Read"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Want to Read items from backup")
                            wantToRead = recovered
                        }
                    }
                    
                    if onHoldManga.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "On Hold"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) On Hold Manga items from backup")
                            onHoldManga = recovered
                        }
                    }
                    
                    if lostInterestManga.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "Lost Interest"
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Lost Interest Manga items from backup")
                            lostInterestManga = recovered
                        }
                    }
                    
                    if completedRewatchesManga.isEmpty {
                        let recovered = savedItems.filter {
                            !$0.isAnime && $0.status == "Completed" && $0.isRewatch
                        }.map { $0.toRankingItem() }
                        if !recovered.isEmpty {
                            print("🔄 Recovering \(recovered.count) Completed Reread Manga items from backup")
                            completedRewatchesManga = recovered
                        }
                    }
                    
                    // After recovery, save any recovered items to Core Data
                    syncRecoveredItemsToCoreData()
                }
            }
            
            // Sync recovered items back to Core Data
            private func syncRecoveredItemsToCoreData() {
                // For each list, save items to Core Data
                for item in currentlyWatching + rankedAnime + wantToWatch + onHoldAnime + lostInterestAnime +
                           completedRewatchesAnime + currentlyReading + rankedManga + wantToRead +
                           onHoldManga + lostInterestManga + completedRewatchesManga {
                    updateCoreDataForItem(item)
                }
                
                print("✅ Synced recovered items back to Core Data")
            }

            // Load RankingItems from Core Data for a given type and status.
            func loadRankingItems(isAnime: Bool, status: String, isRewatch: Bool = false) -> [RankingItem] {
                let animeItems = coreDataManager.fetchAnimeItems(isAnime: isAnime, status: status, isRewatch: isRewatch)
                return animeItems.map { $0.toRankingItem() }
            }
            
            /*
            // NOTE: Character management methods commented out
            // These methods would require additional implementation in CoreDataManager
            // or they should be implemented when you add character management features
            
            // Load characters from Core Data
            func loadCharacters() {
                // This would load characters from CoreData when implemented
                // For now, we'll leave this method as a placeholder
                print("Character loading not implemented yet")
            }
            
            // Character storage methods
            func saveCharacterToStorage(_ character: CharacterRankItem) {
                // This would save a character to CoreData when implemented
                print("Character saving not implemented yet")
            }
            
            func updateCharacterInStorage(_ character: CharacterRankItem) {
                // This would update a character in CoreData when implemented
                print("Character updating not implemented yet")
            }
            
            func deleteCharacterFromStorage(_ characterId: Int) {
                // This would delete a character from CoreData when implemented
                print("Character deletion not implemented yet")
            }
            */

            // Update Core Data for a RankingItem
            func updateCoreDataForItem(_ item: RankingItem) {
                // Get the Core Data context
                let context = coreDataManager.container.viewContext

                // Create or update AnimeItem in Core Data
                _ = item.toAnimeItem(context: context)

                // Save the context
                coreDataManager.saveContext()
            }
            
            /// Saves a single library change by updating the Core Data entry for the item.
            func saveLibraryChange(for item: RankingItem) {
                updateCoreDataForItem(item)
                
                // Also save to UserDefaults for development backup
                UserDefaults.standard.saveLibraryItem(from: item)
                
                // Optionally, you could add additional logging or even UI feedback here.
                print("Library change saved for item: \(item.title)")
            }
            
            func updateRating(id: Int, isAnime: Bool, newRating: Double) {
                // Find the item from your lists (example for anime)
                if isAnime, let index = currentlyWatching.firstIndex(where: { $0.id == id }) {
                    var item = currentlyWatching[index]
                    item.score = newRating
                    currentlyWatching[index] = item
                    // Persist the change
                    saveLibraryChange(for: item)
                }
                
                // Check other anime lists
                if isAnime, let index = rankedAnime.firstIndex(where: { $0.id == id }) {
                    var item = rankedAnime[index]
                    item.score = newRating
                    rankedAnime[index] = item
                    saveLibraryChange(for: item)
                }
                
                if isAnime, let index = wantToWatch.firstIndex(where: { $0.id == id }) {
                    var item = wantToWatch[index]
                    item.score = newRating
                    wantToWatch[index] = item
                    saveLibraryChange(for: item)
                }
                
                if isAnime, let index = onHoldAnime.firstIndex(where: { $0.id == id }) {
                    var item = onHoldAnime[index]
                    item.score = newRating
                    onHoldAnime[index] = item
                    saveLibraryChange(for: item)
                }
                
                if isAnime, let index = lostInterestAnime.firstIndex(where: { $0.id == id }) {
                    var item = lostInterestAnime[index]
                    item.score = newRating
                    lostInterestAnime[index] = item
                    saveLibraryChange(for: item)
                }
                
                // Manga lists
                if !isAnime, let index = currentlyReading.firstIndex(where: { $0.id == id }) {
                    var item = currentlyReading[index]
                    item.score = newRating
                    currentlyReading[index] = item
                    saveLibraryChange(for: item)
                }
                
                if !isAnime, let index = rankedManga.firstIndex(where: { $0.id == id }) {
                    var item = rankedManga[index]
                    item.score = newRating
                    rankedManga[index] = item
                    saveLibraryChange(for: item)
                }
                
                if !isAnime, let index = wantToRead.firstIndex(where: { $0.id == id }) {
                    var item = wantToRead[index]
                    item.score = newRating
                    wantToRead[index] = item
                    saveLibraryChange(for: item)
                }
                
                if !isAnime, let index = onHoldManga.firstIndex(where: { $0.id == id }) {
                    var item = onHoldManga[index]
                    item.score = newRating
                    onHoldManga[index] = item
                    saveLibraryChange(for: item)
                }
                
                if !isAnime, let index = lostInterestManga.firstIndex(where: { $0.id == id }) {
                    var item = lostInterestManga[index]
                    item.score = newRating
                    lostInterestManga[index] = item
                    saveLibraryChange(for: item)
                }
            }
        }
