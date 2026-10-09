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
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(white: 0.12)).preferredColorScheme(.dark)
        } else { ChatGPTView(state: state, spaceImageProvider: { item in item.imageKey.flatMap { DemoMediaFixture.images[$0] }.map(Image.init(uiImage:)) }, mediaImageProvider: { item in DemoMediaFixture.images[item.imageKey].map(Image.init(uiImage:)) }, mediaVideoProvider: { _ in AnyView(DemoVideoContent()) }, imagesArtwork: { AnyView(DemoTemplateArtwork(key: $0.artworkKey)) }) }
    }
    var body: some Scene {
        WindowGroup {
            demoContent.onAppear {
                guard !hasConfigured else { return }; hasConfigured = true
                state.settings.account = .init(displayName: "Alex Morgan", username: "alexmorgan", email: "alex@example.com", avatarInitials: "AM", subscription: "Pro")
                state.settings.about = .init(appName: "ChatGPT for iOS", version: "1.2026.267", build: "36747771815", termsURL: URL(string: "https://example.com/terms"), privacyURL: URL(string: "https://example.com/privacy"))
                state.settings.onAction = { action in if case .openLink(_, let url) = action { selectedMarkdownLink = url } }
                configureFeatureFixtures(state)
                configureSpaceFixtures(state)
                configureImagesFixtures(state)
                state.photoPicker.items = DemoMediaFixture.items
                WidgetCenter.shared.reloadAllTimelines()
                state.onAction = { action in
                    switch action {
                    case .send, .retry:
                        responseTask?.cancel()
                        guard let id = state.responseID else { return }
                        responseTask = Task { @MainActor in
                            let words = "Hello! I'm ready to help. What would you like to work on today?\n\nWe can start by outlining your goal, gathering a few ideas, and turning them into a clear plan. Tell me what matters most, and we'll take it one step at a time.".split(separator: " ")
                            var result = ""
                            for word in words {
                                do { try await Task.sleep(for: .milliseconds(ProcessInfo.processInfo.arguments.contains("--ui-test") ? 180 : 80)) } catch { return }
                                guard !Task.isCancelled else { return }
                                result += (result.isEmpty ? "" : " ") + word
                                state.updateResponse(id: id, text: result)
                            }
                            state.updateResponse(id: id, text: result, finished: true)
                        }
                    case .stop, .newChat: responseTask?.cancel()
                    case .voiceText(let text):
                        state.voice.transcript.append(.init(role: .user, text: text))
                        state.voice.transcript.append(.init(role: .assistant, text: "Start with a sunny spot and a few easy herbs. Basil, mint, and parsley work well in small containers."))
                    case .markdown(.copyCode(let text)): UIPasteboard.general.string = text
                    case .markdown(.openLink(let url)): selectedMarkdownLink = url
                    case .copyMessage(_, let text): UIPasteboard.general.string = text
                    case .media(.copy(let id)):
                        let item = (state.messages.flatMap(\.media) + state.media + state.photoPicker.items).first { $0.id == id }
                        if let key = item?.imageKey { UIPasteboard.general.image = DemoMediaFixture.images[key] }
                    case .readAloud(let id, let playing):
                        playbackTask?.cancel(); playbackToken = UUID()
                        let token = playbackToken
                        if playing {
                            playbackTask = Task { @MainActor in
                                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                                guard !Task.isCancelled, playbackToken == token, state.speakingMessage == id, state.readAloudPlaying else { return }
                                state.readAloudElapsed = 1; state.readAloudPlaying = false
                            }
                        }
                    default: break
                    }
                }
                state.voice.onAction = { action in
                    switch action {
                    case .requestScreenSharing: state.voice.variant = .classic; state.voice.isSharingScreen = true
                    case .requestLiveVideo: state.voice.showsLiveCamera = true
                    default: break
                    }
                }
                let arguments = ProcessInfo.processInfo.arguments
                if arguments.contains("--empty-finance") { state.finance.data = .init(); state.finance.transactions = []; state.page = .finances }
                if arguments.contains("--empty-health") { state.health.data = .init(); state.health.providerStatus = [:]; state.health.setupComplete = true; state.page = .health }
                state.voice.animatesOrbTexture = !arguments.contains("--ui-test")
                if arguments.contains("--ui-test") { state.appearance = "Dark" }
                if arguments.contains("--light") { state.appearance = "Light" }
                if arguments.contains("--conversation"), state.messages.isEmpty {
                    state.messages = [.init(role: .user, text: "Reply with a short greeting."), .init(role: .assistant, text: "Hey! 👋 How’s it going?")]
                }
                if arguments.contains("--work-task") { configureDemoWorkTask(state, prompt: "Design a poster for a neighborhood garden event.") }
                if arguments.contains("--images") { state.page = .images }
                if arguments.contains("--settings") { state.page = .settings }
                if arguments.contains("--general") { state.open(.settings); state.openSettings(.general) }
                if arguments.contains("--about") { state.open(.settings); state.openSettings(.about) }
                if arguments.contains("--markdown") { state.messages = [.init(role: .assistant, text: demoMarkdown)] }
                if arguments.contains("--inline-code") { state.messages = [.init(role: .assistant, text: demoInlineCode)] }
                if arguments.contains("--table-code") { state.messages = [.init(role: .assistant, text: demoTableCode)] }
                if arguments.contains("--dot-connected") { state.page = .dot; state.dot.applyCallPresentation(.init(phase: .connected, elapsedSeconds: 38)) }
                if arguments.contains("--dot-summary") {
                    state.page = .dot
                    let summary = DotMessage(text: "", isUser: true, kind: .callEnded(durationSeconds: 443), receipt: .delivered)
                    state.dot.append(summary)
                    if arguments.contains("--dot-read") { state.dot.updateReceipt(.read, for: summary.id) }
                }
                if arguments.contains("--dot-failed") { state.page = .dot; state.dot.callPhase = .failed; state.dot.callMinimized = true }
                if arguments.contains("--voice-classic") { state.voice.start(); state.voice.variant = .classic; state.setVoice(true) }
                if arguments.contains("--long-draft") { state.draft = String(repeating: "This is a long draft to measure the composer.\n", count: 15) }
            }.alert("Link", isPresented: Binding(get: { selectedMarkdownLink != nil }, set: { if !$0 { selectedMarkdownLink = nil } })) {
                Button("Done") { selectedMarkdownLink = nil }
            } message: { Text(selectedMarkdownLink?.absoluteString ?? "") }
            .onOpenURL { url in
                guard let route = ChatWidgetRoute(url: url) else { return }
                state.showsDrawer = false; state.showsAttachmentMenu = false
                state.camera.close(); state.photoPicker.close()
                if route.destination != .voice { state.setVoice(false) }
                if route.destination != .dictation { state.finishDictation() }
                switch route.destination {
                case .chat: state.page = .chat
                case .work: state.page = .work
                case .codex:
                    state.page = .codex
                    if let id = route.taskID { state.codex.openTask(id) }
                case .remote: state.page = .dot; state.dot.computerIsPresented = true
                case .camera: state.page = .chat; state.camera.open()
                case .photos: state.page = .chat; state.photoPicker.isPresented = true; state.onAction(.attach("Photos"))
                case .dictation: state.page = .chat; state.beginDictation()
                case .voice: state.page = .chat; state.setVoice(true)
                }
            }
        }
    }
}

