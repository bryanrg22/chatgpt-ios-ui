import Testing
@testable import ChatGPTUI

@Suite struct MemorySummaryStateTests {
    @Test func refreshChangesDisplayTimestampAndPreservesSummary() {
        var memory = MemorySummaryPresentationState()
        let original = memory.sections
        memory.refresh()
        #expect(memory.updatedLabel == "Updated just now")
        #expect(memory.sections == original)
        #expect(memory.isEnabled)
    }
    @Test func deleteThenRefreshCannotRestoreDeletedMemory() {
        var memory = MemorySummaryPresentationState()
        memory.deleteAndTurnOff(); memory.refresh()
        #expect(memory.sections.isEmpty)
        #expect(!memory.isEnabled)
        #expect(memory.updatedLabel == "Memory is off")
    }
    @Test func independentMemoryStatesDoNotShareMutation() {
        var first = MemorySummaryPresentationState()
        let second = MemorySummaryPresentationState()
        first.deleteAndTurnOff()
        #expect(!second.sections.isEmpty)
        #expect(second.isEnabled)
    }
}
