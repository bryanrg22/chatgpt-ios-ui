import Testing
@testable import ChatGPTUI

@Suite @MainActor struct ExplorePresentationTests {
    @Test func expansionStaysInDrawerAndPreservesDraftAndPage() {
        var actions: [ChatAction] = []
        let state = ChatState { actions.append($0) }
        state.page = .dot; state.draft = "Keep this"; state.showsDrawer = true
        state.open(.explore)
        #expect(state.explore.isExpanded); #expect(state.showsDrawer)
        #expect(state.page == .dot); #expect(state.draft == "Keep this"); #expect(actions.isEmpty)
        state.open(.sites); #expect(!state.showsDrawer); #expect(state.explore.isExpanded)
    }
    @Test func siteCreationPreparesWorkDraftWithoutSending() {
        var actions: [ChatAction] = []; var requests: [ExploreAction] = []
        let state = ChatState { actions.append($0) }; state.explore.onAction = { requests.append($0) }
        state.createSiteDraft()
        #expect(state.page == .work); #expect(state.composerContext == .sites)
        #expect(state.draft == "Create a website that ..."); #expect(state.messages.isEmpty)
        #expect(state.responseID == nil); #expect(requests == [.createSite]); #expect(actions == [.newChat])
        state.draft = "Build a garden site"; let response = state.send()
        #expect(response != nil); #expect(state.messages.first?.context == .sites)
        #expect(actions.last == .send(text: "Build a garden site", attachments: [], thinkHarder: true, context: .sites))
    }
    @Test func queryChangesEmitOnlyChangedHostRequests() {
        var actions: [ExploreAction] = []; let state = ExplorePresentationState()
        state.onAction = { actions.append($0) }; state.sitesQuery = "Garden"; state.sitesQuery = "Garden"; state.sitesQuery = ""
        #expect(actions == [.searchSites("Garden"), .searchSites("")])
    }
    @Test func messageEditingRestoresPriorComposerContextOnCancel() {
        let state = ChatState(); let message = ChatMessage(role: .user, text: "Plain", context: nil)
        state.messages = [message]; state.composerContext = .sites; state.draft = "Unsent site"
        state.beginEditing(message); #expect(state.composerContext == nil)
        state.cancelEditing(); #expect(state.composerContext == .sites); #expect(state.draft == "Unsent site")
        state.newChat(); #expect(state.composerContext == nil)
    }
}
