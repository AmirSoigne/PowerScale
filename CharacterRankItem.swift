import Foundation
import CoreData

// Model for character ranking data
struct CharacterRankItem: Identifiable, Codable {
    let id: Int
    let name: String
    let characterImage: String
    let rank: Int
    let isFavorite: Bool
    let dateAdded: Date
    let animeOrigin: String? // Optional reference to the source anime
    
    // Helper initializer from CharacterDetail
    init(from character: CharacterDetail) {
        self.id = character.id
        self.name = character.name.full
        self.characterImage = character.image?.medium ?? ""
        self.rank = 0 // Default rank
        self.isFavorite = true
        self.dateAdded = Date()
        self.animeOrigin = nil // Can be set later if needed
    }
    
    // Custom initializer for creating/updating items
    init(id: Int, name: String, characterImage: String, rank: Int, isFavorite: Bool, dateAdded: Date, animeOrigin: String?) {
        self.id = id
        self.name = name
        self.characterImage = characterImage
        self.rank = rank
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.animeOrigin = animeOrigin
    }
}
