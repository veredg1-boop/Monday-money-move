import SwiftUI

@main
struct MondayMoneyMoveApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = MoveStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(purchases)
                .task { await purchases.loadProducts() }
                .task { await purchases.observeTransactions() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await purchases.refreshStatus() }
                    }
                }
        }
    }
}
