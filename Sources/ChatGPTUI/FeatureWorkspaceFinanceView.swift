#if os(iOS)
import SwiftUI

public struct FinanceWorkspaceView: View {
    @Bindable private var state: FinanceWorkspaceState
    private let onBack: () -> Void
    @State private var showsConnect = false
    @State private var showsCustomize = false
    @State private var showsFilter = false
    @State private var datesExpanded = false
    @State private var notice: String?
    public init(state: FinanceWorkspaceState, onBack: @escaping () -> Void) { self.state = state; self.onBack = onBack }
    public var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: onBack) { DrawerGlyph() }.accessibilityLabel("Open sidebar"); Spacer(); Text("Finances").font(.system(size: 17, weight: .semibold)); Spacer(); menu }.padding(.horizontal, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if state.showsSuggestions { suggestions.padding(.top, 34) }
                    FeatureTabs(titles: ["Dashboard", "Chats", "Accounts", "Transactions"], selection: $state.tab).padding(.top, 12)
                    Group { switch state.tab { case "Accounts": accounts; case "Transactions": transactions; case "Chats": chats; default: dashboard } }.padding(.horizontal, 16)
                }.padding(.bottom, 80)
            }.scrollIndicators(.hidden)
        }.overlay(alignment: .bottom) { FeatureComposer(placeholder: "Ask Finances", draft: $state.draft, onSend: { state.beginChat(state.draft) }, onOpen: gap).padding(.horizontal, 34).padding(.bottom, 6) }
            .background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .sheet(isPresented: $showsConnect, onDismiss: { if let prompt = state.pendingChat { state.pendingChat = nil; if prompt == "cash" { state.beginCashChat() } else { state.beginChat(prompt) } } }) { FinanceConnectSheet(state: state, onClose: { showsConnect = false }).presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .sheet(isPresented: $showsCustomize) { FinanceCustomizeSheet(state: state).presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .fullScreenCover(isPresented: $state.chatPresented) { FinanceChatView(state: state) }
            .alert("UI reference needed", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private var menu: some View {
        Menu {
            Button { state.pinned.toggle() } label: { Label(state.pinned ? "Unpin" : "Pin", systemImage: "pin.slash") }
            Button { state.hidesValues.toggle() } label: { Label(state.hidesValues ? "Show values" : "Hide values", systemImage: "eye.slash") }
            Button { showsCustomize = true } label: { Label("Customize dashboard", systemImage: "slider.horizontal.3") }
            Button { gap("Financial memories") } label: { Label("Financial memories", systemImage: "square.and.pencil") }
            Button { gap("Help Center") } label: { Label("Help Center", systemImage: "questionmark.circle") }
        } label: { GlassCircle(symbol: "ellipsis") }.accessibilityLabel("Finance menu")
    }
    private var suggestions: some View {
        VStack(spacing: 12) {
            HStack { Text("Get started").font(.system(size: 20, weight: .semibold)); Spacer(); Button { state.showsSuggestions = false } label: { Image(systemName: "xmark").foregroundStyle(.secondary) }.accessibilityLabel("Hide finance suggestions") }.padding(.horizontal, 16)
            ScrollView(.horizontal) { HStack(spacing: 10) { suggestion("🔍", "Fraud review", "Review my recent transactions for unfamiliar charges or unusual activity."); suggestion("💡", "Tips", "What financial tips should I consider based on my information?") }.padding(.horizontal, 16) }.scrollIndicators(.hidden)
        }
    }
    private func suggestion(_ emoji: String, _ title: String, _ detail: String) -> some View { Button { state.beginChat(detail) } label: { HStack(spacing: 16) { Text(emoji).font(.system(size: 30)); VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 16, weight: .semibold)); Text(detail).font(.system(size: 15)).foregroundStyle(.secondary).lineLimit(2) } }.padding(20).frame(width: 320, height: 94, alignment: .leading).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 28)).overlay { RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.12)) } } }
    private var dashboard: some View {
        VStack(spacing: 18) {
            ForEach(state.dashboardOrder.filter { state.shownDashboardCards.contains($0) }, id: \.self) { title in
                if title == "Spend by category" { if state.data.spendingTotal != nil || !state.data.spendingCategories.isEmpty { spending } }
                else if let value = state.data.dashboardValues[title] { VStack(alignment: .leading, spacing: 15) { Text(title).font(.system(size: 18, weight: .semibold)); Text(state.displayValue(value)).font(.system(size: 24)).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(24).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 26)) }
            }
        }
    }
    private var spending: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack { Text("Spending").fontWeight(.semibold); Spacer(); if let total = state.data.spendingTotal { Text(state.formattedAmount(total)).fontWeight(.semibold) } }.font(.system(size: 18))
            Button { gap("Spending date range") } label: { HStack { Text(state.data.spendingPeriod); Image(systemName: "chevron.down").foregroundStyle(.secondary) }.font(.system(size: 14)) }.padding(.top, -15)
            Divider()
            GeometryReader { geometry in HStack(spacing: 2) { ForEach(Array(state.data.boundedSpendingSegments.enumerated()), id: \.offset) { index, fraction in RoundedRectangle(cornerRadius: 3).fill(Color.green.opacity(max(0.15, 1 - Double(index) * 0.15))).frame(width: max(0, geometry.size.width - Double(max(0, state.data.spendingSegments.count - 1)) * 2) * fraction) } } }.frame(height: 40)
            ForEach(state.data.spendingCategories) { category in
                HStack(spacing: 14) { FeatureGlyph(symbol: category.symbol); VStack(alignment: .leading, spacing: 6) { Text(category.title).font(.system(size: 16)); Capsule().fill(.green.opacity(0.8)).frame(width: 148 * category.boundedBarWidth, height: 4) }; Spacer(); Text(state.formattedAmount(category.amount)).font(.system(size: 16)) }; Divider()
            }
        }.padding(24).background(ChatDesign.surface, in: RoundedRectangle(cornerRadius: 26)).overlay { RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.15)) }
    }
    private var accounts: some View {
        VStack(spacing: 18) {
            Button { state.connectionTab = "Accounts"; showsConnect = true } label: { HStack(spacing: 16) { FeatureGlyph(symbol: "plus", size: 40); Text("Add account").font(.system(size: 15, weight: .semibold)); Spacer() } }.padding(.vertical, 10)
            Divider()
            ForEach(state.data.accountGroups) { group in
                Button { state.toggleGroup(group.id) } label: { HStack { VStack(alignment: .leading, spacing: 4) { Text(group.title).font(.system(size: 15, weight: .semibold)); Text(group.subtitle).font(.system(size: 12)).foregroundStyle(.secondary) }; Spacer(); Text(state.formattedAmount(group.balance)); Image(systemName: state.expandedAccountGroups.contains(group.id) ? "chevron.up" : "chevron.down") } }
                if state.expandedAccountGroups.contains(group.id) { ForEach(group.accounts) { account in Button { state.onAction(.openAccount(account.id)) } label: { HStack(spacing: 16) { Image(systemName: account.symbol).font(.system(size: 22)).foregroundStyle(.teal).frame(width: 40, height: 40).background(.white, in: Circle()); VStack(alignment: .leading, spacing: 5) { Text(account.title).font(.system(size: 14)); Text(account.subtitle).font(.system(size: 12)).foregroundStyle(.secondary) }; Spacer(); VStack(alignment: .trailing, spacing: 5) { Text(state.formattedAmount(account.balance)); Text(account.updated).font(.system(size: 12)).foregroundStyle(.secondary) } }.padding(.vertical, 12) } } }
                Divider()
            }
        }.font(.system(size: 15))
    }
    private var chats: some View {
        VStack(spacing: 16) { ForEach(state.data.chats) { chat in Button { state.onAction(.openChat(chat.id)) } label: { VStack(alignment: .leading, spacing: 2) { Text(chat.title); Text(chat.preview).foregroundStyle(.secondary) }.font(.system(size: 17)).frame(maxWidth: .infinity, alignment: .leading) }; Divider() } }.padding(.horizontal, 8)
    }
    private var transactions: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) { HStack { Image(systemName: "magnifyingglass"); TextField("Search transactions", text: $state.query).accessibilityIdentifier("finance.transaction-search") }.font(.system(size: 14)).padding(12).background(ChatDesign.raised, in: Capsule()); Button { showsFilter.toggle() } label: { Image(systemName: "line.3.horizontal.decrease").font(.system(size: 19)).frame(width: 36, height: 36) }.accessibilityLabel("Filter transactions") }
            if showsFilter { filterPanel }
            ForEach(state.visibleTransactions) { transaction in
                VStack(alignment: .leading, spacing: 18) { Text(transaction.date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 14)).foregroundStyle(.secondary); HStack(spacing: 12) { FeatureGlyph(symbol: transaction.amount > 0 ? "banknote" : "arrow.left.arrow.right"); VStack(alignment: .leading, spacing: 8) { Text(transaction.name).lineLimit(1); Text("\(transaction.category) · \(transaction.account)").foregroundStyle(.secondary).lineLimit(1) }; Spacer(minLength: 0); VStack(alignment: .trailing, spacing: 8) { Text(state.formattedAmount(transaction.amount)).foregroundStyle(transaction.amount > 0 ? .green : .primary); if transaction.pending { Text("Pending").foregroundStyle(.secondary) } } }.font(.system(size: 16)); Divider() }
            }
        }.padding(.horizontal, 8)
    }
    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Date").foregroundStyle(.secondary)
            Button { datesExpanded.toggle() } label: { HStack { Label(state.dateFilter, systemImage: "calendar"); Spacer(); Image(systemName: datesExpanded ? "chevron.down" : "chevron.right") }.contentShape(Rectangle()) }.accessibilityIdentifier("finance.filter.dates")
            if datesExpanded { ForEach(["All dates", "This month", "Last month", "This year", "Last year"], id: \.self) { value in Button { state.dateFilter = value; datesExpanded = false; showsFilter = false } label: { HStack { Text(value); Spacer(); if state.dateFilter == value { Image(systemName: "checkmark") } }.frame(height: 24).contentShape(Rectangle()) }.accessibilityIdentifier("finance.filter.date." + value) } }
            Divider(); Text("Account").foregroundStyle(.secondary); Button { gap("Transaction account filter") } label: { Label(state.accountFilter, systemImage: "wallet.pass").frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()) }.accessibilityIdentifier("finance.filter.accounts")
            Divider(); Text("Category").foregroundStyle(.secondary); Button { gap("Transaction category filter") } label: { Label(state.categoryFilter, systemImage: "folder").frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()) }.accessibilityIdentifier("finance.filter.categories")
        }.font(.system(size: 14)).padding(18).frame(maxWidth: 250).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 24)).frame(maxWidth: .infinity, alignment: .trailing)
    }
    private func gap(_ name: String) { state.onAction(.openDestination(name)); notice = "\(name) is awaiting a captured reference." }
}
struct FeatureTabs: View {
    let titles: [String]
    @Binding var selection: String
    var body: some View { ScrollViewReader { proxy in ScrollView(.horizontal) { HStack(spacing: 8) { ForEach(titles, id: \.self) { title in Button { selection = title; withAnimation { proxy.scrollTo(title, anchor: .center) } } label: { Text(title).font(.system(size: 17)).foregroundStyle(selection == title ? .primary : .secondary).padding(.horizontal, 16).frame(height: 44).background(selection == title ? ChatDesign.raised : .clear, in: Capsule()) }.id(title) } }.padding(.horizontal, 16) }.scrollIndicators(.hidden) } }
}
struct FeatureGlyph: View { let symbol: String; var size: CGFloat = 32; var body: some View { Image(systemName: symbol).font(.system(size: size * 0.48)).frame(width: size, height: size).background(.white.opacity(0.10), in: Circle()) } }
struct FeatureComposer: View {
    let placeholder: String
    @Binding var draft: String
    let onSend: () -> Void
    let onOpen: (String) -> Void
    var body: some View { HStack(spacing: 14) { Button { onOpen("Attachments") } label: { Image(systemName: "plus").font(.system(size: 24)) }.accessibilityLabel("Feature attachments"); TextField(placeholder, text: $draft, axis: .vertical).font(.system(size: 17)).lineLimit(1...6); Button { onOpen("Dictation") } label: { Image(systemName: "mic").font(.system(size: 22)) }.accessibilityLabel("Feature dictation"); Button { if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { onOpen("Voice") } else { onSend() } } label: { Group { if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { VoiceBars() } else { Image(systemName: "arrow.up").font(.system(size: 20, weight: .semibold)) } }.foregroundStyle(.white).frame(width: 34, height: 34).background(ChatDesign.blue, in: Circle()) }.accessibilityLabel(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Feature voice" : "Send feature message") }.padding(.horizontal, 14).padding(.vertical, 7).glassEffect(.regular.interactive(), in: Capsule()) }
}
#endif
