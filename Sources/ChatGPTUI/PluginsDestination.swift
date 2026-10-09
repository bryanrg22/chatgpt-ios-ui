import Foundation

public enum PluginPermission: String, CaseIterable, Sendable {
    case ask = "Always ask", read = "Allow read actions", lowRisk = "Allow low-risk actions", all = "Allow all actions"
    public var shortLabel: String { self == .lowRisk ? "Allow low-risk" : rawValue }
    public var detail: String {
        switch self {
        case .ask: "ChatGPT will ask before reading or making changes."
        case .read: "ChatGPT can read without asking, but will ask before making changes."
        case .lowRisk: "ChatGPT will automatically approve low-risk actions but may deny actions involving sensitive information. Learn more"
        case .all: "ChatGPT won’t ask before reading or taking action. This comes with elevated risk. Learn more"
        }
    }
}
/// Presentation choices only. This state grants no actual service access or permissions.
public struct PluginCatalogPresentationState: Equatable, Sendable {
    public private(set) var installedIDs: Set<String>
    public private(set) var permissionOverrides: [String: PluginPermission] = [:]
    public private(set) var accounts: [String: [String]] = [:]
    public var search = ""
    public init(installedIDs: Set<String> = Set(PluginFixture.installed.map(\.id))) { self.installedIDs = installedIDs }
    public func permission(for id: String) -> PluginPermission { permissionOverrides[id] ?? .lowRisk }
    public mutating func setPermission(_ permission: PluginPermission, for id: String) {
        if permission == .lowRisk { permissionOverrides.removeValue(forKey: id) }
        else { permissionOverrides[id] = permission }
    }
    public mutating func resetPermission(for id: String) { permissionOverrides.removeValue(forKey: id) }
    public mutating func install(_ id: String) { installedIDs.insert(id) }
    public mutating func uninstall(_ id: String) { installedIDs.remove(id); permissionOverrides.removeValue(forKey: id); accounts.removeValue(forKey: id) }
    public func connectedAccounts(for id: String) -> [String] { accounts[id] ?? (installedIDs.contains(id) ? ["alex@example.com"] : []) }
    @discardableResult public mutating func addSampleAccount(_ email: String, for id: String) -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@"), !email.contains(" ") else { return false }
        var values = connectedAccounts(for: id)
        guard !values.contains(where: { $0.caseInsensitiveCompare(email) == .orderedSame }) else { return false }
        values.append(email); accounts[id] = values; installedIDs.insert(id); return true
    }
    public mutating func removeAccount(_ email: String, for id: String) { accounts[id] = connectedAccounts(for: id).filter { $0 != email } }
}

public struct PluginFixture: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let symbol: String
    public let tintName: String
    public init(id: String, name: String, subtitle: String, symbol: String, tintName: String) {
        self.id = id; self.name = name; self.subtitle = subtitle; self.symbol = symbol; self.tintName = tintName
    }
    public static var all: [PluginFixture] { installed + popular.filter { !installed.contains($0) } + noteworthy }
    public static let installed = [
        PluginFixture(id: "figma", name: "Figma", subtitle: "Design and collaborate", symbol: "square.stack.3d.up.fill", tintName: "purple"),
        PluginFixture(id: "youtube", name: "YouTube", subtitle: "Find and explore videos", symbol: "play.rectangle", tintName: "red"),
        PluginFixture(id: "docs", name: "Google Docs", subtitle: "Create and edit documents", symbol: "doc.text.fill", tintName: "blue"),
        PluginFixture(id: "cash", name: "Cash App", subtitle: "Review sample finances", symbol: "dollarsign.circle.fill", tintName: "green"),
        PluginFixture(id: "github", name: "GitHub", subtitle: "Explore projects and code", symbol: "chevron.left.forwardslash.chevron.right", tintName: "white"),
        PluginFixture(id: "gmail", name: "Gmail", subtitle: "Read and manage Gmail", symbol: "envelope.fill", tintName: "red"),
        PluginFixture(id: "drive", name: "Google Drive", subtitle: "Drive, Docs, Sheets or Slides", symbol: "externaldrive.fill", tintName: "green")
    ] + ["Notion", "Slack", "Calendar", "Linear", "Dropbox", "OneDrive", "Maps", "Weather", "Tasks", "Notes", "Photos", "Contacts"].map {
        PluginFixture(id: $0.lowercased(), name: $0, subtitle: "Explore your sample workspace", symbol: "square.grid.2x2.fill", tintName: "blue")
    }
    static let popular = [installed[5], PluginFixture(id: "desktop", name: "Remote Desktop Commander", subtitle: "Build and automate, anywhere", symbol: "desktopcomputer", tintName: "white"), installed[6], PluginFixture(id: "flaim", name: "Flaim Fantasy", subtitle: "Fantasy Sports Analysis", symbol: "flame", tintName: "white")]
    static let noteworthy = [PluginFixture(id: "adobe", name: "Adobe", subtitle: "Design, combine, and edit", symbol: "a.square.fill", tintName: "red"), PluginFixture(id: "ideas", name: "Ideas", subtitle: "Plan your next project", symbol: "lightbulb", tintName: "yellow")]
}

