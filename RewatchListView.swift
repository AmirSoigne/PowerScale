import SwiftUI

struct RewatchListView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ForEach with explicit index to force correct numbering
            ForEach(0..<viewModel.completedRewatches.count, id: \.self) { index in
                let rewatch = viewModel.completedRewatches[index]
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Force sequential numbering starting at 1
                        Text("Rewatch #\(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(4)
                        
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if rewatch.startDate != nil {
                        Text("Started: \(viewModel.formatDate(rewatch.startDate!))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let endDate = rewatch.endDate {
                        Text("Completed: \(viewModel.formatDate(endDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
    }
}
