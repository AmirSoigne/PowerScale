import SwiftUI

struct RankingView: View {
    @ObservedObject var rankingManager = RankingManager.shared
    @State private var selectedCategory = "Anime"
    @State private var showingPairwiseRanking = false
    @State private var showingNoItemsAlert = false
    @ObservedObject private var profileManager = ProfileManager.shared
    
    // State for characters tab
    @AppStorage("favoriteCharacters") private var favoriteCharactersData: Data = Data()
    @State private var favoriteCharacters: [CharacterItem] = []
    @State private var isLoadingCharacters = false
    
    // Simple model to represent character items
    struct CharacterItem: Identifiable {
        let id: Int
        let name: String
        let imageURL: String
        
        // Default initializer
        init(id: Int, name: String, imageURL: String) {
            self.id = id
            self.name = name
            self.imageURL = imageURL
        }
        
        // Initialize from CharacterDetail
        init(from detail: CharacterDetail) {
            self.id = detail.id
            self.name = detail.name.full
            self.imageURL = detail.image?.medium ?? ""
        }
    }

    private let categories = ["Anime", "Manga", "Characters"]

    private var allAnimeItems: [RankingItem] {
        (rankingManager.currentlyWatching +
        rankingManager.rankedAnime +
        rankingManager.onHoldAnime +
        rankingManager.lostInterestAnime)
        .sorted(by: { $0.rank < $1.rank || ($0.rank == $1.rank && $0.title < $1.title) })
    }

    private var allMangaItems: [RankingItem] {
        (rankingManager.currentlyReading +
        rankingManager.rankedManga +
        rankingManager.onHoldManga +
        rankingManager.lostInterestManga)
        .sorted(by: { $0.rank < $1.rank || ($0.rank == $1.rank && $0.title < $1.title) })
    }

