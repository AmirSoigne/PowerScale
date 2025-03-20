import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var rankingManager = RankingManager.shared
    
    @State private var isEditingProfile = false
    @State private var editedUsername: String = ""
    @State private var editedBio: String = ""
    @State private var selectedGenres: [String] = []
    @State private var selectedThemeColor: String = "blue"
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var profileImage: Image?
    @State private var showingSettings = false
    
    // Computed properties for statistics
    private var totalAnimeCount: Int {
        return rankingManager.currentlyWatching.count +
               rankingManager.rankedAnime.count +
               rankingManager.wantToWatch.count +
               rankingManager.onHoldAnime.count +
               rankingManager.lostInterestAnime.count
    }
    
    private var totalMangaCount: Int {
        return rankingManager.currentlyReading.count +
               rankingManager.rankedManga.count +
               rankingManager.wantToRead.count +
               rankingManager.onHoldManga.count +
               rankingManager.lostInterestManga.count
    }
    
    private var completedAnimeCount: Int {
        return rankingManager.rankedAnime.count
    }
    
    private var completedMangaCount: Int {
        return rankingManager.rankedManga.count
    }
    
    // Formatted join date
    private var joinDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: profileManager.currentProfile.joinDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background image
                Image("bg2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.3)
                    .blur(radius: 5)
                
                // Dark overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header with photo
                        ZStack {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(profileManager.currentProfile.getThemeColor(), lineWidth: 3))
                                    .shadow(radius: 10)
                                    .padding(.top, 40)
                            } else {
                                // Default image
                                Image(systemName: profileManager.currentProfile.profileImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .padding(30)
                                    .foregroundColor(.white)
                                    .background(profileManager.currentProfile.getThemeColor())
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    .shadow(radius: 10)
                                    .padding(.top, 40)
                            }
                            
                            // Only show the camera overlay in edit mode
                            if isEditingProfile {
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    ZStack {
                                        // Semi-transparent overlay
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 120, height: 120)
                                        
                                        // Camera icon
                                        VStack {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white)
                                            
                                            Text("Change Photo")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.top, 5)
                                        }
                                    }
                                    .padding(.top, 40)
                                }
                                .onChange(of: selectedItem) { oldValue, newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                            selectedImageData = data
                                            if let uiImage = UIImage(data: data) {
                                                // Process the image - resize and make circular
                                                let resizedImage = ProfileImageManager.shared.resizeImage(uiImage, targetSize: CGSize(width: 400, height: 400))
                                                let circularImage = ProfileImageManager.shared.createCircularProfileImage(from: resizedImage)
                                                
                                                // Save the processed image
                                                if ProfileImageManager.shared.saveProfileImage(circularImage) {
                                                    profileImage = Image(uiImage: circularImage)
                                                    profileManager.setCustomImage(true)
                                                    
                                                    // Post notification that profile image has changed
                                                    NotificationCenter.default.post(name: Notification.Name("ProfileImageChanged"), object: nil)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Username
                        if isEditingProfile {
                            TextField("Username", text: $editedUsername)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            Text(profileManager.currentProfile.username)
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                        
                        // Join date
                        Text("Member since \(joinDateFormatted)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Bio
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About Me")
                                .font(.headline)
                                .foregroundColor(profileManager.currentProfile.getThemeColor())
                                .padding(.horizontal, 35)
                            
                            if isEditingProfile {
                                ZStack(alignment: .topLeading) {
                                    // Background for text editor
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.5))
                                        .frame(height: 120)
                                    
                                    // Text editor with proper padding
                                    TextEditor(text: $editedBio)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .frame(height: 120)
                                        .foregroundColor(.white) // Make text white
                                        .background(Color.clear) // Make background transparent
                                        .accentColor(profileManager.currentProfile.getThemeColor()) // Set cursor color
                                        .scrollContentBackground(.hidden) // Hide the default background
                                        .disableAutocorrection(true)
                                }
                                .padding(.horizontal)
                            } else {
                                Text(profileManager.currentProfile.bio)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 25)
                            }
                        }
                        
                        // Favorite genres
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Favorite Genres")
                                .font(.headline)
                                .foregroundColor(profileManager.currentProfile.getThemeColor())
                                .padding(.horizontal, 35)
                            
                            if isEditingProfile {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        Spacer()
                                            .frame(width: 20)
                                        
                                        ForEach(UserProfile.availableGenres, id: \.self) { genre in
                                            Button(action: {
                                                if selectedGenres.contains(genre) {
                                                    selectedGenres.removeAll { $0 == genre }
                                                } else {
                                                    selectedGenres.append(genre)
                                                }
                                            }) {
                                                Text(genre)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        selectedGenres.contains(genre)
                                                        ? profileManager.currentProfile.getThemeColor()
                                                        : Color.gray.opacity(0.3)
                                                    )
                                                    .foregroundColor(.white)
                                                    .cornerRadius(20)
                                            }
                                        }
                                        
                                        Spacer()
                                            .frame(width: 20)
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                if profileManager.currentProfile.favoriteGenres.isEmpty {
                                    Text("No favorite genres selected")
                                        .foregroundColor(.gray)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(10)
                                        .padding(.horizontal, 30)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            Spacer()
                                                .frame(width: 20)
                                            
                                            ForEach(profileManager.currentProfile.favoriteGenres, id: \.self) { genre in
                                                Text(genre)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(profileManager.currentProfile.getThemeColor().opacity(0.7))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(20)
                                            }
                                            
                                            Spacer()
                                                .frame(width: 20)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        // Theme selection (only in edit mode)
                        if isEditingProfile {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Profile Theme")
                                    .font(.headline)
                                    .foregroundColor(UserProfile.availableThemes[selectedThemeColor] ?? .blue)
                                    .padding(.horizontal, 35)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        Spacer()
                                            .frame(width: 20)
                                        
                                        ForEach(Array(UserProfile.availableThemes.keys), id: \.self) { colorName in
                                            let color = UserProfile.availableThemes[colorName] ?? .blue
                                            
                                            Button(action: {
                                                selectedThemeColor = colorName
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(color)
                                                        .frame(width: 40, height: 40)
                                                    
                                                    if colorName == selectedThemeColor {
                                                        Circle()
                                                            .strokeBorder(Color.white, lineWidth: 2)
                                                            .frame(width: 46, height: 46)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                            .frame(width: 20)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Statistics section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("My Statistics")
                                .font(.headline)
                                .foregroundColor(profileManager.currentProfile.getThemeColor())
                                .padding(.horizontal, 35)
                            
                            VStack(spacing: 15) {
                                // Create a 2x2 grid of stats
                                HStack(spacing: 15) {
                                    // Total Anime
                                    statCard(
                                        title: "Total Anime",
                                        value: "\(totalAnimeCount)",
                                        iconName: "play.tv.fill"
                                    )
                                    
                                    // Total Manga
                                    statCard(
                                        title: "Total Manga",
                                        value: "\(totalMangaCount)",
                                        iconName: "book.fill"
                                    )
                                }
                                
                                HStack(spacing: 15) {
                                    // Completed Anime
                                    statCard(
                                        title: "Completed Anime",
                                        value: "\(completedAnimeCount)",
                                        iconName: "checkmark.circle.fill"
                                    )
                                    
                                    // Completed Manga
                                    statCard(
                                        title: "Completed Manga",
                                        value: "\(completedMangaCount)",
                                        iconName: "checkmark.square.fill"
                                    )
                                }
                            }
                            .padding(.horizontal, 35)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading item (left side) - Settings button or Cancel button when editing
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditingProfile {
                        Button(action: {
                            isEditingProfile = false
                        }) {
                            Text("Cancel")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 14, weight: .medium))
                        }
                    } else {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Trailing item (right side) - Edit or Save button
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditingProfile {
                        // Save button when in edit mode
                        Button(action: {
                            // Save changes
                            profileManager.updateProfile(
                                username: editedUsername,
                                bio: editedBio,
                                favoriteGenres: selectedGenres,
                                themeColor: selectedThemeColor
                            )
                            isEditingProfile = false
                        }) {
                            Text("Save")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(profileManager.currentProfile.getThemeColor())
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 14, weight: .medium))
                        }
                    } else {
                        // Edit button when not in edit mode
                        Button(action: {
                            // Initialize editing fields with current values
                            editedUsername = profileManager.currentProfile.username
                            editedBio = profileManager.currentProfile.bio
                            selectedGenres = profileManager.currentProfile.favoriteGenres
                            selectedThemeColor = profileManager.currentProfile.themeColor
                            isEditingProfile = true
                        }) {
                            Text("Edit")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(profileManager.currentProfile.getThemeColor())
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            // Load the profile image if available
            if profileManager.currentProfile.hasCustomImage {
                if let savedImage = ProfileImageManager.shared.loadProfileImage() {
                    profileImage = Image(uiImage: savedImage)
                }
            }
        }
    }
    
    // Helper function to create stat cards
    private func statCard(title: String, value: String, iconName: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(profileManager.currentProfile.getThemeColor())
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}
