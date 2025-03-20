import SwiftUI
import CoreData

struct PairwiseRankingView: View {
    @EnvironmentObject var rankingManager: RankingManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    @State internal var pairIndex = 0
    @State internal var totalPairs = 0
    @State private var completedPairs = 0
    @State private var isProcessingResult = false
    @State private var showCancelAlert = false
    @State private var showingResults = false
    @State private var showAnimations = true
    @State private var showFinalResult = false
    @State private var isLoading = true
    
    var category: String
    var isCharacterRanking: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    // State for UI updates
    @State private var animation1Active = false
    @State private var animation2Active = false
    
    // State for image refresh
    @State private var leftItemImage: UIImage? = nil
    @State private var rightItemImage: UIImage? = nil
    
    // States for knockout animation
    @State private var leftWinnerAnimation = false
    @State private var rightWinnerAnimation = false
    @State private var leftLoserAnimation = false
    @State private var rightLoserAnimation = false
    @State private var processingAnimation = false
    
    // Animation completion handler
    @State private var animationComplete = false
    
    // State for character ranking
    @State private var favoriteCharacters: [Int] = []
    
    // States for recovery
    @State private var isRecovering = false
    @State private var recoveryMessage = ""
    
    // Replace the regular @State property with @AppStorage
    @AppStorage("characterRankings") private var rankingsData: Data = Data()
    
    // Keep this as @State since it's used for UI updates
    @State private var rankings: [Character] = []
    
    // Add AppStorage for anime and manga rankings
    @AppStorage("animeRankings") private var animeRankingsData: Data = Data()
    @AppStorage("mangaRankings") private var mangaRankingsData: Data = Data()
    
    // State properties for each type
    @State private var animeRankings: [RankingItem] = []
    @State private var mangaRankings: [RankingItem] = []
    @State private var characterRankings: [Character] = []
    
    var body: some View {
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
            
            VStack(spacing: 20) {
                if rankingManager.pairwiseCompleted {
                    // Show completion message
                    completionView
                } else if !rankingManager.pairwiseComparison.isEmpty &&
                          rankingManager.currentPairIndex < rankingManager.pairwiseComparison.count {
                    // Show comparison view
                    pairComparisonView
                } else {
                    // Fallback if no pairs
                    Text("No items to compare.")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Head-to-Head")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Cancel pairwise ranking
                        rankingManager.pairwiseComparison = []
                        rankingManager.currentPairIndex = 0
                        rankingManager.isPairwiseRankingActive = false
                        rankingManager.pairwiseCompleted = false
                        rankingManager.activeRankingCategory = ""
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                // Check if we need to initialize from storage
                loadInitialState()
                
                // Update UI state
                pairIndex = rankingManager.currentPairIndex
                totalPairs = rankingManager.pairwiseComparison.count
                
                // If it's character ranking, load favorite character IDs
                if isCharacterRanking {
                    loadFavoriteCharacterIds()
                }
                
                // Preload the first pair of images
                if let currentPair = getCurrentPair() {
                    loadDirectImages(currentPair.0, currentPair.1)
                    prefetchNextPairImages()
                }
                
                loadRankings()
                
                // If we have saved rankings, restore them based on category
                if category == "Anime" && !animeRankings.isEmpty {
                    rankingManager.rankedAnime = animeRankings
                } else if category == "Manga" && !mangaRankings.isEmpty {
                    rankingManager.rankedManga = mangaRankings
                } else if category == "Characters" && !characterRankings.isEmpty {
                    // Handle character rankings as before
                }
            }
        }
    }
    
    // View shown when all comparisons are completed
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Ranking Complete!")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text("Your \(category.lowercased()) have been ranked based on your preferences.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                // Save rankings before dismissing
                if isCharacterRanking {
                    saveCharacterRankings()
                } else {
                    rankingManager.persistRankingResults()
                    
                    // Also explicitly clear the active session
                    UserDefaults.standard.set(false, forKey: "hasSavedRankingSession")
                }
                
                // Double-check all data was saved
                verifyAllDataSaved()
                
                // Dismiss the view
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("View Rankings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 30)
    }
    
