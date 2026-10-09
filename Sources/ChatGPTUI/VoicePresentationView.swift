#if os(iOS)
import SwiftUI

struct VoicePresentationView: View {
    @Bindable var state: ChatState
    var cameraPreview: AnyView
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var composerFocused: Bool
    @State private var attachmentsPresented = false
    @State private var morePresented = false
    @State private var collapseStarted: Date?
    @State private var textureEpoch = Date()
    var body: some View {
        GeometryReader { geometry in
            let fullHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            ZStack {
                (state.voice.isChoosing ? Color(white: 0.19) : .black).ignoresSafeArea()
                if state.voice.isChoosing {
                    VStack {
                        HStack {
                            Color.clear.frame(width: 44, height: 44)
                            Spacer(); Text("Choose your voice").font(.system(size: 17, weight: .semibold)); Spacer()
                            Button { state.setVoice(false) } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close voice chooser")
                        }.padding(.horizontal, 16).padding(.top, 2)
                        Spacer()
                    }
                    orb(size: 176).position(x: geometry.size.width / 2, y: fullHeight * (393.0 / 852) - geometry.safeAreaInsets.top)
                    profileDescription(nameSize: 22, detailSize: 17)
                        .position(x: geometry.size.width / 2, y: fullHeight * (628.0 / 852) - geometry.safeAreaInsets.top)
                    pageDots.position(x: geometry.size.width / 2, y: fullHeight * (682.0 / 852) - geometry.safeAreaInsets.top)
                    Button { state.startVoice() } label: {
                        Text("Start Voice").font(.system(size: 17, weight: .semibold)).foregroundStyle(.black)
                            .frame(width: max(120, geometry.size.width - 60), height: 44).background(.white, in: Capsule())
                    }.accessibilityIdentifier("voice.start")
                        .position(x: geometry.size.width / 2, y: fullHeight * (779.0 / 852) - geometry.safeAreaInsets.top)
                } else {
                    if state.voice.hasTranscript {
                        transcript.padding(.top, 62).padding(.bottom, 174)
                    }
                    orbLayer(geometry: geometry, fullHeight: fullHeight)
                    VStack {
                        HStack {
                            Button { state.requestVoiceNavigation(.sidebar) } label: { DrawerGlyph() }.accessibilityLabel("Voice sidebar")
                            Spacer()
                            if state.voice.variant == .current { Button { withAnimation(reduceMotion ? nil : .default) { state.voice.showsSettings = true }; composerFocused = false } label: {
                                VoiceSettingsGlyph().stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).frame(width: 23, height: 23)
                                    .frame(width: 44, height: 44).glassEffect(.regular.interactive(), in: Circle())
                            }.accessibilityLabel("Voice settings").accessibilityIdentifier("voice.settings") }
                        }.padding(.horizontal, 16).padding(.top, 2)
                        Spacer()
                        controls.padding(.horizontal, composerFocused ? 12 : 34).opacity(state.voice.showsEffort ? 0 : 1).allowsHitTesting(!state.voice.showsEffort)
                    }
                }
                if attachmentsPresented {
                    Color.clear.contentShape(Rectangle()).onTapGesture { attachmentsPresented = false }
                    VStack { Spacer(); HStack { attachmentPopover; Spacer(minLength: 0) }.padding(.leading, 26) }
                }
                if state.voice.showsEffort {
                    Color.clear.contentShape(Rectangle()).onTapGesture { state.voice.showsEffort = false }
                    VStack { Spacer(); effortPanel.padding(.horizontal, 25) }
                }
                if state.voice.showsModelSwitch {
                    Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { state.voice.showsModelSwitch = false }
                    VStack { Spacer(); modelSwitchPanel.padding(.horizontal, 8).padding(.bottom, 8 - geometry.safeAreaInsets.bottom) }
                }
                if state.voice.showsLiveCamera { liveCamera }
                if state.voice.showsSettings {
                    Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { withAnimation(reduceMotion ? nil : .default) { state.voice.showsSettings = false } }
                    VStack { Spacer(); settingsPanel.frame(height: 214).padding(.horizontal, 8).padding(.bottom, 8 - geometry.safeAreaInsets.bottom) }
                }
            }.animation(reduceMotion ? nil : .default, value: state.voice.showsSettings)
        }.foregroundStyle(.white).preferredColorScheme(.dark).buttonStyle(.plain)
        .onChange(of: state.voice.hasTranscript) { old, new in collapseStarted = new && !old && !reduceMotion && !state.voice.hasHostOrbDiameter ? .now : nil }
        .onChange(of: state.voice.hasHostOrbDiameter) { _, supplied in if supplied { collapseStarted = nil } }
        .task(id: collapseStarted) {
            guard let started = collapseStarted else { return }
            do { try await Task.sleep(for: .seconds(VoiceOrbCollapse.duration)) } catch { return }
            if collapseStarted == started { collapseStarted = nil }
        }
        .onChange(of: state.voice.showsModelSwitch) { _, showing in if showing { composerFocused = false } }
        .onChange(of: state.voice.showsLiveCamera) { _, showing in if showing { composerFocused = false } }
    }
    private func orbLayer(geometry: GeometryProxy, fullHeight: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: collapseStarted == nil && (!state.voice.animatesOrbTexture || reduceMotion))) { timeline in
            let resting = state.voice.variant == .classic ? 178.0 : 193.0
            let largeY = fullHeight * (441.0 / 852) - geometry.safeAreaInsets.top - (state.voice.showsSettings ? 65 : 0)
            let target = VoiceOrbCollapse.Sample(diameter: state.voice.presentedOrbDiameter, centerY: state.voice.hasTranscript ? max(120, geometry.size.height - 108) : largeY)
            let frame = collapseStarted.map { VoiceOrbCollapse.sample(elapsed: timeline.date.timeIntervalSince($0), from: .init(diameter: resting, centerY: largeY), to: target) } ?? target
            orb(size: frame.diameter, phase: state.voice.orbPhase + (state.voice.animatesOrbTexture && !reduceMotion ? timeline.date.timeIntervalSince(textureEpoch) * 0.6 : 0)).position(x: geometry.size.width / 2, y: frame.centerY)
        }
    }
    private func orb(size: CGFloat, phase: Double = 0) -> some View {
        VoiceOrb(size: size, tint: state.voice.variant == .classic ? Color(red: 0.0, green: 0.57, blue: 1) : Color(red: 0.20, green: 0.38, blue: 0.97), cloudColor: state.voice.variant == .classic ? Color(red: 0.87, green: 0.98, blue: 0.97) : Color(red: 0.94, green: 0.96, blue: 1), phase: phase, cloudTilt: state.voice.variant == .classic ? 0.3 : 0)
            .rotationEffect(.degrees(state.voice.variant == .classic ? 180 : 0))
            .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                state.voice.next(value.translation.width < 0 ? 1 : -1)
                state.onAction(.selectVoice(state.voice.selectedID))
            })
    }
    private func profileDescription(nameSize: CGFloat, detailSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(state.voice.selected.name).font(.system(size: nameSize, weight: .semibold))
            Text(state.voice.selected.detail).font(.system(size: detailSize)).foregroundStyle(Color(white: 0.55))
        }.gesture(DragGesture(minimumDistance: 30).onEnded { value in
            state.voice.next(value.translation.width < 0 ? 1 : -1); state.onAction(.selectVoice(state.voice.selectedID))
        })
    }
    private var pageDots: some View {
        HStack(spacing: 11) {
            ForEach(0..<max(9, state.voice.profiles.count), id: \.self) { index in
                Circle().fill(index == state.voice.selectedIndex ? .white : Color(white: 0.37)).frame(width: 7, height: 7)
            }
        }.accessibilityLabel("Voice \(state.voice.selectedIndex + 1) of \(max(9, state.voice.profiles.count))")
    }
    private var controls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                attachmentMenu
                TextField("Ask ChatGPT", text: Binding(get: { state.voice.draft }, set: { state.voice.draft = $0; state.onAction(.voiceDraftChanged($0)) })).font(.system(size: 17)).focused($composerFocused).accessibilityIdentifier("voice.composer")
                    .onSubmit { submitVoiceText() }
                if state.voice.variant == .current { Button { composerFocused = false; state.voice.showsEffort.toggle() } label: { ThinkingGauge(color: state.thinkHarder ? state.accentColor : .gray).frame(width: 23, height: 23) }.accessibilityLabel("Voice thinking").accessibilityValue(state.thinkHarder ? "On" : "Off") }
            }.padding(.horizontal, 12).frame(height: 48).glassEffect(.regular, in: Capsule())
            if state.voice.isSharingScreen {
                Button { state.voice.requestScreenSharing() } label: {
                    Image(systemName: "arrow.up.square.fill").font(.system(size: 25)).frame(width: 48, height: 48).background(.blue, in: Circle())
                }.accessibilityLabel("Stop sharing screen").accessibilityIdentifier("voice.sharing")
            }
            Button {
                state.voice.isMuted.toggle(); state.onAction(.voiceMuted(state.voice.isMuted))
            } label: { GlassCircle(symbol: state.voice.isMuted ? "mic.slash" : "mic", size: 48).background(state.voice.isMuted && state.voice.mutedControlIsRed ? Color.red : Color.clear, in: Circle()) }.accessibilityLabel(state.voice.isMuted ? "Unmute voice" : "Mute voice").accessibilityIdentifier("voice.mute")
            Button { state.setVoice(false) } label: { Image(systemName: "xmark").font(.system(size: 22)).foregroundStyle(.black).frame(width: 48, height: 48).background(.white, in: Circle()) }.accessibilityLabel("End voice").accessibilityIdentifier("voice.end")
        }
    }
    private var settingsPanel: some View {
        VStack(spacing: 0) {
            profileDescription(nameSize: 18, detailSize: 13).padding(.top, 42)
            pageDots.padding(.top, 18)
            Menu {
                Picker("Language", selection: Binding(get: { state.voice.language }, set: { state.voice.language = $0; state.onAction(.voiceLanguage($0)) })) {
                    ForEach(state.voice.availableLanguages, id: \.self) { language in Text(language).tag(language) }
                }
            } label: {
                HStack(spacing: 12) { Image(systemName: "globe").font(.system(size: 20)); Text("Language"); Spacer(); Text(state.voice.language).foregroundStyle(.gray); Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold)).foregroundStyle(.gray) }
                    .font(.system(size: 17)).padding(.horizontal, 20).frame(height: 50).background(.black, in: Capsule())
            }.menuOrder(.fixed).accessibilityLabel("Voice language").padding(.horizontal, 22).padding(.top, 30)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity).background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 40, style: .continuous))
    }
    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(state.voice.transcript) { message in
                        HStack {
                            if message.role == .user { Spacer(minLength: 45) }
                            Text(message.text).font(.system(size: 17)).lineSpacing(4)
                                .padding(message.role == .user ? 13 : 0)
                                .background(message.role == .user ? (state.voice.variant == .classic ? Color(red: 0.02, green: 0.15, blue: 0.27) : Color(red: 4 / 255, green: 5 / 255, blue: 95 / 255)) : .clear, in: RoundedRectangle(cornerRadius: 23))
                                .id(message.id)
                            if message.role == .assistant { Spacer(minLength: 0) }
                        }
                    }
                }.padding(.horizontal, 20)
            }.scrollIndicators(.hidden)
                .onChange(of: state.voice.transcript) { _, _ in if let id = state.voice.transcript.last?.id { proxy.scrollTo(id, anchor: .bottom) } }
        }.accessibilityIdentifier("voice.transcript")
    }
    private var attachmentMenu: some View {
        Button { attachmentsPresented.toggle(); morePresented = false } label: { Image(systemName: "plus").font(.system(size: 24)).frame(width: 24, height: 44) }.accessibilityLabel("Voice attachments")
    }
    private var attachmentPopover: some View {
        VStack(spacing: 0) {
            if morePresented {
                mediaRows
            } else {
                ForEach([("Camera", "camera"), ("Photos", "photo"), ("Files", "paperclip")], id: \.0) { title, symbol in
                    menuRow(title, symbol: symbol) { state.voice.onAction(.attachment(title)); attachmentsPresented = false }
                }
                if state.voice.variant == .current {
                    menuRow("Plugins", symbol: "puzzlepiece.extension") { state.voice.onAction(.attachment("Plugins")); attachmentsPresented = false }
                    Button { state.thinkHarder.toggle(); attachmentsPresented = false } label: {
                        HStack(spacing: 16) {
                            ThinkingGauge(color: state.thinkHarder ? ChatDesign.blue : .white).frame(width: 25, height: 25).frame(width: 44, height: 44).background(.white.opacity(0.07), in: Circle())
                            Text("Think harder").font(.system(size: 20)); Spacer()
                            if state.thinkHarder { Image(systemName: "checkmark").font(.system(size: 18)) }
                        }.foregroundStyle(state.thinkHarder ? ChatDesign.blue : .white).padding(.horizontal, 22).frame(height: 68)
                    }
                    menuRow("More", symbol: "ellipsis") { morePresented = true }
                } else if state.voice.isSharingScreen {
                    menuRow("Stop sharing screen", symbol: "arrow.up.square", selected: true) { attachmentsPresented = false; state.voice.requestScreenSharing() }
                } else { mediaRows }
            }
        }.padding(.vertical, 10).frame(width: 280).background(Color(white: 0.12).opacity(0.85), in: RoundedRectangle(cornerRadius: 48))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 48))
    }
    @ViewBuilder private var mediaRows: some View {
        menuRow("Live video", symbol: "video") { attachmentsPresented = false; state.voice.requestLiveVideo() }
        menuRow("Share screen", symbol: "arrow.up.square") { attachmentsPresented = false; state.voice.requestScreenSharing() }
    }
    private func menuRow(_ title: String, symbol: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol).font(.system(size: 22)).rotationEffect(.degrees(symbol == "paperclip" ? -45 : 0)).frame(width: 44, height: 44).background(.white.opacity(0.07), in: Circle())
                Text(title).font(.system(size: 20)).multilineTextAlignment(.leading); Spacer(minLength: 0)
                if selected { Image(systemName: "checkmark").font(.system(size: 18)) }
            }.foregroundStyle(selected ? ChatDesign.blue : .white).padding(.horizontal, 22).frame(height: 68)
        }
    }
    private var effortPanel: some View {
        VStack(spacing: 20) {
            Text(state.voice.effortPosition == 1 ? "Medium" : state.voice.effortPosition == 2 ? "High" : "Thinking effort").font(.system(size: 22, weight: .semibold))
            GeometryReader { geometry in
                let step = max(0, geometry.size.width - 48) / 4
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.18, green: 0.33, blue: 0.95)).frame(width: 48 + step * CGFloat(state.voice.effortPosition), height: 48)
                    ForEach(0..<5) { index in
                        Button { state.voice.setEffort(index) } label: {
                            Circle().fill(index == state.voice.effortPosition ? .white : Color.gray.opacity(0.6))
                                .frame(width: index == state.voice.effortPosition ? 40 : 12, height: index == state.voice.effortPosition ? 40 : 12).frame(width: 48, height: 48)
                        }.position(x: 24 + CGFloat(index) * step, y: 24).accessibilityLabel("Voice effort position \(index + 1)")
                    }
                }.frame(width: geometry.size.width, height: 48).contentShape(Rectangle()).highPriorityGesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard step > 0 else { return }
                    state.voice.setEffort(Int(((value.location.x - 24) / step).rounded()))
                })
            }.frame(height: 48).padding(12).glassEffect(.regular, in: Capsule())
        }
    }
    private var modelSwitchPanel: some View {
        VStack(spacing: 20) {
            HStack { Spacer(); Button { state.voice.showsModelSwitch = false } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Cancel voice model switch") }
            Text("Switch voice models to share screen?").font(.system(size: 20, weight: .bold)).multilineTextAlignment(.center)
            Text("Sharing your screen isn’t available with this voice model yet. To share your screen, you can continue this conversation with an older voice model.").font(.system(size: 17)).foregroundStyle(.gray).multilineTextAlignment(.center)
            Button { state.voice.continueScreenSharing() } label: { Text("Continue").foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 46).background(.white, in: Capsule()) }.accessibilityIdentifier("voice.shareContinue")
            Button { state.voice.showsModelSwitch = false } label: { Text("Cancel").frame(maxWidth: .infinity).frame(height: 46).overlay(Capsule().stroke(.gray.opacity(0.4))) }
        }.padding(20).padding(.bottom, 14).background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 40))
    }
    private var liveCamera: some View {
        ZStack {
            cameraPreview.ignoresSafeArea()
            VStack {
                Text("Don’t use for live navigation or decisions that may impact your health or safety.").font(.system(size: 13)).multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 4)
                Spacer()
                HStack {
                    Button { state.voice.onAction(.flipCamera) } label: { GlassCircle(symbol: "arrow.2.circlepath", size: 48) }.accessibilityLabel("Flip live camera")
                    Spacer()
                    Button { state.voice.isMuted.toggle(); state.onAction(.voiceMuted(state.voice.isMuted)) } label: { GlassCircle(symbol: state.voice.isMuted ? "mic.slash" : "mic", size: 48) }.accessibilityLabel("Live camera microphone")
                    Spacer()
                    Button { state.voice.cameraFlashEnabled.toggle(); state.voice.onAction(.cameraFlash(state.voice.cameraFlashEnabled)) } label: { GlassCircle(symbol: state.voice.cameraFlashEnabled ? "bolt" : "bolt.slash", size: 48) }.accessibilityLabel("Live camera flash")
                    Spacer()
                    Button { state.voice.closeLiveVideo() } label: { GlassCircle(symbol: "xmark", size: 48) }.accessibilityLabel("Close live camera")
                }.padding(.horizontal, 34)
            }
        }
    }
    private func submitVoiceText() {
        let text = state.voice.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        state.onAction(.voiceText(text)); state.voice.draft = ""; composerFocused = false
    }
}
private struct VoiceSettingsGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (y, x) in [(0.25, 0.63), (0.75, 0.32)] {
            let center = CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
            let radius = rect.width * 0.13
            path.move(to: CGPoint(x: rect.minX, y: center.y)); path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            path.move(to: CGPoint(x: center.x + radius, y: center.y)); path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        }
        return path
    }
}
#endif
