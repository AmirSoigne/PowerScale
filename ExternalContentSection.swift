import SwiftUI

struct ExternalContentSection: View {
    let detailedAnime: Anime?
    let isAnime: Bool
    
    var body: some View {
        VStack {
            // External links section
            if let links = detailedAnime?.externalLinks, !links.isEmpty {
                ExternalLinksView(links: links)
            }
            
            // Streaming episodes section (anime only)
            if isAnime, let episodes = detailedAnime?.streamingEpisodes, !episodes.isEmpty {
                StreamingEpisodesView(episodes: episodes)
            }
            
            // Trailer section (anime only)
            if isAnime, let trailer = detailedAnime?.trailer, trailer.id != nil {
                TrailerView(trailer: trailer)
            }
            
            // Recommendations section
            if let recommendations = detailedAnime?.recommendations?.nodes, !recommendations.isEmpty {
                RecommendationsView(recommendations: recommendations, isAnime: isAnime)
            }
        }
    }
}

// MARK: - External Links View
struct ExternalLinksView: View {
    let links: [ExternalLink]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("EXTERNAL LINKS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(links.prefix(6)) { link in
                        Button(action: {
                            if let url = URL(string: link.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(link.site)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(getLinkColor(site: link.site))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Streaming Episodes View
struct StreamingEpisodesView: View {
    let episodes: [StreamingEpisode]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("WATCH ONLINE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(episodes.prefix(6), id: \.site) { episode in
                        VStack(alignment: .center, spacing: 5) {
                            // Episode thumbnail
                            if let thumbnailURL = episode.thumbnail, !thumbnailURL.isEmpty {
                                CachedAsyncImage(urlString: thumbnailURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 160, height: 90)
                                        .cornerRadius(8)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 160, height: 90)
                                        .cornerRadius(8)
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 160, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        Text(episode.site ?? "Stream")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Episode title and site
                            Text(episode.title ?? "Episode")
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .frame(width: 160)
                            
                            Text(episode.site ?? "")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            if let urlString = episode.url, let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Trailer View
struct TrailerView: View {
    let trailer: Trailer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("TRAILER")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack {
                // Trailer thumbnail
                if let thumbnail = trailer.thumbnail, let thumbnailURL = URL(string: thumbnail) {
                    CachedAsyncImage(urlString: thumbnail) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    .onTapGesture {
                        var url: URL?
                        if let site = trailer.site?.lowercased(), let id = trailer.id {
                            if site == "youtube" {
                                url = URL(string: "https://www.youtube.com/watch?v=\(id)")
                            } else if site == "dailymotion" {
                                url = URL(string: "https://www.dailymotion.com/video/\(id)")
                            }
                        }
                        
                        if let url = url {
                            UIApplication.shared.open(url)
                        }
                    }
                } else {
                    // Fallback if no thumbnail
                    Button(action: {
                        var url: URL?
                        if let site = trailer.site?.lowercased(), let id = trailer.id {
                            if site == "youtube" {
                                url = URL(string: "https://www.youtube.com/watch?v=\(id)")
                            } else if site == "dailymotion" {
                                url = URL(string: "https://www.dailymotion.com/video/\(id)")
                            }
                        }
                        
                        if let url = url {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Watch Trailer on \(trailer.site ?? "Video Site")")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    let recommendations: [RecommendationNode]
    let isAnime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("RECOMMENDATIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(recommendations.prefix(6), id: \.mediaRecommendation.id) { rec in
                        // Each recommendation is a navigation link with proper conversion
                        NavigationLink(destination: AnimeDetailView(
                            anime: createAnimeFromMediaNode(rec.mediaRecommendation),
                            isAnime: isAnime
                        )) {
                            VStack(alignment: .center, spacing: 8) {
                                // Recommendation image
                                CachedAsyncImage(urlString: rec.mediaRecommendation.coverImage.large) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(8)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(8)
                                }
                                
                                // Title
                                Text(rec.mediaRecommendation.title.english ?? rec.mediaRecommendation.title.romaji ?? "Unknown")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
