import Foundation
import Observation

@nonexhaustive public enum ExploreAction: Equatable, Sendable {
    case searchSites(String), createSite
}

/// Presentation only; site content and creation results are provided by a host.
@MainActor @Observable public final class ExplorePresentationState {
    public var isExpanded = false
    public var sitesQuery = "" {
        didSet { if oldValue != sitesQuery { onAction(.searchSites(sitesQuery)) } }
    }
    public var onAction: (ExploreAction) -> Void = { _ in }
    public init() {}
    public func expand() { isExpanded = true }
}

public struct ChatComposerContext: Equatable, Sendable {
    public let id: String
    public let title: String
    public let symbol: String
    public init(id: String, title: String, symbol: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
    }
    public static let sites = Self(id: "sites", title: "Sites", symbol: "square.grid.2x2.fill")
}
