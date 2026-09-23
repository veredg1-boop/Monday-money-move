import Foundation
import Combine
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
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let data = defaults.data(forKey: key),
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
            defaults.set(data, forKey: key)
        }
    }

    func requestWeeklyReminder() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        var date = DateComponents()
        date.weekday = 2
        date.hour = 9
        let content = UNMutableNotificationContent()
        content.title = "Your Monday Money Move"
        content.body = "Take one minute to choose this week’s smartest money move."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "weekly-money-move", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true))
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var monthlyProduct: Product?
    @Published var isSubscribed = false
    @Published var isWorking = false
    @Published var isLoadingProducts = false
    @Published var canOfferFreeTrial = false
    @Published var statusMessage: String?
    private let productID = "com.mondaymoneymove.monthly"

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        statusMessage = nil
        do {
            let products = try await Product.products(for: [productID])
            monthlyProduct = products.first { product in
                product.id == productID && product.type == .autoRenewable &&
                product.subscription?.subscriptionPeriod.unit == .month &&
                product.subscription?.subscriptionPeriod.value == 1
            }
            if monthlyProduct == nil {
                statusMessage = "Membership is currently unavailable. Please try again shortly."
            }
        } catch {
            monthlyProduct = nil
            statusMessage = "We couldn’t load membership details. Check your connection and try again."
        }
        await refreshStatus()
    }

    func purchase() async {
        guard !isWorking else { return }
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
        guard !isWorking else { return }
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
        var hasMembership = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == productID,
               transaction.revocationDate == nil,
               !transaction.isUpgraded {
                hasMembership = true
            }
        }
        isSubscribed = hasMembership
        await refreshTrialEligibility()
    }

    // Keep pending approvals, renewals, and refunds in sync while the app is open.
    // The view's structured task cancels this listener when its lifetime ends.
    func observeTransactions() async {
        for await update in Transaction.updates {
            guard !Task.isCancelled else { return }
            guard case .verified(let transaction) = update,
                  transaction.productID == productID else { continue }
            await refreshStatus()
            await transaction.finish()
        }
    }

    private func refreshTrialEligibility() async {
        canOfferFreeTrial = false
        guard !isSubscribed,
              let subscription = monthlyProduct?.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial,
              offer.periodCount == 1 else { return }
        let isSevenDays = (offer.period.unit == .day && offer.period.value == 7) ||
            (offer.period.unit == .week && offer.period.value == 1)
        guard isSevenDays else { return }
        canOfferFreeTrial = await subscription.isEligibleForIntroOffer
    }
}

