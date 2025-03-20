import Foundation
import SwiftUI  // Added for IndexSet

extension RankingManager {
    // MARK: - Pairwise Ranking Methods
    
    // Move an item in the ranking order (existing functionality)
    func moveItem(from source: IndexSet, to destination: Int, in category: String) {
        // Create a mutable copy of the items to reorder
        var itemsToReorder: [RankingItem] = []
        if category == "Anime" {
            itemsToReorder = rankedAnime + currentlyWatching + onHoldAnime + lostInterestAnime
        } else {
            itemsToReorder = rankedManga + currentlyReading + onHoldManga + lostInterestManga
        }
        
        // Sort them by current rank first to ensure consistent ordering
        itemsToReorder.sort { $0.rank < $1.rank }
        
        // Perform the move operation
        itemsToReorder.move(fromOffsets: source, toOffset: destination)
        
        // Update ranks based on new positions
        for (index, item) in itemsToReorder.enumerated() {
            let newRank = index + 1
            
            // Only update if the rank has changed
            if item.rank != newRank {
                // Create updated item with new rank (preserving existing Elo rating)
                let updatedItem = RankingItem(
                    id: item.id,
                    title: item.title,
                    coverImage: item.coverImage,
                    status: item.status,
                    isAnime: item.isAnime,
                    rank: newRank,
                    score: item.score,
                    startDate: item.startDate,
                    endDate: item.endDate,
                    isRewatch: item.isRewatch,
                    rewatchCount: item.rewatchCount,
                    progress: item.progress,
                    summary: item.summary,
                    genres: item.genres,
                    eloRating: item.eloRating
                )
                
                // Update in the appropriate list
                if item.isAnime {
                    switch item.status {
                    case "Completed":
                        if let index = rankedAnime.firstIndex(where: { $0.id == item.id }) {
                            rankedAnime[index] = updatedItem
                        }
                    case "Currently Watching":
                        if let index = currentlyWatching.firstIndex(where: {
                            $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount
                        }) {
                            currentlyWatching[index] = updatedItem
                        }
                    case "On Hold":
                        if let index = onHoldAnime.firstIndex(where: { $0.id == item.id }) {
                            onHoldAnime[index] = updatedItem
                        }
                    case "Lost Interest":
                        if let index = lostInterestAnime.firstIndex(where: { $0.id == item.id }) {
                            lostInterestAnime[index] = updatedItem
                        }
                    default:
                        break
                    }
                } else {
                    // Similar updates for manga lists
                    switch item.status {
                    case "Completed":
                        if let index = rankedManga.firstIndex(where: { $0.id == item.id }) {
                            rankedManga[index] = updatedItem
                        }
                    case "Currently Reading":
                        if let index = currentlyReading.firstIndex(where: {
                            $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount
                        }) {
                            currentlyReading[index] = updatedItem
                        }
                    case "On Hold":
                        if let index = onHoldManga.firstIndex(where: { $0.id == item.id }) {
                            onHoldManga[index] = updatedItem
                        }
                    case "Lost Interest":
                        if let index = lostInterestManga.firstIndex(where: { $0.id == item.id }) {
                            lostInterestManga[index] = updatedItem
                        }
                    default:
                        break
                    }
                }
                
                // Update in Core Data using the new helper method
                saveLibraryChange(for: updatedItem)
            }
        }
        
        // Force a UI refresh
        objectWillChange.send()
    }
    
    // MARK: - Elo Rating Methods
    /// Updates the Elo ratings for the winner and loser using the standard Elo formula.
    /// - Parameters:
    ///   - winner: The RankingItem that won (passed as inout).
    ///   - loser: The RankingItem that lost (passed as inout).
    ///   - K: The K-factor used for adjustment (default 32).
    func updateEloRatings(winner: inout RankingItem, loser: inout RankingItem, K: Double = 32) {
        let expectedWinner = 1.0 / (1.0 + pow(10, (loser.eloRating - winner.eloRating) / 400))
        let expectedLoser = 1.0 / (1.0 + pow(10, (winner.eloRating - loser.eloRating) / 400))
        winner.eloRating += K * (1 - expectedWinner)
        loser.eloRating += K * (0 - expectedLoser)
    }
    
    // MARK: - Record Pairwise Result with Elo Integration
    /// Records a pairwise result by updating win counts and Elo ratings, then updating the lists and Core Data.
    /// - Parameters:
    ///   - winner: The item that won the comparison.
    ///   - loser: The item that lost the comparison.
    func recordPairwiseResult(winner: RankingItem, loser: RankingItem) {
        // Increase win count (existing logic)
        self.winCounts[winner.id] = (self.winCounts[winner.id] ?? 0) + 1
        
        // Create mutable copies to update Elo ratings
        var updatedWinner = winner
        var updatedLoser = loser
        updateEloRatings(winner: &updatedWinner, loser: &updatedLoser)
        
        // Update items in their lists and persist to Core Data
        updateItemInList(updatedWinner)
        updateItemInList(updatedLoser)
        
        // Increment the current pair index
        self.currentPairIndex += 1
        
        // Check if the ranking session is complete
        if self.currentPairIndex >= self.pairwiseComparison.count {
            self.pairwiseCompleted = true
            // Optionally sort ranked lists by Elo rating for display
            sortItemsByEloRating()
        }
    }
    
    /// Searches for the item in the lists and updates it, then persists to Core Data.
    /// - Parameter item: The updated RankingItem.
    private func updateItemInList(_ item: RankingItem) {
        if item.isAnime {
            switch item.status {
            case "Completed":
                if let index = rankedAnime.firstIndex(where: { $0.id == item.id }) {
                    rankedAnime[index] = item
                }
            case "Currently Watching":
                if let index = currentlyWatching.firstIndex(where: { $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount }) {
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
            default:
                break
            }
        } else {
            switch item.status {
            case "Completed":
                if let index = rankedManga.firstIndex(where: { $0.id == item.id }) {
                    rankedManga[index] = item
                }
            case "Currently Reading":
                if let index = currentlyReading.firstIndex(where: { $0.id == item.id && $0.isRewatch == item.isRewatch && $0.rewatchCount == item.rewatchCount }) {
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
            default:
                break
            }
        }
        // Use the new helper method to save changes to Core Data
        saveLibraryChange(for: item)
    }
    
    /// Sorts the ranked anime and manga lists in descending order based on the Elo rating.
    private func sortItemsByEloRating() {
        rankedAnime.sort { $0.eloRating > $1.eloRating }
        rankedManga.sort { $0.eloRating > $1.eloRating }
    }
} 
