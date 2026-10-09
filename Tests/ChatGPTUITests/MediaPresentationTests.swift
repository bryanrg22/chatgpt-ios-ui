import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct MediaPresentationTests {
    @Test func invalidAspectRatiosCannotEscapeThroughConstruction() {
        for value in [Double.nan, .infinity, -.infinity, 0, -1] {
            #expect(ChatMedia(imageKey: "opaque", aspectRatio: value).aspectRatio == 1)
        }
        #expect(ChatMedia(imageKey: "portrait", aspectRatio: 0.5).aspectRatio == 0.5)
        #expect(ChatMedia(imageKey: "panorama", aspectRatio: 5).aspectRatio == 5)
    }
    @Test func emptyViewerDoesNotEmitActionsOrExposeFavorite() {
        let state = MediaViewerState(isFavorite: true); var actions: [MediaAction] = []; state.onAction = { actions.append($0) }
        state.toggleChrome(); state.toggleFavorite(); state.dismiss(); state.perform(.download(UUID()))
        #expect(state.item == nil); #expect(!state.isFavorite); #expect(state.showsChrome); #expect(actions.isEmpty)
    }
    @Test func presentAndDismissResetTransientChromeAndFavorite() {
        let a = ChatMedia(imageKey: "a"); let b = ChatMedia(imageKey: "b")
        let state = MediaViewerState(); var actions: [MediaAction] = []; state.onAction = { actions.append($0) }
        state.present(a, isFavorite: true); state.toggleChrome()
        #expect(!state.showsChrome); #expect(state.item == a)
        state.present(b); #expect(state.showsChrome); #expect(!state.isFavorite)
        state.dismiss(); state.dismiss(); #expect(state.item == nil)
        #expect(actions == [.open(a.id), .open(b.id), .close(b.id)])
    }
    @Test func favoriteChangesLocallyAndDuplicateUpdatesDoNotEmit() {
        let item = ChatMedia(imageKey: "a"); let state = MediaViewerState(item: item)
        var actions: [MediaAction] = []; state.onAction = { actions.append($0) }
        state.toggleFavorite(); state.perform(.favorite(item.id, true)); state.toggleFavorite()
        #expect(!state.isFavorite); #expect(actions == [.favorite(item.id, true), .favorite(item.id, false)])
    }
    @Test func staleActionCannotCloseOrModifyNewlyPresentedItem() {
        let a = ChatMedia(imageKey: "a"); let b = ChatMedia(imageKey: "b")
        let state = MediaViewerState(item: b); var actions: [MediaAction] = []; state.onAction = { actions.append($0) }
        for action in [MediaAction.close(a.id), .copy(a.id), .favorite(a.id, true), .edit(a.id), .resize(a.id), .remove(a.id), .download(a.id)] { state.perform(action) }
        #expect(actions.isEmpty); #expect(state.item == b); #expect(!state.isFavorite)
    }
    @Test func hostIntentsDoNotInventFileWritesEditorResultsOrDeletion() {
        let item = ChatMedia(imageKey: "opaque"); let state = MediaViewerState(item: item)
        var emitted: [MediaAction] = []; state.onAction = { emitted.append($0) }
        let requested: [MediaAction] = [.copy(item.id), .download(item.id), .edit(item.id), .resize(item.id), .remove(item.id)]
        for action in requested { state.perform(action) }
        #expect(emitted == requested); #expect(state.item == item); #expect(state.showsChrome)
        state.perform(.close(item.id)); #expect(state.item == nil); #expect(emitted.last == .close(item.id))
    }
}
