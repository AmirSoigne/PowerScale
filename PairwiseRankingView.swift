import SwiftUI
import CoreData

struct PairwiseRankingView: View {
    @ObservedObject var rankingManager: RankingManager
    var category: String
    @Environment(\.presentationMode) var presentationMode
    
    // State for UI updates
    @State private var pairIndex: Int = 0
    @State private var totalPairs: Int = 0
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
    @State private var isCharacterRanking = false
    @State private var favoriteCharacters: [Int] = []
    
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
                // Determine if this is character ranking
                isCharacterRanking = category == "Characters"
                
                // If it's character ranking, load favorite character IDs
                if isCharacterRanking {
                    loadFavoriteCharacterIds()
                }
                
                // Update state values when view appears
                pairIndex = rankingManager.currentPairIndex
                totalPairs = rankingManager.pairwiseComparison.count
                
                // Preload the first pair of images
                if let currentPair = getCurrentPair() {
                    loadDirectImages(currentPair.0, currentPair.1)
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
                // If it was character ranking, update character order in UserDefaults
                if isCharacterRanking {
                    saveCharacterRankings()
                }
                
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("View Rankings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
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
                                handleItemSelection(isLeftItem: true, winner: currentPair.0, loser: currentPair.1)
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
                                handleItemSelection(isLeftItem: false, winner: currentPair.1, loser: currentPair.0)
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
                        recordPairwiseResult(winner: currentPair.0, loser: currentPair.1)
                    } else {
                        recordPairwiseResult(winner: currentPair.1, loser: currentPair.0)
                    }
                    pairIndex = rankingManager.currentPairIndex
                    
                    // Preload next pair of images
                    if let nextPair = getCurrentPair() {
                        loadDirectImages(nextPair.0, nextPair.1)
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
    private func handleItemSelection(isLeftItem: Bool, winner: RankingItem, loser: RankingItem) {
        // Set the animation flag to prevent multiple taps
        processingAnimation = true
        
        // Start with highlight animation
        if isLeftItem {
            withAnimation { animation1Active = true }
        } else {
            withAnimation { animation2Active = true }
        }
        
        // Sequence of animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 1. Prepare for knockout - remove highlight
            withAnimation {
                animation1Active = false
                animation2Active = false
            }
            
            // 2. Animate winner moving toward loser
            if isLeftItem {
                leftWinnerAnimation = true
                // Delay for the loser animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 3. Animate loser getting knocked out
                    rightLoserAnimation = true
                    
                    // 4. Complete the animation sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        finishAnimationAndProceed(winner: winner, loser: loser)
                    }
                }
            } else {
                rightWinnerAnimation = true
                // Delay for the loser animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 3. Animate loser getting knocked out
                    leftLoserAnimation = true
                    
                    // 4. Complete the animation sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        finishAnimationAndProceed(winner: winner, loser: loser)
                    }
                }
            }
        }
    }
    
    // Helper function to finish the animation and move to next pair
    private func finishAnimationAndProceed(winner: RankingItem, loser: RankingItem) {
        // Record the result
        recordPairwiseResult(winner: winner, loser: loser)
        
        // Reset all animation states
        leftWinnerAnimation = false
        rightWinnerAnimation = false
        leftLoserAnimation = false
        rightLoserAnimation = false
        pairIndex = rankingManager.currentPairIndex
        
        // Preload next pair of images if available
        if let nextPair = getCurrentPair() {
            loadDirectImages(nextPair.0, nextPair.1)
        }
        
        // Allow new interactions
        processingAnimation = false
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
        
        // Load the left image directly
        if let url = URL(string: leftItem.coverImage) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.leftItemImage = image
                    }
                }
            }.resume()
        }
        
        // Load the right image directly
        if let url = URL(string: rightItem.coverImage) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.rightItemImage = image
                    }
                }
            }.resume()
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
    
    // Record the pairwise result
    private func recordPairwiseResult(winner: RankingItem, loser: RankingItem) {
        // Increment win count for the winner
        rankingManager.winCounts[winner.id] = (rankingManager.winCounts[winner.id] ?? 0) + 1
        
        // Update the current pair index
        rankingManager.currentPairIndex += 1
        
        // Check if we're done with all comparisons
        if rankingManager.currentPairIndex >= rankingManager.pairwiseComparison.count {
            // Finish the ranking process
            rankingManager.pairwiseCompleted = true
            
            // Handle completion by sorting and updating ranks
            if rankingManager.activeRankingCategory == "Anime" {
                updateAnimeRankings()
            } else if rankingManager.activeRankingCategory == "Manga" {
                updateMangaRankings()
            } else if rankingManager.activeRankingCategory == "Characters" {
                // No need to update anything here as we'll handle character rankings differently
                // when the user taps "View Rankings" in the completion view
            }
        }
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
        // Sort favoriteCharacters based on win counts
        favoriteCharacters.sort { (a, b) -> Bool in
            let aWins = rankingManager.winCounts[a] ?? 0
            let bWins = rankingManager.winCounts[b] ?? 0
            return aWins > bWins // Higher win count means better rank
        }
        
        // Save the sorted array back to UserDefaults
        do {
            let data = try JSONEncoder().encode(favoriteCharacters)
            UserDefaults.standard.set(data, forKey: "favoriteCharacters")
            
            // Post notification that character order has changed
            NotificationCenter.default.post(name: Notification.Name("CharacterOrderChanged"), object: nil)
        } catch {
            print("Error encoding favorite characters: \(error)")
        }
    }
    
    // MARK: - Anime/Manga Ranking Methods
    
    // Helper method to update anime rankings based on win counts
    private func updateAnimeRankings() {
        // First, collect all items to be ranked
        var itemsToRank = rankingManager.rankedAnime +
                         rankingManager.currentlyWatching +
                         rankingManager.onHoldAnime +
                         rankingManager.lostInterestAnime
        
        print("🏆 STARTING ANIME RANKING UPDATE")
        print("Total items to rank: \(itemsToRank.count)")
        
        // Create a map of ID to win count for easier access
        let winCountMap = rankingManager.winCounts
        print("Win counts: \(winCountMap)")
        
        // First sort items by their win count - this determines their new rank
        itemsToRank.sort { (a, b) -> Bool in
            let aWins = winCountMap[a.id] ?? 0
            let bWins = winCountMap[b.id] ?? 0
            return aWins > bWins // Higher win count means better rank
        }
        
        // Print the sorted items to verify
        print("🔄 ITEMS SORTED BY WIN COUNT:")
        for (index, item) in itemsToRank.enumerated() {
            print("Rank \(index+1): ID=\(item.id), Title=\(item.title), Wins=\(winCountMap[item.id] ?? 0)")
        }
        
        // Now we need to update the ranks in Core Data directly
        // This is the critical part - we'll only update the rank field
        // and leave everything else untouched
        let context = rankingManager.coreDataManager.container.viewContext
        
        // Get the current state of all anime items from Core Data
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAnime == YES")
        
        do {
            // Get all anime items from Core Data
            let allAnimeItems = try context.fetch(fetchRequest)
            print("📊 Found \(allAnimeItems.count) items in Core Data")
            
            // Create a dictionary for quick lookups by ID
            var animeItemsById = [Int64: AnimeItem]()
            for item in allAnimeItems {
                animeItemsById[item.id] = item
            }
            
            // Now update each item's rank based on its position in the sorted list
            for (index, rankedItem) in itemsToRank.enumerated() {
                let newRank = index + 1
                
                // Look up the Core Data item by ID
                if let coreDataItem = animeItemsById[Int64(rankedItem.id)] {
                    // Print before and after to verify the changes
                    print("Updating rank for: ID=\(coreDataItem.id), Title=\(coreDataItem.title ?? "Unknown")")
                    print("  Old rank: \(coreDataItem.rank), New rank: \(newRank)")
                    
                    // ONLY update the rank - nothing else
                    coreDataItem.rank = Int16(newRank)
                } else {
                    print("⚠️ Warning: Item not found in Core Data: ID=\(rankedItem.id)")
                }
            }
            
            // Save the changes
            try context.save()
            print("✅ Saved all rank updates to Core Data")
            
            // Now force a complete reload from Core Data
            rankingManager.loadAllDataFromCoreData()
            print("✅ Reloaded all data from Core Data")
            
        } catch {
            print("❌ Error updating ranks: \(error)")
        }
        
        // Mark the ranking process as complete
        rankingManager.pairwiseCompleted = true
        rankingManager.isPairwiseRankingActive = false
        
        // Clear win counts for next time
        rankingManager.winCounts.removeAll()
    }
    
    // Helper method to update manga rankings based on win counts
    private func updateMangaRankings() {
        // First, collect all items to be ranked
        var itemsToRank = rankingManager.rankedManga +
                          rankingManager.currentlyReading +
                          rankingManager.onHoldManga +
                          rankingManager.lostInterestManga
        
        print("🏆 STARTING MANGA RANKING UPDATE")
        print("Total items to rank: \(itemsToRank.count)")
        
        // Create a map of ID to win count for easier access
        let winCountMap = rankingManager.winCounts
        print("Win counts: \(winCountMap)")
        
        // First sort items by their win count - this determines their new rank
        itemsToRank.sort { (a, b) -> Bool in
            let aWins = winCountMap[a.id] ?? 0
            let bWins = winCountMap[b.id] ?? 0
            return aWins > bWins // Higher win count means better rank
        }
        
        // Print the sorted items to verify
        print("🔄 ITEMS SORTED BY WIN COUNT:")
        for (index, item) in itemsToRank.enumerated() {
            print("Rank \(index+1): ID=\(item.id), Title=\(item.title), Wins=\(winCountMap[item.id] ?? 0)")
        }
        
        // Now we need to update the ranks in Core Data directly
        // This is the critical part - we'll only update the rank field
        // and leave everything else untouched
        let context = rankingManager.coreDataManager.container.viewContext
        
        // Get the current state of all manga items from Core Data
        let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isAnime == NO")
        
        do {
            // Get all manga items from Core Data
            let allMangaItems = try context.fetch(fetchRequest)
            print("📊 Found \(allMangaItems.count) items in Core Data")
            
            // Create a dictionary for quick lookups by ID
            var mangaItemsById = [Int64: AnimeItem]()
            for item in allMangaItems {
                mangaItemsById[item.id] = item
            }
            
            // Now update each item's rank based on its position in the sorted list
            for (index, rankedItem) in itemsToRank.enumerated() {
                let newRank = index + 1
                
                // Look up the Core Data item by ID
                if let coreDataItem = mangaItemsById[Int64(rankedItem.id)] {
                    // Print before and after to verify the changes
                    print("Updating rank for: ID=\(coreDataItem.id), Title=\(coreDataItem.title ?? "Unknown")")
                    print("  Old rank: \(coreDataItem.rank), New rank: \(newRank)")
                    
                    // ONLY update the rank - nothing else
                    coreDataItem.rank = Int16(newRank)
                } else {
                    print("⚠️ Warning: Item not found in Core Data: ID=\(rankedItem.id)")
                }
            }
            
            // Save the changes
            try context.save()
            print("✅ Saved all rank updates to Core Data")
            
            // Now force a complete reload from Core Data
            rankingManager.loadAllDataFromCoreData()
            print("✅ Reloaded all data from Core Data")
            
        } catch {
            print("❌ Error updating ranks: \(error)")
        }
        
        // Mark the ranking process as complete
        rankingManager.pairwiseCompleted = true
        rankingManager.isPairwiseRankingActive = false
        
        // Clear win counts for next time
        rankingManager.winCounts.removeAll()
    }
}

#Preview {
    // For preview purposes, we create a mock
    NavigationView {
        PairwiseRankingView(rankingManager: RankingManager.shared, category: "Anime")
    }
}
