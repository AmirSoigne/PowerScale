import SwiftUI
import UIKit

// A utility class to manage the user's profile image
class ProfileImageManager {
    static let shared = ProfileImageManager()
    
    private init() {}
    
    // File name for storing the profile image
    private let profileImageFilename = "profile_image.jpg"
    private let tabIconFilename = "tab_icon.jpg"
    
    // Save a profile image to disk
    func saveProfileImage(_ image: UIImage) -> Bool {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG data")
            return false
        }
        
        let fileURL = getProfileImageURL()
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Profile image saved successfully at: \(fileURL)")
            
            // Also create and save a tab bar sized version
            createAndSaveTabIcon(from: image)
            
            return true
        } catch {
            print("❌ Error saving profile image: \(error)")
            return false
        }
    }
    
    // Create and save a small icon specifically for the tab bar
    private func createAndSaveTabIcon(from originalImage: UIImage) {
        // Create a tab bar sized version (small, optimized for tab bar)
        let tabSize = CGSize(width: 30, height: 30)
        let tabImage = resizeImage(originalImage, targetSize: tabSize)
        let circularTabImage = createCircularProfileImage(from: tabImage)
        
        // Save the tab icon
        if let imageData = circularTabImage.jpegData(compressionQuality: 1.0) {
            let tabIconURL = getTabIconURL()
            do {
                try imageData.write(to: tabIconURL)
                print("✅ Tab icon saved successfully")
            } catch {
                print("❌ Error saving tab icon: \(error)")
            }
        }
    }
    
    // Load the tab icon specifically for tab bar
    func loadTabIcon() -> UIImage? {
        let fileURL = getTabIconURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let imageData = try Data(contentsOf: fileURL)
                if let image = UIImage(data: imageData) {
                    return image
                }
            } catch {
                print("❌ Error loading tab icon: \(error)")
                
                // If tab icon fails to load but main image exists, recreate it
                if let originalImage = loadProfileImage() {
                    createAndSaveTabIcon(from: originalImage)
                    return loadTabIcon() // Try again
                }
            }
        } else if let originalImage = loadProfileImage() {
            // If tab icon doesn't exist but main image does, create it
            createAndSaveTabIcon(from: originalImage)
            return loadTabIcon() // Try again
        }
        
        return nil
    }
    
    // Load the profile image from disk
    func loadProfileImage() -> UIImage? {
        let fileURL = getProfileImageURL()
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let imageData = try Data(contentsOf: fileURL)
                if let image = UIImage(data: imageData) {
                    return image
                } else {
                    print("⚠️ Could not create UIImage from data")
                }
            } catch {
                print("❌ Error loading profile image: \(error)")
            }
        } else {
            print("ℹ️ No profile image exists at: \(fileURL)")
        }
        
        return nil
    }
    
    // Delete the profile image from disk
    func deleteProfileImage() -> Bool {
        let fileURL = getProfileImageURL()
        let tabIconURL = getTabIconURL()
        
        var success = true
        
        // Delete main profile image
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ Profile image deleted successfully")
            } catch {
                print("❌ Error deleting profile image: \(error)")
                success = false
            }
        }
        
        // Delete tab icon
        if FileManager.default.fileExists(atPath: tabIconURL.path) {
            do {
                try FileManager.default.removeItem(at: tabIconURL)
                print("✅ Tab icon deleted successfully")
            } catch {
                print("❌ Error deleting tab icon: \(error)")
                success = false
            }
        }
        
        // Post notification about the deletion
        NotificationCenter.default.post(name: Notification.Name("ProfileImageChanged"), object: nil)
        
        return success
    }
    
    // Get the URL where the profile image is stored
    private func getProfileImageURL() -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(profileImageFilename)
    }
    
    // Get the URL where the tab icon is stored
    private func getTabIconURL() -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(tabIconFilename)
    }
    
    // Helper method to resize an image before saving (if needed)
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // Create a circular profile image
    func createCircularProfileImage(from image: UIImage) -> UIImage {
        let imageSize = image.size
        let minDimension = min(imageSize.width, imageSize.height)
        
        // Create a square context with the minimum dimension
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: minDimension, height: minDimension))
        
        return renderer.image { context in
            // Create a circular clip path
            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: CGSize(width: minDimension, height: minDimension)),
                cornerRadius: minDimension / 2
            )
            path.addClip()
            
            // Calculate positioning to center the image
            let xOffset = (minDimension - imageSize.width) / 2
            let yOffset = (minDimension - imageSize.height) / 2
            
            // Draw the image
            image.draw(at: CGPoint(x: xOffset, y: yOffset))
        }
    }
}
