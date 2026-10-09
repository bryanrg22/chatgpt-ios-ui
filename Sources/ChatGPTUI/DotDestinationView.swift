#if os(iOS)
import SwiftUI

public struct DotDestinationView: View {
    @Bindable private var state: DotPresentationState
    private let onBack: () -> Void
    @State private var selectedMessage: DotMessage?
    @State private var selectedTextID: UUID?
    @State private var showDelete = false
    @State private var showsAttachments = false
    @State private var notice: String?
    @FocusState private var composerFocused: Bool
    public init(state: DotPresentationState, onBack: @escaping () -> Void) { self.state = state; self.onBack = onBack }
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(state.messages) { message in
                                bubble(message).blur(radius: state.replyTo != nil && state.replyTo != message.id ? 13 : 0).id(message.id)
                                    .onLongPressGesture { if selectedTextID != message.id { selectedMessage = message; composerFocused = false } }
                                    .accessibilityAction(named: "Reply") { state.beginReply(message.id); composerFocused = true }
                                    .accessibilityAction(named: "Copy") { copy(message) }
                            }
                        }.padding(.horizontal, 16).padding(.bottom, 16)
                    }.scrollIndicators(.hidden).defaultScrollAnchor(.bottom, for: .initialOffset)
                        .onChange(of: state.replyTo) { _, id in if let id { proxy.scrollTo(id, anchor: .center) } }
                        .onChange(of: state.messages.count) { _, _ in if let id = state.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) } }
                }
                composer.padding(.horizontal, composerFocused ? 12 : 34).padding(.bottom, 6)
            }
            if showsAttachments { attachmentMenu }
            if let message = selectedMessage { messageMenu(message) }
        }.background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .overlay(alignment: .top) { if state.callPhase != .idle { DotCallView(state: state).frame(maxHeight: state.callMinimized ? (state.callPhase == .failed ? 474 : 294) : .infinity, alignment: .top).padding(.horizontal, state.callMinimized ? 8 : 0).padding(.top, state.callMinimized ? 8 : 0).ignoresSafeArea(.container) } }
            .onChange(of: state.callPhase) { _, phase in if phase != .idle { composerFocused = false } }
            .onChange(of: state.computerIsPresented) { _, presented in if presented { composerFocused = false } }
            .fullScreenCover(isPresented: $state.computerIsPresented) { DotComputerView(state: state) { DotSyntheticDesktop() } }
            .confirmationDialog("Delete this local conversation?", isPresented: $showDelete, titleVisibility: .visible) { Button("Delete", role: .destructive) { state.deleteLocalConversation() }; Button("Cancel", role: .cancel) {} } message: { Text("This confirmation is a provisional offline-demo state; the original confirmation has not been captured.") }
            .alert("UI reference needed", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private var header: some View {
        ZStack(alignment: .top) {
            HStack {
                if state.replyTo == nil { Button(action: onBack) { DrawerGlyph() }.accessibilityLabel("Open sidebar") }
                Spacer()
                Button { if state.replyTo != nil { state.cancelReply() } else { composerFocused = false; state.beginCall() } } label: { GlassCircle(symbol: state.replyTo != nil ? "xmark" : "phone") }.accessibilityLabel(state.replyTo != nil ? "Cancel dot reply" : "Call dot")
            }.padding(.horizontal, 16)
            VStack(spacing: 0) {
                DotAvatar().frame(width: 58, height: 58)
                Menu {
                    Section("Computers") {
                        Button { composerFocused = false; state.onAction(.openComputer("Your dot’s computer")); state.computerIsPresented = true } label: { Label("Your dot’s computer", systemImage: "desktopcomputer") }
                        if state.computerAvailable {
                            Menu { Button("Revoke access", role: .destructive) { state.revokeComputer() } } label: { Label(state.computerName, systemImage: "desktopcomputer") }
                        }
                    }
                    Button { state.togglePause() } label: { Label(state.isPaused ? "Resume" : "Pause", systemImage: state.isPaused ? "play.circle" : "pause.circle") }
                    Button("Delete", systemImage: "trash", role: .destructive) { showDelete = true }
                } label: { Text(state.name).font(.system(size: 17, weight: .semibold)).padding(.horizontal, 12).frame(height: 36).glassEffect(.regular.interactive(), in: Capsule()) }.accessibilityIdentifier("dot.menu")
            }.padding(.top, 6)
        }.frame(height: 100)
    }
    private func bubble(_ message: DotMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 52) }
            VStack(alignment: .leading, spacing: 5) {
                if state.replyTo == message.id { Text("Today \(message.time)").font(.system(size: 12)).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.bottom, 10) }
                Group {
                    if message.isCallSummary {
                        Label(message.displayText, systemImage: "phone.down.fill").font(.system(size: 14)).foregroundStyle(Color(red: 0.76, green: 0.80, blue: 0.89))
                    } else if selectedTextID == message.id {
                        DotSelectableMessageText(text: message.displayText).frame(maxWidth: .infinity)
                    } else {
                        Text("\(message.text)\(Text(message.linkLabel.map { " " + $0 } ?? "").underline(message.linkLabel != nil))").font(.system(size: 17))
                    }
                }.padding(.horizontal, 16).padding(.vertical, message.isCallSummary ? 9 : 12)
                    .background(message.isUser ? Color(red: 0.11, green: 0.15, blue: 0.23) : ChatDesign.raised, in: RoundedRectangle(cornerRadius: 28))
                    .overlay(alignment: .topTrailing) { if let reaction = message.reaction { Text(reaction).padding(6).background(ChatDesign.raised, in: Capsule()).offset(x: 4, y: -8) } }
                    .accessibilityIdentifier("dot.message.\(message.id)")
                    .onTapGesture { if message.linkLabel != nil && selectedMessage == nil && selectedTextID != message.id { state.onAction(.openLink(message.id)) } }
                if message.isUser, let receipt = message.receipt {
                    Text(receipt.label).font(.system(size: 10)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 4).accessibilityIdentifier("dot.receipt.\(message.id)")
                }
            }.frame(maxWidth: message.isCallSummary ? 220 : 310, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer(minLength: 36) }
        }
    }
    private var composer: some View {
        HStack(spacing: 14) {
            Button { showsAttachments.toggle() } label: { Image(systemName: "plus").font(.system(size: 25)).frame(width: 22, height: 32) }.accessibilityLabel("Dot attachments")
            TextField("Message", text: $state.draft, axis: .vertical).font(.system(size: 17)).lineLimit(1...6).focused($composerFocused).accessibilityIdentifier("dot.composer").onChange(of: composerFocused) { _, focused in if focused { selectedTextID = nil } }
            if state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button { state.onAction(.dictation); notice = "Dot dictation has not yet been captured." } label: { Image(systemName: "mic").font(.system(size: 22)) }.accessibilityLabel("Dot dictation")
            } else {
                Button { _ = state.send() } label: { Image(systemName: "arrow.up").font(.system(size: 21, weight: .semibold)).foregroundStyle(.white).frame(width: 34, height: 34).background(Color(red: 0.38, green: 0.55, blue: 0.75), in: Circle()) }.accessibilityLabel("Send dot message")
            }
        }.padding(.horizontal, 14).padding(.vertical, 7).glassEffect(.regular.interactive(), in: Capsule())
    }
    private var attachmentMenu: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear.contentShape(Rectangle()).onTapGesture { showsAttachments = false }
            VStack(spacing: 0) {
                ForEach(Array(zip(["Camera", "Photos", "Files"], ["camera", "photo", "paperclip"])), id: \.0) { title, symbol in
                    Button { showsAttachments = false; attachment(title) } label: { HStack(spacing: 16) { Image(systemName: symbol).font(.system(size: 22)).frame(width: 44, height: 44).background(.white.opacity(0.1), in: Circle()); Text(title).font(.system(size: 20)); Spacer() }.padding(.horizontal, 22).frame(height: 68).contentShape(Rectangle()) }
                }
            }.padding(.vertical, 10).frame(width: 278).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 40)).padding(.leading, 24).padding(.bottom, 0)
        }.accessibilityAddTraits(.isModal)
    }
    private func messageMenu(_ message: DotMessage) -> some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea().onTapGesture { selectedMessage = nil }
            VStack(alignment: .leading, spacing: 14) {
                if message.supportsReactions { HStack(spacing: 13) {
                    ForEach(["❤️", "👍", "👎", "‼️", "😂", "✅"], id: \.self) { value in Button { state.react(value, to: message.id); selectedMessage = nil } label: { Text(value).font(.system(size: 24)) }.accessibilityLabel("React \(value)") }
                    Button { state.onAction(.moreReactions(message.id)); selectedMessage = nil; notice = "The expanded reaction picker has not yet been captured." } label: { Image(systemName: "face.smiling").font(.system(size: 24)) }.accessibilityLabel("More reactions")
                }.padding(12).glassEffect(.regular, in: Capsule()) }
                bubble(message)
                VStack(spacing: 0) {
                    contextRow("Copy", symbol: "document.on.document") { copy(message); selectedMessage = nil }
                    if !message.isCallSummary {
                        contextRow("Select text", symbol: "text.page") { selectedTextID = message.id; selectedMessage = nil }
                    }
                    contextRow("Reply", symbol: "arrow.turn.down.right") { state.beginReply(message.id); selectedMessage = nil; composerFocused = true }
                }.padding(.vertical, 8).frame(width: 250).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34))
            }.padding(.horizontal, 16)
        }.accessibilityAddTraits(.isModal)
    }
    private func contextRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View { Button(action: action) { Label(title, systemImage: symbol).font(.system(size: 17)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).frame(height: 43).contentShape(Rectangle()) } }
    private func copy(_ message: DotMessage) { state.copy(message.id); UIPasteboard.general.string = message.displayText }
    private func attachment(_ title: String) { state.onAction(.attach(title)); notice = "Dot \(title) destination has not yet been captured. Attachment selection belongs to the host app." }
}
struct DotAvatar: View {
    var body: some View {
        GeometryReader { geometry in
            let lineWidth = min(geometry.size.width, geometry.size.height) * 17 / 58
            Circle().stroke(Color(red: 0.72, green: 0.74, blue: 0.81), lineWidth: lineWidth).padding(lineWidth / 2)
        }
    }
}
#endif
