import Foundation
import Observation

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public enum Role: String, Sendable { case user, assistant }
    public let id: UUID
    public let role: Role
    public var text: String
    public var attachments: [String]
    public var media: [ChatMedia]
    public var context: ChatComposerContext?
    public init(id: UUID = UUID(), role: Role, text: String, attachments: [String] = [], media: [ChatMedia] = [], context: ChatComposerContext? = nil) {
        self.id = id; self.role = role; self.text = text; self.attachments = attachments; self.media = media; self.context = context
    }
}
public enum ChatAction: Equatable, Sendable {
    case send(text: String, attachments: [String], thinkHarder: Bool, media: [ChatMedia] = [], context: ChatComposerContext? = nil)
    case stop, newChat, beginDictation, endDictation, beginVoice, endVoice
    case attach(String), selectModel(String), openDestination(String)
    case copyMessage(UUID, String), feedback(UUID, MessageFeedback?), retry(originalID: UUID, responseID: UUID), readAloud(UUID, Bool), share(UUID)
    case submitFeedback(UUID, issue: String, details: String), branch(UUID)
    case camera(CameraAction)
    case attachMedia(ChatMedia), removeDraftMedia(UUID), media(MediaAction), requestPhotoLibrary
    case markdown(MarkdownAction)
    case selectVoice(String), voiceMuted(Bool), voiceLanguage(String), voiceText(String)
    case voiceNavigation(VoiceNavigationIntent), voiceDraftChanged(String)
}
public enum MessageFeedback: String, Sendable { case positive, negative }
public enum ComposerMode: Equatable, Sendable { case idle, dictating, responding }
public enum ChatPage: String, CaseIterable, Sendable {
    case chat = "Chat", work = "Work", customize = "Customize", personality = "Personality"
    case settings = "Settings", general = "General", memory = "Memory", plugins = "Plugins", about = "About"
    case health = "Health", finances = "Finances"
    case sites = "Sites", projects = "Projects", images = "Images", workTask = "Work task"
    case dot = "Your dot", scheduled = "Scheduled", space = "Space", codex = "Codex", explore = "Explore"
}

