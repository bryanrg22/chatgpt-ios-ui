import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct SettingsPresentationTests {
    @Test func capturedModelLabelsPreserveHostIdentifiersAndEvents() {
        let chat = ChatState()
        var actions: [ChatAction] = []
        chat.onAction = { actions.append($0) }
        let sol = SettingsPreferenceOptions.models.first { $0.title == "5.6 Sol" }!
        let previous = SettingsPreferenceOptions.models.first { $0.title == "5.5" }!
        chat.selectModel(sol.id)
        #expect(chat.model == "GPT-5.6 Sol")
        chat.selectModel(previous.id)
        #expect(chat.model == "GPT-5.5")
        #expect(actions == [.selectModel("GPT-5.6 Sol"), .selectModel("GPT-5.5")])
        #expect(SettingsPreferenceOptions.modelTitle(for: "GPT-6") == "GPT-6")
        #expect(SettingsPreferenceOptions.modelTitle(for: "Host model") == "Host model")
    }
    @Test func capturedStartChoiceIsLocalAndDoesNotNavigateOrDiscardDraft() {
        let chat = ChatState()
        chat.draft = "Unsent"
        chat.open(.settings)
        chat.openSettings(.general)
        var actions: [ChatAction] = []
        chat.onAction = { actions.append($0) }
        #expect(SettingsPreferenceOptions.startScreens == ["Chat", "Codex"])
        chat.startScreen = "Codex"
        chat.goBack()
        #expect(chat.page == .settings)
        #expect(chat.startScreen == "Codex")
        #expect(chat.draft == "Unsent")
        #expect(actions.isEmpty)
    }
    @Test func defaultMetadataContainsNoAccountOrReferenceVersionFixture() {
        let state = SettingsPresentationState()
        #expect(state.account == .init())
        #expect(state.about == .init())
        #expect(state.about.versionLabel.isEmpty)
    }
    @Test func hostUpdatesRemainIndependentAndLegacyAliasesForward() {
        let chat = ChatState()
        chat.settings.account = .init(
            displayName: "Sam", username: "sam", email: "sam@example.invalid", avatarInitials: "S",
            phoneNumber: "+1 555 0100", subscription: "Team")
        chat.settings.about = .init(appName: "My Interface", version: "2.0", build: "7")
        #expect(chat.email == "sam@example.invalid")
        #expect(chat.username == "sam")
        #expect(chat.displayName == "Sam")
        chat.username = "sam-new"
        chat.email = "other@example.invalid"
        chat.displayName = "Sam Example"
        #expect(chat.settings.account.username == "sam-new")
        #expect(chat.settings.account.email == "other@example.invalid")
        #expect(chat.settings.account.displayName == "Sam Example")
        #expect(chat.settings.account.subscription == "Team")
        #expect(chat.settings.about.versionLabel == "2.0 (7)")
        chat.settings.about = .init()
        #expect(chat.settings.about.appName.isEmpty)
        #expect(chat.settings.about.versionLabel.isEmpty)
        #expect(chat.settings.account.subscription == "Team")
    }
    @Test func versionFormattingHandlesPartialHostMetadataWithoutInventingValues() {
        #expect(SettingsAboutPresentation(version: " 3.1 ", build: " ").versionLabel == "3.1")
        #expect(SettingsAboutPresentation(build: " 24 ").versionLabel == "24")
        #expect(SettingsAboutPresentation(version: "3.1", build: "24").versionLabel == "3.1 (24)")
    }
    @Test func legalLinksEmitOnlySuppliedCurrentURLsAndDoNotMutateMetadata() {
        let state = SettingsPresentationState()
        var actions: [SettingsAction] = []
        state.onAction = { actions.append($0) }
        state.requestLink(.termsOfUse)
        state.requestLink(.privacyPolicy)
        #expect(actions.isEmpty)
        let terms = URL(string: "https://example.invalid/terms")!,
            privacy = URL(string: "https://example.invalid/privacy")!
        state.about = .init(appName: "Example", termsURL: terms, privacyURL: privacy)
        let original = state.about
        state.requestLink(.termsOfUse)
        state.requestLink(.privacyPolicy)
        #expect(actions == [.openLink(.termsOfUse, terms), .openLink(.privacyPolicy, privacy)])
        #expect(state.about == original)
        state.about.termsURL = nil
        state.requestLink(.termsOfUse)
        #expect(actions.count == 2)
        state.about.privacyURL = terms
        state.requestLink(.privacyPolicy)
        #expect(actions.last == .openLink(.privacyPolicy, terms))
    }
    @Test func settingsRoutesEmitTypedIntentAndBackPreservesDraftAndPreferences() {
        let chat = ChatState()
        var actions: [SettingsAction] = []
        chat.settings.onAction = { actions.append($0) }
        chat.draft = "Keep this draft"
        chat.appearance = "Light"
        chat.open(.settings)
        chat.openSettings(.about)
        #expect(chat.page == .about)
        chat.goBack()
        #expect(chat.page == .settings)
        chat.openSettings(.general)
        #expect(chat.page == .general)
        chat.goBack()
        #expect(chat.page == .settings)
        #expect(actions == [.openDestination(.about), .openDestination(.general)])
        #expect(chat.draft == "Keep this draft")
        #expect(chat.appearance == "Light")
    }
}
