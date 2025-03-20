

import Foundation
import CoreData


extension GenreItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GenreItem> {
        return NSFetchRequest<GenreItem>(entityName: "GenreItem")
    }

    @NSManaged public var name: String?
    @NSManaged public var profile: UserProfileData?

}

extension GenreItem : Identifiable {

}
