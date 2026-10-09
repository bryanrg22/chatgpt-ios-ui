/// Caller-owned presentation for a sent video card. This does not start, stop,
/// or infer playback; the host supplies moving content through its view closure.
public enum VideoCardPresentation: Equatable, Sendable {
    case pausedPoster
    case hostPreview
    public var showsPlayAffordance: Bool { self == .pausedPoster }
}
