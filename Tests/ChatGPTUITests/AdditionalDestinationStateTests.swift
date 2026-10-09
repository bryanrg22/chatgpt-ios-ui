import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct AdditionalDestinationStateTests {
    @Test func invalidTaskDoesNotChangeListOrSelection() {
        var presentation = ScheduledPresentationState(tasks: [])
        presentation.selectedTab = "Paused"
        for draft in [
            ScheduledTaskPresentation(title: " \n ", instructions: "Valid instructions"),
            ScheduledTaskPresentation(title: "Valid name", instructions: "\t "),
            ScheduledTaskPresentation(title: "Valid name", instructions: "Valid instructions", interval: 0)
        ] {
            let accepted = presentation.save(draft)
            #expect(!accepted)
            #expect(presentation.tasks.isEmpty)
            #expect(presentation.selectedTab == "Paused")
        }
    }

    @Test func saveTrimsAndEditingReplacesSameIdentity() {
        var presentation = ScheduledPresentationState(tasks: [])
        var draft = ScheduledTaskPresentation(title: "  Reading reminder\n", instructions: "  Read a chapter.  ")
        let firstSave = presentation.save(draft)
        #expect(firstSave)
        #expect(presentation.tasks.first?.title == "Reading reminder")
        #expect(presentation.tasks.first?.instructions == "Read a chapter.")
        draft.title = "Updated reminder"
        draft.notify = false
        draft.time = "Evening"
        let updatedSave = presentation.save(draft)
        #expect(updatedSave)
        #expect(presentation.tasks.count == 1)
        #expect(presentation.tasks.first?.id == draft.id)
        #expect(presentation.tasks.first?.title == "Updated reminder")
        #expect(presentation.tasks.first?.notify == false)
        #expect(presentation.tasks.first?.time == "Evening")
    }

    @Test func cancelledEditorCopyLeavesOriginalUnchanged() {
        let original = ScheduledTaskPresentation(title: "Original", instructions: "Original instructions", emoji: "📚")
        let presentation = ScheduledPresentationState(tasks: [original])
        var unsavedDraft = presentation.tasks[0]
        unsavedDraft.title = "Discard this edit"
        unsavedDraft.notify = false
        unsavedDraft.emoji = "🌱"
        unsavedDraft.repeatRule = "Monthly"
        #expect(presentation.tasks == [original])
        #expect(unsavedDraft != original)
    }

    @Test func navigationPreservesCreatedDeletedTasksAndSelectedTab() {
        let state = ChatState()
        state.open(.scheduled)
        let removedID = state.scheduled.tasks[0].id
        state.scheduled.delete(id: removedID)
        let saved = ScheduledTaskPresentation(
            title: "Persistent local task", instructions: "Keep this fixture", status: "Paused")
        let accepted = state.scheduled.save(saved)
        #expect(accepted)
        state.open(.chat)
        state.open(.settings)
        state.open(.scheduled)
        #expect(state.scheduled.tasks.contains { $0.id == saved.id })
        #expect(!state.scheduled.tasks.contains { $0.id == removedID })
        #expect(state.scheduled.selectedTab == "Paused")
        #expect(state.scheduled.visibleTasks.allSatisfy { $0.status == "Paused" })
    }

    @Test func independentSessionsDoNotShareTaskMutations() {
        let first = ChatState()
        let second = ChatState()
        let removed = first.scheduled.tasks[0].id
        first.scheduled.delete(id: removed)
        #expect(second.scheduled.tasks.contains { $0.id == removed })
        #expect(!first.scheduled.tasks.contains { $0.id == removed })
    }

    @Test func searchCombinesTrimmedQueryAndCategoryWithoutEmptyQueryResults() {
        #expect(SearchFixture.matching(query: " \n ", category: "All").isEmpty)
        let images = SearchFixture.matching(query: "  DESIGN  ", category: "Images")
        #expect(images.count == 1)
        #expect(images.first?.id == "design-image")
        #expect(SearchFixture.matching(query: "museum", category: "Chats").first?.id == "weekend")
        #expect(SearchFixture.matching(query: "museum", category: "Images").isEmpty)
        #expect(SearchFixture.matching(query: "unmatched-string-123", category: "All").isEmpty)
    }

    @Test func queryAndCategorySurviveNavigationTogether() {
        let state = ChatState()
        state.search = "design"
        state.searchCategory = "Pages"
        state.open(.scheduled)
        state.open(.chat)
        #expect(state.search == "design")
        #expect(state.searchCategory == "Pages")
        #expect(
            SearchFixture.matching(query: state.search, category: state.searchCategory).map(\.id) == ["design-notes"])
    }
}
