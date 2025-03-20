import UIKit

class PowerScaleAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Run silent image fix on app startup
        DispatchQueue.global(qos: .utility).async {
            self.fixAnimeImages()
        }
        
        return true
    }
    
    // Silent fix function that verifies and corrects image URLs
    private func fixAnimeImages() {
        print("💡 Checking anime cover images for consistency...")
        
        // Get all anime items from Core Data
        let allItems = CoreDataManager.shared.fetchAllAnimeItems(isAnime: true) +
                      CoreDataManager.shared.fetchAllAnimeItems(isAnime: false)
        
        if allItems.isEmpty {
            print("✅ No items to check.")
            return
        }
        
        print("🔍 Found \(allItems.count) items to verify")
        
        // Process items in batches to avoid overloading the network
        let batchSize = 5
        let batches = stride(from: 0, to: allItems.count, by: batchSize).map {
            Array(allItems[$0..<min($0 + batchSize, allItems.count)])
        }
        
        let dispatchGroup = DispatchGroup()
        var fixCount = 0
        
        for (batchIndex, batch) in batches.enumerated() {
            // Add slight delay between batches to be nice to the API
            if batchIndex > 0 {
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            for item in batch {
                dispatchGroup.enter()
                
                // Check if this is anime or manga and call appropriate API
                if item.isAnime {
                    AniListAPI.shared.getAnimeDetails(id: Int(item.id)) { anime in
                        if let anime = anime {
                            let correctCoverURL = anime.coverImage.large
                            if item.coverImageURL != correctCoverURL {
                                // Image URL mismatch found - fix it
                                DispatchQueue.main.async {
                                    print("🛠️ Fixing anime ID \(item.id): \(item.title ?? "Unknown")")
                                    item.coverImageURL = correctCoverURL
                                    fixCount += 1
                                    dispatchGroup.leave()
                                }
                            } else {
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    // For manga - using anime API for simplicity
                    AniListAPI.shared.getAnimeDetails(id: Int(item.id)) { anime in
                        if let anime = anime {
                            let correctCoverURL = anime.coverImage.large
                            if item.coverImageURL != correctCoverURL {
                                // Image URL mismatch found - fix it
                                DispatchQueue.main.async {
                                    print("🛠️ Fixing manga ID \(item.id): \(item.title ?? "Unknown")")
                                    item.coverImageURL = correctCoverURL
                                    fixCount += 1
                                    dispatchGroup.leave()
                                }
                            } else {
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        // When all checks are done, save changes
        dispatchGroup.notify(queue: .main) {
            if fixCount > 0 {
                CoreDataManager.shared.saveContext()
                print("✅ Fixed \(fixCount) image mismatches")
            } else {
                print("✅ All items have correct cover images")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session
    }
}
