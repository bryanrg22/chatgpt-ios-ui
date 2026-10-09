import Testing
@testable import ChatGPTUI

@Suite struct InlineCodeRoutingTests {
    @Test func nestedCodeChoosesSelectableDecorationWithoutChangingPlainText() {
        let value = MarkdownInline.link(destination: "https://example.com", children: [.strong([.text("Use "), .code("soil🙂")])])
        #expect(value.containsInlineCode)
        #expect(value.plainText == "Use soil🙂")
        #expect(!MarkdownInline.strong([.text("`not parsed code`")]).containsInlineCode)
        #expect(!MarkdownInline.image(.init(source: "local", alt: "code")).containsInlineCode)
        #expect(MarkdownInline.code("").containsInlineCode)
    }
}

@Suite struct InlineCodeTableTests {
    @Test func tableRetainsAlignmentCodeAndLinkWithoutPaddingSource() {
        let document = MarkdownDocumentModel(source: "| Left | Center | Right |\n| :--- | :---: | ---: |\n| `mint🙂` [guide](https://example.com) | **`water_seedlings_gently`** | `sun` |")
        guard case .table(let header, let rows, let alignments) = document.blocks.first else { Issue.record("Missing table"); return }
        #expect(header.count == 3); #expect(rows.count == 1)
        guard case .left = alignments[0], case .center = alignments[1], case .right = alignments[2] else { Issue.record("Lost column alignment"); return }
        #expect(rows[0].allSatisfy { $0.contains(where: \.containsInlineCode) })
        #expect(rows[0][0].map(\.plainText).joined() == "mint🙂 guide")
        #expect(rows[0][1].map(\.plainText).joined() == "water_seedlings_gently")
    }
}
