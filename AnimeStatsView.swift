import SwiftUI

struct AnimeStatsView: View {
    let anime: Anime
    
    var body: some View {
        HStack(spacing: 0) {
            // Average score
            VStack(spacing: 4) {
                Text("AVERAGE SCORE")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text("\(anime.averageScore ?? 0)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            // Highest rated
            VStack(spacing: 4) {
                Text("HIGHEST RATED")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let rankings = anime.rankings, let highestRanking = rankings.first(where: { $0.type == "RATED" }) {
                    Text("#\(highestRanking.rank)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("All Time")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else {
                    Text("#--")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Most popular - Fixed implementation
            VStack(spacing: 4) {
                Text("MOST POPULAR")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let rankings = anime.rankings, let popularRanking = rankings.first(where: { $0.type == "POPULAR" }) {
                    // Use the actual rank from the rankings array
                    Text("#\(popularRanking.rank)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("All Time")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else if let popularity = anime.popularity, popularity > 0 {
                    // Fallback to showing "Ranked" instead of the raw popularity number
                    Text("Ranked")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("#--")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
