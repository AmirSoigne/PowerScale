import SwiftUI

struct SelectionMenuView: View {
    @Binding var isPresented: Bool
    let animeTitle: String
    let isAnime: Bool
    let animeId: Int
    let totalEpisodes: Int
    
    // Callback that passes all the necessary information
    let onSelection: (String, Date?, Date?, Bool, Int) -> Void
    
    // State for collecting information
    @State private var selectedStatus: String = ""
    @State private var showDatePickers: Bool = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var trackStartDate: Bool = false
    @State private var trackEndDate: Bool = true
    @State private var showRewatchOption: Bool = false
    @State private var currentStatus: String = ""
    @State private var hasCompletedBefore: Bool = false
    @State private var isStartingRewatch: Bool = false
    @State private var isCompletingRewatch: Bool = false
    @State private var isCurrentlyRewatching: Bool = false
    @State private var currentRewatchCount: Int = 0
    
    // Reference to ranking manager
    @ObservedObject private var rankingManager = RankingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            Text(animeTitle)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.9))
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Status options group based on current state
            VStack(spacing: 0) {
                // If currently rewatching, show the complete rewatch option prominently
                if isCurrentlyRewatching {
                    menuItem(
                        icon: "checkmark.seal",
                        text: "Complete Rewatch #\(currentRewatchCount)",
                        action: {
                            isCompletingRewatch = true
                            selectedStatus = "Completed"
                            trackEndDate = true
                            showDatePickers = true
                        }
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.vertical, 2)
                }
                // If completed but not rewatching, show start rewatch option
                else if hasCompletedBefore && currentStatus == "Completed" {
                    let nextRewatchNum = getNextRewatchNumber()
                    menuItem(
                        icon: "arrow.counterclockwise",
                        text: "Start Rewatch #\(nextRewatchNum)",
                        action: {
                            isStartingRewatch = true
                            selectedStatus = "Currently \(isAnime ? "Watching" : "Reading")"
                            // Immediately select
                            select(selectedStatus)
                        }
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.vertical, 2)
                }
                
                // Regular status options
                menuItem(
                    icon: "calendar.badge.plus",
                    text: isAnime ? "Add to Want to Watch" : "Add to Want to Read",
                    action: {
                        selectedStatus = isAnime ? "Want to Watch" : "Want to Read"
                        select(selectedStatus)
                    }
                )
                
                menuItem(
                    icon: "checkmark.circle",
                    text: "Completed",
                    action: {
                        selectedStatus = "Completed"
                        isCompletingRewatch = false
                        showDatePickers = true
                    }
                )
                
                menuItem(
                    icon: "play.circle",
                    text: isAnime ? "Currently Watching" : "Currently Reading",
                    action: {
                        selectedStatus = isAnime ? "Currently Watching" : "Currently Reading"
                        isStartingRewatch = false
                        showDatePickers = true
                    }
                )
                
                menuItem(
                    icon: "pause.circle",
                    text: "On Hold",
                    action: {
                        selectedStatus = "On Hold"
                        select(selectedStatus)
                    }
                )
                
                menuItem(
                    icon: "xmark.circle",
                    text: "Lost Interest",
                    action: {
                        selectedStatus = "Lost Interest"
                        select(selectedStatus)
                    }
                )
            }
            
            // Date selection if needed
            if showDatePickers {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.5))
                    
                    // For Completed status
                    if selectedStatus == "Completed" {
                        if !isCompletingRewatch {
                            Toggle("I know when I started", isOn: $trackStartDate)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                            
                            if trackStartDate {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .padding(.horizontal)
                                    .foregroundColor(.white)
                                    .accentColor(.blue)
                            }
                        }
                        
                        Toggle("Track completion date", isOn: $trackEndDate)
                            .padding(.horizontal)
                            .foregroundColor(.white)
                        
                        if trackEndDate {
                            if isCompletingRewatch {
                                DatePicker("Rewatch #\(currentRewatchCount) Completion Date", selection: $endDate, displayedComponents: .date)
                                    .padding(.horizontal)
                                    .foregroundColor(.white)
                                    .accentColor(.blue)
                            } else {
                                DatePicker("Completion Date", selection: $endDate, displayedComponents: .date)
                                    .padding(.horizontal)
                                    .foregroundColor(.white)
                                    .accentColor(.blue)
                            }
                        }
                    }
                    
                    // For Currently Watching/Reading status
                    if selectedStatus.starts(with: "Currently") {
                        Toggle("I know when I started", isOn: $trackStartDate)
                            .padding(.horizontal)
                            .foregroundColor(.white)
                        
                        if trackStartDate {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .accentColor(.blue)
                        }
                    }
                    
                    // Confirm button
                    Button(action: {
                        select(selectedStatus)
                    }) {
                        Text("Confirm")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 12)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showDatePickers)
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Share option
            menuItem(
                icon: "square.and.arrow.up",
                text: "Share",
                action: { select("Share") }
            )
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Cancel button
            Button(action: { isPresented = false }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 270)
        .background(
            // More solid background with less transparency
            ZStack {
                Color.black.opacity(0.9)
                
                // Very subtle gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.02)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 15, x: 0, y: 5)
        .onAppear {
            // Check current status and if item has been completed before
            checkItemStatus()
            
            // Initialize date tracking flags
            if selectedStatus == "Completed" {
                trackEndDate = true
                trackStartDate = false
            } else if selectedStatus.starts(with: "Currently") {
                trackStartDate = false
            }
        }
    }
    
    // Helper function to create consistent menu items
    private func menuItem(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Handle selection and dismiss the menu
    private func select(_ status: String) {
        if status == "Share" {
            // Handle share action differently
            // (You could implement sharing functionality here)
            isPresented = false
            return
        }
        
        withAnimation(.easeIn(duration: 0.15)) {
            // Determine which dates to pass
            let startDateToUse = trackStartDate ? startDate : Date() // Always use current date if not explicitly chosen
            let endDateToUse = trackEndDate && (selectedStatus == "Completed") ? endDate : nil
            
            // Determine the rewatch count to use
            let rewatchCount: Int
            if isStartingRewatch {
                rewatchCount = getNextRewatchNumber()
            } else if isCompletingRewatch {
                rewatchCount = currentRewatchCount
            } else {
                rewatchCount = 0
            }
            
            // Call the callback with all information
            onSelection(
                status,
                startDateToUse,
                endDateToUse,
                isStartingRewatch || isCompletingRewatch,
                rewatchCount
            )
            isPresented = false
        }
    }
    
    // Check the current status of the item
    private func checkItemStatus() {
        // Get current status from RankingManager
        currentStatus = rankingManager.getCurrentStatus(id: animeId, isAnime: isAnime)
        
        // Check if this item has been completed before
        hasCompletedBefore = currentStatus == "Completed" ||
                             rankingManager.hasRewatches(id: animeId, isAnime: isAnime)
        
        // Check if this is currently being rewatched
        if let currentRewatch = rankingManager.getCurrentRewatchItem(id: animeId, isAnime: isAnime) {
            isCurrentlyRewatching = true
            currentRewatchCount = currentRewatch.rewatchCount
        } else {
            isCurrentlyRewatching = false
            currentRewatchCount = 0
        }
    }
    
    // Get the next rewatch number for a new rewatch
    private func getNextRewatchNumber() -> Int {
        // Call the ranking manager's method to get the next rewatch number
        return rankingManager.getNextRewatchNumber(id: animeId, isAnime: isAnime)
    }
}
