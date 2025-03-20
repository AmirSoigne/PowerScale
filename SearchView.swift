import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var animeResults: [Anime] = []
    @State private var mangaResults: [Anime] = []
    @State private var isSearching = false
    @State private var searchTask: DispatchWorkItem?
    @State private var minimumSearchLength = 2
    @State private var showSearch = false
    @State private var hasSubmittedSearch = false
    
    // Quick add states
    @State private var isMultiSelectMode = false
    @State private var selectedItems: [Anime] = []
    @State private var showCategoryPicker = false
    @State private var selectedCategory = ""
    @State private var showConfirmation = false
    @State private var showMixedTypeAlert = false  // New alert for mixed type selections
    @ObservedObject private var rankingManager = RankingManager.shared
    
    // API fetch states
    @State private var trendingAnime: [Anime] = []
    @State private var currentSeasonAnime: [Anime] = []
    @State private var upcomingAnime: [Anime] = []
    @State private var topRankedAnime: [Anime] = []
    @State private var topRankedMovies: [Anime] = []
    @State private var popularAnime: [Anime] = []
    @State private var trendingManga: [Anime] = []
    @State private var topRankedManga: [Anime] = []
    @State private var popularManga: [Anime] = []
    @State private var popularManhwa: [Anime] = []
    
    // Loading states
    @State private var loadingStates: [String: Bool] = [
        "trendingAnime": true,
        "currentSeasonAnime": true,
        "upcomingAnime": true,
        "topRankedAnime": true,
        "topRankedMovies": true,
        "popularAnime": true,
        "trendingManga": true,
        "topRankedManga": true,
        "popularManga": true,
        "popularManhwa": true
    ]
    
    // Get current season and year for display
    private var currentSeason: String {
        let (season, year) = getCurrentSeasonAndYear()
        return "\(formatSeason(season)) \(year)"
    }
    
    // Get upcoming season and year for display
    private var upcomingSeason: String {
        let (season, year) = getNextSeasonAndYear()
        return "\(formatSeason(season)) \(year)"
    }
    
    // Available categories for quick add
    private var animeCategories = ["Currently Watching", "Completed", "Want to Watch", "On Hold", "Lost Interest"]
    private var mangaCategories = ["Currently Reading", "Completed", "Want to Read", "On Hold", "Lost Interest"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                if isSearchActive && hasSubmittedSearch {
                    searchResultsView
                } else {
                    exploreContentView
                }
                
                // Search overlay
                if showSearch {
                    searchOverlay
                }
                
                // Category picker overlay
                if showCategoryPicker {
                    categoryPickerOverlay
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isMultiSelectMode {
                        Button("Cancel") {
                            // Exit multi-select mode
                            isMultiSelectMode = false
                            selectedItems = []
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        // Multi-select button
                        Button(action: {
                            withAnimation {
                                isMultiSelectMode.toggle()
                                if !isMultiSelectMode {
                                    selectedItems = []
                                }
                            }
                        }) {
                            Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        // Search button
                        Button(action: {
                            withAnimation {
                                showSearch = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay(
                // Quick add button when items are selected
                VStack {
                    Spacer()
                    
                    if isMultiSelectMode && selectedItems.count > 0 {
                        Button(action: {
                            showCategoryPicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                
                                Text("Add \(selectedItems.count) items")
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                        }
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: selectedItems.count)
            )
            .overlay(
                // Confirmation alert
                ZStack {
                    if showConfirmation {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showConfirmation = false
                                }
                            }
                        
                        VStack(spacing: 15) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.green)
                            
                            Text("Added to \(selectedCategory)")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            Text("\(selectedItems.count) items successfully added")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(30)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(15)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: showConfirmation)
            )
            .alert("Can't Mix Types", isPresented: $showMixedTypeAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can't select both anime and manga items at the same time. Please select only one type.")
            }
            .onAppear {
                // Fetch data when view appears if lists are empty
                if trendingAnime.isEmpty { fetchTrendingAnime() }
                if currentSeasonAnime.isEmpty { fetchCurrentSeasonAnime() }
                if upcomingAnime.isEmpty { fetchUpcomingAnime() }
                if topRankedAnime.isEmpty { fetchTopRankedAnime() }
                if topRankedMovies.isEmpty { fetchTopRankedMovies() }
                if popularAnime.isEmpty { fetchPopularAnime() }
                if trendingManga.isEmpty { fetchTrendingManga() }
                if topRankedManga.isEmpty { fetchTopRankedManga() }
                if popularManga.isEmpty { fetchPopularManga() }
                if popularManhwa.isEmpty { fetchPopularManhwa() }
            }
        }
    }
    
    // Category picker overlay
    private var categoryPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showCategoryPicker = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Add to")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Determine if all items are anime by checking if they have episodes
                let allSelectedAreAnime = areAllSelectedItemsAnime()
                
                // Choose appropriate categories based on content type
                let categories = allSelectedAreAnime ? animeCategories : mangaCategories
                
                VStack(spacing: 5) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            // Add items to selected category
                            addSelectedItemsToCategory(category)
                            
                            // Show confirmation
                            selectedCategory = category
                            withAnimation {
                                showCategoryPicker = false
                                showConfirmation = true
                            }
                            
                            // Hide confirmation after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showConfirmation = false
                                }
                                
                                // Exit multi-select mode after adding
                                isMultiSelectMode = false
                                selectedItems = []
                            }
                        }) {
                            Text(category)
                                .font(.system(size: 16))
                                .padding(.vertical, 12)
                                .frame(width: 250)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Button("Cancel") {
                    withAnimation {
                        showCategoryPicker = false
                    }
                }
                .foregroundColor(.gray)
                .padding(.top, 10)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(Color.black.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }
    
    // The main Explore content view with categories
    private var exploreContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Content sections
                sectionView(
                    title: "CURRENTLY TRENDING ANIME",
                    items: trendingAnime,
                    isLoading: loadingStates["trendingAnime"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "CURRENT SEASON - \(currentSeason.uppercased())",
                    items: currentSeasonAnime,
                    isLoading: loadingStates["currentSeasonAnime"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "UPCOMING SEASON - \(upcomingSeason.uppercased())",
                    items: upcomingAnime,
                    isLoading: loadingStates["upcomingAnime"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "TOP RANKED ANIME",
                    items: topRankedAnime,
                    isLoading: loadingStates["topRankedAnime"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "TOP RANKED ANIME MOVIES",
                    items: topRankedMovies,
                    isLoading: loadingStates["topRankedMovies"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "POPULAR ANIME",
                    items: popularAnime,
                    isLoading: loadingStates["popularAnime"] ?? false,
                    isAnime: true
                )
                
                sectionView(
                    title: "CURRENTLY TRENDING MANGA",
                    items: trendingManga,
                    isLoading: loadingStates["trendingManga"] ?? false,
                    isAnime: false
                )
                
                sectionView(
                    title: "TOP RANKED MANGA",
                    items: topRankedManga,
                    isLoading: loadingStates["topRankedManga"] ?? false,
                    isAnime: false
                )
                
                sectionView(
                    title: "POPULAR MANGA",
                    items: popularManga,
                    isLoading: loadingStates["popularManga"] ?? false,
                    isAnime: false
                )
                
                sectionView(
                    title: "POPULAR MANHWA",
                    items: popularManhwa,
                    isLoading: loadingStates["popularManhwa"] ?? false,
                    isAnime: false
                )
                
                Spacer(minLength: 80)
            }
            .padding(.top, 10)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    // Search overlay
    private var searchOverlay: some View {
        ZStack {
            // Semi-transparent background - only dismiss when tapping outside the search box area
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Just dismiss the keyboard, not the entire overlay
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 16) {
                // Search bar
                HStack {
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search anime, manga, or users")
                                .foregroundColor(.gray)
                                .padding(.leading, 36)
                        }
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding(.leading, 10)
                            
                            TextField("", text: $searchText)
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                                .onChange(of: searchText) { oldValue, newValue in
                                    // Don't activate search mode just from typing
                                    if newValue.isEmpty {
                                        animeResults = []
                                        mangaResults = []
                                        isSearchActive = false
                                        hasSubmittedSearch = false
                                    } else {
                                        // Prepare search but don't switch views
                                        debouncedSearch()
                                    }
                                }
                                .onSubmit {
                                    // Only when user presses return/enter do we consider it a search submission
                                    if searchText.count >= minimumSearchLength {
                                        performSearch()
                                        hasSubmittedSearch = true
                                        isSearchActive = true // Make sure to set this to true on submit
                                        showSearch = false // Hide overlay and show results
                                    }
                                }
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Button(action: {
                        dismissSearch()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                // Suggestions under search bar
                if searchText.count >= minimumSearchLength && !hasSubmittedSearch {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Press Return to search for \"\(searchText)\"")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Show search history or suggestions here if you want
                        Text("Popular suggestions:")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        
                        // Example suggestions
                        ForEach(["dragon ball", "naruto", "one piece", "attack on titan"], id: \.self) { suggestion in
                            if suggestion.contains(searchText.lowercased()) {
                                Button(action: {
                                    searchText = suggestion
                                    performSearch()
                                    hasSubmittedSearch = true
                                    isSearchActive = true // Make sure to set this to true
                                    showSearch = false
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(suggestion)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if !hasSubmittedSearch {
                    // Initial search prompt
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .padding(.bottom, 16)
                        
                        Text("Search for anime, manga, or users")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        if searchText.count > 0 && searchText.count < minimumSearchLength {
                            Text("Type at least \(minimumSearchLength) characters to search")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                }
                
                Spacer()
            }
        }
        .transition(.opacity)
    }
    
    // Search results view - when user has submitted a search
    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add a search bar at the top of results page
                HStack {   Button(action: {
                    // Reset search state and go back to main explore view
                    resetSearch()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                    Button(action: {
                        // Show search overlay again
                        showSearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            Text(searchText)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    resetSearch()
                                }
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Loading indicator
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Results sections - Modified for multi-select
                ResultsSection(title: "ANIME", results: animeResults, isAnime: true,
                               isMultiSelectMode: isMultiSelectMode, selectedItems: $selectedItems,
                               onSelectItem: toggleItemSelection, onShowMixedTypeAlert: { showMixedTypeAlert = true })
                
                ResultsSection(title: "MANGA", results: mangaResults, isAnime: false,
                               isMultiSelectMode: isMultiSelectMode, selectedItems: $selectedItems,
                               onSelectItem: toggleItemSelection, onShowMixedTypeAlert: { showMixedTypeAlert = true })
                
                // No results state
                if animeResults.isEmpty && mangaResults.isEmpty && !isSearching {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                            .padding(.top, 60)
                        
                        Text("No results found for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Try checking your spelling or using different keywords")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    // Section view with loading state - Modified for multi-select
    private func sectionView(title: String, items: [Anime], isLoading: Bool, isAnime: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.leading, 16)
            
            if isLoading {
                // Show loading skeleton
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCard()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else if items.isEmpty {
                // Show empty state
                HStack {
                    Spacer()
                    Text("No items available")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            } else {
                // Show actual items with multi-select support
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            if isMultiSelectMode {
                                // Multi-select mode card
                                Button(action: {
                                    toggleItemSelection(item)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ZStack(alignment: .topTrailing) {
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
                                            
                                            // Selection indicator
                                            ZStack {
                                                Circle()
                                                    .fill(Color.black.opacity(0.7))
                                                    .frame(width: 26, height: 26)
                                                
                                                Image(systemName: isItemSelected(item) ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(isItemSelected(item) ? .blue : .white)
                                            }
                                            .padding(5)
                                        }
                                        
                                        // Title
                                        Text(item.title.english ?? item.title.romaji ?? "Unknown")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .frame(width: 120, height: 36, alignment: .topLeading)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(canSelectItem(item) ? 1.0 : 0.5) // Dim items that can't be selected
                            } else {
                                // Regular navigation card
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
                                        
                                        // Title
                                        Text(item.title.english ?? item.title.romaji ?? "Unknown")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .frame(width: 120, height: 36, alignment: .topLeading)
                                        
                                        
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Results Section for Search - Modified for multi-select
    
    struct ResultsSection: View {
        let title: String
        let results: [Anime]
        let isAnime: Bool
        let isMultiSelectMode: Bool
        @Binding var selectedItems: [Anime]
        let onSelectItem: (Anime) -> Void
        let onShowMixedTypeAlert: () -> Void
        
        var body: some View {
            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Horizontal scroll view for similar design as explore sections
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(results) { item in
                                if isMultiSelectMode {
                                    // Multi-select mode card
                                    Button(action: {
                                        if canSelectItem(item) {
                                            onSelectItem(item)
                                        } else {
                                            onShowMixedTypeAlert()
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack(alignment: .topTrailing) {
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
                                                
                                                // Selection indicator
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.black.opacity(0.7))
                                                        .frame(width: 26, height: 26)
                                                    
                                                    Image(systemName: isItemSelected(item) ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(isItemSelected(item) ? .blue : .white)
                                                }
                                                .padding(5)
                                            }
                                            
                                            // Title
                                            Text(item.title.english ?? item.title.romaji ?? "Unknown")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .frame(width: 120, height: 36, alignment: .topLeading)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .opacity(canSelectItem(item) ? 1.0 : 0.5) // Dim items that can't be selected
                                } else {
                                    // Regular navigation card
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
                                            
                                            // Title
                                            Text(item.title.english ?? item.title.romaji ?? "Unknown")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .frame(width: 120, height: 36, alignment: .topLeading)
                                        }
                                    }
                                                                       .buttonStyle(PlainButtonStyle())
                                                                   }
                                                               }
                                                           }
                                                           .padding(.horizontal, 16)
                                                       }
                                                       
                                                       // Show all option
                                                       if results.count > 5 {
                                                           Button(action: {
                                                               // Future implementation: show all results
                                                           }) {
                                                               Text("View all \(results.count) results")
                                                                   .font(.caption)
                                                                   .foregroundColor(.blue)
                                                                   .padding(.horizontal, 16)
                                                                   .padding(.top, 4)
                                                                   .padding(.bottom, 8)
                                                           }
                                                       }
                                                   }
                                                   .padding(.vertical, 8)
                                               }
                                           }
                                           
                                           // Helper to check if an item is selected
                                           private func isItemSelected(_ item: Anime) -> Bool {
                                               return selectedItems.contains(where: { $0.id == item.id })
                                           }
                                           
                                           // Helper to determine if an item can be selected based on current selection
                                           private func canSelectItem(_ item: Anime) -> Bool {
                                               let isAnimeItem = item.episodes != nil
                                               
                                               // If nothing selected yet, can always select
                                               if selectedItems.isEmpty {
                                                   return true
                                               }
                                               
                                               // If items are selected, check that types match
                                               let hasAnimeSelected = selectedItems.contains(where: { $0.episodes != nil })
                                               let hasMangaSelected = selectedItems.contains(where: { $0.episodes == nil })
                                               
                                               if isAnimeItem {
                                                   return hasAnimeSelected || !hasMangaSelected
                                               } else {
                                                   return hasMangaSelected || !hasAnimeSelected
                                               }
                                           }
                                       }
                                       
                                       // MARK: - Skeleton Loading Card
                                       
                                       private struct SkeletonCard: View {
                                           @State private var isAnimating = false
                                           
                                           var body: some View {
                                               VStack(alignment: .leading, spacing: 6) {
                                                   // Skeleton image
                                                   Rectangle()
                                                       .fill(Color.gray.opacity(0.3))
                                                       .frame(width: 120, height: 180)
                                                       .cornerRadius(8)
                                                       .overlay(
                                                           LinearGradient(
                                                               gradient: Gradient(colors: [
                                                                   Color.gray.opacity(0.3),
                                                                   Color.gray.opacity(0.5),
                                                                   Color.gray.opacity(0.3)
                                                               ]),
                                                               startPoint: .leading,
                                                               endPoint: .trailing
                                                           )
                                                           .mask(
                                                               Rectangle()
                                                                   .fill(LinearGradient(
                                                                       gradient: Gradient(colors: [.clear, .white, .clear]),
                                                                       startPoint: .leading,
                                                                       endPoint: .trailing
                                                                   ))
                                                                   .rotationEffect(.degrees(70))
                                                                   .offset(x: isAnimating ? 200 : -200)
                                                           )
                                                       )
                                                   
                                                   // Skeleton title
                                                   Rectangle()
                                                       .fill(Color.gray.opacity(0.3))
                                                       .frame(width: 120, height: 16)
                                                       .cornerRadius(4)
                                                   
                                                   // Skeleton subtitle
                                                   Rectangle()
                                                       .fill(Color.gray.opacity(0.3))
                                                       .frame(width: 80, height: 12)
                                                       .cornerRadius(4)
                                               }
                                               .onAppear {
                                                   withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                                       isAnimating = true
                                                   }
                                               }
                                           }
                                       }
                                       
                                       // MARK: - Multi-select Helpers
                                       
                                       // Check if an item is selected
                                       private func isItemSelected(_ item: Anime) -> Bool {
                                           return selectedItems.contains(where: { $0.id == item.id })
                                       }
                                       
                                       // Check if an item can be selected (based on current selection)
                                       private func canSelectItem(_ item: Anime) -> Bool {
                                           let isAnimeItem = item.episodes != nil
                                           
                                           // If nothing selected yet, can always select
                                           if selectedItems.isEmpty {
                                               return true
                                           }
                                           
                                           // If items are selected, check that types match
                                           let hasAnimeSelected = selectedItems.contains(where: { $0.episodes != nil })
                                           let hasMangaSelected = selectedItems.contains(where: { $0.episodes == nil })
                                           
                                           if isAnimeItem {
                                               return hasAnimeSelected || !hasMangaSelected
                                           } else {
                                               return hasMangaSelected || !hasAnimeSelected
                                           }
                                       }
                                       
                                       // Toggle selection of an item
                                       private func toggleItemSelection(_ item: Anime) {
                                           if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
                                               selectedItems.remove(at: index)
                                           } else {
                                               // Check if we can add this item
                                               if canSelectItem(item) {
                                                   selectedItems.append(item)
                                               } else {
                                                   // Show alert that we can't mix types
                                                   showMixedTypeAlert = true
                                               }
                                           }
                                       }
                                       
                                       // Check if all selected items are anime
                                       private func areAllSelectedItemsAnime() -> Bool {
                                           // If all items have episodes (not chapters), they're anime
                                           return selectedItems.allSatisfy { $0.episodes != nil }
                                       }
                                       
                                       // Add selected items to a category
                                       private func addSelectedItemsToCategory(_ category: String) {
                                           let isAnimeCategory = animeCategories.contains(category)
                                           let today = Date()
                                           
                                           for item in selectedItems {
                                               let isItemAnime = item.episodes != nil
                                               
                                               // Only add anime to anime categories and manga to manga categories
                                               if isAnimeCategory == isItemAnime {
                                                   // Create a ranking item with today's date
                                                   let rankingItem = RankingItem(
                                                       from: item,
                                                       status: category,
                                                       isAnime: isItemAnime,
                                                       rank: 0,  // Default rank
                                                       score: 0,  // Default score
                                                       startDate: today,  // Today as start date
                                                       endDate: category == "Completed" ? today : nil,  // Today as end date if completed
                                                       progress: category == "Completed" ? (isItemAnime ? (item.episodes ?? 0) : (item.chapters ?? 0)) : 0  // Set progress to total if completed
                                                   )
                                                   
                                                   // Add to the appropriate category in RankingManager
                                                   rankingManager.addItem(
                                                       rankingItem,
                                                       category: isItemAnime ? "Anime" : "Manga"
                                                   )
                                               } else {
                                                   print("Warning: Attempted to add \(isItemAnime ? "anime" : "manga") to \(isAnimeCategory ? "anime" : "manga") category")
                                               }
                                           }
                                       }
                                       
                                       // MARK: - Search Methods
                                       
                                       // Reset search completely
                                       private func resetSearch() {
                                           searchTask?.cancel()
                                           
                                           withAnimation {
                                               searchText = ""
                                               isSearchActive = false
                                               hasSubmittedSearch = false
                                               animeResults = []
                                               mangaResults = []
                                           }
                                       }
                                       
                                       // Helper function to dismiss search
                                       private func dismissSearch() {
                                           // Cancel any pending search task
                                           searchTask?.cancel()
                                           
                                           withAnimation {
                                               // Hide the search overlay and reset search state
                                               showSearch = false
                                               if !hasSubmittedSearch {
                                                   searchText = ""
                                                   isSearchActive = false
                                                   animeResults = []
                                                   mangaResults = []
                                               }
                                           }
                                       }
                                       
                                       // Helper method to get status for an item based on its status value
                                       private func getStatus(for anime: Anime) -> String {
                                           guard let status = anime.status else { return "" }
                                           
                                           // Print the actual status value from the API for debugging
                                           print("Original status from API: \(status)")
                                           
                                           switch status {
                                           case "FINISHED", "COMPLETED":
                                               return "Completed Series"
                                           case "RELEASING", "CURRENT":
                                               if anime.episodes != nil {
                                                   return "Airing" // For anime
                                               } else {
                                                   return "Publishing" // For manga
                                               }
                                           case "NOT_YET_RELEASED":
                                               return "Upcoming"
                                           case "CANCELLED":
                                               return "Cancelled"
                                           case "HIATUS":
                                               return "On Hiatus"
                                           default:
                                               return status  // Return the original status if none of the cases match
                                           }
                                       }
                                       
                                       // Modify your SearchView.swift file to add this function for determining status color
                                       private func getStatusColor(for status: String) -> Color {
                                           let lowercasedStatus = status.lowercased()
                                           
                                           if lowercasedStatus.contains("airing") || lowercasedStatus.contains("publishing") ||
                                              lowercasedStatus.contains("releasing") || lowercasedStatus.contains("current") {
                                               return .blue
                                           } else if lowercasedStatus.contains("upcoming") || lowercasedStatus.contains("not_yet_released") {
                                               return .orange
                                           } else if lowercasedStatus.contains("finished") || lowercasedStatus.contains("completed") {
                                               return .green
                                           } else if lowercasedStatus.contains("hiatus") {
                                               return .yellow
                                           } else if lowercasedStatus.contains("cancelled") {
                                               return .red
                                           }
                                           return .gray
                                       }

                                       // Add this function to format the status text
                                       private func formatStatus(for anime: Anime) -> String {
                                           guard let status = anime.status else { return "" }
                                           
                                           switch status {
                                               case "FINISHED", "COMPLETED":
                                                   return "Completed Series"
                                               case "RELEASING", "CURRENT":
                                                   if anime.episodes != nil {
                                                       return "Airing"
                                                   } else {
                                                       return "Publishing"
                                                   }
                                               case "NOT_YET_RELEASED":
                                                   return "Upcoming"
                                               case "CANCELLED":
                                                   return "Cancelled"
                                               case "HIATUS":
                                                   return "On Hiatus"
                                               default:
                                                   return status.replacingOccurrences(of: "_", with: " ").capitalized
                                           }
                                       }
                                       
                                       // Helper function to format season names
                                       private func formatSeason(_ season: String) -> String {
                                           switch season {
                                           case "WINTER": return "Winter"
                                           case "SPRING": return "Spring"
                                           case "SUMMER": return "Summer"
                                           case "FALL": return "Fall"
                                           default: return season.capitalized
                                           }
                                       }
                                       
                                       // Helper method to determine current season and year
                                       private func getCurrentSeasonAndYear() -> (String, Int) {
                                           let currentDate = Date()
                                           let calendar = Calendar.current
                                           let month = calendar.component(.month, from: currentDate)
                                           let year = calendar.component(.year, from: currentDate)
                                           
                                           let season: String
                                           switch month {
                                           case 1, 2, 3:
                                               season = "WINTER"
                                           case 4, 5, 6:
                                               season = "SPRING"
                                           case 7, 8, 9:
                                               season = "SUMMER"
                                           case 10, 11, 12:
                                               season = "FALL"
                                           default:
                                               season = "WINTER"
                                           }
                                           
                                           return (season, year)
                                       }
                                       
                                       // Helper method to determine next season and year
                                       private func getNextSeasonAndYear() -> (String, Int) {
                                           let (currentSeason, currentYear) = getCurrentSeasonAndYear()
                                           
                                           var nextSeason: String
                                           var nextYear = currentYear
                                           
                                           switch currentSeason {
                                           case "WINTER":
                                               nextSeason = "SPRING"
                                           case "SPRING":
                                               nextSeason = "SUMMER"
                                           case "SUMMER":
                                               nextSeason = "FALL"
                                           case "FALL":
                                               nextSeason = "WINTER"
                                               nextYear += 1
                                           default:
                                               nextSeason = "SPRING"
                                           }
                                           
                                           return (nextSeason, nextYear)
                                       }
                                       
                                       // MARK: - API Fetch Methods
                                       
                                       // Fetch trending anime
                                       private func fetchTrendingAnime() {
                                           loadingStates["trendingAnime"] = true
                                           
                                           AniListAPI.shared.fetchTrendingAnime { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.trendingAnime = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["trendingAnime"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch current season anime
                                       private func fetchCurrentSeasonAnime() {
                                           loadingStates["currentSeasonAnime"] = true
                                           
                                           AniListAPI.shared.fetchCurrentSeasonAnime { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.currentSeasonAnime = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["currentSeasonAnime"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch upcoming anime
                                       private func fetchUpcomingAnime() {
                                           loadingStates["upcomingAnime"] = true
                                           
                                           AniListAPI.shared.fetchUpcomingSeasonAnime { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.upcomingAnime = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["upcomingAnime"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch top ranked anime
                                       private func fetchTopRankedAnime() {
                                           loadingStates["topRankedAnime"] = true
                                           
                                           AniListAPI.shared.fetchTopRankedAnime { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.topRankedAnime = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["topRankedAnime"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch top ranked movies
                                       private func fetchTopRankedMovies() {
                                           loadingStates["topRankedMovies"] = true
                                           
                                           AniListAPI.shared.fetchTopRankedMovies { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.topRankedMovies = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["topRankedMovies"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch popular anime
                                       private func fetchPopularAnime() {
                                           loadingStates["popularAnime"] = true
                                           
                                           AniListAPI.shared.fetchPopularAnime { result in
                                               DispatchQueue.main.async {
                                                   if let animes = result {
                                                       self.popularAnime = animes.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["popularAnime"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch trending manga
                                       private func fetchTrendingManga() {
                                           loadingStates["trendingManga"] = true
                                           
                                           AniListAPI.shared.fetchTrendingManga { result in
                                               DispatchQueue.main.async {
                                                   if let mangas = result {
                                                       self.trendingManga = mangas.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["trendingManga"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch top ranked manga
                                       private func fetchTopRankedManga() {
                                           loadingStates["topRankedManga"] = true
                                           
                                           AniListAPI.shared.fetchTopRankedManga { result in
                                               DispatchQueue.main.async {
                                                   if let mangas = result {
                                                       self.topRankedManga = mangas.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["topRankedManga"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch popular manga
                                       private func fetchPopularManga() {
                                           loadingStates["popularManga"] = true
                                           
                                           AniListAPI.shared.fetchPopularManga { result in
                                               DispatchQueue.main.async {
                                                   if let mangas = result {
                                                       self.popularManga = mangas.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["popularManga"] = false
                                               }
                                           }
                                       }
                                       
                                       // Fetch popular manhwa
                                       private func fetchPopularManhwa() {
                                           loadingStates["popularManhwa"] = true
                                           
                                           AniListAPI.shared.fetchPopularManhwa { result in
                                               DispatchQueue.main.async {
                                                   if let manhwas = result {
                                                       self.popularManhwa = manhwas.filter { !($0.isAdult ?? false) }
                                                   }
                                                   self.loadingStates["popularManhwa"] = false
                                               }
                                           }
                                       }
                                       
                                       // Search functionality
                                       private func debouncedSearch() {
                                           searchTask?.cancel()
                                           
                                           if searchText.count < minimumSearchLength {
                                               isSearchActive = false
                                               animeResults = []
                                               mangaResults = []
                                               return
                                           }
                                           
                                           let task = DispatchWorkItem {
                                               performSearch()
                                           }
                                           
                                           searchTask = task
                                           
                                           // Use a delay but don't set isSearchActive until user submits
                                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                               // Only perform the search if the task hasn't been canceled
                                               if !task.isCancelled {
                                                   task.perform()
                                               }
                                           }
                                       }
                                       
                                       private func performSearch() {
                                           guard !searchText.isEmpty && searchText.count >= minimumSearchLength else { return }
                                           
                                           // Set isSearchActive to true when search is performed
                                           isSearchActive = true
                                           isSearching = true
                                           
                                           var completedRequests = 0
                                           let totalRequests = 2
                                           
                                           let checkCompletion = {
                                               completedRequests += 1
                                               if completedRequests == totalRequests {
                                                   DispatchQueue.main.async {
                                                       isSearching = false
                                                   }
                                               }
                                           }
                                           
                                           AniListAPI.shared.searchAnime(query: searchText) { anime in
                                               DispatchQueue.main.async {
                                                   animeResults = (anime ?? []).filter { !($0.isAdult ?? false) }
                                                   checkCompletion()
                                               }
                                           }
                                           
                                           AniListAPI.shared.searchManga(query: searchText) { manga in
                                               DispatchQueue.main.async {
                                                   mangaResults = (manga ?? []).filter { !($0.isAdult ?? false) }
                                                   checkCompletion()
                                               }
                                           }
                                       }
                                    }
