import SwiftUI

struct RatingView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    var showLabel: Bool = true
    var showInline: Bool = false
    
    // Add state for the text field value
    @State private var ratingText: String = ""
    // State to track whether the rating is being edited
    @State private var isEditing: Bool = false
    
    init(viewModel: AnimeDetailViewModel, showLabel: Bool = true, showInline: Bool = false) {
        self.viewModel = viewModel
        self.showLabel = showLabel
        self.showInline = showInline
        // Initialize the rating text state with the current rating
        self._ratingText = State(initialValue: String(format: "%.1f", viewModel.temporaryRating))
    }
    
    var body: some View {
        if showInline {
            // Inline horizontal layout
            HStack(spacing: 10) {
                if isEditing || viewModel.isRatingChanged {
                    // EDIT MODE: Show input controls
                    TextField("0.0", text: $ratingText)
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .padding(4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(5)
                        .foregroundColor(.white)
                        .onChange(of: ratingText) { oldValue, newValue in
                            updateRatingFromText(newValue)
                        }
                        .onAppear {
                            ratingText = String(format: "%.1f", viewModel.temporaryRating)
                        }
                    
                    // Slider for adjusting rating
                    Slider(
                        value: Binding(
                            get: { viewModel.temporaryRating },
                            set: {
                                viewModel.temporaryRating = $0
                                ratingText = String(format: "%.1f", $0)
                                viewModel.isRatingChanged = true
                            }
                        ),
                        in: 0...10,
                        step: 0.1
                    )
                    .accentColor(.yellow)
                    
                    Text("/10")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    
                    // Save button
                    Button(action: {
                        viewModel.userRating = viewModel.temporaryRating
                        viewModel.updateRating() // This saves to CoreData
                        viewModel.isRatingChanged = false
                        isEditing = false
                    }) {
                        Text("Save")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                } else {
                    // VIEW MODE: Just show the rating with an edit button
                    Text("\(String(format: "%.1f", viewModel.userRating))/10")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        isEditing = true
                        viewModel.temporaryRating = viewModel.userRating
                        ratingText = String(format: "%.1f", viewModel.userRating)
                    }) {
                        Text("Edit")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
            }
        } else {
            // Full vertical layout (code omitted for brevity, similar to inline layout)
            VStack(spacing: 12) {
                if showLabel {
                    HStack {
                        Text("Your Rating:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
                
                if isEditing || viewModel.isRatingChanged {
                    // EDIT MODE: Full controls
                    HStack {
                        // Text field for direct numerical input
                        TextField("0.0", text: $ratingText)
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .padding(6)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(5)
                            .foregroundColor(.white)
                            .onChange(of: ratingText) { oldValue, newValue in
                                updateRatingFromText(newValue)
                            }
                            .onAppear {
                                ratingText = String(format: "%.1f", viewModel.temporaryRating)
                            }
                        
                        // Slider for adjusting rating
                        Slider(
                            value: Binding(
                                get: { viewModel.temporaryRating },
                                set: {
                                    viewModel.temporaryRating = $0
                                    ratingText = String(format: "%.1f", $0)
                                    viewModel.isRatingChanged = true
                                }
                            ),
                            in: 0...10,
                            step: 0.1
                        )
                        .accentColor(.yellow)
                        
                        // Display the numerical value
                        Text("/10")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    
                    // Save button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            viewModel.userRating = viewModel.temporaryRating
                            viewModel.updateRating() // This saves to CoreData
                            viewModel.isRatingChanged = false
                            isEditing = false
                        }) {
                            Text("Save Rating")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                } else {
                    // VIEW MODE: Just show the rating with an edit button
                    HStack {
                        Text("\(String(format: "%.1f", viewModel.userRating))/10")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        
                        Spacer()
                        
                        Button(action: {
                            isEditing = true
                            viewModel.temporaryRating = viewModel.userRating
                            ratingText = String(format: "%.1f", viewModel.userRating)
                        }) {
                            Text("Edit")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Function to update the rating value from text input
    private func updateRatingFromText(_ text: String) {
        // Filter out invalid characters
        let filtered = text.filter { "0123456789.".contains($0) }
        
        // Only allow one decimal point
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            let firstPart = components.first ?? ""
            let secondPart = components.dropFirst().joined()
            ratingText = firstPart + "." + secondPart
        } else {
            ratingText = filtered
        }
        
        // Convert to Double
        if let value = Double(ratingText), value <= 10 {
            viewModel.temporaryRating = value
            viewModel.isRatingChanged = true
        } else if ratingText.isEmpty || ratingText == "." {
            viewModel.temporaryRating = 0
            viewModel.isRatingChanged = true
        } else if Double(ratingText) ?? 0 > 10 {
            viewModel.temporaryRating = 10
            ratingText = "10.0"
            viewModel.isRatingChanged = true
        }
    }
}
