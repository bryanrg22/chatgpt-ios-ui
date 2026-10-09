#if os(iOS)
import SwiftUI
import UIKit

/// In-place native selection; UIKit supplies edit actions rather than a drawn
/// toolbar or custom Translate/Share command.
struct DotSelectableMessageText: UIViewRepresentable {
    let text: String
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false; view.isSelectable = true; view.isScrollEnabled = false
        view.backgroundColor = .clear; view.textColor = .label; view.font = .systemFont(ofSize: 17)
        view.textContainerInset = .zero; view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.accessibilityIdentifier = "dot.selectedText"
        let interaction = UIEditMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction); context.coordinator.interaction = interaction
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        guard view.text != text else { return }
        view.text = text
        let coordinator = context.coordinator
        DispatchQueue.main.async {
            guard view.window != nil else { return }
            view.becomeFirstResponder(); view.selectAll(nil); view.layoutIfNeeded()
            DispatchQueue.main.async {
                guard view.window != nil, let range = view.selectedTextRange else { return }
                let rect = view.firstRect(for: range)
                coordinator.interaction?.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: rect.midX, y: rect.minY)))
            }
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
    final class Coordinator: NSObject, UIEditMenuInteractionDelegate {
        var interaction: UIEditMenuInteraction?
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            return UIMenu(children: suggestedActions)
        }

    }
}
#endif
