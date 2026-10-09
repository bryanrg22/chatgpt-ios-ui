import Foundation
import Observation

public enum SpaceTab: String, CaseIterable, Sendable { case suggested = "Suggested", favorites = "Favorites", folders = "Folders", pages = "Pages", images = "Images", all = "All" }
public enum SpaceLayout: String, Sendable { case grid = "Grid", list = "List" }
public enum SpaceItemKind: String, Sendable { case image, document, spreadsheet, presentation, pdf, page, folder }
public enum SpaceItemOrigin: String, Sendable { case uploaded, generated, connected }
public enum SpaceFilter: String, CaseIterable, Sendable {
    case uploaded = "Uploaded", generated = "Generated", images = "Images", documents = "Documents", spreadsheets = "Spreadsheets", presentations = "Presentations", pdfs = "PDFs"
}
public enum SpaceLoadState: Equatable, Sendable { case loaded, loading, failed(message: String) }
public struct SpaceItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String
    public var kind: SpaceItemKind
    public var origin: SpaceItemOrigin
    public var isFavorite: Bool
    public var isSuggested: Bool
    /// The host resolves this opaque key through SpaceView's imageProvider.
    public var imageKey: String?
    public init(id: UUID = UUID(), title: String, subtitle: String = "", kind: SpaceItemKind, origin: SpaceItemOrigin = .uploaded, isFavorite: Bool = false, isSuggested: Bool = true, imageKey: String? = nil) {
        self.id = id; self.title = title; self.subtitle = subtitle; self.kind = kind; self.origin = origin; self.isFavorite = isFavorite; self.isSuggested = isSuggested; self.imageKey = imageKey
    }
}
public enum SpaceAction: Equatable, Sendable {
    case openItem(UUID), favorite(UUID, Bool), download(UUID), editImage(UUID), resizeImage(UUID), removeImage(UUID)
    case createImage, createNote, createFolder, uploadFiles, selectItems, openPlugins, openDeleted, retry
    case filterChanged(SpaceFilter?), tabChanged(SpaceTab)
}
@MainActor @Observable public final class SpacePresentationState {
    public var tab: SpaceTab = .suggested
    public var layout: SpaceLayout = .grid
    public var query = ""
    public var filter: SpaceFilter?
    public var loadState: SpaceLoadState = .loaded
    public private(set) var items: [SpaceItem]
    public private(set) var activeImageID: UUID?
    public var onAction: (SpaceAction) -> Void = { _ in }
    public init(items: [SpaceItem] = [], loadState: SpaceLoadState = .loaded) {
        var seen = Set<UUID>(); self.items = items.filter { seen.insert($0.id).inserted }; self.loadState = loadState
    }
    public var title: String { tab == .favorites ? "Library" : "Space" }
    public var activeImage: SpaceItem? { items.first { $0.id == activeImageID && $0.kind == .image } }
    public var visibleItems: [SpaceItem] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            let inTab: Bool
            switch tab {
            case .suggested: inTab = item.isSuggested
            case .favorites: inTab = item.isFavorite
            case .folders: inTab = item.kind == .folder
            case .pages: inTab = item.kind == .page
            case .images: inTab = item.kind == .image
            case .all: inTab = true
            }
            let matchesFilter: Bool
            switch filter {
            case .uploaded: matchesFilter = item.origin == .uploaded
            case .generated: matchesFilter = item.origin == .generated
            case .images: matchesFilter = item.kind == .image
            case .documents: matchesFilter = item.kind == .document
            case .spreadsheets: matchesFilter = item.kind == .spreadsheet
            case .presentations: matchesFilter = item.kind == .presentation
            case .pdfs: matchesFilter = item.kind == .pdf
            case nil: matchesFilter = true
            }
            return inTab && matchesFilter && (search.isEmpty || item.title.localizedStandardContains(search) || item.subtitle.localizedStandardContains(search))
        }
    }
    public func chooseTab(_ value: SpaceTab) { tab = value; onAction(.tabChanged(value)) }
    public func chooseFilter(_ value: SpaceFilter) { filter = filter == value ? nil : value; onAction(.filterChanged(filter)) }
    public func replaceItems(_ replacement: [SpaceItem]) {
        var seen = Set<UUID>(); items = replacement.filter { seen.insert($0.id).inserted }
        if activeImage == nil { activeImageID = nil }
    }
    public func open(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        if item.kind == .image { activeImageID = id }
        onAction(.openItem(id))
    }
    public func closeImage() { activeImageID = nil }
    public func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle(); onAction(.favorite(id, items[index].isFavorite))
    }
    /// Only valid image identifiers emit image actions. Remove requests the
    /// eraser tool; this model never edits, uploads, or deletes an image.
    public func imageAction(_ action: SpaceAction) {
        let id: UUID
        switch action {
        case .download(let value), .editImage(let value), .resizeImage(let value), .removeImage(let value): id = value
        default: return
        }
        guard items.contains(where: { $0.id == id && $0.kind == .image }) else { return }
        onAction(action)
    }
}
