import Foundation
import Observation

public enum CodexGrouping: String, CaseIterable, Sendable {
    case priority = "Priority", project = "By project", chronological = "Chronological list"
}
@nonexhaustive public enum CodexUIAction: Equatable, Sendable {
    case submit(taskID: UUID, text: String, project: String?)
    case stop(UUID)
    case pair(code: String)
    case openDestination(String)
}
public struct CodexTaskFixture: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var project: String?
    public var isRunning: Bool
    public var messages: [String]
    public var response: String
    public var activities: [String]
    public init(
        id: UUID = UUID(), title: String, project: String? = nil, isRunning: Bool = false, messages: [String] = [],
        response: String =
            "The sample task is ready for a visual review. Compare spacing, typography, and the visible controls before connecting an agent.",
        activities: [String] = ["Messaged 2 agents", "Inspect example interface…"]
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.isRunning = isRunning
        self.messages = messages
        self.response = response
        self.activities = activities
    }
}
/// Local presentation state only. No remote connections, agent execution, or storage service.
@MainActor @Observable public final class CodexPresentationState {
    public var grouping: CodexGrouping = .project
    public var recentsFirst = true
    public var expandedProjects: Set<String> = ["SampleApp"]
    public var query = ""
    public var draft = ""
    public var selectedProject: String?
    public private(set) var selectedTaskID: UUID?
    public private(set) var tasks: [CodexTaskFixture]
    public private(set) var archivedTasks = [
        CodexTaskFixture(title: "Review component fixtures", project: "ExampleProject")
    ]
    public var cloudConnected = true
    public var desktopConnected = true
    public var dismissKeyboardAfterSending = true
    public var showsContextUsage = false
    public var onAction: (CodexUIAction) -> Void = { _ in }
    public init(tasks: [CodexTaskFixture]? = nil) {
        self.tasks =
            tasks ?? [
                .init(title: "Explain browser controls"), .init(title: "Fix text formatting"),
                .init(title: "Draw a free-body diagram"), .init(title: "Create a copy-and-paste list"),
                .init(
                    title: "Refine the sample interface", project: "SampleApp", isRunning: true,
                    messages: ["Review the example screens and outline the next visual changes."]),
                .init(title: "Create a system design image", project: "SampleApp"),
                .init(title: "Review the home screen", project: "GardenJournal"),
                .init(title: "Update fixture content", project: "ReadingList")
            ]
    }
    public var selectedTask: CodexTaskFixture? { tasks.first { $0.id == selectedTaskID } }
    public var projects: [String] { Array(Set(tasks.compactMap(\.project))).sorted() }
    public var visibleTasks: [CodexTaskFixture] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = tasks.filter {
            q.isEmpty || $0.title.localizedCaseInsensitiveContains(q)
                || ($0.project?.localizedCaseInsensitiveContains(q) ?? false)
        }
        return grouping == .priority ? filtered.filter(\.isRunning) + filtered.filter { !$0.isRunning } : filtered
    }
    public func toggleProject(_ name: String) {
        if expandedProjects.contains(name) { expandedProjects.remove(name) } else { expandedProjects.insert(name) }
    }
    public func openTask(_ id: UUID) {
        guard tasks.contains(where: { $0.id == id }) else { return }
        selectedTaskID = id
        draft = ""
        selectedProject = nil
    }
    public func goHome() {
        selectedTaskID = nil
        draft = ""
        selectedProject = nil
    }
    public func newTask(project: String? = nil) {
        selectedTaskID = nil
        selectedProject = project
        draft = ""
    }
    @discardableResult public func send() -> Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, selectedTask?.isRunning != true else { return false }
        let id: UUID
        if let index = tasks.firstIndex(where: { $0.id == selectedTaskID }) {
            tasks[index].messages.append(text)
            tasks[index].isRunning = true
            id = tasks[index].id
        } else {
            let task = CodexTaskFixture(
                title: String(text.prefix(72)), project: selectedProject, isRunning: true, messages: [text])
            tasks.insert(task, at: 0)
            id = task.id
            selectedTaskID = id
            if let project = selectedProject { expandedProjects.insert(project) }
        }
        draft = ""
        onAction(.submit(taskID: id, text: text, project: selectedTask?.project))
        return true
    }
    @discardableResult public func updateTask(_ id: UUID, response: String, activities: [String], isRunning: Bool)
        -> Bool
    {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return false }
        tasks[index].response = response
        tasks[index].activities = activities
        tasks[index].isRunning = isRunning
        return true
    }
    public func stop() {
        guard let index = tasks.firstIndex(where: { $0.id == selectedTaskID }), tasks[index].isRunning else { return }
        tasks[index].isRunning = false
        onAction(.stop(tasks[index].id))
    }
    public func restoreArchived(_ id: UUID) {
        guard let index = archivedTasks.firstIndex(where: { $0.id == id }) else { return }
        tasks.insert(archivedTasks.remove(at: index), at: 0)
    }
    @discardableResult public func requestPairing(_ code: String) -> Bool {
        let value = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        onAction(.pair(code: value))
        return true
    }
    public func disconnectAll() {
        cloudConnected = false
        desktopConnected = false
    }
}
