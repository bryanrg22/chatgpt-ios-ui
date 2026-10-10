import ChatGPTUI
import SwiftUI

// Live Xcode previews for every catalogued screen, in both appearances, driven by the same `DemoScreen` list the
// screenshot tests and `--screen` launch argument use. Open this file in Xcode and use the canvas to iterate on a
// screen without launching the demo. Each preview shows the fixture data the demo and tests show.

/// A screen with the demo fixtures installed, the same way the demo app and the screenshot tests build it.
@MainActor private func demoScreen(_ screen: DemoScreen, appearance: String) -> some View {
    let state = ChatState()
    installDemoFixtures(state)
    applyDemoScreen(screen, to: state, baseArguments: ["--ui-test"])
    state.appearance = appearance
    return demoChatView(state: state)
}

#Preview("Chat home · light") { demoScreen(.chatHome, appearance: "Light") }
#Preview("Chat home · dark") { demoScreen(.chatHome, appearance: "Dark") }
#Preview("Chat typed · light") { demoScreen(.chatTyped, appearance: "Light") }
#Preview("Chat typed · dark") { demoScreen(.chatTyped, appearance: "Dark") }
#Preview("Chat long draft · light") { demoScreen(.chatLongDraft, appearance: "Light") }
#Preview("Chat long draft · dark") { demoScreen(.chatLongDraft, appearance: "Dark") }
#Preview("Chat conversation · light") { demoScreen(.chatConversation, appearance: "Light") }
#Preview("Chat conversation · dark") { demoScreen(.chatConversation, appearance: "Dark") }
#Preview("Chat temporary · light") { demoScreen(.chatTemporary, appearance: "Light") }
#Preview("Chat temporary · dark") { demoScreen(.chatTemporary, appearance: "Dark") }
#Preview("Chat dictation · light") { demoScreen(.chatDictation, appearance: "Light") }
#Preview("Chat dictation · dark") { demoScreen(.chatDictation, appearance: "Dark") }
#Preview("Drawer · light") { demoScreen(.drawer, appearance: "Light") }
#Preview("Drawer · dark") { demoScreen(.drawer, appearance: "Dark") }
#Preview("Drawer explore · light") { demoScreen(.drawerExplore, appearance: "Light") }
#Preview("Drawer explore · dark") { demoScreen(.drawerExplore, appearance: "Dark") }
#Preview("Attachment menu · light") { demoScreen(.attachmentMenu, appearance: "Light") }
#Preview("Attachment menu · dark") { demoScreen(.attachmentMenu, appearance: "Dark") }
#Preview("Camera · light") { demoScreen(.camera, appearance: "Light") }
#Preview("Camera · dark") { demoScreen(.camera, appearance: "Dark") }
#Preview("Photo picker · light") { demoScreen(.photoPicker, appearance: "Light") }
#Preview("Photo picker · dark") { demoScreen(.photoPicker, appearance: "Dark") }
#Preview("Media viewer · light") { demoScreen(.mediaViewer, appearance: "Light") }
#Preview("Media viewer · dark") { demoScreen(.mediaViewer, appearance: "Dark") }
#Preview("Markdown · light") { demoScreen(.markdown, appearance: "Light") }
#Preview("Markdown · dark") { demoScreen(.markdown, appearance: "Dark") }
#Preview("Markdown inline code · light") { demoScreen(.markdownInlineCode, appearance: "Light") }
#Preview("Markdown inline code · dark") { demoScreen(.markdownInlineCode, appearance: "Dark") }
#Preview("Markdown table code · light") { demoScreen(.markdownTableCode, appearance: "Light") }
#Preview("Markdown table code · dark") { demoScreen(.markdownTableCode, appearance: "Dark") }
#Preview("Work home · light") { demoScreen(.workHome, appearance: "Light") }
#Preview("Work home · dark") { demoScreen(.workHome, appearance: "Dark") }
#Preview("Work task · light") { demoScreen(.workTask, appearance: "Light") }
#Preview("Work task · dark") { demoScreen(.workTask, appearance: "Dark") }
#Preview("Voice chooser · light") { demoScreen(.voiceChooser, appearance: "Light") }
#Preview("Voice chooser · dark") { demoScreen(.voiceChooser, appearance: "Dark") }
#Preview("Voice classic · light") { demoScreen(.voiceClassic, appearance: "Light") }
#Preview("Voice classic · dark") { demoScreen(.voiceClassic, appearance: "Dark") }
#Preview("Settings · light") { demoScreen(.settings, appearance: "Light") }
#Preview("Settings · dark") { demoScreen(.settings, appearance: "Dark") }
#Preview("Settings general · light") { demoScreen(.settingsGeneral, appearance: "Light") }
#Preview("Settings general · dark") { demoScreen(.settingsGeneral, appearance: "Dark") }
#Preview("Settings about · light") { demoScreen(.settingsAbout, appearance: "Light") }
#Preview("Settings about · dark") { demoScreen(.settingsAbout, appearance: "Dark") }
#Preview("Customize · light") { demoScreen(.customize, appearance: "Light") }
#Preview("Customize · dark") { demoScreen(.customize, appearance: "Dark") }
#Preview("Personality · light") { demoScreen(.personality, appearance: "Light") }
#Preview("Personality · dark") { demoScreen(.personality, appearance: "Dark") }
#Preview("Memory · light") { demoScreen(.memory, appearance: "Light") }
#Preview("Memory · dark") { demoScreen(.memory, appearance: "Dark") }
#Preview("Plugins · light") { demoScreen(.plugins, appearance: "Light") }
#Preview("Plugins · dark") { demoScreen(.plugins, appearance: "Dark") }
#Preview("Health · light") { demoScreen(.health, appearance: "Light") }
#Preview("Health · dark") { demoScreen(.health, appearance: "Dark") }
#Preview("Health empty · light") { demoScreen(.healthEmpty, appearance: "Light") }
#Preview("Health empty · dark") { demoScreen(.healthEmpty, appearance: "Dark") }
#Preview("Finances · light") { demoScreen(.finances, appearance: "Light") }
#Preview("Finances · dark") { demoScreen(.finances, appearance: "Dark") }
#Preview("Finances empty · light") { demoScreen(.financesEmpty, appearance: "Light") }
#Preview("Finances empty · dark") { demoScreen(.financesEmpty, appearance: "Dark") }
#Preview("Sites · light") { demoScreen(.sites, appearance: "Light") }
#Preview("Sites · dark") { demoScreen(.sites, appearance: "Dark") }
#Preview("Projects · light") { demoScreen(.projects, appearance: "Light") }
#Preview("Projects · dark") { demoScreen(.projects, appearance: "Dark") }
#Preview("Images · light") { demoScreen(.images, appearance: "Light") }
#Preview("Images · dark") { demoScreen(.images, appearance: "Dark") }
#Preview("Scheduled · light") { demoScreen(.scheduled, appearance: "Light") }
#Preview("Scheduled · dark") { demoScreen(.scheduled, appearance: "Dark") }
#Preview("Space · light") { demoScreen(.space, appearance: "Light") }
#Preview("Space · dark") { demoScreen(.space, appearance: "Dark") }
#Preview("Codex · light") { demoScreen(.codex, appearance: "Light") }
#Preview("Codex · dark") { demoScreen(.codex, appearance: "Dark") }
#Preview("Dot · light") { demoScreen(.dot, appearance: "Light") }
#Preview("Dot · dark") { demoScreen(.dot, appearance: "Dark") }
#Preview("Dot connected · light") { demoScreen(.dotConnected, appearance: "Light") }
#Preview("Dot connected · dark") { demoScreen(.dotConnected, appearance: "Dark") }
#Preview("Dot call summary · light") { demoScreen(.dotCallSummary, appearance: "Light") }
#Preview("Dot call summary · dark") { demoScreen(.dotCallSummary, appearance: "Dark") }
#Preview("Dot failed call · light") { demoScreen(.dotFailedCall, appearance: "Light") }
#Preview("Dot failed call · dark") { demoScreen(.dotFailedCall, appearance: "Dark") }
