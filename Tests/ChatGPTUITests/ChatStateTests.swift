import Testing
@testable import ChatGPTUI

@Suite @MainActor struct ChatStateTests {
    @Test func whitespaceDoesNotSend() {
        let state = ChatState(); state.draft = " \n "
        #expect(!state.canSend); #expect(state.send() == nil); #expect(state.messages.isEmpty)
    }
    @Test func attachmentsCanSendWithoutText() {
        var actions: [ChatAction] = []
        let state = ChatState { actions.append($0) }; state.addAttachment("Example.pdf")
        #expect(state.canSend); let id = state.send()
        #expect(id != nil); #expect(state.messages.first?.attachments == ["Example.pdf"])
        #expect(state.attachments.isEmpty); #expect(state.composerMode == .responding)
        #expect(actions.last == .send(text: "", attachments: ["Example.pdf"], thinkHarder: true))
    }
    @Test func staleStreamCannotOverwriteNewConversation() {
        let state = ChatState(); state.draft = "First"
        let first = state.send()!; state.stop(); state.newChat(); state.draft = "Second"
        let second = state.send()!
        state.updateResponse(id: first, text: "Stale", finished: true)
        #expect(state.responseID == second); #expect(state.messages.last?.text == "")
        state.updateResponse(id: second, text: "Current", finished: true)
        #expect(state.messages.last?.text == "Current"); #expect(state.composerMode == .idle)
    }
    @Test func stopRetainsPartialResponseAndDraft() {
        let state = ChatState(); state.draft = "Hello"; let id = state.send()!
        state.updateResponse(id: id, text: "Partial"); state.draft = "Next question"; state.stop()
        state.updateResponse(id: id, text: "Late update", finished: true)
        #expect(state.messages.last?.text == "Partial"); #expect(state.draft == "Next question")
    }
    @Test func dictationCancelsWithoutLosingDraft() {
        let state = ChatState(); state.draft = "Existing"
        state.beginDictation(); #expect(!state.canSend); state.finishDictation()
        #expect(state.draft == "Existing"); state.beginDictation(); state.finishDictation(transcript: "added words")
        #expect(state.draft == "Existing added words"); #expect(state.composerMode == .idle)
    }
    @Test func feedbackIsExclusiveAndCanToggleOff() {
        let state = ChatState(); let message = ChatMessage(role: .assistant, text: "Hello")
        state.messages = [message]; state.setFeedback(.positive, for: message.id)
        #expect(state.feedback[message.id] == .positive)
        state.setFeedback(.negative, for: message.id); #expect(state.feedback[message.id] == .negative)
        state.setFeedback(.negative, for: message.id); #expect(state.feedback[message.id] == nil)
    }
    @Test func retryRetiresLaterTurnsAndOldStream() {
        let state = ChatState(); state.draft = "Hello"; let old = state.send()!
        state.updateResponse(id: old, text: "First answer", finished: true)
        state.draft = "Followup"; let later = state.send()!
        state.updateResponse(id: later, text: "Later answer", finished: true)
        state.retry(old)
        #expect(state.messages.count == 2); #expect(state.responseID != old)
        state.updateResponse(id: old, text: "Late old data")
        #expect(state.messages.last?.text == "")
    }
    @Test func navigationPreservesComposerDraftAndSelection() {
        let state = ChatState(); state.draft = "Draft"; state.thinkHarder = false
        state.open(.settings); state.open(.chat)
        #expect(state.draft == "Draft"); #expect(!state.thinkHarder)
    }
    @Test func busyComposerPreventsDuplicateSendAndDictation() {
        let state = ChatState(); state.draft = "Hello"; state.send(); state.draft = "Second"
        #expect(state.send() == nil); state.beginDictation(); #expect(state.composerMode == .responding)
        #expect(state.messages.count == 2)
    }
    @Test func retryCleansRemovedMessageTransientState() {
        var actions: [ChatAction] = []
        let state = ChatState { actions.append($0) }; state.draft = "Question"; let old = state.send()!
        state.updateResponse(id: old, text: "Answer", finished: true)
        let answer = state.messages.last!; state.setFeedback(.positive, for: old); state.copyMessage(answer); state.toggleReadAloud(old)
        state.readAloudElapsed = 12; state.retry(old)
        #expect(state.feedback[old] == nil); #expect(state.copiedMessage == nil)
        #expect(state.speakingMessage == nil); #expect(!state.readAloudPlaying); #expect(state.readAloudElapsed == 0)
        #expect(actions.last == .retry(originalID: old, responseID: state.responseID!))
    }
    @Test func newChatResetsTransientMediaState() {
        let state = ChatState(); let message = ChatMessage(role: .assistant, text: "Hello")
        state.messages = [message]; state.toggleReadAloud(message.id); state.readAloudElapsed = 4
        state.dictationLevels = [0.7]; state.camera.open(); state.camera.beginScan(); state.newChat()
        #expect(state.speakingMessage == nil); #expect(!state.readAloudPlaying); #expect(state.readAloudElapsed == 0)
        #expect(state.dictationLevels.isEmpty); #expect(!state.camera.isPresented); #expect(!state.camera.scanning)
    }
    @Test func editingRestoresDraftAttachmentsOnCancel() {
        let state = ChatState(); let user = ChatMessage(role: .user, text: "Old", attachments: ["Old.jpg"])
        state.messages = [user]; state.attachments = ["Draft.pdf"]; state.draft = "Unsent"
        state.beginEditing(user); #expect(state.attachments == ["Old.jpg"])
        state.addAttachment("Edit.jpg"); state.cancelEditing()
        #expect(state.attachments == ["Draft.pdf"]); #expect(state.draft == "Unsent")
    }
    @Test func cameraCyclesFlashAndBackExitsScanFirst() {
        let camera = CameraPresentationState(); camera.open(); camera.cycleFlash(); #expect(camera.flash == .auto)
        camera.cycleFlash(); #expect(camera.flash == .on); camera.cycleFlash(); #expect(camera.flash == .off)
        camera.beginScan(); camera.back(); #expect(!camera.scanning); #expect(camera.isPresented)
        camera.back(); #expect(!camera.isPresented)
    }
    @Test func editingCancelRestoresUnsentDraft() {
        let state = ChatState(); let user = ChatMessage(role: .user, text: "Original")
        state.messages = [user]; state.draft = "Unsent draft"; state.beginEditing(user)
        #expect(state.draft == "Original"); state.draft = "Changed"; state.cancelEditing()
        #expect(state.draft == "Unsent draft"); #expect(state.messages.first?.text == "Original")
    }
    @Test func editingSubmitReplacesTurnAndStartsNewResponse() {
        let state = ChatState(); let user = ChatMessage(role: .user, text: "Original")
        state.messages = [user, .init(role: .assistant, text: "Previous answer")]
        state.beginEditing(user); state.draft = "Edited"; let reply = state.send()
        #expect(reply != nil); #expect(state.messages.count == 2); #expect(state.messages.first?.text == "Edited")
        #expect(state.editingMessageID == nil)
    }
    @Test func detailBackReturnsToActualOrigin() {
        let state = ChatState(); state.open(.settings); state.open(.personality); state.goBack()
        #expect(state.page == .settings)
        state.open(.customize); state.open(.personality); state.goBack()
        #expect(state.page == .customize)
    }
    @Test func copyConfirmationIsIdentityScoped() {
        let state = ChatState(); let a = ChatMessage(role: .assistant, text: "A"); let b = ChatMessage(role: .assistant, text: "B")
        state.copyMessage(a); state.copyMessage(b); state.clearCopyConfirmation(id: a.id)
        #expect(state.copiedMessage == b.id); state.clearCopyConfirmation(id: b.id); #expect(state.copiedMessage == nil)
    }
}
