import SwiftUI

struct RatingSection: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    
    var body: some View {
        HStack {
            Text("Your Rating:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Use the RatingView component
            RatingView(viewModel: viewModel, showLabel: false, showInline: true)
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
    }
}
