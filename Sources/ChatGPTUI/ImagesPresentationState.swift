import Foundation
import Observation

public enum ImagesCategory: String, CaseIterable, Sendable { case templates = "Templates", trending = "Trending" }
public struct ImageTemplate: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var headline: String
    public var prompt: String
    public var artworkKey: String
    public var category: ImagesCategory
    public init(id: String, title: String, headline: String, prompt: String, artworkKey: String, category: ImagesCategory = .templates) {
        self.id = id; self.title = title; self.headline = headline; self.prompt = prompt; self.artworkKey = artworkKey; self.category = category
    }
}
public enum ImagesAction: Equatable, Sendable { case requestAttachment, requestDictation, submitPrompt(String, context: ChatComposerContext?), selectCategory(ImagesCategory), openTemplate(String), shareTemplate(String), tryTemplate(ImageTemplate), dismissLibraryNotice }
@MainActor @Observable public final class ImagesPresentationState {
    public var items: [ImageTemplate]
    public private(set) var category: ImagesCategory = .templates
    public private(set) var selectedID: String?
    public var showsLibraryNotice = true
    public var onAction: (ImagesAction) -> Void
    public init(items: [ImageTemplate] = [], onAction: @escaping (ImagesAction) -> Void = { _ in }) { self.items = items; self.onAction = onAction }
    public var visibleItems: [ImageTemplate] { items.filter { $0.category == category } }
    public var selected: ImageTemplate? { items.first { $0.id == selectedID } }
    public func selectCategory(_ value: ImagesCategory) { guard value != category else { return }; category = value; onAction(.selectCategory(value)) }
    public func open(_ id: String) { guard items.contains(where: { $0.id == id }) else { return }; selectedID = id; onAction(.openTemplate(id)) }
    public func close() { selectedID = nil }
    public func dismissNotice() { guard showsLibraryNotice else { return }; showsLibraryNotice = false; onAction(.dismissLibraryNotice) }
    public func shareSelected() { guard let selected else { return }; onAction(.shareTemplate(selected.id)) }
    public func submitPrompt(_ text: String, context: ChatComposerContext?) { let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmed.isEmpty else { return }; onAction(.submitPrompt(trimmed, context: context)) }
    public func trySelected() { guard let selected else { return }; selectedID = nil; onAction(.tryTemplate(selected)) }
}
