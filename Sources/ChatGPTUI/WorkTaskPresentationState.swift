import Foundation
import Observation

public enum WorkTaskStatus: String, Equatable, Sendable {
    case working = "Working", stopped = "Stopped working", completed = "Completed", waiting =
        "Waiting for your response"
}
public struct WorkTaskMessage: Identifiable, Equatable, Sendable {
    public enum Role: Equatable, Sendable { case user, assistant }
    public let id: UUID
    public var role: Role
    public var text: String
    public init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
public struct WorkClarificationOption: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}
public struct WorkClarificationQuestion: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var options: [WorkClarificationOption]
    public init(id: UUID = UUID(), title: String, options: [WorkClarificationOption] = []) {
        self.id = id
        self.title = title
        var seen = Set<UUID>()
        self.options = options.filter { seen.insert($0.id).inserted }
    }
}
public struct WorkTaskTraceItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var text: String
    public var isSecondary: Bool
    public init(id: UUID = UUID(), text: String, isSecondary: Bool = false) {
        self.id = id
        self.text = text
        self.isSecondary = isSecondary
    }
}
public enum WorkTaskAnswer: Equatable, Sendable { case option(UUID), text(String), skipped }
@nonexhaustive public enum WorkTaskAction: Equatable, Sendable {
    case stop(UUID), followUp(taskID: UUID, text: String)
    case answer(taskID: UUID, questionID: UUID, answer: WorkTaskAnswer)
    case questionChanged(UUID), closeClarification, openActivity, openMenu, attachments, dictation, voice
    case share, pin, addToProject, uploadedFiles, findInChat, archive, delete
}
/// The host owns messages, runtime status and task execution. No timers or fabricated responses.
@MainActor @Observable public final class WorkTaskPresentationState {
    public let taskID: UUID
    public var title: String
    public private(set) var activityExpanded = false
    public private(set) var messages: [WorkTaskMessage]
    public private(set) var status: WorkTaskStatus
    public private(set) var questions: [WorkClarificationQuestion]
    public private(set) var traceItems: [WorkTaskTraceItem]
    public private(set) var questionIndex = 0
    public private(set) var clarificationIsPresented: Bool
    public private(set) var answerDrafts: [UUID: String] = [:]
    public private(set) var answers: [UUID: WorkTaskAnswer] = [:]
    public private(set) var stopRequested = false
    public var followUpDraft = ""
    public var onAction: (WorkTaskAction) -> Void = { _ in }
    public init(
        taskID: UUID = UUID(), title: String = "Work", messages: [WorkTaskMessage] = [],
        status: WorkTaskStatus = .stopped, questions: [WorkClarificationQuestion] = [],
        traceItems: [WorkTaskTraceItem] = []
    ) {
        self.taskID = taskID
        self.title = title
        self.messages = messages
        self.status = status
        self.traceItems = traceItems
        var seen = Set<UUID>()
        let normalizedQuestions = questions.filter { seen.insert($0.id).inserted }
        self.questions = normalizedQuestions
        self.clarificationIsPresented = !normalizedQuestions.isEmpty
    }
    public var currentQuestion: WorkClarificationQuestion? {
        questions.indices.contains(questionIndex) ? questions[questionIndex] : nil
    }
    public var currentAnswerDraft: String {
        get { currentQuestion.flatMap { answerDrafts[$0.id] } ?? "" }
        set {
            guard let id = currentQuestion?.id else { return }
            answerDrafts[id] = newValue
        }
    }
    public var hasPreviousQuestion: Bool { questionIndex > 0 && currentQuestion != nil }
    public var hasNextQuestion: Bool { questionIndex + 1 < questions.count }
    public func moveQuestion(by offset: Int) {
        guard !questions.isEmpty else { return }
        // Bound the offset before addition to avoid overflowing with hostile host values.
        let bounded = min(max(offset, -questionIndex), questions.count - 1 - questionIndex)
        guard bounded != 0 else { return }
        questionIndex += bounded
        if let id = currentQuestion?.id { onAction(.questionChanged(id)) }
    }
    public func toggleActivity() {
        activityExpanded.toggle()
        onAction(.openActivity)
    }
    public func closeClarification() {
        guard clarificationIsPresented else { return }
        clarificationIsPresented = false
        onAction(.closeClarification)
    }
    public func showClarification() { clarificationIsPresented = !questions.isEmpty }
    @discardableResult public func chooseOption(_ id: UUID) -> Bool {
        guard let q = currentQuestion, q.options.contains(where: { $0.id == id }) else { return false }
        answers[q.id] = .option(id)
        onAction(.answer(taskID: taskID, questionID: q.id, answer: .option(id)))
        return true
    }
    @discardableResult public func submitAnswerDraft() -> Bool {
        guard let q = currentQuestion else { return false }
        let value = currentAnswerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        answers[q.id] = .text(value)
        onAction(.answer(taskID: taskID, questionID: q.id, answer: .text(value)))
        return true
    }
    public func skipQuestion() {
        guard let id = currentQuestion?.id else { return }
        answers[id] = .skipped
        onAction(.answer(taskID: taskID, questionID: id, answer: .skipped))
    }
    public func requestStop() {
        guard status == .working, !stopRequested else { return }
        stopRequested = true
        onAction(.stop(taskID))
    }
    /// Lets the host re-enable Stop after a rejected/cancelled request without inventing a status change.
    public func resolveStopRequest() { stopRequested = false }
    @discardableResult public func sendFollowUp() -> Bool {
        let value = followUpDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard status != .working, !value.isEmpty else { return false }
        followUpDraft = ""
        onAction(.followUp(taskID: taskID, text: value))
        return true
    }
    /// Retains drafts for surviving question IDs; host updates may reorder/remove questions.
    public func update(
        messages: [WorkTaskMessage], status: WorkTaskStatus, questions: [WorkClarificationQuestion],
        traceItems: [WorkTaskTraceItem] = []
    ) {
        let selectedID = currentQuestion?.id
        let priorStatus = self.status
        self.messages = messages
        self.status = status
        self.traceItems = traceItems
        var seen = Set<UUID>()
        self.questions = questions.filter { seen.insert($0.id).inserted }
        let valid = Set(self.questions.map { $0.id })
        answerDrafts = answerDrafts.filter { valid.contains($0.key) }
        answers = answers.filter { key, answer in
            guard let question = self.questions.first(where: { $0.id == key }) else { return false }
            if case let .option(id) = answer { return question.options.contains { $0.id == id } }
            return true
        }
        if let selectedID, let newIndex = self.questions.firstIndex(where: { $0.id == selectedID }) {
            questionIndex = newIndex
        } else {
            questionIndex = min(questionIndex, max(0, self.questions.count - 1))
        }
        if self.questions.isEmpty { clarificationIsPresented = false }
        if status != .working || priorStatus != .working { stopRequested = false }
    }
}
