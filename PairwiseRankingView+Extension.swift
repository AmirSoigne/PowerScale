// This code should be placed in a separate file named "PairwiseRankingView+Extension.swift"
import SwiftUI

extension PairwiseRankingView {
    // Add this method to handle automatic saving on disappear
    func autosaveRankingSession() {
        // Don't save if we've completed the ranking or if there are no items to rank
        if rankingManager.pairwiseCompleted ||
           rankingManager.pairwiseComparison.isEmpty ||
           rankingManager.currentPairIndex <= 0 {
            return
        }
        
        // Save the session
        print("📊 Auto-saving pairwise ranking session at index \(rankingManager.currentPairIndex)...")
        rankingManager.saveRankingSession()
    }
    
    // Add recovery method in case something goes wrong
    func recoverRankingSessionIfNeeded() {
        // Only attempt recovery if we have a saved session
        if rankingManager.hasSavedRankingSession &&
           rankingManager.savedRankingCategory == category &&
           rankingManager.savedPairwiseComparison.isEmpty &&
           rankingManager.pairwiseComparison.isEmpty {
            
            print("🔄 Attempting to recover pairwise ranking session...")
            
            // Force a reload from UserDefaults
            rankingManager.loadFromPersistentStorage()
            
            // If we successfully recovered the session
            if !rankingManager.savedPairwiseComparison.isEmpty {
                // Restore the active session from the saved one
                rankingManager.activeRankingCategory = rankingManager.savedRankingCategory
                rankingManager.pairwiseComparison = rankingManager.savedPairwiseComparison
                rankingManager.currentPairIndex = rankingManager.savedCurrentPairIndex
                rankingManager.winCounts = rankingManager.savedWinCounts
                rankingManager.isPairwiseRankingActive = true
                rankingManager.pairwiseCompleted = false
                
                // Update our local state
                setPairIndex(rankingManager.currentPairIndex)
                setTotalPairs(rankingManager.pairwiseComparison.count)
                
                print("✅ Successfully recovered session with \(getTotalPairs()) pairs, currently at pair \(getPairIndex())")
            }
        }
    }
}