    var body: some View {
        NavigationView {
            ZStack {
                Image("bg2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.3)
                    .blur(radius: 5)

                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCategory = category
                                    
                                    // Load characters when selecting the Characters tab
                                    if category == "Characters" && favoriteCharacters.isEmpty {
                                        loadFavoriteCharacters()
                                    }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(category)
                                        .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                                        .foregroundColor(selectedCategory == category ? .white : .gray)

                                    Rectangle()
                                        .fill(selectedCategory == category ? Color.blue : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.black.opacity(0.4))
                    .padding(.top, 10)

                    // Head-to-Head ranking button - now available for all categories
                    Button(action: {
                        if selectedCategory == "Characters" {
                            // Only proceed if we have at least 2 characters
                            if favoriteCharacters.count >= 2 {
                                // Set up character ranking
                                setupCharacterRanking()
                                showingPairwiseRanking = true
                            } else {
                                showingNoItemsAlert = true
                            }
                        } else {
                            // Existing anime/manga ranking code
                            let itemsToRank = selectedCategory == "Anime" ? allAnimeItems : allMangaItems
                            if itemsToRank.count >= 2 {
                                rankingManager.activeRankingCategory = selectedCategory
                                rankingManager.winCounts.removeAll()
                                rankingManager.pairwiseComparison = generateOptimizedPairs(from: itemsToRank)
                                rankingManager.currentPairIndex = 0
                                rankingManager.isPairwiseRankingActive = true
                                rankingManager.pairwiseCompleted = false

                                showingPairwiseRanking = true
                            } else {
                                showingNoItemsAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 14))
                            Text("Start Head-to-Head Ranking")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .frame(width: 280)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    
                    // Add Resume Saved Ranking button - only for Anime & Manga for now
                    if selectedCategory != "Characters" && rankingManager.hasSavedRankingSession &&
                       rankingManager.savedRankingCategory == selectedCategory &&
                       !rankingManager.pairwiseCompleted &&
                       rankingManager.savedCurrentPairIndex > 0 &&
                       !rankingManager.savedPairwiseComparison.isEmpty {
                        Button(action: {
                            rankingManager.resumeSavedSession()
                            showingPairwiseRanking = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                Text("Resume Saved Ranking")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .padding(.top, -10)
                    }
                    
                    // Content List - conditionally display based on selected category
                    if selectedCategory == "Characters" {
                        // Character content
                        characterContentView
                    } else {
                        // Original list for Anime and Manga
                        List {
                            let items = selectedCategory == "Anime" ? allAnimeItems : allMangaItems
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                NavigationLink(destination: AnimeDetailView(anime: item.toAnime(), isAnime: selectedCategory == "Anime")) {
                                    HStack(spacing: 12) {
                                        // Medal for top 3 ranks, regular circle for others
                                        if index == 0 {
                                            // Gold medal
                                            ZStack {
                                                Circle()
                                                    .fill(Color.yellow)
                                                    .frame(width: 25, height: 25)
                                                
                                                Image(systemName: "medal.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                            }
                                        } else if index == 1 {
                                            // Silver medal
                                            ZStack {
                                                Circle()
                                                    .fill(Color(white: 0.8))
                                                    .frame(width: 25, height: 25)
                                                
                                                Image(systemName: "medal.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                            }
                                        } else if index == 2 {
                                            // Bronze medal
                                            ZStack {
                                                Circle()
                                                    .fill(Color(red: 0.8, green: 0.5, blue: 0.2))
                                                    .frame(width: 25, height: 25)
                                                
                                                Image(systemName: "medal.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                            }
                                        } else {
                                            // Regular rank number
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 25, height: 25)
                                                
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        // Anime cover image
                                        CachedAsyncImage(urlString: item.coverImage) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 80)
                                                .cornerRadius(6)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 60, height: 80)
                                                .cornerRadius(6)
                                        }
                                        
                                        // Title and status with consistent colors
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(maxWidth: 180, alignment: .leading)
                                            
                                            Text(item.status)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(statusColor(item.status).opacity(0.3))
                                                .cornerRadius(3)
                                            
                                            // New: Display the Composite Score
                                            Text("Composite Score: \(String(format: "%.1f", item.compositeScore))")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))

                                        }
                                        
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(Color.black.opacity(0.5))
                                .listRowInsets(EdgeInsets(top: 6, leading: 35, bottom: 6, trailing: 20))
                            }
                            .onMove { indices, destination in
                                rankingManager.moveItem(from: indices, to: destination, in: selectedCategory)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal, 0)
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: EditButton())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingPairwiseRanking) {
                PairwiseRankingView(rankingManager: rankingManager, category: selectedCategory)
            }
            .alert("Not Enough Items", isPresented: $showingNoItemsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You need at least 2 items to start a head-to-head ranking.")
            }
            .onAppear {
                // If we're already on the Characters tab, load the character data
                if selectedCategory == "Characters" && favoriteCharacters.isEmpty {
                    loadFavoriteCharacters()
                }
            }
        }
        .accentColor(profileManager.currentProfile.getThemeColor())
        // Add this global listener to update when showing the Characters tab
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FavoriteCharactersChanged"))) { _ in
            if selectedCategory == "Characters" {
                loadFavoriteCharacters()
            }
        }
    }
    
    // MARK: - Character Content View
    
    private var characterContentView: some View {
        Group {
            if isLoadingCharacters {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Loading your favorite characters...")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if favoriteCharacters.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Favorite Characters")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Find characters you like and tap the heart button to add them here")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Display the favorite characters
                List {
                    ForEach(Array(favoriteCharacters.enumerated()), id: \.element.id) { index, character in
                        NavigationLink(destination: CharacterDetailView(
                            characterId: character.id,
                            characterName: character.name,
                            imageURL: character.imageURL
                        )) {
                            HStack(spacing: 12) {
                                // Rank indicator - smaller with adjusted sizes
                                ZStack {
                                    Circle()
                                        .fill(Color.red) // Red for characters to differentiate
                                        .frame(width: 25, height: 25) // Smaller circle
                                    
                                    // Use a heart icon instead of number for characters
                                    if index == 0 {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 12)) // Smaller heart
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .medium)) // Smaller text
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Character image
                                CachedAsyncImage(urlString: character.imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 80)
                                        .cornerRadius(6)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 80)
                                        .cornerRadius(6)
                                }
                                
                                // Character name
                                Text(character.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.black.opacity(0.5))
                        .listRowInsets(EdgeInsets(top: 6, leading: 35, bottom: 6, trailing: 20))
                    }
                    .onDelete { indexSet in
                        removeCharacters(at: indexSet)
                    }
                    .onMove { indices, destination in
                        favoriteCharacters.move(fromOffsets: indices, toOffset: destination)
                        saveCharacterOrder()
                    }
                }
                .listStyle(PlainListStyle())
                .padding(.horizontal, 5)
            }
        }
        // Listen for both notifications to update character list
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FavoriteCharactersChanged"))) { _ in
            // Reload character data when favorites change
            print("📣 Received notification: FavoriteCharactersChanged")
            loadFavoriteCharacters()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CharacterOrderChanged"))) { _ in
            // Reload character data when the order has changed
            print("📣 Received notification: CharacterOrderChanged")
            loadFavoriteCharacters()
        }
    }
    
    // MARK: - Character Management
    
    // Load favorite characters
    private func loadFavoriteCharacters() {
        isLoadingCharacters = true
        favoriteCharacters = []
        
        // Get the list of favorite character IDs - this determines the order!
        let favoriteIds = getFavoriteCharacterIds()
        if favoriteIds.isEmpty {
            isLoadingCharacters = false
            return
        }
        
        // Set up a dispatch group to track all API calls
        let group = DispatchGroup()
        var loadedCharacters: [CharacterItem] = []
        
        // Load each character
        for characterId in favoriteIds {
            group.enter()
            
            AniListAPI.shared.getCharacterDetails(id: characterId) { character in
                if let character = character {
                    let characterItem = CharacterItem(
                        id: character.id,
                        name: character.name.full,
                        imageURL: character.image?.medium ?? ""
                    )
                    loadedCharacters.append(characterItem)
                }
                group.leave()
            }
        }
        
        // When all characters are loaded
        group.notify(queue: .main) {
            // This is the key change - sort the characters to match the order in favoriteIds
            self.favoriteCharacters = favoriteIds.compactMap { id in
                loadedCharacters.first { $0.id == id }
            }
            self.isLoadingCharacters = false
        }
    }
    
    // Get the list of favorite character IDs
    private func getFavoriteCharacterIds() -> [Int] {
        guard !favoriteCharactersData.isEmpty else { return [] }
        
        do {
            return try JSONDecoder().decode([Int].self, from: favoriteCharactersData)
        } catch {
            print("Error decoding favorite characters: \(error)")
            return []
        }
    }
    
    // Remove characters from favorites
    private func removeCharacters(at indexSet: IndexSet) {
        // Get the IDs to remove
        let idsToRemove = indexSet.map { favoriteCharacters[$0].id }
        
        // Remove from the UI list
        favoriteCharacters.remove(atOffsets: indexSet)
        
        // Update the persisted favorites
        var favoriteIds = getFavoriteCharacterIds()
        favoriteIds.removeAll { idsToRemove.contains($0) }
        saveFavoriteCharacterIds(favoriteIds)
    }
    
    // Save the current order of characters
    private func saveCharacterOrder() {
        // Save the character IDs in their current order
        let orderedIds = favoriteCharacters.map { $0.id }
        saveFavoriteCharacterIds(orderedIds)
    }
    
    // Save the list of favorite character IDs
    private func saveFavoriteCharacterIds(_ ids: [Int]) {
        do {
            let data = try JSONEncoder().encode(ids)
            favoriteCharactersData = data
        } catch {
            print("Error encoding favorite characters: \(error)")
        }
    }
    
    // Setup character ranking for head-to-head comparison
    private func setupCharacterRanking() {
        // Get the favorite character IDs
        let favoriteIds = getFavoriteCharacterIds()
        
        // Use the RankingManager's dedicated method
        rankingManager.setupCharacterRanking(characters: favoriteIds)
    }
    
    // MARK: - Pairwise Ranking methods
    
    // More efficient pair generation using a merge-sort inspired approach
    private func generateOptimizedPairs(from items: [RankingItem]) -> [(RankingItem, RankingItem)] {
        // If we have fewer than 2 items, no pairs to compare
        if items.count < 2 {
            return []
        }
        
        // Start with a shuffled copy of the items to ensure random initial order
        var itemsCopy = items.shuffled()
        
        // Initial sorted subarrays of size 1
        var sortedSubarrays: [[RankingItem]] = itemsCopy.map { [$0] }
        var pairs: [(RankingItem, RankingItem)] = []
        
        // Merge sorted subarrays until only one remains
        while sortedSubarrays.count > 1 {
            var newSortedSubarrays: [[RankingItem]] = []
            
            // Process pairs of sorted subarrays
            for i in stride(from: 0, to: sortedSubarrays.count - 1, by: 2) {
                // Generate pairs from the two sorted subarrays
                let newPairs = generateMergePairs(sortedSubarrays[i], sortedSubarrays[i + 1])
                pairs.append(contentsOf: newPairs.0)
                newSortedSubarrays.append(newPairs.1)
            }
            
            // Handle the case where we have an odd number of sorted subarrays
            if sortedSubarrays.count % 2 == 1 {
                newSortedSubarrays.append(sortedSubarrays.last!)
            }
            
            sortedSubarrays = newSortedSubarrays
        }
        
        return pairs
    }
    
    // Helper method to generate pairs for merging two sorted subarrays
    private func generateMergePairs(_ left: [RankingItem], _ right: [RankingItem]) -> ([(RankingItem, RankingItem)], [RankingItem]) {
        var pairs: [(RankingItem, RankingItem)] = []
        var mergedArray: [RankingItem] = []
        
        var i = 0, j = 0
        
        while i < left.count && j < right.count {
            // Create pair for comparison - this is what the user will see
            pairs.append((left[i], right[j]))
            
            // For the sake of generating remaining pairs, we'll assume left wins
            // The actual winner will be determined by user input
            mergedArray.append(left[i])
            i += 1
            
            // If we've processed all left items but still have right items
            if i == left.count && j < right.count {
                // Add all remaining right items
                mergedArray.append(contentsOf: right[j..<right.count])
                break
            }
            
            // If we've processed all right items but still have left items
            if j == right.count && i < left.count {
                // Add all remaining left items
                mergedArray.append(contentsOf: left[i..<left.count])
                break
            }
        }
        
        return (pairs, mergedArray)
    }
    
    // Legacy pair generation method (kept for reference)
    private func generateAllPairs(from items: [RankingItem]) -> [(RankingItem, RankingItem)] {
        var pairs: [(RankingItem, RankingItem)] = []
        for i in 0..<items.count {
            for j in i+1..<items.count {
                pairs.append((items[i], items[j]))
            }
        }
        return pairs.shuffled() // Shuffled to randomize comparisons
    }
    
    // Helper function for consistent status colors
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "currently watching", "currently reading":
            return .blue
        case "want to watch", "want to read":
            return .orange
        case "on hold":
            return .yellow
        case "lost interest", "dropped":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    RankingView()
}
