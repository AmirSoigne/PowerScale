import SwiftUI

struct HomeView: View {
    @ObservedObject private var rankingManager = RankingManager.shared
    @State private var selectedTab: Int = 0
    @EnvironmentObject var tabSelection: TabSelectionState
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background image
                Image("bg2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.3)
                
                // Dark overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Main content with extra safe padding
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Add padding at the top
                        Spacer().frame(height: 20)
                        
                        // Anime sections
                        // Currently Watching Section - limited to 5
                        if !rankingManager.currentlyWatching.isEmpty {
                            sectionView(
                                title: "CURRENTLY WATCHING",
                                items: Array(rankingManager.currentlyWatching.prefix(5).map { $0.toAnime() }),
                                isAnime: true
                            )
                        }
                        
                        // Top Ranked Anime - Get from all lists EXCEPT want to watch
                        let topRankedAnime = getTopRankedAnime().prefix(5).map { $0.toAnime() }
                        if !topRankedAnime.isEmpty {
                            sectionView(
                                title: "YOUR TOP RANKED ANIME",
                                items: Array(topRankedAnime),
                                isAnime: true
                            )
                        }
                        
                        // On Hold Anime
                        if !rankingManager.onHoldAnime.isEmpty {
                            sectionView(
                                title: "ON HOLD ANIME",
                                items: Array(rankingManager.onHoldAnime.prefix(5).map { $0.toAnime() }),
                                isAnime: true
                            )
                        }
                        
                        // Lost Interest Anime
                        if !rankingManager.lostInterestAnime.isEmpty {
                            sectionView(
                                title: "DROPPED ANIME",
                                items: Array(rankingManager.lostInterestAnime.prefix(5).map { $0.toAnime() }),
                                isAnime: true
                            )
                        }
                        
                        // Currently Reading Section
                        if !rankingManager.currentlyReading.isEmpty {
                            sectionView(
                                title: "CURRENTLY READING",
                                items: Array(rankingManager.currentlyReading.prefix(5).map { $0.toAnime() }),
                                isAnime: false
                            )
                        }
                        
                        // Top Ranked Manga - Get from all lists EXCEPT want to read
                        let topRankedManga = getTopRankedManga().prefix(5).map { $0.toAnime() }
                        if !topRankedManga.isEmpty {
                            sectionView(
                                title: "YOUR TOP RANKED MANGA",
                                items: Array(topRankedManga),
                                isAnime: false
                            )
                        }
                        
                        // On Hold Manga
                        if !rankingManager.onHoldManga.isEmpty {
                            sectionView(
                                title: "ON HOLD MANGA",
                                items: Array(rankingManager.onHoldManga.prefix(5).map { $0.toAnime() }),
                                isAnime: false
                            )
                        }
                        
                        // Lost Interest Manga
                        if !rankingManager.lostInterestManga.isEmpty {
                            sectionView(
                                title: "DROPPED MANGA",
                                items: Array(rankingManager.lostInterestManga.prefix(5).map { $0.toAnime() }),
                                isAnime: false
                            )
                        }
                        
                        // Show welcome message if no content
                        if rankingManager.currentlyWatching.isEmpty &&
                           rankingManager.currentlyReading.isEmpty &&
                           rankingManager.rankedAnime.isEmpty &&
                           rankingManager.rankedManga.isEmpty &&
                           rankingManager.onHoldAnime.isEmpty &&
                           rankingManager.onHoldManga.isEmpty &&
                           rankingManager.lostInterestAnime.isEmpty &&
                           rankingManager.lostInterestManga.isEmpty {
                            VStack(spacing: 15) {
                                Text("Welcome to PowerScale!")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text("Search for your favorite anime and manga to start building your collection.")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 30)
                                
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                }
            }
        }
    }
    
    // Section view with consistent styling to SearchView
    private func sectionView(title: String, items: [Anime], isAnime: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Add See More button based on the title
                seeMoreButton(for: title, isAnime: isAnime)
            }
            .padding(.leading, 40)  // Increased left padding to match specification
            .padding(.trailing, 40)
            
            if items.isEmpty {
                // Show empty state
                HStack {
                    Spacer()
                    Text("No items available")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            } else {
                // Show actual items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Spacer().frame(width: 24)  // Added left spacing
                        
                        ForEach(items, id: \.id) { item in
                            // Use the updated NavigationLink to the self-loading AnimeDetailView
                            NavigationLink(destination: AnimeDetailView(anime: item, isAnime: isAnime)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Cover image
                                    CachedAsyncImage(urlString: item.coverImage.large) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(8)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 120, height: 180)
                                            .cornerRadius(8)
                                    }
                                    
                                    // Title and status
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title.english ?? item.title.romaji ?? "Unknown")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .frame(width: 120, alignment: .topLeading)
                                        
                                        // User status indicator
                                        HStack(spacing: 3) {
                                            Circle()
                                                .fill(statusColor(getUserStatus(isAnime: isAnime, id: item.id)))
                                                .frame(width: 6, height: 6)
                                            
                                            Text(formatUserStatus(getUserStatus(isAnime: isAnime, id: item.id)))
                                                .font(.system(size: 10))
                                                .foregroundColor(statusColor(getUserStatus(isAnime: isAnime, id: item.id)))
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(width: 120, height: 52, alignment: .topLeading)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // Helper function to create "See More" buttons for each section
    private func seeMoreButton(for title: String, isAnime: Bool) -> some View {
        Button(action: {
            // Navigate to the appropriate tab and category
            switch title {
            case "CURRENTLY WATCHING":
                // Navigate to Library tab with "Currently Watching" category selected
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(0, forKey: "selectedLibraryType")  // 0 for Anime
                UserDefaults.standard.set("Currently Watching", forKey: "selectedAnimeCategory")
            case "YOUR TOP RANKED ANIME":
                // Navigate to Ranking tab with Anime selected
                tabSelection.selectedTab = 3  // Ranking tab
                UserDefaults.standard.set("Anime", forKey: "selectedRankingCategory")
            case "ON HOLD ANIME":
                // Navigate to Library tab with "On Hold" category selected
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(0, forKey: "selectedLibraryType")  // 0 for Anime
                UserDefaults.standard.set("On Hold", forKey: "selectedAnimeCategory")
            case "DROPPED ANIME":
                // Navigate to Library tab with "Lost Interest" category selected
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(0, forKey: "selectedLibraryType")  // 0 for Anime
                UserDefaults.standard.set("Lost Interest", forKey: "selectedAnimeCategory")
            case "CURRENTLY READING":
                // Navigate to Library tab with "Currently Reading" category selected
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(1, forKey: "selectedLibraryType")  // 1 for Manga
                UserDefaults.standard.set("Currently Reading", forKey: "selectedMangaCategory")
            case "YOUR TOP RANKED MANGA":
                // Navigate to Ranking tab with Manga selected
                tabSelection.selectedTab = 3  // Ranking tab
                UserDefaults.standard.set("Manga", forKey: "selectedRankingCategory")
            case "ON HOLD MANGA":
                // Navigate to Library tab with "On Hold" category selected for Manga
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(1, forKey: "selectedLibraryType")  // 1 for Manga
                UserDefaults.standard.set("On Hold", forKey: "selectedMangaCategory")
            case "DROPPED MANGA":
                // Navigate to Library tab with "Lost Interest" category selected for Manga
                tabSelection.selectedTab = 2  // Library tab
                UserDefaults.standard.set(1, forKey: "selectedLibraryType")  // 1 for Manga
                UserDefaults.standard.set("Lost Interest", forKey: "selectedMangaCategory")
            default:
                break
            }
        }) {
            Text("See More")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    // Function to get top ranked anime (all statuses EXCEPT want to watch)
    // Function to get top ranked anime (using rank order from ranking tab)
    func getTopRankedAnime() -> [RankingItem] {
        // Combine all relevant lists (excluding Want to Watch)
        var allAnime = [RankingItem]()
        
        // Add completed anime
        allAnime.append(contentsOf: rankingManager.rankedAnime)
        
        // Add currently watching
        allAnime.append(contentsOf: rankingManager.currentlyWatching)
        
        // Add on hold
        allAnime.append(contentsOf: rankingManager.onHoldAnime)
        
        // Add dropped/lost interest
        allAnime.append(contentsOf: rankingManager.lostInterestAnime)
        
        // First filter out any items with rank = 0 (unranked)
        let rankedItems = allAnime.filter { $0.rank > 0 }
        
        // If we have ranked items, sort by rank
        if !rankedItems.isEmpty {
            return rankedItems.sorted { $0.rank < $1.rank }
        }
        
        // Fallback: sort by score if no items have ranks
        return allAnime.sorted { $0.score > $1.score }
    }

    // Function to get top ranked manga (using rank order from ranking tab)
    func getTopRankedManga() -> [RankingItem] {
        // Combine all relevant lists (excluding Want to Read)
        var allManga = [RankingItem]()
        
        // Add completed manga
        allManga.append(contentsOf: rankingManager.rankedManga)
        
        // Add currently reading
        allManga.append(contentsOf: rankingManager.currentlyReading)
        
        // Add on hold
        allManga.append(contentsOf: rankingManager.onHoldManga)
        
        // Add dropped/lost interest
        allManga.append(contentsOf: rankingManager.lostInterestManga)
        
        // First filter out any items with rank = 0 (unranked)
        let rankedItems = allManga.filter { $0.rank > 0 }
        
        // If we have ranked items, sort by rank
        if !rankedItems.isEmpty {
            return rankedItems.sorted { $0.rank < $1.rank }
        }
        
        // Fallback: sort by score if no items have ranks
        return allManga.sorted { $0.score > $1.score }
    }

    // Helper to prioritize statuses
    func getStatusPriority(_ status: String) -> Int {
        let lowercasedStatus = status.lowercased()
        
        if lowercasedStatus.contains("completed") {
            return 1
        } else if lowercasedStatus.contains("watching") || lowercasedStatus.contains("reading") {
            return 2
        } else if lowercasedStatus.contains("hold") {
            return 3
        } else if lowercasedStatus.contains("want") {
            return 4
        } else if lowercasedStatus.contains("lost") || lowercasedStatus.contains("dropped") {
            return 5
        }
        
        return 6 // Unknown status
    }
    
    // Get user status for an item
    private func getUserStatus(isAnime: Bool, id: Int) -> String {
        if isAnime {
            // Check each anime list
            if rankingManager.currentlyWatching.contains(where: { $0.id == id }) {
                return "Currently Watching"
            } else if rankingManager.rankedAnime.contains(where: { $0.id == id }) {
                return "Completed"
            } else if rankingManager.wantToWatch.contains(where: { $0.id == id }) {
                return "Want to Watch"
            } else if rankingManager.onHoldAnime.contains(where: { $0.id == id }) {
                return "On Hold"
            } else if rankingManager.lostInterestAnime.contains(where: { $0.id == id }) {
                return "Lost Interest"
            }
        } else {
            // Check each manga list
            if rankingManager.currentlyReading.contains(where: { $0.id == id }) {
                return "Currently Reading"
            } else if rankingManager.rankedManga.contains(where: { $0.id == id }) {
                return "Completed"
            } else if rankingManager.wantToRead.contains(where: { $0.id == id }) {
                return "Want to Read"
            } else if rankingManager.onHoldManga.contains(where: { $0.id == id }) {
                return "On Hold"
            } else if rankingManager.lostInterestManga.contains(where: { $0.id == id }) {
                return "Lost Interest"
            }
        }
        
        return "" // This shouldn't happen for items on home screen
    }
    
    // Format user status for display (shorter versions)
    private func formatUserStatus(_ status: String) -> String {
        switch status {
        case "Currently Watching":
            return "Watching"
        case "Currently Reading":
            return "Reading"
        case "Want to Watch":
            return "Want to Watch"
        case "Want to Read":
            return "Want to Read"
        case "Lost Interest":
            return "Dropped"
        default:
            return status
        }
    }
    
    // Helper function to determine status color
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "Currently Watching", "Currently Reading", "Watching", "Reading":
            return .blue
        case "Want to Watch", "Want to Read":
            return .orange
        case "On Hold":
            return .yellow
        case "Lost Interest", "Dropped":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(TabSelectionState())
}
