// UserProgressSection.swift - Updated to remove duplicate rating view

import SwiftUI

struct UserProgressSection: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    @Binding var showOptionsMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR STATUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Current status indicator
            HStack {
                if !viewModel.userStatus.isEmpty {
                    statusLabel(viewModel.isRewatch ? "\(viewModel.userStatus) (Rewatch #\(viewModel.rewatchCount))" : viewModel.userStatus)
                } else {
                    Text("Not in your list")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showOptionsMenu.toggle()
                    }
                }) {
                    Text(viewModel.userStatus.isEmpty ? "Add to List" : "Change")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Progress tracking if currently watching/reading
            if viewModel.userStatus.starts(with: "Currently") {
                HStack {
                    Text("Progress:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(viewModel.watchedEpisodes) / \(viewModel.totalEpisodes)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.watchedEpisodes > 0 {
                            viewModel.watchedEpisodes -= 1
                            viewModel.updateProgress()
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        if viewModel.watchedEpisodes < viewModel.totalEpisodes {
                            viewModel.watchedEpisodes += 1
                            viewModel.updateProgress()
                        }
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            
            // Display completion date if completed (not in rewatch)
            if viewModel.userStatus == "Completed" && !viewModel.isRewatch && viewModel.endDate != nil {
                Text("Completed: \(viewModel.formatDate(viewModel.endDate!))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            
            // IMPORTANT: The duplicate rating view was here - removed to fix the issue
            // Now the only rating view is the one in AnimeDetailView
        }
    }
    
    private func statusLabel(_ status: String) -> some View {
        Text(status)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(viewModel.statusColor(for: status.split(separator: " ").first?.description ?? "").opacity(0.3))
            .cornerRadius(8)
    }
}
