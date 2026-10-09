import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct FeatureWorkspaceStateTests {
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value + "T12:00:00Z")! }
    @Test func transactionsCombineFiltersAndCrossYearBoundaries() {
        let state = FinanceWorkspaceState(referenceDate: date("2026-01-08"))
        state.transactions = [.init(name: "Coffee", category: "Dining", account: "Card", amount: -4, date: date("2026-01-03")), .init(name: "Coffee beans", category: "Groceries", account: "Card", amount: -12, date: date("2025-12-31")), .init(name: "Income", category: "Income", account: "Bank", amount: 2000, date: date("2025-01-12"))]
        state.dateFilter = "Last month"; #expect(state.visibleTransactions.map(\.name) == ["Coffee beans"])
        state.dateFilter = "This year"; state.query = "  COFFEE  "; #expect(state.visibleTransactions.map(\.name) == ["Coffee"])
        state.categoryFilter = "Groceries"; #expect(state.visibleTransactions.isEmpty)
        state.dateFilter = "Last year"; #expect(state.visibleTransactions.map(\.name) == ["Coffee beans"])
        state.accountFilter = "Bank"; #expect(state.visibleTransactions.isEmpty)
    }
    @Test func customizationDropsUnknownsDeduplicatesAndMaintainsCompleteOrder() {
        let state = FinanceWorkspaceState(); state.applyDashboard(order: ["Accounts", "Accounts", "Invalid"], shown: ["Accounts", "Invalid"])
        #expect(state.dashboardOrder.first == "Accounts"); #expect(state.dashboardOrder.count == FinanceWorkspaceState.dashboardOptions.count); #expect(state.shownDashboardCards == ["Accounts"])
    }
    @Test func hideValuesDoesNotChangeUnderlyingData() {
        let state = FinanceWorkspaceState(); let original = state.transactions; state.hidesValues = true
        #expect(state.formattedAmount(-18.5) == "••••"); #expect(state.transactions == original)
    }
    @Test func cashCreatesChatWithoutCreatingOrMutatingAccounts() {
        let state = FinanceWorkspaceState(); let original = state.transactions; var events: [FeatureWorkspaceAction] = []; state.onAction = { events.append($0) }; state.chatDraft = "Old unsent text"
        state.beginCashChat(); #expect(state.chatPresented); #expect(state.chatMessages.count == 1); #expect(state.chatDraft.isEmpty); #expect(state.transactions == original); #expect(events.count == 1)
        state.chatDraft = "  Example cash  "; let sent = state.sendChat(); #expect(sent); #expect(state.chatMessages.last?.text == "Example cash"); #expect(events.last == .sendMessage("Example cash"))
    }
    @Test func blankChatDoesNotPublish() {
        let state = FinanceWorkspaceState(); var events: [FeatureWorkspaceAction] = []; state.onAction = { events.append($0) }; state.beginChat(" \n "); state.chatDraft = "  "
        let sent = state.sendChat(); #expect(!sent); #expect(!state.chatPresented); #expect(events.isEmpty)
    }
    @Test func healthSetupCancelRollsBackTemporaryEdits() {
        let state = HealthWorkspaceState(); state.conditionItems = ["Existing sample"]
        state.beginSetup(); state.advance(); state.searchPresented = true; state.searchResults = ["Example condition"]; state.selectSearchResult("Example condition")
        #expect(state.conditionItems.count == 2); state.cancelSetup(); #expect(state.conditionItems == ["Existing sample"]); #expect(!state.setupComplete); #expect(!state.searchPresented)
    }
    @Test func healthFinishCommitsOnlyOnceAndSkipsAreAllowed() {
        let state = HealthWorkspaceState(); var events: [FeatureWorkspaceAction] = []; state.onAction = { events.append($0) }; state.beginSetup()
        state.advance(); state.advance(); state.advance(); #expect(state.step == .family); state.advance(); state.advance()
        #expect(state.setupComplete); #expect(!state.setupPresented); #expect(events == [.setupCompleted]); #expect(state.conditionItems.isEmpty)
    }
    @Test func healthBackClearsSearchButKeepsStepAndKnownResultIdentity() {
        let state = HealthWorkspaceState(); state.beginSetup(); state.advance(); state.searchPresented = true; state.searchQuery = "typed"; state.back()
        #expect(state.step == .conditions); #expect(!state.searchPresented); #expect(state.searchQuery.isEmpty)
        state.searchPresented = true; state.searchResults = ["Example condition"]; state.selectSearchResult("Unknown"); #expect(state.conditionItems.isEmpty)
        state.selectSearchResult("Example condition"); state.searchPresented = true; state.selectSearchResult("Example condition"); #expect(state.conditionItems == ["Example condition"])
    }
    @Test func setupDoesNotClaimProviderConnectionAndSessionsAreIndependent() {
        let first = HealthWorkspaceState(); let second = HealthWorkspaceState(); first.beginSetup(); first.providerStatus["Example"] = "Connected"
        #expect(first.providerStatus["Apple Health"] == nil); #expect(second.providerStatus["Example"] == nil); #expect(!second.setupPresented)
    }
}

