#if os(iOS)
import SwiftUI

public struct CodexDestinationView: View {
    @Bindable private var state: CodexPresentationState
    private let onBack: () -> Void
    private let onOpenProfile: () -> Void
    private let onOpenGeneral: () -> Void
    @State private var showsMenu = false
    @State private var showsSearch = false
    @State private var showsSettings = false
    @State private var showsArchived = false
    @State private var showsConnection = false
    @State private var showsSettingsConnection = false
    @State private var archiveFilter = "Sample Mac"
    @State private var archiveQuery = ""
    @State private var notice: String?
    @FocusState private var composerFocused: Bool
    public init(state: CodexPresentationState, onBack: @escaping () -> Void, onOpenProfile: @escaping () -> Void = {}, onOpenGeneral: @escaping () -> Void = {}) { self.state = state; self.onBack = onBack; self.onOpenProfile = onOpenProfile; self.onOpenGeneral = onOpenGeneral }
    public var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 16).padding(.bottom, 16)
            
            if let task = state.selectedTask { detail(task) } else { home }
            if state.selectedTask != nil {
                HStack(spacing: 8) {
                    Button { gap("Changed files") } label: { HStack(spacing: 5) { Text("3 files"); Text("+42").foregroundStyle(.green); Text("−12").foregroundStyle(.red) }.font(.system(size: 12)).padding(10).glassEffect(.regular, in: Capsule()) }
                    Button { gap("Agents") } label: { Label("2 agents", systemImage: "person.2").font(.system(size: 12)).padding(10).glassEffect(.regular, in: Capsule()) }
                }.padding(.bottom, 12)
            }
            if !showsSearch { composer.padding(.horizontal, 34).padding(.bottom, 6) }
        }.background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .overlay(alignment: .top) { if showsMenu { menu.padding(.top, 8) } }
            .fullScreenCover(isPresented: $showsConnection) { connectionScanner }
            .sheet(isPresented: $showsArchived) { archived.presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .sheet(isPresented: $showsSettings) { settings.presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .alert("UI reference needed", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private var header: some View {
        HStack(spacing: 12) {
            if showsSearch {
                HStack(spacing: 10) { Image(systemName: "magnifyingglass").font(.system(size: 22)); TextField("Search chats", text: $state.query).font(.system(size: 17)).accessibilityIdentifier("codex.search") }.padding(.horizontal, 14).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule())
                Button { showsSearch = false; state.query = "" } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close Codex search")
            } else {
            Button { if state.selectedTask != nil { state.goHome() } else { onBack() } } label: { if state.selectedTask != nil { GlassCircle(symbol: "chevron.left") } else { DrawerGlyph() } }.accessibilityLabel(state.selectedTask == nil ? "Open sidebar" : "Back to Codex")
            if let task = state.selectedTask {
                VStack(alignment: .leading, spacing: 3) { Text(task.title).font(.system(size: 17, weight: .semibold)).lineLimit(1); Text("\(task.project ?? "Local task") · Sample Mac").font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1) }
                Spacer(minLength: 0)
                HStack(spacing: 24) { Button { state.newTask() } label: { Image(systemName: "square.and.pencil") }; Button { gap("Task menu") } label: { Image(systemName: "ellipsis") } }.font(.system(size: 22)).padding(.horizontal, 16).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule())
            } else {
                Spacer(); Button { showsMenu.toggle() } label: { HStack(spacing: 8) { Text("Codex").font(.system(size: 17, weight: .semibold)); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) } }.accessibilityIdentifier("codex.menu"); Spacer()
                Button { showsSearch.toggle(); if !showsSearch { state.query = "" } } label: { GlassCircle(symbol: "magnifyingglass") }.accessibilityLabel("Search Codex tasks")
            }
        }
        }.frame(height: 44)
    }
    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if state.grouping == .project && state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if state.recentsFirst { recents }
                    projects
                    if !state.recentsFirst { recents }
                } else {
                    Text(state.grouping == .priority ? "Priority" : "Tasks").font(.system(size: 17, weight: .semibold))
                    ForEach(state.visibleTasks) { task in taskRow(task) }
                    if state.visibleTasks.isEmpty { Text("No tasks found").foregroundStyle(.secondary) }
                }
            }.padding(.horizontal, 20).padding(.top, 7).padding(.bottom, 20)
        }.scrollIndicators(.hidden)
    }
    private var recents: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text("Recents").font(.system(size: 17, weight: .semibold)); Spacer(); newTaskButton(project: nil) }
            ForEach(state.visibleTasks.filter { $0.project == nil }.prefix(4)) { task in taskRow(task) }
        }
    }
    private var projects: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projects").font(.system(size: 17, weight: .semibold)).padding(.bottom, 8)
            ForEach(state.projects, id: \.self) { project in
                HStack(spacing: 14) {
                    Button { state.toggleProject(project) } label: { HStack(spacing: 14) { Image(systemName: state.expandedProjects.contains(project) ? "folder.badge.minus" : "folder").font(.system(size: 22)); Text(project).fontWeight(.medium); if project == "SampleApp" { Text("dev/Projects").foregroundStyle(.secondary).lineLimit(1) }; Spacer(minLength: 0) } }.accessibilityLabel("\(state.expandedProjects.contains(project) ? "Collapse" : "Expand") \(project)")
                    newTaskButton(project: project)
                }.frame(minHeight: 44)
                if state.expandedProjects.contains(project) { ForEach(state.visibleTasks.filter { $0.project == project }) { task in taskRow(task).padding(.leading, 36) } }
            }
        }.font(.system(size: 17))
    }
    private func newTaskButton(project: String?) -> some View {
        Button { state.newTask(project: project); composerFocused = true } label: { Image(systemName: "square.and.pencil").font(.system(size: 18)).foregroundStyle(.secondary).frame(width: 32, height: 36) }.accessibilityLabel(project.map { "New task in \($0)" } ?? "New Codex task")
    }
    private func taskRow(_ task: CodexTaskFixture) -> some View {
        Button { state.openTask(task.id) } label: { HStack { Text(task.title).lineLimit(1); Spacer(minLength: 8); if task.isRunning { ProgressView().controlSize(.small) } }.font(.system(size: 17)).frame(minHeight: 50).contentShape(Rectangle()) }.accessibilityIdentifier("codex.task.\(task.id)")
    }
    private func detail(_ task: CodexTaskFixture) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label("Messaged 1 agent ›", systemImage: "person.crop.square").foregroundStyle(.secondary)
                ForEach(Array(task.messages.enumerated()), id: \.offset) { _, message in
                    HStack { Spacer(minLength: 50); Text(message).padding(14).background(Color(red: 0.016, green: 0.02, blue: 0.37), in: RoundedRectangle(cornerRadius: 22)).foregroundStyle(.white) }
                }
                Text(task.response)
                ForEach(Array(task.activities.enumerated()), id: \.offset) { _, activity in Button { gap("Tool event details") } label: { Label(activity + " ›", systemImage: "terminal").foregroundStyle(.secondary) } }
                Text(task.isRunning ? "Reviewing the local presentation fixture…" : "The local presentation is paused.").foregroundStyle(.secondary)
            }.font(.system(size: 17)).lineSpacing(6).padding(.horizontal, 16).padding(.top, 4)
        }.scrollIndicators(.hidden)
    }
    private var composer: some View {
        HStack(spacing: 14) {
            Button { gap("Codex attachments") } label: { Image(systemName: "plus").font(.system(size: 24)) }.accessibilityLabel("Codex attachments")
            TextField(state.selectedTask != nil ? "Follow up" : "Ask Codex", text: $state.draft, axis: .vertical).font(.system(size: 17)).lineLimit(1...6).focused($composerFocused).accessibilityIdentifier("codex.composer")
            Button { gap("Codex dictation") } label: { Image(systemName: "mic").font(.system(size: 22)) }.accessibilityLabel("Codex dictation")
            Button {
                if state.selectedTask?.isRunning == true { state.stop() }
                else if !state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { if state.send() && state.dismissKeyboardAfterSending { composerFocused = false } }
                else { gap("Codex voice") }
            } label: { Group { if state.selectedTask?.isRunning == true { Image(systemName: "stop.fill").font(.system(size: 15)) } else if !state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { Image(systemName: "arrow.up").font(.system(size: 20, weight: .semibold)) } else { VoiceBars() } }.foregroundStyle(.white).frame(width: 34, height: 34).background(ChatDesign.blue, in: Circle()) }.accessibilityLabel(state.selectedTask?.isRunning == true ? "Stop Codex task" : state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Codex voice" : "Send Codex message")
        }.padding(.horizontal, 14).padding(.vertical, 7).glassEffect(.regular.interactive(), in: Capsule())
    }
    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(CodexGrouping.allCases, id: \.self) { grouping in menuRow(grouping.rawValue, symbol: grouping == .priority ? "bell" : grouping == .project ? "folder" : "clock.arrow.circlepath", checked: state.grouping == grouping) { state.grouping = grouping } }
            Divider().padding(.vertical, 10)
            menuRow("Recents first", symbol: "bubble.left.and.bubble.right", checked: state.recentsFirst) { state.recentsFirst.toggle() }
            Divider().padding(.vertical, 10)
            Text("Manage").font(.system(size: 12)).foregroundStyle(.secondary).padding(.leading, 36).padding(.bottom, 8)
            menuRow("Archived tasks", symbol: "archivebox") { showsArchived = true }
            menuRow("Add connection", symbol: "link") { showsConnection = true }
            menuRow("Settings", symbol: "gearshape") { showsSettings = true }
            Divider().padding(.vertical, 10)
            Text("Usage remaining").font(.system(size: 12)).foregroundStyle(.secondary).padding(.leading, 36)
            Text("Week 45%").font(.system(size: 17)).padding(.leading, 36).padding(.vertical, 20)
        }.padding(.horizontal, 20).padding(.top, 8).frame(width: 250).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34))
            .onTapGesture {}.background { Color.clear.contentShape(Rectangle()).onTapGesture { showsMenu = false }.ignoresSafeArea().frame(width: 1000, height: 2000) }
    }
    private func menuRow(_ title: String, symbol: String, checked: Bool = false, action: @escaping () -> Void) -> some View {
        Button { action(); showsMenu = false } label: { HStack(spacing: 12) { Image(systemName: "checkmark").font(.system(size: 15)).opacity(checked ? 1 : 0).frame(width: 10); Image(systemName: symbol).font(.system(size: 20)).frame(width: 22); Text(title).font(.system(size: 17)); Spacer(minLength: 0) }.frame(height: 43).contentShape(Rectangle()) }
    }
    private var settings: some View {
        VStack(spacing: 0) {
            HStack { Button("Edit") { gap("Connection editing") }.padding(.horizontal, 16).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule()); Spacer(); Text("Codex").fontWeight(.semibold); Spacer(); Button { showsSettings = false } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close Codex settings") }.font(.system(size: 17)).padding(16)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Button { showsSettings = false; onOpenProfile() } label: { HStack(spacing: 12) { Text("AM").font(.system(size: 10)).frame(width: 24, height: 24).background(.teal, in: Circle()); Text("Profile"); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(16).background(ChatDesign.raised, in: Capsule()) }
                    VStack(spacing: 10) {
                        HStack { Text("Connections").fontWeight(.semibold).foregroundStyle(.secondary); Spacer(); Button("Disconnect All") { state.disconnectAll() }.font(.system(size: 12)).foregroundStyle(ChatDesign.blue) }.padding(.horizontal, 16)
                        VStack(spacing: 0) { connection("Cloud", detail: "Cloud agent", symbol: "cloud", connected: $state.cloudConnected); Divider().padding(.leading, 50); connection("Sample-Mac.local", detail: "Codex Desktop", symbol: "laptopcomputer", connected: $state.desktopConnected); Divider().padding(.leading, 50); Button { showsSettingsConnection = true } label: { Label("Add connection", systemImage: "plus").foregroundStyle(ChatDesign.blue).frame(maxWidth: .infinity, alignment: .leading).padding(16) } }.background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 26))
                    }
                    VStack(alignment: .leading, spacing: 10) { Button { showsSettings = false; onOpenGeneral() } label: { HStack { Text("Open Codex automatically"); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(16).background(ChatDesign.raised, in: Capsule()) }; Text("Open ChatGPT directly into Codex.").font(.system(size: 13)).foregroundStyle(.secondary).padding(.leading, 16) }
                    VStack(alignment: .leading, spacing: 10) { Text("Composer").fontWeight(.semibold).foregroundStyle(.secondary).padding(.leading, 16); VStack(spacing: 0) { Toggle("Dismiss keyboard after sending", isOn: $state.dismissKeyboardAfterSending).padding(16); Divider().padding(.horizontal, 16); Toggle("Show context window usage", isOn: $state.showsContextUsage).padding(16); Divider().padding(.horizontal, 16); Button { gap("Follow-up behavior") } label: { HStack { Text("Follow-up behavior"); Spacer(); Text("Queue ⌃").foregroundStyle(.secondary) }.padding(16) } }.background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 26)) }
                }.font(.system(size: 17)).padding(16).padding(.top, 18)
            }.scrollIndicators(.hidden)
        }.background(ChatDesign.surface.ignoresSafeArea()).buttonStyle(.plain)
            .fullScreenCover(isPresented: $showsSettingsConnection) { connectionScanner }
    }
    private var connectionScanner: some View {
        CodexConnectionView(onClose: { showsConnection = false; showsSettingsConnection = false }, onPair: { code in _ = state.requestPairing(code); showsConnection = false; showsSettingsConnection = false }) { Color(white: 0.045) }
    }
    private var archived: some View {
        VStack(spacing: 22) {
            HStack { Color.clear.frame(width: 44, height: 44); Spacer(); Text("Archived tasks").font(.system(size: 17, weight: .semibold)); Spacer(); Button { showsArchived = false } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close archived tasks") }.padding(.horizontal, 16)
            ScrollView(.horizontal) { HStack(spacing: 12) { ForEach(["All", "Cloud", "Sample Mac"], id: \.self) { name in Button { archiveFilter = name } label: { HStack { if name == "Cloud" { Image(systemName: "cloud") }; if name == "Sample Mac" { Image(systemName: "laptopcomputer") }; Text(name) }.padding(.horizontal, 16).frame(height: 44).background(archiveFilter == name ? ChatDesign.raised : .clear, in: Capsule()) } } } }.scrollIndicators(.hidden)
            VStack(alignment: .leading, spacing: 24) {
                Button { gap("Archived month selector") } label: { HStack { Text("September").fontWeight(.semibold); Image(systemName: "chevron.down").font(.system(size: 10)) } }
                if !state.archivedTasks.isEmpty && archiveFilter != "Cloud" && (archiveQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || "Review component fixtures".localizedCaseInsensitiveContains(archiveQuery.trimmingCharacters(in: .whitespacesAndNewlines))) {
                    ForEach(state.archivedTasks) { task in HStack { VStack(alignment: .leading, spacing: 5) { Text(task.title); Text("ExampleProject · Sample-Mac.local").font(.system(size: 13)).foregroundStyle(.secondary) }; Spacer(); Button { state.restoreArchived(task.id) } label: { Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44) }.accessibilityLabel("Restore \(task.title)") } }
                }
            }.font(.system(size: 17)).padding(.horizontal, 20)
            Spacer()
            HStack(spacing: 10) { Image(systemName: "magnifyingglass"); TextField("Search archived tasks", text: $archiveQuery).accessibilityIdentifier("codex.archive-search") }.font(.system(size: 17)).padding(14).glassEffect(.regular.interactive(), in: Capsule()).padding(.horizontal, 26).padding(.bottom, 12)
        }.padding(.top, 16).background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
    }
    private func connection(_ name: String, detail: String, symbol: String, connected: Binding<Bool>) -> some View {
        Toggle(isOn: connected) { HStack(spacing: 12) { Image(systemName: symbol).font(.system(size: 24)).foregroundStyle(.secondary).frame(width: 22); VStack(alignment: .leading, spacing: 3) { Text(detail).font(.system(size: 12)).foregroundStyle(.secondary); Text(name); HStack(spacing: 5) { Circle().fill(connected.wrappedValue ? .green : .gray).frame(width: 7, height: 7); Text(connected.wrappedValue ? "Connected" : "Disconnected").font(.system(size: 14)).foregroundStyle(.secondary) } } } }.padding(16).accessibilityIdentifier("codex.connection.\(detail)")
    }
    private func gap(_ name: String) { state.onAction(.openDestination(name)); notice = "\(name) has not yet been captured. This offline skeleton does not open a real connection or run tools." }
}
#endif
