#if os(iOS)
import SwiftUI

struct ChatMediaThumbnail: View {
    let item: ChatMedia
    let provider: (ChatMedia) -> Image?
    var showsDuration = true
    var body: some View {
        Group {
            if let image = provider(item) { image.resizable().scaledToFill() }
            else { Rectangle().fill(Color(white: 0.15)).overlay { Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(.secondary) } }
        }.clipped().overlay(alignment: .bottomLeading) {
            if showsDuration, let duration = item.durationLabel {
                Text(duration).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 4).padding(.vertical, 2).background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4)).padding(8)
            }
        }.accessibilityLabel(item.kind == .video ? "Video \(item.title)" : item.title.isEmpty ? "Image" : item.title)
    }
}

public struct RecentPhotosPanel: View {
    @Bindable private var state: PhotoPickerPresentationState
    private let imageProvider: (ChatMedia) -> Image?
    private let onChoose: ([ChatMedia]) -> Void
    private let onAllPhotos: () -> Void
    public init(state: PhotoPickerPresentationState, imageProvider: @escaping (ChatMedia) -> Image? = { _ in nil }, onChoose: @escaping ([ChatMedia]) -> Void, onAllPhotos: @escaping () -> Void) {
        self.state = state; self.imageProvider = imageProvider; self.onChoose = onChoose; self.onAllPhotos = onAllPhotos
    }
    public var body: some View {
        GeometryReader { geometry in
            let width = max(0, (geometry.size.width - 4) / 3)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(state.items) { item in
                        Button { state.toggle(item.id) } label: {
                            ChatMediaThumbnail(item: item, provider: imageProvider).frame(width: width, height: width)
                                .overlay { if state.selectedIDs.contains(item.id) { Color.black.opacity(0.22) } }
                                .overlay(alignment: .bottomTrailing) {
                                    if let index = state.selectedIDs.firstIndex(of: item.id) {
                                        Text(String(index + 1)).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).frame(width: 24, height: 24).background(Color.blue, in: Circle()).overlay { Circle().stroke(.white, lineWidth: 1.5) }.padding(5)
                                    }
                                }
                        }.accessibilityIdentifier("photos.item.\(item.id)").accessibilityLabel(item.title).accessibilityAddTraits(state.selectedIDs.contains(item.id) ? .isSelected : [])
                    }
                }
            }.scrollIndicators(.hidden)
                .overlay(alignment: .bottom) {
                    HStack {
                        Button { state.close() } label: { GlassCircle(symbol: "chevron.left") }.accessibilityLabel("Close recent photos")
                        Spacer()
                        Button {
                            if state.selection.isEmpty { onAllPhotos() } else { onChoose(state.takeSelection()) }
                        } label: {
                            Text(state.selectionButtonTitle).font(.system(size: 17, weight: .semibold)).padding(.horizontal, 20).frame(height: 44)
                                .glassEffect(.regular.tint(state.selection.isEmpty ? .clear : .blue).interactive(), in: Capsule())
                        }.accessibilityIdentifier("photos.add")
                    }.padding(.horizontal, 24).padding(.bottom, 24)
                }
        }.background(.black).clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous)).foregroundStyle(.white).buttonStyle(.plain)
    }
}
#endif
