import Foundation

// Extension for rewatch-related functionality
extension RankingManager {
    // MARK: - Rewatch Management Methods
    
    // Check if an item has any rewatches
    func hasRewatches(id: Int, isAnime: Bool) -> Bool {
        if isAnime {
            return currentlyWatching.contains(where: { $0.id == id && $0.isRewatch }) ||
                   completedRewatchesAnime.contains(where: { $0.id == id })
        } else {
            return currentlyReading.contains(where: { $0.id == id && $0.isRewatch }) ||
                   completedRewatchesManga.contains(where: { $0.id == id })
        }
    }
    
    // Check if an item is specifically a rewatch
    func isItemRewatch(id: Int, isAnime: Bool) -> Bool {
        if isAnime {
            return currentlyWatching.contains(where: { $0.id == id && $0.isRewatch })
        } else {
            return currentlyReading.contains(where: { $0.id == id && $0.isRewatch })
        }
    }
    
    // Get the current rewatch item that's in progress
    func getCurrentRewatchItem(id: Int, isAnime: Bool) -> RankingItem? {
        if isAnime {
            return currentlyWatching.first(where: { $0.id == id && $0.isRewatch })
        } else {
            return currentlyReading.first(where: { $0.id == id && $0.isRewatch })
        }
    }
    
    // Get all rewatches for an item
    func getRewatches(id: Int, isAnime: Bool) -> [RankingItem] {
        if isAnime {
            return currentlyWatching.filter { $0.id == id && $0.isRewatch }
        } else {
            return currentlyReading.filter { $0.id == id && $0.isRewatch }
        }
    }
    
    // Get all completed rewatches for an item
    func getCompletedRewatches(id: Int, isAnime: Bool) -> [RankingItem] {
        var result: [RankingItem] = []
        var seenCounts = Set<Int>()
        
        if isAnime {
            // Get all rewatches for this ID
            let allRewatches = completedRewatchesAnime.filter { $0.id == id }
            
            // Only include rewatches with unique counts
            for rewatch in allRewatches.sorted(by: { $0.rewatchCount < $1.rewatchCount }) {
                if !seenCounts.contains(rewatch.rewatchCount) {
                    result.append(rewatch)
                    seenCounts.insert(rewatch.rewatchCount)
                }
            }
        } else {
            // Same logic for manga
            let allRewatches = completedRewatchesManga.filter { $0.id == id }
            
            for rewatch in allRewatches.sorted(by: { $0.rewatchCount < $1.rewatchCount }) {
                if !seenCounts.contains(rewatch.rewatchCount) {
                    result.append(rewatch)
                    seenCounts.insert(rewatch.rewatchCount)
                }
            }
        }
        
        return result
    }
    
    // Start a new rewatch for a completed item
    func startRewatch(for item: RankingItem) {
        // Create a rewatch item
        let rewatch = RankingItem.createRewatch(from: item)
        
        // Add it to the watching/reading list
        if item.isAnime {
            currentlyWatching.append(rewatch)
        } else {
            currentlyReading.append(rewatch)
        }
        
        // Update in Core Data
        updateCoreDataForItem(rewatch)
    }
    
    // Complete a rewatch with better handling to avoid duplicates
    func completeRewatch(id: Int, isAnime: Bool, endDate: Date?) -> Bool {
        // Find the current rewatch
        if let currentRewatch = getCurrentRewatchItem(id: id, isAnime: isAnime) {
            // Create a completed version of this rewatch with the provided end date
            let completedRewatch = RankingItem(
                id: currentRewatch.id,
                title: currentRewatch.title,
                coverImage: currentRewatch.coverImage,
                status: "Completed",
                isAnime: currentRewatch.isAnime,
                rank: currentRewatch.rank,
                score: currentRewatch.score,
                startDate: currentRewatch.startDate,
                endDate: endDate ?? Date(), // Use provided date or today
                isRewatch: true,
                rewatchCount: currentRewatch.rewatchCount, // Preserve the original count
                progress: totalEpisodesFor(id: id, isAnime: isAnime)
            )
            
            // First remove the in-progress rewatch to avoid duplication
            if isAnime {
                currentlyWatching.removeAll(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == currentRewatch.rewatchCount
                })
            } else {
                currentlyReading.removeAll(where: {
                    $0.id == id && $0.isRewatch && $0.rewatchCount == currentRewatch.rewatchCount
                })
            }
            
            // Make sure there isn't already a completed rewatch with this number
            if isAnime {
                completedRewatchesAnime.removeAll(where: {
                    $0.id == id && $0.rewatchCount == currentRewatch.rewatchCount
                })
            } else {
                completedRewatchesManga.removeAll(where: {
                    $0.id == id && $0.rewatchCount == currentRewatch.rewatchCount
                })
            }
            
            // Add to completed rewatches
            if isAnime {
                completedRewatchesAnime.append(completedRewatch)
            } else {
                completedRewatchesManga.append(completedRewatch)
            }
            
            // Update in Core Data
            updateCoreDataForItem(completedRewatch)
            
            return true
        }
        
