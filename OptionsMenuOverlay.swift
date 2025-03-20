import SwiftUI

struct OptionsMenuOverlay: View {
    @Binding var isPresented: Bool
    let animeTitle: String
    let isAnime: Bool
    let animeId: Int
    let totalEpisodes: Int
    let onSelection: (String, Date?, Date?, Bool, Int) -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background for menu (tap to dismiss)
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Menu positioned in the center of the screen
            SelectionMenuView(
                isPresented: $isPresented,
                animeTitle: animeTitle,
                isAnime: isAnime,
                animeId: animeId,
                totalEpisodes: totalEpisodes,
                onSelection: onSelection
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
