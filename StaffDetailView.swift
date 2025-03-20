import SwiftUI



// Make both DateInfo structs conform to the protocol


struct StaffDetailView: View {
    let staffId: Int
    let staffName: String
    let imageURL: String
    
    @State private var staffDetail: StaffDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var retryCount = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle(staffName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadStaffDetails()
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error: error)
            } else if let staff = staffDetail {
                staffDetailsView(staff: staff)
            } else {
                Text("No staff details available")
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 250)
                    .cornerRadius(10)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray.opacity(0.5))
                
                ShimmerView()
                    .frame(width: 180, height: 250)
                    .cornerRadius(10)
                    .opacity(0.7)
            }
            
            Text(staffName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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
    
    // MARK: - Staff Details View
    
    private func staffDetailsView(staff: StaffDetail) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Staff image
                CachedAsyncImage(urlString: staff.image?.large ?? imageURL) { image in
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
                
                // Display staff name in native and English
                VStack(spacing: 8) {
                    Text(staff.name.full)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let nativeName = staff.name.native, !nativeName.isEmpty {
                        Text(nativeName)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    // Info cards for occupation, gender, age, etc.
                    staffInfoCards(staff: staff)
                }
                .padding(.horizontal)
                
                // Staff description/bio
                if let description = staff.description, !description.isEmpty {
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
                
                // Characters voiced section
                if let characters = staff.characters?.edges, !characters.isEmpty {
                    SectionDivider()
                    VStack(alignment: .leading, spacing: 15) {
                        Text("CHARACTERS VOICED")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(characters, id: \.self) { edge in
                                    if let node = edge.node {
                                        NavigationLink(destination: CharacterDetailView(
                                            characterId: node.id,
                                            characterName: node.name.full,
                                            imageURL: node.image?.medium ?? ""
                                        )) {
                                            VStack(alignment: .center, spacing: 8) {
                                                CachedAsyncImage(urlString: node.image?.medium ?? "") { image in
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
                                                
                                                Text(node.name.full)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 100)
                                                
                                                if let role = edge.role {
                                                    Text(role)
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Media worked on section
                if let mediaWorked = staff.characterMedia?.edges, !mediaWorked.isEmpty {
                    SectionDivider()
                    VStack(alignment: .leading, spacing: 15) {
                        Text("FEATURED IN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(mediaWorked, id: \.self) { edge in
                                    if let media = edge.node {
                                        NavigationLink(destination: AnimeDetailView(
                                            anime: convertToAnime(media),
                                            isAnime: true)
                                        ) {
                                            VStack(alignment: .center, spacing: 8) {
                                                CachedAsyncImage(urlString: media.coverImage.large) { image in
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
                                                
                                                Text(media.title.english ?? media.title.romaji ?? "Unknown")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 100)
                                                
                                                if let role = edge.characterRole {
                                                    Text(role)
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(
            staffBackgroundView(staff: staff)
        )
    }
    
    private func staffInfoCards(staff: StaffDetail) -> some View {
        VStack {
            HStack(spacing: 15) {
                if let occupations = staff.primaryOccupations, !occupations.isEmpty {
                    InfoCard(
                        title: "Occupation",
                        value: occupations.joined(separator: ", ")
                    )
                }
                
                if let gender = staff.gender, !gender.isEmpty {
                    InfoCard(
                        title: "Gender",
                        value: gender
                    )
                }
                
                if let age = staff.age {
                    InfoCard(
                        title: "Age",
                        value: "\(age)"
                    )
                }
            }
            .padding(.top, 12)
            
            if let dateOfBirth = staff.dateOfBirth, dateOfBirth.month != nil {
                HStack {
                    InfoCard(
                        title: "Birthday",
                        value: formatBirthday(dateOfBirth)
                    )
                    
                    if let yearsActive = staff.yearsActive, !yearsActive.isEmpty {
                        InfoCard(
                            title: "Years Active",
                            value: formatYearsActive(yearsActive)
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helper methods
    
    // Updated to use the protocol
    private func formatBirthday(_ date: DateInfoProtocol) -> String {
        var components = [String]()
        
        if let month = date.month {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let calendar = Calendar.current
            if let monthDate = calendar.date(from: DateComponents(month: month)) {
                components.append(formatter.string(from: monthDate))
            }
        }
        
        if let day = date.day {
            components.append("\(day)")
        }
        
        if let year = date.year {
            components.append("\(year)")
        }
        
        return components.joined(separator: " ")
    }
    
    private func formatYearsActive(_ years: [Int]) -> String {
        if years.count == 1 {
            return "Since \(years[0])"
        } else if years.count >= 2 {
            return "\(years[0]) - \(years[years.count-1])"
        }
        return "Unknown"
    }
    
    private func convertToAnime(_ media: StaffDetail.Media) -> Anime {
        return Anime(
            id: media.id,
            title: media.title,
            coverImage: media.coverImage,
            description: nil,
            episodes: nil,
            chapters: nil,
            volumes: nil,
            duration: nil,
            status: nil,
            format: nil,
            season: nil,
            seasonYear: nil,
            isAdult: false,
            startDate: nil,
            endDate: nil,
            genres: nil,
            tags: nil,
            averageScore: nil,
            meanScore: nil,
            popularity: nil,
            favourites: nil,
            trending: nil,
            rankings: nil,
            studios: nil,
            producers: nil,
            staff: nil,
            relations: nil,
            characters: nil,
            externalLinks: nil,
            trailer: nil,
            streamingEpisodes: nil,
            nextAiringEpisode: nil,
            recommendations: nil,
            bannerImage: nil
        )
    }
    
    // MARK: - Background view
    
    private func staffBackgroundView(staff: StaffDetail) -> some View {
        ZStack {
            CachedAsyncImage(urlString: staff.image?.large ?? imageURL) { image in
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
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.yellow)
            
            Text("Couldn't load staff details")
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
                loadStaffDetails()
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
    
    // MARK: - Load Data
    
    private func loadStaffDetails() {
        // Make sure we're loading
        isLoading = true
        errorMessage = nil
        
        // Add a print statement for debugging
        print("🎬 Loading staff details for ID: \(staffId)")
        
        AniListAPI.shared.getStaffDetails(id: staffId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let staff = result {
                    print("✅ Successfully loaded staff: \(staff.name.full)")
                    self.staffDetail = staff
                    
                    // Debug what data we received
                    print("🔍 Staff Data:")
                    print("- Has description: \(staff.description != nil)")
                    print("- Has characters: \(staff.characters?.edges?.count ?? 0) characters")
                    print("- Has media: \(staff.characterMedia?.edges?.count ?? 0) media")
                } else {
                    self.errorMessage = """
                        We couldn't retrieve the staff information.
                        Please check your connection and try again.
                        """
                    print("❌ Failed to load staff details for ID: \(staffId)")
                }
            }
        }
    }
    
    // MARK: - Clean Description
    
    private func cleanDescription(_ description: String) -> String {
        var cleaned = description
        
        // Remove underscores, tildes, or any other special chars
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")
        cleaned = cleaned.replacingOccurrences(of: "~", with: "")
        
        // Remove markdown links [text](url) -> text
        if let regex = try? NSRegularExpression(pattern: "\\[(.*?)\\]\\((.*?)\\)", options: []) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: NSRange(location: 0, length: cleaned.utf16.count),
                withTemplate: "$1"
            )
        }
        
        // Remove leftover brackets
        cleaned = cleaned.replacingOccurrences(of: "[", with: "")
        cleaned = cleaned.replacingOccurrences(of: "]", with: "")
        
        // Remove <br> or basic HTML tags
        cleaned = cleaned
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<i>", with: "")
            .replacingOccurrences(of: "</i>", with: "")
            .replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
        
        // Remove source tags like (Source: Wikipedia)
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
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Info card component
struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}
