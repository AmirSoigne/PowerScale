// AnimeHeaderView.swift

import SwiftUI

struct AnimeHeaderView: View {
    let anime: Anime
    let isAnime: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            CachedAsyncImage(urlString: anime.coverImage.large) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 250)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 250)
                    .cornerRadius(10)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
            .padding(.top, 60)
            
            // Title and Studio/Author
            VStack(spacing: 6) {
                Text(anime.title.english ?? anime.title.romaji ?? "Unknown Title")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if isAnime {
                    // For anime, show studio information with improved handling
                    if let studios = anime.studios?.nodes, !studios.isEmpty {
                        // Filter for actual animation studios and join their names
                        let animationStudios = studios.filter { $0.isAnimationStudio ?? true }
                        if !animationStudios.isEmpty {
                            let studioNames = animationStudios.map { $0.name }.joined(separator: ", ")
                            Text(studioNames)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            // If no animation studios found, show all studios
                            let studioNames = studios.map { $0.name }.joined(separator: ", ")
                            Text(studioNames)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        // If no studios data available
                        Text("Studio information unavailable")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .onAppear {
                                debugPrintStudioInfo(anime)
                            }
                    }
                } else {
                    // For manga, show author/creator information
                    if let staff = anime.staff?.edges, !staff.isEmpty {
                        // Filter for authors, artists, etc.
                        let authorNames = staff
                            .filter {
                                $0.role.contains("Story") ||
                                $0.role.contains("Art") ||
                                $0.role.contains("Author") ||
                                $0.role.contains("Creator") ||
                                $0.role.contains("Illustrator")
                            }
                            .map { $0.node.name.full }
                            .joined(separator: ", ")
                        
                        if !authorNames.isEmpty {
                            Text(authorNames)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Text("Creator information unavailable")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Creator information unavailable")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Next episode airing info or publishing status
                if let nextEpisode = anime.nextAiringEpisode {
                    let timeRemaining = formatTimeUntilAiring(nextEpisode.timeUntilAiring)
                    let airingDate = formatAiringDate(nextEpisode.airingAt)
                    
                    VStack(spacing: 2) {
                        Text("Episode \(nextEpisode.episode) airs in \(timeRemaining)")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Release date: \(airingDate)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)
                    .padding(.top, 6)
                } else if anime.status == "RELEASING" && isAnime {
                    // For ongoing anime without specific next episode info
                    Text("Currently Airing")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .padding(.top, 6)
                } else if anime.status == "RELEASING" && !isAnime {
                    // For ongoing manga
                    Text("Ongoing Publication")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .padding(.top, 6)
                } else if anime.status == "FINISHED" || anime.status == "COMPLETED" {
                    Text(isAnime ? "Series Completed" : "Publication Completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .padding(.top, 6)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // Debug print for troubleshooting
            if isAnime {
                debugPrintStudioInfo(anime)
            }
        }
    }
    
    // Debug helper to print studio information
    private func debugPrintStudioInfo(_ anime: Anime) {
        print("🔍 Studio Debug for \(anime.title.romaji ?? "Unknown"):")
        print("- Has studios property: \(anime.studios != nil)")
        
        if let studios = anime.studios {
            print("- Has nodes in studios: \(studios.nodes != nil)")
            
            if let nodes = studios.nodes {
                print("- Number of studios: \(nodes.count)")
                
                for (index, studio) in nodes.enumerated() {
                    print("  • Studio \(index + 1): \(studio.name) (Animation: \(studio.isAnimationStudio ?? false))")
                }
            }
        }
    }
    
    // Helper function to format time until airing
    private func formatTimeUntilAiring(_ seconds: Int) -> String {
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
    
    // Helper function to format airing date
    private func formatAiringDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
