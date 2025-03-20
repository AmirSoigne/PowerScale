import Foundation
import CoreData

extension AnimeItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnimeItem> {
        return NSFetchRequest<AnimeItem>(entityName: "AnimeItem")
    }

    // Existing properties
    @NSManaged public var id: Int64
    @NSManaged public var title: String?
    @NSManaged public var coverImageURL: String?
    @NSManaged public var animeDescription: String?
    @NSManaged public var status: String?
    @NSManaged public var isAnime: Bool
    @NSManaged public var rank: Int16
    @NSManaged public var score: Int16
    @NSManaged public var episodes: Int16
    @NSManaged public var isAdult: Bool
    @NSManaged public var genres: [String]?
    
    // New properties for rewatch functionality
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var isRewatch: Bool
    @NSManaged public var rewatchCount: Int16
    @NSManaged public var progress: Int16
}
