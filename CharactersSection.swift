import SwiftUI

// Extension on CharacterEdge to provide a non-optional identifier for use in ForEach.
extension CharacterEdge {
    var identifier: String {
        // Convert the integer ID to a String.
        return String(node.id)
    }
}

struct CharactersSection: View {
    let characters: [CharacterEdge]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionDivider()
            
            Text("CHARACTERS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(characters.prefix(6), id: \.identifier) { edge in
                        CharacterItem(edge: edge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CharacterItem: View {
    let edge: CharacterEdge
    
    var body: some View {
        VStack(spacing: 15) {
            // Character link - navigates to CharacterDetailView
            NavigationLink(destination: CharacterDetailView(
                characterId: edge.node.id,
                characterName: edge.node.name.full,
                imageURL: edge.node.image.medium ?? ""
            )) {
                VStack(alignment: .center, spacing: 5) {
                    // Character image
                    CachedAsyncImage(urlString: edge.node.image.medium ?? "") { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 100)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 100)
                            .cornerRadius(8)
                    }
                    
                    // Character name
                    Text(edge.node.name.full)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(width: 70)
                    
                    // Role
                    Text(edge.role ?? "")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // If voice actors exist, add link to the first voice actor
            if let voiceActors = edge.voiceActors, !voiceActors.isEmpty,
               let firstVA = voiceActors.first {
                NavigationLink(destination: StaffDetailView(
                    staffId: firstVA.id,
                    staffName: firstVA.name.full,
                    imageURL: firstVA.image.medium ?? ""
                )) {
                    VStack(alignment: .center, spacing: 5) {
                        // Voice actor image
                        CachedAsyncImage(urlString: firstVA.image.medium ?? "") { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 100)
                                .cornerRadius(8)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 100)
                                .cornerRadius(8)
                        }
                        
                        // Voice actor name
                        Text(firstVA.name.full)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 70)
                        
                        // Language
                        if let language = firstVA.language {
                            Text(language)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