/// Fictional fixtures belong to this executable, never to the reusable package.
@MainActor private func configureFeatureFixtures(_ state: ChatState) {
    var finance = FinancePresentationData()
    finance.spendingTotal = 1420; finance.spendingPeriod = "October"
    finance.spendingSegments = [0.68, 0.16, 0.08, 0.04, 0.04]
    finance.spendingCategories = zip(["Housing", "Entertainment", "Shopping", "Dining"], ["house", "popcorn", "bag", "fork.knife"]).map { title, symbol in
        .init(id: title, title: title, symbol: symbol, amount: title == "Housing" ? 1100 : 80, relativeBarWidth: title == "Housing" ? 1 : 20.0 / 148)
    }
    for title in FinanceWorkspaceState.dashboardOptions where title != "Spend by category" {
        finance.dashboardValues[title] = title == "Net Worth" ? .amount(12600) : title == "Credit score" ? .text("720") : .text("No additional sample activity")
    }
    finance.accountGroups = ["Cash", "Investments", "Credit"].map { group in
        let names = group == "Cash" ? ["EVERYDAY SAVINGS", "SAMPLE CHECKING"] : ["EXAMPLE " + group.uppercased()]
        return .init(id: group, title: group, subtitle: group == "Cash" ? "20% of assets" : "Sample accounts", balance: group == "Cash" ? 1200 : 4800, accounts: names.map { name in
            .init(id: name, title: name, subtitle: "Sample · 1001", balance: 600, updated: "1 hour ago")
        })
    }
    finance.chats = ["Review sample balances", "Track a savings goal"].map { .init(id: $0, title: $0, preview: "Explore the example information…") }
    finance.creditProvider = "Experian"; finance.creditScore = "720"
    state.finance.data = finance
    let date = Date(timeIntervalSince1970: 1791417600)
    state.finance.referenceDate = date
    state.finance.transactions = [.init(name: "Example employer", category: "Income", account: "Checking 1001", amount: 1800, date: date), .init(name: "To savings", category: "Transfers", account: "Savings 2002", amount: -75, date: date.addingTimeInterval(-86400)), .init(name: "Neighborhood Cafe", category: "Dining", account: "Credit Card 3003", amount: -18.50, date: date.addingTimeInterval(-86400), pending: true)]
    state.finance.onAction = { [weak state] action in
        guard let state else { return }
        switch action {
        case .startChat(let prompt) where prompt.hasPrefix("Help me track a cash account manually."):
            state.finance.chatMessages.append(.init(role: .assistant, text: "Let’s add your cash account to Finances as a separate, manually tracked account.\n\nFirst question: What would you like to name the account?\n\nFor example: Everyday Checking, Emergency Savings, or Cash Account."))
        case .openChat(let id):
            if let chat = state.finance.data.chats.first(where: { $0.id == id }) { state.finance.beginChat(chat.title) }
        default: break
        }
    }
    var health = HealthPresentationData()
    let samples = [15.0, 33, 24, 8, 18, 30, 13].map { $0 / 40 }
    health.introductionMetrics = [
        .init(id: "ldl", title: "LDL cholesterol", value: "88", unit: "mg/dL · Sample", bars: false, chartSamples: samples),
        .init(id: "calories", title: "Active calories", value: "420", unit: "cal · Sample", bars: true, chartSamples: samples),
        .init(id: "heart", title: "Resting heart rate", value: "64", unit: "bpm · Sample", bars: false, chartSamples: samples)]
    health.activityMetrics = [
        .init(id: "distance", title: "Distance walking + running", value: "1.8", unit: "mi · Yesterday", bars: true, chartSamples: samples),
        .init(id: "flights", title: "Flights climbed", value: "4", unit: "· Yesterday", bars: true, chartSamples: samples),
        .init(id: "steps", title: "Step count", value: "4,200", unit: "/d · Yesterday", bars: true, chartSamples: samples),
        .init(id: "speed", title: "Walking speed", value: "2.4", unit: "mi/h · Yesterday", bars: false, chartSamples: samples)]
    health.providers = ["Apple Health", "Function Health", "One Medical", "Cedars-Sinai", "UCLA Medical Center", "UC San Diego", "Kaiser Permanente - Southern California", "Rush University Medical Center", "City of Hope"].map {
        .init(id: $0, name: $0, symbol: $0 == "Apple Health" ? "heart.fill" : "cross.case.fill", isConnected: $0 == "Apple Health", accountStatus: $0 == "Apple Health" ? "Connected" : "")
    }
    state.health.data = health; state.health.providerStatus = ["Apple Health": "Syncing…"]
}

