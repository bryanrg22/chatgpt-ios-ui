import Foundation
import Observation

public enum ProjectMemory: String, CaseIterable, Sendable { case standard, projectOnly }
public struct ProjectDraft: Equatable, Sendable {
    public var name = ""
    public var symbol = "folder"
    public var hasCustomIcon = false
    public var color = "Default"
    public var memory: ProjectMemory = .standard
    public init() {}
}
public enum ProjectsAction: Equatable, Sendable { case search(String), create(ProjectDraft) }

@MainActor @Observable public final class ProjectsPresentationState {
    public var query = "" { didSet { if oldValue != query { onAction(.search(query)) } } }
    public var isCreating = false
    public var isSubmitting = false
    public var showsMemorySettings = false
    public var draft = ProjectDraft()
    public var showsIconPicker = false
    public var pendingSymbol = "folder"
    public var pendingColor = "Default"
    public var pendingMemory: ProjectMemory = .standard
    public var onAction: (ProjectsAction) -> Void = { _ in }
    public init() {}
    public var canCreate: Bool { !isSubmitting && !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public func beginCreation() {
        draft = .init()
        isSubmitting = false
        isCreating = true
    }
    public func cancelCreation() {
        isCreating = false
        isSubmitting = false
        showsMemorySettings = false
        showsIconPicker = false
        draft = .init()
    }
    public func openMemorySettings() {
        pendingMemory = draft.memory
        showsMemorySettings = true
    }
    public func closeMemorySettings(save: Bool) {
        if save { draft.memory = pendingMemory }
        showsMemorySettings = false
    }
    public var iconHasChanges: Bool { pendingSymbol != draft.symbol || pendingColor != draft.color }
    public func openIconPicker() {
        pendingSymbol = draft.symbol
        pendingColor = draft.color
        showsIconPicker = true
    }
    public func closeIconPicker(save: Bool) {
        if save {
            draft.symbol = pendingSymbol
            draft.color = pendingColor
            draft.hasCustomIcon = true
        }
        showsIconPicker = false
    }
    public func selectSuggestion(_ name: String, symbol: String, color: String) {
        draft.name = name
        draft.symbol = symbol
        draft.color = color
        draft.hasCustomIcon = true
    }
    @discardableResult public func submit() -> Bool {
        guard isCreating, canCreate else { return false }
        var value = draft
        value.name = value.name.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmitting = true
        onAction(.create(value))
        return true
    }
}
