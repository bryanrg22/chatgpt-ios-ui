#if os(iOS)
    import SwiftUI

    /// The captured About card; the host supplies displayed app metadata and handles link intents.
    public struct AboutSettingsView: View {
        @Bindable private var state: SettingsPresentationState
        private let onBack: () -> Void
        public init(state: SettingsPresentationState, onBack: @escaping () -> Void) {
            self.state = state
            self.onBack = onBack
        }
        public var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) { GlassCircle(symbol: "chevron.left") }.accessibilityLabel("Back from About")
                    Spacer()
                    Text("About").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }.padding(.horizontal, 16).padding(.top, 2)
                ScrollView {
                    GroupCard {
                        legalRow(
                            "Terms of use", symbol: "text.book.closed", link: .termsOfUse,
                            identifier: "settings.about.terms")
                        RowDivider()
                        legalRow(
                            "Privacy policy", symbol: "lock", link: .privacyPolicy, identifier: "settings.about.privacy"
                        )
                        RowDivider()
                        HStack(alignment: .top, spacing: 14) {
                            Image("ChatGPTKnot", bundle: .module).resizable().scaledToFit().frame(width: 20, height: 20)
                                .frame(width: 23).padding(.top, 2).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(state.about.appName).font(.system(size: 17)).accessibilityIdentifier(
                                    "settings.about.appName")
                                if !state.about.versionLabel.isEmpty {
                                    Text(state.about.versionLabel).font(.system(size: 13)).foregroundStyle(.secondary)
                                        .accessibilityIdentifier("settings.about.version")
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(.horizontal, 18).padding(.vertical, 16)
                    }.padding(.horizontal, 16).padding(.top, 44)
                }.scrollIndicators(.hidden)
            }.buttonStyle(.plain).background(ChatDesign.settingsCanvas.ignoresSafeArea())
        }
        private func legalRow(_ title: String, symbol: String, link: SettingsLegalLink, identifier: String) -> some View
        {
            Button {
                state.requestLink(link)
            } label: {
                SettingsRow(title: title, icon: symbol, chevron: false)
            }
            .disabled(state.url(for: link) == nil).accessibilityIdentifier(identifier)
        }
    }
#endif
