import SwiftUI

struct WatchHistoryView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Only show "Original Watch" label if there are rewatches
            if viewModel.hasRewatches {
                // Original watch info (only shown when there are rewatches)
                if let originalItem = viewModel.findOriginalCompletedItem() {
                    VStack(alignment: .leading, spacing: 4) {
                        // Header for original completion
                        HStack {
                            Text("Original Watch")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Force left alignment
                        
                        // Original watch dates
                        if originalItem.startDate != nil {
                            Text("Started: \(viewModel.formatDate(originalItem.startDate!))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let endDate = originalItem.endDate {
                            Text("Completed: \(viewModel.formatDate(endDate))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            // Removed the duplicate completion date display that was here
            
            // If there are rewatches, display them
            if viewModel.hasRewatches {
                // Show the rewatch history toggle and list
                if !viewModel.completedRewatches.isEmpty {
                    Button(action: {
                        withAnimation {
                            viewModel.showRewatchHistory.toggle()
                        }
                    }) {
                        HStack {
                            // Create a set of unique rewatch numbers
                            let uniqueRewatchCounts = Set(viewModel.completedRewatches.map { $0.rewatchCount })
                            
                            Text("Rewatch History (\(uniqueRewatchCounts.count))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: viewModel.showRewatchHistory ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if viewModel.showRewatchHistory {
                        RewatchListView(viewModel: viewModel)
                    }
                }
            }
        }
    }
}
