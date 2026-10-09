import Testing
@testable import ChatGPTUI

@Suite @MainActor struct ProjectsPresentationTests {
    @Test func creationRequiresNameAndEmitsOnlyOnceUntilHostCompletes() {
        let state = ProjectsPresentationState(); var actions: [ProjectsAction] = []
        state.onAction = { actions.append($0) }; state.beginCreation()
        let empty = state.submit(); #expect(!empty)
        state.draft.name = "  Garden  "; let sent = state.submit(); let duplicate = state.submit()
        #expect(sent); #expect(!duplicate); #expect(state.isCreating); #expect(state.isSubmitting)
        var expected = ProjectDraft(); expected.name = "Garden"; #expect(actions == [.create(expected)])
        state.cancelCreation(); #expect(!state.isSubmitting); #expect(state.draft.name.isEmpty)
    }
    @Test func memorySettingsCancelAndDoneAreTransactional() {
        let state = ProjectsPresentationState(); state.beginCreation()
        state.openMemorySettings(); state.pendingMemory = .projectOnly; state.closeMemorySettings(save: false)
        #expect(state.draft.memory == .standard)
        state.openMemorySettings(); state.pendingMemory = .projectOnly; state.closeMemorySettings(save: true)
        #expect(state.draft.memory == .projectOnly)
    }
    @Test func iconDraftPreservesSelectionOnCancelAndCommitsOnDone() {
        let state = ProjectsPresentationState(); state.beginCreation(); state.openIconPicker()
        #expect(!state.iconHasChanges); state.pendingColor = "Blue"; state.pendingSymbol = "brain"
        #expect(state.iconHasChanges); state.closeIconPicker(save: false)
        #expect(state.draft.symbol == "folder"); #expect(!state.draft.hasCustomIcon)
        state.openIconPicker(); state.pendingColor = "Blue"; state.pendingSymbol = "brain"; state.closeIconPicker(save: true)
        #expect(state.draft.symbol == "brain"); #expect(state.draft.color == "Blue"); #expect(state.draft.hasCustomIcon)
        state.selectSuggestion("Writing", symbol: "pencil.tip", color: "Purple")
        #expect(state.draft.name == "Writing"); #expect(state.draft.color == "Purple")
    }
}
