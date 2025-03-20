

import Foundation
import CoreData


extension UserProfileData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileData> {
        return NSFetchRequest<UserProfileData>(entityName: "UserProfileData")
    }

    @NSManaged public var username: String?
    @NSManaged public var bio: String?
    @NSManaged public var joinDate: Date?
    @NSManaged public var profileImageName: String?
    @NSManaged public var themeColor: String?
    @NSManaged public var hasCustomImage: Bool
    @NSManaged public var favoriteGenres: GenreItem?

}

extension UserProfileData : Identifiable {

}
