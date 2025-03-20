import Foundation

class APIRequestThrottler {
   static let shared = APIRequestThrottler()
   
   private var requestQueue = [() -> Void]()
   private var isProcessingQueue = false
   private let minRequestInterval: TimeInterval = 1.0 // 1 second between requests
   
   private init() {}
   
   func executeRequest(_ request: @escaping () -> Void) {
       requestQueue.append(request)
       
       if !isProcessingQueue {
           processQueue()
       }
   }
   
   private func processQueue() {
       guard !requestQueue.isEmpty else {
           isProcessingQueue = false
           return
       }
       
       isProcessingQueue = true
       
       // Execute the first request in the queue
       let request = requestQueue.removeFirst()
       request()
       
       // Wait before processing the next request
       DispatchQueue.main.asyncAfter(deadline: .now() + minRequestInterval) { [weak self] in
           self?.processQueue()
       }
   }
}
