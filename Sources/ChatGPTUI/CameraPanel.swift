#if os(iOS)
import SwiftUI

/// Host-injected preview; the default is an original static fixture and never accesses a camera.
public struct CameraPanel<Preview: View>: View {
    @Bindable var state: CameraPresentationState
    var onAction: (CameraAction) -> Void
    var onAttach: (String) -> Void
    private let preview: Preview
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public init(state: CameraPresentationState, onAction: @escaping (CameraAction) -> Void = { _ in }, onAttach: @escaping (String) -> Void = { _ in }, @ViewBuilder preview: () -> Preview) {
        self.state = state; self.onAction = onAction; self.onAttach = onAttach; self.preview = preview()
    }
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                preview.frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.12)], startPoint: .center, endPoint: .bottom).allowsHitTesting(false)
                if state.scanning {
                    Text("Hold your camera over a page").font(.system(size: 15, weight: .semibold)).padding(.horizontal, 16).frame(height: 40)
                        .glassEffect(.regular, in: Capsule()).padding(.bottom, 92)
                }
                GlassEffectContainer(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        HStack {
                            cameraButton("chevron.left", label: "Camera back") {
                                if state.scanning { state.back(); onAction(.scan(false)) }
                                else { state.close(); onAction(.close) }
                            }
                            Spacer()
                            Button {
                                state.captures += 1; onAction(.shutter)
                                if !state.scanning { onAttach("Camera sample.jpg"); state.close(); onAction(.close) }
                            } label: {
                                Circle().fill(.white).frame(width: 52, height: 52).padding(7)
                                    .background(.black.opacity(0.2), in: Circle()).overlay { Circle().stroke(.white.opacity(0.6), lineWidth: 1) }
                            }.buttonStyle(CameraShutterStyle()).accessibilityLabel("Camera shutter").accessibilityIdentifier("camera.shutter")
                            Spacer()
                            cameraButton(state.scanning ? "checkmark" : state.optionsExpanded ? "xmark" : "ellipsis", label: state.scanning ? "Finish scan" : "Camera options") {
                                if state.scanning { if state.captures > 0 { onAttach("Scanned document.pdf") }; state.close(); onAction(.close) }
                                else { withAnimation(reduceMotion ? nil : .default) { state.optionsExpanded.toggle() } }
                            }.glassEffectID("options", in: glassNamespace)
                                .overlay(alignment: .topTrailing) {
                                    if state.showsOptionsHint && !state.optionsExpanded && !state.scanning {
                                        Circle().fill(Color(red: 0.20, green: 0.38, blue: 0.96)).frame(width: 10, height: 10)
                                            .overlay { Circle().stroke(.white.opacity(0.7), lineWidth: 0.5) }.accessibilityHidden(true)
                                    }
                                }
                        }
                        if state.optionsExpanded && !state.scanning {
                            VStack(spacing: 16) {
                                cameraButton("document.viewfinder", label: "Scan document") { state.beginScan(); onAction(.scan(true)) }.glassEffectID("scan", in: glassNamespace)
                                cameraButton(flashSymbol, label: "Flash \(state.flash.rawValue)") { state.cycleFlash(); onAction(.flash(state.flash)) }.glassEffectID("flash", in: glassNamespace).accessibilityIdentifier("camera.flash")
                                cameraButton("arrow.2.circlepath", label: "Flip camera") { state.frontFacing.toggle(); onAction(.flip) }.glassEffectID("flip", in: glassNamespace)
                            }.padding(.bottom, 69)
                        }
                    }
                }.padding(.horizontal, 22).padding(.bottom, 16)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
            .foregroundStyle(.white).environment(\.colorScheme, .dark)
    }
    private var flashSymbol: String { state.flash == .off ? "bolt.slash.fill" : state.flash == .auto ? "bolt.badge.a.fill" : "bolt.fill" }
    private func cameraButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if symbol == "document.viewfinder" {
                    Image(systemName: "viewfinder").font(.system(size: 23, weight: .medium))
                    Image(systemName: "doc.on.doc").font(.system(size: 13, weight: .medium))
                } else { Image(systemName: symbol).font(.system(size: 23, weight: .medium)) }
            }.frame(width: 44, height: 44).glassEffect(.regular.tint(.black.opacity(0.24)).interactive(), in: Circle())
        }
            .buttonStyle(.plain).accessibilityLabel(label)
    }
}
private struct CameraShutterStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay { if configuration.isPressed { Circle().fill(Color(red: 1, green: 0, blue: 0.30)).padding(7) } }
            .scaleEffect(configuration.isPressed ? 1.06 : 1)
    }
}
public struct SyntheticCameraPreview: View {
    public init() {}
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.45, green: 0.49, blue: 0.45), Color(red: 0.71, green: 0.67, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.91)).frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.6).rotationEffect(.degrees(-8)).shadow(color: .black.opacity(0.15), radius: 20)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Design notes").font(.system(size: 22, weight: .semibold)).foregroundStyle(.black.opacity(0.7))
                    ForEach(0..<6) { index in Capsule().fill(.black.opacity(0.12)).frame(width: index == 5 ? 90 : 165, height: 5) }
                    Text("SYNTHETIC PREVIEW").font(.system(size: 10, weight: .medium)).tracking(2).foregroundStyle(.black.opacity(0.35)).padding(.top, 18)
                }.rotationEffect(.degrees(-8))
            }
        }.accessibilityHidden(true)
    }
}
#endif
