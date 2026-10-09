#if os(iOS)
    import SwiftUI

    struct FinanceConnectSheet: View {
        @Bindable var state: FinanceWorkspaceState
        let onClose: () -> Void
        @State private var notice: String?
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    Color.clear.frame(width: 36, height: 36)
                    Spacer()
                    Text("Connect finances").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button(action: onClose) {
                        GlassCircle(
                            symbol: state.connectionTab == "Credit score" ? "checkmark.circle" : "xmark", size: 36)
                    }.accessibilityLabel("Close connect finances")
                }.padding(.horizontal, 24).padding(.top, 24)
                FeatureTabs(titles: ["Accounts", "Credit score", "Manual accounts"], selection: $state.connectionTab)
                ScrollView {
                    switch state.connectionTab {
                    case "Credit score": credit
                    case "Manual accounts": manual
                    default: plaid
                    }
                }.scrollIndicators(.hidden)
            }.background(ChatDesign.surface.ignoresSafeArea()).buttonStyle(.plain)
                .alert(
                    "UI reference needed",
                    isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })
                ) {
                    Button("OK") { notice = nil }
                } message: {
                    Text(notice ?? "")
                }
        }
        private var plaid: some View {
            VStack(spacing: 28) {
                Image(systemName: "square.on.square.intersection").font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.black).frame(width: 48, height: 48).background(
                        .white, in: RoundedRectangle(cornerRadius: 12)
                    ).accessibilityLabel("Plaid logo approximation")
                Text("Connect your financial accounts\nwith Plaid").font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                VStack(spacing: 18) {
                    benefit("💰", "See your full financial picture", "Understand your spending, savings, and more")
                    Divider()
                    benefit(
                        "💬", "Get answers about your money",
                        "Ask ChatGPT questions and get insights personalized to your finances")
                    Divider()
                    benefit(
                        "🛡️", "Connect securely",
                        "Link your accounts without sharing your bank login details with ChatGPT")
                }.padding(18).overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.18)) }
                Button {
                    state.onAction(.connectProvider("Plaid"))
                    notice =
                        "Plaid authentication is supplied by the host. Its account-linking screens are not part of this captured interface."
                } label: {
                    Text("Continue to Plaid").font(.system(size: 15, weight: .semibold)).foregroundStyle(.black)
                        .padding(.horizontal, 18).frame(height: 40).background(.white, in: Capsule())
                }
            }.padding(.horizontal, 44).padding(.top, 38)
        }
        private func benefit(_ emoji: String, _ title: String, _ subtitle: String) -> some View {
            HStack(spacing: 16) {
                Text(emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 15, weight: .medium))
                    Text(subtitle).font(.system(size: 14)).foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        private var credit: some View {
            Group {
                if state.data.creditScore != nil {
                    VStack(spacing: 28) {
                        HStack(spacing: 12) {
                            Text("E").font(.system(size: 23, weight: .bold)).foregroundStyle(.purple).frame(
                                width: 34, height: 34
                            ).background(.white, in: Circle())
                            VStack(alignment: .leading, spacing: 6) {
                                Text(state.data.creditProvider).font(.system(size: 17))
                                Text(
                                    state.data.creditScore.map { state.displayValue(.text($0)) + " credit score" } ?? ""
                                ).font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark").foregroundStyle(.blue).frame(width: 34, height: 34)
                                .background(.blue.opacity(0.25), in: Circle())
                        }
                        Button {
                            state.pendingChat = "Explore my credit score"
                            onClose()
                        } label: {
                            Text("Explore my credit score").font(.system(size: 15, weight: .semibold)).foregroundStyle(
                                .black
                            ).frame(maxWidth: .infinity).frame(height: 40).background(.white, in: Capsule())
                        }
                    }.padding(24)
                }
            }
        }
        private var manual: some View {
            VStack(spacing: 16) {
                ForEach(
                    Array(
                        zip(
                            [
                                "Cash", "Investments", "Real estate", "Vehicle", "Other assets", "Loans", "Other debt",
                                "Tax records", "Insurance"
                            ],
                            [
                                "banknote", "chart.bar", "house", "car", "number", "note.text", "minus", "calculator",
                                "shield"
                            ])), id: \.0
                ) { title, symbol in
                    Button {
                        if title == "Cash" {
                            state.pendingChat = "cash"
                            onClose()
                        } else {
                            state.onAction(.openDestination("Manual " + title))
                            notice = "The \(title) entry flow has not yet been captured."
                        }
                    } label: {
                        HStack(spacing: 14) {
                            FeatureGlyph(symbol: symbol, size: 44)
                            Text(title).font(.system(size: 17))
                            Spacer()
                            if title != "Tax records" { Image(systemName: "chevron.right").foregroundStyle(.secondary) }
                        }.contentShape(Rectangle())
                    }.accessibilityIdentifier("finance.manual." + title).disabled(title == "Tax records").opacity(
                        title == "Tax records" ? 0.4 : 1)
                }
            }.padding(.horizontal, 24).padding(.top, 8)
        }
    }
    struct FinanceCustomizeSheet: View {
        @Bindable var state: FinanceWorkspaceState
        @Environment(\.dismiss) private var dismiss
        @State private var order: [String] = []
        @State private var shown: Set<String> = []
        private var changed: Bool { order != state.dashboardOrder || shown != state.shownDashboardCards }
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }.accessibilityLabel("Cancel dashboard customization")
                    Spacer()
                    Text("Customize dashboard").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button {
                        state.applyDashboard(order: order, shown: shown)
                        dismiss()
                    } label: {
                        GlassCircle(symbol: "checkmark")
                    }.disabled(!changed).accessibilityLabel("Save dashboard customization")
                }.padding(16)
                List {
                    Section("Shown") {
                        ForEach(order, id: \.self) { title in
                            Button {
                                if shown.contains(title) { shown.remove(title) } else { shown.insert(title) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: shown.contains(title) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(shown.contains(title) ? .blue : .secondary).font(
                                            .system(size: 22))
                                    Text(title).font(.system(size: 17)).foregroundStyle(.primary).lineLimit(1)
                                }.frame(minHeight: 34)
                            }.listRowBackground(ChatDesign.raised)
                        }.onMove { indices, offset in order.move(fromOffsets: indices, toOffset: offset) }
                    }
                    Button("Reset to defaults") {
                        order = FinanceWorkspaceState.dashboardOptions
                        shown = Set(order)
                    }.disabled(order == FinanceWorkspaceState.dashboardOptions && shown == Set(order))
                }.environment(\.editMode, .constant(.active)).scrollContentBackground(.hidden).listStyle(.insetGrouped)
            }.background(ChatDesign.raised.ignoresSafeArea()).onAppear {
                order = state.dashboardOrder
                shown = state.shownDashboardCards
            }
        }
    }
    struct FinanceChatView: View {
        @Bindable var state: FinanceWorkspaceState
        @State private var notice: String?
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        state.chatPresented = false
                    } label: {
                        GlassCircle(symbol: "chevron.left")
                    }.accessibilityLabel("Back to finances")
                    Spacer()
                    Button {
                        state.onAction(.openDestination("Finance chat menu"))
                    } label: {
                        GlassCircle(symbol: "ellipsis")
                    }.accessibilityLabel("Finance chat menu")
                }.padding(.horizontal, 16)
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(state.chatMessages) { message in
                            if message.role == .user {
                                HStack {
                                    Spacer(minLength: 82)
                                    Text(message.text).font(.system(size: 17)).padding(16).background(
                                        Color(red: 0.016, green: 0.02, blue: 0.37),
                                        in: RoundedRectangle(cornerRadius: 24))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 18) {
                                    Text(message.text).font(.system(size: 17)).lineSpacing(6)
                                    HStack(spacing: 18) {
                                        ForEach(
                                            [
                                                "document.on.document", "hand.thumbsup", "hand.thumbsdown",
                                                "square.and.arrow.up", "ellipsis"
                                            ], id: \.self
                                        ) { symbol in
                                            Button {
                                                if symbol == "document.on.document" {
                                                    UIPasteboard.general.string = message.text
                                                } else {
                                                    state.onAction(.openDestination("Finance response " + symbol))
                                                    notice = "This response action is available to the host."
                                                }
                                            } label: {
                                                Image(systemName: symbol).font(.system(size: 17)).foregroundStyle(
                                                    .secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(16).padding(.top, 8)
                }.scrollIndicators(.hidden)
                FeatureComposer(
                    placeholder: "Ask ChatGPT", draft: $state.chatDraft, onSend: { _ = state.sendChat() },
                    onOpen: { state.onAction(.openDestination($0)) }
                ).padding(.horizontal, 34)
                Text(
                    "ChatGPT can make mistakes and isn’t a licensed investment adviser or authorized to prepare tax returns."
                ).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(
                    .horizontal, 32
                ).padding(.top, 8)
            }.background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
                .alert("UI demo", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                    Button("OK") { notice = nil }
                } message: {
                    Text(notice ?? "")
                }
        }
    }
#endif
