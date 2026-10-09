import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct CodexPresentationStateTests {
    @Test func invalidSubmissionDoesNotCreateTaskOrEmitAction() {
        let state = CodexPresentationState(tasks: []); var events: [CodexUIAction] = []; state.onAction = { events.append($0) }
        state.draft = " \n "; let accepted = state.send()
        #expect(!accepted); #expect(state.tasks.isEmpty); #expect(events.isEmpty)
    }
    @Test func projectTaskAndFollowupKeepIdentityAndEmitTypedActions() {
        let state = CodexPresentationState(tasks: []); var events: [CodexUIAction] = []; state.onAction = { events.append($0) }
        state.newTask(project: "SampleApp"); state.draft = "  Review the layout  "; let created = state.send()
        #expect(created); let id = state.selectedTaskID!
        #expect(state.selectedTask?.project == "SampleApp"); #expect(state.selectedTask?.title == "Review the layout"); #expect(state.draft.isEmpty)
        #expect(events == [.submit(taskID: id, text: "Review the layout", project: "SampleApp")])
        state.draft = "Preserve this followup"; let whileRunning = state.send(); #expect(!whileRunning); #expect(state.draft == "Preserve this followup")
        state.stop(); let followedUp = state.send(); #expect(followedUp); #expect(state.tasks.count == 1); #expect(state.selectedTaskID == id); #expect(state.selectedTask?.messages.count == 2)
    }
    @Test func filtersTrimMatchProjectAndPriorityKeepsIdleTasks() {
        let first = CodexTaskFixture(title: "Draft plan", project: "Notebook")
        let second = CodexTaskFixture(title: "Review interface", isRunning: true)
        let state = CodexPresentationState(tasks: [first, second]); state.query = "  NOTEBOOK \n"
        #expect(state.visibleTasks == [first]); state.query = "missing"; #expect(state.visibleTasks.isEmpty)
        state.query = ""; state.grouping = .priority; #expect(state.visibleTasks == [second, first])
    }
    @Test func navigationDoesNotLoseTasksOrConnectionSelections() {
        let state = CodexPresentationState(tasks: []); state.newTask(project: "Example"); state.draft = "Keep this task"; _ = state.send(); let id = state.selectedTaskID!
        state.disconnectAll(); state.goHome(); state.openTask(id)
        #expect(state.selectedTask?.title == "Keep this task"); #expect(!state.cloudConnected); #expect(!state.desktopConnected)
        state.toggleProject("Example"); #expect(!state.expandedProjects.contains("Example")); state.toggleProject("Example"); #expect(state.expandedProjects.contains("Example"))
    }
    @Test func invalidSelectionAndRepeatedStopHaveNoSideEffects() {
        let fixture = CodexTaskFixture(title: "Active", isRunning: true); let state = CodexPresentationState(tasks: [fixture]); var events: [CodexUIAction] = []; state.onAction = { events.append($0) }
        state.openTask(fixture.id); state.openTask(UUID()); #expect(state.selectedTaskID == fixture.id)
        state.stop(); state.stop(); #expect(events == [.stop(fixture.id)])
    }
    @Test func independentSessionsDoNotShareState() {
        let one = CodexPresentationState(); let two = CodexPresentationState(); one.disconnectAll(); one.grouping = .chronological
        #expect(two.cloudConnected); #expect(two.grouping == .project)
    }
    @Test func archivedRestoreMovesExactlyOnceAndPersistsInHome() {
        let state = CodexPresentationState(tasks: []); let archived = state.archivedTasks[0]
        state.restoreArchived(UUID()); #expect(state.tasks.isEmpty)
        state.restoreArchived(archived.id); state.restoreArchived(archived.id)
        #expect(state.archivedTasks.isEmpty); #expect(state.tasks == [archived])
        state.openTask(archived.id); state.goHome(); #expect(state.tasks == [archived])
    }

    @Test func pairingValidatesWithoutChangingConnectionsOrRetainingCode() {
        let state = CodexPresentationState(); state.disconnectAll(); var events: [CodexUIAction] = []; state.onAction = { events.append($0) }
        let empty = state.requestPairing(" \n "); #expect(!empty); #expect(events.isEmpty)
        let supplied = state.requestPairing("  DEMO-1234  "); #expect(supplied)
        #expect(events == [.pair(code: "DEMO-1234")]); #expect(!state.cloudConnected); #expect(!state.desktopConnected)
    }

    @Test func hostResponseUpdatesOnlyTargetWithoutEmittingUserAction() {
        let task = CodexTaskFixture(title: "Review"); let state = CodexPresentationState(tasks: [task]); var actions: [CodexUIAction] = []; state.onAction = { actions.append($0) }
        let missing = state.updateTask(UUID(), response: "No", activities: [], isRunning: false); #expect(!missing)
        let updated = state.updateTask(task.id, response: "Host response", activities: ["Read sample file"], isRunning: false); #expect(updated)
        #expect(state.tasks[0].response == "Host response"); #expect(state.tasks[0].activities == ["Read sample file"]); #expect(actions.isEmpty)
    }

}
