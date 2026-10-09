#if os(iOS)
    import SwiftUI

    /// A canvas for reference review, not a Dynamic Island, Live Activity or CallKit
    /// session. The host owns actual system integration and may consume DotUIAction.
    public struct DotSystemCallPreview: View {
        public enum Style: Sendable { case compact, expanded }
        private let presentation: DotCallPresentation
        private let style: Style
        private let onAction: (DotUIAction) -> Void
        public init(
            presentation: DotCallPresentation, style: Style, onAction: @escaping (DotUIAction) -> Void = { _ in }
        ) {
            self.presentation = presentation
            self.style = style
            self.onAction = onAction
        }
        public var body: some View {
            VStack(spacing: 14) {
                Group {
                    if style == .compact {
                        HStack {
                            DotAvatar().frame(width: 13, height: 13)
                            Spacer(minLength: 80)
                            Text(presentation.elapsedLabel).font(.system(size: 12, weight: .medium)).monospacedDigit()
                        }.padding(.horizontal, 10).frame(width: 220, height: 37)
                    } else {
                        HStack(spacing: 12) {
                            DotAvatar().frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(presentation.elapsedLabel).font(.system(size: 14)).foregroundStyle(.gray)
                                    .monospacedDigit()
                                Text("Your dot").font(.system(size: 16, weight: .semibold))
                            }
                            Spacer(minLength: 8)
                            Button {
                                onAction(.mute(!presentation.microphoneMuted))
                            } label: {
                                Image(systemName: "mic.slash.fill").font(.system(size: 22)).foregroundStyle(
                                    presentation.microphoneMuted
                                        ? Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1) : .white
                                )
                                .frame(width: 48, height: 48).background(
                                    presentation.microphoneMuted ? Color.white : Color(white: 0.14), in: Circle())
                            }.accessibilityLabel("Mute system call preview").accessibilityValue(
                                presentation.microphoneMuted ? "On" : "Off")
                            Button {
                                onAction(.endCall)
                            } label: {
                                Image(systemName: "phone.down.fill").font(.system(size: 23)).frame(
                                    width: 48, height: 48
                                ).background(Color.red, in: Circle())
                            }.accessibilityLabel("End system call preview")
                        }.padding(.horizontal, 18).frame(maxWidth: 377).frame(height: 88)
                    }
                }.background(.black, in: Capsule()).foregroundStyle(.white).buttonStyle(.plain)
                Text("System call preview · No active call").font(.footnote).foregroundStyle(.secondary)
            }.accessibilityIdentifier(style == .compact ? "dot.systemPreview.compact" : "dot.systemPreview.expanded")
        }
    }
#endif
