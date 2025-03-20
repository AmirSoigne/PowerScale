//
//  APIRateLimiter.swift
//  PowerScale
//
//  Created by Khalil White on 3/20/25.
//

import Foundation

class APIRateLimiter {
    static let shared = APIRateLimiter()
    
    private let requestsPerMinute = 90 // AniList limit
    private var requestTimestamps: [Date] = []
    private let queue = DispatchQueue(label: "com.yourapp.rateLimiter")
    
    func executeRequest(block: @escaping () -> Void) {
        queue.async {
            // Remove timestamps older than 1 minute
            let oneMinuteAgo = Date().addingTimeInterval(-60)
            self.requestTimestamps = self.requestTimestamps.filter { $0 > oneMinuteAgo }
            
            // Check if we've reached the limit
            if self.requestTimestamps.count >= self.requestsPerMinute {
                // Calculate when we can make the next request
                if let oldestTimestamp = self.requestTimestamps.first {
                    let waitTime = 60 - Date().timeIntervalSince(oldestTimestamp) + 0.1
                    if waitTime > 0 {
                        Thread.sleep(forTimeInterval: waitTime)
                    }
                }
            }
            
            // Add current timestamp and execute request
            self.requestTimestamps.append(Date())
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

