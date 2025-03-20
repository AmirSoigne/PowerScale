import SwiftUI

struct AnimeCardView: View {
    let item: RankingItem
    @State private var showNSFWContent = false

    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            ZStack {
                CachedAsyncImage(urlString: item.coverImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 140) // Smaller size
                        .clipped()
                        .blur(radius: containsExplicitContent && !showNSFWContent ? 20 : 0)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .center,
                                endPoint: .bottom
                            ))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                        .frame(width: 100, height: 140) // Smaller size
                }

                // NSFW indicator overlay
                if containsExplicitContent && !showNSFWContent {
                    VStack {
                        Text("NSFW")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(.top, 6)

                        Button(action: {
                            withAnimation {
                                showNSFWContent.toggle()
                            }
                        }) {
                            Text("Show")
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        .padding(.top, 4)
                    }
                }
            }

            // Info Section
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 3) {
                    Circle()
                        .fill(statusColor(item.status))
                        .frame(width: 5, height: 5)

                    Text(item.status)
                        .font(.system(size: 10))
                        .foregroundColor(statusTextColor(item.status))  // Use text color based on status
                        .lineLimit(1)
                }
            }
            .frame(width: 100, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(containsExplicitContent ? Color.red.opacity(0.3) : Color.white.opacity(0.1), lineWidth: containsExplicitContent ? 1.0 : 0.5)
        )
    }

    // Highly targeted NSFW detection that only blurs content with explicit nudity
    private var containsExplicitContent: Bool {
        // Only blur content explicitly focused on sexual content
        let explicitKeywords = [
            "hentai", "ero", "smut", "xxx", "pornographic",
            "r18", "18+", "explicit sex"
        ]
        
        // Safe popular anime that should never be flagged
        let safeAnime = [
            "my hero academia", "boku no hero", "re:zero", "rezero", "attack on titan",
            "shingeki no kyojin", "demon slayer", "kimetsu no yaiba", "jujutsu kaisen",
            "chainsaw man", "naruto", "one piece", "bleach", "hunter x hunter",
            "fullmetal alchemist", "death note", "tokyo ghoul", "sword art online"
        ]

        // Check title and tags/summary if available
        let lowercasedTitle = item.title.lowercased()
        let lowercasedSummary = (item.summary ?? "").lowercased()
        
        // First check if it's in our safe list - if so, never blur
        for safeTitle in safeAnime {
            if lowercasedTitle.contains(safeTitle) {
                return false
            }
        }
        
        // Check for certain combinations - "ecchi" alone isn't enough
        if lowercasedTitle.contains("ecchi") {
            // Only blur ecchi if combined with other signals
            if lowercasedTitle.contains("uncensored") ||
               lowercasedSummary.contains("nudity") ||
               lowercasedSummary.contains("explicit") {
                return true
            } else {
                // Most ecchi shows don't need to be blurred
                return false
            }
        }
        
        // Check if title contains explicit keywords
        for keyword in explicitKeywords {
            if lowercasedTitle.contains(keyword) {
                return true
            }
        }
        
        // Only blur if summary explicitly mentions nudity or sexual content
        // Using more specific terms to avoid false positives
        let explicitSummaryTerms = [
            "full nudity", "explicit sex scene", "pornographic", "hentai"
        ]
        
        for term in explicitSummaryTerms {
            if lowercasedSummary.contains(term) {
                return true
            }
        }
        
        // A show marking itself as adult content + having "uncensored" is a strong signal
        if (lowercasedTitle.contains("uncensored") || lowercasedSummary.contains("uncensored")) &&
           item.isAnime {
            return true
        }
        
        return false
    }

    private func statusColor(_ status: String) -> Color {
        let lowercasedStatus = status.lowercased()
        
        if lowercasedStatus.contains("publishing") || lowercasedStatus.contains("releasing") {
            return .blue
        } else if lowercasedStatus.contains("finished") || lowercasedStatus.contains("completed") {
            return .green
        } else if lowercasedStatus.contains("airing") || lowercasedStatus.contains("currently") {
            return .blue
        } else if lowercasedStatus.contains("upcoming") || lowercasedStatus.contains("want to") {
            return .orange
        } else if lowercasedStatus.contains("hold") {
            return .yellow
        } else if lowercasedStatus.contains("lost") || lowercasedStatus.contains("dropped") {
            return .red
        }
        return .gray
    }
    
    // Function for text color
    private func statusTextColor(_ status: String) -> Color {
        let lowercasedStatus = status.lowercased()
        
        if lowercasedStatus.contains("publishing") || lowercasedStatus.contains("releasing") {
            return .blue
        } else if lowercasedStatus.contains("finished") || lowercasedStatus.contains("completed") {
            return .green
        } else if lowercasedStatus.contains("airing") || lowercasedStatus.contains("currently") {
            return .blue
        } else {
            return .gray
        }
    }
}
