import Foundation
import Observation

public enum VoiceInterfaceVariant: String, Sendable { case current, classic }
public enum VoiceUIAction: Equatable, Sendable {
    case attachment(String), requestScreenSharing, stopScreenSharing, requestLiveVideo
    case endLiveVideo, flipCamera, cameraFlash(Bool), effort(Int)
}

public enum VoiceNavigationIntent: String, Equatable, Sendable { case sidebar, attachments }

public struct VoiceProfile: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var detail: String
    public init(id: String, name: String, detail: String) { self.id = id; self.name = name; self.detail = detail }
}

/// Presentation only. No microphone, speech synthesis, audio session, or network is created.
@MainActor @Observable public final class VoicePresentationState {
    public var profiles: [VoiceProfile] = [.init(id: "breeze", name: "Breeze", detail: "Animated and earnest")]
    public private(set) var selectedID = "breeze"
    public private(set) var hasChosenVoice = false
    public private(set) var isChoosing = true
    public private(set) var isActive = false
    public var showsSettings = false
    public var isMuted = true
    public var language = "Auto"
    /// Only languages visible in the captured menu; hosts may provide the remaining catalog.
    public var availableLanguages = ["Auto", "Afrikaans", "Amharic", "Arabic", "Armenian", "Azerbaijani", "Bangla", "Belarusian", "Bosnian", "Bulgarian", "Burmese", "Cantonese (Traditional Chinese)", "Catalan", "Croatian", "Czech"]
    public var draft = ""
    public var transcript: [ChatMessage] = []
    public var variant: VoiceInterfaceVariant = .current
    public var isSharingScreen = false
    public var showsModelSwitch = false
    public var showsEffort = false
    public private(set) var effortPosition = 2
    public var showsLiveCamera = false
    public var cameraFlashEnabled = false
    public var mutedControlIsRed = false
    /// Host-supplied diameter in points. Nil uses a captured resting endpoint.
    /// The recorded extrema are observations, not an amplitude mapping or design cap.
    public var orbDiameter: Double?
    public var orbPhase = 0.0
    /// Cosmetic texture drift only. Hosts may instead supply `orbPhase` frame by frame.
    public var animatesOrbTexture = false
    public var onAction: (VoiceUIAction) -> Void = { _ in }
    public var hasTranscript: Bool { !transcript.isEmpty }
    /// Explicit host geometry bypasses the sample transition so two animation owners cannot compete.
    public var hasHostOrbDiameter: Bool { orbDiameter.map { $0.isFinite && $0 > 0 } ?? false }
    public var presentedOrbDiameter: Double {
        let fallback = hasTranscript ? 80.0 : (variant == .classic ? 178.0 : 193.0)
        guard let value = orbDiameter, value.isFinite, value > 0 else { return fallback }
        return min(value, 400)
    }
    public func setEffort(_ position: Int) {
        let next = min(4, max(0, position)); guard next != effortPosition else { return }
        effortPosition = next; onAction(.effort(next))
    }
    public func requestScreenSharing() {
        guard isActive else { return }
        showsEffort = false
        if isSharingScreen { isSharingScreen = false; onAction(.stopScreenSharing) }
        else if variant == .current { showsModelSwitch = true }
        else { onAction(.requestScreenSharing) }
    }
    /// Emits the request only. The host supplies sharing/variant state after its own outcome.
    public func continueScreenSharing() {
        guard isActive, showsModelSwitch else { return }
        showsModelSwitch = false; onAction(.requestScreenSharing)
    }
    public func requestLiveVideo() {
        guard isActive else { return }; onAction(.requestLiveVideo)
    }
    public func closeLiveVideo() {
        guard showsLiveCamera else { return }; showsLiveCamera = false; onAction(.endLiveVideo)
    }
    public func clearConversation() { transcript.removeAll(); draft = ""; orbDiameter = nil }

    public init() {}
    public var selected: VoiceProfile { profiles.first { $0.id == selectedID } ?? .init(id: "breeze", name: "Breeze", detail: "Animated and earnest") }
    public var selectedIndex: Int { profiles.firstIndex { $0.id == selectedID } ?? 0 }
    public func open() { isChoosing = !hasChosenVoice; isActive = hasChosenVoice; showsSettings = false }
    @discardableResult public func start() -> Bool {
        guard !isActive else { return false }
        hasChosenVoice = true; isChoosing = false; isActive = true
        return true
    }
    @discardableResult public func close() -> Bool {
        let wasActive = isActive
        isActive = false; showsSettings = false; showsEffort = false; showsModelSwitch = false; showsLiveCamera = false; isSharingScreen = false; cameraFlashEnabled = false
        return wasActive
    }
    public func select(_ id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        selectedID = id
    }
    public func next(_ direction: Int) {
        guard profiles.count > 1 else { return }
        let index = min(profiles.count - 1, max(0, selectedIndex + direction))
        selectedID = profiles[index].id
    }
}
