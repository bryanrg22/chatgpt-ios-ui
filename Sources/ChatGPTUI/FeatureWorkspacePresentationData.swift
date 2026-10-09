import Foundation

/// Host-owned display data. No records or sample values are synthesized by the UI.
public enum FinanceDisplayValue: Equatable, Sendable {
    case amount(Double), text(String)
}
public struct FinanceSpendingCategory: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var symbol: String
    public var amount: Double
    public var relativeBarWidth: Double
    public init(id: String, title: String, symbol: String, amount: Double, relativeBarWidth: Double) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.amount = amount
        self.relativeBarWidth = relativeBarWidth
    }
    public var boundedBarWidth: Double { relativeBarWidth.isFinite ? min(1, max(0, relativeBarWidth)) : 0 }
}
public struct FinanceAccountRow: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var balance: Double
    public var updated: String
    public var symbol: String
    public init(
        id: String, title: String, subtitle: String, balance: Double, updated: String,
        symbol: String = "building.columns.fill"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.balance = balance
        self.updated = updated
        self.symbol = symbol
    }
}
public struct FinanceAccountGroup: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var balance: Double
    public var accounts: [FinanceAccountRow]
    public init(id: String, title: String, subtitle: String, balance: Double, accounts: [FinanceAccountRow]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.balance = balance
        self.accounts = accounts
    }
}
public struct FeatureChatSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var preview: String
    public init(id: String, title: String, preview: String) {
        self.id = id
        self.title = title
        self.preview = preview
    }
}
public struct FinancePresentationData: Equatable, Sendable {
    public var spendingTotal: Double?
    public var spendingPeriod: String = ""
    public var spendingSegments: [Double] = []
    public var spendingCategories: [FinanceSpendingCategory] = []
    public var dashboardValues: [String: FinanceDisplayValue] = [:]
    public var accountGroups: [FinanceAccountGroup] = []
    public var chats: [FeatureChatSummary] = []
    public var creditProvider: String = ""
    public var creditScore: String?
    public init() {}
    /// Invalid or negative host fractions never reach SwiftUI geometry; oversized totals are normalized.
    public var boundedSpendingSegments: [Double] {
        let values = spendingSegments.map { $0.isFinite ? min(1, max(0, $0)) : 0 }
        let total = values.reduce(0, +)
        return total > 1 ? values.map { $0 / total } : values
    }
}
public struct HealthMetric: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var value: String
    public var unit: String
    public var bars: Bool
    public var chartSamples: [Double]
    public init(id: String, title: String, value: String, unit: String, bars: Bool, chartSamples: [Double] = []) {
        self.id = id
        self.title = title
        self.value = value
        self.unit = unit
        self.bars = bars
        self.chartSamples = chartSamples
    }
    public var boundedChartSamples: [Double] { chartSamples.map { $0.isFinite ? min(1, max(0, $0)) : 0 } }
}
public struct HealthProvider: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var symbol: String
    public var isConnected: Bool
    public var accountStatus: String
    public init(
        id: String, name: String, symbol: String = "cross.case.fill", isConnected: Bool = false,
        accountStatus: String = ""
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.isConnected = isConnected
        self.accountStatus = accountStatus
    }
}
public struct HealthPresentationData: Equatable, Sendable {
    public var introductionMetrics: [HealthMetric] = []
    public var activityTitle: String = "Activity"
    public var activityMetrics: [HealthMetric] = []
    public var providers: [HealthProvider] = []
    public var chats: [FeatureChatSummary] = []
    public init() {}
}