@MainActor private func configureSpaceFixtures(_ state: ChatState) {
    state.space.replaceItems([
        .init(title: "Garden design", kind: .image, origin: .generated, imageKey: "garden-0"),
        .init(title: "Planting guide", subtitle: "October 8", kind: .document),
        .init(title: "Seasonal notes", subtitle: "October 7", kind: .pdf),
        .init(title: "Workshop", subtitle: "Connected", kind: .folder),
        .init(title: "Project ideas", subtitle: "October 6", kind: .page)
    ])
    state.space.onAction = { [weak state] action in
        if case .openPlugins = action { state?.page = .plugins }
    }
}

/// Original programmatic fixture artwork. No source screenshots or user photos.
@MainActor private enum DemoMediaFixture {
    static let video = ChatMedia(id: UUID(uuidString: "20000000-0000-0000-0000-000000000000")!, imageKey: "garden-video", title: "Garden clip", aspectRatio: 1179.0 / 2556, kind: .video, durationSeconds: 8)
    static let items: [ChatMedia] = (0..<12).map { .init(id: UUID(uuidString: String(format: "10000000-0000-0000-0000-%012d", $0))!, imageKey: "garden-\($0)", title: "Garden notes \($0 + 1)", aspectRatio: 480.0 / 496) } + [video]
    static let images: [String: UIImage] = Dictionary(uniqueKeysWithValues: (0..<12).map { index in
        let artwork = UIGraphicsImageRenderer(size: CGSize(width: 480, height: 496)).image { context in
            let hue = CGFloat(index) / 18 + 0.3
            UIColor(hue: hue, saturation: 0.65, brightness: 0.6, alpha: 1).setFill(); context.fill(CGRect(x: 0, y: 0, width: 480, height: 496))
            UIColor(red: 0.96, green: 0.98, blue: 0.91, alpha: 1).setFill(); context.fill(CGRect(x: 10, y: 10, width: 460, height: 476))
            UIColor(hue: hue, saturation: 0.7, brightness: 0.5, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 205, y: 76, width: 80, height: 135)).fill()
            UIBezierPath(ovalIn: CGRect(x: 143, y: 120, width: 83, height: 44)).fill()
            let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
            ("Garden notes\n\(index + 1)" as NSString).draw(in: CGRect(x: 20, y: 275, width: 440, height: 160), withAttributes: [.font: UIFont.systemFont(ofSize: 48, weight: .medium), .foregroundColor: UIColor(hue: hue, saturation: 0.7, brightness: 0.5, alpha: 1), .paragraphStyle: paragraph])
        }
        return ("garden-\(index)", artwork)
    }).merging(["garden-video": videoPoster]) { _, new in new }
    static let videoPoster = UIGraphicsImageRenderer(size: CGSize(width: 1179, height: 2556)).image { context in
        UIColor(red: 0.08, green: 0.23, blue: 0.15, alpha: 1).setFill(); context.fill(CGRect(x: 0, y: 0, width: 1179, height: 2556))
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        ("Garden notes" as NSString).draw(in: CGRect(x: 60, y: 1210, width: 1059, height: 150), withAttributes: [.font: UIFont.systemFont(ofSize: 80, weight: .medium), .foregroundColor: UIColor.white, .paragraphStyle: paragraph])
    }
}

