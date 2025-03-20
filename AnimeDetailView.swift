import SwiftUI

struct AnimeDetailView: View {
    let anime: Anime
    @StateObject private var viewModel: AnimeDetailViewModel
    @State private var showOptionsMenu = false
    @Environment(\.presentationMode) var presentationMode
    var isAnime: Bool = true
    @State private var detailedAnime: Anime?
    @State private var isLoading = true
    
    init(anime: Anime, isAnime: Bool = true) {
        self.anime = anime
        self.isAnime = isAnime
        // Initialize the view model
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(anime: anime, isAnime: isAnime))
    }
    
    var body: some View {
        ZStack {
            // Background content
            BackgroundView(anime: anime)
            
            // Loading indicator overlay
            if isLoading {
                LoadingOverlayView()
            }
            
            // Main content area
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // Add spacing before header to push content down
                    Spacer().frame(height: 60)
                    
                    // Header Section
                    AnimeHeaderView(anime: detailedAnime ?? anime, isAnime: isAnime)
                    
                    // Stats Bar
                    AnimeStatsView(anime: detailedAnime ?? anime)
                    
                    // Rating Section
                    RatingSection(viewModel: viewModel)
                    
                    // User Status and Progress
                    UserProgressSection(viewModel: viewModel, showOptionsMenu: $showOptionsMenu)
                    
                    // Watch History
                    WatchHistoryView(viewModel: viewModel)
                    
                    // Content sections with dividers
                    SummarySection(viewModel: viewModel)
                    
                    SeriesInfoSection(anime: detailedAnime ?? anime, isAnime: isAnime)
                    
                    if let nextEpisode = detailedAnime?.nextAiringEpisode {
                        NextEpisodeSection(nextEpisode: nextEpisode)
                    }
                    
                    TagsAndGenresSection(detailedAnime: detailedAnime, anime: anime)
                    
                    // Characters section
                    if let characters = detailedAnime?.characters?.edges, !characters.isEmpty {
                        CharactersSection(characters: characters)
                    }
                    
                    // Related anime section
                    if let relations = detailedAnime?.relations?.edges, !relations.isEmpty {
                        RelatedMediaSection(relations: relations, isAnime: isAnime)
                    }
                    
                    // External links, streaming, trailer, recommendations
                    ExternalContentSection(detailedAnime: detailedAnime, isAnime: isAnime)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 30)
                .opacity(isLoading ? 0.3 : 1.0) // Dim content while loading
            }
            
            // Options menu overlay
            if showOptionsMenu {
                OptionsMenuOverlay(
                    isPresented: $showOptionsMenu,
                    animeTitle: anime.title.english ?? anime.title.romaji ?? "Unknown",
                    isAnime: isAnime,
                    animeId: anime.id,
                    totalEpisodes: viewModel.totalEpisodes,
                    onSelection: viewModel.handleStatusSelection
                )
            }
            
            // Custom navigation header overlay
            NavigationHeaderView(presentationMode: presentationMode, showOptionsMenu: $showOptionsMenu)
        }
        .edgesIgnoringSafeArea(.all)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Always load full details when the view appears
            fetchFullDetails()
            
            // Add this line to load rankings specifically for anime
            if isAnime {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    loadRankingsData()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // New method to fetch rankings data specifically
    private func loadRankingsData() {
        if let detailedAnime = detailedAnime, isAnime {
            // Only load rankings if we don't already have them
            if detailedAnime.rankings == nil || detailedAnime.rankings?.isEmpty == true {
                AniListAPI.shared.getAnimeRankings(id: detailedAnime.id) { updatedAnime in
                    if let updatedAnime = updatedAnime, let rankings = updatedAnime.rankings {
                        DispatchQueue.main.async {
                            // Create a completely new Anime object with the updated rankings
                            // We need to do this because Anime is a struct with immutable properties
                            let updatedDetailedAnime = Anime(
                                id: detailedAnime.id,
                                title: detailedAnime.title,
                                coverImage: detailedAnime.coverImage,
                                description: detailedAnime.description,
                                episodes: detailedAnime.episodes,
                                chapters: detailedAnime.chapters,
                                volumes: detailedAnime.volumes,
                                duration: detailedAnime.duration,
                                status: detailedAnime.status,
                                format: detailedAnime.format,
                                season: detailedAnime.season,
                                seasonYear: detailedAnime.seasonYear,
                                isAdult: detailedAnime.isAdult,
                                startDate: detailedAnime.startDate,
                                endDate: detailedAnime.endDate,
                                genres: detailedAnime.genres,
                                tags: detailedAnime.tags,
                                averageScore: detailedAnime.averageScore,
                                meanScore: detailedAnime.meanScore,
                                popularity: detailedAnime.popularity,
                                favourites: detailedAnime.favourites,
                                trending: detailedAnime.trending,
                                rankings: rankings, // Use the new rankings here
                                studios: detailedAnime.studios,
                                producers: detailedAnime.producers,
                                staff: detailedAnime.staff,
                                relations: detailedAnime.relations,
                                characters: detailedAnime.characters,
                                externalLinks: detailedAnime.externalLinks,
                                trailer: detailedAnime.trailer,
                                streamingEpisodes: detailedAnime.streamingEpisodes,
                                nextAiringEpisode: detailedAnime.nextAiringEpisode,
                                recommendations: detailedAnime.recommendations,
                                bannerImage: detailedAnime.bannerImage
                            )
                            
                            // Update the state with our new Anime object
                            self.detailedAnime = updatedDetailedAnime
                            
                            print("✅ Updated rankings data successfully!")
                            print("🏆 Found \(rankings.count) rankings")
                            
                            // Print detailed info about the rankings we received
                            for (index, rank) in rankings.enumerated() {
                                print("  • Ranking \(index + 1): Type=\(rank.type), Rank=#\(rank.rank), Context=\(rank.context)")
                            }
                        }
                    } else {
                        print("❌ Failed to load rankings data")
                    }
                }
            }
        }
    }
    
    // New method to fetch full details
    private func fetchFullDetails() {
        isLoading = true
        
        // Define completion handler to process results
        let completionHandler: (Anime?) -> Void = { detailedAnime in
            DispatchQueue.main.async {
                if let detailedAnime = detailedAnime {
                    self.detailedAnime = detailedAnime
                    print("✅ Loaded \(self.isAnime ? "anime" : "manga") details for \(detailedAnime.title.romaji ?? "Unknown")")
                    
                    // Enhanced studio debugging
                    if let studios = detailedAnime.studios?.nodes, !studios.isEmpty {
                        let animationStudios = studios.filter { $0.isAnimationStudio ?? true }
                        let producers = studios.filter { !($0.isAnimationStudio ?? true) }
                        
                        // Log detailed studio information for debugging
                        print("🏢 Studio information:")
                        print("- Total studios: \(studios.count)")
                        print("- Animation studios: \(animationStudios.count)")
                        print("- Production studios: \(producers.count)")
                    }
                    
                    // Debug what data is available
                    print("- Has studios: \(detailedAnime.studios?.nodes?.count ?? 0) studios")
                    print("- Has characters: \(detailedAnime.characters?.edges?.count ?? 0) characters")
                    print("- Has relations: \(detailedAnime.relations?.edges?.count ?? 0) related media")
                    print("- Has external links: \(detailedAnime.externalLinks?.count ?? 0) links")
                    
                    if self.isAnime {
                        // Additional anime-specific data
                        print("- Has streaming episodes: \(detailedAnime.streamingEpisodes?.count ?? 0) episodes")
                        print("- Has trailer: \(detailedAnime.trailer != nil)")
                        
                        // Next episode debug information
                        if let nextEpisode = detailedAnime.nextAiringEpisode {
                            let airDate = Date(timeIntervalSince1970: TimeInterval(nextEpisode.airingAt))
                            print("📺 Next episode information:")
                            print("- Episode number: \(nextEpisode.episode)")
                            print("- Airing at: \(airDate)")
                            print("- Time until airing: \(formatTimeUntilAiring(nextEpisode.timeUntilAiring))")
                        }
                    }
                } else {
                    print("❌ Failed to load details")
                }
                
                // Always set isLoading to false, even on failure
                self.isLoading = false
            }
        }
        
        // Fetch based on type
        if isAnime {
            AniListAPI.shared.getAnimeDetails(id: anime.id, completion: completionHandler)
        } else {
            AniListAPI.shared.getMangaDetails(id: anime.id, completion: completionHandler)
        }
    }
}

