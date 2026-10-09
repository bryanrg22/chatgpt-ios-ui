import Foundation

public enum ChatWidgetDestination: String, CaseIterable, Codable, Sendable {
    case chat, camera, photos, dictation, voice, work, codex, remote
    public var url: URL { URL(string: "chatgpt-ui-demo://widget/" + rawValue)! }
    public init?(url: URL) {
        guard url.scheme == "chatgpt-ui-demo", url.host == "widget", url.user == nil, url.password == nil,
            url.port == nil, url.query == nil, url.fragment == nil,
            let destination = Self(rawValue: String(url.path.dropFirst())), url.path == "/" + destination.rawValue
        else { return nil }
        self = destination
    }
    public var title: String {
        switch self {
        case .chat: "Chat"
        case .camera: "Camera"
        case .photos: "Photos"
        case .dictation: "Dictation"
        case .voice: "Voice"
        case .work: "Work"
        case .codex: "Codex"
        case .remote: "Remote"
        }
    }
    public var symbol: String {
        switch self {
        case .chat: "bubble.right"
        case .camera: "camera"
        case .photos: "photo"
        case .dictation: "mic"
        case .voice: "waveform"
        case .work: "briefcase"
        case .codex: "terminal"
        case .remote: "desktopcomputer"
        }
    }
}
public enum ChatWidgetLayout: String, CaseIterable, Codable, Sendable { case codexUsage, chat, shortcuts, codexTasks }
public enum ChatWidgetSize: String, CaseIterable, Codable, Sendable { case small, medium, large, tall }
public struct ChatWidgetShortcut: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var title: String
    public var destination: ChatWidgetDestination
    public init(id: String, title: String, destination: ChatWidgetDestination) {
        self.id = id
        self.title = title
        self.destination = destination
    }
}
/// Immutable timeline presentation. Usage has only its observed placeholder; no invented loaded values.
public struct ChatWidgetPresentation: Equatable, Codable, Sendable {
    public var layout: ChatWidgetLayout
    public var shortcuts: [ChatWidgetShortcut]
    public var tasks: [ChatWidgetTask]
    public init(layout: ChatWidgetLayout, shortcuts: [ChatWidgetShortcut] = [], tasks: [ChatWidgetTask] = []) {
        self.layout = layout
        self.shortcuts = shortcuts
        self.tasks = tasks
    }
}

public struct ChatWidgetTask: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var isRunning: Bool
    public init(id: UUID, title: String, isRunning: Bool = false) {
        self.id = id
        self.title = title
        self.isRunning = isRunning
    }
    public var url: URL { ChatWidgetRoute(destination: .codex, taskID: id).url }
}
public struct ChatWidgetRoute: Equatable, Sendable {
    public let destination: ChatWidgetDestination
    public let taskID: UUID?
    public init(destination: ChatWidgetDestination, taskID: UUID? = nil) {
        self.destination = destination
        self.taskID = destination == .codex ? taskID : nil
    }
    public var url: URL {
        var components = URLComponents(url: destination.url, resolvingAgainstBaseURL: false)!
        if let taskID { components.queryItems = [.init(name: "task", value: taskID.uuidString)] }
        return components.url!
    }
    public init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let query = components.queryItems
        components.queryItems = nil
        guard let base = components.url, let destination = ChatWidgetDestination(url: base) else { return nil }
        if let query {
            guard destination == .codex, query.count == 1, query[0].name == "task", let text = query[0].value,
                let id = UUID(uuidString: text)
            else { return nil }
            self.init(destination: destination, taskID: id)
        } else {
            self.init(destination: destination)
        }
    }
}