private let demoMarkdown = """
## Garden notes

A **small garden** can be *easy to maintain*.

> Start with one sunny corner.

---

### Planting list

- Choose a container
  - Add drainage
  - Prepare the soil
- Water gently

Use `print("Hello!")` as a code example.

### Code Block

```python
def greet(name):
    return f"Hello, {name}!"

print(greet("World"))
```

Visit the [garden guide](https://example.com/garden-guide) for more information.

### Small Table

| Item | Description |
| --- | --- |
| 1 | Choose a container |
| 2 | Add soil |
| 3 | Plant seeds |
"""

/// Original silent moving fixture supplied by the demo host, not an AV player.
private struct DemoVideoContent: View {
    var body: some View {
        TimelineView(.animation) { context in
            let offset = sin(context.date.timeIntervalSinceReferenceDate * 0.8) * 40
            ZStack {
                Color(red: 0.08, green: 0.23, blue: 0.15)
                Ellipse().fill(.green.opacity(0.5)).frame(width: 180, height: 260).blur(radius: 24).offset(x: offset, y: -80)
                Text("Garden notes").font(.system(size: 28, weight: .medium)).foregroundStyle(.white)
            }
        }.aspectRatio(1179.0 / 2556, contentMode: .fit)
    }
}


@MainActor private func configureImagesFixtures(_ state: ChatState) {
    state.images.onAction = { action in
        switch action {
        case .tryTemplate(let item): configureDemoWorkTask(state, prompt: item.prompt)
        case .submitPrompt(let text, _): configureDemoWorkTask(state, prompt: text)
        default: break
        }
    }
    state.images.items = [
        .init(id: "poster", title: "Poster", headline: "Design a poster", prompt: "Create a poster that expresses my idea through clear hierarchy, readable required text, and imagery/typography that work together for the intended audience.", artworkKey: "poster"),
        .init(id: "interior", title: "Interior design", headline: "Design an interior", prompt: "Explore a quiet reading room with plants and warm natural light.", artworkKey: "interior"),
        .init(id: "logo", title: "Logo", headline: "Create a logo", prompt: "Create a simple mark for a neighborhood garden club.", artworkKey: "logo"),
        .init(id: "illustration", title: "Illustration", headline: "Make an illustration", prompt: "Illustrate a peaceful moment in a small garden.", artworkKey: "illustration"),
        .init(id: "aerial", title: "Aerial view", headline: "Explore an aerial view", prompt: "Show a small garden from above.", artworkKey: "aerial", category: .trending),
        .init(id: "tin", title: "Collector’s tin", headline: "Create a collector’s tin", prompt: "Arrange a collection of favorite garden objects.", artworkKey: "tin", category: .trending),
        .init(id: "flashback", title: "’80s flashback", headline: "Create an ’80s flashback", prompt: "Make a colorful retro portrait illustration.", artworkKey: "flashback", category: .trending),
        .init(id: "caricature", title: "Caricature", headline: "Draw a caricature", prompt: "Draw a playful portrait of a gardener.", artworkKey: "caricature", category: .trending)
    ]
}

