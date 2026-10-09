import Foundation
import Testing
@testable import ChatGPTUI

@MainActor struct WorkTaskPresentationTests {
    @Test func emptyQuestionsAndExtremeNavigationAreSafe() {
        let state = WorkTaskPresentationState()
        state.moveQuestion(by: .max)
        state.moveQuestion(by: .min)
        state.currentAnswerDraft = "ignored"
        state.skipQuestion()
        state.closeClarification()
        #expect(state.currentQuestion == nil)
        #expect(state.questionIndex == 0)
        #expect(state.answerDrafts.isEmpty)
        #expect(!state.clarificationIsPresented)
        #expect(!state.submitAnswerDraft())
    }
    @Test func carouselBoundsAndDraftsSurviveRoundTrip() {
        let questions = [WorkClarificationQuestion(title: "Message?"), .init(title: "Audience?")]
        let state = WorkTaskPresentationState(questions: questions)
        state.currentAnswerDraft = "A garden event"
        state.moveQuestion(by: .max)
        #expect(state.questionIndex == 1)
        state.currentAnswerDraft = "Neighbors"
        state.moveQuestion(by: .min)
        #expect(state.questionIndex == 0)
        #expect(state.currentAnswerDraft == "A garden event")
        state.closeClarification()
        state.showClarification()
        #expect(state.currentAnswerDraft == "A garden event")
        #expect(state.clarificationIsPresented)
    }
    @Test func hostReorderingPreservesIdentityAndRemovedDraftsArePruned() {
        let first = WorkClarificationQuestion(title: "First")
        let second = WorkClarificationQuestion(title: "Second")
        let state = WorkTaskPresentationState(questions: [first, second])
        state.currentAnswerDraft = "First draft"
        state.moveQuestion(by: 1)
        state.currentAnswerDraft = "Second draft"
        state.update(messages: [], status: .stopped, questions: [second, first])
        #expect(state.questionIndex == 0)
        #expect(state.currentAnswerDraft == "Second draft")
        state.update(messages: [], status: .stopped, questions: [first])
        #expect(state.currentAnswerDraft == "First draft")
        #expect(state.answerDrafts[second.id] == nil)
        state.update(messages: [], status: .stopped, questions: [])
        #expect(!state.clarificationIsPresented)
        #expect(state.answerDrafts.isEmpty)
    }
    @Test func optionsAreValidatedAndEmitTypedIntentWithoutAdvancing() {
        let option = WorkClarificationOption(title: "Print")
        let question = WorkClarificationQuestion(title: "Format?", options: [option])
        let state = WorkTaskPresentationState(questions: [question, .init(title: "Other?")])
        var actions: [WorkTaskAction] = []
        state.onAction = { actions.append($0) }
        #expect(!state.chooseOption(UUID()))
        #expect(actions.isEmpty)
        #expect(state.chooseOption(option.id))
        #expect(state.questionIndex == 0)
        #expect(actions == [.answer(taskID: state.taskID, questionID: question.id, answer: .option(option.id))])
    }
    @Test func answerTextIsTrimmedAndSkipRetainsDraft() {
        let question = WorkClarificationQuestion(title: "Message?")
        let state = WorkTaskPresentationState(questions: [question])
        var actions: [WorkTaskAction] = []
        state.onAction = { actions.append($0) }
        state.currentAnswerDraft = "  \n "
        #expect(!state.submitAnswerDraft())
        #expect(actions.isEmpty)
        state.currentAnswerDraft = "  Garden day  "
        #expect(state.submitAnswerDraft())
        #expect(state.answers[question.id] == .text("Garden day"))
        state.skipQuestion()
        #expect(state.answers[question.id] == .skipped)
        #expect(state.currentAnswerDraft == "  Garden day  ")
        #expect(state.questionIndex == 0)
    }
    @Test func stopIsIdempotentAndRuntimeStatusStaysHostOwned() {
        let state = WorkTaskPresentationState(status: .working)
        var actions: [WorkTaskAction] = []
        state.onAction = { actions.append($0) }
        state.requestStop()
        state.requestStop()
        #expect(actions == [.stop(state.taskID)])
        #expect(state.status == .working)
        #expect(state.stopRequested)
        state.update(messages: [], status: .stopped, questions: [])
        #expect(!state.stopRequested)
        state.requestStop()
        #expect(actions.count == 1)
        state.update(messages: [], status: .working, questions: [])
        state.requestStop()
        #expect(actions.count == 2)
        state.resolveStopRequest()
        #expect(!state.stopRequested)
        #expect(state.status == .working)
        state.requestStop()
        state.requestStop()
        #expect(actions.count == 3)
    }
    @Test func followUpRejectsBlankOrRunningAndDoesNotFabricateReply() {
        let state = WorkTaskPresentationState(status: .working)
        state.followUpDraft = "  Make it green  "
        #expect(!state.sendFollowUp())
        #expect(!state.followUpDraft.isEmpty)
        state.update(messages: [], status: .stopped, questions: [])
        var action: WorkTaskAction?
        state.onAction = { action = $0 }
        #expect(state.sendFollowUp())
        #expect(action == .followUp(taskID: state.taskID, text: "Make it green"))
        #expect(state.messages.isEmpty)
        #expect(state.followUpDraft.isEmpty)
        #expect(!state.sendFollowUp())
    }
    @Test func removingAnOptionClearsItsStaleAnswer() {
        let option = WorkClarificationOption(title: "Print")
        var question = WorkClarificationQuestion(title: "Format?", options: [option])
        let state = WorkTaskPresentationState(questions: [question])
        #expect(state.chooseOption(option.id))
        question.options = []
        state.update(messages: [], status: .stopped, questions: [question])
        #expect(state.answers[question.id] == nil)
    }
    @Test func duplicateQuestionAndOptionIdentitiesAreNormalized() {
        let option = WorkClarificationOption(title: "One")
        let question = WorkClarificationQuestion(title: "Question", options: [option, option])
        let state = WorkTaskPresentationState(questions: [question, question])
        #expect(state.questions.count == 1)
        #expect(state.currentQuestion?.options.count == 1)
        state.update(messages: [], status: .stopped, questions: [question, question])
        #expect(state.questions.count == 1)
    }
}
