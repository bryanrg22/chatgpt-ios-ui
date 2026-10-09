import SwiftUI
import ChatGPTUI
import ChatGPTWidgets
import WidgetKit
import UIKit

@main struct ChatGPTDemoApp: App {
    @State private var state = ChatState()
    @State private var hasConfigured = false
    @State private var responseTask: Task<Void, Never>?
    @State private var playbackTask: Task<Void, Never>?
    @State private var playbackToken = UUID()
    @State private var selectedMarkdownLink: URL?
    @ViewBuilder private var demoContent: some View {
        if ProcessInfo.processInfo.arguments.contains("--dot-system-preview") {
            VStack(spacing: 60) {
                DotSystemCallPreview(presentation: state.dot.callPresentation, style: .compact)
                DotSystemCallPreview(presentation: state.dot.callPresentation, style: .expanded) { action in
                    if case .mute = action { state.dot.toggleMute() }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(white: 0.12)).preferredColorScheme(
                .dark)
        } else {
            demoChatView(state: state)
        }
    }
    var body: some Scene {
        WindowGroup {
            demoContent.onAppear {
                guard !hasConfigured else { return }
                hasConfigured = true
                installDemoFixtures(state)
                state.settings.onAction = { action in
                    if case .openLink(_, let url) = action { selectedMarkdownLink = url }
                }
                WidgetCenter.shared.reloadAllTimelines()
                state.onAction = { action in
                    switch action {
                    case .send, .retry:
                        responseTask?.cancel()
                        guard let id = state.responseID else { return }
                        responseTask = Task { @MainActor in
                            let words =
                                "Hello! I'm ready to help. What would you like to work on today?\n\nWe can start by outlining your goal, gathering a few ideas, and turning them into a clear plan. Tell me what matters most, and we'll take it one step at a time."
                                .split(separator: " ")
                            var result = ""
                            for word in words {
                                do {
                                    try await Task.sleep(
                                        for: .milliseconds(
                                            ProcessInfo.processInfo.arguments.contains("--ui-test") ? 180 : 80))
                                } catch { return }
                                guard !Task.isCancelled else { return }
                                result += (result.isEmpty ? "" : " ") + word
                                state.updateResponse(id: id, text: result)
                            }
                            state.updateResponse(id: id, text: result, finished: true)
                        }
                    case .stop, .newChat: responseTask?.cancel()
                    case .voiceText(let text):
                        state.voice.transcript.append(.init(role: .user, text: text))
                        state.voice.transcript.append(
                            .init(
                                role: .assistant,
                                text:
                                    "Start with a sunny spot and a few easy herbs. Basil, mint, and parsley work well in small containers."
                            ))
                    case .markdown(.copyCode(let text)): UIPasteboard.general.string = text
                    case .markdown(.openLink(let url)): selectedMarkdownLink = url
                    case .copyMessage(_, let text): UIPasteboard.general.string = text
                    case .media(.copy(let id)):
                        let item = (state.messages.flatMap(\.media) + state.media + state.photoPicker.items).first {
                            $0.id == id
                        }
                        if let key = item?.imageKey { UIPasteboard.general.image = DemoMediaFixture.images[key] }
                    case .readAloud(let id, let playing):
                        playbackTask?.cancel()
                        playbackToken = UUID()
                        let token = playbackToken
                        if playing {
                            playbackTask = Task { @MainActor in
                                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                                guard !Task.isCancelled, playbackToken == token, state.speakingMessage == id,
                                    state.readAloudPlaying
                                else { return }
                                state.readAloudElapsed = 1
                                state.readAloudPlaying = false
                            }
                        }
                    default: break
                    }
                }
                state.voice.onAction = { action in
                    switch action {
                    case .requestScreenSharing:
                        state.voice.variant = .classic
                        state.voice.isSharingScreen = true
                    case .requestLiveVideo: state.voice.showsLiveCamera = true
                    default: break
                    }
                }
                let arguments = ProcessInfo.processInfo.arguments
                if let screen = DemoScreen(launchArguments: arguments) {
                    applyDemoScreen(screen, to: state, baseArguments: arguments)
                } else {
                    applyDemoLaunchArguments(arguments, to: state)
                }
            }.alert(
                "Link",
                isPresented: Binding(
                    get: { selectedMarkdownLink != nil }, set: { if !$0 { selectedMarkdownLink = nil } })
            ) {
                Button("Done") { selectedMarkdownLink = nil }
            } message: {
                Text(selectedMarkdownLink?.absoluteString ?? "")
            }
            .onOpenURL { url in
                guard let route = ChatWidgetRoute(url: url) else { return }
                state.showsDrawer = false
                state.showsAttachmentMenu = false
                state.camera.close()
                state.photoPicker.close()
                if route.destination != .voice { state.setVoice(false) }
                if route.destination != .dictation { state.finishDictation() }
                switch route.destination {
                case .chat: state.page = .chat
                case .work: state.page = .work
                case .codex:
                    state.page = .codex
                    if let id = route.taskID { state.codex.openTask(id) }
                case .remote:
                    state.page = .dot
                    state.dot.computerIsPresented = true
                case .camera:
                    state.page = .chat
                    state.camera.open()
                case .photos:
                    state.page = .chat
                    state.photoPicker.isPresented = true
                    state.onAction(.attach("Photos"))
                case .dictation:
                    state.page = .chat
                    state.beginDictation()
                case .voice:
                    state.page = .chat
                    state.setVoice(true)
                }
            }
        }
    }
}
