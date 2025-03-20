import Foundation
import SwiftUI
import CoreData

struct UserProfile: Identifiable {
    var id = UUID()
    var username: String
    var bio: String
    var joinDate: Date
    var favoriteGenres: [String]
    var profileImageName: String
    var themeColor: String
    
    // Selected custom image (will be stored separately)
    var hasCustomImage: Bool = false
    
    // Statistics (these will be computed based on user's lists)
    var animeCount: Int {
        // This would be implemented to count items across all anime lists
        return 0
    }
    
    var mangaCount: Int {
        // This would be implemented to count items across all manga lists
        return 0
    }
    
    var totalHoursWatched: Double {
        // This would calculate total hours based on completed anime
        return 0.0
    }
    
    // Default profile with placeholder values
    static let defaultProfile = UserProfile(
        username: "Anime Fan",
        bio: "I love watching anime and reading manga!",
        joinDate: Date(),
        favoriteGenres: ["Action", "Adventure"],
        profileImageName: "person.circle.fill",
        themeColor: "blue"
    )
    
    // Available theme colors
    static let availableThemes = [
        "blue": Color.blue,
        "purple": Color.purple,
        "pink": Color.pink,
        "red": Color.red,
        "orange": Color.orange,
        "green": Color.green,
        "teal": Color.teal,
        "gray": Color.gray
    ]
    
    // Available genres for selection
    static let availableGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy",
        "Horror", "Mystery", "Romance", "Sci-Fi", "Slice of Life",
        "Sports", "Supernatural", "Thriller", "Isekai", "Mecha"
    ]
    
    // Get the Color object for the current theme
    func getThemeColor() -> Color {
        return UserProfile.availableThemes[themeColor] ?? .blue
    }
}

// ProfileManager to handle saving and loading profile data
class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile
    
    
    
    
    // Singleton instance
    static let shared = ProfileManager()
    
    // Core Data manager reference
    private let coreDataManager = CoreDataManager.shared
    
    // Private initializer for singleton
    // Update this method in your ProfileManager class in UserProfile.swift

    private init() {
        // Always start with default profile
        self.currentProfile = UserProfile.defaultProfile
        
        // Delay Core Data access to ensure stack is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let profileData = self.coreDataManager.fetchUserProfile() {
                DispatchQueue.main.async {
                    self.currentProfile = profileData.toUserProfile()
                    self.objectWillChange.send()
                }
            }
        }
    }
    // Update and save profile
    func updateProfile(username: String, bio: String, favoriteGenres: [String], themeColor: String) {
        // Update in-memory profile
        currentProfile.username = username
        currentProfile.bio = bio
        currentProfile.favoriteGenres = favoriteGenres
        currentProfile.themeColor = themeColor
        
        // Update in Core Data
        if let profileData = coreDataManager.fetchUserProfile() {
            coreDataManager.updateUserProfile(profileData, username: username, bio: bio, themeColor: themeColor)
            coreDataManager.updateProfileGenres(profileData, with: favoriteGenres)
        }
    }
    
    // Set custom profile image (in a real app, this would save the image to disk)
    func setCustomImage(_ hasCustomImage: Bool) {
        // Update in-memory profile
        currentProfile.hasCustomImage = hasCustomImage
        
        // Update in Core Data
        if let profileData = coreDataManager.fetchUserProfile() {
            coreDataManager.setCustomImage(profileData, hasCustomImage: hasCustomImage)
        }
    }
    
    // Calculate statistics based on user's anime and manga lists
    func updateStatistics() {
        // This would be implemented to calculate real statistics
        // based on the user's lists in RankingManager
        
        // For Core Data, we don't need to explicitly save here
        // since the statistics are computed properties
    }
}