/// Original generated sample artwork; actual product thumbnails remain host-supplied.
private struct DemoTemplateArtwork: View {
    let key: String
    var body: some View {
        GeometryReader { geometry in
            if key == "logo" {
                ZStack {
                    Color(red: 0.78, green: 0.83, blue: 0.86)
                    ZStack {
                        Circle().fill(Color(red: 0.17, green: 0.2, blue: 0.49))
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5).padding(5)
                        Image(systemName: "fish").font(.system(size: geometry.size.width * 0.3)).rotationEffect(.degrees(-90)).foregroundStyle(Color(red: 0.78, green: 0.83, blue: 0.86))
                    }.frame(width: geometry.size.width * 0.62, height: geometry.size.width * 0.62)
                }
            } else if key == "poster", geometry.size.width > geometry.size.height {
                ZStack {
                    Color(red: 0.965, green: 0.535, blue: 0.235)
                    Image("gallery-poster").resizable().scaledToFit()
                }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
            } else {
                Image("gallery-" + key).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }
        }
    }
}

@MainActor private func configureDemoWorkTask(_ state: ChatState, prompt: String) {
    state.draft = ""; state.composerContext = nil
    state.workTask = WorkTaskPresentationState(messages: [.init(role: .user, text: prompt)], status: .working)
    state.workTask.onAction = { action in
        guard case .stop = action else { return }
        let questions: [WorkClarificationQuestion] = [
            .init(title: "What should the poster communicate, and what exact text or supplied assets must it include?", options: ["Event announcement", "Idea or campaign", "Art or personal project"].map { .init(title: $0) }),
            .init(title: "Which visual direction would you like to explore?", options: ["Bright and playful", "Simple and calm", "Classic typography"].map { .init(title: $0) }),
            .init(title: "Where will the poster be used?", options: ["Printed flyer", "Social post", "Both formats"].map { .init(title: $0) })
        ]
        state.workTask.update(messages: state.workTask.messages, status: .stopped, questions: questions, traceItems: [.init(text: "Reviewing the poster request"), .init(text: "Preparing a few questions about the design", isSecondary: true)])
        state.workTask.showClarification()
    }
    state.page = .workTask
}

private let demoInlineCode = """
## Garden notes

Use `print("Hello!")` as a code example. **Keep `soil` moist**, and visit the [garden guide](https://example.com/garden-guide).

A wrapping example: `container.prepare(soil: compost, seeds: basil, watering: gentle, sunlight: morning)` finishes here.

Ordinary text remains easy to select.
"""

private let demoTableCode = """
## Garden reference

| Left | Center | Right |
| :--- | :---: | ---: |
| `mint` [guide](https://example.com/garden-guide) | `water_seedlings_gently` | `morning_sunlight` |
| `soil` | `basil` | `sun` |

### Wide table

| One | Two | Three | Four | Five | Six | Seven | Eight |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `one` | `two` | `three` | `four` | `five` | `six` | `seven` | `eight` |
"""
