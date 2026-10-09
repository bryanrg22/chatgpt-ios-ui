import Testing
@testable import ChatGPTUI

@MainActor @Suite struct VoicePresentationStateTests {
    @Test func chooserCancellationDoesNotStartAudioIntegration() {
        var events: [ChatAction] = []
        let state = ChatState { events.append($0) }
        state.setVoice(true)
        #expect(state.voice.isChoosing)
        #expect(!state.voice.isActive)
        state.setVoice(false)
        #expect(events.isEmpty)
        #expect(!state.voice.hasChosenVoice)
    }
    @Test func startingAndEndingAreIdempotentAndReopeningKeepsVoice() {
        var events: [ChatAction] = []
        let state = ChatState { events.append($0) }
        state.startVoice()
        #expect(events.isEmpty)
        state.setVoice(true)
        state.startVoice()
        state.startVoice()
        #expect(events == [.beginVoice])
        #expect(state.voice.isActive)
        #expect(!state.voice.isChoosing)
        state.setVoice(false)
        state.setVoice(false)
        #expect(events == [.beginVoice, .endVoice])
        state.setVoice(true)
        #expect(state.voice.isActive)
        #expect(!state.voice.isChoosing)
        #expect(events == [.beginVoice, .endVoice, .beginVoice])
    }
    @Test func endingPreservesDraftPreferencesButClearsSettingsPanel() {
        let state = ChatState()
        state.setVoice(true)
        state.startVoice()
        state.voice.draft = "Unsent voice text"
        state.voice.language = "Arabic"
        state.voice.isMuted = false
        state.voice.showsSettings = true
        state.setVoice(false)
        state.setVoice(true)
        #expect(state.voice.draft == "Unsent voice text")
        #expect(state.voice.language == "Arabic")
        #expect(!state.voice.isMuted)
        #expect(!state.voice.showsSettings)
    }
    @Test func hostSuppliedProfilesSelectOnlyValidIDsAndClampNavigation() {
        let state = VoicePresentationState()
        state.profiles.append(.init(id: "sample", name: "Sample voice", detail: "Host-supplied fixture"))
        state.select("missing")
        #expect(state.selectedID == "breeze")
        state.next(1)
        #expect(state.selectedID == "sample")
        state.next(1)
        #expect(state.selectedID == "sample")
        state.next(-1)
        state.next(-1)
        #expect(state.selectedID == "breeze")
    }
    @Test func newChatClosesAnActiveVoiceSession() {
        var events: [ChatAction] = []
        let state = ChatState { events.append($0) }
        state.setVoice(true)
        state.startVoice()
        state.voice.draft = "Previous conversation draft"
        state.newChat()
        #expect(!state.showsVoice)
        #expect(!state.voice.isActive)
        #expect(state.voice.draft.isEmpty)
        #expect(events.suffix(2) == [.endVoice, .newChat])
    }
    @Test func navigationIntentsPreserveAnActiveVoiceSession() {
        var events: [ChatAction] = []
        let state = ChatState { events.append($0) }
        state.requestVoiceNavigation(.sidebar)
        #expect(events.isEmpty)
        state.setVoice(true)
        state.startVoice()
        state.requestVoiceNavigation(.sidebar)
        state.requestVoiceNavigation(.attachments)
        #expect(state.showsVoice)
        #expect(state.voice.isActive)
        #expect(events.suffix(2) == [.voiceNavigation(.sidebar), .voiceNavigation(.attachments)])
    }
    @Test func sharingRequestRequiresActiveSessionAndExplicitHostOutcome() {
        let voice = VoicePresentationState()
        var actions: [VoiceUIAction] = []
        voice.onAction = { actions.append($0) }
        voice.requestScreenSharing()
        #expect(!voice.showsModelSwitch)
        #expect(actions.isEmpty)
        voice.start()
        voice.requestScreenSharing()
        #expect(voice.showsModelSwitch)
        voice.continueScreenSharing()
        #expect(!voice.showsModelSwitch)
        #expect(actions == [.requestScreenSharing])
        #expect(!voice.isSharingScreen)
        #expect(voice.variant == .current)
        voice.continueScreenSharing()
        #expect(actions.count == 1)
        voice.variant = .classic
        voice.isSharingScreen = true
        voice.requestScreenSharing()
        #expect(!voice.isSharingScreen)
        #expect(actions.last == .stopScreenSharing)
    }
    @Test func closeClearsMediaPresentationButPreservesTranscript() {
        let voice = VoicePresentationState()
        voice.start()
        voice.transcript = [.init(role: .user, text: "A fictional prompt")]
        voice.showsLiveCamera = true
        voice.isSharingScreen = true
        voice.showsModelSwitch = true
        voice.showsEffort = true
        voice.close()
        #expect(!voice.showsLiveCamera)
        #expect(!voice.isSharingScreen)
        #expect(!voice.showsModelSwitch)
        #expect(!voice.showsEffort)
        #expect(voice.transcript.count == 1)
        voice.clearConversation()
        #expect(voice.transcript.isEmpty)
    }
    @Test func orbGeometryHandlesInvalidHostInputsAndUsesTranscriptEndpoint() {
        let voice = VoicePresentationState()
        #expect(voice.presentedOrbDiameter == 193)
        voice.variant = .classic
        #expect(voice.presentedOrbDiameter == 178)
        voice.transcript = [.init(role: .assistant, text: "Fixture")]
        #expect(voice.presentedOrbDiameter == 80)
        for invalid in [Double.nan, Double.infinity, -3, 0] {
            voice.orbDiameter = invalid
            #expect(voice.presentedOrbDiameter == 80)
        }
        voice.orbDiameter = 215
        #expect(voice.presentedOrbDiameter == 215)
        voice.orbDiameter = 1e9
        #expect(voice.presentedOrbDiameter == 400)
    }
    @Test func liveVideoAndEffortAreBoundedHostIntents() {
        let voice = VoicePresentationState()
        var actions: [VoiceUIAction] = []
        voice.onAction = { actions.append($0) }
        voice.requestLiveVideo()
        #expect(actions.isEmpty)
        voice.start()
        voice.requestLiveVideo()
        #expect(actions == [.requestLiveVideo])
        #expect(!voice.showsLiveCamera)
        voice.showsLiveCamera = true
        voice.closeLiveVideo()
        voice.closeLiveVideo()
        #expect(actions.last == .endLiveVideo)
        voice.setEffort(-100)
        #expect(voice.effortPosition == 0)
        voice.setEffort(100)
        #expect(voice.effortPosition == 4)
    }
    @Test func recordedCollapseRetainsMeasuredUndershootAndSettles() {
        let from = VoiceOrbCollapse.Sample(diameter: 198, centerY: 875.0 / 3)
        let to = VoiceOrbCollapse.Sample(diameter: 236.0 / 3, centerY: 1210.0 / 3)
        #expect(VoiceOrbCollapse.sample(elapsed: 0, from: from, to: to) == from)
        let undershoot = VoiceOrbCollapse.sample(elapsed: 1.0 / 6, from: from, to: to)
        #expect(abs(undershoot.diameter - 54) < 0.001)
        #expect(undershoot.centerY > to.centerY)
        #expect(VoiceOrbCollapse.sample(elapsed: 0.5, from: from, to: to) == to)
        #expect(VoiceOrbCollapse.sample(elapsed: .infinity, from: from, to: to) == to)
    }
    @Test func earlyTimelineFrameKeepsStartEndpointAndHostGeometryHasOneOwner() {
        let from = VoiceOrbCollapse.Sample(diameter: 193, centerY: 400)
        let to = VoiceOrbCollapse.Sample(diameter: 80, centerY: 710)
        #expect(VoiceOrbCollapse.sample(elapsed: -0.001, from: from, to: to) == from)
        #expect(VoiceOrbCollapse.sample(elapsed: -100, from: from, to: to) == from)
        #expect(VoiceOrbCollapse.sample(elapsed: .nan, from: from, to: to) == to)
        let voice = VoicePresentationState()
        for invalid in [Double.nan, .infinity, 0, -1] {
            voice.orbDiameter = invalid
            #expect(!voice.hasHostOrbDiameter)
        }
        voice.orbDiameter = 215
        #expect(voice.hasHostOrbDiameter)
        voice.transcript = [.init(role: .assistant, text: "A garden plan")]
        #expect(voice.presentedOrbDiameter == 215)
        voice.orbDiameter = nil
        #expect(!voice.hasHostOrbDiameter)
        #expect(voice.presentedOrbDiameter == 80)
    }
    @Test func proceduralCloudIsBoundedDeterministicAndContinuousInPhase() {
        for x in stride(from: 0.0, through: 1.0, by: 0.1) {
            for y in stride(from: 0.0, through: 1.0, by: 0.1) {
                let a = VoiceCloudField.alpha(x: x, y: y, phase: 0)
                #expect(a.isFinite && a >= 0 && a <= 1)
                #expect(a == VoiceCloudField.alpha(x: x, y: y, phase: .nan))
                #expect(abs(a - VoiceCloudField.alpha(x: x, y: y, phase: 0.001)) < 0.01)
            }
        }
        #expect(VoiceCloudField.alpha(x: .infinity, y: 0, phase: 0) == 0)
        #expect(VoiceCloudField.alpha(x: 0.5, y: 0.85, phase: 0) > VoiceCloudField.alpha(x: 0.5, y: 0.1, phase: 0))
    }
}
