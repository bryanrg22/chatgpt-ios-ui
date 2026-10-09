#if canImport(UIKit)
    import SwiftUI

    /// SF typography for captured ChatGPT rich text; parser and host actions remain independent.
    public struct ChatGPTMarkdownTheme {
        public var bodyFont: Font
        public var headingFonts: [Font]
        public var codeFont: Font
        public var foreground: Color = .primary
        public var secondary: Color = .secondary
        public var link: Color = .primary
        public var quoteBar: Color = .secondary.opacity(0.25)
        public var codeBackground: Color = .secondary.opacity(0.10)
        public var rule: Color = .secondary.opacity(0.25)
        public var blockSpacing: CGFloat = 22
        public var lineSpacing: CGFloat = 5
        public var listSpacing: CGFloat = 8
        public var tableColumnWidth: CGFloat = 150
        public init(bodySize: CGFloat = 17) {
            bodyFont = .system(size: bodySize)
            headingFonts = [22, 20, 18, 17, 17, 17].map { .system(size: $0, weight: .semibold) }
            codeFont = .system(size: 14, design: .monospaced)
        }
    }

    public struct ChatGPTMarkdownView: View {
        @State private var availableWidth: CGFloat = 361
        public let document: MarkdownDocumentModel
        public var theme: ChatGPTMarkdownTheme
        private let onAction: (MarkdownAction) -> Void
        private let imageContent: ((MarkdownImage) -> AnyView)?
        private let unsupportedContent: ((MarkdownUnsupportedKind, String) -> AnyView)?
        public init(
            document: MarkdownDocumentModel, theme: ChatGPTMarkdownTheme = .init(),
            imageContent: ((MarkdownImage) -> AnyView)? = nil,
            unsupportedContent: ((MarkdownUnsupportedKind, String) -> AnyView)? = nil,
            onAction: @escaping (MarkdownAction) -> Void = { _ in }
        ) {
            self.document = document
            self.theme = theme
            self.imageContent = imageContent
            self.unsupportedContent = unsupportedContent
            self.onAction = onAction
        }
        public init(
            _ source: String, theme: ChatGPTMarkdownTheme = .init(),
            onAction: @escaping (MarkdownAction) -> Void = { _ in }
        ) { self.init(document: .init(source: source), theme: theme, onAction: onAction) }
        public var body: some View {
            blocks(document.blocks).foregroundStyle(theme.foreground)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.width
                } action: {
                    if $0 > 0 { availableWidth = $0 }
                }
                .environment(
                    \.openURL,
                    OpenURLAction { url in
                        if let local = MarkdownAction.decodePresentationURL(url) {
                            onAction(local)
                        } else {
                            onAction(.openLink(url))
                        }
                        return .handled
                    })
        }
        private func blocks(_ blocks: [MarkdownBlock]) -> some View {
            VStack(alignment: .leading, spacing: theme.blockSpacing) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in render(block) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        @ViewBuilder private func inline(_ content: [MarkdownInline], font: Font? = nil) -> some View {
            if content.contains(where: \.containsInlineCode) {
                SelectableInlineCode(content: content, font: font ?? theme.bodyFont, theme: theme, onAction: onAction)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(attributed(content, font: font ?? theme.bodyFont)).lineSpacing(theme.lineSpacing).textSelection(
                    .enabled
                ).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        private func render(_ block: MarkdownBlock) -> AnyView {
            switch block {
            case .paragraph(let content):
                if content.count == 1, case .image(let image) = content[0], let imageContent {
                    return imageContent(image)
                }
                return AnyView(inline(content))
            case .heading(let level, let content):
                return AnyView(
                    inline(
                        content,
                        font: (theme.headingFonts.isEmpty
                            ? theme.bodyFont.bold()
                            : theme.headingFonts[min(max(level - 1, 0), theme.headingFonts.count - 1)])
                    ).accessibilityAddTraits(.isHeader))
            case .rule:
                return AnyView(Rectangle().fill(theme.rule).frame(height: 1).accessibilityLabel("Horizontal rule"))
            case .quote(let children):
                return AnyView(
                    HStack(alignment: .top, spacing: 14) { blocks(children) }.padding(.leading, 17).overlay(
                        alignment: .leading
                    ) { Rectangle().fill(theme.quoteBar).frame(width: 4) }.accessibilityIdentifier("markdown.quote"))
            case .list(let start, let items):
                return AnyView(
                    VStack(alignment: .leading, spacing: theme.listSpacing) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(item.checked.map { $0 ? "☑" : "☐" } ?? start.map { "\($0 + index)." } ?? "•").font(
                                    theme.bodyFont
                                ).frame(minWidth: 18, alignment: .trailing)
                                blocks(item.blocks)
                            }
                        }
                    }.accessibilityIdentifier("markdown.list"))
            case .code(let language, let content):
                return AnyView(ChatGPTCodeCard(language: language, content: content, theme: theme, onAction: onAction))
            case .table(let header, let rows, let alignments):
                return AnyView(
                    ScrollView(.horizontal) {
                        VStack(spacing: 0) {
                            tableRow(
                                header, widths: tableWidths(header: header, rows: rows), alignments: alignments,
                                header: true)
                            Rectangle().fill(theme.rule).frame(height: 1)
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                tableRow(
                                    row, widths: tableWidths(header: header, rows: rows), alignments: alignments,
                                    header: false)
                                Rectangle().fill(theme.rule).frame(height: 0.5)
                            }
                        }
                    }.accessibilityIdentifier("markdown.table"))
            case .unsupported(let kind, let source):
                if let unsupportedContent { return unsupportedContent(kind, source) }
                return AnyView(
                    Text(verbatim: source).font(theme.codeFont).textSelection(.enabled).contextMenu {
                        Button("Open content") { onAction(.unsupported(kind: kind, source: source)) }
                    })
            }
        }
        private func tableWidths(header: [[MarkdownInline]], rows: [[[MarkdownInline]]]) -> [CGFloat] {
            let weights = header.indices.map { index in
                CGFloat(
                    max(
                        5,
                        ([header] + rows).map { index < $0.count ? $0[index].map(\.plainText).joined().count : 0 }.max()
                            ?? 5))
            }
            let total = max(1, weights.reduce(0, +))
            return weights.map { max(72, availableWidth * $0 / total) }
        }
        private func tableRow(
            _ cells: [[MarkdownInline]], widths: [CGFloat], alignments: [MarkdownColumnAlignment], header: Bool
        ) -> some View {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                    let alignment = index < alignments.count ? alignments[index] : .left
                    Group {
                        if cell.contains(where: \.containsInlineCode) {
                            SelectableInlineCode(
                                content: cell, font: header ? theme.bodyFont.bold() : theme.bodyFont, theme: theme,
                                onAction: onAction,
                                alignment: alignment == .right ? .right : alignment == .center ? .center : .left)
                        } else {
                            Text(attributed(cell, font: header ? theme.bodyFont.bold() : theme.bodyFont)).textSelection(
                                .enabled
                            ).lineSpacing(theme.lineSpacing)
                        }
                    }.frame(
                        width: index < widths.count ? widths[index] : theme.tableColumnWidth,
                        alignment: alignment == .right ? .trailing : alignment == .center ? .center : .leading
                    ).padding(.vertical, 10)
                }
            }
        }
        private func attributed(
            _ children: [MarkdownInline], font: Font, bold: Bool = false, italic: Bool = false, strike: Bool = false
        ) -> AttributedString {
            var result = AttributedString()
            for child in children {
                var run = AttributedString()
                switch child {
                case .strong(let children):
                    run = attributed(children, font: font, bold: true, italic: italic, strike: strike)
                case .emphasis(let children):
                    run = attributed(children, font: font, bold: bold, italic: true, strike: strike)
                case .strikethrough(let children):
                    run = attributed(children, font: font, bold: bold, italic: italic, strike: true)
                case .link(let destination, let children):
                    run = attributed(children, font: font, bold: bold, italic: italic, strike: strike)
                    run.link = URL(string: destination)
                    run.foregroundColor = theme.link
                    run.underlineStyle = .single
                default:
                    let value: String
                    switch child {
                    case .image(let image): value = "▧ " + (image.alt.isEmpty ? "Image" : image.alt)
                    default: value = child.plainText
                    }
                    run = AttributedString(value)
                    var face = font
                    if case .code = child {
                        face = theme.codeFont
                        run.backgroundColor = theme.codeBackground
                    }
                    if bold { face = face.bold() }
                    if italic { face = face.italic() }
                    run.font = face
                    run.strikethroughStyle = strike ? .single : nil
                    if case .image(let image) = child {
                        run.link = MarkdownAction.image(image).presentationURL
                        run.foregroundColor = theme.link
                    }
                    if case .unsupported(let kind, let source) = child {
                        run.link = MarkdownAction.unsupported(kind: kind, source: source).presentationURL
                    }
                }
                result.append(run)
            }
            return result
        }
    }
    private struct ChatGPTCodeCard: View {
        let language: String?
        let content: String
        let theme: ChatGPTMarkdownTheme
        let onAction: (MarkdownAction) -> Void
        @State private var copied = false
        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(language?.capitalized ?? "").font(.system(size: 14))
                    Spacer()
                    Button {
                        onAction(.copyCode(content))
                        copied = true
                    } label: {
                        Group { if copied { Image(systemName: "checkmark") } else { ChatCopySymbol.image } }.font(
                            .system(size: 18)
                        ).frame(width: 26, height: 26)
                    }
                    .accessibilityIdentifier("markdown.code.copy").accessibilityLabel(
                        copied ? "Code copied" : "Copy code")
                }
                ScrollView(.horizontal) {
                    Text(highlighted).font(theme.codeFont).textSelection(.enabled).fixedSize(
                        horizontal: true, vertical: false
                    ).accessibilityIdentifier("markdown.code.content")
                }.scrollIndicators(.hidden)
            }.padding(16).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24))
                .overlay { RoundedRectangle(cornerRadius: 24).stroke(.secondary.opacity(0.1), lineWidth: 1) }
                .task(id: copied) {
                    guard copied else { return }
                    do { try await Task.sleep(for: .seconds(2)) } catch { return }
                    copied = false
                }
        }
        private var highlighted: AttributedString {
            let tokens = PythonCodePresentation.tokens(content, language: language)
            var result = AttributedString()
            for token in tokens {
                var run = AttributedString(token.text)
                run.font = theme.codeFont
                switch token.kind {
                case .plain: run.foregroundColor = .secondary
                case .keyword: run.foregroundColor = Color(red: 0.74, green: 0.44, blue: 0.8)
                case .string: run.foregroundColor = Color(red: 0.58, green: 0.71, blue: 0.4)
                case .interpolation: run.foregroundColor = Color(red: 0.9, green: 0.4, blue: 0.48)
                case .number: run.foregroundColor = .orange
                case .comment: run.foregroundColor = .gray
                }
                result.append(run)
            }
            return result
        }
    }
#endif
