import SwiftUI
import CoreData

@main
struct PowerScaleApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showLoadingScreen = true
    
    // Initialize Core Data first before anything else can use it
    let coreDataManager = CoreDataManager.shared
    
    // Use UIApplicationDelegateAdaptor to connect AppDelegate
    @UIApplicationDelegateAdaptor(PowerScaleAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            if !hasLaunchedBefore || showLoadingScreen {
                LoadingScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showLoadingScreen = false
                            hasLaunchedBefore = true
                        }
                    }
                    // Also add the environment here
                    .environment(\.managedObjectContext, coreDataManager.container.viewContext)
            } else {
                MainView()
                    .environment(\.managedObjectContext, coreDataManager.container.viewContext)
            }
        }
    }
}
