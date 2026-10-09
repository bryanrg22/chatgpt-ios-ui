import SwiftUI
import WidgetKit
import ChatGPTWidgets

struct DemoEntry: TimelineEntry {
    let date: Date
    let presentation: ChatWidgetPresentation
}
/// The executable injects a fixed offline snapshot. Hosts can substitute their own provider/storage.
struct DemoProvider: TimelineProvider {
    let presentation: ChatWidgetPresentation
    func placeholder(in context: Context) -> DemoEntry { .init(date: .now, presentation: presentation) }
    func getSnapshot(in context: Context, completion: @escaping (DemoEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DemoEntry>) -> Void) {
        completion(Timeline(entries: [placeholder(in: context)], policy: .never))
    }
}
struct DemoWidget: Widget {
    var kind: String = "ChatGPTDemo.Chat"
    var layout: ChatWidgetLayout = .chat
    var title: String = "ChatGPT"
    var detail: String = "Quickly start a new chat with ChatGPT."
    var families: [WidgetFamily] = [.systemSmall, .systemMedium]
    static let sampleTasks: [ChatWidgetTask] = [
        "Plan the garden", "Review the planting guide", "Add seasonal reminders", "Update the watering schedule",
        "Choose container sizes", "Compare herb varieties", "Arrange the patio", "Review the checklist"
    ].enumerated().map { index, title in
        .init(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!, title: title,
            isRunning: index == 0)
    }
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DemoProvider(
                presentation: .init(
                    layout: layout,
                    shortcuts: [ChatWidgetDestination.chat, .camera, .photos, .voice].map {
                        .init(id: $0.rawValue, title: $0.title, destination: $0)
                    }, tasks: Self.sampleTasks))
        ) { entry in
            DemoEntryView(entry: entry)
        }.configurationDisplayName(title).description(detail).supportedFamilies(families)
    }
}
struct DemoEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DemoEntry
    var body: some View {
        ChatWidgetView(
            presentation: entry.presentation,
            size: family == .systemSmall ? .small : family == .systemMedium ? .medium : .large)
    }
}
@main struct ChatGPTDemoWidgetBundle: WidgetBundle {
    var body: some Widget {
        DemoWidget(
            kind: "ChatGPTDemo.CodexUsage", layout: .codexUsage, title: "Codex usage",
            detail: "See your remaining Codex usage and when your limits reset.")
        DemoWidget(
            kind: "ChatGPTDemo.Chat", layout: .chat, title: "ChatGPT", detail: "Quickly start a new chat with ChatGPT.")
        DemoWidget(
            kind: "ChatGPTDemo.Shortcuts", layout: .shortcuts, title: "ChatGPT shortcuts",
            detail: "Choose your shortcuts for ChatGPT, work, and remote.")
        DemoWidget(
            kind: "ChatGPTDemo.CodexTasks", layout: .codexTasks, title: "Codex tasks",
            detail: "Keep up with your latest Codex tasks, across all hosts or just the ones you choose.",
            families: [.systemMedium, .systemLarge])
    }
}
