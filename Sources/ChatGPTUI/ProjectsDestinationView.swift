#if os(iOS)
import SwiftUI

public struct ProjectsDestinationView: View {
    @Bindable private var state: ProjectsPresentationState
    private let onSidebar: () -> Void
    private let content: ((String) -> AnyView?)?
    public init(state: ProjectsPresentationState, onSidebar: @escaping () -> Void, content: ((String) -> AnyView?)? = nil) { self.state = state; self.onSidebar = onSidebar; self.content = content }
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onSidebar) { DrawerGlyph() }.accessibilityLabel("Open sidebar")
                Spacer(); Text("Projects").font(.system(size: 17, weight: .semibold)); Spacer()
                Button { state.beginCreation() } label: { GlassCircle(symbol: "plus") }.accessibilityLabel("New project").accessibilityIdentifier("projects.add")
            }.padding(.horizontal, 16).padding(.top, 2)
            GeometryReader { geometry in
                if let content = content?(state.query) { content }
                else {
                    VStack(spacing: 16) {
                        Image(systemName: "folder").font(.system(size: 14, weight: .medium)).frame(width: 32, height: 32).background(.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 9))
                        Text("Start your first project").font(.system(size: 17))
                        Text("Projects help you organize chats, files, and\ntools in one place").font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3).padding(.top, -8)
                        Button { state.beginCreation() } label: { Text("New project").font(.system(size: 17, weight: .semibold)).padding(.horizontal, 21).frame(height: 40).foregroundStyle(ChatDesign.canvas).background(Color.primary, in: Capsule()) }.accessibilityIdentifier("projects.create")
                    }.frame(maxWidth: .infinity).position(x: geometry.size.width / 2, y: geometry.size.height * 0.55)
                }
            }
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").font(.system(size: 19)).foregroundStyle(.secondary)
                TextField("Search projects", text: $state.query, prompt: Text("Search projects").foregroundStyle(Color(uiColor: .secondaryLabel))).font(.system(size: 17)).accessibilityIdentifier("projects.search")
            }.padding(.horizontal, 15).frame(height: 48).glassEffect(.regular, in: Capsule()).padding(.horizontal, 34)
        }.background(ChatDesign.canvas).buttonStyle(.plain)
            .sheet(isPresented: $state.isCreating) { NewProjectForm(state: state).presentationDetents([.large]).presentationDragIndicator(.hidden) }
    }
}
private struct NewProjectForm: View {
    @Bindable var state: ProjectsPresentationState
    @FocusState private var nameFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { nameFocused = false; state.openMemorySettings() } label: { Text("Settings").font(.system(size: 17)).padding(.horizontal, 16).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule()) }.accessibilityIdentifier("projects.settings")
                Spacer()
                Button { state.cancelCreation() } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Cancel new project")
            }.overlay { Text("New project").font(.system(size: 17, weight: .semibold)).allowsHitTesting(false) }.padding(.horizontal, 16).padding(.top, 16)
            Text("Projects give ChatGPT shared context across\nchats and files, all in one place.").font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3).padding(.top, 10)
            HStack(spacing: 12) {
                Button { nameFocused = false; state.openIconPicker() } label: { ProjectGlyph(symbol: state.draft.hasCustomIcon ? state.draft.symbol : "smile-plus", size: 20).foregroundStyle(state.draft.hasCustomIcon ? projectIconColor(state.draft.color) : .secondary) }.accessibilityLabel("Choose project icon")
                TextField("Project Name", text: $state.draft.name).font(.system(size: 17)).focused($nameFocused).accessibilityIdentifier("projects.name")
            }.padding(.horizontal, 16).frame(height: 46).background(projectFieldBackground, in: RoundedRectangle(cornerRadius: 13)).padding(.horizontal, 20).padding(.top, 24)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    suggestion("Homework", symbol: "graduationcap", color: .blue)
                    suggestion("Writing", symbol: "pencil.tip", color: .purple)
                    suggestion("Health", symbol: "stethoscope", color: .red)
                }.padding(.horizontal, 20)
            }.scrollIndicators(.hidden).padding(.top, 20)
            Spacer()
            Button { nameFocused = false; state.submit() } label: { Text("Create project").font(.system(size: 17, weight: .medium)).frame(maxWidth: .infinity).frame(height: 52).foregroundStyle(ChatDesign.canvas).background(Color.primary, in: Capsule()) }.disabled(!state.canCreate).accessibilityIdentifier("projects.submit").padding(.horizontal, 20).padding(.bottom, 32)
        }.background(projectSheetBackground).buttonStyle(.plain)
            .sheet(isPresented: $state.showsIconPicker) { ProjectIconPicker(state: state).presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .sheet(isPresented: $state.showsMemorySettings) { ProjectMemorySettings(state: state).presentationDetents([.large]).presentationDragIndicator(.hidden) }
    }
    private func suggestion(_ title: String, symbol: String, color: Color) -> some View {
        Button { state.selectSuggestion(title, symbol: symbol, color: title == "Homework" ? "Blue" : title == "Writing" ? "Purple" : "Red") } label: {
            HStack(spacing: 8) { ProjectGlyph(symbol: symbol, size: 20).foregroundStyle(color); Text(title) }.font(.system(size: 17)).padding(.horizontal, 12).frame(height: 40).overlay { Capsule().stroke(.secondary.opacity(0.3), lineWidth: 1) }
        }.accessibilityIdentifier("projects.suggestion.\(title)")
    }
}
private struct ProjectMemorySettings: View {
    @Bindable var state: ProjectsPresentationState
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                pill("Cancel") { state.closeMemorySettings(save: false) }; Spacer()
                Text("Project settings").font(.system(size: 17, weight: .semibold)); Spacer()
                pill("Done") { state.closeMemorySettings(save: true) }
            }.padding(.bottom, 12)
            Text("Memory").font(.system(size: 15, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 4)
            memory(.standard, title: "Default memory", text: "This project can access memory from outside chats, and vice versa.")
            memory(.projectOnly, title: "Project-only memory", text: "This project can only access its own memory. Its memory is hidden from outside chats.")
            Spacer()
        }.padding(.horizontal, 16).padding(.top, 16).background(projectSheetBackground).buttonStyle(.plain)
    }
    private func pill(_ title: String, action: @escaping () -> Void) -> some View { Button(action: action) { Text(title).font(.system(size: 17)).padding(.horizontal, 16).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule()) } }
    private func memory(_ value: ProjectMemory, title: String, text: String) -> some View {
        Button { state.pendingMemory = value } label: {
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 17)); Text(text).font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(3) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 18)).overlay { RoundedRectangle(cornerRadius: 18).stroke(state.pendingMemory == value ? Color.blue : .secondary.opacity(0.3), lineWidth: state.pendingMemory == value ? 1.5 : 1) }
        }.accessibilityAddTraits(state.pendingMemory == value ? .isSelected : []).accessibilityIdentifier("projects.memory.\(value.rawValue)")
    }
}

