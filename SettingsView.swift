import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var showResetConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var showResetCompleted = false
    @State private var showImageCacheCleared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color(red: 0.05, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // App Information
                        GroupBox(
                            label: Label("App Information", systemImage: "info.circle")
                                .foregroundColor(.white)
                        ) {
                            VStack(spacing: 12) {
                                SettingsRow(title: "Version", detail: "1.0.0")
                                SettingsRow(title: "Build", detail: "103")
                                SettingsRow(title: "Device", detail: UIDevice.current.model)
                                SettingsRow(title: "iOS Version", detail: UIDevice.current.systemVersion)
                            }
                            .padding(.vertical, 8)
                        }
                        .groupBoxStyle(DarkGroupBoxStyle())
                        
                        // Cache and Data
                        GroupBox(
                            label: Label("Cache and Data", systemImage: "trash")
                                .foregroundColor(.white)
                        ) {
                            VStack(spacing: 0) {
                                Button(action: {
                                    showClearCacheConfirmation = true
                                }) {
                                    HStack {
                                        Text("Clear Image Cache")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 12)
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                Button(action: {
                                    showResetConfirmation = true
                                }) {
                                    HStack {
                                        Text("Reset All Data")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .groupBoxStyle(DarkGroupBoxStyle())
                        
                        // About
                        GroupBox(
                            label: Label("About PowerScale", systemImage: "doc.text")
                                .foregroundColor(.white)
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PowerScale helps you organize and rank your anime and manga collections.")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("Built with ♥ by Khalil")
                                    .foregroundColor(.white)
                                    .font(.footnote)
                            }
                            .padding(.vertical, 8)
                        }
                        .groupBoxStyle(DarkGroupBoxStyle())
                        
                        // Legal Information
                        GroupBox(
                            label: Label("Legal", systemImage: "doc.text")
                                .foregroundColor(.white)
                        ) {
                            VStack(spacing: 0) {
                                NavigationLink(
                                    destination: LegalTextView(title: "Terms of Service", content: termsOfService)
                                ) {
                                    HStack {
                                        Text("Terms of Service")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 12)
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                NavigationLink(
                                    destination: LegalTextView(title: "Privacy Policy", content: privacyPolicy)
                                ) {
                                    HStack {
                                        Text("Privacy Policy")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 12)
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                HStack {
                                    Text("Data Source")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("AniList API")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                            }
                            .padding(.vertical, 4)
                        }
                        .groupBoxStyle(DarkGroupBoxStyle())
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            })
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text("Reset All Data"),
                    message: Text("This will delete all your anime and manga lists. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Cache Cleared", isPresented: $showImageCacheCleared) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Image cache has been cleared successfully.")
            }
            .alert("Reset Completed", isPresented: $showResetCompleted) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All data has been reset successfully.")
            }
            .alert(isPresented: $showClearCacheConfirmation) {
                Alert(
                    title: Text("Clear Image Cache"),
                    message: Text("This will clear all cached images. They will be redownloaded when needed."),
                    primaryButton: .destructive(Text("Clear")) {
                        clearImageCache()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func resetAllData() {
        // Reset all data in CoreDataManager
        CoreDataManager.shared.resetAllData()
        
        // Reset ranking manager (will reload from core data)
        RankingManager.shared.loadAllDataFromCoreData()
        
        // Show confirmation
        showResetCompleted = true
    }
    
    private func clearImageCache() {
        // Clear the image cache
        ImageCache.shared.clearCache()
        
        // Show confirmation
        showImageCacheCleared = true
    }
}

// Settings row view for displaying key-value pairs
struct SettingsRow: View {
    var title: String
    var detail: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(detail)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// Custom group box style for dark background
struct DarkGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            HStack {
                configuration.label
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            configuration.content
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

// Legal text view for displaying terms and privacy policy
struct LegalTextView: View {
    var title: String
    var content: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// Sample legal text (placeholder)
let termsOfService = """
Terms of Service

Last Updated: March 10, 2025

1. Acceptance of Terms

By accessing or using PowerScale, you agree to be bound by these Terms of Service.

2. Changes to Terms

We reserve the right to modify these terms at any time. Your continued use of PowerScale constitutes your acceptance of the revised terms.

3. Privacy Policy

Your use of PowerScale is also governed by our Privacy Policy.

4. User Accounts

You are responsible for safeguarding your password and for all activities that occur under your account.

5. Content

PowerScale displays anime and manga information from AniList's API. We do not claim ownership of this content.

6. Prohibited Uses

You agree not to use PowerScale for any unlawful purpose or in any way that could damage, disable, or impair the service.

7. Termination

We may terminate or suspend your access to PowerScale without prior notice for any violation of these terms.

8. Disclaimer

PowerScale is provided "as is" without warranties of any kind.

9. Limitation of Liability

We shall not be liable for any indirect, incidental, special, consequential or punitive damages resulting from your use of PowerScale.

10. Governing Law

These terms shall be governed by and construed in accordance with the laws of the United States.
"""

let privacyPolicy = """
Privacy Policy

Last Updated: March 10, 2025

1. Information We Collect

PowerScale collects the following information:
- Account preferences and settings
- Your anime and manga lists and ratings
- App usage data to improve the service

2. How We Use Your Information

We use your information to:
- Provide, maintain, and improve PowerScale
- Personalize your experience
- Communicate with you about PowerScale

3. Information Sharing

We do not sell or share your personal information with third parties except as described in this policy.

4. Data Storage

All data is stored locally on your device and not transmitted to external servers except when interacting with the AniList API.

5. Data Security

We implement reasonable security measures to protect your information from unauthorized access.

6. Your Rights

You can delete all your data from PowerScale at any time using the Reset All Data function in Settings.

7. Changes to This Policy

We may update this policy from time to time. We will notify you of any changes by posting the new policy on this page.

8. Contact Us

If you have any questions about this Privacy Policy, please contact us.
"""

#Preview {
    SettingsView()
}
