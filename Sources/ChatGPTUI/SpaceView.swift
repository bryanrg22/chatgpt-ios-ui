#if os(iOS)
import SwiftUI

/// Offline Space presentation. Images are resolved by the host; no URL loading
/// or private photo access is performed by this view.
public struct SpaceView: View {
    @Bindable private var state: SpacePresentationState
    private let onBack: () -> Void
    private let imageProvider: (SpaceItem) -> Image?
    public init(state: SpacePresentationState, onBack: @escaping () -> Void, imageProvider: @escaping (SpaceItem) -> Image? = { _ in nil }) {
        self.state = state; self.onBack = onBack; self.imageProvider = imageProvider
    }
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) { DrawerGlyph() }.accessibilityLabel("Open sidebar")
                Spacer(); Text(state.title).font(.system(size: 17, weight: .semibold)); Spacer()
                optionsMenu
            }.padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 5) {
                    ForEach(SpaceTab.allCases, id: \.self) { tab in
                        Button { state.chooseTab(tab) } label: {
                            Text(tab.rawValue).font(.system(size: 15)).padding(.horizontal, 15).frame(height: 40)
                                .background(state.tab == tab ? Color(white: 0.22) : .clear, in: Capsule())
                        }.accessibilityIdentifier("space.tab.\(tab.rawValue)").accessibilityAddTraits(state.tab == tab ? .isSelected : [])
                    }
                }.padding(.horizontal, 16)
            }.scrollIndicators(.hidden)
            content
        }.foregroundStyle(.primary).tint(Color.primary).background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .safeAreaInset(edge: .bottom) { bottomBar.padding(.horizontal, 28).padding(.bottom, 5) }
            .fullScreenCover(isPresented: Binding(get: { state.activeImage != nil }, set: { if !$0 { state.closeImage() } })) {
                if let item = state.activeImage { SpaceImagePresentation(item: item, space: state, imageProvider: imageProvider) }
            }
    }
    private var optionsMenu: some View {
        Menu {
            Section {
                Button { state.layout = .grid } label: { Label("Grid", systemImage: state.layout == .grid ? "checkmark" : "square.grid.2x2") }
                Button { state.layout = .list } label: { Label("List", systemImage: state.layout == .list ? "checkmark" : "list.bullet") }
            }
            Section { Button { state.onAction(.selectItems) } label: { Label("Select", systemImage: "checkmark.circle") } }
            Section {
                if state.tab == .suggested { Button { state.onAction(.openPlugins) } label: { Label("Plugins", systemImage: "at") } }
                Menu {
                    Section {
                        filterButton(.uploaded, symbol: "arrow.up.to.line")
                        filterButton(.generated, symbol: "wand.and.stars")
                    }
                    Section {
                        filterButton(.images, symbol: "photo")
                        filterButton(.documents, symbol: "document")
                        filterButton(.spreadsheets, symbol: "tablecells")
                        filterButton(.presentations, symbol: "rectangle.on.rectangle")
                        filterButton(.pdfs, symbol: "doc.richtext")
                    }
                } label: { Label("Filter", systemImage: "line.3.horizontal.decrease") }
            }
            Section { Button { state.onAction(.openDeleted) } label: { Label("Deleted", systemImage: "trash") } }
        } label: { GlassCircle(symbol: "ellipsis") }.menuOrder(.fixed).accessibilityLabel("Space options")
    }
    private func filterButton(_ filter: SpaceFilter, symbol: String) -> some View {
        Button { state.chooseFilter(filter) } label: { Label(filter.rawValue, systemImage: state.filter == filter ? "checkmark" : symbol) }.accessibilityIdentifier("space.filter.\(filter.rawValue)")
    }
    @ViewBuilder private var content: some View {
        switch state.loadState {
        case .loading:
            VStack(spacing: 32) {
                ForEach(0..<2) { _ in HStack(spacing: 16) {
                    Circle().fill(Color(white: 0.08)).frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 7) { Capsule().fill(Color(white: 0.13)).frame(width: 157, height: 7); Capsule().fill(Color(white: 0.13)).frame(width: 92, height: 5) }
                    Spacer()
                } }
                Spacer()
            }.padding(.horizontal, 24).padding(.top, 16).accessibilityLabel("Loading Space")
        case .failed(let message):
            VStack(spacing: 16) { Text(message).multilineTextAlignment(.center); Button("Try again") { state.onAction(.retry) }; Spacer() }.padding(32)
        case .loaded:
            if state.visibleItems.isEmpty { emptyContent }
            else { ScrollView {
                if state.layout == .list || state.tab == .folders || state.tab == .pages {
                    LazyVStack(spacing: 4) { ForEach(state.visibleItems) { item in itemRow(item) } }.padding(.horizontal, 16)
                } else { masonry.padding(.horizontal, 16) }
            }.scrollIndicators(.hidden) }
        }
    }
    private var emptyContent: some View {
        VStack(spacing: 8) {
            if state.tab == .favorites && state.query.isEmpty && state.filter == nil {
                Text("Save your favorites").font(.system(size: 18, weight: .semibold))
                Text("Items you add to Favorites will\nappear here.").font(.system(size: 17)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Image(systemName: "bookmark").font(.system(size: 24)).foregroundStyle(.secondary).padding(.top, 22)
            } else {
                Text(state.query.isEmpty ? "No items" : "No results").font(.system(size: 17)).foregroundStyle(.secondary)
            }
            Spacer()
        }.frame(maxWidth: .infinity).padding(.top, 30).accessibilityIdentifier("space.empty")
    }
    private var masonry: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(0..<2) { column in
                LazyVStack(spacing: 12) {
                    ForEach(Array(state.visibleItems.enumerated()).filter { $0.offset % 2 == column }.map(\.element)) { item in
                        Button { state.open(item.id) } label: { gridCard(item) }.accessibilityIdentifier("space.item.\(item.id)").accessibilityLabel(item.title)
                    }
                }.frame(maxWidth: .infinity)
            }
        }
    }
    private func gridCard(_ item: SpaceItem) -> some View {
        Group {
            if let image = imageProvider(item) {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                VStack(alignment: .leading) { Text(item.title).font(.system(size: 17)).lineLimit(3); Spacer(); Image(systemName: symbol(item.kind)).font(.system(size: 25)).foregroundStyle(iconColor(item.kind)) }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).frame(height: 170)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 17)).overlay { RoundedRectangle(cornerRadius: 17).stroke(Color(white: 0.18), lineWidth: 1) }
    }
    private func itemRow(_ item: SpaceItem) -> some View {
        Button { state.open(item.id) } label: {
            HStack(spacing: 12) {
                Group {
                    if let image = imageProvider(item) { image.resizable().scaledToFill() }
                    else { Image(systemName: symbol(item.kind)).font(.system(size: 21)).foregroundStyle(iconColor(item.kind)).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(white: 0.12)) }
                }.frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.system(size: 17)).lineLimit(1)
                    if !item.subtitle.isEmpty { Text(item.subtitle).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
        }.accessibilityIdentifier("space.item.\(item.id)")
    }
    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) { Image(systemName: "magnifyingglass").font(.system(size: 19)); TextField("Search", text: $state.query).font(.system(size: 17)).accessibilityIdentifier("space.search") }
                .padding(.horizontal, 15).frame(height: 48).glassEffect(.regular, in: Capsule())
            Menu {
                Button { state.onAction(.createImage) } label: { Label("Image", systemImage: "photo") }
                Button { state.onAction(.createNote) } label: { Label("Note", systemImage: "note.text") }
                Button { state.onAction(.createFolder) } label: { Label("Folder", systemImage: "folder") }
                Divider()
                Button { state.onAction(.uploadFiles) } label: { Label("Upload files", systemImage: "arrow.up.to.line") }
            } label: { Image(systemName: "plus").font(.system(size: 27)).frame(width: 48, height: 48).glassEffect(.regular.interactive(), in: Circle()) }.menuOrder(.fixed).accessibilityLabel("Add to Space")
        }
    }
    private func symbol(_ kind: SpaceItemKind) -> String {
        switch kind { case .image: "photo"; case .document: "doc.text.fill"; case .spreadsheet: "tablecells.fill"; case .presentation: "rectangle.on.rectangle"; case .pdf: "doc.richtext"; case .page: "doc.text"; case .folder: "folder" }
    }
    private func iconColor(_ kind: SpaceItemKind) -> Color {
        switch kind { case .document, .page: .blue; case .pdf: .red; case .spreadsheet: .green; default: .secondary }
    }
}
private struct SpaceImagePresentation: View {
    let item: SpaceItem
    let space: SpacePresentationState
    let imageProvider: (SpaceItem) -> Image?
    @State private var viewer: MediaViewerState
    init(item: SpaceItem, space: SpacePresentationState, imageProvider: @escaping (SpaceItem) -> Image?) {
        self.item = item; self.space = space; self.imageProvider = imageProvider
        _viewer = State(initialValue: MediaViewerState(item: ChatMedia(id: item.id, imageKey: item.imageKey ?? "", title: item.title), isFavorite: item.isFavorite))
    }
    var body: some View {
        MediaViewer(state: viewer, imageProvider: { _ in imageProvider(item) }, accessibilityContext: "Space image", menuTitle: item.title)
            .onAppear {
                viewer.onAction = { action in
                    switch action {
                    case .close: space.closeImage()
                    case .favorite(let id, let selected):
                        if space.items.first(where: { $0.id == id })?.isFavorite != selected { space.toggleFavorite(id) }
                    case .download(let id): space.imageAction(.download(id))
                    case .edit(let id): space.imageAction(.editImage(id))
                    case .resize(let id): space.imageAction(.resizeImage(id))
                    case .remove(let id): space.imageAction(.removeImage(id))
                    case .open, .copy, .requestVideoFit: break
                    }
                }
            }
    }
}
#endif
