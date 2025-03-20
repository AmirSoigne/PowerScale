import SwiftUI

struct NextEpisodeSection: View {
    let nextEpisode: AiringSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT EPISODE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Add a more prominent airing card with countdown
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Episode \(nextEpisode.episode)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Add a countdown badge
                    Text(formatTimeUntilAiring(nextEpisode.timeUntilAiring))
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                
                // Add air date
                Text("Airs on: \(formatAiringDate(nextEpisode.airingAt))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Add a progress bar to visually show time until airing
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: calculateAiringProgress(nextEpisode.timeUntilAiring), total: 7*24*60*60) // 1 week maximum
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                        .frame(height: 4)
                }
                .padding(.top, 6)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.bottom, 15)
    }
    
    // Helper function to calculate airing progress (as a value between 0-1)
    private func calculateAiringProgress(_ secondsRemaining: Int) -> Double {
        let weekInSeconds: Double = 7 * 24 * 60 * 60
        // This assumes we're showing a week at most, and the closer to airing, the more progress
        return max(0, min(1, (weekInSeconds - Double(secondsRemaining)) / weekInSeconds))
    }
}