/// Owns only presentation state. Hosts consume actions and supply content; no networking or device access.
@MainActor @Observable public final class ChatState {
    public var draft = ""
    public var composerContext: ChatComposerContext?
    public let explore = ExplorePresentationState()
    public let projects = ProjectsPresentationState()
    public let images = ImagesPresentationState()
    public let settings = SettingsPresentationState()
    public var workTask = WorkTaskPresentationState()
    public var attachments: [String] = []
    public var media: [ChatMedia] = []
    public var videoCardPresentations: [UUID: VideoCardPresentation] = [:]
    public let mediaViewer = MediaViewerState()
    public let photoPicker = PhotoPickerPresentationState()
    public var favoriteMediaIDs: Set<UUID> = []
    public var messages: [ChatMessage] = []
    public private(set) var feedback: [UUID: MessageFeedback] = [:]
    public private(set) var speakingMessage: UUID?
    public var readAloudPlaying = false
    public var readAloudElapsed = 0.0
    public var readAloudSpeed = 1.0
    public private(set) var copiedMessage: UUID?
    public private(set) var composerMode: ComposerMode = .idle
    public private(set) var responseID: UUID?
    public private(set) var editingMessageID: UUID?
    private var draftBeforeEditing = ""
    private var attachmentsBeforeEditing: [String] = []
    private var mediaBeforeEditing: [ChatMedia] = []
    private var contextBeforeEditing: ChatComposerContext?
    public let camera = CameraPresentationState()
    public let voice = VoicePresentationState()
    public let codex = CodexPresentationState()
    public let dot = DotPresentationState()
    public let finance = FinanceWorkspaceState()
    public let health = HealthWorkspaceState()
    public let space = SpacePresentationState()
    public var dictationLevels: [Double] = []
    public var thinkHarder = true
    public var temporaryChat = false
    public var showsDrawer = false
    public var showsAttachmentMenu = false
    public var showsVoice = false
    public var page: ChatPage = .chat
    private var navigationHistory: [ChatPage] = []
    public var model = "GPT-6"
    public var search = ""
    public var searchCategory = "All"
    public var scheduled = ScheduledPresentationState()
    public var memorySummary = MemorySummaryPresentationState()
    public var pluginCatalog = PluginCatalogPresentationState()
    public var appearance = "System"
    public var accentName = "Blue"
    public var showsVoiceAnnouncement = true
    public var temporaryPersonalized = true
    public var workModel = "6.1 Sol"
    public var workEffort = "Medium"
    public var startScreen = "Chat"
    public var style = "Default"
    public var warmth = 0.5
    public var enthusiasm = 0.5
    public var headers = 0.5
    public var emoji = 0.5
    public var instructions = ""
    public var autoCorrect = true
    public var haptics = true
    public var autocomplete = true
    public var trending = true
    public var webSearch = true
    public var referenceMemory = true
    public var displayName: String { get { settings.account.displayName } set { settings.account.displayName = newValue } }
    public var username: String { get { settings.account.username } set { settings.account.username = newValue } }
    public var email: String { get { settings.account.email } set { settings.account.email = newValue } }
    public var onAction: @MainActor (ChatAction) -> Void
    public init(onAction: @escaping @MainActor (ChatAction) -> Void = { _ in }) {
        self.onAction = onAction
        mediaViewer.onAction = { [weak self] action in
            guard let self else { return }
            if case .favorite(let id, let selected) = action {
                if selected { self.favoriteMediaIDs.insert(id) } else { self.favoriteMediaIDs.remove(id) }
            }
            self.onAction(.media(action))
        }
    }
    public var canSend: Bool { composerMode == .idle && (!draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty || !media.isEmpty) }
    @discardableResult public func send() -> UUID? {
        guard canSend else { return nil }
        if let editingMessageID, let index = messages.firstIndex(where: { $0.id == editingMessageID }) {
            removeMessages(from: index)
        }
        editingMessageID = nil; draftBeforeEditing = ""; attachmentsBeforeEditing = []; mediaBeforeEditing = []; contextBeforeEditing = nil
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let files = attachments; let images = media
        messages.append(ChatMessage(role: .user, text: text, attachments: files, media: images, context: composerContext))
        let reply = ChatMessage(role: .assistant, text: "")
        messages.append(reply); responseID = reply.id; composerMode = .responding
        draft = ""; attachments = []; media = []; showsAttachmentMenu = false
        onAction(.send(text: text, attachments: files, thinkHarder: thinkHarder, media: images, context: composerContext))
        return reply.id
    }
    /// Request identity prevents cancelled or superseded response streams from editing a newer chat.
    public func updateResponse(id: UUID, text: String, finished: Bool = false) {
        guard responseID == id, composerMode == .responding,
              let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
        if finished { responseID = nil; composerMode = .idle }
    }
    public func stop() { responseID = nil; composerMode = .idle; onAction(.stop) }
    public func newChat() {
        responseID = nil; composerMode = .idle; messages = []; draft = ""; composerContext = nil; attachments = []; media = []; videoCardPresentations = [:]; mediaViewer.dismiss()
        editingMessageID = nil; draftBeforeEditing = ""; attachmentsBeforeEditing = []; mediaBeforeEditing = []; contextBeforeEditing = nil
        closeReadAloud(); feedback = [:]; copiedMessage = nil; navigationHistory = []; dictationLevels = []
        camera.close(); photoPicker.close()
        if voice.close() { onAction(.endVoice) }
        voice.clearConversation()
        page = .chat; showsDrawer = false; showsAttachmentMenu = false; showsVoice = false
        onAction(.newChat)
    }
    public func setFeedback(_ value: MessageFeedback, for id: UUID) {
        guard messages.contains(where: { $0.id == id && $0.role == .assistant }) else { return }
        feedback[id] = feedback[id] == value ? nil : value
        onAction(.feedback(id, feedback[id]))
    }
    public func copyMessage(_ message: ChatMessage) {
        copiedMessage = message.id; onAction(.copyMessage(message.id, message.text))
    }
    public func clearCopyConfirmation(id: UUID) { if copiedMessage == id { copiedMessage = nil } }
    public func toggleReadAloud(_ id: UUID) {
        speakingMessage = speakingMessage == id ? nil : id
        readAloudPlaying = speakingMessage != nil; readAloudElapsed = 0
        onAction(.readAloud(id, speakingMessage == id))
    }
    public func closeReadAloud() {
        if let id = speakingMessage { onAction(.readAloud(id, false)) }
        speakingMessage = nil; readAloudPlaying = false; readAloudElapsed = 0; readAloudSpeed = 1
    }
    public func togglePlayback() {
        guard let id = speakingMessage else { return }
        readAloudPlaying.toggle(); onAction(.readAloud(id, readAloudPlaying))
    }
    public func retry(_ id: UUID) {
        guard composerMode == .idle, let index = messages.firstIndex(where: { $0.id == id && $0.role == .assistant }) else { return }
        // Keep earlier conversation context and retire later turns so a retry has one unambiguous stream.
        removeMessages(from: index)
        let message = ChatMessage(role: .assistant, text: "")
        messages.append(message); responseID = message.id; composerMode = .responding
        onAction(.retry(originalID: id, responseID: message.id))
    }
    private func removeMessages(from index: Int) {
        let removed = Set(messages[index...].map(\.id))
        let removedMedia = Set(messages[index...].flatMap(\.media).map(\.id))
        videoCardPresentations = videoCardPresentations.filter { !removedMedia.contains($0.key) }
        if let selected = mediaViewer.item, messages[index...].contains(where: { $0.media.contains(where: { $0.id == selected.id }) }) { mediaViewer.dismiss() }
        if let id = speakingMessage, removed.contains(id) { closeReadAloud() }
        if let id = copiedMessage, removed.contains(id) { copiedMessage = nil }
        feedback = feedback.filter { !removed.contains($0.key) }
        messages.removeSubrange(index...)
    }
    public func addAttachment(_ name: String) {
        attachments.append(name); showsAttachmentMenu = false; onAction(.attach(name))
    }
    public func videoCardPresentation(for item: ChatMedia) -> VideoCardPresentation { videoCardPresentations[item.id] ?? .pausedPoster }
    public func openMedia(_ item: ChatMedia) { mediaViewer.present(item, isFavorite: favoriteMediaIDs.contains(item.id)) }
    public func addMedia(_ item: ChatMedia) {
        if let index = media.firstIndex(where: { $0.id == item.id }) { media[index] = item } else { media.append(item) }
        showsAttachmentMenu = false; onAction(.attachMedia(item))
    }
    public func removeMedia(_ id: UUID) {
        guard media.contains(where: { $0.id == id }) else { return }
        media.removeAll { $0.id == id }; onAction(.removeDraftMedia(id))
    }
    public func beginEditing(_ message: ChatMessage) {
        guard message.role == .user, messages.contains(where: { $0.id == message.id }), composerMode == .idle, editingMessageID == nil else { return }
        editingMessageID = message.id; draftBeforeEditing = draft; attachmentsBeforeEditing = attachments; mediaBeforeEditing = media; contextBeforeEditing = composerContext
        draft = message.text; attachments = message.attachments; media = message.media; composerContext = message.context
    }
    public func cancelEditing() {
        guard editingMessageID != nil else { return }
        editingMessageID = nil; draft = draftBeforeEditing; attachments = attachmentsBeforeEditing; media = mediaBeforeEditing; composerContext = contextBeforeEditing
        draftBeforeEditing = ""; attachmentsBeforeEditing = []; mediaBeforeEditing = []; contextBeforeEditing = nil
    }
    public func beginDictation() {
        guard composerMode == .idle else { return }; dictationLevels = []; composerMode = .dictating; onAction(.beginDictation)
    }
    public func finishDictation(transcript: String? = nil) {
        guard composerMode == .dictating else { return }
        if let transcript, !transcript.isEmpty { draft += (draft.isEmpty ? "" : " ") + transcript }
        composerMode = .idle; dictationLevels = []; onAction(.endDictation)
    }
    public func createSiteDraft() {
        newChat(); page = .work; composerContext = .sites; draft = "Create a website that ..."
        explore.onAction(.createSite)
    }
    public func open(_ destination: ChatPage) {
        if destination == .explore { explore.expand(); showsDrawer = true; return }
        if showsDrawer || destination == .chat { navigationHistory = [] }
        else if destination != page { navigationHistory.append(page) }
        page = destination; showsDrawer = false; showsAttachmentMenu = false
        onAction(.openDestination(destination.rawValue))
    }
    public func goBack() { page = navigationHistory.popLast() ?? .chat }
    public func openSettings(_ destination: SettingsDestination) {
        settings.requestDestination(destination)
        switch destination {
        case .about: open(.about)
        case .general: open(.general)
        case .personalization: open(.personality)
        case .memory: open(.memory)
        case .plugins: open(.plugins)
        }
    }
    public func selectModel(_ value: String) { model = value; onAction(.selectModel(value)) }
    public func setVoice(_ active: Bool) {
        guard active != showsVoice else { return }
        showsVoice = active
        if active { voice.open(); if voice.isActive { onAction(.beginVoice) } }
        else if voice.close() { onAction(.endVoice) }
    }
    public func startVoice() { guard showsVoice else { return }; if voice.start() { onAction(.beginVoice) } }
    public func requestVoiceNavigation(_ destination: VoiceNavigationIntent) {
        guard showsVoice, voice.isActive else { return }
        onAction(.voiceNavigation(destination))
    }
}
