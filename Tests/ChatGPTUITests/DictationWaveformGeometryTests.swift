import Testing
@testable import ChatGPTUI

@Suite struct DictationWaveformGeometryTests {
    @Test func nonFiniteSamplesBecomeSilenceAndFiniteSamplesClamp() {
        let heights = DictationWaveformGeometry.heights(
            levels: [.nan, .infinity, -.infinity, -2, 2, 0.5], availableWidth: 36, availableHeight: 28)
        #expect(heights == [3, 3, 3, 3, 25, 14])
        #expect(heights.allSatisfy { $0.isFinite })
    }
    @Test func geometryNeverExceedsAllocatedHeight() {
        #expect(DictationWaveformGeometry.heights(levels: [0, 1], availableWidth: 12, availableHeight: 2) == [2, 2])
        #expect(
            DictationWaveformGeometry.heights(levels: [1], availableWidth: 6, availableHeight: 20, peakHeight: 100) == [
                20
            ])
    }
    @Test func invalidBoundsCannotProduceInvalidFramesOrUnboundedArrays() {
        for width in [Double.nan, .infinity, -.infinity, -1, 0] {
            #expect(DictationWaveformGeometry.heights(levels: [1], availableWidth: width, availableHeight: 28).isEmpty)
        }
        for height in [Double.nan, .infinity, -.infinity, -1, 0] {
            #expect(
                DictationWaveformGeometry.heights(levels: [1], availableWidth: 100, availableHeight: height).isEmpty)
        }
        #expect(
            DictationWaveformGeometry.heights(
                levels: [1], availableWidth: .greatestFiniteMagnitude, availableHeight: 28
            ).count == 512)
    }
    @Test func silenceAndCustomPeakAreDeterministic() {
        #expect(DictationWaveformGeometry.heights(levels: [], availableWidth: 18, availableHeight: 28) == [3, 3, 3])
        #expect(
            DictationWaveformGeometry.heights(levels: [0, 1], availableWidth: 24, availableHeight: 28, peakHeight: 17)
                == [3, 17, 3, 17])
        #expect(
            DictationWaveformGeometry.heights(levels: [1], availableWidth: 6, availableHeight: 28, peakHeight: .nan)
                == [25])
    }
}
