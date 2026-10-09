#if os(iOS)
import SwiftUI

/// No camera or pairing service is created. A host may inject a live preview and handle the pairing intent.
public struct CodexConnectionView<Preview: View>: View {
    private let preview: Preview
    private let onClose: () -> Void
    private let onPair: (String) -> Void
    @State private var manual = false
    @State private var code = ""
    public init(onClose: @escaping () -> Void, onPair: @escaping (String) -> Void, @ViewBuilder preview: () -> Preview) { self.onClose = onClose; self.onPair = onPair; self.preview = preview() }
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    HStack { Button(action: onClose) { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close connection scanner"); Spacer() }.padding(.horizontal, 16).padding(.top, 16)
                    Spacer()
                    VStack(spacing: 28) {
                        preview.frame(width: min(280, geometry.size.width - 80), height: min(280, geometry.size.width - 80)).clipShape(RoundedRectangle(cornerRadius: 44))
                            .overlay { ScannerCorners().stroke(.yellow, style: StrokeStyle(lineWidth: 2.5, lineCap: .round)).padding(28) }.accessibilityLabel("QR scanner preview")
                        Text("Scan QR code to pair").font(.system(size: 20, weight: .semibold))
                    }
                    Spacer()
                    Button { code = ""; manual = true } label: { Text("Pair manually instead").font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 54).overlay { Capsule().stroke(.white.opacity(0.16)) } }.padding(.horizontal, 48).padding(.bottom, 44)
                }
                if manual {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) { Text("Pair manually").font(.system(size: 17, weight: .semibold)); Text("Enter the pairing code shown on your desktop.").font(.system(size: 15)).foregroundStyle(.secondary) }.padding(.horizontal, 14)
                        TextField("Pairing code", text: $code).textInputAutocapitalization(.never).autocorrectionDisabled().font(.system(size: 17)).padding(.horizontal, 16).frame(height: 48).background(.white.opacity(0.12), in: Capsule()).accessibilityIdentifier("codex.pairing-code")
                        HStack(spacing: 8) {
                            Button { code = ""; manual = false } label: { Text("Cancel").frame(maxWidth: .infinity).frame(height: 48).glassEffect(.regular.interactive(), in: Capsule()) }
                            Button { let submitted = code.trimmingCharacters(in: .whitespacesAndNewlines); code = ""; manual = false; onPair(submitted) } label: { Text("Pair").frame(maxWidth: .infinity).frame(height: 48).glassEffect(.regular.interactive(), in: Capsule()) }.disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }.font(.system(size: 17, weight: .medium))
                    }.padding(16).frame(width: min(320, geometry.size.width - 48)).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 36)).accessibilityAddTraits(.isModal)
                }
            }
        }.foregroundStyle(.white).preferredColorScheme(.dark).buttonStyle(.plain)
    }
}
private struct ScannerCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(); let length = rect.width * 0.15
        for corner in 0..<4 {
            let x = corner % 2 == 0 ? rect.minX : rect.maxX
            let y = corner < 2 ? rect.minY : rect.maxY
            let dx: CGFloat = corner % 2 == 0 ? 1 : -1
            let dy: CGFloat = corner < 2 ? 1 : -1
            path.move(to: CGPoint(x: x + dx * length, y: y)); path.addLine(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x, y: y + dy * length))
        }
        return path
    }
}
#endif
