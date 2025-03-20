import SwiftUI

struct TagsAndGenresSection: View {
    let detailedAnime: Anime?
    let anime: Anime
    
    var body: some View {
        VStack {
            // Tags section
            SectionDivider()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("TAGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Tag cloud
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let tags = detailedAnime?.tags {
                            ForEach(tags.filter { !($0.isAdult ?? false) }.prefix(10)) { tag in
                                Text(tag.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(15)
                            }
                        } else {
                            ForEach(anime.genres ?? [], id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
            
            // Genres section
            SectionDivider()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("GENRES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Genre tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(detailedAnime?.genres ?? anime.genres ?? [], id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
        }
    }
}
