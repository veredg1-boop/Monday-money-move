import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: MoveStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var screen: Screen = .home
    @State private var goal = ""
    @State private var pace = ""
    @State private var recommendation = ""

    enum Screen { case home, goal, pace, style, result, history, membership }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.93), Color(red: 0.92, green: 0.96, blue: 0.94)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        brand
                        if let current = store.current { currentMove(current) }
                        content
                    }
                    .padding()
                }
            }
            .tint(.green)
        }
    }

    private var brand: some View {
        HStack(spacing: 12) {
            Text("M").font(.title2.bold()).foregroundStyle(.white).frame(width: 48, height: 48).background(Color(red: 0.09, green: 0.21, blue: 0.18)).clipShape(RoundedRectangle(cornerRadius: 15))
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
        case .goal: question("What would make the biggest difference right now?", options: [("Pay down debt","debt"),("Build my savings","save"),("Stop overspending","spend"),("Invest more consistently","invest")]) { goal=$0; screen = .pace }
        case .pace: question("What feels realistic this week?", options: [("A small step under $25","small"),("A focused step from $25–$100","medium"),("A bigger step over $100","large")]) { pace=$0; screen = .style }
        case .style: question("What kind of action would help most?", options: [("Set it up automatically","automatic"),("Take one action today","once"),("Review and make a decision","review")]) { recommendation = move(for: goal, pace: pace, style: $0); screen = .result }
        case .result: resultCard
        case .history: historyCard
        case .membership: membershipCard
        }
    }

    private var home: some View {
        card {
            VStack(alignment: .leading, spacing: 18) {
                Text("FOUNDING MEMBER BETA").font(.caption.bold()).foregroundStyle(Color(red: 0.09, green: 0.31, blue: 0.24))
                Text("Stop wondering what to do with your money next.").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("A one-minute weekly check-in that turns financial overwhelm into one clear, manageable action.").font(.title3).foregroundStyle(.secondary)
                primaryButton(store.moves.isEmpty || purchases.isSubscribed ? "Start This Week’s Check-In" : "Unlock This Week’s Move") {
                    screen = store.moves.isEmpty || purchases.isSubscribed ? .goal : .membership
                }
                Button("Remind me every Monday") { Task { await store.requestWeeklyReminder() } }.font(.subheadline.bold())
                if !store.moves.isEmpty {
                    Text("\(store.completedCount) of \(store.moves.count) weekly moves completed")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
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
                            .padding().frame(maxWidth:.infinity).background(Color(.secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius:14))
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
                Text(recommendation).font(.title3.bold()).padding().background(Color(red:0.97,green:0.95,blue:0.90)).clipShape(RoundedRectangle(cornerRadius:14))
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
                primaryButton(purchases.isWorking ? "Please wait…" : "Start Membership") {
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
                    Link("Privacy", destination: URL(string: "https://veredg1-boop.github.io/Monday-money-move/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://veredg1-boop.github.io/Monday-money-move/terms.html")!)
                    Link("Support", destination: URL(string: "https://veredg1-boop.github.io/Monday-money-move/support.html")!)
                }.font(.footnote)
                Button("Not now") { screen = .home }.font(.footnote)
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
        content().padding(24).frame(maxWidth:.infinity,alignment:.leading).background(.white).clipShape(RoundedRectangle(cornerRadius:24)).shadow(color:.black.opacity(0.07),radius:18,y:8)
    }

    private func primaryButton(_ title:String, action:@escaping()->Void) -> some View {
        Button(action:action) { Text(title).font(.headline).frame(maxWidth:.infinity).padding().foregroundStyle(.white).background(Color(red:0.09,green:0.21,blue:0.18)).clipShape(RoundedRectangle(cornerRadius:15)) }
    }

    private func move(for goal:String, pace:String, style:String) -> String {
        let amount = pace == "small" ? "a small amount" : pace == "medium" ? "$25–$100" : "more than $100"
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
        case ("invest","automatic"): return "Schedule a recurring investment of \(amount) on payday."
        case ("invest","review"): return "Review diversification, fees, and risk before choosing your next investment."
        default: return "Invest \(amount) consistently instead of waiting for the perfect time."
        }
    }
}
