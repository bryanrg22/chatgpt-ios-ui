#if os(iOS)
import SwiftUI

/// Local viewer shell. The host owns screen transport, clipboard, windows, and key delivery.
public struct DotComputerView<Preview: View>: View {
    @Bindable private var state: DotPresentationState
    private let preview: Preview
    @FocusState private var keyboardVisible: Bool
    @State private var input = ""
    @State private var zoom: CGFloat = 1
    @GestureState private var magnification: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    public init(state: DotPresentationState, @ViewBuilder preview: () -> Preview) { self.state = state; self.preview = preview() }
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                if state.computerConnecting { VStack(spacing: 12) { ProgressView().tint(.white); Text("Connecting…").font(.system(size: 17)).foregroundStyle(.secondary) }.position(x: geometry.size.width / 2, y: geometry.size.height / 2) }
                else {
                    preview.frame(width: geometry.size.width, height: geometry.size.width * 0.76)
                        .scaleEffect(min(4, max(1, zoom * magnification)))
                        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
                        .frame(width: geometry.size.width, height: geometry.size.width * 0.76).clipped()
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.5)
                        .gesture(MagnifyGesture().updating($magnification) { value, current, _ in current = value.magnification }.onEnded { value in zoom = min(4, max(1, zoom * value.magnification)); if zoom == 1 { offset = .zero } })
                        .simultaneousGesture(DragGesture().updating($drag) { value, current, _ in if zoom > 1 { current = value.translation } }.onEnded { value in if zoom > 1 { let maxX = geometry.size.width * (zoom - 1) / 2; let maxY = geometry.size.width * 0.76 * (zoom - 1) / 2; offset = CGSize(width: min(maxX, max(-maxX, offset.width + value.translation.width)), height: min(maxY, max(-maxY, offset.height + value.translation.height))) } })
                }
            }.ignoresSafeArea(.keyboard)
            VStack {
                HStack {
                    Button { keyboardVisible = false; state.computerIsPresented = false } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close dot computer")
                    Spacer(); Label("Your dot’s computer", systemImage: "laptopcomputer").font(.system(size: 17, weight: .semibold)); Spacer(); Color.clear.frame(width: 44, height: 44)
                }.padding(.horizontal, 16)
                Spacer()
                TextField("Computer input", text: $input).focused($keyboardVisible).autocorrectionDisabled().textInputAutocapitalization(.never).onSubmit { if !input.isEmpty { state.onAction(.computerInput(input)); input = "" } }.frame(width: 1, height: 1).opacity(0.01).accessibilityIdentifier("dot.computer-input")
                HStack(spacing: 12) {
                    Spacer()
                    utility("Clipboard", symbol: "document.on.clipboard") { state.onAction(.computerClipboard) }.disabled(!state.computerClipboardAvailable).opacity(state.computerClipboardAvailable ? 1 : 0.35)
                    utility("Computer windows", symbol: "rectangle.on.rectangle") { state.onAction(.computerWindows) }
                    utility(keyboardVisible ? "Hide computer keyboard" : "Show computer keyboard", symbol: keyboardVisible ? "chevron.down" : "keyboard") { keyboardVisible.toggle() }
                }.padding(.horizontal, 16).padding(.bottom, 10)
            }
        }.foregroundStyle(.white).buttonStyle(.plain).preferredColorScheme(.dark)
    }
    private func utility(_ name: String, symbol: String, action: @escaping () -> Void) -> some View { Button(action: action) { Image(systemName: symbol).font(.system(size: 18)).frame(width: 44, height: 44).overlay { Circle().stroke(.white.opacity(0.25)) } }.accessibilityLabel(name) }
}
struct DotSyntheticDesktop: View {
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(red: 0.14, green: 0.25, blue: 0.49), Color(red: 0.47, green: 0.31, blue: 0.53)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 0) {
                HStack { Text("Workspace").fontWeight(.bold); Text("File   Edit   View"); Spacer(); Text("9:41") }.font(.system(size: 6)).padding(5).background(.black.opacity(0.3))
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) { Text("Garden plan").font(.system(size: 7, weight: .semibold)).lineLimit(1); Text("Notes"); Text("Drafts"); Text("Images"); Spacer() }.font(.system(size: 7)).frame(width: 66, alignment: .leading).padding(10).background(Color(white: 0.13))
                    VStack(alignment: .leading, spacing: 10) { Text("Weekend garden workshop").font(.system(size: 10, weight: .semibold)); Text("Choose a sunny spot for the planters. Bring two small pots, fresh soil, and a watering can."); ForEach(0..<5) { index in RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.09)).frame(height: index == 3 ? 23 : 6) }; Spacer() }.font(.system(size: 7)).padding(12).background(Color(white: 0.09))
                }.padding(22)
            }
        }.accessibilityLabel("Synthetic computer desktop")
    }
}
#endif
