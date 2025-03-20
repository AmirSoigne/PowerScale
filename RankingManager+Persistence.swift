import Foundation

// Extension to add enhanced persistence methods
extension RankingManager {
    // Enhanced method to check for saved sessions
    func enhancedCheckForSavedPairwiseSession() {
        // Check if there's a saved pairwise session from UserDefaults
        hasSavedRankingSession = UserDefaults.standard.bool(forKey: PairwiseKeys.hasSavedSession)
        
        if hasSavedRankingSession {
            // Load the basic session info
            savedRankingCategory = UserDefaults.standard.string(forKey: PairwiseKeys.rankingCategory) ?? ""
            savedCurrentPairIndex = UserDefaults.standard.integer(forKey: PairwiseKeys.currentPairIndex)
            
            // Load win counts
            if let data = UserDefaults.standard.data(forKey: PairwiseKeys.winCounts) {
                if let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
                    savedWinCounts = decoded
                }
            }
            
            // Try to load the full session info
            if let session = UserDefaults.standard.getSavedPairwiseSession() {
                print("📊 Found saved pairwise session for \(savedRankingCategory)")
                
                // Log the details for verification
                print("📊 Session details: Category: \(session.category), Current Pair: \(session.currentPairIndex), Total Pairs: \(session.pairwiseItems.count)")
                
                // Restore the session
                activeRankingCategory = session.category
                currentPairIndex = session.currentPairIndex
                winCounts = session.winCounts
                
                // Recreate the pairwise comparison from the saved session
                recreatePairwiseComparison(from: session)
                
                // Verify that the session was restored correctly
                if pairwiseComparison.isEmpty {
                    print("⚠️ Failed to recreate pairwise comparisons from saved session")
                    hasSavedRankingSession = false
                } else {
                    print("✅ Successfully restored pairwise session with \(pairwiseComparison.count) comparisons")
                }
            } else {
                print("⚠️ Failed to load saved pairwise session details")
                hasSavedRankingSession = false
            }
        } else {
            print("ℹ️ No saved pairwise session found")
        }
    }
    
    // Enhanced method to save to persistent storage
    func enhancedSaveToPersistentStorage() {
        // Save basic session information
        UserDefaults.standard.set(hasSavedRankingSession, forKey: PairwiseKeys.hasSavedSession)
        UserDefaults.standard.set(savedRankingCategory, forKey: PairwiseKeys.rankingCategory)
        UserDefaults.standard.set(savedCurrentPairIndex, forKey: PairwiseKeys.currentPairIndex)
        
        // Convert pairwise comparison to a saveable format
        if !savedPairwiseComparison.isEmpty {
            var pairwisePairs = [PairwiseComparisonPair]()
            for (item1, item2) in savedPairwiseComparison {
                pairwisePairs.append(PairwiseComparisonPair(
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
            let sessionInfo = PairwiseSessionInfo(
                category: savedRankingCategory,
                pairwiseItems: pairwisePairs,
                currentPairIndex: savedCurrentPairIndex,
                winCounts: savedWinCounts,
                activeRankingItemIds: Array(activeItemIds)
            )
            
            // Save to UserDefaults
            UserDefaults.standard.saveUserDefaultsPairwiseSession(session: sessionInfo)
            
            // Verify save
            verifySessionSave()
        } else {
            // If there's no comparison data, just save the win counts
            if let data = try? JSONEncoder().encode(savedWinCounts) {
                UserDefaults.standard.set(data, forKey: PairwiseKeys.winCounts)
            }
        }
    }
    
    // Helper to verify session save
    private func verifySessionSave() {
        guard let savedSession = UserDefaults.standard.getSavedPairwiseSession() else {
            print("⚠️ Verification failed: Could not retrieve saved session")
            return
        }
        
        // Check key fields
        if savedSession.category != savedRankingCategory {
            print("⚠️ Verification failed: Category mismatch")
        } else if savedSession.currentPairIndex != savedCurrentPairIndex {
            print("⚠️ Verification failed: Current pair index mismatch")
        } else {
            print("✅ Session save verified successfully")
        }
    }
    
    // If recreatePairwiseComparison is private in another file, either:
    // 1. Make it internal/public in its original declaration
    // 2. Create a new method here with a different name
    // 3. Use a different approach to access the functionality
    
    // For example:
    internal func recreatePairwiseComparison(from session: PairwiseSessionInfo) {
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
} 