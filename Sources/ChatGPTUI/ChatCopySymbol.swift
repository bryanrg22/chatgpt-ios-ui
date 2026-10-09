#if canImport(UIKit)
    import SwiftUI
    import UIKit

    /// Captured Copy marks put the foreground square at bottom-left.
    /// A public UIImage orientation preserves the SF template for native menu rendering.
    @MainActor enum ChatCopySymbol {
        private static let symbol = (UIImage(systemName: "square.on.square") ?? UIImage())
            .withHorizontallyFlippedOrientation()
        static var image: Image { Image(uiImage: symbol).renderingMode(.template) }
    }
#endif
