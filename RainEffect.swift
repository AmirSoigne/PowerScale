
import SwiftUI

struct RainEffect: View {
    var body: some View {
        ZStack {
            ForEach(0..<200, id: \.self) { _ in
                RainDrop()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
            }
        }
    }
}

