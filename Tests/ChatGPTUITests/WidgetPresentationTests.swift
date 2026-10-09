import Foundation
import Testing
import ChatGPTWidgets

@Suite struct WidgetPresentationTests {
    @Test func everyDestinationRoundTripsThroughItsOwnedScheme() {
        for destination in ChatWidgetDestination.allCases {
            #expect(ChatWidgetDestination(url: destination.url) == destination)
            #expect(ChatWidgetRoute(url: destination.url)?.destination == destination)
        }
    }
    @Test func rejectsUnknownRoutesExternalHostsAndInjectedParameters() {
        for input in ["https://widget/chat", "chatgpt-ui-demo://other/chat", "chatgpt-ui-demo://widget/unknown", "chatgpt-ui-demo://widget/chat/extra", "chatgpt-ui-demo://widget/chat?task=invalid", "chatgpt-ui-demo://widget/chat#fragment", "chatgpt-ui-demo://user@widget/chat", "chatgpt-ui-demo://widget:12/chat", "chatgpt-ui-demo://widget/codex?task=bad", "chatgpt-ui-demo://widget/codex?task=00000000-0000-0000-0000-000000000001&extra=1"] {
            #expect(ChatWidgetRoute(url: URL(string: input)!) == nil)
        }
    }
    @Test func codexTaskRoutesRetainIdentityAndOtherRoutesDropTaskIdentity() {
        let id = UUID(); let route = ChatWidgetRoute(destination: .codex, taskID: id)
        #expect(ChatWidgetRoute(url: route.url) == route)
        #expect(ChatWidgetRoute(destination: .camera, taskID: id).taskID == nil)
        #expect(ChatWidgetRoute(url: ChatWidgetTask(id: id, title: "Host task").url)?.taskID == id)
    }
    @Test func hostTimelineDataIsCodableEmptyAndIndependent() throws {
        var first = ChatWidgetPresentation(layout: .codexTasks)
        #expect(first.tasks.isEmpty); #expect(first.shortcuts.isEmpty)
        first.tasks = [.init(id: UUID(), title: "Host task", isRunning: true)]
        first.shortcuts = [.init(id: "custom", title: "My work", destination: .work)]
        let second = first; first.tasks.removeAll()
        #expect(second.tasks.count == 1); #expect(first.tasks.isEmpty)
        let decoded = try JSONDecoder().decode(ChatWidgetPresentation.self, from: JSONEncoder().encode(second))
        #expect(decoded == second)
    }
}
