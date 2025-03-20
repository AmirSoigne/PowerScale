 

import SwiftUI

struct RainDrop: View {
    @State private var yOffset: CGFloat = -100
    
    var body: some View {
        Rectangle()
            .frame(width: 2, height: CGFloat.random(in: 10...30))
            .foregroundColor(Color.white.opacity(0.1))
            .offset(y: yOffset)
            .onAppear {
                withAnimation(Animation.linear(duration: Double.random(in: 0.6...1.2)).repeatForever(autoreverses: false)) {
                    yOffset = UIScreen.main.bounds.height + 50
                }
            }
    }
}
