#if os(iOS)
    import SwiftUI
    import UIKit

    /// UIMenu's title supplies the native explanatory header that SwiftUI's single Section omits.
    struct NativeModelPicker: UIViewRepresentable {
        let selectedID: String
        let onSelect: (String) -> Void
        func makeUIView(context: Context) -> UIButton {
            let button = UIButton(type: .system)
            button.showsMenuAsPrimaryAction = true
            button.preferredMenuElementOrder = .fixed
            button.accessibilityIdentifier = "settings.model"
            return button
        }
        func updateUIView(_ button: UIButton, context: Context) {
            button.accessibilityLabel = "Model, " + SettingsPreferenceOptions.modelTitle(for: selectedID)
            button.menu = UIMenu(
                title: "Choose the model version\nused in Chat mode",
                children: SettingsPreferenceOptions.models.map { option in
                    UIAction(title: option.title, state: option.id == selectedID ? .on : .off) { _ in
                        onSelect(option.id)
                    }
                })
        }
    }
#endif
