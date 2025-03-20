//
//  PairwiseRankingCoordinator.swift
//  PowerScale
//
//  Created by Khalil White on 3/20/25.
//

import Foundation
import CoreData

class PairwiseRankingCoordinator {
    static let shared = PairwiseRankingCoordinator()
    
    private var isProcessing = false
    private var queue: [(RankingItem, RankingItem, (Bool) -> Void)] = []
    
    func recordPairwiseResult(winner: RankingItem, loser: RankingItem, completion: @escaping (Bool) -> Void) {
        queue.append((winner, loser, completion))
        processNextInQueue()
    }
    
    private func processNextInQueue() {
        guard !isProcessing, !queue.isEmpty else { return }
        
        isProcessing = true
        let (winner, loser, completion) = queue.removeFirst()
        
        // Update win counts in memory
        RankingManager.shared.winCounts[winner.id] = (RankingManager.shared.winCounts[winner.id] ?? 0) + 1
        RankingManager.shared.currentPairIndex += 1
        
        // Save the current state to UserDefaults
        saveCurrentSessionState()
        
        // Verify save was successful
        verifyPairwiseSessionSave()
        
        // Simulate some processing time to avoid rate limiting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion(true)
            self.isProcessing = false
            self.processNextInQueue()
        }
    }
    
    internal func saveCurrentSessionState() {
        let rm = RankingManager.shared
        
        // 1. Save the basic session info
        UserDefaults.standard.set(true, forKey: PairwiseKeys.hasSavedSession)
        UserDefaults.standard.set(rm.activeRankingCategory, forKey: PairwiseKeys.rankingCategory)
        UserDefaults.standard.set(rm.currentPairIndex, forKey: PairwiseKeys.currentPairIndex)
        
        // 2. Save win counts
        if let encoded = try? JSONEncoder().encode(rm.winCounts) {
            UserDefaults.standard.set(encoded, forKey: PairwiseKeys.winCounts)
        }
        
        // 3. Save the actual items being compared
        saveActiveItems()
        
        // 4. Save the pairwise comparison items
        savePairwiseItems()
        
        print("💾 Saved pairwise session state - Category: \(rm.activeRankingCategory), Pair: \(rm.currentPairIndex)")
    }
    
    private func saveActiveItems() {
        let rm = RankingManager.shared
        
        // Determine which items are being actively ranked
        var activeItemIds: [Int] = []
        
        if rm.activeRankingCategory == "Anime" {
            activeItemIds = rm.rankedAnime.map { $0.id }
        } else if rm.activeRankingCategory == "Manga" {
            activeItemIds = rm.rankedManga.map { $0.id }
        } else if rm.activeRankingCategory == "Characters" {
            // Extract character IDs from all pairwise comparisons
            let allItems = rm.pairwiseComparison.flatMap { [$0.0, $0.1] }
            activeItemIds = Array(Set(allItems.map { $0.id }))
        }
        
        // Save these IDs to UserDefaults
        UserDefaults.standard.set(activeItemIds, forKey: PairwiseKeys.activeRankingItems)
    }
    
    private func savePairwiseItems() {
        let rm = RankingManager.shared
        
        // Create simplified version of comparison pairs (just IDs)
        var pairItems: [PairwiseComparisonPair] = []
        
        for (item1, item2) in rm.pairwiseComparison {
            let pair = PairwiseComparisonPair(
                firstItemId: item1.id,
                secondItemId: item2.id
            )
            pairItems.append(pair)
        }
        
        // Extract active item IDs
        let activeItemIds = UserDefaults.standard.array(forKey: PairwiseKeys.activeRankingItems) as? [Int] ?? []
        
        // Create the session info
        let sessionInfo = PairwiseSessionInfo(
            category: rm.activeRankingCategory,
            pairwiseItems: pairItems,
            currentPairIndex: rm.currentPairIndex,
            winCounts: rm.winCounts,
            activeRankingItemIds: activeItemIds
        )
        
        // Save the session info with the updated method signature
        UserDefaults.standard.saveUserDefaultsPairwiseSession(session: sessionInfo)
    }
    
    private func verifyPairwiseSessionSave() {
        // Check if the session was properly saved
        let hasSavedSession = UserDefaults.standard.bool(forKey: PairwiseKeys.hasSavedSession)
        let savedCategory = UserDefaults.standard.string(forKey: PairwiseKeys.rankingCategory) ?? ""
        let savedIndex = UserDefaults.standard.integer(forKey: PairwiseKeys.currentPairIndex)
        
        let rm = RankingManager.shared
        
        // Verify saved state matches actual state
        if !hasSavedSession || savedCategory != rm.activeRankingCategory || savedIndex != rm.currentPairIndex {
            print("⚠️ Session save verification failed. Retrying save...")
            saveCurrentSessionState() // Retry the save
        } else {
            print("✅ Session save verified successfully")
        }
    }
}

