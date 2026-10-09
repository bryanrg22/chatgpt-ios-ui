import Foundation
import Observation

/// Host-supplied recent media. This type never reads the device photo library.
@MainActor @Observable public final class PhotoPickerPresentationState {
    public var items: [ChatMedia] = []
    public var isPresented = false
    public private(set) var selectedIDs: [UUID] = []
    public init() {}
    public var selection: [ChatMedia] { selectedIDs.compactMap { id in items.first { $0.id == id } } }
    public var selectionButtonTitle: String {
        let selected = selection
        guard !selected.isEmpty else { return "All Photos" }
        let allVideos = selected.allSatisfy { $0.kind == .video }
        let allPhotos = selected.allSatisfy { $0.kind == .image }
        let noun = allVideos ? "video" : allPhotos ? "photo" : "item"
        return "Add \(selected.count) \(noun)\(selected.count == 1 ? "" : "s")"
    }
    public func toggle(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        if selectedIDs.contains(id) { selectedIDs.removeAll { $0 == id } } else { selectedIDs.append(id) }
    }
    public func close() {
        isPresented = false
        selectedIDs = []
    }
    public func takeSelection() -> [ChatMedia] {
        let result = selection
        close()
        return result
    }
}
