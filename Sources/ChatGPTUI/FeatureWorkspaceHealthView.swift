#if os(iOS)
import SwiftUI

public struct HealthWorkspaceView: View {
    @Bindable private var state: HealthWorkspaceState
    private let onBack: () -> Void
    @State private var notice: String?
    @State private var destination: HealthSecondaryDestination?
    public init(state: HealthWorkspaceState, onBack: @escaping () -> Void) { self.state = state; self.onBack = onBack }
    public var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: onBack) { DrawerGlyph() }.accessibilityLabel("Open sidebar"); Spacer(); Text("Health").font(.system(size: 17, weight: .semibold)); Spacer(); if state.setupComplete { Menu {
                Button(state.pinned ? "Unpin" : "Pin", systemImage: "pin.slash") { state.pinned.toggle() }
                Button("Apple Health", systemImage: "heart") { gap("Apple Health") }
                Button("Active conditions", systemImage: "list.clipboard") { state.step = .conditions; destination = .conditions }
                Button("Current medications", systemImage: "staroflife") { gap("Current medications") }
                Button("Family history", systemImage: "person.2") { gap("Family history") }
                Button("Help Center", systemImage: "questionmark.circle") { gap("Health Help Center") }
            } label: { GlassCircle(symbol: "ellipsis") }.accessibilityLabel("Health menu") } else { Color.clear.frame(width: 44, height: 44) } }.padding(.horizontal, 16)
            if state.setupComplete { connected } else { introduction }
        }.background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .sheet(isPresented: $state.setupPresented, onDismiss: { if state.setupPresented { state.cancelSetup() } }) { HealthSetupSheet(state: state).presentationDetents([.large]).presentationDragIndicator(.hidden).interactiveDismissDisabled() }
            .sheet(item: $destination, onDismiss: { state.searchPresented = false; state.searchQuery = "" }) { value in
                HealthSetupSheet(state: state, standalone: value).presentationDetents([.large]).presentationDragIndicator(.hidden)
            }
            .alert("UI reference needed", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private var introduction: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            Image(systemName: "heart.fill").font(.system(size: 25)).foregroundStyle(.white).frame(width: 44, height: 44).background(.red, in: RoundedRectangle(cornerRadius: 18)).rotationEffect(.degrees(-8)).padding(.bottom, 34)
            Text("Connect your health data").font(.system(size: 22, weight: .semibold)).padding(.bottom, 8)
            Text("Securely connect your medical records\nand Apple Health to ChatGPT").font(.system(size: 16)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer(minLength: 60)
            VStack(spacing: 0) { ForEach(Array(state.data.introductionMetrics.enumerated()), id: \.element.id) { index, item in metric(item); if index < state.data.introductionMetrics.count - 1 { Divider() } } }.padding(20).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 28)).mask { LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom) }.padding(.horizontal, 26)
            FeaturePrimaryButton("Continue") { state.beginSetup() }.accessibilityIdentifier("health.startSetup").padding(.horizontal, 34).padding(.bottom, 10)
        }
    }
    private var connected: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if state.showsSuggestions { suggestions.padding(.top, 34) }
                FeatureTabs(titles: ["Home", "Chats", "Records", "Accounts"], selection: $state.tab)
                switch state.tab {
                case "Home": activityCard
                case "Chats":
                    if !state.data.chats.isEmpty {
                        VStack(spacing: 16) { ForEach(state.data.chats) { chat in
                            Button { state.onAction(.openChat(chat.id)) } label: { VStack(alignment: .leading) { Text(chat.title); Text(chat.preview).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
                        } }.padding(.horizontal, 24)
                    } else { VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 25))
                        Text("Health chats will appear here").font(.system(size: 17))
                    }.foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 68) }
                case "Records":
                    VStack(spacing: 22) {
                        Text("📖").font(.system(size: 38))
                        Text("Make sense of your complete\nhealth history").font(.system(size: 17, weight: .semibold)).multilineTextAlignment(.center)
                        Button { destination = .providers } label: { Text("Connect").font(.system(size: 17, weight: .medium)).foregroundStyle(.black).padding(.horizontal, 24).frame(height: 44).background(.white, in: Capsule()) }
                    }.frame(maxWidth: .infinity).padding(.top, 90)
                case "Accounts": accounts
                default: EmptyView()
                }
            }.padding(.bottom, 100)
        }.scrollIndicators(.hidden).overlay(alignment: .bottom) {
            FeatureComposer(placeholder: "Ask ChatGPT", draft: $state.draft, onSend: { state.onAction(.startChat(state.draft)); gap("Health chat") }, onOpen: gap).padding(.horizontal, 34).padding(.bottom, 6)
        }
    }
    private var suggestions: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Get started").font(.system(size: 20, weight: .semibold)); Spacer()
                Button { state.showsSuggestions = false } label: { Image(systemName: "xmark").foregroundStyle(.secondary) }.accessibilityLabel("Hide health suggestions")
            }.padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach([("🔍", "Health history", "Summarize my health history."), ("❤️", "Health questions", "Help me prepare for my next visit.")], id: \.1) { item in
                        Button { state.onAction(.startChat(item.2)); gap("Health chat") } label: {
                            HStack(spacing: 16) {
                                Text(item.0).font(.system(size: 30))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.1).font(.system(size: 16, weight: .semibold))
                                    Text(item.2).font(.system(size: 15)).foregroundStyle(.secondary)
                                }
                            }.padding(20).frame(width: 320, height: 94).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 28)).overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.12)) }
                        }
                    }
                }.padding(.horizontal, 16)
            }.scrollIndicators(.hidden)
        }
    }
    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.data.activityTitle).font(.system(size: 20, weight: .semibold)).padding(.bottom, 12)
            ForEach(Array(state.data.activityMetrics.enumerated()), id: \.element.id) { index, item in
                metric(item); if index < state.data.activityMetrics.count - 1 { Divider() }
            }
        }.padding(22).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 28)).overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.17)) }.padding(.horizontal, 16)
    }
    private var accounts: some View {
        VStack(spacing: 16) {
            Button { destination = .providers } label: {
                HStack(spacing: 14) { Image(systemName: "plus").frame(width: 44, height: 44).background(ChatDesign.raised, in: Circle()); Text("Add account"); Spacer() }
            }.accessibilityIdentifier("health.add-account")
            Divider()
            ForEach(state.connectedProviders) { provider in Button { state.onAction(.openAccount(provider.id)) } label: {
                HStack(spacing: 14) {
                    Image(systemName: provider.symbol).foregroundStyle(provider.symbol == "heart.fill" ? .pink : .teal).frame(width: 44, height: 44).background(.white, in: Circle())
                    VStack(alignment: .leading, spacing: 4) { Text(provider.name); Text(provider.accountStatus).font(.system(size: 14)).foregroundStyle(.secondary) }; Spacer()
                }
            } }
        }.font(.system(size: 17)).padding(.horizontal, 16)
    }
    private func metric(_ item: HealthMetric) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) { Text(item.title).font(.system(size: 15)).foregroundStyle(.secondary); Text("\(Text(item.value).font(.system(size: 18, weight: .semibold))) \(Text(item.unit).font(.system(size: 13)).foregroundStyle(.secondary))") }; Spacer(); FeatureMiniChart(bars: item.bars, samples: item.boundedChartSamples).frame(width: 64, height: 40)
        }.padding(.vertical, 18)
    }
    private func gap(_ name: String) { state.onAction(.openDestination(name)); notice = "\(name) is awaiting a captured reference." }
}
struct FeatureMiniChart: View {
    var bars = true
    var samples: [Double]
    var body: some View { HStack(alignment: .bottom, spacing: 4) { ForEach(Array(samples.enumerated()), id: \.offset) { index, height in if bars { Capsule().fill(.blue).frame(width: 5, height: height * 40) } else { Circle().fill(.blue).frame(width: 5, height: 5).offset(y: -height * 40 * 0.45) } } }.accessibilityHidden(true) }
}
struct FeaturePrimaryButton: View {
    let title: String
    let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View { Button(action: action) { Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 54).background(.white, in: Capsule()) } }
}
enum HealthSecondaryDestination: String, Identifiable { case providers, conditions; var id: String { rawValue } }
struct HealthSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: HealthWorkspaceState
    var standalone: HealthSecondaryDestination? = nil
    @State private var notice: String?
    private var title: String { if standalone == .providers { return "Connect your health data" }; if standalone == .conditions && !state.searchPresented { return "Active conditions" }; if state.searchPresented { return state.step == .medications ? "Add new medication" : "Add new condition" }; switch state.step { case .accounts: return "Connect more accounts"; case .conditions: return "Add conditions"; case .medications: return "Add medications"; case .family: return "Review family history" } }
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if (standalone == nil && state.step != .accounts) || state.searchPresented { Button { state.back() } label: { GlassCircle(symbol: "chevron.left") }.accessibilityLabel("Back in health setup") } else { Color.clear.frame(width: 44, height: 44) }
                Spacer(); if standalone == nil { HStack(spacing: 4) { ForEach(0..<4) { index in Capsule().fill(index == state.step.rawValue ? .white : .white.opacity(0.25)).frame(width: index == state.step.rawValue ? 24 : 8, height: 4) } } }; Spacer()
                if state.step == .accounts || standalone != nil { Button { if standalone != nil { state.searchPresented = false; dismiss() } else { state.cancelSetup() } } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Cancel health setup") } else { Color.clear.frame(width: 44, height: 44) }
            }.padding(.horizontal, 16).padding(.top, 16)
            Text(title).font(.system(size: 22, weight: .semibold))
            if standalone == .providers { Text("We’ll securely sync your records").font(.system(size: 16)).foregroundStyle(.secondary) }
            if state.searchPresented { search }
            else {
                ScrollView {
                    if standalone == .providers { providers } else { switch state.step { case .accounts: providers; case .conditions, .medications: additions; case .family: family } }
                }.scrollIndicators(.hidden)
                if standalone != .providers { FeaturePrimaryButton(standalone != nil ? "Done" : state.step == .accounts ? "Continue" : state.step == .family ? "Done" : "Skip for now") { if standalone != nil { dismiss() } else { state.advance() } }.accessibilityIdentifier("health.setupContinue").padding(.horizontal, 34).padding(.bottom, 12) }
            }
        }.background(ChatDesign.surface.ignoresSafeArea()).buttonStyle(.plain)
            .alert("UI reference needed", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private var providers: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) { Image(systemName: "magnifyingglass"); TextField("Search", text: $state.providerQuery).accessibilityIdentifier("health.provider-search") }.font(.system(size: 17)).padding(16).overlay { Capsule().stroke(.white.opacity(0.2)) }
            ForEach(state.visibleProviders) { provider in
                Button { state.onAction(.connectProvider(provider.id)); notice = "The \(provider.name) connection flow belongs to the host and has not been captured here." } label: { HStack(spacing: 14) { Image(systemName: provider.symbol).font(.system(size: 24)).foregroundStyle(provider.symbol == "heart.fill" ? .pink : .teal).frame(width: 48, height: 48).background(.white, in: Circle()); VStack(alignment: .leading, spacing: 5) { Text(provider.name).font(.system(size: 17)); if let status = state.providerStatusText(provider) { Text(status).font(.system(size: 13)).foregroundStyle(.secondary) } }; Spacer(); Image(systemName: !state.providerIsSelected(provider) ? "plus" : "checkmark").font(.system(size: 21)).foregroundStyle(!state.providerIsSelected(provider) ? Color.secondary : Color.blue).frame(width: 34, height: 34).background(!state.providerIsSelected(provider) ? .clear : .blue.opacity(0.2), in: Circle()).overlay { if !state.providerIsSelected(provider) { Circle().stroke(.white.opacity(0.2)) } } } }
            }
        }.padding(.horizontal, 26).padding(.top, 12)
    }
    private var additions: some View {
        VStack(spacing: 14) {
            Text(state.step == .conditions ? "Add conditions that are representative of your current health" : "Add medications & supplements that you are currently taking").font(.system(size: 16)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.bottom, 20)
            outlinedRow(state.step == .conditions ? "Add new condition" : "Add new medication", symbol: "magnifyingglass") { state.searchQuery = ""; state.searchPresented = true }
            if standalone == nil { outlinedRow("Import from medical records", symbol: "list.clipboard") { state.onAction(.openDestination("Import medical records")); notice = "Medical record import has not yet been captured." } }
            ForEach(state.step == .conditions ? state.conditionItems : state.medicationItems, id: \.self) { Text($0).frame(maxWidth: .infinity, alignment: .leading).padding(16) }
        }.padding(.horizontal, 26)
    }
    private var family: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add conditions your close relatives have been diagnosed with").font(.system(size: 16)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.bottom, 18)
            Text("Cardiovascular").foregroundStyle(.secondary).padding(.horizontal, 4)
            ForEach(["Heart disease", "High blood pressure", "Stroke", "High cholesterol", "Atrial fibrillation"], id: \.self) { condition in outlinedRow(condition) { state.onAction(.openDestination("Family history: " + condition)); notice = "The family-member selection screen has not yet been captured." } }
            Text("Cancer").foregroundStyle(.secondary).padding(.top, 20)
            outlinedRow("Breast cancer") { state.onAction(.openDestination("Family history: Breast cancer")); notice = "The family-member selection screen has not yet been captured." }
        }.font(.system(size: 16)).padding(.horizontal, 26)
    }
    private var search: some View {
        VStack {
            ScrollView { VStack { ForEach(state.searchResults.filter { state.searchQuery.isEmpty || $0.localizedCaseInsensitiveContains(state.searchQuery) }, id: \.self) { result in Button { state.selectSearchResult(result) } label: { Text(result).frame(maxWidth: .infinity, alignment: .leading).padding(16) } } } }
            HStack(spacing: 12) { HStack { Image(systemName: "magnifyingglass"); TextField("Search", text: $state.searchQuery).accessibilityIdentifier("health.item-search") }.font(.system(size: 17)).padding(16).overlay { Capsule().stroke(.white.opacity(0.15)) }; Button { state.searchQuery = "" } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Clear health search") }.padding(.horizontal, 12).padding(.bottom, 12)
        }
    }
    private func outlinedRow(_ title: String, symbol: String? = nil, action: @escaping () -> Void) -> some View { Button(action: action) { HStack(spacing: 12) { if let symbol { Image(systemName: symbol).font(.system(size: 19)) }; Text(title).font(.system(size: 16, weight: .medium)); Spacer(); Image(systemName: "plus").font(.system(size: 21)).frame(width: 34, height: 34).overlay { Circle().stroke(.white.opacity(0.2)) } }.padding(.horizontal, 22).frame(minHeight: 60).overlay { Capsule().stroke(.white.opacity(0.2)) } } }
}
#endif
