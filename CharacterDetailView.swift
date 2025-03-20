import SwiftUI

// Define DateInfoProtocol - this is the ONLY place it should be defined
protocol DateInfoProtocol {
    var year: Int? { get }
    var month: Int? { get }
    var day: Int? { get }
}

// Make both DateInfo structs conform to the protocol
extension CharacterDetail.DateInfo: DateInfoProtocol {}
extension StaffDetail.DateInfo: DateInfoProtocol {}

struct CharacterDetailView: View {
    let characterId: Int
    let characterName: String
    let imageURL: String
    
    @State private var characterDetail: CharacterDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var retryCount = 0
    @State private var isFavorite: Bool = false
    
    // Add access to UserDefaults to persist the favorite status
    @AppStorage("favoriteCharacters") private var favoriteCharactersData: Data = Data()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Main content based on loading/error states
            contentView
        }
        .navigationTitle(characterName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .font(.system(size: 22))
                        .scaleEffect(isFavorite ? 1.1 : 1.0)
                        .shadow(color: isFavorite ? .red.opacity(0.5) : .clear, radius: isFavorite ? 3 : 0)
                }
            }
        }
        .onAppear {
            loadCharacterDetails()
            checkIfFavorite()
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error: error)
            } else if let character = characterDetail {
                characterDetailsView(character: character)
            } else {
                // Fallback if data is missing
                Text("No character details available")
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Placeholder silhouette
            ZStack {
                // Background placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 250)
                    .cornerRadius(10)
                
                // Person silhouette
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Character name
            Text(characterName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
                .padding(.top, 10)
            
            Text("Loading details...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.yellow)
            
            Text("Couldn't load character details")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                retryCount += 1
                isLoading = true
                errorMessage = nil
                loadCharacterDetails()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Character Details View
    
    private func characterDetailsView(character: CharacterDetail) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Character image
                CachedAsyncImage(urlString: character.image?.medium ?? imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 250)
                        .cornerRadius(10)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 180, height: 250)
                        .cornerRadius(10)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
                .padding(.top, 20)
                
                // Character name, alternative names, favorites
                VStack(spacing: 8) {
                    Text(character.name.full)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // If there's a native name or alternative names
                    if let nativeName = character.name.native, !nativeName.isEmpty {
                        Text(nativeName)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    if let altNames = character.name.alternative, !altNames.isEmpty {
                        Text("AKA: \(altNames.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Member favorites
                    Text("Member Favorites: \(character.favourites ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Description
                if let description = character.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ABOUT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text(cleanDescription(description))
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // Optional: Additional fields like gender, age, etc.
                if let gender = character.gender, !gender.isEmpty {
                    InfoRow(label: "Gender", value: gender)
                        .padding(.horizontal)
                }
                if let age = character.age, !age.isEmpty {
                    InfoRow(label: "Age", value: age)
                        .padding(.horizontal)
                }
                if let blood = character.bloodType, !blood.isEmpty {
                    InfoRow(label: "Blood Type", value: blood)
                        .padding(.horizontal)
                }
                
                if hasVoiceActors(character) {
                    voiceActorsSection(character: character)
                }
                if hasMediaAppearances(character) {
                    mediaAppearancesSection(character: character)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(
            characterBackgroundView(character: character)
        )
    }
    
    // MARK: - Voice Actors
    
    private func hasVoiceActors(_ character: CharacterDetail) -> Bool {
        guard let edges = character.media?.edges else { return false }
        return edges.contains(where: { ($0.voiceActors?.count ?? 0) > 0 })
    }
    
    private func voiceActorsSection(character: CharacterDetail) -> some View {
        VStack {
            SectionDivider()
            VStack(alignment: .leading, spacing: 15) {
                Text("VOICE ACTORS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(getVoiceActors(character), id: \.id) { actor in
                            voiceActorItem(actor: actor)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func getVoiceActors(_ character: CharacterDetail) -> [CharacterDetail.VoiceActor] {
        guard let edges = character.media?.edges else { return [] }
        var allVoiceActors: [CharacterDetail.VoiceActor] = []
        
        for edge in edges {
            if let actors = edge.voiceActors {
                allVoiceActors.append(contentsOf: actors)
            }
        }
        
        // Remove duplicates
        var unique: [CharacterDetail.VoiceActor] = []
        var seen = Set<Int>()
        
        for va in allVoiceActors {
            if !seen.contains(va.id) {
                unique.append(va)
                seen.insert(va.id)
            }
        }
        return unique
    }
    
    private func voiceActorItem(actor: CharacterDetail.VoiceActor) -> some View {
        NavigationLink(destination: StaffDetailView(
            staffId: actor.id,
            staffName: actor.name.full,
            imageURL: actor.image?.medium ?? ""
        )) {
            VStack(alignment: .center, spacing: 8) {
                CachedAsyncImage(urlString: actor.image?.medium ?? "") { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
                
                Text(actor.name.full)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 80)
                
                if let language = actor.language {
                    Text(language)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Media Appearances
    
    private func hasMediaAppearances(_ character: CharacterDetail) -> Bool {
        return (character.media?.edges?.count ?? 0) > 0
    }
    
    private func mediaAppearancesSection(character: CharacterDetail) -> some View {
        VStack {
            SectionDivider()
            VStack(alignment: .leading, spacing: 15) {
                Text("APPEARANCES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(getMediaAppearances(character), id: \.self) { info in
                            mediaAppearanceItem(node: info.node, role: info.role)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private struct MediaAppearanceInfo: Hashable {
        let node: Anime
        let role: String?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(node.id)
            hasher.combine(role)
        }
        
        static func == (lhs: MediaAppearanceInfo, rhs: MediaAppearanceInfo) -> Bool {
            return lhs.node.id == rhs.node.id && lhs.role == rhs.role
        }
    }
    
    private func getMediaAppearances(_ character: CharacterDetail) -> [MediaAppearanceInfo] {
        guard let edges = character.media?.edges else { return [] }
        var result: [MediaAppearanceInfo] = []
        
        for edge in edges {
            if let node = edge.node {
                result.append(MediaAppearanceInfo(node: node, role: edge.role))
            }
        }
        return result
    }
    
    private func mediaAppearanceItem(node: Anime, role: String?) -> some View {
        NavigationLink(destination: AnimeDetailView(anime: node, isAnime: node.episodes != nil)) {
            VStack(alignment: .center, spacing: 8) {
                // Cover image
                CachedAsyncImage(urlString: node.coverImage.large) { image in
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
                Text(node.title.english ?? node.title.romaji ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 100)
                
                if let role = role {
                    Text(role)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Favorite Management
    
    // Function to check if this character is a favorite
    private func checkIfFavorite() {
        let favoriteCharacters = getFavoriteCharacters()
        isFavorite = favoriteCharacters.contains(characterId)
    }
    
    // Function to toggle favorite status
    private func toggleFavorite() {
        var favoriteCharacters = getFavoriteCharacters()
        
        if favoriteCharacters.contains(characterId) {
            // Remove from favorites
            favoriteCharacters.removeAll { $0 == characterId }
        } else {
            // Add to favorites
            favoriteCharacters.append(characterId)
        }
        
        // Update the UI state
        isFavorite.toggle()
        
        // Save the updated favorites list
        saveFavoriteCharacters(favoriteCharacters)
        
        // Post notification about the change
        NotificationCenter.default.post(name: Notification.Name("FavoriteCharactersChanged"), object: nil)
    }
    
    // Function to get the current favorites list
    private func getFavoriteCharacters() -> [Int] {
        guard !favoriteCharactersData.isEmpty else { return [] }
        
        do {
            return try JSONDecoder().decode([Int].self, from: favoriteCharactersData)
        } catch {
            print("Error decoding favorite characters: \(error)")
            return []
        }
    }
    
    // Function to save the updated favorites list
    private func saveFavoriteCharacters(_ favorites: [Int]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            favoriteCharactersData = data
        } catch {
            print("Error encoding favorite characters: \(error)")
        }
    }
    
    // MARK: - Load Character Details
    
    private func loadCharacterDetails() {
        guard characterId != 0 else {
            self.errorMessage = "This character has an invalid ID (0)."
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔍 Loading character details for ID: \(characterId)")
        
        AniListAPI.shared.getCharacterDetails(id: characterId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let character = result {
                    print("✅ Successfully loaded character: \(character.name.full)")
                    self.characterDetail = character
                } else {
                    print("❌ Failed to load character details for ID: \(characterId)")
                    self.errorMessage = """
                        We couldn't retrieve the character information. \
                        Please check your connection and try again.
                        """
                }
            }
        }
    }
    
    // MARK: - Clean Description
    
    private func cleanDescription(_ description: String) -> String {
        var cleaned = description
        
        // 1) Remove underscores
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")
        
        // 2) Convert Markdown links [text](URL) -> text
        //    e.g. "[Sung Jin-Ah](https://...)" -> "Sung Jin-Ah"
        if let regex = try? NSRegularExpression(pattern: "\\[(.*?)\\]\\((.*?)\\)", options: []) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: NSRange(location: 0, length: cleaned.utf16.count),
                withTemplate: "$1"
            )
        }
        
        // 3) Remove leftover brackets e.g. "[Park Kyung-Hye]" -> "Park Kyung-Hye"
        cleaned = cleaned.replacingOccurrences(of: "[", with: "")
        cleaned = cleaned.replacingOccurrences(of: "]", with: "")
        
        // 4) Remove <br> or basic HTML tags
        cleaned = cleaned
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<i>", with: "")
            .replacingOccurrences(of: "</i>", with: "")
            .replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
        
        // 5) Remove source tags like (Source: Wikipedia)
        let sourcePatterns = [
            "(Source: .*?\\))",
            "(Source:.*?$)",
            "\\(Source:.*?\\)",
            "\\[Source:.*?\\]",
            "\\[Written by:.*?\\]",
            "\\(Written by:.*?\\)"
        ]
        for pattern in sourcePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    options: [],
                    range: NSRange(location: 0, length: cleaned.utf16.count),
                    withTemplate: ""
                )
            }
        }
        
        // Trim whitespace
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Background View
    
    private func characterBackgroundView(character: CharacterDetail) -> some View {
        ZStack {
            // Background blur with character image
            CachedAsyncImage(urlString: character.image?.medium ?? imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 20)
                    .brightness(-0.4)
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()
            
            // Overlay gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
