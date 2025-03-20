//
//  PairwiseImageCache.swift
//  PowerScale
//
//  Created by Khalil White on 3/20/25.
//

import Foundation
import UIKit

class PairwiseImageCache {
    static let shared = PairwiseImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func getImage(for url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }
        
        // Use rate limiter to avoid too many concurrent image downloads
        APIRateLimiter.shared.executeRequest {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    // Store in cache
                    self.cache.setObject(image, forKey: url.absoluteString as NSString)
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
        }
    }
}

