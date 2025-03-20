import SwiftUI
import CoreData

@main
struct PowerScaleApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showLoadingScreen = true
    
    // Initialize Core Data first before anything else can use it
    let coreDataManager = CoreDataManager.shared
    
    // Use UIApplicationDelegateAdaptor to connect AppDelegate
    @UIApplicationDelegateAdaptor(PowerScaleAppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if !hasLaunchedBefore || showLoadingScreen {
                LoadingScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showLoadingScreen = false
                            hasLaunchedBefore = true
                        }
                    }
                    // Also add the environment here
                    .environment(\.managedObjectContext, coreDataManager.container.viewContext)
            } else {
                MainView()
                    .environment(\.managedObjectContext, coreDataManager.container.viewContext)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                print("📱 App becoming inactive - saving state")
            } else if newPhase == .background {
                print("📱 App entering background - forcing save")
                saveAllDataBeforeBackground()
            } else if newPhase == .active {
                print("📱 App becoming active - checking data")
            }
        }
    }
    
    func saveAllDataBeforeBackground() {
        // Create a semaphore to make the save synchronous
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Save ranking state to UserDefaults
            if RankingManager.shared.isPairwiseRankingActive {
                UserDefaults.standard.set(true, forKey: PairwiseKeys.hasSavedSession)
                UserDefaults.standard.set(
                    RankingManager.shared.activeRankingCategory, 
                    forKey: PairwiseKeys.rankingCategory
                )
                UserDefaults.standard.set(
                    RankingManager.shared.currentPairIndex, 
                    forKey: PairwiseKeys.currentPairIndex
                )
                
                if let encoded = try? JSONEncoder().encode(RankingManager.shared.winCounts) {
                    UserDefaults.standard.set(encoded, forKey: PairwiseKeys.winCounts)
                }
            }
            
            // Force save all ranking data
            RankingManager.shared.persistRankingResults()
            
            // Force CoreData to save
            let context = CoreDataManager.shared.container.viewContext
            
            if context.hasChanges {
                do {
                    try context.save()
                    print("✅ Successfully saved Core Data before app backgrounded")
                } catch {
                    print("❌ Error saving Core Data before backgrounding: \(error)")
                }
            }
            
            // Signal completion
            semaphore.signal()
        }
        
        // Wait for the save to complete (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
    }
}