// Helper function to format time until airing
func formatTimeUntilAiring(_ seconds: Int) -> String {
    let days = seconds / 86400
    if days > 0 {
        return "\(days) day\(days > 1 ? "s" : "")"
    }
    
    let hours = seconds / 3600
    if hours > 0 {
        return "\(hours) hour\(hours > 1 ? "s" : "")"
    }
    
    let minutes = seconds / 60
    return "\(minutes) minute\(minutes > 1 ? "s" : "")"
}

// Helper function to format airing date from timestamp
func formatAiringDate(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// Helper to create a link color based on streaming site
func getLinkColor(site: String) -> Color {
    switch site.lowercased() {
    case "crunchyroll", "funimation":
        return Color.orange
    case "netflix":
        return Color.red
    case "hulu":
        return Color.green
    case "twitter":
        return Color.blue
    case "anilist":
        return Color(red: 0.2, green: 0.4, blue: 0.8)
    case "instagram":
        return Color.purple
    case "tiktok":
        return Color.black
    case "bilibili":
        return Color(red: 0.0, green: 0.7, blue: 0.9)
    case "youtube":
        return Color.red
    default:
        return Color.gray
    }
}

// Helper for formatting relation types
func formatRelationType(_ relationType: String) -> String {
    switch relationType {
    case "PREQUEL":
        return "Prequel"
    case "SEQUEL":
        return "Sequel"
    case "PARENT":
        return "Parent"
    case "SIDE_STORY":
        return "Side Story"
    case "ADAPTATION":
        return "Adaptation"
    case "ALTERNATIVE":
        return "Alternative"
    case "CHARACTER":
        return "Character"
    case "SUMMARY":
        return "Summary"
    case "SPIN_OFF":
        return "Spin-off"
    default:
        return relationType.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// Convert MediaNode to Anime for navigation purposes
func createAnimeFromMediaNode(_ node: MediaNode) -> Anime {
    return Anime(
        id: node.id,
        title: node.title,
        coverImage: node.coverImage,
        description: node.description,
        episodes: nil,
        chapters: nil,
        volumes: nil,
        duration: nil,
        status: nil,
        format: node.format,
        season: nil,
        seasonYear: nil,
        isAdult: false,
        startDate: nil,
        endDate: nil,
        genres: nil,
        tags: nil,
        averageScore: nil,
        meanScore: nil,
        popularity: nil,
        favourites: nil,
        trending: nil,
        rankings: nil,
        studios: nil,
        producers: nil,
        staff: nil,
        relations: nil,
        characters: nil,
        externalLinks: nil,
        trailer: nil,
        streamingEpisodes: nil,
        nextAiringEpisode: nil,
        recommendations: nil,
        bannerImage: nil
    )
}
