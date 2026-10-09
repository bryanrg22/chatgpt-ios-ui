/// Every screen the demo can open directly, by name.
///
/// One list, compiled into three targets: the demo app (`--screen <name>` opens that screen), the screenshot
/// tests (one light and one dark reference image per case) and the UI tests (one accessibility audit per case).
/// Adding a case here adds it to all three.
enum DemoScreen: String, CaseIterable, Sendable {
    case chatHome, chatTyped, chatLongDraft, chatConversation, chatTemporary, chatDictation
    case drawer, drawerExplore, attachmentMenu, camera, photoPicker, mediaViewer
    case markdown, markdownInlineCode, markdownTableCode
    case workHome, workTask
    case voiceChooser, voiceClassic
    case settings, settingsGeneral, settingsAbout, customize, personality, memory, plugins
    case health, healthEmpty, finances, financesEmpty
    case sites, projects, images, scheduled, space, codex
    case dot, dotConnected, dotCallSummary, dotFailedCall
}
