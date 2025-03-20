import SwiftUI

struct BackgroundView: View {
    let anime: Anime
    
    var body: some View {
        ZStack {
            // Background blur of anime image
            CachedAsyncImage(urlString: anime.coverImage.large) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 8)
                    .brightness(-0.2)
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()
            
            // Content overlay with gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
