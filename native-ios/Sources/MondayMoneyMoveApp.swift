import SwiftUI

@main
struct MondayMoneyMoveApp: App {
    @StateObject private var store = MoveStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(purchases)
                .task { await purchases.loadProducts() }
        }
    }
}
