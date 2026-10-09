import Foundation
import Observation

public enum ChatMediaKind: String, Sendable { case image, video }

/// Host-resolved media metadata. `imageKey` is opaque: this package never treats
/// it as a URL or reads the photo library. Supply the matching image to the view.
public struct ChatMedia: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let imageKey: String
    public let title: String
    public let aspectRatio: Double
    public let kind: ChatMediaKind
    public let durationSeconds: Int?
    public var durationLabel: String? {
        guard kind == .video, let durationSeconds else { return nil }
        return "\(durationSeconds / 60):" + String(format: "%02d", durationSeconds % 60)
    }
    public init(id: UUID = UUID(), imageKey: String, title: String = "", aspectRatio: Double = 1, kind: ChatMediaKind = .image, durationSeconds: Int? = nil) {
        self.id = id; self.imageKey = imageKey; self.title = title
        self.aspectRatio = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1
        self.kind = kind
        self.durationSeconds = kind == .video ? durationSeconds.flatMap { $0 >= 0 ? $0 : nil } : nil
    }
}

/// Intents only. In particular, `remove` requests the observed eraser tool; it
/// does not delete the media or pretend an edited image has been produced.
public enum MediaAction: Equatable, Sendable {
    case open(UUID), close(UUID), copy(UUID), favorite(UUID, Bool)
    case download(UUID), edit(UUID), resize(UUID), remove(UUID)
    /// The captured video fit button requests host presentation; no unverified
    /// zoom/crop transition or player state is manufactured by the skeleton.
    case requestVideoFit(UUID)
    public var mediaID: UUID {
        switch self {
        case .open(let id), .close(let id), .copy(let id), .favorite(let id, _),
             .download(let id), .edit(let id), .resize(let id), .remove(let id), .requestVideoFit(let id): id
        }
    }
}

@MainActor @Observable public final class MediaViewerState {
    public private(set) var item: ChatMedia?
    public private(set) var isFavorite: Bool
    public private(set) var showsChrome = true
    public var onAction: (MediaAction) -> Void = { _ in }
    public init(item: ChatMedia? = nil, isFavorite: Bool = false) {
        self.item = item; self.isFavorite = item?.kind == .image && isFavorite
    }
    public func present(_ item: ChatMedia, isFavorite: Bool = false) {
        self.item = item; self.isFavorite = item.kind == .image && isFavorite; showsChrome = true
        onAction(.open(item.id))
    }
    public func dismiss() {
        guard let item else { return }
        self.item = nil; isFavorite = false; showsChrome = true
        onAction(.close(item.id))
    }
    public func toggleChrome() { if item?.kind == .image { showsChrome.toggle() } }
    public func toggleFavorite() {
        guard let item else { return }
        perform(.favorite(item.id, !isFavorite))
    }
    public func perform(_ action: MediaAction) {
        guard let item, item.id == action.mediaID else { return }
        // Only observed video controls are surfaced. Image-only commands from
        // a stale host/menu cannot apply to a video with the same identifier.
        if item.kind == .video {
            switch action {
            case .close: dismiss()
            case .open, .requestVideoFit: onAction(action)
            default: break
            }
            return
        }
        switch action {
        case .requestVideoFit: break
        case .close: dismiss()
        case .favorite(_, let selected):
            guard isFavorite != selected else { return }
            isFavorite = selected; onAction(action)
        default: onAction(action)
        }
    }
}
