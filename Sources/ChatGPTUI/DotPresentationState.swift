import Foundation
import Observation

public enum DotMessageKind: Equatable, Sendable {
    case text
    case callEnded(durationSeconds: Int)
}
public enum DotDeliveryReceipt: Int, Equatable, Sendable {
    case delivered, read
    public var label: String { self == .delivered ? "Delivered" : "Read" }
}
public struct DotMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var text: String
    public var isUser: Bool
    public var time: String
    public var linkLabel: String?
    public var replyTo: UUID?
    public var reaction: String?
    public var kind: DotMessageKind
    public var receipt: DotDeliveryReceipt?
    public init(
        id: UUID = UUID(), text: String, isUser: Bool = false, time: String = "11:15 PM", linkLabel: String? = nil,
        replyTo: UUID? = nil, reaction: String? = nil, kind: DotMessageKind = .text, receipt: DotDeliveryReceipt? = nil
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.time = time
        self.linkLabel = linkLabel
        self.replyTo = replyTo
        self.reaction = reaction
        self.kind = kind
        self.receipt = isUser ? receipt : nil
    }
    public var isCallSummary: Bool { if case .callEnded = kind { true } else { false } }
    public var supportsReactions: Bool { !isUser && !isCallSummary }
    public var displayText: String {
        if case .callEnded(let duration) = kind { return "\(DotCallPresentation.durationLabel(duration)) · Call ended" }
        return text + (linkLabel.map { " " + $0 } ?? "")
    }
}
public enum DotCallPhase: String, Sendable { case idle, calling, connected, failed }
/// Host-supplied presentation data. It neither starts CallKit nor accesses audio.
public struct DotCallPresentation: Equatable, Sendable {
    public var phase: DotCallPhase
    public var elapsedSeconds: Int
    public var microphoneMuted: Bool
    public init(phase: DotCallPhase = .calling, elapsedSeconds: Int = 0, microphoneMuted: Bool = false) {
        self.phase = phase
        self.elapsedSeconds = max(0, elapsedSeconds)
        self.microphoneMuted = microphoneMuted
    }
    public static func durationLabel(_ seconds: Int) -> String {
        let value = max(0, seconds)
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }
    public var elapsedLabel: String { Self.durationLabel(elapsedSeconds) }
}
public enum DotUIAction: Equatable, Sendable {
    case send(text: String, replyTo: UUID?)
    case reaction(message: UUID, value: String?)
    case copy(message: UUID, text: String)
    case pause(Bool), delete, revokeComputer(String), openComputer(String)
    case beginCall, endCall, speaker(Bool), mute(Bool)
    case computerInput(String), computerClipboard, computerWindows
    case attach(String), dictation, openLink(UUID), moreReactions(UUID)
}
@MainActor @Observable public final class DotPresentationState {
    public var draft = ""
    public var name = "dot"
    public var computerName = "Sample-Mac.lan"
    public var computerAvailable = true
    public var computerIsPresented = false
    public var computerConnecting = false
    public var computerClipboardAvailable = false
    public var isPaused = false
    public var callPhase: DotCallPhase = .idle
    public private(set) var callElapsedSeconds = 0
    public var callMinimized = false
    public var speakerEnabled = true
    public var microphoneMuted = false
    public private(set) var replyTo: UUID?
    public private(set) var messages: [DotMessage]
    public var onAction: (DotUIAction) -> Void = { _ in }
    public init(messages: [DotMessage]? = nil) {
        self.messages =
            messages ?? [
                .init(text: "I’ll check the garden workshop guide for the suggested materials and preparation steps."),
                .init(
                    text:
                        "The workshop includes five short activities, with a maximum of two projects per person. That is the full program; I haven’t checked which activities you’ve already tried.",
                    linkLabel: "Community workshop guide."),
                .init(
                    text:
                        "For the balcony planter, the next session begins Saturday at 9 AM. Bring two small containers and choose a sunny spot before you start. The guide includes a checklist for soil and watering.",
                    linkLabel: "Planter instructions."),
                .init(
                    text:
                        "One last reminder: the local library has a collection of gardening books available this week. You can review the catalog and decide which examples fit your space. Start with a guide to container gardens and a seasonal planting calendar.",
                    linkLabel: "Library reading list.")
            ]
    }
    public var replyMessage: DotMessage? { messages.first { $0.id == replyTo } }
    public var callPresentation: DotCallPresentation {
        .init(phase: callPhase, elapsedSeconds: callElapsedSeconds, microphoneMuted: microphoneMuted)
    }
    /// A host adapter supplies connection, elapsed-time and mute updates; no timer
    /// or simulated connection is started by the reusable presentation library.
    public func applyCallPresentation(_ update: DotCallPresentation) {
        callPhase = update.phase
        callElapsedSeconds = max(0, update.elapsedSeconds)
        microphoneMuted = update.microphoneMuted
        if update.phase == .idle { callMinimized = false }
    }
    public func beginReply(_ id: UUID) {
        guard messages.contains(where: { $0.id == id }) else { return }
        replyTo = id
    }
    public func cancelReply() { replyTo = nil }
    @discardableResult public func send() -> Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        let replying = replyTo
        messages.append(.init(text: text, isUser: true, replyTo: replying))
        draft = ""
        replyTo = nil
        onAction(.send(text: text, replyTo: replying))
        return true
    }
    public func append(_ message: DotMessage) {
        var incoming = message
        if !incoming.isUser { incoming.receipt = nil }
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            if incoming.isUser, let old = messages[index].receipt,
                incoming.receipt == nil || old.rawValue > incoming.receipt!.rawValue
            {
                incoming.receipt = old
            }
            messages[index] = incoming
        } else {
            messages.append(incoming)
        }
    }
    /// Receipt updates are explicit host acknowledgements. Stale Delivered updates
    /// cannot downgrade Read, and no receipt is invented when a local send occurs.
    @discardableResult public func updateReceipt(_ receipt: DotDeliveryReceipt, for id: UUID) -> Bool {
        guard let index = messages.firstIndex(where: { $0.id == id }), messages[index].isUser else { return false }
        if let current = messages[index].receipt, current.rawValue >= receipt.rawValue { return false }
        messages[index].receipt = receipt
        return true
    }
    public func react(_ value: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }), messages[index].supportsReactions else { return }
        let reaction = messages[index].reaction == value ? nil : value
        messages[index].reaction = reaction
        onAction(.reaction(message: id, value: reaction))
    }
    public func copy(_ id: UUID) {
        guard let message = messages.first(where: { $0.id == id }) else { return }
        onAction(.copy(message: id, text: message.displayText))
    }
    public func togglePause() {
        isPaused.toggle()
        onAction(.pause(isPaused))
    }
    public func deleteLocalConversation() {
        messages.removeAll()
        replyTo = nil
        draft = ""
        onAction(.delete)
    }
    public func revokeComputer() {
        guard computerAvailable else { return }
        computerAvailable = false
        onAction(.revokeComputer(computerName))
    }
    public func beginCall() {
        guard callPhase == .idle else { return }
        callPhase = .calling
        callElapsedSeconds = 0
        callMinimized = false
        onAction(.beginCall)
    }
    public func retryCall() {
        guard callPhase == .failed else { return }
        callPhase = .calling
        callElapsedSeconds = 0
        onAction(.beginCall)
    }
    public func endCall() {
        guard callPhase != .idle else { return }
        callPhase = .idle
        callMinimized = false
        onAction(.endCall)
    }
    public func toggleSpeaker() {
        speakerEnabled.toggle()
        onAction(.speaker(speakerEnabled))
    }
    public func toggleMute() {
        microphoneMuted.toggle()
        onAction(.mute(microphoneMuted))
    }
}