private var projectSheetBackground: Color { Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.11, alpha: 1) : .secondarySystemBackground }) }
private var projectFieldBackground: Color { Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1) : .tertiarySystemFill }) }

private func projectIconColor(_ name: String) -> Color {
    switch name { case "Red": .red; case "Orange": .orange; case "Yellow": .yellow; case "Green": .green; case "Blue": .blue; case "Purple": .purple; default: .primary }
}
private struct ProjectIconPicker: View {
    @Bindable var state: ProjectsPresentationState
    private let symbols = ["folder", "dollarsign.circle", "book.closed", "graduationcap", "pencil", "pencil.tip", "curlybraces", "terminal", "music.note", "popcorn", "paintbrush.pointed", "paintpalette", "stethoscope", "staroflife", "leaf", "suitcase", "chart.bar", "figure.strengthtraining.functional", "dumbbell", "book.closed.circle", "scalemass", "globe.desk", "airplane", "globe", "wrench", "pawprint", "flask", "brain", "heart", "carrot"]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if state.iconHasChanges { pill("Cancel") { state.closeIconPicker(save: false) } }
                else { Color.clear.frame(width: 84, height: 44) }
                Spacer(); Text("Choose icon").font(.system(size: 17, weight: .semibold)); Spacer()
                pill("Done") { state.closeIconPicker(save: true) }
            }.padding(.horizontal, 16).padding(.top, 16)
            ProjectGlyph(symbol: state.pendingSymbol, size: 48).foregroundStyle(projectIconColor(state.pendingColor)).frame(height: 52).padding(.top, 40).accessibilityIdentifier("projects.icon.preview")
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(["Default", "Red", "Orange", "Yellow", "Green", "Blue", "Purple"], id: \.self) { color in
                        Button { state.pendingColor = color } label: {
                            Circle().fill(projectIconColor(color)).frame(width: 40, height: 40).overlay {
                                if state.pendingColor == color { Circle().stroke(projectSheetBackground, lineWidth: 4).frame(width: 28, height: 28) }
                            }
                        }.accessibilityLabel(color).accessibilityIdentifier("projects.color.\(color)").accessibilityAddTraits(state.pendingColor == color ? .isSelected : [])
                    }
                }.padding(.horizontal, 20)
            }.scrollIndicators(.hidden).padding(.top, 40)
            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 0.5).padding(.horizontal, 20).padding(.top, 32)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 22) {
                ForEach(symbols, id: \.self) { symbol in
                    Button { state.pendingSymbol = symbol } label: { ProjectGlyph(symbol: symbol, size: 28).foregroundStyle(state.pendingSymbol == symbol ? Color.secondary : Color.primary).frame(width: 38, height: 38).contentShape(Rectangle()) }.accessibilityLabel(symbol).accessibilityIdentifier("projects.icon.\(symbol)")
                }
            }.padding(.horizontal, 20).padding(.top, 38)
            Spacer()
        }.background(projectSheetBackground).buttonStyle(.plain)
    }
    private func pill(_ title: String, action: @escaping () -> Void) -> some View { Button(action: action) { Text(title).font(.system(size: 17)).padding(.horizontal, 16).frame(height: 44).glassEffect(.regular.interactive(), in: Capsule()) } }
}
/// Original outline approximations of the captured non-SF nib and smile-plus.
private struct ProjectGlyph: View {
    let symbol: String
    let size: CGFloat
    var body: some View {
        Group {
            if symbol == "pencil.tip" || symbol == "smile-plus" {
                Canvas { context, bounds in
                    let unit = bounds.width / 24
                    var path = Path()
                    if symbol == "pencil.tip" {
                        path.move(to: .init(x: 3, y: 22)); path.addLine(to: .init(x: 6, y: 7)); path.addLine(to: .init(x: 14, y: 3)); path.addLine(to: .init(x: 22, y: 10)); path.addLine(to: .init(x: 18, y: 19)); path.closeSubpath()
                        path.move(to: .init(x: 3, y: 22)); path.addLine(to: .init(x: 12, y: 13))
                        path.addEllipse(in: .init(x: 11, y: 10, width: 4, height: 4))
                    } else {
                        path.addArc(center: .init(x: 11, y: 13), radius: 9, startAngle: .degrees(-85), endAngle: .degrees(0), clockwise: true)
                        path.addArc(center: .init(x: 11, y: 13), radius: 5, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                        path.move(to: .init(x: 8, y: 10)); path.addLine(to: .init(x: 8, y: 10.5)); path.move(to: .init(x: 14, y: 10)); path.addLine(to: .init(x: 14, y: 10.5))
                        path.move(to: .init(x: 19, y: 1)); path.addLine(to: .init(x: 19, y: 9)); path.move(to: .init(x: 15, y: 5)); path.addLine(to: .init(x: 23, y: 5))
                    }
                    context.stroke(path.applying(.init(scaleX: unit, y: unit)), with: .foreground, style: .init(lineWidth: unit * 1.8, lineCap: .round, lineJoin: .round))
                }
            } else { Image(systemName: symbol).font(.system(size: size, weight: .regular)) }
        }.frame(width: size, height: size)
    }
}
#endif
