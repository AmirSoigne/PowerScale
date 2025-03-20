

import SwiftUI

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            // Background Image
            Image("bg")
                .resizable()
                .ignoresSafeArea()
                .opacity(1)
                .saturation(0.3)

            VStack {
                // Glitchy Logo
                GlitchLogo()
            }

            // Rain Effect (Ensures it's in the background)
            RainEffect()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    LoadingScreen()
}

