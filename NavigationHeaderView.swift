import SwiftUI

struct NavigationHeaderView: View {
    var presentationMode: Binding<PresentationMode>
    @Binding var showOptionsMenu: Bool
    
    var body: some View {
        VStack {
            // Add more space at the top to push buttons down
            Spacer().frame(height: 15)
            
            HStack {
                // Back button
                Button(action: {
                    // Dismiss the view using presentationMode
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Options button
                Button(action: {
                    withAnimation {
                        showOptionsMenu.toggle()
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 55) // Increased from 40 to push buttons down
            
            Spacer()
        }
    }
}
