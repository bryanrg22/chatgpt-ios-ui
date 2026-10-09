import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct ChatMediaStateTests {
    @Test func mediaOnlySendCarriesIdentityAndClearsDraft() {
        var actions: [ChatAction] = []
        let state = ChatState { actions.append($0) }
        let media = ChatMedia(imageKey: "host-a", title: "Host image", aspectRatio: 0.9)
        state.addMedia(media)
        #expect(state.canSend)
        let response = state.send()
        #expect(response != nil)
        #expect(state.media.isEmpty)
        #expect(state.messages.first?.media == [media])
        #expect(actions.last == .send(text: "", attachments: [], thinkHarder: true, media: [media]))
    }
    @Test func editCancellationRestoresUnsentMediaAndRemovalIsLocal() {
        let state = ChatState()
        let sent = ChatMedia(imageKey: "sent")
        let draft = ChatMedia(imageKey: "draft")
        let message = ChatMessage(role: .user, text: "First", media: [sent])
        state.messages = [message]
        state.draft = "Unsent"
        state.addMedia(draft)
        state.beginEditing(message)
        #expect(state.media == [sent])
        state.removeMedia(sent.id)
        state.cancelEditing()
        #expect(state.media == [draft])
        #expect(state.draft == "Unsent")
        #expect(state.messages.first?.media == [sent])
        state.newChat()
        #expect(state.media.isEmpty)
    }
    @Test func retiredMessagesCloseTheirMediaViewer() {
        let state = ChatState()
        let image = ChatMedia(imageKey: "later")
        let response = ChatMessage(role: .assistant, text: "First reply")
        state.messages = [
            .init(role: .user, text: "First"), response, .init(role: .user, text: "Later", media: [image])
        ]
        state.mediaViewer.present(image)
        state.retry(response.id)
        #expect(state.mediaViewer.item == nil)
    }
    @Test func pickerSelectionIsOrderedCancellableAndHostRemovalSafe() {
        let state = PhotoPickerPresentationState()
        let a = ChatMedia(imageKey: "a")
        let b = ChatMedia(imageKey: "b")
        state.items = [a, b]
        state.toggle(b.id)
        state.toggle(a.id)
        #expect(state.selection == [b, a])
        state.toggle(b.id)
        #expect(state.selection == [a])
        state.items = [b]
        #expect(state.selection.isEmpty)
        state.toggle(b.id)
        let result = state.takeSelection()
        #expect(result == [b])
        #expect(state.selectedIDs.isEmpty)
        state.isPresented = true
        state.toggle(b.id)
        state.close()
        #expect(!state.isPresented)
        #expect(state.selection.isEmpty)
    }
    @Test func selectionTitleTracksMediaKindAndHostRemoval() {
        let state = PhotoPickerPresentationState()
        let image = ChatMedia(imageKey: "image")
        let video = ChatMedia(imageKey: "video", kind: .video, durationSeconds: 8)
        state.items = [image, video]
        #expect(state.selectionButtonTitle == "All Photos")
        state.toggle(video.id)
        #expect(state.selectionButtonTitle == "Add 1 video")
        state.toggle(image.id)
        #expect(state.selectionButtonTitle == "Add 2 items")
        state.items = [image]
        #expect(state.selectionButtonTitle == "Add 1 photo")
    }
    @Test func videoCardPresentationIsExplicitAndCleansRetiredTurns() {
        let state = ChatState()
        let a = ChatMedia(imageKey: "a", kind: .video)
        let b = ChatMedia(imageKey: "b", kind: .video)
        #expect(state.videoCardPresentation(for: a).showsPlayAffordance)
        state.videoCardPresentations[a.id] = .hostPreview
        #expect(!state.videoCardPresentation(for: a).showsPlayAffordance)
        #expect(state.videoCardPresentation(for: b).showsPlayAffordance)
        state.openMedia(a)
        state.mediaViewer.dismiss()
        #expect(state.videoCardPresentation(for: a) == .hostPreview)
        let response = ChatMessage(role: .assistant, text: "Reply")
        state.messages = [.init(role: .user, text: "First"), response, .init(role: .user, text: "Later", media: [a])]
        state.retry(response.id)
        #expect(state.videoCardPresentations[a.id] == nil)
        state.videoCardPresentations[b.id] = .hostPreview
        state.newChat()
        #expect(state.videoCardPresentations.isEmpty)
    }
}
