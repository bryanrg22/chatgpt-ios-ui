import Foundation
import Testing
@testable import ChatGPTUI

@Suite @MainActor struct MediaVideoTests {
    @Test func legacyImagesHaveNoMovieDuration() {
        let image = ChatMedia(imageKey: "still", durationSeconds: 8)
        #expect(image.kind == .image); #expect(image.durationSeconds == nil); #expect(image.durationLabel == nil)
    }
    @Test func durationIsHostDataWithoutInventedRoundingOrOverflow() {
        #expect(ChatMedia(imageKey: "movie", kind: .video).durationLabel == nil)
        #expect(ChatMedia(imageKey: "movie", kind: .video, durationSeconds: -1).durationLabel == nil)
        #expect(ChatMedia(imageKey: "movie", kind: .video, durationSeconds: 0).durationLabel == "0:00")
        #expect(ChatMedia(imageKey: "movie", kind: .video, durationSeconds: 8).durationLabel == "0:08")
        #expect(ChatMedia(imageKey: "movie", kind: .video, durationSeconds: 90).durationLabel == "1:30")
        #expect(ChatMedia(imageKey: "movie", kind: .video, durationSeconds: Int.max).durationLabel != nil)
    }
    @Test func videoControlsEmitOnlyCapturedIntentsAndDoNotInventPlayback() {
        let video = ChatMedia(imageKey: "movie", kind: .video, durationSeconds: 8)
        let state = MediaViewerState(item: video, isFavorite: true)
        var events: [MediaAction] = []; state.onAction = { events.append($0) }
        state.toggleChrome(); state.toggleFavorite()
        for action in [MediaAction.edit(video.id), .resize(video.id), .remove(video.id), .download(video.id), .copy(video.id)] { state.perform(action) }
        #expect(state.showsChrome); #expect(!state.isFavorite); #expect(events.isEmpty)
        state.perform(.requestVideoFit(UUID())); #expect(events.isEmpty)
        state.perform(.requestVideoFit(video.id))
        #expect(events == [.requestVideoFit(video.id)]); #expect(state.item == video)
        state.dismiss(); #expect(events.last == .close(video.id)); #expect(state.item == nil)
    }
    @Test func changingMediaKindsRestoresImageControlsAndRejectsVideoIntent() {
        let image = ChatMedia(imageKey: "still"); let movie = ChatMedia(imageKey: "movie", kind: .video)
        let state = MediaViewerState(item: image); state.toggleChrome(); #expect(!state.showsChrome)
        state.present(movie, isFavorite: true); #expect(state.showsChrome); #expect(!state.isFavorite)
        state.present(image, isFavorite: true); #expect(state.isFavorite)
        var events: [MediaAction] = []; state.onAction = { events.append($0) }
        state.perform(.requestVideoFit(image.id)); #expect(events.isEmpty)
        state.toggleChrome(); #expect(!state.showsChrome)
    }
}
