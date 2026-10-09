#if os(iOS)
    import SwiftUI

    /// A backend-independent, interactive interface study. Supply `ChatState.onAction` to integrate a host.
    public struct ChatGPTView: View {
        @Environment(\.colorScheme) private var colorScheme
        @Bindable private var state: ChatState
        @State private var composerFocused = false
        @State private var searchPresented = false
        @State private var attachmentPicker: String?
        @State private var localNotice: String?
        @State private var feedbackMessage: ChatMessage?
        @State private var toast: String?
        @State private var expandedComposer = false
        @State private var selectedText: ChatMessage?
        @State private var showsTemporarySettings = false
        @State private var showsWorkModels = false
        @Namespace private var tabNamespace
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        private let imagesArtwork: (ImageTemplate) -> AnyView?
        private let cameraPreview: AnyView
        private let spaceImageProvider: (SpaceItem) -> Image?
        private let mediaImageProvider: (ChatMedia) -> Image?
        private let mediaVideoProvider: (ChatMedia) -> AnyView?
        public init(
            state: ChatState, spaceImageProvider: @escaping (SpaceItem) -> Image? = { _ in nil },
            mediaImageProvider: @escaping (ChatMedia) -> Image? = { _ in nil },
            mediaVideoProvider: @escaping (ChatMedia) -> AnyView? = { _ in nil },
            imagesArtwork: @escaping (ImageTemplate) -> AnyView? = { _ in nil }
        ) {
            self.state = state
            self.imagesArtwork = imagesArtwork
            self.spaceImageProvider = spaceImageProvider
            self.mediaImageProvider = mediaImageProvider
            self.mediaVideoProvider = mediaVideoProvider
            cameraPreview = AnyView(SyntheticCameraPreview())
        }
        public init<CameraPreview: View>(
            state: ChatState, spaceImageProvider: @escaping (SpaceItem) -> Image? = { _ in nil },
            mediaImageProvider: @escaping (ChatMedia) -> Image? = { _ in nil },
            mediaVideoProvider: @escaping (ChatMedia) -> AnyView? = { _ in nil },
            imagesArtwork: @escaping (ImageTemplate) -> AnyView? = { _ in nil },
            @ViewBuilder cameraPreview: () -> CameraPreview
        ) {
            self.state = state
            self.imagesArtwork = imagesArtwork
            self.spaceImageProvider = spaceImageProvider
            self.mediaImageProvider = mediaImageProvider
            self.mediaVideoProvider = mediaVideoProvider
            self.cameraPreview = AnyView(cameraPreview())
        }
        public var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    ChatDesign.canvas.ignoresSafeArea()
                    if state.showsDrawer { drawer.frame(width: min(310, geometry.size.width - 72)) }
                    mainContent
                        .frame(width: geometry.size.width)
                        .background(ChatDesign.canvas)
                        .mask {
                            RoundedRectangle(cornerRadius: state.showsDrawer ? 54 : 0)
                                .ignoresSafeArea(.container, edges: state.showsDrawer ? [] : .all)
                        }
                        .overlay {
                            if state.showsDrawer {
                                Color.white.opacity(0.08).onTapGesture { state.showsDrawer = false }
                            }
                        }
                        .offset(x: state.showsDrawer ? min(310, geometry.size.width - 72) : 0)
                }.animation(.spring(response: 0.38, dampingFraction: 0.86), value: state.showsDrawer)
                    .overlay(alignment: .bottom) {
                        if state.photoPicker.isPresented {
                            RecentPhotosPanel(
                                state: state.photoPicker, imageProvider: mediaImageProvider,
                                onChoose: { items in items.forEach { state.addMedia($0) } },
                                onAllPhotos: { state.onAction(.requestPhotoLibrary) }
                            )
                            .frame(height: min(492, geometry.size.height - 80)).padding(.horizontal, 12)
                            .padding(.bottom, 12 - geometry.safeAreaInsets.bottom)
                        } else if state.camera.isPresented {
                            CameraPanel(
                                state: state.camera, onAction: { state.onAction(.camera($0)) },
                                onAttach: { state.addAttachment($0) }
                            ) { cameraPreview }
                            .frame(height: min(492, geometry.size.height - 80)).padding(.horizontal, 12)
                            .padding(.bottom, 12 - geometry.safeAreaInsets.bottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }.animation(reduceMotion ? nil : .default, value: state.camera.isPresented)
            }
            .foregroundStyle(.primary).tint(state.accentColor).preferredColorScheme(
                state.appearance == "System" ? nil : state.appearance == "Light" ? .light : .dark
            )
            .sheet(item: $feedbackMessage) { message in
                FeedbackView { issue, details in
                    state.onAction(.submitFeedback(message.id, issue: issue, details: details))
                    feedbackMessage = nil
                    showToast("Thank you for your feedback!")
                }.presentationDetents([.large]).presentationDragIndicator(.hidden)
            }
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast).font(.system(size: 15, weight: .medium)).padding(.horizontal, 20).padding(.vertical, 15)
                        .glassEffect(.regular, in: Capsule()).padding(.top, 54).transition(.opacity)
                }
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { state.mediaViewer.item != nil }, set: { if !$0 { state.mediaViewer.dismiss() } })
            ) {
                MediaViewer(
                    state: state.mediaViewer, imageProvider: mediaImageProvider, videoProvider: mediaVideoProvider)
            }
            .fullScreenCover(isPresented: $searchPresented) {
                SearchDestinationView(state: state) { searchPresented = false }
            }
            .sheet(isPresented: $showsTemporarySettings) {
                temporarySettings.presentationDetents([.height(365)]).presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showsWorkModels) {
                workModels.presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedText) { message in
                NavigationStack {
                    ScrollView { Text(message.text).textSelection(.enabled).padding() }.navigationTitle("Select text")
                        .toolbar { Button("Done") { selectedText = nil } }
                }
            }
            .fullScreenCover(isPresented: $expandedComposer) {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            expandedComposer = false
                        } label: {
                            GlassCircle(symbol: "arrow.down.right.and.arrow.up.left")
                        }.accessibilityLabel("Collapse composer")
                    }.padding()
                    TextEditor(text: $state.draft).font(.system(size: 17)).scrollContentBackground(.hidden).padding(
                        .horizontal, 16)
                    HStack {
                        Spacer()
                        Button {
                            expandedComposer = false
                            state.send()
                        } label: {
                            Image(systemName: "arrow.up").font(.system(size: 22, weight: .semibold)).foregroundStyle(
                                .white
                            ).frame(width: 40, height: 40).background(state.accentColor, in: Circle())
                        }.disabled(!state.canSend).accessibilityLabel("Send expanded message")
                    }.padding(20)
                }.background(ChatDesign.canvas)
            }
            .fullScreenCover(isPresented: Binding(get: { state.showsVoice }, set: { state.setVoice($0) })) {
                VoicePresentationView(state: state, cameraPreview: cameraPreview)
            }
            .sheet(
                item: Binding(get: { attachmentPicker.map(AttachmentRoute.init) }, set: { attachmentPicker = $0?.id })
            ) { route in
                NavigationStack {
                    VStack(spacing: 24) {
                        Image(systemName: route.id == "Files" ? "doc" : "photo").font(.system(size: 54))
                            .foregroundStyle(.secondary)
                        Text("Choose a sample attachment").font(.title3.bold())
                        Text("This offline demo does not access your camera, photos, or files.").foregroundStyle(
                            .secondary
                        ).multilineTextAlignment(.center)
                        Button("Add sample \(route.id == "Files" ? "document" : "photo")") {
                            state.addAttachment(route.id == "Files" ? "Notes.pdf" : "Photo.jpg")
                            attachmentPicker = nil
                        }.buttonStyle(.borderedProminent)
                        Spacer()
                    }.padding(28).padding(.top, 30).navigationTitle(route.id).navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { attachmentPicker = nil } }
                        }
                }.presentationDetents([.medium, .large]).preferredColorScheme(.dark)
            }
            .alert("UI demo", isPresented: Binding(get: { localNotice != nil }, set: { if !$0 { localNotice = nil } }))
            {
                Button("OK") { localNotice = nil }
            } message: {
                Text(localNotice ?? "")
            }
        }
        private var mainContent: some View {
            VStack(spacing: 0) {
                if [.chat, .work].contains(state.page) {
                    if state.editingMessageID != nil {
                        HStack {
                            Button {
                                state.cancelEditing()
                                composerFocused = false
                            } label: {
                                GlassCircle(symbol: "xmark")
                            }.accessibilityLabel("Cancel editing")
                            Spacer()
                            Text("Edit message").font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Color.clear.frame(width: 44, height: 44)
                        }.padding(.horizontal, 16).padding(.top, 2)
                    } else {
                        topBar.padding(.horizontal, 16).padding(.top, 2)
                    }
                    if state.speakingMessage != nil { readAloudPlayer.padding(.horizontal, 10).padding(.top, 16) }
                    if state.editingMessageID != nil {
                        Spacer()
                    } else if state.messages.isEmpty {
                        home.frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        conversation
                    }
                    Group {
                        if state.composerMode == .dictating {
                            dictationComposer.padding(.horizontal, 34)
                        } else if compactComposer {
                            compactComposerView.padding(.horizontal, 34)
                        } else {
                            composer.padding(.horizontal, 12)
                        }
                    }.padding(.bottom, 0)
                } else if state.page == .about {
                    AboutSettingsView(state: state.settings, onBack: { state.goBack() })
                } else if state.page == .workTask {
                    WorkTaskView(state: state.workTask, onBack: { state.open(.images) })
                } else if state.page == .images {
                    ImagesDestinationView(
                        state: state.images, onSidebar: { state.showsDrawer = true }, artwork: imagesArtwork,
                        composer: AnyView(imagesComposer))
                } else if state.page == .projects {
                    ProjectsDestinationView(state: state.projects, onSidebar: { state.showsDrawer = true })
                } else if state.page == .sites {
                    SitesDestinationView(
                        state: state.explore, onSidebar: { state.showsDrawer = true },
                        onCreate: { state.createSiteDraft() })
                } else if state.page == .health {
                    HealthWorkspaceView(state: state.health, onBack: { state.showsDrawer = true })
                } else if state.page == .finances {
                    FinanceWorkspaceView(state: state.finance, onBack: { state.showsDrawer = true })
                } else if state.page == .codex {
                    CodexDestinationView(
                        state: state.codex, onBack: { state.showsDrawer = true },
                        onOpenProfile: { state.open(.settings) }, onOpenGeneral: { state.open(.general) })
                } else if state.page == .dot {
                    DotDestinationView(state: state.dot, onBack: { state.showsDrawer = true })
                } else if state.page == .space {
                    SpaceView(
                        state: state.space, onBack: { state.showsDrawer = true }, imageProvider: spaceImageProvider)
                } else if state.page == .scheduled {
                    ScheduledDestinationView(state: state)
                } else if state.page == .memory {
                    MemoryDestinationView(state: state)
                } else if state.page == .plugins {
                    PluginsDestinationView(state: state)
                } else {
                    SettingsScreens(state: state, notice: $localNotice)
                }
            }.background(ChatDesign.canvas)
                .overlay(alignment: .bottomLeading) {
                    if state.showsAttachmentMenu {
                        ZStack(alignment: .bottomLeading) {
                            Color.clear.contentShape(Rectangle()).onTapGesture { state.showsAttachmentMenu = false }
                            attachmentPopover.padding(.leading, 6)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity))
                    }
                }
        }
        private var imagesComposer: some View {
            Group {
                if state.draft.isEmpty && state.composerContext == nil {
                    HStack(spacing: 10) {
                        imagesAttachment
                        TextField("Describe an image", text: $state.draft).font(.system(size: 17))
                            .accessibilityIdentifier("images.composer")
                        imagesDictation
                        imagesSubmit
                    }.padding(.horizontal, 12).frame(height: 48).glassEffect(.regular, in: Capsule()).padding(
                        .horizontal, 22)
                } else {
                    VStack(spacing: 15) {
                        HStack(spacing: 5) {
                            if let context = state.composerContext {
                                Label(context.title, systemImage: context.symbol).foregroundStyle(
                                    Color(red: 0.76, green: 0.77, blue: 1)
                                ).fixedSize()
                            }
                            TextField("Describe an image", text: $state.draft, axis: .vertical).lineLimit(1...4)
                                .accessibilityIdentifier("images.composer")
                        }.font(.system(size: 17))
                        HStack {
                            imagesAttachment
                            Spacer()
                            imagesDictation
                            imagesSubmit
                        }
                    }.padding(16).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
                }
            }.buttonStyle(.plain)
        }
        private var imagesAttachment: some View {
            Button {
                state.images.onAction(.requestAttachment)
            } label: {
                Image(systemName: "paperclip").font(.system(size: 23)).frame(width: 28, height: 32)
            }.accessibilityLabel("Image attachments")
        }
        private var imagesDictation: some View {
            Button {
                state.images.onAction(.requestDictation)
            } label: {
                Image(systemName: "mic").font(.system(size: 22)).frame(width: 32, height: 32)
            }.accessibilityLabel("Dictate image prompt")
        }
        private var imagesSubmit: some View {
            Button {
                state.images.submitPrompt(state.draft, context: state.composerContext)
            } label: {
                Image(systemName: "arrow.up").font(.system(size: 22, weight: .semibold)).foregroundStyle(.white).frame(
                    width: 32, height: 32
                ).background(
                    state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray : state.accentColor, in: Circle())
            }.disabled(state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityLabel(
                "Send image prompt")
        }
        private var topBar: some View {
            HStack {
                Button {
                    composerFocused = false
                    state.showsDrawer.toggle()
                } label: {
                    DrawerGlyph()
                }.accessibilityLabel("Open sidebar").accessibilityIdentifier("sidebarButton")
                Spacer()
                if state.messages.isEmpty {
                    if !state.temporaryChat {
                        HStack(spacing: 0) {
                            ForEach([ChatPage.chat, .work], id: \.self) { tab in
                                Button {
                                    withAnimation(reduceMotion ? nil : .default) { state.page = tab }
                                } label: {
                                    Text(tab.rawValue).font(.system(size: 15, weight: .medium)).frame(
                                        width: 72, height: 39
                                    )
                                    .background {
                                        if state.page == tab {
                                            Capsule().fill(
                                                colorScheme == .dark
                                                    ? ChatDesign.canvas.opacity(0.8) : Color.black.opacity(0.06)
                                            ).matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
                                        }
                                    }
                                }.accessibilityAddTraits(state.page == tab ? .isSelected : [])
                            }
                        }.padding(4).glassEffect(.regular, in: Capsule())
                    }
                    Spacer()
                    if state.page == .chat {
                        Button {
                            state.temporaryChat.toggle()
                        } label: {
                            TemporaryChatGlyph().stroke(
                                style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 23, height: 23)
                            .overlay {
                                if state.temporaryChat {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                }
                            }
                            .frame(width: 44, height: 44)
                            .foregroundStyle(state.temporaryChat ? state.accentColor : .primary)
                            .glassEffect(.regular.interactive(), in: .circle)
                        }.accessibilityLabel("Temporary chat").accessibilityValue(state.temporaryChat ? "On" : "Off")
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                } else {
                    HStack(spacing: 20) {
                        Button {
                            state.newChat()
                        } label: {
                            Image(systemName: "square.and.pencil").font(.system(size: 23)).frame(width: 32, height: 44)
                        }.accessibilityLabel("New chat")
                        Menu {
                            Button("Rename", systemImage: "pencil") {
                                localNotice = "Conversation naming is supplied by your host."
                            }
                            Button("Share", systemImage: "square.and.arrow.up") {
                                localNotice = "Sharing is supplied by your host."
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) { state.newChat() }
                        } label: {
                            Image(systemName: "ellipsis").font(.system(size: 22, weight: .bold)).frame(
                                width: 32, height: 44)
                        }.accessibilityLabel("Conversation options")
                    }.padding(.horizontal, 12).glassEffect(.regular.interactive(), in: Capsule())
                }
            }.buttonStyle(.plain)
        }
        private var home: some View {
            VStack(spacing: 0) {
                Spacer()
                if state.camera.isPresented {
                    Color.clear.frame(height: 1)
                } else if state.temporaryChat {
                    Text("Temporary chat").font(.system(size: 17, weight: .semibold)).foregroundStyle(.secondary)
                    Text("This chat won’t appear in history. Learn more").font(.system(size: 15)).foregroundStyle(
                        .secondary
                    ).padding(.top, 8)
                    Button {
                        showsTemporarySettings = true
                    } label: {
                        HStack {
                            Text(state.temporaryPersonalized ? "Personalized" : "Unpersonalized")
                            Image(systemName: "chevron.down").font(.system(size: 11))
                        }.font(.system(size: 15)).foregroundStyle(.secondary)
                    }.padding(.top, 18)
                } else if state.page == .work && state.draft.isEmpty && state.composerContext == nil {
                    Spacer()
                    VStack(alignment: .leading, spacing: 23) {
                        Label("Explore an idea", systemImage: "sparkles")
                        Button {
                            state.open(.plugins)
                        } label: {
                            Label("Files · Connect", systemImage: "doc")
                        }
                        Button {
                            state.open(.plugins)
                        } label: {
                            Label("Calendar · Connect", systemImage: "calendar")
                        }
                    }.font(.system(size: 17)).foregroundStyle(.secondary).frame(
                        maxWidth: .infinity, alignment: .leading
                    ).padding(.bottom, 20)
                } else if state.draft.isEmpty && state.showsVoiceAnnouncement {
                    VoiceOrb().padding(.bottom, 20)
                    Text("Meet the new Voice").font(.system(size: 17, weight: .semibold)).padding(.bottom, 4)
                    Text("More natural conversations, powered by our\nnext-generation voice model")
                        .font(.system(size: 15)).foregroundStyle(Color(white: 0.75)).multilineTextAlignment(.center)
                        .lineSpacing(3)
                    Button {
                        state.showsVoiceAnnouncement = false
                        state.setVoice(true)
                    } label: {
                        Text("Start Voice").font(.system(size: 17, weight: .semibold)).padding(.horizontal, 17).frame(
                            height: 44
                        )
                        .glassEffect(.regular.interactive(), in: Capsule())
                    }.padding(.top, 20).accessibilityIdentifier("startVoiceButton")
                }
                if state.page != .work { Spacer() }
            }.padding(.horizontal, 18)
        }
        @ViewBuilder private func sentMedia(_ item: ChatMedia) -> some View {
            let height = min(260.0, max(80.0, 185.0 / item.aspectRatio))
            if item.kind == .video {
                let presentation = state.videoCardPresentation(for: item)
                Button {
                    state.openMedia(item)
                } label: {
                    Group {
                        if presentation == .hostPreview, let preview = mediaVideoProvider(item) {
                            preview
                        } else {
                            ChatMediaThumbnail(item: item, provider: mediaImageProvider, showsDuration: false)
                        }
                    }.frame(width: 120, height: min(240, 120 / item.aspectRatio)).clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay {
                        if presentation.showsPlayAffordance {
                            Image(systemName: "play.circle").font(.system(size: 40, weight: .regular)).foregroundStyle(
                                .white
                            ).accessibilityHidden(true)
                        }
                    }
                }.buttonStyle(.plain).frame(width: 120, height: min(240, 120 / item.aspectRatio)).clipped()
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton).accessibilityIdentifier(
                        "message.media.\(item.id)"
                    )
                    .accessibilityLabel("\(presentation.showsPlayAffordance ? "Play" : "Open") video \(item.title)")
            } else {
                Button {
                    state.openMedia(item)
                } label: {
                    ChatMediaThumbnail(item: item, provider: mediaImageProvider).frame(width: 185, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }.buttonStyle(.plain).accessibilityIdentifier("message.media.\(item.id)")
                    .contextMenu {
                        Button {
                            state.onAction(.media(.copy(item.id)))
                        } label: {
                            Label {
                                Text("Copy")
                            } icon: {
                                ChatCopySymbol.image
                            }
                        }.tint(.primary)
                    } preview: {
                        ChatMediaThumbnail(item: item, provider: mediaImageProvider).frame(
                            width: 211, height: height * 211 / 185
                        ).clipShape(RoundedRectangle(cornerRadius: 24))
                    }
            }
        }
        private var conversation: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        ForEach(state.messages) { message in
                            if message.role == .user {
                                HStack {
                                    Spacer(minLength: 38)
                                    VStack(alignment: .trailing, spacing: 8) {
                                        ForEach(message.media) { item in sentMedia(item) }
                                        ForEach(message.attachments, id: \.self) {
                                            Text($0).font(.footnote).padding(12).background(
                                                ChatDesign.surface, in: RoundedRectangle(cornerRadius: 12))
                                        }
                                        if !message.text.isEmpty {
                                            Text(message.text).font(.system(size: 17)).padding(.horizontal, 16).padding(
                                                .vertical, 11
                                            ).foregroundStyle(colorScheme == .dark ? .white : state.accentColor)
                                                .background(
                                                    colorScheme == .dark
                                                        ? Color(red: 4.0 / 255, green: 5.0 / 255, blue: 95.0 / 255)
                                                        : state.accentColor.opacity(0.08),
                                                    in: RoundedRectangle(cornerRadius: 22)
                                                ).contextMenu {
                                                    Section("Today") {
                                                        Button {
                                                            copy(message)
                                                        } label: {
                                                            Label {
                                                                Text("Copy")
                                                            } icon: {
                                                                ChatCopySymbol.image
                                                            }
                                                        }.tint(.primary)
                                                        Button("Edit", systemImage: "pencil") {
                                                            state.beginEditing(message)
                                                        }
                                                        Button("Select text", systemImage: "text.cursor") {
                                                            selectedText = message
                                                        }
                                                        Button("Share prompt", systemImage: "square.and.arrow.up") {
                                                            state.onAction(.share(message.id))
                                                            localNotice = "Sharing is supplied by your host app."
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 18) {
                                    if message.text.isEmpty {
                                        Circle().frame(width: 11, height: 11).padding(.top, 8).accessibilityLabel(
                                            "Thinking")
                                    } else {
                                        ChatGPTMarkdownView(message.text) { state.onAction(.markdown($0)) }
                                    }
                                    if state.responseID != message.id, !message.text.isEmpty {
                                        HStack(spacing: 18) {
                                            messageAction(
                                                state.copiedMessage == message.id ? "checkmark" : "square.on.square",
                                                label: "Copy response"
                                            ) { copy(message) }
                                            if state.feedback[message.id] != .negative {
                                                messageAction(
                                                    state.feedback[message.id] == .positive
                                                        ? "hand.thumbsup.fill" : "hand.thumbsup", label: "Good response"
                                                ) { rate(.positive, message: message) }
                                                .background(
                                                    state.feedback[message.id] == .positive
                                                        ? ChatDesign.raised : .clear,
                                                    in: RoundedRectangle(cornerRadius: 5))
                                            }
                                            if state.feedback[message.id] != .positive {
                                                messageAction(
                                                    state.feedback[message.id] == .negative
                                                        ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                                                    label: "Bad response"
                                                ) { rate(.negative, message: message) }
                                                .background(
                                                    state.feedback[message.id] == .negative
                                                        ? ChatDesign.raised : .clear,
                                                    in: RoundedRectangle(cornerRadius: 5))
                                            }
                                            messageAction("square.and.arrow.up", label: "Share response") {
                                                state.onAction(.share(message.id))
                                                localNotice = "Sharing is supplied by the host app."
                                            }
                                            Menu {
                                                responseMoreMenu(message)
                                            } label: {
                                                Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(.secondary)
                                            }.menuOrder(.fixed).accessibilityLabel("More response actions")
                                        }
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Color.clear.frame(height: 2).id("bottom")
                    }.padding(.horizontal, 16).padding(.top, 22).padding(.bottom, 20)
                }.scrollDismissesKeyboard(.interactively)
                    .onChange(of: state.messages.last?.text) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                    .onChange(of: state.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
            }
        }
        private var compactComposer: Bool {
            !state.messages.isEmpty && !composerFocused && state.editingMessageID == nil
                && state.composerMode != .dictating && state.attachments.isEmpty && state.media.isEmpty
                && state.draft.isEmpty
        }
        private var dictationComposer: some View {
            HStack(spacing: 12) {
                Button {
                    state.finishDictation()
                } label: {
                    Image(systemName: "xmark").font(.system(size: 20)).frame(width: 32, height: 32).background(
                        .primary.opacity(0.1), in: Circle())
                }.accessibilityLabel("Cancel dictation")
                DictationWaveform(levels: state.dictationLevels).frame(maxWidth: .infinity).frame(height: 28)
                Button {
                    state.finishDictation()
                } label: {
                    Image(systemName: "stop.fill").font(.system(size: 14)).frame(width: 32, height: 32).background(
                        .primary.opacity(0.1), in: Circle())
                }.accessibilityLabel("Stop dictation")
                Button {
                    state.finishDictation()
                    if state.canSend { state.send() }
                } label: {
                    Image(systemName: "arrow.up").font(.system(size: 21, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 32, height: 32).background(state.accentColor, in: Circle())
                }.accessibilityLabel("Send dictation")
            }.padding(8).glassEffect(.regular, in: Capsule()).buttonStyle(.plain)
        }
        private var compactComposerView: some View {
            HStack(spacing: 10) {
                attachmentMenu
                Button {
                    composerFocused = true
                } label: {
                    Text(
                        state.temporaryChat
                            ? "Temporary chat" : state.page == .work ? "Work with ChatGPT" : "Ask ChatGPT"
                    ).font(.system(size: 17)).foregroundStyle(ChatDesign.secondary).frame(
                        maxWidth: .infinity, alignment: .leading)
                }.accessibilityLabel("Message").accessibilityIdentifier("focusComposer")
                Button {
                    composerFocused = false
                    state.beginDictation()
                } label: {
                    Image(systemName: "mic").font(.system(size: 21)).frame(width: 27, height: 32)
                }.accessibilityLabel("Dictate").disabled(state.composerMode == .responding)
                Button {
                    if state.composerMode == .responding {
                        state.stop()
                    } else if state.canSend {
                        composerFocused = false
                        state.send()
                    } else {
                        state.setVoice(true)
                    }
                } label: {
                    Group {
                        if state.composerMode == .responding {
                            Image(systemName: "stop.fill").font(.system(size: 14))
                        } else if state.canSend || state.temporaryChat {
                            Image(systemName: "arrow.up").font(.system(size: 20, weight: .semibold))
                        } else {
                            VoiceBars()
                        }
                    }.frame(width: 32, height: 32).foregroundStyle(.white).background(state.accentColor, in: Circle())
                }.accessibilityLabel(
                    state.composerMode == .responding
                        ? "Stop response" : (state.canSend || state.temporaryChat) ? "Send message" : "Start voice"
                ).accessibilityIdentifier("composerPrimaryButton")
            }.padding(8).glassEffect(.regular, in: Capsule()).buttonStyle(.plain)
        }
        private var composer: some View {
            VStack(alignment: .leading, spacing: 8) {
                if !state.media.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(state.media) { item in
                                ChatMediaThumbnail(item: item, provider: mediaImageProvider).frame(
                                    width: 120, height: 120
                                ).clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            state.removeMedia(item.id)
                                        } label: {
                                            Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(.white).frame(width: 24, height: 24).background(
                                                    .black.opacity(0.45), in: Circle())
                                        }.padding(7).accessibilityLabel(
                                            "Remove \(item.kind == .video ? "video" : "image") \(item.title)")
                                    }.accessibilityIdentifier("composer.media.\(item.id)").accessibilityValue(
                                        item.durationLabel ?? "")
                            }
                        }
                    }.scrollIndicators(.hidden).padding(.bottom, 14)
                }
                if !state.attachments.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(state.attachments.enumerated()), id: \.offset) { index, file in
                                HStack {
                                    Image(systemName: "doc")
                                    Text(file)
                                    Button {
                                        state.attachments.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }.accessibilityLabel("Remove \(file)")
                                }
                                .font(.footnote).padding(10).background(
                                    .white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }.scrollIndicators(.hidden)
                }
                if state.composerMode == .dictating {
                    DictationWaveform(levels: state.dictationLevels).frame(height: 34).accessibilityLabel(
                        "Dictation waveform demo")
                } else {
                    HStack(alignment: .top, spacing: 3) {
                        if let context = state.composerContext {
                            Label(context.title, systemImage: context.symbol).font(.system(size: 17)).foregroundStyle(
                                Color(red: 0.81, green: 0.82, blue: 1)
                            ).fixedSize().padding(.top, 2).accessibilityIdentifier("composer.context")
                        }
                        ComposerTextView(
                            text: $state.draft,
                            focused: Binding(get: { composerFocused }, set: { composerFocused = $0 }),
                            autocorrect: state.autoCorrect, tint: state.accentColor
                        )
                        .overlay(alignment: .topLeading) {
                            if state.draft.isEmpty {
                                Text(
                                    state.temporaryChat
                                        ? "Temporary chat" : state.page == .work ? "Work with ChatGPT" : "Ask ChatGPT"
                                ).font(.system(size: 17)).foregroundStyle(ChatDesign.secondary).allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 5).padding(.top, 2)
                        .padding(.trailing, state.draft.count > 180 ? 26 : 0)
                        .overlay(alignment: .topTrailing) {
                            if state.draft.count > 180 {
                                Button {
                                    expandedComposer = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 17))
                                        .padding(4)
                                }.accessibilityLabel("Expand composer")
                            }
                        }
                    }
                }
                HStack {
                    if state.composerMode == .dictating {
                        Button {
                            state.finishDictation()
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 22)).frame(width: 32, height: 32)
                        }.accessibilityLabel("Cancel dictation")
                        Spacer()
                        Text("Listening…").font(.system(size: 14)).foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            state.finishDictation(transcript: "This is a sample voice message.")
                        } label: {
                            Image(systemName: "checkmark").font(.system(size: 19, weight: .semibold)).frame(
                                width: 32, height: 32
                            ).background(state.accentColor, in: Circle())
                        }.accessibilityLabel("Finish dictation")
                    } else {
                        attachmentMenu
                        Spacer()
                        if state.page == .work {
                            Button {
                                showsWorkModels = true
                            } label: {
                                HStack(spacing: 2) {
                                    Text(state.workModel).fontWeight(.medium)
                                    Text(state.workEffort).foregroundStyle(.secondary)
                                }.font(.system(size: 15))
                            }
                        } else if state.thinkHarder {
                            Button {
                                state.thinkHarder = false
                            } label: {
                                ThinkingGauge(color: state.accentColor).frame(width: 25, height: 25).frame(
                                    width: 32, height: 32)
                            }.accessibilityLabel("Think harder enabled")
                        }
                        Button {
                            composerFocused = false
                            state.beginDictation()
                        } label: {
                            Image(systemName: "mic").font(.system(size: 23)).frame(width: 32, height: 32)
                        }.disabled(state.composerMode == .responding).padding(.leading, 10).accessibilityLabel(
                            "Dictate")
                        Button {
                            if state.composerMode == .responding {
                                state.stop()
                            } else if state.canSend {
                                composerFocused = false
                                state.send()
                            } else {
                                composerFocused = false
                                state.setVoice(true)
                            }
                        } label: {
                            Group {
                                if state.composerMode == .responding {
                                    Image(systemName: "stop.fill").font(.system(size: 14))
                                } else if state.canSend || state.temporaryChat {
                                    Image(systemName: "arrow.up").font(.system(size: 20, weight: .semibold))
                                } else {
                                    VoiceBars()
                                }
                            }.frame(width: 32, height: 32).foregroundStyle(.white).background(
                                state.temporaryChat && !state.canSend ? Color.gray : state.accentColor, in: Circle())
                        }.disabled(state.temporaryChat && !state.canSend && state.composerMode != .responding).padding(
                            .leading, 10
                        ).accessibilityLabel(
                            state.composerMode == .responding
                                ? "Stop response"
                                : (state.canSend || state.temporaryChat) ? "Send message" : "Start voice"
                        ).accessibilityIdentifier("composerPrimaryButton")
                    }
                }
            }.padding(12).frame(minHeight: 92).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
                .overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.10), lineWidth: 1) }
                .buttonStyle(.plain)
        }
        private var attachmentMenu: some View {
            Button {
                withAnimation(.snappy(duration: 0.22)) { state.showsAttachmentMenu.toggle() }
            } label: {
                Image(systemName: "plus").font(.system(size: 26, weight: .regular)).frame(width: 32, height: 32)
            }.accessibilityLabel("Add attachments and tools").accessibilityIdentifier("attachmentMenu")
        }
        private var attachmentPopover: some View {
            VStack(spacing: 0) {
                attachmentRow("Camera", symbol: "camera") {
                    composerFocused = false
                    state.showsAttachmentMenu = false
                    state.camera.open()
                    state.onAction(.camera(.open))
                }
                attachmentRow("Photos", symbol: "photo") {
                    composerFocused = false
                    state.photoPicker.isPresented = true
                    state.camera.close()
                    state.showsAttachmentMenu = false
                }
                attachmentRow("Files", symbol: "paperclip") {
                    attachmentPicker = "Files"
                    state.showsAttachmentMenu = false
                }
                attachmentRow("Plugins", symbol: "puzzlepiece.extension") { state.open(.plugins) }
                Button {
                    state.thinkHarder.toggle()
                    state.showsAttachmentMenu = false
                } label: {
                    HStack(spacing: 16) {
                        ThinkingGauge(color: state.accentColor).frame(width: 25, height: 25).frame(
                            width: 44, height: 44
                        ).background(.primary.opacity(0.07), in: Circle())
                        Text("Think harder").font(.system(size: 20))
                        Spacer()
                        if state.thinkHarder { Image(systemName: "checkmark").font(.system(size: 18)) }
                    }.foregroundStyle(state.thinkHarder ? state.accentColor : .primary).padding(.horizontal, 22).frame(
                        height: 68)
                }
            }.padding(.vertical, 10).frame(width: 280).background(
                ChatDesign.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 48)
            ).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 48)).buttonStyle(.plain)
        }
        private func attachmentRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: symbol).font(.system(size: 22)).frame(width: 44, height: 44).background(
                        .primary.opacity(0.07), in: Circle())
                    Text(title).font(.system(size: 20))
                    Spacer()
                }.padding(.horizontal, 22).frame(height: 68)
            }
        }
        private var readAloudPlayer: some View {
            HStack(spacing: 17) {
                Button {
                    state.togglePlayback()
                } label: {
                    Image(systemName: state.readAloudPlaying ? "pause" : "arrow.counterclockwise").font(
                        .system(size: 22))
                }.accessibilityLabel(state.readAloudPlaying ? "Pause reading" : "Replay reading")
                Text(String(format: "%02d:%02d", Int(state.readAloudElapsed) / 60, Int(state.readAloudElapsed) % 60))
                    .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                Spacer(minLength: 0)
                Button {
                    state.readAloudSpeed = state.readAloudSpeed == 2 ? 1 : state.readAloudSpeed + 0.5
                } label: {
                    Text("\(state.readAloudSpeed.formatted())x").font(.system(size: 19))
                }.accessibilityLabel("Playback speed")
                Button {
                    state.readAloudElapsed = max(0, state.readAloudElapsed - 15)
                } label: {
                    Image(systemName: "gobackward.15").font(.system(size: 22))
                }.accessibilityLabel("Back 15 seconds")
                Button {
                    state.readAloudElapsed += 15
                } label: {
                    Image(systemName: "goforward.15").font(.system(size: 22))
                }.accessibilityLabel("Forward 15 seconds")
                Button {
                    state.closeReadAloud()
                } label: {
                    Image(systemName: "xmark").font(.system(size: 22))
                }.accessibilityLabel("Close player")
            }.padding(.horizontal, 20).frame(height: 70).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 25))
                .buttonStyle(.plain)
        }
        private var temporarySettings: some View {
            VStack(spacing: 14) {
                Text("Temporary chat settings").font(.system(size: 21, weight: .semibold)).padding(.bottom, 10)
                ForEach([true, false], id: \.self) { personalized in
                    Button {
                        state.temporaryPersonalized = personalized
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(personalized ? "Personalized" : "Unpersonalized").font(
                                    .system(size: 15, weight: .medium))
                                Text(
                                    personalized
                                        ? "This chat can reference memory, plugins, and custom instructions"
                                        : "This chat will ignore memory, plugins, and custom instructions"
                                ).font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            if state.temporaryPersonalized == personalized {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                            }
                        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20).stroke(
                                    state.temporaryPersonalized == personalized
                                        ? Color.primary : Color.secondary.opacity(0.2),
                                    lineWidth: state.temporaryPersonalized == personalized ? 1.7 : 1)
                            }
                    }
                }
                Spacer(minLength: 0)
                Button {
                    showsTemporarySettings = false
                } label: {
                    Text("Done").font(.system(size: 17, weight: .semibold)).foregroundStyle(
                        colorScheme == .dark ? .black : .white
                    ).frame(maxWidth: .infinity).frame(height: 48).background(Color.primary, in: Capsule())
                }
            }.padding(30).background(ChatDesign.canvas).buttonStyle(.plain)
        }
        private var workModels: some View {
            VStack {
                Text("Configure").font(.system(size: 17, weight: .semibold)).padding(.top, 24).padding(.bottom, 20)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(
                            [
                                "Default", "6.1 Sol", "6 Astra", "6 Sol", "6 Luna", "5.6 Sol", "5.6 Terra", "5.6 Luna",
                                "5.5"
                            ], id: \.self
                        ) { model in
                            Button {
                                state.workModel = model
                                state.onAction(.selectModel(model))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(model).font(.system(size: 17))
                                        if model == "Default" {
                                            Text("Recommended set of frontier models").font(.system(size: 15))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if state.workModel == model {
                                        Image(systemName: "checkmark").font(.system(size: 20))
                                    }
                                }.frame(minHeight: 61).contentShape(Rectangle())
                            }
                            if model != "5.5" { Divider() }
                        }
                    }.padding(.horizontal, 42)
                }
                Button {
                    showsWorkModels = false
                } label: {
                    Text("Done").font(.system(size: 17, weight: .semibold)).foregroundStyle(
                        colorScheme == .dark ? .black : .white
                    ).frame(maxWidth: .infinity).frame(height: 48).background(Color.primary, in: Capsule())
                }.padding(26)
            }.background(ChatDesign.canvas).buttonStyle(.plain)
        }
        private var drawer: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("ChatGPT").font(.system(size: 22, weight: .bold))
                    Spacer()
                    Button {
                        searchPresented.toggle()
                    } label: {
                        GlassCircle(symbol: "magnifyingglass")
                    }.accessibilityLabel("Search chats")
                }.padding(.horizontal, 24).padding(.bottom, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(
                            Array(
                                zip(
                                    [ChatPage.dot, .scheduled, .space, .customize, .codex],
                                    ["record.circle", "clock", "books.vertical", "slider.horizontal.3", "cloud"])),
                            id: \.0
                        ) { page, icon in
                            Button {
                                state.open(page)
                            } label: {
                                Label(page.rawValue, systemImage: icon).font(.system(size: 17, weight: .medium)).frame(
                                    maxWidth: .infinity, alignment: .leading
                                ).frame(height: 48)
                            }
                        }
                        if state.explore.isExpanded {
                            ForEach(
                                Array(
                                    zip(
                                        [ChatPage.sites, .projects, .plugins, .images],
                                        ["square.grid.2x2", "folder", "puzzlepiece.extension", "paintpalette"])),
                                id: \.0
                            ) { page, icon in
                                Button {
                                    state.open(page)
                                } label: {
                                    Label(page.rawValue, systemImage: icon).font(.system(size: 17, weight: .medium))
                                        .frame(maxWidth: .infinity, alignment: .leading).frame(height: 48).contentShape(
                                            Rectangle())
                                }.accessibilityIdentifier("explore.\(page.rawValue.lowercased())")
                            }
                        } else {
                            Button {
                                state.open(.explore)
                            } label: {
                                Label("Explore", systemImage: "square.grid.2x2").font(
                                    .system(size: 17, weight: .medium)
                                ).frame(maxWidth: .infinity, alignment: .leading).frame(height: 48).contentShape(
                                    Rectangle())
                            }.accessibilityIdentifier("explore.expand")
                        }
                        Text("Pinned").font(.system(size: 17, weight: .semibold)).padding(.top, 26).padding(.bottom, 13)
                        ForEach(
                            ["Weekend reading list", "A new idea", "Learning SwiftUI", "Finances", "Health"].filter {
                                state.search.isEmpty || $0.localizedCaseInsensitiveContains(state.search)
                            }, id: \.self
                        ) { title in
                            Button {
                                openSample(title)
                            } label: {
                                Label(title, systemImage: "bubble.left").font(.system(size: 17)).lineLimit(1).frame(
                                    maxWidth: .infinity, alignment: .leading
                                ).frame(height: 48)
                            }
                        }
                        Text("Recents").font(.system(size: 17, weight: .semibold)).padding(.top, 28).padding(
                            .bottom, 14)
                        ForEach(
                            ["A thoughtful morning routine", "A trip to the coast", "Design notes"].filter {
                                state.search.isEmpty || $0.localizedCaseInsensitiveContains(state.search)
                            }, id: \.self
                        ) { title in
                            Button {
                                openSample(title)
                            } label: {
                                Text(title).font(.system(size: 17)).lineLimit(1).frame(
                                    maxWidth: .infinity, alignment: .leading
                                ).frame(height: 48)
                            }
                        }
                    }.padding(.horizontal, 24).padding(.bottom, 16)
                }.scrollIndicators(.hidden)
                HStack {
                    Button {
                        state.newChat()
                    } label: {
                        Label("Chat", systemImage: "square.and.pencil").font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 21).frame(height: 48).glassEffect(
                                .regular.tint(state.accentColor).interactive(), in: Capsule())
                    }.accessibilityLabel("New chat")
                    Spacer()
                    Button {
                        state.open(.settings)
                    } label: {
                        GlassCircle(symbol: "gearshape", size: 48)
                    }.accessibilityLabel("Settings")
                }.padding(.horizontal, 24)
            }.buttonStyle(.plain).padding(.top, 2)
        }
        @ViewBuilder private func messageContextMenu(_ message: ChatMessage) -> some View {
            Button {
                copy(message)
            } label: {
                Label {
                    Text("Copy")
                } icon: {
                    ChatCopySymbol.image
                }
            }.tint(.primary)
            Button("Read aloud", systemImage: "speaker.wave.2") { state.toggleReadAloud(message.id) }
            Button("Good response", systemImage: "hand.thumbsup") { state.setFeedback(.positive, for: message.id) }
            Button("Bad response", systemImage: "hand.thumbsdown") { state.setFeedback(.negative, for: message.id) }
            Button("Try again", systemImage: "arrow.clockwise") { state.retry(message.id) }
        }
        @ViewBuilder private func responseMoreMenu(_ message: ChatMessage) -> some View {
            Section("Today") {
                Button("Branch in new chat", systemImage: "arrow.triangle.branch") {
                    state.onAction(.branch(message.id))
                    localNotice = "Branching is supplied by your host app."
                }
                Button("Read Aloud", systemImage: "speaker.wave.2") { state.toggleReadAloud(message.id) }
            }
            Section("Used 6 Thinking") {
                Button("Retry", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") { state.retry(message.id) }
                Button("Use Pro mode", systemImage: "brain") {
                    state.thinkHarder = true
                    state.retry(message.id)
                }
                Button("Search the web", systemImage: "globe") {
                    state.webSearch = true
                    state.retry(message.id)
                }
            }
        }
        private func rate(_ feedback: MessageFeedback, message: ChatMessage) {
            state.setFeedback(feedback, for: message.id)
            if state.feedback[message.id] == .negative {
                feedbackMessage = message
            } else if state.feedback[message.id] == .positive {
                showToast("Thank you for your feedback!")
            }
        }
        private func showToast(_ message: String) {
            toast = message
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                if toast == message { withAnimation { toast = nil } }
            }
        }
        private func messageAction(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Group { if symbol == "square.on.square" { ChatCopySymbol.image } else { Image(systemName: symbol) } }
                    .font(.system(size: 15)).foregroundStyle(.secondary).frame(minWidth: 16, minHeight: 20)
            }.accessibilityLabel(label)
        }
        private func copy(_ message: ChatMessage) {
            state.copyMessage(message)
            showToast("Message copied")
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                state.clearCopyConfirmation(id: message.id)
            }
        }
        private func openSample(_ title: String) {
            state.newChat()
            state.messages = [
                .init(role: .user, text: title),
                .init(role: .assistant, text: "Here's a place to begin. What would you like to explore together?")
            ]
        }
    }
    private struct AttachmentRoute: Identifiable { let id: String }

    struct DictationWaveform: View {
        var levels: [Double] = []
        var body: some View {
            GeometryReader { geometry in
                let heights = DictationWaveformGeometry.heights(
                    levels: levels, availableWidth: geometry.size.width, availableHeight: geometry.size.height)
                HStack(spacing: 3) {
                    ForEach(heights.indices, id: \.self) { index in
                        Capsule().fill(.secondary).frame(width: 3, height: heights[index])
                    }
                }.frame(maxHeight: .infinity)
            }.clipped()
        }
    }

#endif
