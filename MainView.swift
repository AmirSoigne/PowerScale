import SwiftUI

struct MainView: View {
    // Theme color from user profile
    @ObservedObject private var profileManager = ProfileManager.shared
    
    // Add StateObject for tab selection
    @StateObject private var tabSelection = TabSelectionState()
    
    // State to observe profile image changes
    @State private var profileImageUpdated = false
    @State private var profileUIImage: UIImage? = nil
    
    init() {
        // Customize the tab bar appearance to be transparent
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8) // Semi-transparent black
        
        // Customize the unselected state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // Customize the selected state - will be updated based on user theme
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            // Home Tab
            ZStack {
                HomeView()
                    .environmentObject(tabSelection)
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.001)) // Nearly invisible
                        .frame(height: 50) // Height of tab bar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
                    .font(.system(size: 12))
            }
            .tag(0)
            .accentColor(profileManager.currentProfile.getThemeColor())

            // Search Tab
            ZStack {
                SearchView()
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.001)) // Nearly invisible
                        .frame(height: 50) // Height of tab bar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .tabItem {
                Label("Explore", systemImage: "map")
                    .font(.system(size: 12))
            }
            .tag(1)
            .accentColor(profileManager.currentProfile.getThemeColor())
            
            // Library Tab (Combined Anime & Manga)
            ZStack {
                LibraryView()
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.001)) // Nearly invisible
                        .frame(height: 50) // Height of tab bar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
                    .font(.system(size: 12))
            }
            .tag(2)
            .accentColor(profileManager.currentProfile.getThemeColor())

            // Ranking Tab
            ZStack {
                RankingView()
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.001)) // Nearly invisible
                        .frame(height: 50) // Height of tab bar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .tabItem {
                Label("Ranking", systemImage: "trophy.fill")
                    .font(.system(size: 12))
            }
            .tag(3)
            .accentColor(profileManager.currentProfile.getThemeColor())
            
            // Profile Tab
            ZStack {
                ProfileView()
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.001)) // Nearly invisible
                        .frame(height: 50) // Height of tab bar
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .tabItem {
                // Use different approach based on whether we have a profile image
                if profileImageUpdated && profileManager.currentProfile.hasCustomImage {
                    // Use a custom tab image
                    Label("Profile", systemImage: "person.crop.circle.fill")
                } else {
                    // Use default icon
                    Label("Profile", systemImage: "person.fill")
                }
            }
            .tag(4)
            .accentColor(profileManager.currentProfile.getThemeColor())
        }
        .environmentObject(tabSelection)
        .onAppear {
            // Create smaller icon configuration
            let iconConfig = UIImage.SymbolConfiguration(scale: .small)
            
            // Apply configuration to all tab bar items
            UITabBar.appearance().items?.forEach { item in
                if let image = item.image {
                    item.image = image.withConfiguration(iconConfig)
                }
                if let selectedImage = item.selectedImage {
                    item.selectedImage = selectedImage.withConfiguration(iconConfig)
                }
            }
            
            // Update tab bar selected color based on user theme
            UITabBar.appearance().tintColor = UIColor(profileManager.currentProfile.getThemeColor())
            
            // Check if user has a profile image
            checkProfileImage()
            
            // Set up notification observer for profile image changes
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ProfileImageChanged"),
                object: nil,
                queue: .main
            ) { _ in
                checkProfileImage()
            }
        }
    }
    
    // Helper function to check for profile image
    private func checkProfileImage() {
        if profileManager.currentProfile.hasCustomImage {
            if let _ = ProfileImageManager.shared.loadProfileImage() {
                // We have a valid profile image
                profileImageUpdated = true
            } else {
                profileImageUpdated = false
            }
        } else {
            profileImageUpdated = false
        }
    }
}

#Preview {
    MainView()
}
