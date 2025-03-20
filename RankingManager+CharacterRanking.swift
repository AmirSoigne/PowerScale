import Foundation

extension RankingManager {
    // MARK: - Character Ranking Methods
    
    // Process character ranking results
    func processCharacterRankingResults(favoriteIds: [Int]) -> [Int] {
        // Sort the character IDs based on win counts
        var sortedCharacterIds = favoriteIds.sorted { (a, b) -> Bool in
            let aWins = winCounts[a] ?? 0
            let bWins = winCounts[b] ?? 0
            return aWins > bWins // Higher win count means better rank
        }
        
        print("🎭 CHARACTER RANKING RESULTS:")
        for (index, id) in sortedCharacterIds.enumerated() {
            print("Rank \(index+1): Character ID=\(id), Wins=\(winCounts[id] ?? 0)")
        }
        
        return sortedCharacterIds
    }
    
    // Save character ranking order to UserDefaults
    func saveCharacterRankingOrder(_ characterIds: [Int]) {
        do {
            let data = try JSONEncoder().encode(characterIds)
            UserDefaults.standard.set(data, forKey: "favoriteCharacters")
            
            // Post notification that character order has changed
            NotificationCenter.default.post(name: Notification.Name("CharacterOrderChanged"), object: nil)
            
            print("✅ Saved character ranking order to UserDefaults")
        } catch {
            print("❌ Error saving character ranking order: \(error)")
        }
    }
    
    // Set up character ranking
    func setupCharacterRanking(characters: [Int]) {
        // Clear previous win counts
        winCounts.removeAll()
        
        // Set the active category
        activeRankingCategory = "Characters"
        isPairwiseRankingActive = true
        pairwiseCompleted = false
        currentPairIndex = 0
        
        // Create temporary RankingItems for the characters
        var characterItems: [RankingItem] = []
        
        // Process characters in batches of 10
        let batchSize = 10
        let characterBatches = stride(from: 0, to: characters.count, by: batchSize).map {
            Array(characters[$0..<min($0 + batchSize, characters.count)])
        }
        
        // Process each batch sequentially
        processNextBatch(batches: characterBatches, currentIndex: 0, characterItems: characterItems)
    }
    
    private func processNextBatch(batches: [[Int]], currentIndex: Int, characterItems: [RankingItem]) {
        guard currentIndex < batches.count else {
            // All batches processed, generate pairs
            self.pairwiseComparison = self.generateOptimizedPairs(from: characterItems)
            print("✅ Generated \(self.pairwiseComparison.count) character comparison pairs")
            return
        }
        
        let batch = batches[currentIndex]
        let group = DispatchGroup()
        var batchItems: [RankingItem] = []
        
        for characterId in batch {
            group.enter()
            
            APIRateLimiter.shared.executeRequest {
                AniListAPI.shared.getCharacterDetails(id: characterId) { character in
                    if let character = character {
                        // Create a temporary RankingItem for the character
                        let item = RankingItem(
                            id: character.id,
                            title: character.name.full,
                            coverImage: character.image?.medium ?? "",
                            status: "Favorite",
                            isAnime: false,
                            rank: 0,
                            score: 0,
                            startDate: nil,
                            endDate: nil,
                            isRewatch: false,
                            rewatchCount: 0,
                            progress: 0,
                            summary: character.description,
                            genres: nil
                        )
                        
                        batchItems.append(item)
                    }
                    
                    group.leave()
                }
            }
        }
        
        // When batch is complete, process next batch
        group.notify(queue: .main) {
            let allItems = characterItems + batchItems
            // Wait a short while before starting the next batch to avoid rate limiting
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processNextBatch(batches: batches, currentIndex: currentIndex + 1, characterItems: allItems)
            }
        }
    }
    
    // Helper method to generate optimized pairs
    private func generateOptimizedPairs(from items: [RankingItem]) -> [(RankingItem, RankingItem)] {
        // If we have fewer than 2 items, no pairs to compare
        if items.count < 2 {
            return []
        }
        
        // Start with a shuffled copy of the items to ensure random initial order
        var itemsCopy = items.shuffled()
        
        // Initial sorted subarrays of size 1
        var sortedSubarrays: [[RankingItem]] = itemsCopy.map { [$0] }
        var pairs: [(RankingItem, RankingItem)] = []
        
        // Merge sorted subarrays until only one remains
        while sortedSubarrays.count > 1 {
            var newSortedSubarrays: [[RankingItem]] = []
            
            // Process pairs of sorted subarrays
            for i in stride(from: 0, to: sortedSubarrays.count - 1, by: 2) {
                // Generate pairs from the two sorted subarrays
                let newPairs = generateMergePairs(sortedSubarrays[i], sortedSubarrays[i + 1])
                pairs.append(contentsOf: newPairs.0)
                newSortedSubarrays.append(newPairs.1)
            }
            
            // Handle the case where we have an odd number of sorted subarrays
            if sortedSubarrays.count % 2 == 1 {
                newSortedSubarrays.append(sortedSubarrays.last!)
            }
            
            sortedSubarrays = newSortedSubarrays
        }
        
        return pairs
    }
    
    // Helper method to generate pairs for merging two sorted subarrays
    private func generateMergePairs(_ left: [RankingItem], _ right: [RankingItem]) -> ([(RankingItem, RankingItem)], [RankingItem]) {
        var pairs: [(RankingItem, RankingItem)] = []
        var mergedArray: [RankingItem] = []
        
        var i = 0, j = 0
        
        while i < left.count && j < right.count {
            // Create pair for comparison - this is what the user will see
            pairs.append((left[i], right[j]))
            
            // For the sake of generating remaining pairs, we'll assume left wins
            // The actual winner will be determined by user input
            mergedArray.append(left[i])
            i += 1
            
            // If we've processed all left items but still have right items
            if i == left.count && j < right.count {
                // Add all remaining right items
                mergedArray.append(contentsOf: right[j..<right.count])
                break
            }
            
            // If we've processed all right items but still have left items
            if j == right.count && i < left.count {
                // Add all remaining left items
                mergedArray.append(contentsOf: left[i..<left.count])
                break
            }
        }
        
        return (pairs, mergedArray)
    }
}
