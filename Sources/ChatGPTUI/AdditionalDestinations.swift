import Foundation

struct SearchFixture: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let category: String
    let detail: String
    var kindLabel: String { category == "Images" ? "Image" : category == "Pages" ? "Page" : "Chat" }
    static func matching(query: String, category: String) -> [SearchFixture] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        return samples.filter {
            (category == "All" || $0.category == category)
                && ($0.title + " " + $0.detail).localizedCaseInsensitiveContains(normalized)
        }
    }
    static let samples = [
        SearchFixture(
            id: "design-image", title: "design-reference.jpg", category: "Images",
            detail: "A fictional landscape composition for the design reference collection."),
        SearchFixture(
            id: "design-plan", title: "Design planning", category: "Chats",
            detail: "Let's outline the design milestones for our sample project."),
        SearchFixture(
            id: "design-notes", title: "Design notes", category: "Pages",
            detail: "A sample page about typography, spacing, and interaction design."),
        SearchFixture(
            id: "weekend", title: "Weekend itinerary", category: "Chats",
            detail: "A fictional weekend with a museum visit and a walk in the park.")
    ]
}
/// Front-end task settings only. These records never create a notification or server job.
public struct ScheduledTaskPresentation: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var instructions: String
    public var emoji: String
    public var status: String
    public var notify: Bool
    public var repeatRule: String
    public var interval: Int
    public var time: String
    public var endRepeat: String
    public var endDate: Date
    public init(
        id: UUID = UUID(), title: String = "", instructions: String = "", emoji: String = "⏰",
        status: String = "Active", notify: Bool = true, repeatRule: String = "Daily",
        interval: Int = 1, time: String = "Morning", endRepeat: String = "Never", endDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.emoji = emoji
        self.status = status
        self.notify = notify
        self.repeatRule = repeatRule
        self.interval = interval
        self.time = time
        self.endRepeat = endRepeat
        self.endDate = endDate
    }
    public var subtitle: String { status == "Active" ? "\(time) · \(repeatRule)" : status }
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (1...31).contains(interval)
    }
    public static let samples = [
        ScheduledTaskPresentation(
            title: "Daily reading roundup", instructions: "Summarize new articles from my sample reading list.",
            emoji: "📰"),
        ScheduledTaskPresentation(
            title: "Weekly project update", instructions: "Review the sample project milestones.", emoji: "💡",
            repeatRule: "Weekly"),
        ScheduledTaskPresentation(
            title: "Five-minute stretch reminder", instructions: "Remind me to stretch.", emoji: "⏰", status: "Paused"),
        ScheduledTaskPresentation(
            title: "Send daily learning digest", instructions: "Review my sample learning notes.", emoji: "🎓",
            status: "Paused"),
        ScheduledTaskPresentation(
            title: "Check project progress", instructions: "Summarize progress in my sample project.", emoji: "📋",
            status: "Paused"),
        ScheduledTaskPresentation(
            title: "Check design event listing", instructions: "Review the sample event schedule.", emoji: "💼",
            status: "Paused"),
        ScheduledTaskPresentation(
            title: "Monitor design updates", instructions: "Find changes in the sample design brief.", emoji: "💼",
            status: "Paused")
    ]
}

/// Owned by ChatState so navigation does not reset created, edited, or deleted tasks.
public struct ScheduledPresentationState: Equatable, Sendable {
    public private(set) var tasks: [ScheduledTaskPresentation]
    public var selectedTab = "Active"
    public init(tasks: [ScheduledTaskPresentation] = ScheduledTaskPresentation.samples) { self.tasks = tasks }
    public var visibleTasks: [ScheduledTaskPresentation] { tasks.filter { $0.status == selectedTab } }
    @discardableResult public mutating func save(_ value: ScheduledTaskPresentation) -> Bool {
        guard value.isValid else { return false }
        var task = value
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.instructions = task.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { tasks[index] = task } else { tasks.append(task) }
        selectedTab = task.status
        return true
    }
    public mutating func delete(id: UUID) { tasks.removeAll { $0.id == id } }
}

