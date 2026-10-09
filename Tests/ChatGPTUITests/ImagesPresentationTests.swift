import Testing
@testable import ChatGPTUI

@MainActor @Suite struct ImagesPresentationTests {
    private var poster: ImageTemplate { .init(id: "poster", title: "Poster", headline: "Design a poster", prompt: "Make a garden poster.", artworkKey: "poster") }
    @Test func emptyAndInjectedCatalogHaveNoFallbackData() {
        let state = ImagesPresentationState()
        #expect(state.visibleItems.isEmpty)
        state.items = [poster, .init(id: "trend", title: "Trend", headline: "Trend", prompt: "New prompt", artworkKey: "trend", category: .trending)]
        #expect(state.visibleItems == [poster])
        state.selectCategory(.trending)
        #expect(state.visibleItems.map(\.id) == ["trend"])
        state.items = []
        #expect(state.visibleItems.isEmpty)
    }
    @Test func selectionAndTryAreHostIntents() {
        var actions: [ImagesAction] = []
        let state = ImagesPresentationState(items: [poster]) { actions.append($0) }
        state.open("missing"); #expect(state.selected == nil); #expect(actions.isEmpty)
        state.open("poster"); state.shareSelected(); state.trySelected(); state.trySelected()
        #expect(actions == [.openTemplate("poster"), .shareTemplate("poster"), .tryTemplate(poster)])
        #expect(state.selected == nil)
        #expect(state.items == [poster])
    }
    @Test func removedSelectionCannotSubmitAndWhitespaceIsIgnored() {
        var actions: [ImagesAction] = []
        let state = ImagesPresentationState(items: [poster]) { actions.append($0) }
        state.open("poster"); actions = []; state.items = []
        state.trySelected(); state.shareSelected(); state.submitPrompt(" \n", context: nil)
        #expect(actions.isEmpty)
        state.submitPrompt("  A garden poster ", context: .sites)
        #expect(actions == [.submitPrompt("A garden poster", context: .sites)])
        state.dismissNotice(); state.dismissNotice()
        #expect(actions.last == .dismissLibraryNotice)
        #expect(actions.count == 2)
    }
}