        return false
    }
    
    // Get the next rewatch number for a new rewatch
    func getNextRewatchNumber(id: Int, isAnime: Bool) -> Int {
        // Get all rewatches (both completed and in-progress)
        let completedRewatches = getCompletedRewatches(id: id, isAnime: isAnime)
        let inProgressRewatches = getRewatches(id: id, isAnime: isAnime)
        
        // Create a set of all rewatch numbers already in use
        let usedRewatchNumbers = Set(
            completedRewatches.map { $0.rewatchCount } +
            inProgressRewatches.map { $0.rewatchCount }
        )
        
        // Start with 1 as the first rewatch number
        var nextNumber = 1
        
        // Find the smallest number that's not already used
        while usedRewatchNumbers.contains(nextNumber) {
            nextNumber += 1
        }
        
        return nextNumber
    }
    
    // Cleanup and fix rewatches (reorganize numbers and remove duplicates)
    func cleanupAndFixRewatches(id: Int, isAnime: Bool) {
        if isAnime {
            // Get all rewatches for this anime ID
            var allRewatches = completedRewatchesAnime.filter { $0.id == id }
            
            // Sort by rewatch count
            allRewatches.sort { $0.rewatchCount < $1.rewatchCount }
            
            // Remove all existing rewatches for this ID
            DispatchQueue.main.async {
                self.completedRewatchesAnime.removeAll { $0.id == id }
            }

            // Re-add them with correct sequential numbering
            for (index, rewatch) in allRewatches.enumerated() {
                // Create a fixed rewatch with the correct count
                let fixedRewatch = RankingItem(
                    id: rewatch.id,
                    title: rewatch.title,
                    coverImage: rewatch.coverImage,
                    status: rewatch.status,
                    isAnime: rewatch.isAnime,
                    rank: rewatch.rank,
                    score: rewatch.score,
                    startDate: rewatch.startDate,
                    endDate: rewatch.endDate,
                    isRewatch: true,
                    rewatchCount: index + 1, // Assign sequential numbers starting from 1
                    progress: rewatch.progress
                )
                
                // Add the fixed rewatch
                completedRewatchesAnime.append(fixedRewatch)
                
                // Update in Core Data
                updateCoreDataForItem(fixedRewatch)
            }
            
            // Also check for duplicates in currentlyWatching
            if let currentRewatch = currentlyWatching.first(where: { $0.id == id && $0.isRewatch }) {
                // Ensure it has the next sequential number
                let nextNumber = completedRewatchesAnime.filter({ $0.id == id }).count + 1
                
                if currentRewatch.rewatchCount != nextNumber {
                    // Remove the current rewatch
                    currentlyWatching.removeAll { $0.id == id && $0.isRewatch }
                    
                    // Create a corrected version
                    let correctedRewatch = RankingItem(
                        id: currentRewatch.id,
                        title: currentRewatch.title,
                        coverImage: currentRewatch.coverImage,
                        status: currentRewatch.status,
                        isAnime: currentRewatch.isAnime,
                        rank: currentRewatch.rank,
                        score: currentRewatch.score,
                        startDate: currentRewatch.startDate,
                        endDate: currentRewatch.endDate,
                        isRewatch: true,
                        rewatchCount: nextNumber,
                        progress: currentRewatch.progress
                    )
                    
                    // Add the corrected rewatch
                    currentlyWatching.append(correctedRewatch)
                    
                    // Update in Core Data
                    updateCoreDataForItem(correctedRewatch)
                }
            }
        } else {
            // Similar logic for manga rewatches
            var allRewatches = completedRewatchesManga.filter { $0.id == id }
            
            // Sort by rewatch count
            allRewatches.sort { $0.rewatchCount < $1.rewatchCount }
            
            // Remove all existing rewatches for this ID
            completedRewatchesManga.removeAll { $0.id == id }
            
            // Re-add them with correct sequential numbering
            for (index, rewatch) in allRewatches.enumerated() {
                // Create a fixed rewatch with the correct count
                let fixedRewatch = RankingItem(
                    id: rewatch.id,
                    title: rewatch.title,
                    coverImage: rewatch.coverImage,
                    status: rewatch.status,
                    isAnime: rewatch.isAnime,
                    rank: rewatch.rank,
                    score: rewatch.score,
                    startDate: rewatch.startDate,
                    endDate: rewatch.endDate,
                    isRewatch: true,
                    rewatchCount: index + 1, // Assign sequential numbers starting from 1
                    progress: rewatch.progress
                )
                
                // Add the fixed rewatch
                completedRewatchesManga.append(fixedRewatch)
                
                // Update in Core Data
                updateCoreDataForItem(fixedRewatch)
            }
            
            // Also check for duplicates in currentlyReading
            if let currentRewatch = currentlyReading.first(where: { $0.id == id && $0.isRewatch }) {
                // Ensure it has the next sequential number
                let nextNumber = completedRewatchesManga.filter({ $0.id == id }).count + 1
                
                if currentRewatch.rewatchCount != nextNumber {
                    // Remove the current rewatch
                    currentlyReading.removeAll { $0.id == id && $0.isRewatch }
                    
                    // Create a corrected version
                    let correctedRewatch = RankingItem(
                        id: currentRewatch.id,
                        title: currentRewatch.title,
                        coverImage: currentRewatch.coverImage,
                        status: currentRewatch.status,
                        isAnime: currentRewatch.isAnime,
                        rank: currentRewatch.rank,
                        score: currentRewatch.score,
                        startDate: currentRewatch.startDate,
                        endDate: currentRewatch.endDate,
                        isRewatch: true,
                        rewatchCount: nextNumber,
                        progress: currentRewatch.progress
                    )
                    
                    // Add the corrected rewatch
                    currentlyReading.append(correctedRewatch)
                    
                    // Update in Core Data
                    updateCoreDataForItem(correctedRewatch)
                }
            }
        }
    }
    
    // Helper to determine the total episodes for a series
    func totalEpisodesFor(id: Int, isAnime: Bool) -> Int {
        // Try to get total episodes from any existing item
        let possibleItems = isAnime ?
            (rankedAnime + currentlyWatching + completedRewatchesAnime) :
            (rankedManga + currentlyReading + completedRewatchesManga)
        
        // Find an item matching the ID
        if let existingItem = possibleItems.first(where: { $0.id == id }) {
            return existingItem.progress > 0 ? existingItem.progress : 0
        }
        
        return 0
    }
}
