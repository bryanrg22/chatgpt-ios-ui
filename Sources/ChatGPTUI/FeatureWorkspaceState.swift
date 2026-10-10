import Foundation
import Observation

@nonexhaustive public enum FeatureWorkspaceAction: Equatable, Sendable {
    case openDestination(String), startChat(String), sendMessage(String)
    case connectProvider(String), setupCompleted, selectHealthItem(String)
    case openAccount(String), openChat(String)
}
public struct FinanceTransaction: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String
    public var account: String
    public var amount: Double
    public var date: Date
    public var pending: Bool
    public init(
        id: UUID = UUID(), name: String, category: String, account: String, amount: Double, date: Date,
        pending: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.account = account
        self.amount = amount
        self.date = date
        self.pending = pending
    }
}
@MainActor @Observable public final class FinanceWorkspaceState {
    public static let dashboardOptions = [
        "Spend by category", "Net Worth", "Credit score", "Daily movers", "Upcoming activity", "Spend this month",
        "Subscriptions", "Bills", "Category review", "Recent transactions", "Fees and interest before refunds",
        "Accounts"
    ]
    public var tab = "Dashboard"
    public var connectionTab = "Accounts"
    public var hidesValues = false
    public var pinned = true
    public var showsSuggestions = true
    public var expandedAccountGroups: Set<String> = ["Cash"]
    public var dashboardOrder = dashboardOptions
    public var shownDashboardCards = Set(dashboardOptions)
    public var query = ""
    public var dateFilter = "All dates"
    public var accountFilter = "All accounts"
    public var categoryFilter = "All categories"
    public var referenceDate: Date
    public var transactions: [FinanceTransaction]
    public var data: FinancePresentationData
    public var currencyCode = "USD"
    public var chatMessages: [ChatMessage] = []
    public var chatPresented = false
    public var pendingChat: String?
    public var draft = ""
    public var chatDraft = ""
    public var onAction: (FeatureWorkspaceAction) -> Void = { _ in }
    public init(
        referenceDate: Date = Date(), data: FinancePresentationData = .init(), transactions: [FinanceTransaction] = []
    ) {
        self.referenceDate = referenceDate
        self.data = data
        self.transactions = transactions
    }
    public func displayValue(_ value: FinanceDisplayValue) -> String {
        switch value {
        case .amount(let amount): return formattedAmount(amount)
        case .text(let text): return hidesValues ? "•••" : text
        }
    }
    public var visibleTransactions: [FinanceTransaction] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return transactions.filter { item in
            let matchesQuery =
                q.isEmpty || item.name.localizedCaseInsensitiveContains(q)
                || item.category.localizedCaseInsensitiveContains(q) || item.account.localizedCaseInsensitiveContains(q)
            let matchesAccount = accountFilter == "All accounts" || accountFilter == item.account
            let matchesCategory = categoryFilter == "All categories" || categoryFilter == item.category
            var matchesDate = true
            switch dateFilter {
            case "This month": matchesDate = calendar.isDate(item.date, equalTo: referenceDate, toGranularity: .month)
            case "Last month":
                matchesDate = calendar.isDate(
                    item.date, equalTo: calendar.date(byAdding: .month, value: -1, to: referenceDate)!,
                    toGranularity: .month)
            case "This year": matchesDate = calendar.isDate(item.date, equalTo: referenceDate, toGranularity: .year)
            case "Last year":
                matchesDate = calendar.isDate(
                    item.date, equalTo: calendar.date(byAdding: .year, value: -1, to: referenceDate)!,
                    toGranularity: .year)
            default: break
            }
            return matchesQuery && matchesAccount && matchesCategory && matchesDate
        }
    }
    public func formattedAmount(_ amount: Double) -> String {
        hidesValues ? "••••" : amount.formatted(.currency(code: currencyCode))
    }
    public func toggleGroup(_ group: String) {
        if expandedAccountGroups.contains(group) {
            expandedAccountGroups.remove(group)
        } else {
            expandedAccountGroups.insert(group)
        }
    }
    public func applyDashboard(order: [String], shown: Set<String>) {
        var seen = Set<String>()
        dashboardOrder = (order + Self.dashboardOptions).filter {
            Self.dashboardOptions.contains($0) && seen.insert($0).inserted
        }
        shownDashboardCards = shown.intersection(Self.dashboardOptions)
    }
    public func beginCashChat() {
        let prompt =
            "Help me track a cash account manually. Ask one short question at a time for its name, checking or savings type, current balance, and currency if unclear. An institution is optional. After I answer, save it as a financial memory for a separate account."
        chatMessages = [.init(role: .user, text: prompt)]
        chatPresented = true
        chatDraft = ""
        onAction(.startChat(prompt))
    }
    public func beginChat(_ prompt: String) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        chatMessages = [.init(role: .user, text: prompt)]
        chatPresented = true
        draft = ""
        chatDraft = ""
        onAction(.startChat(prompt))
    }
    @discardableResult public func sendChat() -> Bool {
        let value = chatDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        chatMessages.append(.init(role: .user, text: value))
        chatDraft = ""
        onAction(.sendMessage(value))
        return true
    }
}
public enum HealthSetupStep: Int, CaseIterable, Sendable { case accounts, conditions, medications, family }
@MainActor @Observable public final class HealthWorkspaceState {
    public var pinned = true
    public var setupComplete: Bool
    public var setupPresented = false
    public var step: HealthSetupStep = .accounts
    public var searchPresented = false
    public var searchQuery = ""
    public var searchResults: [String] = []
    public var conditionItems: [String] = []
    public var medicationItems: [String] = []
    public var familyItems: [String] = []
    public var providerStatus: [String: String] = [:]
    public var data: HealthPresentationData
    public var visibleProviders: [HealthProvider] {
        let query = providerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return data.providers.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }
    public var connectedProviders: [HealthProvider] { data.providers.filter(\.isConnected) }
    public func providerIsSelected(_ provider: HealthProvider) -> Bool {
        provider.isConnected || providerStatus[provider.id] != nil
    }
    public func providerStatusText(_ provider: HealthProvider) -> String? {
        if let status = providerStatus[provider.id] { return status }
        return provider.isConnected && !provider.accountStatus.isEmpty ? provider.accountStatus : nil
    }
    public var providerQuery = ""
    public var tab = "Home"
    public var showsSuggestions = true
    public var draft = ""
    public var onAction: (FeatureWorkspaceAction) -> Void = { _ in }
    private var originalConditions: [String] = []
    private var originalMedications: [String] = []
    private var originalFamily: [String] = []
    public init(setupComplete: Bool = false, data: HealthPresentationData = .init()) {
        self.setupComplete = setupComplete
        self.data = data
    }
    public func beginSetup() {
        originalConditions = conditionItems
        originalMedications = medicationItems
        originalFamily = familyItems
        step = .accounts
        setupPresented = true
        searchPresented = false
        searchQuery = ""
    }
    public func cancelSetup() {
        conditionItems = originalConditions
        medicationItems = originalMedications
        familyItems = originalFamily
        setupPresented = false
        searchPresented = false
        searchQuery = ""
    }
    public func advance() {
        guard setupPresented else { return }
        if step == .family {
            setupComplete = true
            setupPresented = false
            onAction(.setupCompleted)
        } else {
            step = HealthSetupStep(rawValue: step.rawValue + 1)!
        }
        searchPresented = false
        searchQuery = ""
    }
    public func back() {
        if searchPresented {
            searchPresented = false
            searchQuery = ""
        } else if step == .accounts {
            cancelSetup()
        } else {
            step = HealthSetupStep(rawValue: step.rawValue - 1)!
        }
    }
    public func selectSearchResult(_ text: String) {
        guard searchPresented, [.conditions, .medications].contains(step), searchResults.contains(text) else { return }
        if step == .conditions && !conditionItems.contains(text) { conditionItems.append(text) }
        if step == .medications && !medicationItems.contains(text) { medicationItems.append(text) }
        onAction(.selectHealthItem(text))
        searchPresented = false
        searchQuery = ""
    }
}