    // View for comparing two items
    private var pairComparisonView: some View {
        VStack(spacing: 25) {
            // Progress indicator
            progressView
            
            // Instructions
            Text("Which one do you prefer?")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            // Get the current pair
            if let currentPair = getCurrentPair() {
                // Comparison cards
                HStack(spacing: 20) {
                    // First item card - using direct image loading
                    directImageCard(item: currentPair.0, image: leftItemImage)
                        .scaleEffect(animation1Active ? 1.05 : 1.0)
                        .shadow(color: animation1Active ? .blue.opacity(0.6) : .clear, radius: animation1Active ? 10 : 0)
                        // Winner animation: move right to bump opponent
                        .offset(x: leftWinnerAnimation ? 90 : 0)
                        // Loser animation: fly off screen (left side) with card rotation
                        .offset(x: leftLoserAnimation ? -UIScreen.main.bounds.width : 0)
                        .rotation3DEffect(
                            Angle(degrees: leftLoserAnimation ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0) // Rotate around Y axis (horizontal spin)
                        )
                        // Animations
                        .animation(.easeInOut(duration: 0.2), value: animation1Active)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: leftWinnerAnimation)
                        .animation(.easeOut(duration: 0.6), value: leftLoserAnimation)
                        .onTapGesture {
                            if !processingAnimation {
                                handleComparison(winner: currentPair.0, loser: currentPair.1)
                            }
                        }
                    
                    Text("VS")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .opacity(processingAnimation ? 0 : 1) // Hide during animation
                        .animation(.easeOut(duration: 0.2), value: processingAnimation)
                    
                    // Second item card - using direct image loading
                    directImageCard(item: currentPair.1, image: rightItemImage)
                        .scaleEffect(animation2Active ? 1.05 : 1.0)
                        .shadow(color: animation2Active ? .blue.opacity(0.6) : .clear, radius: animation2Active ? 10 : 0)
                        // Winner animation: move left to bump opponent
                        .offset(x: rightWinnerAnimation ? -90 : 0)
                        // Loser animation: fly off screen (right side) with card rotation
                        .offset(x: rightLoserAnimation ? UIScreen.main.bounds.width : 0)
                        .rotation3DEffect(
                            Angle(degrees: rightLoserAnimation ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0) // Rotate around Y axis (horizontal spin)
                        )
                        // Animations
                        .animation(.easeInOut(duration: 0.2), value: animation2Active)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rightWinnerAnimation)
                        .animation(.easeOut(duration: 0.6), value: rightLoserAnimation)
                        .onTapGesture {
                            if !processingAnimation {
                                handleComparison(winner: currentPair.1, loser: currentPair.0)
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            
            // Add Save for Later button
            Button(action: {
                rankingManager.saveRankingSession()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save Progress for Later")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(8)
            }
            .padding(.top, 10)
            .opacity(processingAnimation ? 0 : 1) // Hide during animation
            
            // Skip button
            Button(action: {
                if !processingAnimation, let currentPair = getCurrentPair() {
                    // For skip, we'll record a tie (no preference)
                    // Randomly select a winner to maintain the algorithm
                    if Bool.random() {
                        handleComparison(winner: currentPair.0, loser: currentPair.1)
                    } else {
                        handleComparison(winner: currentPair.1, loser: currentPair.0)
                    }
                    pairIndex = rankingManager.currentPairIndex
                    
                    // Preload next pair of images
                    if let nextPair = getCurrentPair() {
                        loadDirectImages(nextPair.0, nextPair.1)
                        prefetchNextPairImages()
                    }
                }
            }) {
                Text("Skip This Comparison")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
            .padding(.top, 10)
            .opacity(processingAnimation ? 0 : 1) // Hide during animation
        }
    }
    
    // Handler for item selection with animations
    private func handleComparison(winner: RankingItem, loser: RankingItem) {
        isProcessingResult = true
        
        // Use the coordinator from its own file now
        PairwiseRankingCoordinator.shared.recordPairwiseResult(winner: winner, loser: loser) { success in
            if success {
                completedPairs += 1
                pairIndex = rankingManager.currentPairIndex
                
                if pairIndex >= totalPairs {
                    // Completed all pairs
                    rankingManager.isPairwiseRankingActive = false
                    rankingManager.pairwiseCompleted = true
                    
                    // Verify all rankings were saved
                    verifyAllDataSaved()
                    
                    // Show results
                    showingResults = true
                } else {
                    // Move to next pair
                    isProcessingResult = false
                }
            } else {
                // Handle error
                isProcessingResult = false
            }
        }
    }
    
    // Direct image loading card that doesn't use CachedAsyncImage
    private func directImageCard(item: RankingItem, image: UIImage?) -> some View {
        VStack {
            if let uiImage = image {
                // Display the pre-loaded image
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 160)
                    .clipped()
                    .cornerRadius(8)
                    .padding(.top, 30)
                
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 30)
                    .frame(height: 50)
            } else {
                // Placeholder while loading
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 160)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
        .frame(width: 140, height: 220)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
    
    // Progress indicator view
    private var progressView: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress fill
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: calculateProgress(totalWidth: geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            // Progress text
            Text("\(pairIndex)/\(totalPairs) comparisons")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // Helper function to load images directly from URLs
    private func loadDirectImages(_ leftItem: RankingItem, _ rightItem: RankingItem) {
        // Reset images first
        leftItemImage = nil
        rightItemImage = nil
        
        // Load the left image from cache or network
        if let url = URL(string: leftItem.coverImage) {
            PairwiseImageCache.shared.getImage(for: url) { image in
                if image != nil {
                    self.leftItemImage = image
                }
            }
        }
        
        // Load the right image from cache or network
        if let url = URL(string: rightItem.coverImage) {
            PairwiseImageCache.shared.getImage(for: url) { image in
                if image != nil {
                    self.rightItemImage = image
                }
            }
        }
    }
    
    // Helper function to get current pair
    private func getCurrentPair() -> (RankingItem, RankingItem)? {
        if rankingManager.currentPairIndex < rankingManager.pairwiseComparison.count {
            return rankingManager.pairwiseComparison[rankingManager.currentPairIndex]
        }
        return nil
    }
    
    // Helper function to calculate progress bar width
    private func calculateProgress(totalWidth: CGFloat) -> CGFloat {
        if totalPairs == 0 { return 0 }
        let progress = CGFloat(pairIndex) / CGFloat(totalPairs)
        return totalWidth * progress
    }
    
    // MARK: - Character Ranking Methods
    
    // Load favorite character IDs from UserDefaults
    private func loadFavoriteCharacterIds() {
        guard let data = UserDefaults.standard.data(forKey: "favoriteCharacters") else { return }
        
        do {
            favoriteCharacters = try JSONDecoder().decode([Int].self, from: data)
        } catch {
            print("Error decoding favorite characters: \(error)")
        }
    }
    
    // Save character rankings to UserDefaults
    private func saveCharacterRankings() {
        // Create win count map for quick lookup
        var winCountMap: [Int: Int] = [:]
        for (id, wins) in rankingManager.winCounts {
            winCountMap[id] = wins
        }
        
        // Get characters from the ranking manager
        let characterItems = rankingManager.pairwiseComparison.flatMap { [$0.0, $0.1] }
        
        // 1. First get all character IDs
        let allCharacterIds = characterItems.map { $0.id }
        // 2. Then create a Set to get unique IDs
        let uniqueCharacterIds = Set(allCharacterIds)
        // 3. Convert back to Array
        let uniqueIdArray = Array(uniqueCharacterIds)
        // 4. Finally do the compactMap
        let uniqueCharacters = uniqueIdArray.compactMap { id -> Character? in
            if let item = characterItems.first(where: { $0.id == id }) {
                return Character(
                    id: item.id,
                    name: CharacterName(full: item.title, first: "", last: "", native: ""),
                    image: CharacterImage(medium: item.coverImage, large: item.coverImage)
                )
            }
            return nil
        }
        
        // Sort by win count
        let sortedCharacters = uniqueCharacters.sorted { 
            (winCountMap[$0.id] ?? 0) > (winCountMap[$1.id] ?? 0) 
        }
        
        // Update both local state and AppStorage
        rankings = sortedCharacters
        
        if let encoded = try? JSONEncoder().encode(sortedCharacters) {
            rankingsData = encoded
            print("✅ Saved character rankings to UserDefaults")
            
            // Write to a second location for extra safety
            UserDefaults.standard.set(encoded, forKey: "characterRankingsBackup")
        }
        
        // Also print debugging info
        print("📊 Character ranking summary:")
        for (index, character) in sortedCharacters.prefix(5).enumerated() {
            print("  #\(index+1): \(character.name.full) - \(winCountMap[character.id] ?? 0) wins")
        }
    }
    
    // MARK: - Anime/Manga Ranking Methods
    
    // Helper method to update anime rankings based on win counts
    private func updateAnimeRankings() {
        // Get all items that were part of the ranking
        let itemsToRank = rankingManager.rankedAnime.filter { item in
            // Check if this item was involved in comparisons
            return rankingManager.pairwiseComparison.contains { pair in
                return pair.0.id == item.id || pair.1.id == item.id
            }
        }
        
        // Create a win count map for quick lookup
        var winCountMap: [Int: Int] = [:]
        for (id, wins) in rankingManager.winCounts {
            winCountMap[id] = wins
        }
        
        // Sort items by win count (descending)
        var sortedItems = itemsToRank.sorted { (a, b) -> Bool in
            let aWins = winCountMap[a.id] ?? 0
            let bWins = winCountMap[b.id] ?? 0
            return aWins > bWins
        }
        
        // Update ranks based on win count order
        for (index, item) in sortedItems.enumerated() {
            let newRank = index + 1
            
            // Update the rank in the sorted items array
            sortedItems[index] = RankingItem(
                id: item.id,
                title: item.title,
                coverImage: item.coverImage,
                status: item.status,
                isAnime: item.isAnime,
                rank: newRank,
                score: item.score,
                startDate: item.startDate,
                endDate: item.endDate,
                isRewatch: item.isRewatch,
                rewatchCount: item.rewatchCount,
                progress: item.progress,
                summary: item.summary,
                genres: item.genres
            )
        }
        
        // First update in-memory ranked anime array
        rankingManager.rankedAnime = sortedItems
        
        // Now persist everything to CoreData in a single context
        let context = rankingManager.coreDataManager.container.viewContext
        
        for item in sortedItems {
            let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %lld AND isAnime == YES", Int64(item.id))
            
            do {
                let results = try context.fetch(fetchRequest)
                if let animeItem = results.first {
                    animeItem.rank = Int16(item.rank)
                    if item.score > 0 {
                        animeItem.score = Int16(item.score)
                    }
                    print("✅ Updated rank for \(item.title) to #\(item.rank)")
                }
            } catch {
                print("❌ Error updating anime rank: \(error)")
            }
        }
        
        // Save all changes to CoreData in one operation
        do {
            try context.save()
            print("✅ Successfully saved all anime ranking changes")
            
            // Also save to AppStorage for redundancy
            if let encoded = try? JSONEncoder().encode(sortedItems) {
                animeRankingsData = encoded
            }
        } catch {
            print("❌ Error saving context after anime ranking: \(error)")
        }
    }
    
    // Helper method to update manga rankings based on win counts
    private func updateMangaRankings() {
        // Get all items that were part of the ranking
        let itemsToRank = rankingManager.rankedManga.filter { item in
            // Check if this item was involved in comparisons
            return rankingManager.pairwiseComparison.contains { pair in
                return pair.0.id == item.id || pair.1.id == item.id
            }
        }
        
        // Create a win count map for quick lookup
        var winCountMap: [Int: Int] = [:]
        for (id, wins) in rankingManager.winCounts {
            winCountMap[id] = wins
        }
        
        // Sort items by win count (descending)
        var sortedItems = itemsToRank.sorted { (a, b) -> Bool in
            let aWins = winCountMap[a.id] ?? 0
            let bWins = winCountMap[b.id] ?? 0
            return aWins > bWins
        }
        
        // Update ranks based on win count order
        for (index, item) in sortedItems.enumerated() {
            let newRank = index + 1
            
            // Update the rank in the sorted items array
            sortedItems[index] = RankingItem(
                id: item.id,
                title: item.title,
                coverImage: item.coverImage,
                status: item.status,
                isAnime: item.isAnime,
                rank: newRank,
                score: item.score,
                startDate: item.startDate,
                endDate: item.endDate,
                isRewatch: item.isRewatch,
                rewatchCount: item.rewatchCount,
                progress: item.progress,
                summary: item.summary,
                genres: item.genres
            )
        }
        
        // First update in-memory ranked manga array
        rankingManager.rankedManga = sortedItems
        
        // Now persist everything to CoreData in a single context
        let context = rankingManager.coreDataManager.container.viewContext
        
        for item in sortedItems {
            let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %lld AND isAnime == NO", Int64(item.id))
            
            do {
                let results = try context.fetch(fetchRequest)
                if let mangaItem = results.first {
                    mangaItem.rank = Int16(item.rank)
                    if item.score > 0 {
                        mangaItem.score = Int16(item.score)
                    }
                    print("✅ Updated rank for \(item.title) to #\(item.rank)")
                }
            } catch {
                print("❌ Error updating manga rank: \(error)")
            }
        }
        
        // Save all changes to CoreData in one operation
        do {
            try context.save()
            print("✅ Successfully saved all manga ranking changes")
            
            // Also save to AppStorage for redundancy
            if let encoded = try? JSONEncoder().encode(sortedItems) {
                mangaRankingsData = encoded
            }
        } catch {
            print("❌ Error saving context after manga ranking: \(error)")
        }
    }
    
    private func prefetchNextPairImages() {
        // Get the index of the next pair
        let nextIndex = rankingManager.currentPairIndex + 1
        
        // Make sure the next pair exists
        if nextIndex < rankingManager.pairwiseComparison.count {
            let nextPair = rankingManager.pairwiseComparison[nextIndex]
            
            // Prefetch left image
            if let url = URL(string: nextPair.0.coverImage) {
                PairwiseImageCache.shared.getImage(for: url) { _ in }
            }
            
            // Prefetch right image
            if let url = URL(string: nextPair.1.coverImage) {
                PairwiseImageCache.shared.getImage(for: url) { _ in }
            }
        }
    }
    
    private func loadRankings() {
        // Load anime rankings
        if let decodedAnime = try? JSONDecoder().decode([RankingItem].self, from: animeRankingsData) {
            animeRankings = decodedAnime
        }
        
        // Load manga rankings
        if let decodedManga = try? JSONDecoder().decode([RankingItem].self, from: mangaRankingsData) {
            mangaRankings = decodedManga
        }
        
        // Load character rankings
        if let decodedCharacters = try? JSONDecoder().decode([Character].self, from: rankingsData) {
            characterRankings = decodedCharacters
        }
    }
    
    private func saveRankings() {
        if let encoded = try? JSONEncoder().encode(rankings) {
            rankingsData = encoded
        }
    }
    
    private func updateRankings(winner: Character, loser: Character) {
        // existing ranking update logic...
        
        // Add this line after rankings are updated
        saveRankings()
    }
    
    // Add this method for consistent initialization
    private func loadInitialState() {
        if rankingManager.hasSavedRankingSession &&
           rankingManager.savedRankingCategory == category &&
           rankingManager.savedPairwiseComparison.isEmpty &&
           rankingManager.pairwiseComparison.isEmpty {
            
            print("🔄 Attempting to recover pairwise ranking session...")
            
            // Force a reload from UserDefaults
            rankingManager.loadFromPersistentStorage()
            
            // If we successfully recovered the session
            // ... (rest of the method remains unchanged)
        }
    }
    
    // Add verification method
    private func verifyAllDataSaved() {
        if isCharacterRanking {
            // Verify character rankings were saved
            if let data = UserDefaults.standard.data(forKey: "characterRankingsBackup"),
               let decoded = try? JSONDecoder().decode([Character].self, from: data) {
                print("✅ Verified character rankings save: \(decoded.count) characters saved")
            } else {
                print("⚠️ Character rankings verification failed")
            }
        } else {
            // Verify anime/manga rankings
            let category = rankingManager.activeRankingCategory
            let context = rankingManager.coreDataManager.container.viewContext
            
            let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isAnime == %@", category == "Anime")
            
            do {
                let results = try context.fetch(fetchRequest)
                print("✅ Verified \(category) rankings save: \(results.count) items in CoreData")
            } catch {
                print("⚠️ \(category) rankings verification failed: \(error)")
            }
        }
    }
    
    internal func getPairIndex() -> Int {
        return pairIndex
    }
    
    internal func getTotalPairs() -> Int {
        return totalPairs
    }
    
    internal func setPairIndex(_ value: Int) {
        pairIndex = value
    }
    
    internal func setTotalPairs(_ value: Int) {
        totalPairs = value
    }
}

// Extension for additional view components
extension PairwiseRankingView {
    // These can now access private properties
    var progressText: some View {
        Text("\(pairIndex + 1) of \(totalPairs)")
            .font(.caption)
            .foregroundColor(.gray)
    }
    
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 4)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: geometry.size.width * (totalPairs > 0 ? Double(pairIndex) / Double(totalPairs) : 0), height: 4)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct PairwiseRankingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PairwiseRankingView(category: "Anime", isCharacterRanking: false)
                .environmentObject(RankingManager.shared)
                .environmentObject(NetworkMonitor())
        }
    }
}
