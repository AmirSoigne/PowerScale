import SwiftUI

struct RelatedMediaSection: View {
    let relations: [MediaEdge]
    let isAnime: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("RELATED")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(relations.prefix(5), id: \.node.id) { edge in
                        RelatedMediaItem(edge: edge, isAnime: isAnime)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RelatedMediaItem: View {
    let edge: MediaEdge
    let isAnime: Bool
    
    var body: some View {
        // Each related media is a navigation link with proper conversion
        NavigationLink(destination: AnimeDetailView(
            anime: createAnimeFromMediaNode(edge.node),
            isAnime: edge.node.type == "ANIME" || edge.node.format?.contains("TV") ?? false || edge.node.format?.contains("MOVIE") ?? false
        )) {
            VStack(alignment: .center, spacing: 8) {
                // Related anime image
                CachedAsyncImage(urlString: edge.node.coverImage.large) { image in
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
                
                // Related anime title
                Text(edge.node.title.english ?? edge.node.title.romaji ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                
                // Relation type
                if let relationType = edge.relationType {
                    Text(formatRelationType(relationType))
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
