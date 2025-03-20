import SwiftUI
import CoreData

struct LibraryView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var rankingManager = RankingManager.shared
    
    // States for library navigation
    @State private var selectedLibraryType = 0 // 0 for Anime, 1 for Manga
    
    // Anime categories
    @State private var selectedAnimeCategory = "Currently Watching"
    private let animeCategories = ["Currently Watching", "Completed", "Want to Watch", "On Hold", "Lost Interest"]
    
    // Manga categories
    @State private var selectedMangaCategory = "Currently Reading"
    private let mangaCategories = ["Currently Reading", "Completed", "Want to Read", "On Hold", "Lost Interest"]
    
    // States for confirmation dialogs
    @State private var showingConfirmation = false
    @State private var itemToRemove: RankingItem?
    
    // Sorting functionality
    @State private var sortOption: SortOption = .default
    @State private var showingSortOptions = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case alphabetical = "A-Z"
        case genre = "By Genre"
        case dateAdded = "Date Added"
        case dateCompleted = "Date Completed"
        
        var id: String { self.rawValue }
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
                
                VStack(spacing: 0) {
                    // Type selector (Anime/Manga)
                    Picker("Library Type", selection: $selectedLibraryType) {
                        Text("Anime").tag(0)
                        Text("Manga").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))
                    
                    // Category selector - changes based on library type
                    if selectedLibraryType == 0 {
                        // Anime categories
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    // Add spacer at the beginning to ensure left padding
                                    Spacer()
                                        .frame(width: 20)
                                    
                                    ForEach(animeCategories, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedAnimeCategory = category
                                                
                                                // Reset sort to default if dateCompleted is selected and we're switching to a non-completed category
                                                if sortOption == .dateCompleted && category != "Completed" {
                                                    sortOption = .default
                                                }
                                                
                                                // Auto-scroll to make selected category visible
                                                scrollProxy.scrollTo(category, anchor: .center)
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                // Simplified category name for display
                                                Text(simplifyAnimeCategory(category))
                                                    .font(.system(size: 14, weight: selectedAnimeCategory == category ? .semibold : .regular))
                                                    .foregroundColor(selectedAnimeCategory == category ? .white : .gray)
                                                    .fixedSize() // Prevent text from being truncated
                                                
                                                // Indicator line
                                                Rectangle()
                                                    .fill(selectedAnimeCategory == category ? Color.blue : Color.clear)
                                                    .frame(height: 2)
                                            }
                                            .id(category) // Add ID for scrolling
                                            .padding(.horizontal, 15) // Ensure spacing between tabs
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // Add spacer at the end to ensure right padding
                                    Spacer()
                                        .frame(width: 20)
                                }
                            }
                            .background(Color.black.opacity(0.4))
                            .onAppear {
                                // Scroll to the selected category when view appears
                                scrollProxy.scrollTo(selectedAnimeCategory, anchor: .center)
                            }
                        }
                    } else {
                        // Manga categories
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    // Add spacer at the beginning to ensure left padding
                                    Spacer()
                                        .frame(width: 20)
                                    
                                    ForEach(mangaCategories, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedMangaCategory = category
                                                
                                                // Reset sort to default if dateCompleted is selected and we're switching to a non-completed category
                                                if sortOption == .dateCompleted && category != "Completed" {
                                                    sortOption = .default
                                                }
                                                
                                                // Auto-scroll to make selected category visible
                                                scrollProxy.scrollTo(category, anchor: .center)
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                // Simplified category name for display
                                                Text(simplifyMangaCategory(category))
                                                    .font(.system(size: 14, weight: selectedMangaCategory == category ? .semibold : .regular))
                                                    .foregroundColor(selectedMangaCategory == category ? .white : .gray)
                                                    .fixedSize() // Prevent text from being truncated
                                                
                                                // Indicator line
                                                Rectangle()
                                                    .fill(selectedMangaCategory == category ? Color.blue : Color.clear)
                                                    .frame(height: 2)
                                            }
                                            .id(category) // Add ID for scrolling
                                            .padding(.horizontal, 15) // Ensure spacing between tabs
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // Add spacer at the end to ensure right padding
                                    Spacer()
                                        .frame(width: 20)
                                }
                            }
                            .background(Color.black.opacity(0.4))
                            .onAppear {
                                // Scroll to the selected category when view appears
                                scrollProxy.scrollTo(selectedMangaCategory, anchor: .center)
                            }
                        }
                    }
                    
                    // Sort options bar - modified to hide Date Completed option for non-completed categories
                    HStack {
                        Text("Sort by:")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding(.leading, 40)
                        
                        // Sort picker
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                // Only show date completed for completed categories
                                if option != .dateCompleted ||
                                   (selectedLibraryType == 0 && selectedAnimeCategory == "Completed") ||
                                   (selectedLibraryType == 1 && selectedMangaCategory == "Completed") {
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    
                    // Content area based on selections and sort type
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Get items based on category selection
                            let items = getItemsForCurrentSelection()
                            
                            if items.isEmpty {
                                // Empty state message
                                VStack {
                                    Spacer()
                                    Text("No \(selectedLibraryType == 0 ? "anime" : "manga") in this category yet")
                                        .foregroundColor(.gray)
                                        .padding(.top, 50)
                                    
                                    Text("Add some from the Search tab")
                                        .foregroundColor(.gray)
                                        .padding(.top, 10)
                                    Spacer()
                                }
                                .frame(height: 300)
                            } else {
                                // Display sorted content based on selected sort option
                                switch sortOption {
                                case .default:
                                    defaultSortedListView(items: items)
                                case .alphabetical:
                                    alphabeticalSortedView(items: items)
                                case .genre:
                                    genreSortedView(items: items)
                                case .dateAdded:
                                    dateAddedSortedView(items: items)
                                case .dateCompleted:
                                    dateCompletedSortedView(items: items)
                                }
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle(selectedLibraryType == 0 ? "My Anime" : "My Manga")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Remove from list"),
                    message: Text("Are you sure you want to remove this \(selectedLibraryType == 0 ? "anime" : "manga") from your \(selectedLibraryType == 0 ? selectedAnimeCategory.lowercased() : selectedMangaCategory.lowercased()) list?"),
                    primaryButton: .destructive(Text("Remove")) {
                        if let item = itemToRemove {
                            removeItem(item)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                // Load saved selections from UserDefaults if available
                if let savedType = UserDefaults.standard.object(forKey: "selectedLibraryType") as? Int {
                    selectedLibraryType = savedType
                }
                
                if let savedAnimeCategory = UserDefaults.standard.string(forKey: "selectedAnimeCategory") {
                    selectedAnimeCategory = savedAnimeCategory
                }
                
                if let savedMangaCategory = UserDefaults.standard.string(forKey: "selectedMangaCategory") {
                    selectedMangaCategory = savedMangaCategory
                }
                
                if let savedSortOption = UserDefaults.standard.string(forKey: "selectedSortOption") {
                    if let option = SortOption.allCases.first(where: { $0.rawValue == savedSortOption }) {
                        sortOption = option
                    }
                }
                
                // Ensure dateCompleted sort option is only available for completed categories
                if sortOption == .dateCompleted {
                    let isCompletedCategory = (selectedLibraryType == 0 && selectedAnimeCategory == "Completed") ||
                                             (selectedLibraryType == 1 && selectedMangaCategory == "Completed")
                    
                    if !isCompletedCategory {
                        sortOption = .default
                    }
                }
            }
            .onDisappear {
                // Save selections to UserDefaults
                UserDefaults.standard.set(selectedLibraryType, forKey: "selectedLibraryType")
                UserDefaults.standard.set(selectedAnimeCategory, forKey: "selectedAnimeCategory")
                UserDefaults.standard.set(selectedMangaCategory, forKey: "selectedMangaCategory")
                UserDefaults.standard.set(sortOption.rawValue, forKey: "selectedSortOption")
            }
        }
        .accentColor(profileManager.currentProfile.getThemeColor())
    }
    
    // MARK: - Sorted View Implementations
    
    // Default list view (similar to original implementation)
    private func defaultSortedListView(items: [RankingItem]) -> some View {
        VStack {
            ForEach(items) { item in
                navigationLinkForItem(item)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
        }
    }
    
    // Alphabetical sort view (organized by first letter)
    private func alphabeticalSortedView(items: [RankingItem]) -> some View {
        // Group items by first letter of title
        let groupedItems = Dictionary(grouping: items) { item -> String in
            let firstChar = String(item.title.prefix(1)).uppercased()
            // Check if first character is a letter
            return firstChar.rangeOfCharacter(from: CharacterSet.letters) != nil ? firstChar : "#"
        }
        
        // Get sorted keys (letters)
        let sortedKeys = groupedItems.keys.sorted()
        
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sortedKeys, id: \.self) { letter in
                if let letterItems = groupedItems[letter]?.sorted(by: { $0.title < $1.title }) {
                    // Section header
                    Text(letter)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    
                    // Horizontal scroll for items
                    horizontalItemsScrollView(items: letterItems)
                }
            }
        }
    }
    
    // Genre sort view (organized by genres)
    private func genreSortedView(items: [RankingItem]) -> some View {
        // First, collect all unique genres across all items
        var allGenres = Set<String>()
        
        // Create a dictionary mapping each genre to the items that belong to it
        var genreToItems = [String: [RankingItem]]()
        
        // Populate the mappings
        for item in items {
            let itemGenres = getGenresForItem(item)
            
            // Add each genre to our set of all genres
            for genre in itemGenres {
                allGenres.insert(genre)
                
                // Add this item to the list of items for this genre
                if genreToItems[genre] == nil {
                    genreToItems[genre] = [item]
                } else {
                    genreToItems[genre]?.append(item)
                }
            }
        }
        
        // Sort the genres alphabetically
        let sortedGenres = allGenres.sorted()
        
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sortedGenres, id: \.self) { genre in
                if let genreItems = genreToItems[genre]?.sorted(by: { $0.title < $1.title }) {
                    // Section header
                    Text(genre)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    
                    // Horizontal scroll for items
                    horizontalItemsScrollView(items: genreItems)
                }
            }
        }
    }
    
    // Date added sort view - updated with user-friendly date headers
    private func dateAddedSortedView(items: [RankingItem]) -> some View {
        // Group items by start date with user-friendly categories
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let groupedItems = Dictionary(grouping: items) { item -> String in
            guard let date = item.startDate else { return "Unknown Date" }
            
            // Get start of day for the item's date
            let startOfDay = calendar.startOfDay(for: date)
            
            // Calculate difference in days
            let components = calendar.dateComponents([.day], from: startOfDay, to: today)
            
            if let days = components.day {
                // Today
                if days == 0 {
                    return "Today"
                }
                // Yesterday
                else if days == 1 {
                    return "Yesterday"
                }
                // This week (last 7 days)
                else if days <= 7 {
                    return "This Week"
                }
                // Last week (8-14 days ago)
                else if days <= 14 {
                    return "Last Week"
                }
                // This month
                else if calendar.component(.month, from: date) == calendar.component(.month, from: today) &&
                        calendar.component(.year, from: date) == calendar.component(.year, from: today) {
                    return "This Month"
                }
                // Last month
                else if let lastMonth = calendar.date(byAdding: .month, value: -1, to: today),
                        calendar.component(.month, from: date) == calendar.component(.month, from: lastMonth) &&
                        calendar.component(.year, from: date) == calendar.component(.year, from: lastMonth) {
                    return "Last Month"
                }
            }
            
            // For older dates, group by month and year
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        
        // Define the order of date categories
        let dateCategories = [
            "Today",
            "Yesterday",
            "This Week",
            "Last Week",
            "This Month",
            "Last Month"
        ]
        
        // Get all keys from the grouped items
        let allKeys = groupedItems.keys
        
        // Sort the keys with custom categories first, then chronological for month/year
        let sortedDates = allKeys.sorted { date1, date2 -> Bool in
            // Handle special categories
            let index1 = dateCategories.firstIndex(of: date1)
            let index2 = dateCategories.firstIndex(of: date2)
            
            // If both are special categories, sort by index
            if let idx1 = index1, let idx2 = index2 {
                return idx1 < idx2
            }
            // If only date1 is a special category, it comes first
            else if index1 != nil {
                return true
            }
            // If only date2 is a special category, it comes first
            else if index2 != nil {
                return false
            }
            // If neither is a special category, sort chronologically (newest first)
            else {
                // Parse the month/year strings
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                
                if let parsedDate1 = formatter.date(from: date1),
                   let parsedDate2 = formatter.date(from: date2) {
                    return parsedDate1 > parsedDate2
                }
                
                // Fallback to string comparison
                return date1 > date2
            }
        }
        
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sortedDates, id: \.self) { dateCategory in
                if let categoryItems = groupedItems[dateCategory]?.sorted(by: { $0.title < $1.title }) {
                    // Section header
                    Text(dateCategory)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    
                    // Horizontal scroll for items
                    horizontalItemsScrollView(items: categoryItems)
                }
            }
        }
    }
    
    // Date completed sort view - updated with user-friendly date headers
    private func dateCompletedSortedView(items: [RankingItem]) -> some View {
        // Group items by end date with user-friendly categories
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let groupedItems = Dictionary(grouping: items) { item -> String in
            guard let date = item.endDate else { return "Unknown Date" }
            
            // Get start of day for the item's date
            let startOfDay = calendar.startOfDay(for: date)
            
            // Calculate difference in days
            let components = calendar.dateComponents([.day], from: startOfDay, to: today)
            
            if let days = components.day {
                // Today
                if days == 0 {
                    return "Today"
                }
                // Yesterday
                else if days == 1 {
                    return "Yesterday"
                }
                // This week (last 7 days)
                else if days <= 7 {
                    return "This Week"
                }
                // Last week (8-14 days ago)
                else if days <= 14 {
                    return "Last Week"
                }
                // This month
                else if calendar.component(.month, from: date) == calendar.component(.month, from: today) &&
                        calendar.component(.year, from: date) == calendar.component(.year, from: today) {
                    return "This Month"
                }
                // Last month
                else if let lastMonth = calendar.date(byAdding: .month, value: -1, to: today),
                        calendar.component(.month, from: date) == calendar.component(.month, from: lastMonth) &&
                        calendar.component(.year, from: date) == calendar.component(.year, from: lastMonth) {
                    return "Last Month"
                }
            }
            
            // For older dates, group by month and year
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        
        // Define the order of date categories
        let dateCategories = [
            "Today",
            "Yesterday",
            "This Week",
            "Last Week",
            "This Month",
            "Last Month"
        ]
        
        // Get all keys from the grouped items
        let allKeys = groupedItems.keys
        
        // Sort the keys with custom categories first, then chronological for month/year
        let sortedDates = allKeys.sorted { date1, date2 -> Bool in
            // Handle special categories
            let index1 = dateCategories.firstIndex(of: date1)
            let index2 = dateCategories.firstIndex(of: date2)
            
            // If both are special categories, sort by index
            if let idx1 = index1, let idx2 = index2 {
                return idx1 < idx2
            }
            // If only date1 is a special category, it comes first
            else if index1 != nil {
                return true
            }
            // If only date2 is a special category, it comes first
            else if index2 != nil {
                return false
            }
            // If neither is a special category, sort chronologically (newest first)
            else {
                // Parse the month/year strings
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                
                if let parsedDate1 = formatter.date(from: date1),
                   let parsedDate2 = formatter.date(from: date2) {
                    return parsedDate1 > parsedDate2
                }
                
                // Fallback to string comparison
                return date1 > date2
            }
        }
        
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sortedDates, id: \.self) { dateCategory in
                if let categoryItems = groupedItems[dateCategory]?.sorted(by: { $0.title < $1.title }) {
                    // Section header
                    Text(dateCategory)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    
                    // Horizontal scroll for items
                    horizontalItemsScrollView(items: categoryItems)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Horizontal scroll view for items (used in sorted views)
    private func horizontalItemsScrollView(items: [RankingItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Add left padding
                Spacer().frame(width: 20)
                
                // Items in horizontal row
                ForEach(items) { item in
                    navigationLinkForCompactItem(item)
                }
                
                // Add right padding
                Spacer().frame(width: 20)
            }
            .padding(.vertical, 8)
        }
    }
    
    // Regular list item view
    private func navigationLinkForItem(_ item: RankingItem) -> some View {
        NavigationLink(destination: AnimeDetailView(anime: item.toAnime(), isAnime: item.isAnime)) {
            HStack {
                // Cover image
                CachedAsyncImage(urlString: item.coverImage) { image in
                    image.resizable().scaledToFit()
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                }
                
                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let status = getDisplayStatus(for: item) {
                        Text(status)
                            .font(.subheadline)
                            .foregroundColor(getStatusColor(for: item.status))
                    }
                    
                    // Date information if available
                    if let startDate = item.startDate {
                        Text("Started: \(formatDate(startDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let endDate = item.endDate {
                        Text("Completed: \(formatDate(endDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Progress for currently watching/reading
                    if item.status.contains("Currently") {
                        Text("Progress: \(item.progress)/\(getMaxEpisodesOrChapters(for: item))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        .contextMenu {
            Button(action: {
                itemToRemove = item
                showingConfirmation = true
            }) {
                Label("Remove from list", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                itemToRemove = item
                showingConfirmation = true
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    // Compact item view for horizontal scrolling
    private func navigationLinkForCompactItem(_ item: RankingItem) -> some View {
        NavigationLink(destination: AnimeDetailView(anime: item.toAnime(), isAnime: item.isAnime)) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover image
                CachedAsyncImage(urlString: item.coverImage) { image in
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
                    Text(item.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .frame(width: 120, alignment: .topLeading)
                    
                    // Status indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(getStatusColor(for: item.status))
                            .frame(width: 6, height: 6)
                        
                        Text(formatUserStatus(item.status))
                            .font(.system(size: 10))
                            .foregroundColor(getStatusColor(for: item.status))
                            .lineLimit(1)
                    }
                    
                    // Rewatch/reread indicator
                    if item.isRewatch {
                        Text(item.isAnime ? "Rewatch #\(item.rewatchCount)" : "Reread #\(item.rewatchCount)")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
                .frame(width: 120, height: 52, alignment: .topLeading)
            }
            .contextMenu {
                Button(action: {
                    itemToRemove = item
                    showingConfirmation = true
                }) {
                    Label("Remove from list", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    // Get items for the current selection
        private func getItemsForCurrentSelection() -> [RankingItem] {
            if selectedLibraryType == 0 {
                // Anime items
                switch selectedAnimeCategory {
                case "Currently Watching":
                    return rankingManager.currentlyWatching
                case "Completed":
                    // Include both main completions and rewatches
                    return rankingManager.rankedAnime + rankingManager.completedRewatchesAnime
                case "Want to Watch":
                    return rankingManager.wantToWatch
                case "On Hold":
                    return rankingManager.onHoldAnime
                case "Lost Interest":
                    return rankingManager.lostInterestAnime
                default:
                    return []
                }
            } else {
                // Manga items
                switch selectedMangaCategory {
                case "Currently Reading":
                    return rankingManager.currentlyReading
                case "Completed":
                    // Include both main completions and rereads
                    return rankingManager.rankedManga + rankingManager.completedRewatchesManga
                case "Want to Read":
                    return rankingManager.wantToRead
                case "On Hold":
                    return rankingManager.onHoldManga
                case "Lost Interest":
                    return rankingManager.lostInterestManga
                default:
                    return []
                }
            }
        }
        
        // Get genres for an item
        private func getGenresForItem(_ item: RankingItem) -> [String] {
            let anime = item.toAnime()
            guard let genres = anime.genres, !genres.isEmpty else {
                return ["Unknown"]
            }
            return genres
        }
        
        // Get maximum episodes or chapters
        private func getMaxEpisodesOrChapters(for item: RankingItem) -> Int {
            let anime = item.toAnime()
            if item.isAnime {
                return anime.episodes ?? item.progress
            } else {
                return anime.chapters ?? item.progress
            }
        }
        
        // Format display status
        private func getDisplayStatus(for item: RankingItem) -> String? {
            if item.isRewatch {
                return "\(item.status) (\(item.isAnime ? "Rewatch" : "Reread") #\(item.rewatchCount))"
            }
            return item.status
        }
        
        // Format date for display
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        // Format status for compact display
        private func formatUserStatus(_ status: String) -> String {
            switch status {
            case "Currently Watching":
                return "Watching"
            case "Currently Reading":
                return "Reading"
            case "Want to Watch":
                return "Plan to Watch"
            case "Want to Read":
                return "Plan to Read"
            case "Lost Interest":
                return "Dropped"
            default:
                return status
            }
        }
        
        // Get color for status indicator
        private func getStatusColor(for status: String) -> Color {
            switch status {
            case "Completed":
                return .green
            case "Currently Watching", "Currently Reading":
                return .blue
            case "Want to Watch", "Want to Read":
                return .orange
            case "On Hold":
                return .yellow
            case "Lost Interest":
                return .red
            default:
                return .gray
            }
        }
        
        // Remove an item from the appropriate list
        private func removeItem(_ item: RankingItem) {
            if selectedLibraryType == 0 {
                // Remove anime
                switch selectedAnimeCategory {
                case "Currently Watching":
                    rankingManager.currentlyWatching.removeAll { $0.id == item.id }
                case "Completed":
                    if item.isRewatch {
                        rankingManager.completedRewatchesAnime.removeAll {
                            $0.id == item.id && $0.rewatchCount == item.rewatchCount
                        }
                    } else {
                        rankingManager.rankedAnime.removeAll { $0.id == item.id }
                    }
                case "Want to Watch":
                    rankingManager.wantToWatch.removeAll { $0.id == item.id }
                case "On Hold":
                    rankingManager.onHoldAnime.removeAll { $0.id == item.id }
                case "Lost Interest":
                    rankingManager.lostInterestAnime.removeAll { $0.id == item.id }
                default:
                    break
                }
            } else {
                // Remove manga
                switch selectedMangaCategory {
                case "Currently Reading":
                    rankingManager.currentlyReading.removeAll { $0.id == item.id }
                case "Completed":
                    if item.isRewatch {
                        rankingManager.completedRewatchesManga.removeAll {
                            $0.id == item.id && $0.rewatchCount == item.rewatchCount
                        }
                    } else {
                        rankingManager.rankedManga.removeAll { $0.id == item.id }
                    }
                case "Want to Read":
                    rankingManager.wantToRead.removeAll { $0.id == item.id }
                case "On Hold":
                    rankingManager.onHoldManga.removeAll { $0.id == item.id }
                case "Lost Interest":
                    rankingManager.lostInterestManga.removeAll { $0.id == item.id }
                default:
                    break
                }
            }
            
            // Update Core Data
            let context = CoreDataManager.shared.container.viewContext
            let fetchRequest: NSFetchRequest<AnimeItem> = AnimeItem.fetchRequest()
            
            if item.isRewatch {
                // For rewatches, match both ID and rewatch count
                fetchRequest.predicate = NSPredicate(format: "id == %lld AND isRewatch == YES AND rewatchCount == %d",
                                                    Int64(item.id), item.rewatchCount)
            } else {
                fetchRequest.predicate = NSPredicate(format: "id == %lld AND isRewatch == NO", Int64(item.id))
            }
            
            do {
                let results = try context.fetch(fetchRequest)
                if let animeItem = results.first {
                    context.delete(animeItem)
                    CoreDataManager.shared.saveContext()
                }
            } catch {
                print("Error deleting item: \(error)")
            }
            
            // Reset the item to remove
            itemToRemove = nil
        }
        
        // Helper function to simplify anime category names for display
        private func simplifyAnimeCategory(_ category: String) -> String {
            switch category {
            case "Currently Watching":
                return "Watching"
            case "Want to Watch":
                return "Watch Later"
            case "Lost Interest":
                return "Dropped"
            default:
                return category
            }
        }
        
        // Helper function to simplify manga category names for display
        private func simplifyMangaCategory(_ category: String) -> String {
            switch category {
            case "Currently Reading":
                return "Reading"
            case "Want to Read":
                return "Read Later"
            case "Lost Interest":
                return "Dropped"
            default:
                return category
            }
        }
    }
