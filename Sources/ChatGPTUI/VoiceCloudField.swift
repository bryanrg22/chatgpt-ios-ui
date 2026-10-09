import Foundation

/// Original deterministic cloud field; no reference pixels or proprietary shader are used.
/// Phase controls texture drift only, never an inferred microphone/audio mapping.
enum VoiceCloudField {
    static func alpha(x: Double, y: Double, phase: Double, tilt: Double = 0) -> Double {
        guard x.isFinite, y.isFinite else { return 0 }
        let t = phase.isFinite ? phase.truncatingRemainder(dividingBy: 1000) : 0
        let px = min(1, max(0, x))
        let py = min(1, max(0, y))
        let broad = fractal(px * 3.8 + t * 0.18, py * 4.8 - t * 0.12)
        let detail = fractal(px * 17 + t * 0.25, py * 20 - t * 0.2)
        let boundary =
            0.53 + (tilt.isFinite ? tilt : 0) * (0.5 - px) + 0.34 * (broad - 0.5) + 0.045 * sin(px * 6 + t * 0.15)
        let cloud = smooth((py - boundary + 0.065 + (detail - 0.5) * 0.13) / 0.20)
        let fine = noise(px * 97 + t, py * 97 - t) * 0.025
        return min(1, max(0, cloud * (0.73 + broad * 0.35) + broad * 0.035 + fine))
    }
    private static func smooth(_ value: Double) -> Double {
        let n = min(1, max(0, value))
        return n * n * (3 - 2 * n)
    }
    private static func fractal(_ x: Double, _ y: Double) -> Double {
        var result = 0.0
        var amplitude = 0.54
        var frequency = 1.0
        for _ in 0..<4 {
            result += noise(x * frequency, y * frequency) * amplitude
            frequency *= 2.03
            amplitude *= 0.48
        }
        return result
    }
    private static func noise(_ x: Double, _ y: Double) -> Double {
        let ix = floor(x)
        let iy = floor(y)
        let fx = smooth(x - ix)
        let fy = smooth(y - iy)
        let a = hash(ix, iy)
        let b = hash(ix + 1, iy)
        let c = hash(ix, iy + 1)
        let d = hash(ix + 1, iy + 1)
        return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy
    }
    private static func hash(_ x: Double, _ y: Double) -> Double {
        let value = sin(x * 127.1 + y * 311.7) * 43758.5453
        return value - floor(value)
    }
}
