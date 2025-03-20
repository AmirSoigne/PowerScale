//
//  UserDefaults+PairwiseSession.swift
//  PowerScale
//
//  Created by Khalil White on 3/20/25.
//

import Foundation

extension UserDefaults {
    // Model for pairwise item pairs (just IDs)
    // struct PairwiseItemPair: Codable {
    //    let firstItemId: Int
    //    let secondItemId: Int
    // }
    
    // Helper to get saved pairwise session
    func getSavedPairwiseSession() -> PairwiseSessionInfo? {
        guard let data = self.data(forKey: PairwiseKeys.savedPairwiseSession) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let session = try decoder.decode(PairwiseSessionInfo.self, from: data)
            return session
        } catch {
            print("❌ Error decoding saved pairwise session: \(error)")
            return nil
        }
    }
    
    // Helper to save pairwise session
    func saveUserDefaultsPairwiseSession(session: PairwiseSessionInfo) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(session)
            self.set(data, forKey: PairwiseKeys.savedPairwiseSession)
        } catch {
            print("❌ Error encoding pairwise session: \(error)")
        }
    }
    
    // Keep the original method for backward compatibility but mark it as deprecated
    @available(*, deprecated, message: "Use saveUserDefaultsPairwiseSession instead")
    func savePairwiseSession(session: PairwiseSessionInfo) {
        saveUserDefaultsPairwiseSession(session: session)
    }
    
    // Model for library items
    struct UserDefaultsLibraryItemInfo: Codable {
        let mediaId: Int
        let isAnime: Bool
        let title: String
        let coverImageURL: String
        let status: String
        let progress: Int
        let score: Double
        let startDate: Date?
        let endDate: Date?
        let isRewatch: Bool
        let rewatchCount: Int
        let timestamp: Date
    }
    
    // Helper to get saved library items
    func getSavedLibraryItems() -> [UserDefaultsLibraryItemInfo] {
        guard let data = self.data(forKey: PairwiseKeys.libraryItems) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let items = try decoder.decode([UserDefaultsLibraryItemInfo].self, from: data)
            return items
        } catch {
            print("❌ Error decoding saved library items: \(error)")
            return []
        }
    }
    
    // Helper to save library items
    func saveLibraryItems(_ items: [UserDefaultsLibraryItemInfo]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            self.set(data, forKey: PairwiseKeys.libraryItems)
        } catch {
            print("❌ Error encoding library items: \(error)")
        }
    }
    
    // Specify which module/namespace LibraryItemInfo comes from
    // For example, if it's in a module called RankingModels:
    private func decodeLibraryItems(from data: Data) -> [LibraryItemInfo]? {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([LibraryItemInfo].self, from: data)
        } catch {
            print("❌ Error decoding library items: \(error)")
            return nil
        }
    }
}

