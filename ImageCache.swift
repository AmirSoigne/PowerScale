import SwiftUI
import Combine

// A singleton class for caching images
class ImageCache {
    // Shared instance for global access
    static let shared = ImageCache()
    
    // NSCache for in-memory caching of downloaded images
    private var cache = NSCache<NSString, UIImage>()
    
    // Set a reasonable memory limit (10MB)
    private init() {
        cache.totalCostLimit = 10 * 1024 * 1024
    }
    
    // Get an image from the cache
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    // Add an image to the cache
    func setImage(_ image: UIImage, for url: String) {
        // Estimate the memory cost (approximate size in bytes)
        let cost = Int(image.size.width * image.size.height * 4) // 4 bytes per pixel (RGBA)
        cache.setObject(image, forKey: url as NSString, cost: cost)
    }
    
    // Clear the entire cache
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // Remove a specific image from the cache
    func removeImage(for url: String) {
        cache.removeObject(forKey: url as NSString)
    }
}

// A custom AsyncImage implementation that uses our cache
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    // Image URL
    private let url: URL?
    // Content builder for successful image loading
    private let content: (Image) -> Content
    // Placeholder builder for when image is loading
    private let placeholder: () -> Placeholder
    // State to track the loaded UIImage
    @State private var loadedImage: UIImage?
    // State to track if we're currently loading
    @State private var isLoading = false
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    // Convenience initializer that accepts a string URL
    init?(urlString: String, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                // If we have an image, display it using the content builder
                content(Image(uiImage: image))
            } else {
                // Otherwise show the placeholder
                placeholder()
                    .onAppear(perform: loadImage)
            }
        }
    }
    
    // Load the image, using cache if available
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        // Check if the image is already cached
        let urlString = url.absoluteString
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            loadedImage = cachedImage
            return
        }
        
        // Mark that we're loading
        isLoading = true
        
        // Create a URLSession task to download the image
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let uiImage = UIImage(data: data) else {
                isLoading = false
                return
            }
            
            // Store in cache
            ImageCache.shared.setImage(uiImage, for: urlString)
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                loadedImage = uiImage
                isLoading = false
            }
        }
        
        task.resume()
    }
}

// Extension to make CachedAsyncImage easier to use as a drop-in replacement for AsyncImage
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(url: url, content: { $0 }, placeholder: { ProgressView() })
    }
    
    init?(urlString: String) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.init(url: url, content: { $0 }, placeholder: { ProgressView() })
    }
}

// An additional utility to downsample large images when loading from cache
func downsampleImage(at url: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
        return nil
    }
    
    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ] as CFDictionary
    
    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return nil
    }
    
    return UIImage(cgImage: downsampledImage)
}
