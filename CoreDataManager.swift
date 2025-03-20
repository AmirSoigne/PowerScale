import CoreData
import SwiftUI

class CoreDataManager {
    // Singleton instance
    static let shared = CoreDataManager()
    
    // Core Data persistent container
    let container: NSPersistentContainer
    
    // Private initializer for singleton pattern
    private init() {
        container = NSPersistentContainer(name: "PowerScaleModel")
        
        // Get the store URL
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("PowerScaleModel.sqlite")
        
        // Try to remove any existing store
        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("Successfully deleted old store")
            }
        } catch {
            print("Could not delete old store: \(error)")
        }
        
        // Now load the stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Error loading persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure the context for better performance and conflict handling
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // Save Core Data context
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - AnimeItem Methods
    
    func createAnimeItem(from anime: Anime, status: String, isAnime: Bool) -> AnimeItem {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(anime.id))
        
        do {
            let results = try context.fetch(fetchRequest)
            let animeItem: AnimeItem
            
            if let existingItem = results.first {
                animeItem = existingItem
                
                // Print debug info to verify what's potentially changing
                print("⚠️ Updating existing item:")
                print("  ID: \(anime.id)")
                print("  Old title: \(animeItem.title ?? "None")")
                print("  New title: \(anime.title.english ?? anime.title.romaji ?? "Unknown")")
                print("  Old cover: \(animeItem.coverImageURL ?? "None")")
                print("  New cover: \(anime.coverImage.large)")
                
                // Only update status for existing items
                animeItem.status = status
                
                // CRITICAL FIX: DO NOT update title or coverImageURL for existing items!
                // This preserves the original relationship between ID, title, and cover image
                
                // Only update descriptive fields that don't affect identity
                animeItem.animeDescription = anime.description ?? "No description available"
                
                // Don't change rank or score for existing items to preserve user preferences
                // Only update metadata that could change over time
                animeItem.episodes = anime.episodes != nil ? Int16(anime.episodes!) : 0
                animeItem.isAdult = anime.isAdult ?? false
                
                print("✅ Updated item: \(animeItem.id) - \(animeItem.title ?? "Unknown") - Status: \(status)")
            } else {
                // Creating a brand new item
                animeItem = AnimeItem(context: context)
                animeItem.id = Int64(anime.id)
                animeItem.title = anime.title.english ?? anime.title.romaji ?? "Unknown"
                animeItem.coverImageURL = anime.coverImage.large
                animeItem.animeDescription = anime.description ?? "No description available"
                animeItem.status = status
                animeItem.isAnime = isAnime
                animeItem.rank = 0
                animeItem.score = 0
                animeItem.episodes = anime.episodes != nil ? Int16(anime.episodes!) : 0
                animeItem.isAdult = anime.isAdult ?? false
                animeItem.genres = anime.genres
                
                // Set rewatch properties with default values
                animeItem.startDate = Date()
                animeItem.endDate = nil as Date?
                animeItem.isRewatch = false
                animeItem.rewatchCount = 0
                animeItem.progress = 0
                
                print("✅ Created new item: ID=\(anime.id), Title=\(animeItem.title ?? "Unknown"), Cover=\(animeItem.coverImageURL ?? "None")")
            }
            
            saveContext()
            
            // Print debug information
            print("Saved item with coverImageURL: \(animeItem.coverImageURL ?? "nil")")
            
            return animeItem
        } catch {
            print("Error fetching or creating AnimeItem: \(error)")
            
            // Create new item on error
            let animeItem = AnimeItem(context: context)
            animeItem.id = Int64(anime.id)
            animeItem.title = anime.title.english ?? anime.title.romaji ?? "Unknown"
            animeItem.coverImageURL = anime.coverImage.large
            animeItem.animeDescription = anime.description ?? "No description available"
            animeItem.status = status
            animeItem.isAnime = isAnime
            animeItem.rank = 0
            animeItem.score = 0
            animeItem.episodes = anime.episodes != nil ? Int16(anime.episodes!) : 0
            animeItem.isAdult = anime.isAdult ?? false
            
            // Set rewatch properties with default values
            animeItem.startDate = Date()
            animeItem.endDate = nil as Date?
            animeItem.isRewatch = false
            animeItem.rewatchCount = 0
            animeItem.progress = 0
            
            saveContext()
            
            // Print debug information
            print("Created new item with coverImageURL: \(animeItem.coverImageURL ?? "nil")")
            
            return animeItem
        }
    }
    
    // Update an existing anime item
    func updateAnimeItem(_ animeItem: AnimeItem, status: String, rank: Int, score: Int) {
        animeItem.status = status
        animeItem.rank = Int16(rank)
        animeItem.score = Int16(score)
        saveContext()
    }
    
    // Update an anime item with rewatch information
    func updateAnimeItemWithRewatch(_ animeItem: AnimeItem, status: String, rank: Int, score: Int,
                                    startDate: Date?, endDate: Date?, isRewatch: Bool,
                                    rewatchCount: Int, progress: Int) {
        animeItem.status = status
        animeItem.rank = Int16(rank)
        animeItem.score = Int16(score)
        animeItem.startDate = startDate
        animeItem.endDate = endDate
        animeItem.isRewatch = isRewatch
        animeItem.rewatchCount = Int16(rewatchCount)
        animeItem.progress = Int16(progress)
        saveContext()
    }
    
    // Delete an anime item
    func deleteAnimeItem(_ animeItem: AnimeItem) {
        container.viewContext.delete(animeItem)
        saveContext()
    }
    
    // Fetch anime items by status
    func fetchAnimeItems(isAnime: Bool, status: String) -> [AnimeItem] {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAnime == %@ AND status == %@", NSNumber(value: isAnime), status)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AnimeItem.rank, ascending: true)]
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching anime items: \(error)")
            return []
        }
    }
    
    // Fetch anime items by status and rewatch status
    func fetchAnimeItems(isAnime: Bool, status: String, isRewatch: Bool = false) -> [AnimeItem] {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAnime == %@ AND status == %@ AND isRewatch == %@",
                                             NSNumber(value: isAnime), status, NSNumber(value: isRewatch))
        
        // For completed items, sort by rank; for rewatches, sort by rewatchCount
        if isRewatch {
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AnimeItem.rewatchCount, ascending: true)]
        } else {
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AnimeItem.rank, ascending: true)]
        }
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching anime items with rewatch status: \(error)")
            return []
        }
    }
    
    // Fetch all anime items (or manga items) regardless of status
    func fetchAllAnimeItems(isAnime: Bool) -> [AnimeItem] {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAnime == %@", NSNumber(value: isAnime))
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AnimeItem.rank, ascending: true)]
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching all anime items: \(error)")
            return []
        }
    }
    
    // Fetch specific rewatch for an item
    func fetchSpecificRewatch(id: Int64, rewatchCount: Int) -> AnimeItem? {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld AND isRewatch == YES AND rewatchCount == %d",
                                             id, rewatchCount)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching specific rewatch: \(error)")
            return nil
        }
    }
    
    // Fetch all completed rewatches for an item
    func fetchCompletedRewatches(id: Int64, isAnime: Bool) -> [AnimeItem] {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld AND isAnime == %@ AND isRewatch == YES AND status == %@",
                                             id, NSNumber(value: isAnime), "Completed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AnimeItem.rewatchCount, ascending: true)]
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching completed rewatches: \(error)")
            return []
        }
    }
    
    // Count total rewatches for an item
    func countRewatches(id: Int64, isAnime: Bool) -> Int {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld AND isAnime == %@ AND isRewatch == YES",
                                             id, NSNumber(value: isAnime))
        
        do {
            return try container.viewContext.count(for: fetchRequest)
        } catch {
            print("Error counting rewatches: \(error)")
            return 0
        }
    }
    
    // MARK: - UserProfile Methods
    
    // Fetch user profile (creates one if none exists)
    func fetchUserProfile() -> UserProfileData? {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<UserProfileData> = UserProfileData.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            if let existingProfile = profiles.first {
                return existingProfile
            } else {
                // Create in the proper context
                return createDefaultUserProfile()
            }
        } catch {
            print("Error fetching user profile: \(error)")
            return createDefaultUserProfile()
        }
    }

    // Create default user profile
    func createDefaultUserProfile() -> UserProfileData {
        let context = container.viewContext
        let profile = UserProfileData(context: context)
        profile.username = "Anime Fan"
        profile.bio = "I love watching anime and reading manga!"
        profile.joinDate = Date()
        profile.profileImageName = "person.circle.fill"
        profile.themeColor = "blue"
        profile.hasCustomImage = false
        
        // Add default favorite genres
        addGenreToProfile(profile, genreName: "Action")
        addGenreToProfile(profile, genreName: "Adventure")
        
        do {
            try context.save()
            return profile
        } catch {
            print("Error creating default profile: \(error)")
            // If we can't save, at least return the unsaved profile object
            return profile
        }
    }
    
    // Update user profile
    func updateUserProfile(_ profile: UserProfileData, username: String, bio: String, themeColor: String) {
        profile.username = username
        profile.bio = bio
        profile.themeColor = themeColor
        saveContext()
    }
    
    // Set custom image flag
    func setCustomImage(_ profile: UserProfileData, hasCustomImage: Bool) {
        profile.hasCustomImage = hasCustomImage
        saveContext()
    }
    
    // MARK: - Genre Methods
    
    // Add a genre to user profile
    func addGenreToProfile(_ profile: UserProfileData, genreName: String) {
        let context = container.viewContext
        let genre = GenreItem(context: context)
        genre.name = genreName
        genre.profile = profile
        saveContext()
    }
    
    // Remove all genres from profile
    func removeAllGenresFromProfile(_ profile: UserProfileData) {
        guard let genres = profile.favoriteGenres as? Set<GenreItem> else { return }
        
        for genre in genres {
            container.viewContext.delete(genre)
        }
        
        saveContext()
    }
     
    // Update profile genres
    func updateProfileGenres(_ profile: UserProfileData, with genreNames: [String]) {
        // Remove all existing genres
        removeAllGenresFromProfile(profile)
        
        // Add new genres
        for genreName in genreNames {
            addGenreToProfile(profile, genreName: genreName)
        }
    }
    
    // MARK: - Database Maintenance Methods
    
    // Function to completely reset all anime/manga data
    func resetAllData() {
        let context = container.viewContext
        
        // Fetch all AnimeItems
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            
            // Delete all items
            for item in results {
                context.delete(item)
            }
            
            // Save changes
            saveContext()
            print("✅ Successfully reset all anime/manga data")
        } catch {
            print("❌ Error resetting data: \(error)")
        }
    }
    
    // Function to ensure correct cover images for each anime by ID
    func updateCoverImagesFromAPI() {
        let context = container.viewContext
        
        // Fetch all AnimeItems
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            
            let group = DispatchGroup()
            
            // Process each item to update its cover image from the API
            for item in results {
                group.enter()
                
                // Determine if it's anime or manga for the correct API call
                if item.isAnime {
                    AniListAPI.shared.getAnimeDetails(id: Int(item.id)) { anime in
                        if let anime = anime {
                            // Update with fresh data from API
                            DispatchQueue.main.async {
                                item.coverImageURL = anime.coverImage.large
                                item.title = anime.title.english ?? anime.title.romaji ?? item.title
                                print("✅ Updated anime cover: ID \(item.id) - \(item.title ?? "Unknown") - \(item.coverImageURL ?? "No URL")")
                                group.leave()
                            }
                        } else {
                            print("❌ Failed to get anime details for ID: \(item.id)")
                            group.leave()
                        }
                    }
                } else {
                    // For manga (we'll just use anime API for simplicity in this example)
                    AniListAPI.shared.getAnimeDetails(id: Int(item.id)) { anime in
                        if let anime = anime {
                            // Update with fresh data from API
                            DispatchQueue.main.async {
                                item.coverImageURL = anime.coverImage.large
                                item.title = anime.title.english ?? anime.title.romaji ?? item.title
                                print("✅ Updated manga cover: ID \(item.id) - \(item.title ?? "Unknown") - \(item.coverImageURL ?? "No URL")")
                                group.leave()
                            }
                        } else {
                            print("❌ Failed to get manga details for ID: \(item.id)")
                            group.leave()
                        }
                    }
                }
            }
            
            // When all updates are done, save context
            group.notify(queue: .main) {
                self.saveContext()
                print("✅ All cover images updated successfully")
            }
        } catch {
            print("❌ Error fetching items to update covers: \(error)")
        }
    }
}
