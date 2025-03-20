//
//  BatchLoadingManager.swift
//  PowerScale
//
//  Created by Khalil White on 3/5/25.
//

import Foundation
import CoreData
import Combine

// A class to manage batch loading of Core Data entities
class BatchLoadingManager {
    // Shared instance for singleton access
    static let shared = BatchLoadingManager()
    
    // Reference to Core Data manager
    private let coreDataManager = CoreDataManager.shared
    
    // Default batch size - adjust based on your app's performance needs
    private let defaultBatchSize = 20
    
    // Private initializer for singleton pattern
    private init() {}
    
    // Batch fetch anime items with pagination
    func fetchAnimeItemsBatched(
        isAnime: Bool,
        status: String? = nil,
        page: Int = 0,
        batchSize: Int? = nil,
        sortBy: SortOption = .rank,
        ascending: Bool = true,
        completion: @escaping ([AnimeItem]) -> Void
    ) {
        // Use default batch size if none provided
        let itemsPerBatch = batchSize ?? defaultBatchSize
        
        // Calculate offset based on page number
        let offset = page * itemsPerBatch
        
        // Create fetch request
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        
        // Build predicate based on parameters
        var predicates: [NSPredicate] = []
        
        // Always filter by anime/manga type
        predicates.append(NSPredicate(format: "isAnime == %@", NSNumber(value: isAnime)))
        
        // Optionally filter by status
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }
        
        // Combine predicates if needed
        if predicates.count > 1 {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        } else if let predicate = predicates.first {
            fetchRequest.predicate = predicate
        }
        
        // Apply sort descriptors
        fetchRequest.sortDescriptors = [createSortDescriptor(for: sortBy, ascending: ascending)]
        
        // Set pagination parameters
        fetchRequest.fetchLimit = itemsPerBatch
        fetchRequest.fetchOffset = offset
        
        // Perform fetch in background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let context = self.coreDataManager.container.viewContext
                let results = try context.fetch(fetchRequest)
                
                // Return results on main thread
                DispatchQueue.main.async {
                    completion(results)
                }
            } catch {
                print("Error performing batched fetch: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // Check if more items are available
    func hasMoreItems(
        isAnime: Bool,
        status: String? = nil,
        currentCount: Int,
        completion: @escaping (Bool) -> Void
    ) {
        // Create a count fetch request (more efficient than fetching actual objects)
        let fetchRequest: NSFetchRequest<NSNumber> = NSFetchRequest(entityName: "AnimeItem")
        fetchRequest.resultType = .countResultType
        
        // Build predicate based on parameters
        var predicates: [NSPredicate] = []
        
        // Always filter by anime/manga type
        predicates.append(NSPredicate(format: "isAnime == %@", NSNumber(value: isAnime)))
        
        // Optionally filter by status
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }
        
        // Combine predicates if needed
        if predicates.count > 1 {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        } else if let predicate = predicates.first {
            fetchRequest.predicate = predicate
        }
        
        // Perform count in background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let context = self.coreDataManager.container.viewContext
                let count = try context.count(for: fetchRequest)
                
                // Return result on main thread
                DispatchQueue.main.async {
                    completion(count > currentCount)
                }
            } catch {
                print("Error checking for more items: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Create a sort descriptor based on the selected sort option
    private func createSortDescriptor(for option: SortOption, ascending: Bool) -> NSSortDescriptor {
        switch option {
        case .rank:
            return NSSortDescriptor(keyPath: \AnimeItem.rank, ascending: ascending)
        case .title:
            return NSSortDescriptor(keyPath: \AnimeItem.title, ascending: ascending)
        case .score:
            return NSSortDescriptor(keyPath: \AnimeItem.score, ascending: ascending)
        case .dateAdded:
            // This assumes you have a dateAdded property, which you might need to add
            // If you don't have one, you can fall back to another property
            return NSSortDescriptor(key: "id", ascending: ascending)
        }
    }
    
    // Enum for sort options
    enum SortOption {
        case rank
        case title
        case score
        case dateAdded
    }
}
