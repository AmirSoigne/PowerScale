import Foundation
import CoreData

extension RankingManager {
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
