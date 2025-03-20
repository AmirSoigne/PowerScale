import Foundation

// We'll keep the DateInfoProtocol in StaffDetailView.swift

// Extended CharacterName structure with alternative names
extension CharacterName {
    var alternative: [String]? {
        return nil // Or whatever logic you need
    }
}

// Extended CharacterImage structure
struct CharacterImageFull: Codable {
    let large: String?
    let medium: String?
}

// Model for character details from API
struct CharacterDetail: Codable {
    let id: Int
    let name: CharacterName
    let image: CharacterImage?
    let description: String?
    let gender: String?
    let dateOfBirth: DateInfo?
    let age: String?
    let bloodType: String?
    let favourites: Int?
    let media: CharacterMediaConnection?
    
    // Date information structure
    struct DateInfo: Codable {
        let year: Int?
        let month: Int?
        let day: Int?
    }
    
    // Media connection for character's appearances
    struct CharacterMediaConnection: Codable {
        let edges: [CharacterMediaEdge]?
    }
    
    // Edge connecting character to media
    struct CharacterMediaEdge: Codable, Identifiable, Hashable {
        var id: Int? // Added for Identifiable conformance
        let node: Anime?
        let role: String?
        let voiceActors: [VoiceActor]?
        
        // Custom coding keys to handle the ID which might not be in API response
        enum CodingKeys: String, CodingKey {
            case id, node, role, voiceActors
        }
        
        // Custom init to handle optional ID
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(Int.self, forKey: .id)
            node = try container.decodeIfPresent(Anime.self, forKey: .node)
            role = try container.decodeIfPresent(String.self, forKey: .role)
            voiceActors = try container.decodeIfPresent([VoiceActor].self, forKey: .voiceActors)
        }
        
        // Add hash function for Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(role)
            hasher.combine(node?.id)
        }
        
        // Add equatable
        static func == (lhs: CharacterMediaEdge, rhs: CharacterMediaEdge) -> Bool {
            return lhs.id == rhs.id &&
                  lhs.role == rhs.role &&
                  lhs.node?.id == rhs.node?.id
        }
    }
    
    // Voice actor structure
    struct VoiceActor: Codable, Identifiable {
        let id: Int
        let name: CharacterName
        let language: String?
        let image: CharacterImage?
    }
}

// Note: DateInfoProtocol conformance is handled in StaffDetailView.swift

// Staff detail model
struct StaffDetail: Codable {
    let id: Int
    let name: CharacterName
    let image: CharacterImage?
    let description: String?
    let primaryOccupations: [String]?
    let gender: String?
    let dateOfBirth: DateInfo?
    let dateOfDeath: DateInfo?
    let age: Int?
    let yearsActive: [Int]?
    let homeTown: String?
    let bloodType: String?
    let languageV2: String?
    let favourites: Int?
    let characters: CharacterConnection?
    let characterMedia: MediaConnection?
    
    struct DateInfo: Codable {
        let year: Int?
        let month: Int?
        let day: Int?
    }
    
    struct CharacterConnection: Codable {
        let edges: [CharacterEdge]?
    }
    
    struct CharacterEdge: Codable, Identifiable, Hashable {
        // Add an id for Identifiable conformance
        var id: UUID? = UUID()
        let role: String?
        let node: CharacterNode?
        let media: Media?
        
        // Custom coding keys to exclude the generated id
        enum CodingKeys: String, CodingKey {
            case role, node, media
        }
        
        // Add hash function for Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(role)
            hasher.combine(node?.id)
            hasher.combine(media?.id)
        }
        
        // Add equatable
        static func == (lhs: CharacterEdge, rhs: CharacterEdge) -> Bool {
            return lhs.id == rhs.id &&
                  lhs.role == rhs.role &&
                  lhs.node?.id == rhs.node?.id &&
                  lhs.media?.id == rhs.media?.id
        }
    }
    
    struct CharacterNode: Codable, Hashable {
        let id: Int
        let name: CharacterName
        let image: CharacterImage?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: CharacterNode, rhs: CharacterNode) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct Media: Codable, Hashable {
        let id: Int
        let title: AnimeTitle
        let coverImage: CoverImage
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Media, rhs: Media) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct MediaConnection: Codable {
        let edges: [MediaEdge]?
    }
    
    struct MediaEdge: Codable, Identifiable, Hashable {
        // Add an id for Identifiable conformance
        var id: UUID? = UUID()
        let characterRole: String?
        let node: Media?
        let characters: [CharacterNode]?
        
        // Custom coding keys to exclude the generated id
        enum CodingKeys: String, CodingKey {
            case characterRole, node, characters
        }
        
        // Add hash function for Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(characterRole)
            hasher.combine(node?.id)
        }
        
        // Add equatable
        static func == (lhs: MediaEdge, rhs: MediaEdge) -> Bool {
            return lhs.id == rhs.id &&
                  lhs.characterRole == rhs.characterRole &&
                  lhs.node?.id == rhs.node?.id
        }
    }
}

// Note: DateInfoProtocol conformance is handled in StaffDetailView.swift

// Make AnimeTitle conform to Hashable
extension AnimeTitle: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(romaji)
        hasher.combine(english)
        hasher.combine(native)
    }
    
    static func == (lhs: AnimeTitle, rhs: AnimeTitle) -> Bool {
        return lhs.romaji == rhs.romaji &&
               lhs.english == rhs.english &&
               lhs.native == rhs.native
    }
}

// Make CharacterName conform to Hashable
extension CharacterName: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(full)
        hasher.combine(first)
        hasher.combine(last)
        hasher.combine(native)
    }
    
    static func == (lhs: CharacterName, rhs: CharacterName) -> Bool {
        return lhs.full == rhs.full &&
               lhs.first == rhs.first &&
               lhs.last == rhs.last &&
               lhs.native == rhs.native
    }
}

// Make CoverImage conform to Hashable
extension CoverImage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(large)
    }
    
    static func == (lhs: CoverImage, rhs: CoverImage) -> Bool {
        return lhs.large == rhs.large
    }
}

// Make CharacterImage conform to Hashable
extension CharacterImage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(medium)
    }
    
    static func == (lhs: CharacterImage, rhs: CharacterImage) -> Bool {
        return lhs.medium == rhs.medium
    }
}

// Model for character detail API response
struct CharacterDetailResponse: Codable {
    let data: CharacterData
    
    struct CharacterData: Codable {
        let Character: CharacterDetail
    }
}

// Model for staff detail API response
struct StaffDetailResponse: Codable {
    let data: StaffData
    
    struct StaffData: Codable {
        let Staff: StaffDetail
    }
}
