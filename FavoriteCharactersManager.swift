import Foundation
import SwiftUI

// A utility class to manage favorite characters across the app
class FavoriteCharactersManager {
    // Shared instance for singleton access
    static let shared = FavoriteCharactersManager()
    
    // User defaults key for storing favorite character IDs
    private let favoritesKey = "favoriteCharacters"
    
    // Private initializer for singleton pattern
    private init() {}
    
    // Check if a character is a favorite
    func isCharacterFavorite(_ characterId: Int) -> Bool {
        return getFavoriteCharacters().contains(characterId)
    }
    
    // Toggle favorite status for a character
    func toggleFavorite(characterId: Int) -> Bool {
        var favoriteCharacters = getFavoriteCharacters()
        let isFavorite = favoriteCharacters.contains(characterId)
        
        if isFavorite {
            // Remove from favorites
            favoriteCharacters.removeAll { $0 == characterId }
        } else {
            // Add to favorites
            favoriteCharacters.append(characterId)
        }
        
        // Save the updated list
        saveFavoriteCharacters(favoriteCharacters)
        
        // Post notification about the change
        NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
        
        // Return the new status
        return !isFavorite
    }
    
    // Add a character to favorites
    func addFavorite(characterId: Int) {
        var favoriteCharacters = getFavoriteCharacters()
        if !favoriteCharacters.contains(characterId) {
            favoriteCharacters.append(characterId)
            saveFavoriteCharacters(favoriteCharacters)
            
            // Post notification about the change
            NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
        }
    }
    
    // Remove a character from favorites
    func removeFavorite(characterId: Int) {
        var favoriteCharacters = getFavoriteCharacters()
        if favoriteCharacters.contains(characterId) {
            favoriteCharacters.removeAll { $0 == characterId }
            saveFavoriteCharacters(favoriteCharacters)
            
            // Post notification about the change
            NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
        }
    }
    
    // Get the list of favorite character IDs
    func getFavoriteCharacters() -> [Int] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([Int].self, from: data)
        } catch {
            print("Error decoding favorite characters: \(error)")
            return []
        }
    }
    
    // Save the list of favorite character IDs
    private func saveFavoriteCharacters(_ favorites: [Int]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("Error encoding favorite characters: \(error)")
        }
    }
    
    // Reorder favorite characters
    func reorderFavorites(from source: IndexSet, to destination: Int) {
        var favorites = getFavoriteCharacters()
        favorites.move(fromOffsets: source, toOffset: destination)
        saveFavoriteCharacters(favorites)
        
        // Post notification about the order change
        NotificationCenter.default.post(name: Notification.Name("CharacterOrderChanged"), object: nil)
    }
    
    // Save a manual reordering of characters
    func saveCharacterOrder(_ characterIds: [Int]) {
        saveFavoriteCharacters(characterIds)
        
        // Post notification about the order change
        NotificationCenter.default.post(name: Notification.Name("CharacterOrderChanged"), object: nil)
    }
    
    // Get the favorite character at a specific index
    func getFavoriteCharacter(at index: Int) -> Int? {
        let favorites = getFavoriteCharacters()
        guard index >= 0 && index < favorites.count else { return nil }
        return favorites[index]
    }
    
    // Get the count of favorite characters
    func getFavoriteCount() -> Int {
        return getFavoriteCharacters().count
    }
    
    // Clear all favorites
    func clearAllFavorites() {
        saveFavoriteCharacters([])
        
        // Post notification about the change
        NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
    }
    
    // Get the position of a character in the favorites list (for ranking)
    func getCharacterRank(_ characterId: Int) -> Int? {
        let favorites = getFavoriteCharacters()
        return favorites.firstIndex(of: characterId)
    }
    
    // Add a character to favorites at a specific position
    func addFavoriteAt(characterId: Int, position: Int) {
        var favorites = getFavoriteCharacters()
        
        // Remove the character if it's already in the list
        favorites.removeAll { $0 == characterId }
        
        // Insert at the specified position (or at the end if position is out of bounds)
        let insertPosition = min(position, favorites.count)
        favorites.insert(characterId, at: insertPosition)
        
        saveFavoriteCharacters(favorites)
        
        // Post notification about the change
        NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
    }
    
    // Load characters with their full details (requires API calls)
    func loadCharacterDetails(completion: @escaping ([CharacterDetail]) -> Void) {
        let favoriteIds = getFavoriteCharacters()
        if favoriteIds.isEmpty {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var characters: [CharacterDetail] = []
        var failedIds: [Int] = []
        
        for characterId in favoriteIds {
            group.enter()
            
            // Use throttler to execute the request
            APIRequestThrottler.shared.executeRequest {
                AniListAPI.shared.getCharacterDetails(id: characterId) { character in
                    if let character = character {
                        DispatchQueue.main.async {
                            characters.append(character)
                        }
                    } else {
                        // Track failed requests for retry
                        failedIds.append(characterId)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // If there are failed requests, you could implement a retry logic
            // or just continue with what you have
            
            // Sort the characters to match the order in favoriteIds
            let sortedCharacters = favoriteIds.compactMap { id in
                characters.first { $0.id == id }
            }
            
            completion(sortedCharacters)
        }
    }
}

// Extension to help manage favorite character UI components
extension FavoriteCharactersManager {
    // Create a favorite button for character detail views
    func createFavoriteButton(for characterId: Int) -> some View {
        let isFavorite = isCharacterFavorite(characterId)
        
        return Button(action: {
            _ = self.toggleFavorite(characterId: characterId)
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : .white)
                .font(.system(size: 22))
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .shadow(color: isFavorite ? .red.opacity(0.5) : .clear, radius: isFavorite ? 3 : 0)
        }
    }
}
