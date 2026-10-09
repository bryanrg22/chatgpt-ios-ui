import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct DotPresentationStateTests {
    @Test func replyCancelPreservesDraftAndOnlyValidMessageSelects() {
        let state = DotPresentationState(); let id = state.messages[0].id; state.draft = "Keep this text"
        state.beginReply(id); state.beginReply(UUID()); #expect(state.replyTo == id)
        state.cancelReply(); #expect(state.replyTo == nil); #expect(state.draft == "Keep this text")
    }
    @Test func blankSendKeepsReplyThenSendEmitsTrimmedPayload() {
        let state = DotPresentationState(); let id = state.messages[0].id; var actions: [DotUIAction] = []; state.onAction = { actions.append($0) }; state.beginReply(id); state.draft = "  \n "
        let empty = state.send(); #expect(!empty); #expect(state.replyTo == id); #expect(actions.isEmpty)
        state.draft = "  Thanks for the notes  "; let sent = state.send(); #expect(sent)
        #expect(actions == [.send(text: "Thanks for the notes", replyTo: id)]); #expect(state.replyTo == nil); #expect(state.draft.isEmpty); #expect(state.messages.last?.replyTo == id)
    }
    @Test func reactionsToggleAndIgnoreUnknownMessage() {
        let state = DotPresentationState(); let id = state.messages[0].id; state.react("👍", to: id); #expect(state.messages[0].reaction == "👍")
        state.react("👍", to: id); #expect(state.messages[0].reaction == nil); state.react("❤️", to: UUID()); #expect(state.messages.allSatisfy { $0.reaction == nil })
    }
    @Test func hostMessageUpdatesIdentityAndDoesNotDuplicate() {
        let state = DotPresentationState(messages: []); var message = DotMessage(text: "First")
        state.append(message); message.text = "Updated"; state.append(message)
        #expect(state.messages == [message])
    }
    @Test func callStateDoesNotInventFailureTimerAndEndIsIdempotent() {
        let state = DotPresentationState(); var actions: [DotUIAction] = []; state.onAction = { actions.append($0) }
        state.beginCall(); #expect(state.callPhase == .calling); state.callMinimized = true
        state.callPhase = .failed; state.retryCall(); #expect(state.callPhase == .calling); #expect(state.callMinimized)
        state.endCall(); state.endCall(); #expect(state.callPhase == .idle); #expect(!state.callMinimized)
        #expect(actions == [.beginCall, .beginCall, .endCall])
    }
    @Test func computerAndPauseActionsRemainSessionLocal() {
        let state = DotPresentationState(); let other = DotPresentationState(); var actions: [DotUIAction] = []; state.onAction = { actions.append($0) }
        state.revokeComputer(); state.revokeComputer(); state.togglePause()
        #expect(actions == [.revokeComputer("Sample-Mac.lan"), .pause(true)]); #expect(other.computerAvailable); #expect(!other.isPaused)
    }
    @Test func localDeletionClearsPendingReplyAndDraft() {
        let state = DotPresentationState(); state.beginReply(state.messages[0].id); state.draft = "Pending"; state.deleteLocalConversation()
        #expect(state.messages.isEmpty); #expect(state.replyTo == nil); #expect(state.draft.isEmpty)
    }
    @Test func connectedTimeAndMuteAreHostSuppliedWithoutActionEcho() {
        let state = DotPresentationState(messages: []); var actions: [DotUIAction] = []
        state.onAction = { actions.append($0) }
        state.applyCallPresentation(.init(phase: .connected, elapsedSeconds: 443, microphoneMuted: true))
        #expect(state.callPhase == .connected); #expect(state.callPresentation.elapsedLabel == "7:23")
        #expect(state.microphoneMuted); #expect(actions.isEmpty)
        state.toggleMute(); #expect(actions == [.mute(false)])
        state.callMinimized = true; state.applyCallPresentation(.init(phase: .idle))
        #expect(!state.callMinimized); #expect(state.messages.isEmpty)
    }
    @Test func malformedElapsedTimeIsBoundedAndLongCallsKeepMinutes() {
        #expect(DotCallPresentation.durationLabel(-10) == "0:00")
        #expect(DotCallPresentation.durationLabel(3601) == "60:01")
        var update = DotCallPresentation(phase: .connected); update.elapsedSeconds = -12
        let state = DotPresentationState(); state.applyCallPresentation(update)
        #expect(state.callElapsedSeconds == 0)
    }
    @Test func activeCallCannotStartAgainAndEndDoesNotFabricateSummary() {
        let state = DotPresentationState(messages: []); var actions: [DotUIAction] = []
        state.onAction = { actions.append($0) }; state.beginCall(); state.beginCall()
        state.applyCallPresentation(.init(phase: .connected, elapsedSeconds: 38)); state.beginCall(); state.endCall()
        #expect(actions == [.beginCall, .endCall]); #expect(state.messages.isEmpty)
    }
    @Test func receiptsAdvanceOnlyOnExplicitHostAcknowledgement() {
        let state = DotPresentationState(messages: []); state.draft = "Hello"; _ = state.send()
        let message = state.messages[0]; #expect(message.receipt == nil)
        let delivered = state.updateReceipt(.delivered, for: message.id)
        let read = state.updateReceipt(.read, for: message.id)
        let stale = state.updateReceipt(.delivered, for: message.id)
        let duplicate = state.updateReceipt(.read, for: message.id)
        #expect(delivered && read); #expect(!stale && !duplicate); #expect(state.messages[0].receipt == .read)
        state.append(message); #expect(state.messages[0].receipt == .read)
    }
    @Test func receiptsRejectUnknownAndAssistantMessages() {
        let state = DotPresentationState(); let unknown = state.updateReceipt(.read, for: UUID())
        let assistant = state.updateReceipt(.delivered, for: state.messages[0].id)
        #expect(!unknown && !assistant)
        var message = DotMessage(text: "Assistant"); message.receipt = .read; state.append(message)
        #expect(state.messages.last?.receipt == nil)
    }
    @Test func summaryCopiesVisibleDurationAndDisallowsReaction() {
        let summary = DotMessage(text: "unused", isUser: true, kind: .callEnded(durationSeconds: 443), receipt: .delivered)
        let state = DotPresentationState(messages: [summary]); var actions: [DotUIAction] = []; state.onAction = { actions.append($0) }
        state.copy(summary.id); state.react("👍", to: summary.id)
        #expect(summary.displayText == "7:23 · Call ended"); #expect(summary.isCallSummary); #expect(!summary.supportsReactions)
        #expect(actions == [.copy(message: summary.id, text: "7:23 · Call ended")]); #expect(state.messages[0].reaction == nil)
        state.beginReply(summary.id); state.draft = "Let's continue later"; _ = state.send()
        #expect(state.messages.last?.replyTo == summary.id)
    }
    @Test func outgoingTextHasNoAssistantReactionStrip() {
        let outgoing = DotMessage(text: "Thanks", isUser: true)
        let state = DotPresentationState(messages: [outgoing]); state.react("❤️", to: outgoing.id)
        #expect(!outgoing.supportsReactions); #expect(state.messages[0].reaction == nil)
    }
}