@Suite @MainActor struct FeatureHostDataTests {
    @Test func defaultsHaveNoInventedRecords() {
        let finance = FinanceWorkspaceState(); let health = HealthWorkspaceState(setupComplete: true)
        #expect(finance.data == FinancePresentationData()); #expect(finance.transactions.isEmpty)
        #expect(finance.chatMessages.isEmpty); #expect(health.data == HealthPresentationData())
        #expect(health.connectedProviders.isEmpty); #expect(health.visibleProviders.isEmpty); #expect(health.providerStatus.isEmpty)
    }
    @Test func financeAcceptsReplacementAndClearingWithoutFallbackOrResettingUI() {
        var data = FinancePresentationData(); data.spendingPeriod = "February"; data.spendingTotal = 43
        data.spendingCategories = [.init(id: "travel", title: "Travel", symbol: "tram", amount: 43, relativeBarWidth: 1)]
        data.dashboardValues = ["Net Worth": .amount(810), "Credit score": .text("610")]
        data.accountGroups = [.init(id: "g", title: "Reserve", subtitle: "Updated today", balance: 810, accounts: [.init(id: "a", title: "Host bank", subtitle: "7788", balance: 810, updated: "Now")])]
        data.chats = [.init(id: "chat-1", title: "Host thread", preview: "A host preview")]
        let state = FinanceWorkspaceState(data: data); let independent = FinanceWorkspaceState(data: data)
        state.tab = "Accounts"; state.draft = "Keep this"; state.hidesValues = true
        #expect(state.displayValue(data.dashboardValues["Net Worth"]!) == "••••")
        #expect(state.displayValue(data.dashboardValues["Credit score"]!) == "•••")
        #expect(state.data == data); state.data.accountGroups[0].accounts[0].balance = 900
        #expect(independent.data.accountGroups[0].accounts[0].balance == 810)
        state.data = .init(); #expect(state.data.accountGroups.isEmpty); #expect(state.data.spendingCategories.isEmpty)
        #expect(state.tab == "Accounts"); #expect(state.draft == "Keep this"); #expect(state.hidesValues)
    }
    @Test func healthProviderIdentityFilteringAndHostUpdatesAreIndependent() {
        var data = HealthPresentationData()
        data.providers = [.init(id: "provider-1", name: "Harbor Clinic", isConnected: true, accountStatus: "Updated now"), .init(id: "provider-2", name: "Other Clinic")]
        data.activityMetrics = [.init(id: "steps", title: "Host steps", value: "900", unit: "today", bars: true, chartSamples: [0.1, 0.8])]
        let state = HealthWorkspaceState(setupComplete: true, data: data); let second = HealthWorkspaceState(data: data)
        state.providerQuery = "  HARBOR  "; #expect(state.visibleProviders.map(\.id) == ["provider-1"])
        #expect(state.connectedProviders.map(\.id) == ["provider-1"])
        #expect(state.providerIsSelected(data.providers[0])); #expect(state.providerStatusText(data.providers[0]) == "Updated now")
        state.providerStatus["provider-1"] = "Refreshing"; #expect(state.providerStatusText(data.providers[0]) == "Refreshing")
        state.providerStatus = [:]
        state.data.providers[0].isConnected = false; state.data.activityMetrics[0].value = "1000"
        #expect(state.connectedProviders.isEmpty); #expect(second.connectedProviders.count == 1)
        #expect(second.data.activityMetrics[0].value == "900")
        state.data = .init(); #expect(state.visibleProviders.isEmpty); #expect(state.data.activityMetrics.isEmpty); #expect(state.setupComplete)
    }
    @Test func cashPublishesOnlyUserTurnUntilHostSuppliesResponse() {
        let state = FinanceWorkspaceState(); var actions: [FeatureWorkspaceAction] = []
        state.onAction = { actions.append($0); #expect(state.chatMessages.count == 1); #expect(state.chatMessages[0].role == .user) }
        state.beginCashChat(); #expect(actions == [.startChat(state.chatMessages[0].text)])
        state.chatMessages.append(.init(role: .assistant, text: "Host-supplied response"))
        #expect(state.chatMessages.last?.text == "Host-supplied response")
    }
    @Test func injectedChartGeometryIsFiniteBoundedAndNotReplacedWithSampleData() {
        var data = FinancePresentationData(); data.spendingSegments = [.nan, -.infinity, -2, 0.5, 1]
        let expected: [Double] = [0, 0, 0, 1.0 / 3, 2.0 / 3]
        #expect(data.boundedSpendingSegments == expected)
        let category = FinanceSpendingCategory(id: "x", title: "X", symbol: "circle", amount: 0, relativeBarWidth: .nan)
        #expect(category.boundedBarWidth == 0)
        let metric = HealthMetric(id: "x", title: "X", value: "", unit: "", bars: true, chartSamples: [.nan, -.infinity, -1, 0.5, 4])
        #expect(metric.boundedChartSamples == [0, 0, 0, 0.5, 1])
        #expect(HealthMetric(id: "empty", title: "Empty", value: "", unit: "", bars: false).boundedChartSamples.isEmpty)
    }
}
