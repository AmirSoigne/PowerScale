import SwiftUI

struct SummarySection: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionDivider()
            
            Text("SUMMARY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Text(viewModel.cleanedDescription)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.bottom, 10)
        }
    }
}
