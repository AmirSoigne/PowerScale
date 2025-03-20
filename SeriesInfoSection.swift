import SwiftUI

struct SeriesInfoSection: View {
    let anime: Anime
    let isAnime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("SERIES INFO")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Two column layout for metadata
            HStack(alignment: .top) {
                // Left column
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "TYPE", value: formatType(anime.format))
                    if isAnime {
                        InfoRow(label: "EPISODES", value: "\(anime.episodes ?? 0)")
                    } else {
                        InfoRow(label: "CHAPTERS", value: "\(anime.chapters ?? 0)")
                    }
                    InfoRow(label: "SEASON", value: formatSeason(season: anime.season, year: anime.seasonYear))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right column
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: isAnime ? "AIRING" : "STATUS", value: formatStatus(anime.status))
                    if isAnime {
                        InfoRow(label: "RUNTIME", value: formatDuration(anime.duration))
                    } else {
                        InfoRow(label: "VOLUMES", value: "\(anime.volumes ?? 0)")
                    }
                    InfoRow(label: "POPULARITY", value: formatPopularity(anime.popularity))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 15)
        }
    }
    
    // Helper formatting functions
    private func formatType(_ format: String?) -> String {
        guard let format = format else { return isAnime ? "TV" : "Manga" }
        
        switch format {
        case "TV":
            return "TV"
        case "TV_SHORT":
            return "TV Short"
        case "MOVIE":
            return "Movie"
        case "SPECIAL":
            return "Special"
        case "OVA":
            return "OVA"
        case "ONA":
            return "ONA"
        case "MUSIC":
            return "Music"
        case "MANGA":
            return "Manga"
        case "NOVEL":
            return "Novel"
        case "ONE_SHOT":
            return "One-shot"
        default:
            return format.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func formatSeason(season: String?, year: Int?) -> String {
        guard let season = season else { return "Unknown" }
        let formattedSeason = season.capitalized
        
        if let year = year {
            return "\(formattedSeason) \(year)"
        }
        return formattedSeason
    }
    
    private func formatStatus(_ status: String?) -> String {
        guard let status = status else { return "Unknown" }
        
        switch status {
        case "FINISHED":
            return "Completed"
        case "RELEASING":
            return isAnime ? "Currently Airing" : "Ongoing Publication"
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
    
    private func formatDuration(_ duration: Int?) -> String {
        guard let duration = duration else { return "Unknown" }
        return "\(duration) minutes"
    }
    
    private func formatPopularity(_ popularity: Int?) -> String {
        guard let popularity = popularity else { return "Unknown" }
        
        if popularity > 1000000 {
            let millions = Double(popularity) / 1000000.0
            return String(format: "%.1fM lists", millions)
        } else if popularity > 1000 {
            let thousands = Double(popularity) / 1000.0
            return String(format: "%.1fK lists", thousands)
        } else {
            return "\(popularity) lists"
        }
    }
}
