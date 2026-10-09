#if os(iOS)
import SwiftUI
import UIKit

/// UIKit's text layout supplies the intrinsic height and scrolling behavior; no character-count sizing.
struct ComposerTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var focused: Bool
    var autocorrect: Bool
    var tint: Color
    var maximumHeight: CGFloat = 186
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textColor = .label
        view.font = .systemFont(ofSize: 17)
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.contentInset = .zero
        view.delegate = context.coordinator
        view.accessibilityIdentifier = "messageComposer"
        view.accessibilityLabel = "Message"
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        let paragraph = NSMutableParagraphStyle(); paragraph.minimumLineHeight = 24; paragraph.maximumLineHeight = 24
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.label, .paragraphStyle: paragraph]
        if view.text != text { view.attributedText = NSAttributedString(string: text, attributes: attributes) }
        view.tintColor = UIColor(tint)
        view.autocorrectionType = autocorrect ? .yes : .no
        view.typingAttributes = attributes
        if focused && !view.isFirstResponder { view.becomeFirstResponder() }
        if !focused && view.isFirstResponder { view.resignFirstResponder() }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let content = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = min(maximumHeight, max(25, ceil(content.height)))
        uiView.isScrollEnabled = content.height > maximumHeight
        return CGSize(width: width, height: height)
    }
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposerTextView
        init(parent: ComposerTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            textView.invalidateIntrinsicContentSize()
        }
        func textViewDidBeginEditing(_ textView: UITextView) { parent.focused = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.focused = false }
    }
}
#endif
