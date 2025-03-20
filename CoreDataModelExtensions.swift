import Foundation
import CoreData

// MARK: - AnimeItem Extensions
extension AnimeItem {
    // Convert Core Data AnimeItem to Model Anime
    func toAnime() -> Anime {
           // Print for debugging
           print("Converting AnimeItem to Anime - ID: \(id), Title: \(title ?? "Unknown"), CoverURL: \(coverImageURL ?? "nil")")
           
        return Anime(
            id: Int(id),
            title: AnimeTitle(romaji: title ?? "", english: title, native: nil),
            coverImage: CoverImage(large: coverImageURL ?? ""),
            description: animeDescription,
            episodes: episodes > 0 ? Int(episodes) : nil,
            chapters: nil,
            volumes: nil,
            duration: nil,
            status: status,
            format: nil,
            season: nil,
            seasonYear: nil,
            isAdult: isAdult,
            startDate: nil,
            endDate: nil,
            genres: nil,
            tags: nil,
            averageScore: nil,
            meanScore: nil,
            popularity: nil,
            favourites: nil,
            trending: nil,
            rankings: nil,
            studios: nil,
            producers: nil,
            staff: nil,  // Add this missing parameter
            relations: nil,
            characters: nil,
            externalLinks: nil,
            trailer: nil,
            streamingEpisodes: nil,
            nextAiringEpisode: nil,
            recommendations: nil,
            bannerImage: nil
        )
       }
    
    // Convert Core Data AnimeItem to RankingItem
    func toRankingItem() -> RankingItem {
        // Print for debugging
        print("Converting AnimeItem to RankingItem - ID: \(id), Title: \(title ?? "Unknown"), CoverURL: \(coverImageURL ?? "nil")")
        
        return RankingItem(
            id: Int(self.id),
            title: self.title ?? "Unknown",
            coverImage: self.coverImageURL ?? "",
            status: self.status ?? "Unknown",
            isAnime: self.isAnime,
            rank: Int(self.rank),
            score: Double(self.score),
            startDate: self.startDate,
            endDate: self.endDate,
            isRewatch: self.isRewatch,
            rewatchCount: Int(self.rewatchCount),
            progress: Int(self.progress),
            summary: self.animeDescription,
            genres: self.genres
        )
    }
}
// MARK: - UserProfileData Extensions
extension UserProfileData {
    // Convert Core Data UserProfileData to UserProfile
    func toUserProfile() -> UserProfile {
        var genres: [String] = []
        if let favoriteGenresSet = favoriteGenres as? Set<GenreItem> {
            genres = favoriteGenresSet.compactMap { $0.name }
        }
        
        return UserProfile(
            username: self.username ?? "Anime Fan",
            bio: self.bio ?? "",
            joinDate: self.joinDate ?? Date(),
            favoriteGenres: genres,
            profileImageName: self.profileImageName ?? "person.circle.fill",
            themeColor: self.themeColor ?? "blue",
            hasCustomImage: self.hasCustomImage
        )
    }
}

// MARK: - RankingItem Extension
extension RankingItem {
    func toAnimeItem(context: NSManagedObjectContext) -> AnimeItem {
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(self.id))
        
        do {
            // Check if this item already exists in Core Data
            let existingItems = try context.fetch(fetchRequest)
            if let existingItem = existingItems.first {
                // Update existing item
                existingItem.title = self.title
                existingItem.coverImageURL = self.coverImage
                existingItem.animeDescription = "" // Use empty string or a default description
                existingItem.status = self.status
                existingItem.isAnime = self.isAnime
                existingItem.rank = Int16(self.rank)
                existingItem.score = Int16(self.score)
                return existingItem
            } else {
                // Create new item
                let animeItem = AnimeItem(context: context)
                animeItem.id = Int64(self.id)
                animeItem.title = self.title
                animeItem.coverImageURL = self.coverImage
                animeItem.animeDescription = "" // Use empty string or a default description
                animeItem.status = self.status
                animeItem.isAnime = self.isAnime
                animeItem.rank = Int16(self.rank)
                animeItem.score = Int16(self.score)
                animeItem.isAdult = false // Default value
                animeItem.episodes = 0 // Default value
                animeItem.genres = self.genres
                return animeItem
            }
        } catch {
            print("Error fetching AnimeItem: \(error)")
            // Create new item if fetch fails
            let animeItem = AnimeItem(context: context)
            animeItem.id = Int64(self.id)
            animeItem.title = self.title
            animeItem.coverImageURL = self.coverImage
            animeItem.animeDescription = "" // Use empty string or a default description
            animeItem.status = self.status
            animeItem.isAnime = self.isAnime
            animeItem.rank = Int16(self.rank)
            animeItem.score = Int16(self.score)
            animeItem.isAdult = false // Default value
            animeItem.episodes = 0 // Default value
            return animeItem
        }
    }
}

// MARK: - Anime Extension
extension Anime {
    // Convert API Anime model to RankingItem
    func toRankingItem(status: String, isAnime: Bool) -> RankingItem {
        return RankingItem(
            from: self,
            status: status,
            isAnime: isAnime
        )
    }
}
