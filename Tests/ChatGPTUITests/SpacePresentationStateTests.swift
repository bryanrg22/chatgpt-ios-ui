import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct SpacePresentationStateTests {
    @Test func emptyDefaultsHaveNoFabricatedDataOrImage() {
        let state = SpacePresentationState()
        #expect(state.items.isEmpty)
        #expect(state.visibleItems.isEmpty)
        #expect(state.activeImage == nil)
        #expect(state.loadState == .loaded)
    }
    @Test func tabsApplyKindsAndFavoritesWithoutReplacingItems() {
        let image = SpaceItem(title: "Garden", kind: .image, isFavorite: true)
        let page = SpaceItem(title: "Plan", kind: .page)
        let folder = SpaceItem(
            title: "Library", subtitle: "Connected", kind: .folder, origin: .connected, isSuggested: false)
        let state = SpacePresentationState(items: [image, page, folder])
        #expect(state.visibleItems.count == 2)
        state.chooseTab(.favorites)
        #expect(state.title == "Library")
        #expect(state.visibleItems == [image])
        state.chooseTab(.folders)
        #expect(state.visibleItems == [folder])
        state.chooseTab(.pages)
        #expect(state.visibleItems == [page])
        state.chooseTab(.images)
        #expect(state.visibleItems == [image])
        state.chooseTab(.all)
        #expect(state.visibleItems.count == 3)
        #expect(state.title == "Space")
    }
    @Test func searchTrimsWhitespaceAndMatchesTitleOrSubtitle() {
        let item = SpaceItem(title: "Garden plan", subtitle: "Saturday workshop", kind: .document)
        let state = SpacePresentationState(items: [item])
        state.query = "  GARDEN  "
        #expect(state.visibleItems == [item])
        state.query = "workshop"
        #expect(state.visibleItems == [item])
        state.query = "not present"
        #expect(state.visibleItems.isEmpty)
    }
    @Test func filterChangesAreExplicitAndToggleOff() {
        let upload = SpaceItem(title: "Photo", kind: .image)
        let generated = SpaceItem(title: "Sketch", kind: .image, origin: .generated)
        let pdf = SpaceItem(title: "Guide", kind: .pdf)
        let state = SpacePresentationState(items: [upload, generated, pdf])
        var events: [SpaceAction] = []
        state.onAction = { events.append($0) }
        state.chooseFilter(.generated)
        #expect(state.visibleItems == [generated])
        state.chooseFilter(.pdfs)
        #expect(state.visibleItems == [pdf])
        state.chooseFilter(.pdfs)
        #expect(state.visibleItems.count == 3)
        #expect(events == [.filterChanged(.generated), .filterChanged(.pdfs), .filterChanged(nil)])
    }
    @Test func onlyImagesOpenLocalViewerOtherItemsEmitHostIntent() {
        let doc = SpaceItem(title: "Guide", kind: .document)
        let image = SpaceItem(title: "View", kind: .image)
        let state = SpacePresentationState(items: [doc, image])
        var actions: [SpaceAction] = []
        state.onAction = { actions.append($0) }
        state.open(UUID())
        #expect(actions.isEmpty)
        state.open(doc.id)
        #expect(state.activeImage == nil)
        state.open(image.id)
        #expect(state.activeImage == image)
        state.closeImage()
        #expect(state.activeImage == nil)
        #expect(actions == [.openItem(doc.id), .openItem(image.id)])
    }
    @Test func replacingItemsDeduplicatesAndDismissesRemovedViewer() {
        let image = SpaceItem(title: "View", kind: .image)
        let state = SpacePresentationState(items: [image, image])
        #expect(state.items.count == 1)
        state.open(image.id)
        state.replaceItems([])
        #expect(state.activeImage == nil)
        #expect(state.activeImageID == nil)
    }
    @Test func favoriteChangesOnlyKnownItemAndRetainsViewer() {
        let image = SpaceItem(title: "View", kind: .image)
        let state = SpacePresentationState(items: [image])
        var actions: [SpaceAction] = []
        state.onAction = { actions.append($0) }
        state.open(image.id)
        state.toggleFavorite(UUID())
        state.toggleFavorite(image.id)
        #expect(state.activeImage?.isFavorite == true)
        state.toggleFavorite(image.id)
        #expect(state.activeImage?.isFavorite == false)
        #expect(actions == [.openItem(image.id), .favorite(image.id, true), .favorite(image.id, false)])
    }
    @Test func imageActionsDoNotInventModificationOrDeletionResults() {
        let image = SpaceItem(title: "View", kind: .image)
        let doc = SpaceItem(title: "Guide", kind: .document)
        let state = SpacePresentationState(items: [image, doc])
        var actions: [SpaceAction] = []
        state.onAction = { actions.append($0) }
        state.imageAction(.removeImage(doc.id))
        state.imageAction(.download(UUID()))
        state.imageAction(.createNote)
        state.imageAction(.editImage(image.id))
        state.imageAction(.resizeImage(image.id))
        state.imageAction(.download(image.id))
        state.imageAction(.removeImage(image.id))
        #expect(actions.count == 4)
        #expect(state.items == [image, doc])
    }
    @Test func loadingErrorAndSeparateSessionsPreserveHostData() {
        let item = SpaceItem(title: "Guide", kind: .document)
        let a = SpacePresentationState(items: [item], loadState: .loading)
        let b = SpacePresentationState()
        a.loadState = .failed(message: "Offline")
        #expect(a.items == [item])
        #expect(b.items.isEmpty)
        a.loadState = .loaded
        #expect(a.visibleItems == [item])
        #expect(b.loadState == .loaded)
    }
}
