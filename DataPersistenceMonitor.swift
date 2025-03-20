import UIKit
import Foundation
import Combine

// Monitor for data consistency issues
class DataPersistenceMonitor: ObservableObject {
    @Published var hasInconsistentData = false
    @Published var lastSaveTimestamp: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Monitor for changes
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.saveAppState()
            }
            .store(in: &cancellables)
    }
    
    func saveAppState() {
        // Save current state
        if RankingManager.shared.isPairwiseRankingActive {
            UserDefaults.standard.set(true, forKey: "hasSavedRankingSession")
            UserDefaults.standard.set(
                RankingManager.shared.activeRankingCategory, 
                forKey: "savedRankingCategory"
            )
            UserDefaults.standard.set(
                RankingManager.shared.currentPairIndex, 
                forKey: "savedCurrentPairIndex"
            )
            
            if let encoded = try? JSONEncoder().encode(RankingManager.shared.winCounts) {
                UserDefaults.standard.set(encoded, forKey: "savedWinCounts")
            }
        }
        
        // Also check if any CoreData changes need saving
        let context = CoreDataManager.shared.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData state saved during app state change")
            } catch {
                print("❌ Failed to save CoreData during app state change: \(error)")
            }
        }
        
        lastSaveTimestamp = Date()
    }
    
    func verifyDataConsistency() {
        // Check for inconsistencies between CoreData and UserDefaults
        var inconsistencyFound = false
        
        // Check anime rankings
        if let data = UserDefaults.standard.data(forKey: "animeRankingsData"),
           let animeFromUserDefaults = try? JSONDecoder().decode([RankingItem].self, from: data) {
            
            let coreDataAnime = RankingManager.shared.rankedAnime
            
            if coreDataAnime.count != animeFromUserDefaults.count {
                print("⚠️ Data inconsistency: CoreData anime count (\(coreDataAnime.count)) != UserDefaults anime count (\(animeFromUserDefaults.count))")
                inconsistencyFound = true
            }
        }
        
        // Similar check for manga rankings
        if let data = UserDefaults.standard.data(forKey: "mangaRankingsData"),
           let mangaFromUserDefaults = try? JSONDecoder().decode([RankingItem].self, from: data) {
            
            let coreDataManga = RankingManager.shared.rankedManga
            
            if coreDataManga.count != mangaFromUserDefaults.count {
                print("⚠️ Data inconsistency: CoreData manga count (\(coreDataManga.count)) != UserDefaults manga count (\(mangaFromUserDefaults.count))")
                inconsistencyFound = true
            }
        }
        
        // Update the published property
        hasInconsistentData = inconsistencyFound
        
        if inconsistencyFound {
            print("⚠️ Data inconsistencies detected - recovery may be needed")
        } else {
            print("✅ Data consistency verified successfully")
        }
    }
} 