#if os(iOS)
    import SwiftUI

    /// Search is a presentation-only destination. The demo indexes fictional local entries.
    struct SearchDestinationView: View {
        @Bindable var state: ChatState
        var onClose: () -> Void
        @State private var selectedResult: SearchFixture?
        @State private var showFilters = false
        @FocusState private var focused: Bool
        private let categories = ["All", "Chats", "Pages", "Images"]
        private var results: [SearchFixture] {
            SearchFixture.matching(query: state.search, category: state.searchCategory)
        }
        private var queryIsEmpty: Bool { state.search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if queryIsEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "magnifyingglass").font(.system(size: 27)).foregroundStyle(.secondary)
                            Text("Search chats, files, and projects").font(.system(size: 17)).multilineTextAlignment(
                                .center)
                        }.frame(maxWidth: .infinity).padding(.top, geometry.size.height * 0.21)
                        Spacer()
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                showFilters = true
                            } label: {
                                Image(systemName: "slider.horizontal.3").font(.system(size: 20)).frame(
                                    width: 44, height: 44)
                            }.accessibilityLabel("Search filters")
                            ScrollView(.horizontal) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { item in
                                        Button {
                                            state.searchCategory = item
                                        } label: {
                                            Text(item).font(.system(size: 17)).padding(.horizontal, 17).frame(
                                                height: 44
                                            )
                                            .foregroundStyle(
                                                state.searchCategory == item ? Color.primary : Color.secondary
                                            )
                                            .background(
                                                state.searchCategory == item ? ChatDesign.raised : .clear, in: Capsule()
                                            )
                                        }.accessibilityAddTraits(state.searchCategory == item ? .isSelected : [])
                                            .accessibilityIdentifier("search.category.\(item)")
                                    }
                                }
                            }.scrollIndicators(.hidden)
                        }.padding(.top, 8).padding(.bottom, 14)
                        ScrollView {
                            LazyVStack(spacing: 22) {
                                ForEach(results) { result in
                                    Button {
                                        selectedResult = result
                                        state.onAction(.openDestination(result.title))
                                    } label: {
                                        HStack(spacing: 16) {
                                            SearchThumbnail(kind: result.category).frame(width: 40, height: 40)
                                                .accessibilityHidden(true)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.title).font(.system(size: 17)).foregroundStyle(.primary)
                                                    .lineLimit(2)
                                                Text(result.kindLabel).font(.system(size: 14)).foregroundStyle(
                                                    .secondary)
                                            }.frame(maxWidth: .infinity, alignment: .leading)
                                        }.contentShape(Rectangle())
                                    }
                                }
                                if results.isEmpty {
                                    Text("No results").font(.system(size: 17)).foregroundStyle(.secondary).padding(
                                        .top, 36)
                                }
                            }.padding(.horizontal, 12).padding(.top, 4)
                        }.scrollIndicators(.hidden)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").font(.system(size: 20)).accessibilityHidden(true)
                        TextField("Search", text: $state.search).font(.system(size: 17)).focused($focused)
                            .autocorrectionDisabled().accessibilityIdentifier("search.input")
                        if !state.search.isEmpty {
                            Button {
                                state.search = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(
                                    .secondary)
                            }.contentShape(Rectangle().inset(by: -12)).accessibilityLabel("Clear search")
                        }
                    }.padding(.horizontal, 18).frame(height: 48).glassEffect(.regular, in: Capsule())
                    Button {
                        focused = false
                        onClose()
                    } label: {
                        GlassCircle(symbol: "xmark", size: 48)
                    }
                    .accessibilityLabel("Close search")
                }.padding(.horizontal, 12).padding(.bottom, 12)
            }
            .buttonStyle(.plain).background(ChatDesign.canvas.ignoresSafeArea())
            .sheet(isPresented: $showFilters) {
                NavigationStack {
                    List {
                        Picker("Show", selection: $state.searchCategory) {
                            ForEach(categories, id: \.self) { Text($0) }
                        }.pickerStyle(.inline)
                    }
                    .navigationTitle("Search filters").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showFilters = false } } }
                }.presentationDetents([.medium])
            }
            .sheet(item: $selectedResult) { item in
                NavigationStack {
                    VStack(alignment: .leading, spacing: 24) {
                        if item.category == "Images" {
                            SearchThumbnail(kind: "Images").frame(height: 220).frame(maxWidth: .infinity)
                        }
                        Text(item.title).font(.title2.weight(.semibold))
                        Text(item.detail).font(.body)
                        Spacer()
                    }.padding(24).navigationTitle(item.kindLabel).navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) { Button("Done") { selectedResult = nil } }
                        }
                }
            }
        }
    }

    private struct SearchThumbnail: View {
        let kind: String
        var body: some View {
            RoundedRectangle(cornerRadius: 10).fill(ChatDesign.surface)
                .overlay {
                    if kind == "Images" {
                        GeometryReader { proxy in
                            ZStack {
                                Color.indigo.opacity(0.22)
                                Circle().fill(.orange.opacity(0.7)).frame(width: proxy.size.width * 0.23).offset(
                                    x: proxy.size.width * 0.19, y: -proxy.size.height * 0.18)
                                Image(systemName: "mountain.2.fill").resizable().scaledToFit().foregroundStyle(
                                    .indigo.opacity(0.7)
                                ).padding(5).offset(y: proxy.size.height * 0.16)
                            }
                        }.clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: kind == "Pages" ? "doc.text" : "bubble.left").foregroundStyle(.secondary)
                    }
                }
        }
    }

    /// In-memory scheduled-task fixtures. Saving changes the demo UI, never schedules a job.
    struct ScheduledDestinationView: View {
        @Bindable var state: ChatState
        @State private var editor: ScheduledTaskPresentation?
        private let tabs = ["Active", "Paused", "Completed"]
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        state.showsDrawer = true
                    } label: {
                        DrawerGlyph()
                    }.accessibilityLabel("Open sidebar")
                    Spacer()
                    Text("Scheduled").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }.padding(.horizontal, 16).padding(.top, 2)
                HStack(spacing: 8) {
                    ForEach(tabs, id: \.self) { item in
                        Button {
                            state.scheduled.selectedTab = item
                        } label: {
                            Text(item).font(.system(size: 17)).padding(.horizontal, 16).frame(height: 44)
                                .foregroundStyle(state.scheduled.selectedTab == item ? Color.primary : Color.secondary)
                                .background(
                                    state.scheduled.selectedTab == item ? ChatDesign.raised : .clear, in: Capsule())
                        }.accessibilityAddTraits(state.scheduled.selectedTab == item ? .isSelected : [])
                            .accessibilityIdentifier("schedule.tab.\(item)")
                    }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 16).padding(.top, 26).padding(.bottom, 30)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(state.scheduled.visibleTasks) { task in taskCard(task) }
                        if state.scheduled.selectedTab == "Active" {
                            Text("Recommended").font(.system(size: 17, weight: .semibold)).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 24).padding(.top, 28)
                            Button {
                                editor = ScheduledTaskPresentation(
                                    title: "Weekly design briefing",
                                    instructions:
                                        "Give me a weekly summary of design developments for my sample project.",
                                    emoji: "💼")
                            } label: {
                                HStack(spacing: 16) {
                                    Text("💼").font(.system(size: 23)).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Design industry developments").font(.system(size: 17))
                                        Text(
                                            "Give me a weekly scan of design developments that matter for my next project"
                                        ).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(
                                            .leading)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }.padding(20).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
                            }
                        } else if state.scheduled.visibleTasks.isEmpty {
                            Text("No \(state.scheduled.selectedTab.lowercased()) tasks").font(.system(size: 17))
                                .foregroundStyle(.secondary).padding(.top, 40)
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 96)
                }.scrollIndicators(.hidden)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    editor = ScheduledTaskPresentation()
                } label: {
                    Text("New task").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 20).frame(height: 48).background(state.accentColor, in: Capsule())
                        .glassEffect(.regular.tint(state.accentColor).interactive(), in: Capsule())
                }.accessibilityIdentifier("schedule.new").padding(.trailing, 32).padding(.bottom, 10)
            }
            .buttonStyle(.plain).background(ChatDesign.canvas.ignoresSafeArea())
            .sheet(item: $editor) { task in
                ScheduledTaskEditor(initial: task, accent: state.accentColor) { saved in
                    if state.scheduled.save(saved) { editor = nil }
                }
            }
        }
        private func taskCard(_ task: ScheduledTaskPresentation) -> some View {
            HStack(spacing: 16) {
                Button {
                    editor = task
                } label: {
                    HStack(spacing: 16) {
                        Text(task.emoji).font(.system(size: 23)).frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title).font(.system(size: 17)).multilineTextAlignment(.leading)
                            Text(task.subtitle).font(.system(size: 14)).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.contentShape(Rectangle())
                }
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive) { state.scheduled.delete(id: task.id) }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 20, weight: .semibold)).foregroundStyle(.secondary)
                        .frame(width: 28, height: 40)
                }.contentShape(Rectangle().inset(by: -8)).accessibilityLabel("Task options: \(task.title)")
                    .accessibilityIdentifier("schedule.options.\(task.id)")
            }.padding(.horizontal, 20).padding(.vertical, 18)
                .background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
                .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.primary.opacity(0.08), lineWidth: 1) }
        }
    }

    private struct ScheduledTaskEditor: View {
        @Environment(\.dismiss) private var dismiss
        @State private var draft: ScheduledTaskPresentation
        @State private var showInterval = false
        @State private var showEmoji = false
        @State private var chosenIcon = false
        let accent: Color
        let onSave: (ScheduledTaskPresentation) -> Void
        init(initial: ScheduledTaskPresentation, accent: Color, onSave: @escaping (ScheduledTaskPresentation) -> Void) {
            _draft = State(initialValue: initial)
            _chosenIcon = State(initialValue: !initial.title.isEmpty)
            self.accent = accent
            self.onSave = onSave
        }
        private var intervalLabel: String {
            let unit: String
            switch draft.repeatRule {
            case "Hourly": unit = "hour"
            case "Weekly": unit = "week"
            case "Monthly": unit = "month"
            default: unit = "day"
            }
            return draft.interval == 1 ? "Every \(unit)" : "Every \(draft.interval) \(unit)s"
        }
        private var valid: Bool { draft.isValid }
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }.accessibilityLabel("Cancel task")
                    Spacer()
                    Text("New task").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button {
                        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.instructions = draft.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(draft)
                    } label: {
                        Image(systemName: "checkmark").font(.system(size: 24)).foregroundStyle(.white)
                            .frame(width: 44, height: 44).background(valid ? accent : Color.gray, in: Circle())
                            .glassEffect(.regular.interactive(), in: Circle())
                    }.disabled(!valid).accessibilityLabel("Save task").accessibilityIdentifier("schedule.save")
                }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 34)
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            Button {
                                showEmoji = true
                            } label: {
                                if chosenIcon {
                                    Text(draft.emoji).font(.system(size: 22))
                                } else {
                                    Image(systemName: "face.smiling").font(.system(size: 20)).overlay(
                                        alignment: .topTrailing
                                    ) {
                                        Image(systemName: "plus").font(.system(size: 9, weight: .bold)).offset(
                                            x: 4, y: -2)
                                    }
                                }
                            }.foregroundStyle(.secondary).contentShape(Rectangle().inset(by: -12)).accessibilityLabel(
                                "Choose task icon"
                            ).accessibilityValue(draft.emoji)
                            TextField("Task name", text: $draft.title).accessibilityLabel("Task name")
                                .accessibilityIdentifier("schedule.title")
                        }.padding(.horizontal, 24).frame(height: 56).background(ChatDesign.surface, in: Capsule())
                            .overlay { Capsule().strokeBorder(.primary.opacity(0.08), lineWidth: 1) }
                        ZStack(alignment: .topLeading) {
                            if draft.instructions.isEmpty {
                                Text("Instructions").foregroundStyle(.tertiary).padding(.top, 17).padding(.leading, 24)
                                    .accessibilityHidden(true)
                            }
                            TextEditor(text: $draft.instructions).scrollContentBackground(.hidden).padding(
                                .horizontal, 19
                            ).padding(.vertical, 9)
                                .accessibilityLabel("Instructions").accessibilityIdentifier("schedule.instructions")
                        }.frame(height: 176).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
                            .overlay {
                                RoundedRectangle(cornerRadius: 28).strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                            }
                        Toggle("Notify when complete", isOn: $draft.notify).tint(.blue).padding(.horizontal, 24).frame(
                            height: 56
                        )
                        .background(ChatDesign.surface, in: Capsule()).accessibilityIdentifier("schedule.notify")
                        VStack(spacing: 0) {
                            choiceRow(
                                "Repeat", selection: $draft.repeatRule,
                                options: ["Never", "Hourly", "Daily", "Weekdays", "Weekly", "Monthly", "Custom"]
                            )
                            .accessibilityIdentifier("schedule.repeat")
                            if draft.repeatRule != "Never" {
                                Divider().padding(.leading, 24)
                                Button {
                                    showInterval = true
                                } label: {
                                    HStack {
                                        Text(intervalLabel)
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.secondary).padding(.horizontal, 24).frame(height: 56)
                                }.accessibilityLabel("Repeat interval")
                            }
                        }.background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
                        choiceRow("Time", selection: $draft.time, options: ["Morning", "Afternoon", "Evening", "Night"])
                            .background(ChatDesign.surface, in: Capsule()).accessibilityIdentifier("schedule.time")
                        choiceRow("End repeat", selection: $draft.endRepeat, options: ["Never", "On date"])
                            .background(ChatDesign.surface, in: Capsule())
                        if draft.endRepeat == "On date" {
                            DatePicker("End date", selection: $draft.endDate, displayedComponents: .date).padding(20)
                                .background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 24))
                        }
                    }.font(.system(size: 17)).padding(.horizontal, 16).padding(.bottom, 40)
                }.scrollIndicators(.hidden)
            }.buttonStyle(.plain).background(ChatDesign.canvas.ignoresSafeArea()).presentationDragIndicator(.hidden)
                .sheet(isPresented: $showInterval) {
                    NavigationStack {
                        Form { Stepper(intervalLabel, value: $draft.interval, in: 1...31) }
                            .navigationTitle("Repeat").navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) { Button("Done") { showInterval = false } }
                            }
                    }.presentationDetents([.medium])
                }
                .sheet(isPresented: $showEmoji) {
                    NavigationStack {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                            ForEach(["⏰", "📰", "💡", "🎓", "📋", "💼", "📚", "☀️", "🏃", "🧭", "🎨", "🌱"], id: \.self) { icon in
                                Button {
                                    draft.emoji = icon
                                    chosenIcon = true
                                    showEmoji = false
                                } label: {
                                    Text(icon).font(.system(size: 32)).frame(width: 54, height: 54)
                                }
                            }
                        }.padding(24).navigationTitle("Task icon").navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEmoji = false } }
                            }
                    }.presentationDetents([.medium])
                }
        }
        private func choiceRow(_ title: String, selection: Binding<String>, options: [String]) -> some View {
            Menu {
                Picker(title, selection: selection) { ForEach(options, id: \.self) { Text($0) } }
            } label: {
                HStack {
                    Text(title).foregroundStyle(.primary)
                    Spacer()
                    Text(selection.wrappedValue).foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary).padding(.leading, 8)
                }
                .padding(.horizontal, 24).frame(height: 56).contentShape(Rectangle())
            }.menuOrder(.fixed).accessibilityLabel(title).accessibilityValue(selection.wrappedValue)
        }
    }
#endif