#if os(iOS)
import SwiftUI

struct PluginsDestinationView: View {
    private enum Route: Equatable { case catalog, installed, detail, settings, permissions }
    @Bindable var state: ChatState
    @State private var route = Route.catalog
    @State private var selected = PluginFixture.installed[5]
    @State private var showAccount = false
    @State private var email = "alex.work@example.com"
    @State private var actionDetail: String?
    private let readActions = ["Batch read email", "Batch read email threads", "Batch read thread", "Get profile", "Get recent emails", "Search email"]
    private var title: String {
        switch route { case .catalog: "Plugins"; case .installed: "Installed"; case .detail, .permissions: selected.name; case .settings: "" }
    }
    private func back() {
        switch route { case .catalog: state.goBack(); case .installed, .detail: route = .catalog; case .settings: route = .detail; case .permissions: route = .settings }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: back) { GlassCircle(symbol: "chevron.left") }.accessibilityLabel("Back")
                Spacer(); Text(title).font(.system(size: 17, weight: .semibold)); Spacer()
                if route == .detail {
                    Button { route = .settings } label: { GlassCircle(symbol: "gearshape") }.accessibilityLabel("Plugin settings").accessibilityIdentifier("plugins.settings")
                } else if route == .settings {
                    Menu {
                        Button("Remove plugin", systemImage: "trash", role: .destructive) { state.pluginCatalog.uninstall(selected.id); route = .catalog }
                    } label: { GlassCircle(symbol: "ellipsis") }.accessibilityLabel("Plugin options")
                } else { Color.clear.frame(width: 44, height: 44) }
            }.padding(.horizontal, 16).padding(.top, 2).padding(.bottom, route == .permissions ? 42 : 24)
            ScrollView {
                switch route {
                case .catalog: catalog
                case .installed: VStack(spacing: 30) { ForEach(PluginFixture.all.filter { state.pluginCatalog.installedIDs.contains($0.id) }) { row($0) } }.padding(.horizontal, 16)
                case .detail: detail
                case .settings: settings
                case .permissions: permissions
                }
            }.scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            if route == .catalog {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search plugins", text: $state.pluginCatalog.search).accessibilityIdentifier("plugins.search")
                    if !state.pluginCatalog.search.isEmpty { Button { state.pluginCatalog.search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.accessibilityLabel("Clear plugin search") }
                }.font(.system(size: 17)).padding(.horizontal, 16).frame(height: 48).glassEffect(.regular, in: Capsule()).padding(.horizontal, 32).padding(.bottom, 10)
            } else if route == .detail {
                Button { tryPrompt("@\(selected.name) ") } label: {
                    Text("Try in chat").font(.system(size: 17, weight: .medium)).foregroundStyle(Color.adaptive(dark: 0, light: 1)).frame(maxWidth: .infinity).frame(height: 54).background(Color.adaptive(dark: 1, light: 0), in: Capsule())
                }.padding(.horizontal, 32).padding(.bottom, 10).accessibilityIdentifier("plugins.tryInChat")
            }
        }
        .buttonStyle(.plain).background(ChatDesign.canvas.ignoresSafeArea())
        .alert("Connect sample account", isPresented: $showAccount) {
            TextField("Email", text: $email).textInputAutocapitalization(.never).autocorrectionDisabled()
            Button("Add sample") { _ = state.pluginCatalog.addSampleAccount(email, for: selected.id) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Only a local demo account is added. No sign-in or external connection occurs.") }
        .sheet(isPresented: Binding(get: { actionDetail != nil }, set: { if !$0 { actionDetail = nil } })) {
            NavigationStack {
                Form {
                    Text(actionDetail ?? "Read action").font(.headline)
                    Text("Read information from the sample connected account.")
                    Text("No service request runs in this offline demo.").foregroundStyle(.secondary)
                }.navigationTitle("Read action").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { actionDetail = nil } } }
            }.presentationDetents([.medium])
        }
    }
    private var catalog: some View {
        VStack(alignment: .leading, spacing: 32) {
            if state.pluginCatalog.search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 24) {
                    Button { route = .installed } label: { sectionTitle("Installed") }
                    HStack(spacing: 12) {
                        ForEach(Array(PluginFixture.all.filter { state.pluginCatalog.installedIDs.contains($0.id) }.prefix(5))) { plugin in
                            Button { selected = plugin; route = .detail } label: { PluginSymbol(plugin: plugin, size: 48) }.accessibilityLabel(plugin.name)
                        }
                        Button { route = .installed } label: {
                            Text("+\(max(0, state.pluginCatalog.installedIDs.count - 5))").font(.system(size: 17, weight: .semibold)).frame(width: 48, height: 48).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 14))
                        }.accessibilityLabel("Show all installed plugins")
                    }
                }
                VStack(alignment: .leading, spacing: 28) {
                    sectionTitle("Popular")
                    ForEach(PluginFixture.popular) { row($0) }
                }
                VStack(alignment: .leading, spacing: 28) {
                    sectionTitle("New & Noteworthy")
                    ForEach(PluginFixture.noteworthy) { row($0) }
                }.padding(.top, 16)
            } else {
                let query = state.pluginCatalog.search.trimmingCharacters(in: .whitespacesAndNewlines)
                let all = PluginFixture.all
                ForEach(all.filter { ($0.name + " " + $0.subtitle).localizedCaseInsensitiveContains(query) }) { row($0) }
            }
        }.padding(.horizontal, 16).padding(.bottom, 24)
    }
    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 6) { Text(title).font(.system(size: 17, weight: .semibold)); Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)) }.foregroundStyle(.secondary)
    }
    private func row(_ plugin: PluginFixture) -> some View {
        HStack(spacing: 16) {
            Button { selected = plugin; route = .detail } label: {
                HStack(spacing: 16) {
                    PluginSymbol(plugin: plugin, size: 48)
                    VStack(alignment: .leading, spacing: 4) { Text(plugin.name).font(.system(size: 17)); Text(plugin.subtitle).font(.system(size: 14)).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading)
                }.contentShape(Rectangle())
            }.accessibilityIdentifier("plugins.row.\(plugin.id)")
            Button {
                selected = plugin
                if state.pluginCatalog.installedIDs.contains(plugin.id) { route = .settings }
                else { state.pluginCatalog.install(plugin.id); route = .detail }
            } label: { Image(systemName: state.pluginCatalog.installedIDs.contains(plugin.id) ? "ellipsis" : "plus").font(.system(size: 20)).foregroundStyle(.secondary).frame(width: 28, height: 44) }
                .accessibilityLabel(state.pluginCatalog.installedIDs.contains(plugin.id) ? "Settings for \(plugin.name)" : "Add \(plugin.name)")
        }
    }
    private var detail: some View {
        VStack(alignment: .leading, spacing: 22) {
            PluginSymbol(plugin: selected, size: 56)
            VStack(alignment: .leading, spacing: 8) { Text(selected.name).font(.system(size: 28)); Text(selected.subtitle).font(.system(size: 17)).foregroundStyle(.secondary) }
            VStack(spacing: 16) {
                promptCard("Summarize the latest messages in my project thread and list the decisions and next steps.")
                promptCard("Draft a friendly reply to the latest project update with a short list of what we will provide.")
                promptCard("Turn the latest conversation into an action tracker with owners, deadlines, and a reference for each item.")
            }.padding(20).background(LinearGradient(colors: [Color(red: 0.67, green: 0.89, blue: 0.98), Color(red: 0.34, green: 0.73, blue: 0.86), Color(red: 0.43, green: 0.72, blue: 0.58)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
            Text("Use \(selected.name) to explore information, organize your work, and prepare useful next steps.").font(.system(size: 17)).foregroundStyle(.secondary)
        }.padding(.horizontal, 20).padding(.bottom, 20)
    }
    private func promptCard(_ prompt: String) -> some View {
        Button { tryPrompt("@\(selected.name) \(prompt)") } label: {
            HStack(spacing: 16) {
                (Text("@\(selected.name) ").bold() + Text(prompt)).font(.system(size: 17)).foregroundStyle(.black).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").font(.system(size: 18)).foregroundStyle(.black).frame(width: 32, height: 32).background(.white, in: Circle())
            }.padding(16).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 20)).overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.4), lineWidth: 1) }
        }
    }
    private func tryPrompt(_ prompt: String) { state.draft = prompt; state.open(.chat); state.onAction(.openDestination("Try \(selected.name) in chat")) }
    private var settings: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                PluginSymbol(plugin: selected, size: 48)
                Text(selected.name).font(.system(size: 22, weight: .semibold))
                Text(selected.subtitle).font(.system(size: 17)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
            Text("Connected accounts").font(.system(size: 17, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 2)
            VStack(spacing: 0) {
                ForEach(state.pluginCatalog.connectedAccounts(for: selected.id), id: \.self) { account in
                    HStack(spacing: 12) {
                        Text("AM").font(.system(size: 11, weight: .semibold)).frame(width: 32, height: 32).background(.teal.opacity(0.5), in: Circle()).accessibilityHidden(true)
                        Text(account).font(.system(size: 17)).lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        Menu { Button("Disconnect", systemImage: "minus.circle", role: .destructive) { state.pluginCatalog.removeAccount(account, for: selected.id) } } label: { Image(systemName: "ellipsis").frame(width: 32, height: 44) }.accessibilityLabel("Account options for \(account)")
                    }.padding(.horizontal, 16).frame(height: 70)
                    Divider().padding(.leading, 60).padding(.trailing, 16)
                }
                Button { showAccount = true } label: {
                    HStack(spacing: 12) { Image(systemName: "plus").font(.system(size: 23)).frame(width: 32, height: 32).background(ChatDesign.raised, in: Circle()); Text("Connect another account").font(.system(size: 17)); Spacer() }.padding(.horizontal, 16).frame(height: 58)
                }
            }.background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28)).padding(.top, -10)
            Button { route = .permissions } label: { SettingsRow(title: "Permissions", icon: "shield", detail: state.pluginCatalog.permission(for: selected.id).shortLabel) }.background(ChatDesign.surface, in: Capsule()).accessibilityIdentifier("plugins.permissions")
            Text("Read actions").font(.system(size: 17, weight: .semibold)).foregroundStyle(.secondary)
            VStack(spacing: 0) {
                ForEach(readActions, id: \.self) { action in
                    Button { actionDetail = action } label: { SettingsRow(title: action) }
                    if action != readActions.last { Divider().padding(.horizontal, 16) }
                }
            }.background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28)).padding(.top, -10)
        }.padding(.horizontal, 20).padding(.bottom, 24)
    }
    private var permissions: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
                ForEach(PluginPermission.allCases, id: \.self) { permission in
                    Button { state.pluginCatalog.setPermission(permission, for: selected.id) } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(permission.rawValue).font(.system(size: 17))
                                    if permission == .lowRisk { riskBadge("DEFAULT", color: .blue) }
                                    if permission == .all { riskBadge("ELEVATED RISK", color: .orange) }
                                }
                                Text(permission.detail).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: state.pluginCatalog.permission(for: selected.id) == permission ? "checkmark.circle.fill" : "circle").font(.system(size: 22)).foregroundStyle(state.pluginCatalog.permission(for: selected.id) == permission ? .blue : Color.secondary)
                        }.padding(.vertical, 12).padding(.horizontal, 16).contentShape(Rectangle())
                    }.accessibilityAddTraits(state.pluginCatalog.permission(for: selected.id) == permission ? .isSelected : []).accessibilityIdentifier("plugins.permission.\(permission.rawValue)")
                    if permission != PluginPermission.allCases.last { Divider().padding(.horizontal, 16) }
                }
            }.background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 28))
            Text("Choose when ChatGPT should ask for permission when using this plugin.").font(.system(size: 13)).foregroundStyle(.secondary).padding(.horizontal, 16)
            Button { state.pluginCatalog.resetPermission(for: selected.id) } label: {
                Text("Reset to default").font(.system(size: 17)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).frame(height: 52).background(ChatDesign.surface, in: Capsule())
            }.disabled(state.pluginCatalog.permissionOverrides[selected.id] == nil).padding(.top, 4).accessibilityIdentifier("plugins.resetPermission")
            Text("Clear this plugin’s override to use your default setting.").font(.system(size: 13)).foregroundStyle(.secondary).padding(.horizontal, 16)
        }.padding(.horizontal, 16).padding(.bottom, 24)
    }
    private func riskBadge(_ title: String, color: Color) -> some View { Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(color).padding(.horizontal, 7).padding(.vertical, 2).background(color.opacity(0.22), in: Capsule()) }
}
private struct PluginSymbol: View {
    let plugin: PluginFixture
    let size: CGFloat
    private var tint: Color {
        switch plugin.tintName { case "red": .red; case "green": .green; case "purple": .purple; case "yellow": .yellow; case "blue": .blue; default: .primary }
    }
    var body: some View {
        Image(systemName: plugin.symbol).font(.system(size: size * 0.58, weight: .medium)).foregroundStyle(tint).frame(width: size, height: size).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: size * 0.25)).overlay { RoundedRectangle(cornerRadius: size * 0.25).strokeBorder(.primary.opacity(0.12), lineWidth: 1) }.accessibilityHidden(true)
    }
}
#endif
