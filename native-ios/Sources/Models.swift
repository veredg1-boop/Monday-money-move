import Foundation
import StoreKit
import UserNotifications

struct MoneyMove: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let text: String
    var completed: Bool
}

@MainActor
final class MoveStore: ObservableObject {
    @Published var moves: [MoneyMove] = [] { didSet { save() } }
    private let key = "mondayMoneyMoves"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MoneyMove].self, from: data)
        else { return }
        moves = decoded
    }

    var current: MoneyMove? { moves.first }
    var completedCount: Int { moves.filter(\.completed).count }

    func add(_ text: String) {
        moves.insert(MoneyMove(id: UUID(), createdAt: Date(), text: text, completed: false), at: 0)
    }

    func completeCurrent() {
        guard !moves.isEmpty else { return }
        moves[0].completed = true
    }

    func clearAll() {
        moves = []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(moves) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func requestWeeklyReminder() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        var date = DateComponents()
        date.weekday = 2
        date.hour = 9
        let content = UNMutableNotificationContent()
        content.title = "Your Monday Money Move"
        content.body = "Take one minute to choose this week’s smartest money move."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "weekly-money-move", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true))
        try? await center.add(request)
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var monthlyProduct: Product?
    @Published var isSubscribed = false
    @Published var isWorking = false
    @Published var statusMessage: String?
    private let productID = "com.mondaymoneymove.monthly"

    func loadProducts() async {
        monthlyProduct = try? await Product.products(for: [productID]).first
        await refreshStatus()
    }

    func purchase() async {
        guard let product = monthlyProduct else {
            statusMessage = "The subscription is temporarily unavailable. Please try again."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    statusMessage = "Apple could not verify this purchase."
                    return
                }
                await transaction.finish()
                await refreshStatus()
                statusMessage = isSubscribed ? "Membership activated." : nil
            case .pending:
                statusMessage = "Your purchase is waiting for Apple’s approval."
            case .userCancelled:
                statusMessage = nil
            @unknown default:
                statusMessage = "The purchase could not be completed."
            }
        } catch {
            statusMessage = "The purchase could not be completed. Please try again."
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshStatus()
            statusMessage = isSubscribed ? "Your membership has been restored." : "No active membership was found."
        } catch {
            statusMessage = "We couldn’t restore purchases. Please try again."
        }
    }

    func refreshStatus() async {
        isSubscribed = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == productID {
                isSubscribed = true
            }
        }
    }
}
