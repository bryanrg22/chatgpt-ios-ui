import Foundation

/// Defensive presentation geometry for host-supplied samples, not an audio meter calibration.
public enum DictationWaveformGeometry {
    /// The 25pt default peak is provisional. Only the silent dotted mobile reference was captured.
    /// Non-finite samples become silence; all bars fit the caller's allocated height.
    public static func heights(
        levels: [Double], availableWidth: Double, availableHeight: Double, peakHeight: Double = 25
    ) -> [Double] {
        guard availableWidth.isFinite, availableHeight.isFinite,
            availableWidth > 0, availableHeight > 0
        else { return [] }
        let count = Int(min(512, max(1, floor(availableWidth / 6))))
        let peak = min(availableHeight, peakHeight.isFinite && peakHeight > 0 ? peakHeight : 25)
        let baseline = min(3, peak)
        return (0..<count).map { index in
            let raw = levels.isEmpty ? 0 : levels[index % levels.count]
            let level = raw.isFinite ? min(1, max(0, raw)) : 0
            return baseline + level * (peak - baseline)
        }
    }
}
