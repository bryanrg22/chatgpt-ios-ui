#if os(iOS)
    import SwiftUI
    import UIKit

    struct SettingsScreens: View {
        @Environment(\.colorScheme) private var colorScheme
        @Bindable var state: ChatState
        @Binding var notice: String?
        var body: some View {
            VStack(spacing: 0) {
                header.padding(.horizontal, 16).padding(.top, 2).padding(.bottom, state.page == .settings ? 10 : 28)
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        switch state.page {
                        case .settings: settings
                        case .general: general
                        case .customize: customize
                        case .personality: personality
                        default: unobservedDestination
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 24)
                }.scrollIndicators(.hidden)
            }.buttonStyle(.plain).background(ChatDesign.settingsCanvas.ignoresSafeArea())
        }
        private var header: some View {
            HStack {
                if state.page == .settings {
                    Color.clear.frame(width: 44, height: 44)
                } else {
                    Button {
                        if state.page == .customize { state.showsDrawer = true } else { state.goBack() }
                    } label: {
                        if state.page == .customize { DrawerGlyph() } else { GlassCircle(symbol: "chevron.left") }
                    }.accessibilityLabel(state.page == .customize ? "Open sidebar" : "Back")
                }
                Spacer()
                if state.page != .settings { Text(state.page.rawValue).font(.system(size: 17, weight: .semibold)) }
                Spacer()
                if state.page == .settings {
                    Button {
                        state.open(.chat)
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }.accessibilityLabel("Close settings")
                } else if state.page == .personality {
                    Button {
                        state.goBack()
                    } label: {
                        GlassCircle(symbol: "checkmark")
                    }.accessibilityLabel("Save personality")
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
        }
        private func sectionTitle(_ title: String) -> some View {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(ChatDesign.secondary).padding(
                .leading, 16
            ).padding(.bottom, -17)
        }
        private var settings: some View {
            Group {
                VStack(spacing: 9) {
                    Text(state.settings.account.avatarInitials).font(.system(size: 27)).frame(width: 72, height: 72)
                        .background(Color.teal, in: Circle())
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                notice = "Profile editing is a host integration point."
                            } label: {
                                Image(systemName: "pencil").font(.system(size: 15)).frame(width: 32, height: 32)
                                    .background(ChatDesign.raised, in: Circle())
                            }.accessibilityLabel("Edit profile")
                        }
                    Text(state.username).font(.system(size: 17, weight: .semibold))
                }.frame(maxWidth: .infinity)
                sectionTitle("Customize ChatGPT")
                GroupCard {
                    navRow("Personalization", icon: "face.smiling", page: .personality)
                    RowDivider()
                    navRow("Memory", icon: "book", page: .memory)
                    RowDivider()
                    navRow("Plugins", icon: "puzzlepiece.extension", page: .plugins)
                }
                sectionTitle("Account")
                GroupCard {
                    SettingsRow(title: "Email", icon: "envelope", detail: state.email, chevron: false)
                    RowDivider()
                    SettingsRow(
                        title: "Phone number", icon: "phone", detail: state.settings.account.phoneNumber ?? "Not added",
                        chevron: false)
                    RowDivider()
                    Button {
                        notice = "Subscriptions are supplied by the host app."
                    } label: {
                        SettingsRow(
                            title: "Subscription", icon: "plus.app", detail: state.settings.account.subscription,
                            chevron: false)
                    }
                    RowDivider()
                    Button {
                        notice = "This demo has no purchases to restore."
                    } label: {
                        SettingsRow(title: "Restore purchases", icon: "arrow.clockwise", chevron: false)
                    }
                    RowDivider()
                    Button {
                        notice = "Usage and limits are supplied by your backend."
                    } label: {
                        SettingsRow(title: "Usage and limits", icon: "chart.xyaxis.line")
                    }
                }
                sectionTitle("Theme")
                GroupCard {
                    Menu {
                        Picker("Appearance", selection: $state.appearance) {
                            ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) }
                        }
                    } label: {
                        SettingsRow(
                            title: "Appearance", icon: colorScheme == .dark ? "moon" : "sun.max",
                            detail: state.appearance, chevron: false, pickerIndicator: true)
                    }.accessibilityIdentifier("settings.appearance")
                    RowDivider()
                    Menu {
                        Picker("Accent color", selection: $state.accentName) {
                            ForEach(SettingsPreferenceOptions.accents) { option in
                                Label {
                                    Text(option.id)
                                } icon: {
                                    Image(uiImage: option.swatchImage).renderingMode(.original)
                                }.tag(option.id)
                            }
                        }
                    } label: {
                        SettingsRow(
                            title: "Accent color", icon: "paintpalette", detail: state.accentName, chevron: false,
                            pickerIndicator: true,
                            detailDot: SettingsPreferenceOptions.accents.first { $0.id == state.accentName }.map {
                                Color(uiColor: $0.swatchUIColor)
                            })
                    }.menuOrder(.fixed).accessibilityIdentifier("settings.accent")
                }
                sectionTitle("App settings")
                GroupCard {
                    navRow("General", icon: "gearshape", page: .general)
                    RowDivider()
                    Button {
                        notice = "Notifications are configured by the host app."
                    } label: {
                        SettingsRow(title: "Notifications", icon: "bell")
                    }.accessibilityIdentifier("settings.notifications")
                    RowDivider()
                    Button {
                        notice = "Voice settings are not yet visually referenced."
                    } label: {
                        SettingsRow(title: "Voice", icon: "waveform")
                    }.accessibilityIdentifier("settings.voice")
                    RowDivider()
                    ForEach(
                        Array(
                            zip(
                                [
                                    "Parental controls", "Trusted contact", "Safety", "Security and login", "Codex",
                                    "Cloud browser", "Storage"
                                ],
                                [
                                    "person.2", "person.crop.circle.badge.checkmark", "shield", "lock", "cloud",
                                    "globe", "internaldrive"
                                ])), id: \.0
                    ) { title, icon in
                        Button {
                            state.onAction(.openDestination(title))
                            notice = "\(title) is supplied by your host app. Its detail screen is not yet referenced."
                        } label: {
                            SettingsRow(title: title, icon: icon)
                        }
                        RowDivider()
                    }
                    Button {
                        notice = "No data leaves this offline demo."
                    } label: {
                        SettingsRow(title: "Data controls", icon: "externaldrive")
                    }
                }
                sectionTitle("Get help")
                GroupCard {
                    ForEach(["Report app issue", "Help Center", "Privacy Center"], id: \.self) { title in
                        Button {
                            state.onAction(.openDestination(title))
                            notice = "\(title) is supplied by your host app."
                        } label: {
                            SettingsRow(title: title, icon: "questionmark.circle")
                        }
                        RowDivider()
                    }
                    Button {
                        state.openSettings(.about)
                    } label: {
                        SettingsRow(title: "About", icon: "info.circle")
                    }.accessibilityIdentifier("settings.about")
                }
                GroupCard {
                    Button {
                        notice = "This demo has no signed-in account."
                    } label: {
                        SettingsRow(title: "Log out", icon: "rectangle.portrait.and.arrow.right", chevron: false)
                    }
                }
            }
        }
        private var general: some View {
            Group {
                GroupCard {
                    Menu {
                        Picker("Start screen", selection: $state.startScreen) {
                            ForEach(SettingsPreferenceOptions.startScreens, id: \.self) { Text($0).tag($0) }
                        }
                    } label: {
                        SettingsRow(
                            title: "Start screen", icon: "house", detail: state.startScreen, chevron: false,
                            pickerIndicator: true)
                    }.accessibilityIdentifier("settings.startScreen")
                }
                Text("Choose where you start when you open ChatGPT.").font(.system(size: 13)).foregroundStyle(
                    ChatDesign.secondary
                ).padding(.horizontal, 16).padding(.top, -20)
                GroupCard {
                    Button {
                        notice = "Language selection is a host integration point."
                    } label: {
                        SettingsRow(title: "App language", icon: "globe", detail: "English")
                    }
                    RowDivider()
                    toggleRow("Auto-correct spelling", icon: "textformat.abc", value: $state.autoCorrect)
                    RowDivider()
                    toggleRow("Haptic feedback", icon: "iphone.radiowaves.left.and.right", value: $state.haptics)
                }
                sectionTitle("Intelligence")
                GroupCard {
                    SettingsRow(
                        title: "Model", icon: "atom", detail: SettingsPreferenceOptions.modelTitle(for: state.model),
                        chevron: false, pickerIndicator: true
                    )
                    .accessibilityHidden(true)
                    .overlay { NativeModelPicker(selectedID: state.model, onSelect: { state.selectModel($0) }) }
                }
                sectionTitle("Suggestions")
                GroupCard {
                    toggleRow("Autocomplete", icon: "square.and.pencil", value: $state.autocomplete)
                    RowDivider()
                    toggleRow("Trending searches", icon: "arrow.up.right", value: $state.trending)
                }
                sectionTitle("Automatically use")
                GroupCard {
                    Toggle(isOn: $state.webSearch) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Web search")
                                Text("Search the web for real-time info.").font(.system(size: 15)).foregroundStyle(
                                    .secondary)
                            }
                        } icon: {
                            Image(systemName: "globe")
                        }
                    }.tint(.green).padding(18)
                }
            }
        }
        private var customize: some View {
            Group {
                GroupCard(outlined: true) {
                    navRow("Personality", icon: "face.smiling", page: .personality, color: .yellow)
                    RowDivider()
                    navRow("Memory", icon: "book", detail: "9h ago", page: .memory, color: .orange)
                    RowDivider()
                    navRow("Plugins", icon: "puzzlepiece.extension", detail: "0 added", page: .plugins, color: .purple)
                }
                GroupCard(outlined: true) {
                    demoRow("Email", icon: "envelope.fill", detail: "Connected", color: .gray)
                    RowDivider()
                    demoRow("Calendar", icon: "calendar", detail: "Connected", color: .blue)
                    RowDivider()
                    demoRow("Wallet", icon: "wallet.pass.fill", detail: "Coming soon", color: .orange)
                    RowDivider()
                    demoRow("Passwords", icon: "lock.fill", detail: "0 items", color: .purple)
                    RowDivider()
                    navRow("Health", icon: "heart.fill", detail: "Connected", page: .health, color: .red)
                    RowDivider()
                    navRow(
                        "Finances", icon: "dollarsign.circle.fill", detail: "Connected", page: .finances, color: .green)
                }.padding(.top, 16)
                GroupCard(outlined: true) {
                    demoRow("Location", icon: "map.fill", detail: "Precise", color: .green)
                    RowDivider()
                    demoRow("Custom rules", icon: "shield.fill", detail: "0 added", color: .blue)
                }.padding(.top, 16)
            }
        }
        private var personality: some View {
            Group {
                GroupCard(outlined: true) {
                    Menu {
                        Picker("Style and tone", selection: $state.style) {
                            ForEach(
                                ["Default", "Professional", "Friendly", "Candid", "Quirky", "Efficient"], id: \.self
                            ) { Text($0) }
                        }
                    } label: {
                        SettingsRow(
                            title: "Style and tone", detail: state.style == "Default" ? nil : state.style,
                            chevron: false)
                    }
                    Divider().padding(.horizontal, 8)
                    slider("Warmth", value: $state.warmth)
                    Divider().padding(.horizontal, 8)
                    slider("Enthusiasm", value: $state.enthusiasm)
                    Divider().padding(.horizontal, 8)
                    slider("Headers and Lists", value: $state.headers)
                    Divider().padding(.horizontal, 8)
                    slider("Emoji", value: $state.emoji)
                }
                sectionTitle("Custom instructions")
                TextField(
                    "Share anything you’d like ChatGPT to always keep in mind", text: $state.instructions,
                    axis: .vertical
                )
                .lineLimit(3...7).font(.system(size: 17)).padding(24).background(
                    ChatDesign.surface, in: RoundedRectangle(cornerRadius: 26)
                )
                .overlay { RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.13)) }
            }
        }
        private var unobservedDestination: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(state.page.rawValue).font(.largeTitle.bold())
                Text("This destination is awaiting a visual reference.").font(.title3)
                Text("The navigation action is available to your host app. No backend is connected.").foregroundStyle(
                    .secondary)
                Button("Return to chat") { state.open(.chat) }.buttonStyle(.bordered)
            }.padding(.top, 30)
        }
        private func navRow(
            _ title: String, icon: String, detail: String? = nil, page: ChatPage, color: Color = .primary
        ) -> some View {
            Button {
                switch page {
                case .general: state.openSettings(.general)
                case .personality: state.openSettings(.personalization)
                case .memory: state.openSettings(.memory)
                case .plugins: state.openSettings(.plugins)
                default: state.open(page)
                }
            } label: {
                SettingsRow(title: title, icon: icon, detail: detail, color: color)
            }.accessibilityIdentifier("settings.row.\(page.rawValue)")
        }
        private func demoRow(_ title: String, icon: String, detail: String, color: Color) -> some View {
            Button {
                state.onAction(.openDestination(title))
                notice = "\(title) detail is an integration point; this demo uses sample state."
            } label: {
                SettingsRow(title: title, icon: icon, detail: detail, color: color)
            }
        }
        private func toggleRow(_ title: String, icon: String, value: Binding<Bool>) -> some View {
            Toggle(isOn: value) { Label(title, systemImage: icon).font(.system(size: 17)) }.tint(.green).padding(
                .horizontal, 18
            ).frame(minHeight: 52)
        }
        private func slider(_ title: String, value: Binding<Double>) -> some View {
            HStack {
                Text(title).font(.system(size: 17))
                Spacer()
                Slider(value: value, in: 0...1, step: 0.5).frame(width: 136).accessibilityLabel(title)
            }.padding(.horizontal, 24).frame(height: 60)
        }
    }

    private extension SettingsAccentOption {
        var swatchUIColor: UIColor {
            UIColor(
                red: CGFloat((swatchRGB >> 16) & 255) / 255, green: CGFloat((swatchRGB >> 8) & 255) / 255,
                blue: CGFloat(swatchRGB & 255) / 255, alpha: 1)
        }
        var swatchImage: UIImage {
            UIGraphicsImageRenderer(size: CGSize(width: 18, height: 18)).image { context in
                context.cgContext.setFillColor(swatchUIColor.cgColor)
                context.cgContext.fillEllipse(in: CGRect(x: 3, y: 3, width: 12, height: 12))
            }.withRenderingMode(.alwaysOriginal)
        }
    }

#endif
