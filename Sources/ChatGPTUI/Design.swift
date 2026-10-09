#if os(iOS)
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

enum ChatDesign {
    static let blue = Color(red: 0.22, green: 0.39, blue: 0.95)
    static let canvas = Color.adaptive(dark: 0, light: 1)
    static let card = Color.adaptive(dark: 0.12, light: 1)
    static let settingsCanvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color.adaptive(dark: 0.12, light: 0.95)
    static let raised = Color.adaptive(dark: 0.14, light: 0.91)
    static let secondary = Color(white: 0.57)
}
struct GlassCircle: View {
    let symbol: String
    var size: CGFloat = 44
    var body: some View {
        Image(systemName: symbol).font(.system(size: 22, weight: .regular))
            .frame(width: size, height: size).glassEffect(.regular.interactive(), in: .circle)
    }
}
struct DrawerGlyph: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Capsule().frame(width: 21, height: 2)
            Capsule().frame(width: 14, height: 2)
        }.frame(width: 44, height: 44).glassEffect(.regular.interactive(), in: .circle)
    }
}
struct VoiceOrb: View {
    var size: CGFloat = 96
    var tint = Color(red: 0.44, green: 0.42, blue: 1)
    var cloudColor = Color(red: 0.94, green: 0.96, blue: 1)
    var phase = 0.0
    var cloudTilt = 0.0
    var body: some View {
        Circle().fill(tint)
            .overlay {
                Canvas(rendersAsynchronously: true) { context, dimensions in
                    let step = max(1, dimensions.width / 110)
                    for y in stride(from: 0.0, to: dimensions.height, by: step) {
                        for x in stride(from: 0.0, to: dimensions.width, by: step) {
                            let alpha = VoiceCloudField.alpha(x: x / dimensions.width, y: y / dimensions.height, phase: phase, tilt: cloudTilt)
                            context.fill(Path(CGRect(x: x, y: y, width: step + 0.5, height: step + 0.5)), with: .color(cloudColor.opacity(alpha)))
                        }
                    }
                }.blur(radius: size / 280)
            }.clipShape(Circle()).frame(width: size, height: size).accessibilityHidden(true)
    }
}
struct VoiceBars: View {
    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(Array([10.0, 21, 15, 8].enumerated()), id: \.offset) { _, height in
                Capsule().frame(width: 3, height: height)
            }
        }.frame(width: 23, height: 23)
    }
}
struct GroupCard<Content: View>: View {
    var outlined = false
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }.background(ChatDesign.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay { if outlined { RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.13), lineWidth: 1) } }
    }
}
struct SettingsRow: View {
    let title: String
    var icon: String? = nil
    var detail: String? = nil
    var chevron = true
    var color: Color = .primary
    var pickerIndicator = false
    var detailDot: Color? = nil
    var body: some View {
        HStack(spacing: 14) {
            if let icon { Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color).frame(width: 23) }
            Text(title).foregroundStyle(.primary)
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                if let detailDot { Circle().fill(detailDot).frame(width: 12, height: 12).accessibilityHidden(true) }
                if let detail { Text(detail).foregroundStyle(ChatDesign.secondary).lineLimit(1).minimumScaleFactor(0.7) }
                if pickerIndicator { Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(ChatDesign.secondary).accessibilityHidden(true) }
            }
            if chevron && !pickerIndicator { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(ChatDesign.secondary) }
        }.font(.system(size: 17)).padding(.horizontal, 18).frame(minHeight: 52).contentShape(Rectangle())
    }
}
struct RowDivider: View {
    var body: some View { Divider().overlay(.white.opacity(0.05)).padding(.leading, 52).padding(.trailing, 16) }
}

extension Color {
    static func adaptive(dark: Double, light: Double) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { trait in UIColor(white: trait.userInterfaceStyle == .dark ? dark : light, alpha: 1) })
        #else
        Color(nsColor: NSColor(name: nil) { appearance in
            NSColor(white: appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light, alpha: 1)
        })
        #endif
    }
}


struct TemporaryChatGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width * 0.45
        for (start, end) in [(205.0, 264.0), (282.0, 346.0), (4.0, 67.0), (85.0, 132.0), (154.0, 186.0)] {
            path.move(to: CGPoint(x: center.x + cos(start * .pi / 180) * radius, y: center.y + sin(start * .pi / 180) * radius))
            path.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        }
        path.move(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.width * 0.10, y: rect.height * 0.97))
        path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.height * 0.88))
        return path
    }
}
struct ThinkingGauge: View {
    var color = ChatDesign.blue
    var body: some View {
        ZStack {
            Circle().trim(from: 0.13, to: 0.88).stroke(Color.gray, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(90))
            Circle().trim(from: 0.34, to: 0.88).stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(90))
            Circle().stroke(.primary, lineWidth: 1.7).frame(width: 5, height: 5)
            Capsule().fill(.primary).frame(width: 2, height: 10).offset(y: -4).rotationEffect(.degrees(43))
        }
    }
}


extension ChatState {
    var accentColor: Color {
        switch accentName {
        case "Cyan": .cyan
        case "Green": .mint
        case "Lime": Color(red: 0.66, green: 0.84, blue: 0.06)
        case "Yellow": .yellow
        case "Orange": .orange
        case "Pink": .pink
        case "Magenta": Color(red: 0.85, green: 0.30, blue: 0.80)
        case "Purple": .purple
        case "Black": .primary
        default: ChatDesign.blue
        }
    }
}

#endif
