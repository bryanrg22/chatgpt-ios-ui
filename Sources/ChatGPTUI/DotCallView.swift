#if os(iOS)
    import SwiftUI

    public struct DotCallView: View {
        @Bindable private var state: DotPresentationState
        public init(state: DotPresentationState) { self.state = state }
        public var body: some View {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        DotAvatar().frame(width: 58, height: 58)
                        Text(state.name).font(.system(size: 17, weight: .semibold))
                    }.frame(maxWidth: .infinity)
                    Button {
                        state.callMinimized.toggle()
                    } label: {
                        GlassCircle(
                            symbol: state.callMinimized
                                ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    }.accessibilityLabel(state.callMinimized ? "Expand dot call" : "Minimize dot call")
                }.padding(.horizontal, 22).padding(.top, state.callMinimized ? 56 : 65)
                Text(statusLabel).font(.system(size: state.callMinimized ? 17 : 28)).monospacedDigit().foregroundStyle(
                    state.callMinimized ? .white : Color(red: 0.73, green: 0.86, blue: 0.96)
                ).padding(.top, state.callMinimized ? 26 : 34).accessibilityIdentifier("dot.call.status")
                if !state.callMinimized { Spacer() }
                if state.callPhase == .failed {
                    VStack(spacing: 18) {
                        Text("Couldn't connect the call. Check your connection and microphone access, then try again.")
                            .font(.system(size: 17)).multilineTextAlignment(.center)
                        Button {
                            state.retryCall()
                        } label: {
                            Text("Try again").font(.system(size: 17)).padding(.horizontal, 14).padding(.vertical, 7)
                                .background(.white.opacity(0.14), in: Capsule())
                        }
                    }.padding(.horizontal, 28).padding(.top, state.callMinimized ? 44 : 0)
                }
                Spacer(minLength: state.callMinimized ? 32 : 16)
                HStack(spacing: state.callMinimized ? 28 : 40) {
                    callButton(
                        "Speaker", symbol: state.speakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        color: state.speakerEnabled ? .white : .clear,
                        foreground: state.speakerEnabled ? .black : .white
                    ) { state.toggleSpeaker() }
                    callButton(
                        "End", symbol: "phone.down.fill",
                        color: Color(.sRGB, red: 175.0 / 255, green: 1.0 / 255, blue: 2.0 / 255, opacity: 1),
                        foreground: .white
                    ) { state.endCall() }
                    callButton(
                        "Mute", symbol: "mic.slash.fill", color: state.microphoneMuted ? .white : .clear,
                        foreground: state.microphoneMuted ? Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1) : .white
                    ) { state.toggleMute() }
                }.padding(.horizontal, state.callMinimized ? 25 : 34).padding(.bottom, state.callMinimized ? 26 : 40)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if state.callMinimized {
                        Color.black
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.56, blue: 0.65), Color(red: 0.12, green: 0.27, blue: 0.43),
                                Color(red: 0.02, green: 0.11, blue: 0.23)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing
                        ).overlay {
                            Ellipse().fill(.white.opacity(0.18)).frame(width: 100, height: 450).blur(radius: 65).offset(
                                x: 160)
                        }.ignoresSafeArea()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: state.callMinimized ? 42 : 0))
                .overlay {
                    if state.callMinimized {
                        RoundedRectangle(cornerRadius: 42).stroke(Color(white: 0.2), lineWidth: 2)
                    }
                }
                .foregroundStyle(.white).buttonStyle(.plain)
        }
        private var statusLabel: String {
            switch state.callPhase {
            case .connected: state.callPresentation.elapsedLabel
            case .failed: "Call failed"
            case .idle, .calling: "Calling…"
            }
        }
        private func callButton(
            _ title: String, symbol: String, color: Color, foreground: Color, action: @escaping () -> Void
        ) -> some View {
            VStack(spacing: 5) {
                Button(action: action) {
                    Capsule().fill(color).frame(
                        width: state.callMinimized ? 89 : 80, height: state.callMinimized ? 48 : 80
                    )
                    .glassEffect(.regular.tint(color).interactive(), in: Capsule())
                    .overlay {
                        Image(systemName: symbol).font(.system(size: state.callMinimized ? 24 : 28, weight: .semibold))
                            .foregroundStyle(foreground)
                    }
                }.accessibilityLabel("\(title) dot call").accessibilityValue(
                    title == "Mute"
                        ? (state.microphoneMuted ? "On" : "Off")
                        : title == "Speaker" ? (state.speakerEnabled ? "On" : "Off") : "")
                if !state.callMinimized { Text(title).font(.system(size: 15)) }
            }
        }
    }
#endif
