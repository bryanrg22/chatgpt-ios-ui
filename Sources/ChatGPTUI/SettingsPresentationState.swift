import Foundation
import Observation

public struct SettingsModelOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
}
public struct SettingsAccentOption: Identifiable, Equatable, Sendable {
    public let id: String
    /// Approximate sRGB swatch sampled from the captured light menu, not a semantic theme token.
    public let swatchRGB: UInt32
}
public enum SettingsPreferenceOptions {
    public static let startScreens = ["Chat", "Codex"]
    /// Preserve the original package's host-facing IDs while matching the captured visible labels.
    public static let models = [
        SettingsModelOption(id: "GPT-6", title: "GPT-6"),
        SettingsModelOption(id: "GPT-5.6 Sol", title: "5.6 Sol"),
        SettingsModelOption(id: "GPT-5.5", title: "5.5")
    ]
    public static func modelTitle(for id: String) -> String { models.first { $0.id == id }?.title ?? id }
    public static let accents = [
        SettingsAccentOption(id: "Blue", swatchRGB: 0x3067EF), SettingsAccentOption(id: "Cyan", swatchRGB: 0x00B2FD),
        SettingsAccentOption(id: "Green", swatchRGB: 0x03BB9D), SettingsAccentOption(id: "Lime", swatchRGB: 0xB8D811),
        SettingsAccentOption(id: "Yellow", swatchRGB: 0xFFCB3C), SettingsAccentOption(id: "Orange", swatchRGB: 0xFF7F67),
        SettingsAccentOption(id: "Pink", swatchRGB: 0xFF49AE), SettingsAccentOption(id: "Magenta", swatchRGB: 0xDE69DA),
        SettingsAccentOption(id: "Purple", swatchRGB: 0xA15DFF), SettingsAccentOption(id: "Black", swatchRGB: 0x0D0D0D)
    ]
}

public struct SettingsAccountPresentation: Equatable, Sendable {
    public var displayName: String
    public var username: String
    public var email: String
    public var avatarInitials: String
    public var phoneNumber: String?
    public var subscription: String?
    public init(displayName: String = "", username: String = "", email: String = "", avatarInitials: String = "", phoneNumber: String? = nil, subscription: String? = nil) {
        self.displayName = displayName; self.username = username; self.email = email
        self.avatarInitials = avatarInitials; self.phoneNumber = phoneNumber; self.subscription = subscription
    }
}

public struct SettingsAboutPresentation: Equatable, Sendable {
    public var appName: String
    public var version: String
    public var build: String
    public var termsURL: URL?
    public var privacyURL: URL?
    public init(appName: String = "", version: String = "", build: String = "", termsURL: URL? = nil, privacyURL: URL? = nil) {
        self.appName = appName; self.version = version; self.build = build
        self.termsURL = termsURL; self.privacyURL = privacyURL
    }
    public var versionLabel: String {
        let version = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let build = build.trimmingCharacters(in: .whitespacesAndNewlines)
        if build.isEmpty { return version }
        return version.isEmpty ? build : "\(version) (\(build))"
    }
}

public enum SettingsDestination: String, Equatable, Sendable {
    case about, general, personalization, memory, plugins
}
public enum SettingsLegalLink: Equatable, Sendable { case termsOfUse, privacyPolicy }
public enum SettingsAction: Equatable, Sendable {
    case openDestination(SettingsDestination)
    case openLink(SettingsLegalLink, URL)
}

/// Host-owned metadata and typed intents. This object never opens a URL or fetches account data.
@MainActor @Observable public final class SettingsPresentationState {
    public var account: SettingsAccountPresentation
    public var about: SettingsAboutPresentation
    public var onAction: (SettingsAction) -> Void
    public init(account: SettingsAccountPresentation = .init(), about: SettingsAboutPresentation = .init(), onAction: @escaping (SettingsAction) -> Void = { _ in }) {
        self.account = account; self.about = about; self.onAction = onAction
    }
    public func requestDestination(_ destination: SettingsDestination) { onAction(.openDestination(destination)) }
    public func url(for link: SettingsLegalLink) -> URL? {
        switch link { case .termsOfUse: about.termsURL; case .privacyPolicy: about.privacyURL }
    }
    public func requestLink(_ link: SettingsLegalLink) {
        guard let url = url(for: link) else { return }
        onAction(.openLink(link, url))
    }
}
