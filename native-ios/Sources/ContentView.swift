import SwiftUI
import UIKit
import StoreKit
import WebKit

private enum BrandPalette {
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.12)
    static let green = Color(red: 0.086, green: 0.208, blue: 0.184)
    static let midGreen = Color(red: 0.224, green: 0.459, blue: 0.384)
    static let mint = Color(red: 0.875, green: 0.945, blue: 0.914)
    static let cream = Color(red: 0.969, green: 0.957, blue: 0.933)
    static let choice = Color(red: 0.953, green: 0.961, blue: 0.953)
}

struct LegacyWeeklyCheckInView: View {
    @EnvironmentObject private var store: MoveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var screen: Screen = .home
    @State private var goal = ""
    @State private var pace = ""
    @State private var recommendation = ""
    @State private var reminderMessage: String?
    @State private var showDeleteConfirmation = false

    enum Screen { case home, goal, pace, style, result, history, membership, settings, information }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [BrandPalette.cream, BrandPalette.mint.opacity(0.72)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        brand
                        if let current = store.current { currentMove(current) }
                        content
                    }
                    .padding()
                }
            }
            .foregroundStyle(BrandPalette.ink)
            .tint(BrandPalette.midGreen)
        }
    }

    private var brand: some View {
        HStack(spacing: 12) {
            Text("M").font(.title2.bold()).foregroundStyle(.white).frame(width: 48, height: 48).background(BrandPalette.green).clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading) {
                Text("Monday Money Move").font(.headline)
                Text("One smarter move each week").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { screen = .history } label: { Image(systemName: "chart.bar.xaxis") }
        }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .home: home
        case .goal: question("What would make the biggest difference right now?", options: [("Pay down debt","debt"),("Build my savings","save"),("Reduce unnecessary spending","spend"),("Get my finances organized","organize")]) { goal=$0; screen = .pace }
        case .pace: question("What level of move feels right this week?", options: [("A simple move — up to $100","small"),("A meaningful move — $100–$500","medium"),("A stronger move — $500–$2,500","large"),("A significant move — $2,500+","xlarge")]) { pace=$0; screen = .style }
        case .style: question("What kind of action would help most?", options: [("Set it up automatically","automatic"),("Take one action today","once"),("Review and make a decision","review")]) { recommendation = move(for: goal, pace: pace, style: $0); screen = .result }
        case .result: resultCard
        case .history: historyCard
        case .membership: membershipCard
        case .settings: settingsCard
        case .information: informationCard
        }
    }

    private var home: some View {
        card {
            VStack(alignment: .leading, spacing: 18) {
                Text("YOUR WEEKLY MONEY CHECK-IN").font(.caption.bold()).foregroundStyle(BrandPalette.midGreen)
                Text("Stop wondering what to do with your money next.").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("A one-minute weekly check-in that turns financial overwhelm into one clear, manageable action.").font(.title3).foregroundStyle(.secondary)
                primaryButton(store.moves.isEmpty || purchases.isSubscribed ? "Start This Week’s Check-In" : "Unlock This Week’s Move") {
                    screen = store.moves.isEmpty || purchases.isSubscribed ? .goal : .membership
                }
                Button("Remind me every Monday") {
                    Task {
                        let enabled = await store.requestWeeklyReminder()
                        reminderMessage = enabled ? "Monday reminder scheduled for 9:00 AM." : "Reminders are turned off. You can enable them in iPhone Settings."
                    }
                }.font(.subheadline.bold())
                if let reminderMessage {
                    Text(reminderMessage).font(.footnote).foregroundStyle(.secondary)
                }
                if !store.moves.isEmpty {
                    Text("\(store.completedCount) of \(store.moves.count) weekly moves completed")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Divider()
                HStack {
                    Button("Important Information") { screen = .information }
                    Spacer()
                    Button("Settings") { screen = .settings }
                }.font(.footnote.bold())
            }
        }
    }

    private func question(_ title: String, options: [(String,String)], action: @escaping (String)->Void) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("WEEKLY CHECK-IN").font(.caption.bold()).foregroundStyle(.secondary)
                Text(title).font(.title.bold())
                ForEach(options, id: \.1) { item in
                    Button { action(item.1) } label: {
                        HStack { Text(item.0); Spacer(); Image(systemName:"arrow.right") }
                            .padding().frame(maxWidth:.infinity).background(BrandPalette.choice).clipShape(RoundedRectangle(cornerRadius:14))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var resultCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("YOUR MONDAY MONEY MOVE").font(.caption.bold()).foregroundStyle(.secondary)
                Text("One focused action for this week").font(.title.bold())
                Text(recommendation).font(.title3.bold()).padding().background(BrandPalette.cream).clipShape(RoundedRectangle(cornerRadius:14))
                primaryButton("Save My Move") { store.add(recommendation); screen = .home }
            }
        }
    }

    private var historyCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR PROGRESS").font(.caption.bold()).foregroundStyle(.secondary)
                Text("\(store.completedCount) moves completed").font(.title.bold())
                if store.moves.isEmpty { Text("Your weekly moves will appear here.").foregroundStyle(.secondary) }
                ForEach(store.moves) { move in
                    HStack(alignment:.top) {
                        Image(systemName: move.completed ? "checkmark.circle.fill" : "circle").foregroundStyle(.green)
                        VStack(alignment:.leading) {
                            Text(move.text)
                            Text(move.createdAt.formatted(date:.abbreviated,time:.omitted)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                }
                Button("Back") { screen = .home }
            }
        }
    }

    private var membershipCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("MONDAY MONEY MOVE MEMBERSHIP").font(.caption.bold()).foregroundStyle(.secondary)
                Text("Keep your momentum going").font(.title.bold())
                Text("Get a fresh, focused money move each week, save your progress, and use Monday reminders.")
                    .font(.title3).foregroundStyle(.secondary)
                Text(purchases.monthlyProduct?.displayPrice ?? "$9.99")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                + Text(" / month").font(.headline).foregroundColor(.secondary)
                Text("Start with a 7-day free trial, then continue for \(purchases.monthlyProduct?.displayPrice ?? "$9.99") per month. The trial is available to eligible new subscribers. Cancel anytime in Apple Account settings.")
                    .font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Today: begin your free trial", systemImage: "checkmark.circle.fill")
                    Label("Day 7: subscription begins at \(purchases.monthlyProduct?.displayPrice ?? "$9.99") per month", systemImage: "calendar")
                    Label("Cancel anytime in Apple Account settings", systemImage: "gearshape")
                }
                .font(.subheadline)
                .foregroundStyle(BrandPalette.green)
                primaryButton(purchases.isWorking ? "Please wait…" : "Start 7-Day Free Trial") {
                    Task {
                        await purchases.purchase()
                        if purchases.isSubscribed { screen = .goal }
                    }
                }
                .disabled(purchases.isWorking)
                Button("Restore Purchases") { Task { await purchases.restore() } }
                    .disabled(purchases.isWorking)
                if let message = purchases.statusMessage {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
                Text("Payment will be charged to your Apple Account. The subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in Apple Account settings.")
                    .font(.footnote).foregroundStyle(.secondary)
                HStack(spacing: 18) {
                    Link("Privacy", destination: URL(string: "https://mondaymoneymove.com/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://mondaymoneymove.com/terms.html")!)
                    Link("Support", destination: URL(string: "https://mondaymoneymove.com/support.html")!)
                }.font(.footnote)
                Button("Not now") { screen = .home }.font(.footnote)
            }
        }
    }

    private var settingsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("SETTINGS").font(.caption.bold()).foregroundStyle(.secondary)
                Text("Your app, your control").font(.title.bold())
                Text("Your weekly answers and progress are stored only on this device. Monday Money Move does not connect to your bank account.")
                    .foregroundStyle(.secondary)
                Button("Manage Apple Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Delete My App Data", role: .destructive) { showDeleteConfirmation = true }
                Button("Back") { screen = .home }
            }
            .alert("Delete all app data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { store.clearAll(); screen = .home }
            } message: {
                Text("This permanently removes your saved moves and progress from this iPhone.")
            }
        }
    }

    private var informationCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("IMPORTANT INFORMATION").font(.caption.bold()).foregroundStyle(.secondary)
                Text("Educational guidance—not financial advice").font(.title.bold())
                Text("Monday Money Move provides general educational guidance based only on the choices you enter. It does not provide individualized financial, investment, tax, legal, accounting, credit, or insurance advice, and it does not guarantee results.")
                Text("You remain responsible for reviewing each suggestion and deciding whether it is appropriate for you. For advice about your individual circumstances, consult a qualified professional.")
                    .foregroundStyle(.secondary)
                HStack(spacing: 18) {
                    Link("Privacy", destination: URL(string: "https://mondaymoneymove.com/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://mondaymoneymove.com/terms.html")!)
                    Link("Support", destination: URL(string: "https://mondaymoneymove.com/support.html")!)
                }.font(.footnote)
                Button("Back") { screen = .home }
            }
        }
    }

    private func currentMove(_ item: MoneyMove) -> some View {
        card {
            VStack(alignment:.leading,spacing:12) {
                Text(item.completed ? "COMPLETED THIS WEEK" : "THIS WEEK’S MOVE").font(.caption.bold()).foregroundStyle(.secondary)
                Text(item.text).font(.headline)
                if !item.completed { primaryButton("Mark Complete") { store.completeCurrent() } }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().padding(24).frame(maxWidth:.infinity,alignment:.leading).background(.white.opacity(0.97)).clipShape(RoundedRectangle(cornerRadius:24)).overlay(RoundedRectangle(cornerRadius:24).stroke(.white.opacity(0.84), lineWidth: 1)).shadow(color:BrandPalette.green.opacity(0.10),radius:18,y:8)
    }

    private func primaryButton(_ title:String, action:@escaping()->Void) -> some View {
        Button(action:action) { Text(title).font(.headline).frame(maxWidth:.infinity).padding().foregroundStyle(.white).background(BrandPalette.green).clipShape(RoundedRectangle(cornerRadius:15)).shadow(color: BrandPalette.green.opacity(0.18), radius: 9, y: 4) }
    }

    private func move(for goal:String, pace:String, style:String) -> String {
        let amount = pace == "small" ? "up to $100" : pace == "medium" ? "$100–$500" : pace == "large" ? "$500–$2,500" : "$2,500 or more"
        switch (goal, style) {
        case ("debt","automatic"): return "Schedule an automatic extra payment of \(amount) toward your highest-interest balance."
        case ("debt","review"): return "List your debts by interest rate and choose the highest-interest balance to target first."
        case ("debt",_): return "Put \(amount) toward your highest-interest balance this week."
        case ("save","automatic"): return "Schedule an automatic transfer of \(amount) to savings after your next paycheck."
        case ("save","review"): return "Choose a realistic weekly savings amount and decide where it will be kept."
        case ("save",_): return "Move \(amount) into a separate savings account today."
        case ("spend","automatic"): return "Set a spending alert and protect \(amount) from unnecessary spending."
        case ("spend","review"): return "Review your recurring charges and choose one expense to reduce or cancel."
        case ("spend",_): return "Pause one unnecessary purchase worth \(amount) and redirect it to your priority."
        case ("organize","automatic"): return "Schedule a 15-minute weekly money check-in and gather your key balances in one place."
        case ("organize","review"): return "Review your accounts and list the three financial priorities that matter most this month."
        default: return "Gather your bills and balances, then choose one financial task to complete this week."
        }
    }
}


/// The hosted site is the visual and feature source of truth for the iOS app.
/// StoreKit remains native; the site receives only the resulting entitlement state.
struct ContentView: View {
    @EnvironmentObject private var store: MoveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var loadError: String?
    @State private var reloadKey = UUID()
    @State private var showNativeFallback = false

    var body: some View {
        ZStack {
            MondayMoneyMoveWebView(
                purchases: purchases,
                moves: store.moves,
                reloadKey: reloadKey,
                onError: { loadError = $0 }
            )
            .id(reloadKey)
            .ignoresSafeArea()

            if let loadError {
                VStack(spacing: 14) {
                    Text("Monday Money Move couldn’t load")
                        .font(.headline)
                    Text(loadError)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        loadError = nil
                        reloadKey = UUID()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Open the built-in weekly check-in") {
                        showNativeFallback = true
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.969, green: 0.957, blue: 0.933))
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showNativeFallback) {
            LegacyWeeklyCheckInView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}

private struct MondayMoneyMoveWebView: UIViewRepresentable {
    @ObservedObject var purchases: PurchaseManager
    let moves: [MoneyMove]
    let reloadKey: UUID
    let onError: (String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(purchases: purchases, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let content = WKUserContentController()
        content.add(context.coordinator, name: "mmmNative")
        content.addUserScript(WKUserScript(
            source: Self.nativeBridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = content
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = webView
        context.coordinator.moves = moves
        context.coordinator.loadSite()
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
        context.coordinator.moves = moves
        context.coordinator.onError = onError
        context.coordinator.syncMembership()
    }

    private static let nativeBridgeScript = #"""
    (() => {
      let nativeState = 'checking';
      const notify = () => window.dispatchEvent(new CustomEvent('mmm-membership', {
        detail: { active: nativeState === 'active', state: nativeState }
      }));
      const nativeMembership = Object.freeze({
        active: () => nativeState === 'active',
        verify: async () => nativeState === 'active',
        validReference: () => false,
        get state() { return nativeState; },
        get reference() { return ''; }
      });
      Object.defineProperty(window, 'MMMMembership', {
        configurable: true,
        enumerable: true,
        get: () => nativeMembership,
        set: () => {}
      });
      window.mmmSetNativeMembership = active => {
        nativeState = active ? 'active' : 'inactive';
        notify();
        if (typeof window.render === 'function') window.render();
      };
      window.mmmSetNativeStatus = message => {
        if (!message) return;
        let status = document.getElementById('mmm-native-status');
        if (!status) {
          status = document.createElement('div');
          status.id = 'mmm-native-status';
          status.setAttribute('role', 'status');
          status.setAttribute('aria-live', 'polite');
          Object.assign(status.style, {
            position: 'fixed', left: '16px', right: '16px', bottom: '18px',
            zIndex: '2147483647', padding: '14px 18px', borderRadius: '14px',
            background: '#16352f', color: '#fff', font: '600 15px -apple-system, sans-serif',
            boxShadow: '0 8px 24px rgba(0,0,0,.18)'
          });
          document.body.append(status);
        }
        status.textContent = message;
        clearTimeout(status.dismissTimer);
        status.dismissTimer = setTimeout(() => status.remove(), 6000);
      };
      window.mmmImportNativeMovesFromBase64 = encoded => {
        try {
          const bytes = Uint8Array.from(atob(encoded), character => character.charCodeAt(0));
          const incoming = JSON.parse(new TextDecoder().decode(bytes));
          const data = JSON.parse(localStorage.getItem('mmmData') || '{"current":null,"history":[]}');
          if (!Array.isArray(data.history)) data.history = [];
          const migrated = incoming.map(move => {
            const date = new Date((move.createdAt + 978307200) * 1000).toLocaleDateString();
            return { id: move.id, date, text: move.text, complete: move.completed };
          });
          for (const move of migrated.slice().reverse()) {
            const exists = data.history.some(saved => saved.id === move.id || (saved.text === move.text && saved.date === move.date));
            if (!exists) data.history.unshift(move);
          }
          if (!data.current && migrated.length) data.current = migrated[0];
          localStorage.setItem('mmmData', JSON.stringify(data));
          if (typeof window.render === 'function') window.render();
        } catch (_) {}
      };
      const post = action => window.webkit.messageHandlers.mmmNative.postMessage(action);
      document.addEventListener('click', event => {
        const anchor = event.target && event.target.closest ? event.target.closest('a[href]') : null;
        if (anchor) {
          let url;
          try { url = new URL(anchor.href, location.href); } catch (_) {}
          if (url && url.hostname === 'buy.stripe.com') {
            event.preventDefault(); event.stopImmediatePropagation(); post('purchase'); return;
          }
          if (url && url.pathname.endsWith('/restore.html')) {
            event.preventDefault(); event.stopImmediatePropagation(); post('restore'); return;
          }
          if (url && url.pathname.endsWith('/support.html') && url.hash === '#cancel') {
            event.preventDefault(); event.stopImmediatePropagation(); post('manage'); return;
          }
        }
        const button = event.target && event.target.closest ? event.target.closest('button[onclick*="join("]') : null;
        if (button) {
          event.preventDefault(); event.stopImmediatePropagation();
          post(nativeMembership.active() ? 'manage' : 'purchase');
        }
      }, true);
      window.addEventListener('DOMContentLoaded', () => {
        window.join = () => post(nativeMembership.active() ? 'manage' : 'purchase');
      }, { once: true });
    })();
    """#

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        let purchases: PurchaseManager
        var moves: [MoneyMove] = []
        var onError: (String?) -> Void

        init(purchases: PurchaseManager, onError: @escaping (String?) -> Void) {
            self.purchases = purchases
            self.onError = onError
        }

        func loadSite() {
            guard let url = URL(string: "https://veredg1-boop.github.io/Monday-money-move/") else { return }
            webView?.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
        }

        func syncMembership() {
            let active = purchases.isSubscribed ? "true" : "false"
            let status = purchases.statusMessage.flatMap { try? JSONEncoder().encode($0) }
                .flatMap { String(data: $0, encoding: .utf8) }
            let statusCall = status.map { "window.mmmSetNativeStatus && window.mmmSetNativeStatus(\($0));" } ?? ""
            webView?.evaluateJavaScript("window.mmmSetNativeMembership && window.mmmSetNativeMembership(\(active)); \(statusCall)")
        }

        private func migrateNativeMoves() {
            guard !moves.isEmpty, let webView,
                  let data = try? JSONEncoder().encode(moves) else { return }
            let encoded = data.base64EncodedString()
            webView.evaluateJavaScript("window.mmmImportNativeMovesFromBase64 && window.mmmImportNativeMovesFromBase64('\(encoded)');")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let action = message.body as? String else { return }
            Task { @MainActor in
                switch action {
                case "purchase":
                    await purchases.purchase()
                    syncMembership()
                case "restore":
                    await purchases.restore()
                    syncMembership()
                case "manage":
                    await manageSubscription()
                default:
                    break
                }
            }
        }

        private func manageSubscription() async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first else { return }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                await purchases.refreshStatus()
                syncMembership()
            } catch {
                purchases.statusMessage = "Apple subscription settings could not be opened. You can manage it in iPhone Settings."
                syncMembership()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onError(nil)
            syncMembership()
            migrateNativeMoves()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onError(error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onError(error.localizedDescription)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if url.host == "buy.stripe.com" {
                Task { @MainActor in await purchases.purchase(); syncMembership() }
                decisionHandler(.cancel)
                return
            }
            if url.path.hasSuffix("/restore.html") {
                Task { @MainActor in await purchases.restore(); syncMembership() }
                decisionHandler(.cancel)
                return
            }
            if url.path.hasSuffix("/support.html") && url.fragment == "cancel" {
                Task { @MainActor in await manageSubscription() }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
