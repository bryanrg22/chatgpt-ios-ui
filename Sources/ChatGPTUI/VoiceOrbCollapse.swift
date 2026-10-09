import Foundation

/// Sampled endpoint motion from the supplied 59.66fps reference, every fifth frame.
/// This interpolates one recorded collapse; it does not model speech intensity or orb texture.
public enum VoiceOrbCollapse {
    public struct Sample: Equatable, Sendable {
        public var diameter: Double
        public var centerY: Double
        public init(diameter: Double, centerY: Double) {
            self.diameter = diameter
            self.centerY = centerY
        }
    }
    public static let duration = 0.5
    private static let diameters = [594.0, 270, 162, 238, 256, 240, 236]
    private static let centers = [875.0, 1101, 1217, 1233, 1220, 1212, 1210]
    public static func sample(elapsed: Double, from: Sample, to: Sample) -> Sample {
        guard elapsed.isFinite else { return to }
        // TimelineView may supply a date just before the state mutation that starts the animation.
        guard elapsed > 0 else { return from }
        guard elapsed < duration else { return to }
        let position = elapsed / duration * 6
        let index = min(5, Int(position))
        let fraction = position - Double(index)
        let diameter = diameters[index] + (diameters[index + 1] - diameters[index]) * fraction
        let center = centers[index] + (centers[index + 1] - centers[index]) * fraction
        let diameterProgress = (diameter - 594) / (236 - 594)
        let centerProgress = (center - 875) / (1210 - 875)
        return .init(
            diameter: max(1, from.diameter + (to.diameter - from.diameter) * diameterProgress),
            centerY: from.centerY + (to.centerY - from.centerY) * centerProgress)
    }
}
