
import SwiftUI

struct GlitchLogo: View {
    @State private var glitchOffset: CGFloat = 0
    @State private var glitchOpacity: Double = 0.8
    
    var body: some View {
     
            
            
            VStack {
                // Glitchy Logo Effect
                ZStack {
                    Image("logo")
                        .resizable()
                        .frame(width: 400, height: 400)
                        .padding()
                        .colorMultiply(.black)
                    
                    // Red Layer (Slight Offset)
                    Image("logo")
                        .resizable()
                        .frame(width: 400, height: 400)
                        .padding()
                        .colorMultiply(.blue)
                        .offset(x: glitchOffset, y: -glitchOffset)
                        .opacity(glitchOpacity)
                    
                    // Blue Layer (Slight Offset)
                    Image("logo")
                        .resizable()
                        .frame(width: 400, height: 400)
                        .padding()
                        .colorMultiply(.purple)
                        .offset(x: -glitchOffset, y: glitchOffset)
                        .opacity(glitchOpacity)
                  
                    
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                glitchOffset = 5
                                glitchOpacity = 1
                            }
                          
                        }
                }
            }
            .offset(y: -150)
        }
    }

