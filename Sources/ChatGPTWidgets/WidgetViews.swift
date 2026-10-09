#if os(iOS)
import SwiftUI
import WidgetKit

/// Use inside a WidgetKit entry view; native widget margins and system corner treatment are retained.
public struct ChatWidgetView: View {
    public let presentation: ChatWidgetPresentation
    public let size: ChatWidgetSize
    public init(presentation: ChatWidgetPresentation, size: ChatWidgetSize) { self.presentation = presentation; self.size = size }
    public var body: some View {
        Group { switch presentation.layout {
        case .codexUsage: usagePlaceholder
        case .chat: chat
        case .shortcuts: shortcuts
        case .codexTasks: tasks
        } }.foregroundStyle(.white).containerBackground(.black, for: .widget)
            .widgetURL(([.codexUsage, .codexTasks].contains(presentation.layout) ? ChatWidgetDestination.codex : .chat).url)
    }
    private var usagePlaceholder: some View {
        GeometryReader { geometry in
            if size == .small {
                Capsule().fill(.white.opacity(0.12)).frame(width: geometry.size.width, height: 4).position(x: geometry.size.width / 2, y: geometry.size.height * 0.43)
                Capsule().fill(.white.opacity(0.12)).frame(width: geometry.size.width, height: 4).position(x: geometry.size.width / 2, y: geometry.size.height * 0.84)
            } else {
                HStack(spacing: 24) { Capsule().fill(.white.opacity(0.12)); Capsule().fill(.white.opacity(0.12)) }.frame(height: 4).position(x: geometry.size.width / 2, y: geometry.size.height * 0.77)
            }
        }.accessibilityLabel("Codex usage placeholder")
    }
    private var chat: some View {
        GeometryReader { geometry in
            let rowHeight = max(0, (geometry.size.height - 8) / 2)
            VStack(spacing: 8) {
                Link(destination: ChatWidgetDestination.chat.url) {
                    HStack(spacing: 12) {
                        Image("ChatGPTKnot", bundle: .module).resizable().renderingMode(.template).scaledToFit().frame(width: 32, height: 32)
                        Text(size == .small ? "Ask" : "Ask ChatGPT").font(.system(size: 17)).foregroundStyle(.white.opacity(0.55)); Spacer(minLength: 0)
                    }.padding(.horizontal, 14).frame(maxWidth: .infinity).frame(height: rowHeight).background(.white.opacity(0.23), in: Capsule())
                }.accessibilityLabel("Ask ChatGPT")
                HStack(spacing: 8) {
                    ForEach(size == .small ? [ChatWidgetDestination.camera, .voice] : [.camera, .photos, .dictation, .voice], id: \.self) { destination in
                        Link(destination: destination.url) { WidgetActionGlyph(destination: destination).frame(width: rowHeight, height: rowHeight).background(.white.opacity(0.23), in: Circle()) }.accessibilityLabel(destination.title)
                        if destination != .voice { Spacer(minLength: 0) }
                    }
                }
            }
        }
    }
    private var tasks: some View {
        VStack(spacing: 0) {
            ForEach(presentation.tasks.prefix(size == .medium ? 1 : size == .tall ? 8 : 4)) { task in
                Link(destination: task.url) {
                    HStack { Text(task.title).font(.system(size: 16)).lineLimit(1); Spacer(); if task.isRunning { Circle().trim(from: 0.12, to: 0.87).stroke(AngularGradient(colors: [.white.opacity(0.12), .white.opacity(0.8)], center: .center), style: StrokeStyle(lineWidth: 1.7, lineCap: .round)).frame(width: 16, height: 16).accessibilityLabel("Running") } }
                        .frame(height: 59).contentShape(Rectangle())
                }.accessibilityLabel(task.title)
            }
            Spacer(minLength: 0)
        }.padding(.top, size == .medium ? 22 : 18)
    }
    private var shortcuts: some View {
        let columns = size == .small ? 1 : 2
        return GeometryReader { geometry in
            let visible = Array(presentation.shortcuts.prefix(size == .small ? 2 : size == .medium ? 4 : 8))
            let rows = max(1, Int(ceil(Double(visible.count) / Double(columns))))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach(visible) { shortcut in
                    Link(destination: shortcut.destination.url) {
                        VStack(alignment: .leading, spacing: 7) {
                            WidgetActionGlyph(destination: shortcut.destination, size: 22).frame(width: 23, height: 23)
                            Text(shortcut.title).font(.system(size: 13)).lineLimit(1)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading).padding(.horizontal, 10)
                            .frame(height: max(0, (geometry.size.height - CGFloat(rows - 1) * 8) / CGFloat(rows)))
                            .background(.white.opacity(0.23), in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityLabel(shortcut.title)
                }
            }
        }
    }
}
public struct WidgetActionGlyph: View {
    public var destination: ChatWidgetDestination
    public var size: CGFloat
    public init(destination: ChatWidgetDestination, size: CGFloat = 25) { self.destination = destination; self.size = size }
    public var body: some View {
        Group {
            if destination == .voice {
                HStack(spacing: 3) { ForEach(Array([12.0, 28, 21, 10].enumerated()), id: \.offset) { _, height in Capsule().frame(width: 2, height: height * size / 28) } }
            } else if destination == .chat {
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 20)); path.addCurve(to: CGPoint(x: 3, y: 8), control1: CGPoint(x: 0, y: 16), control2: CGPoint(x: 0, y: 11))
                    path.addCurve(to: CGPoint(x: 23, y: 8), control1: CGPoint(x: 7, y: -2), control2: CGPoint(x: 20, y: -1))
                    path.addCurve(to: CGPoint(x: 9, y: 23), control1: CGPoint(x: 30, y: 20), control2: CGPoint(x: 17, y: 28))
                    path.addLine(to: CGPoint(x: 2, y: 25)); path.closeSubpath()
                }.stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)).frame(width: 28, height: 28).scaleEffect(size / 28)
            } else if destination == .photos {
                ZStack {
                    RoundedRectangle(cornerRadius: 3).stroke(lineWidth: 2)
                    Circle().stroke(lineWidth: 1.7).frame(width: 5, height: 5).offset(x: 6, y: -4)
                    Path { p in p.move(to: CGPoint(x: 1, y: 17)); p.addLine(to: CGPoint(x: 7, y: 11)); p.addQuadCurve(to: CGPoint(x: 11, y: 11), control: CGPoint(x: 9, y: 9)); p.addLine(to: CGPoint(x: 22, y: 23)) }.stroke(style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                }.frame(width: 25, height: 23).scaleEffect(size / 25)
            } else { Image(systemName: destination.symbol).font(.system(size: size, weight: .regular)).environment(\.symbolVariants, .none) }
        }.accessibilityHidden(true)
    }
}
#endif
