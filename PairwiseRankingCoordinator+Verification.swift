import Foundation

// Extension to add verification methods to the existing class
extension PairwiseRankingCoordinator {
    // Move the verification method here to avoid duplication
    func verifySessionSave() {
        // Check if the session was properly saved
        let hasSavedSession = UserDefaults.standard.bool(forKey: PairwiseKeys.hasSavedSession)
        let savedCategory = UserDefaults.standard.string(forKey: PairwiseKeys.rankingCategory) ?? ""
        let savedIndex = UserDefaults.standard.integer(forKey: PairwiseKeys.currentPairIndex)
        
        let rm = RankingManager.shared
        
        // Verify saved state matches actual state
        if !hasSavedSession || savedCategory != rm.activeRankingCategory || savedIndex != rm.currentPairIndex {
            print("⚠️ Session save verification failed. Retrying save...")
            // Instead of calling the private method directly, call a public method
            saveSessionState() // Call a public method that we'll define below
        } else {
            print("✅ Session save verified successfully")
        }
    }
    
    // Add a public method to save session state
    func saveSessionState() {
        // This is a public wrapper around the private method
        let rm = RankingManager.shared
        
        // 1. Save the basic session info
        UserDefaults.standard.set(true, forKey: PairwiseKeys.hasSavedSession)
        UserDefaults.standard.set(rm.activeRankingCategory, forKey: PairwiseKeys.rankingCategory)
        UserDefaults.standard.set(rm.currentPairIndex, forKey: PairwiseKeys.currentPairIndex)
        
        // 2. Save win counts
        if let encoded = try? JSONEncoder().encode(rm.winCounts) {
            UserDefaults.standard.set(encoded, forKey: PairwiseKeys.winCounts)
        }
        
        // 3. Save the actual items being compared and pairwise items
        // We'll need to duplicate some logic from the private methods
        // or make those methods internal instead of private
        
        // Create simplified version of comparison pairs (just IDs)
        var pairItems: [PairwiseComparisonPair] = []
        
        for (item1, item2) in rm.pairwiseComparison {
            let pair = PairwiseComparisonPair(
                firstItemId: item1.id,
                secondItemId: item2.id
            )
            pairItems.append(pair)
        }
        
        // Get IDs of all items involved in the ranking
        var activeItemIds = Set<Int>()
        for (item1, item2) in rm.pairwiseComparison {
            activeItemIds.insert(item1.id)
            activeItemIds.insert(item2.id)
        }
        
        // Save these IDs to UserDefaults
        UserDefaults.standard.set(Array(activeItemIds), forKey: PairwiseKeys.activeRankingItems)
        
        // Create the session info
        let sessionInfo = PairwiseSessionInfo(
            category: rm.activeRankingCategory,
            pairwiseItems: pairItems,
            currentPairIndex: rm.currentPairIndex,
            winCounts: rm.winCounts,
            activeRankingItemIds: Array(activeItemIds)
        )
        
        // Save to UserDefaults
        UserDefaults.standard.saveUserDefaultsPairwiseSession(session: sessionInfo)
        
        print("💾 Saved pairwise session state - Category: \(rm.activeRankingCategory), Pair: \(rm.currentPairIndex)")
    }
    
    // Enhance the existing method with verification
    func enhancedSaveCurrentSessionState() {
        // Call our public method
        saveSessionState()
        
        // Then verify the save
        verifySessionSave()
    }
} 