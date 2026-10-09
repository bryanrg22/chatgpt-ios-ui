#if os(iOS)
import SwiftUI

public struct ImagesDestinationView: View {
    @Bindable private var state: ImagesPresentationState
    private let onSidebar: () -> Void
    private let artwork: (ImageTemplate) -> AnyView?
    private let composer: AnyView?
    public init(state: ImagesPresentationState, onSidebar: @escaping () -> Void, artwork: @escaping (ImageTemplate) -> AnyView? = { _ in nil }, composer: AnyView? = nil) {
        self.state = state; self.onSidebar = onSidebar; self.artwork = artwork; self.composer = composer
    }
    public var body: some View {
        VStack(spacing: 0) {
            HStack { Button(action: onSidebar) { DrawerGlyph() }.accessibilityLabel("Open sidebar"); Spacer(); Color.clear.frame(width: 44, height: 44) }
                .overlay { Text("Images").font(.system(size: 17, weight: .semibold)) }.padding(.horizontal, 16).padding(.top, 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if state.showsLibraryNotice { notice.padding(.top, 24).padding(.bottom, 8) }
                    HStack(spacing: 8) {
                        ForEach(ImagesCategory.allCases, id: \.self) { category in
                            Button { state.selectCategory(category) } label: { Text(category.rawValue).font(.system(size: 17, weight: .semibold)).padding(.horizontal, 16).frame(height: 44).background(state.category == category ? Color.primary.opacity(0.25) : .clear, in: Capsule()).foregroundStyle(state.category == category ? .primary : .secondary) }
                                .accessibilityIdentifier("images.category.\(category.rawValue)").accessibilityAddTraits(state.category == category ? .isSelected : [])
                        }
                    }
                    LazyVGrid(columns: [.init(.flexible(), spacing: 16), .init(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(state.visibleItems) { item in
                            Button { state.open(item.id) } label: {
                                artworkContent(item).aspectRatio(0.8, contentMode: .fit).overlay(alignment: .bottomLeading) {
                                    Text(item.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).padding(12).frame(maxWidth: .infinity, alignment: .leading).background { LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom) }
                                }.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).contentShape(RoundedRectangle(cornerRadius: 24))
                            }.accessibilityIdentifier("images.template.\(item.id)").accessibilityLabel(item.title)
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, composer == nil ? 16 : 120)
            }.scrollIndicators(.hidden)
        }.background(ChatDesign.canvas).buttonStyle(.plain)
            .overlay(alignment: .bottom) { if let composer { composer.padding(.horizontal, 12) } }
            .sheet(isPresented: Binding(get: { state.selected != nil }, set: { if !$0 { state.close() } })) {
                if let item = state.selected { detail(item).presentationDetents([.height(550)]).presentationDragIndicator(.hidden).presentationCornerRadius(36).presentationBackground(ChatDesign.canvas) }
            }
    }
    private var notice: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical").font(.system(size: 17)).frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your generated images moved to Library").font(.system(size: 13.5, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.9)
                Text("You can now find your generated images in the Library tab from the sidebar").font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(2)
            }
            Button { state.dismissNotice() } label: { Image(systemName: "xmark").font(.system(size: 17)).frame(width: 20, height: 44) }.accessibilityLabel("Dismiss Library notice")
        }.padding(16).frame(maxWidth: .infinity).overlay { RoundedRectangle(cornerRadius: 26).stroke(.primary.opacity(0.07), lineWidth: 1) }
    }
    private func artworkContent(_ item: ImageTemplate) -> some View {
        GeometryReader { geometry in
            if let supplied = artwork(item) { supplied.frame(width: geometry.size.width, height: geometry.size.height).clipped() }
            else { Color.secondary.opacity(0.2).overlay { Image(systemName: "photo").font(.system(size: 34)).foregroundStyle(.secondary) } }
        }
    }
    private func detail(_ item: ImageTemplate) -> some View {
        VStack(spacing: 0) {
            artworkContent(item).frame(height: 300).overlay(alignment: .topTrailing) {
                HStack(spacing: 6) {
                    Button { state.shareSelected() } label: { GlassCircle(symbol: "square.and.arrow.up") }.accessibilityLabel("Share image template")
                    Button { state.close() } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close image template")
                }.padding(16)
            }
            Text(item.headline).font(.system(size: 21, weight: .semibold)).padding(.top, 30)
            Text(item.prompt).font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(3).multilineTextAlignment(.center).lineLimit(3).padding(.horizontal, 26).padding(.top, 12)
            Spacer(minLength: 20)
            Button { state.trySelected() } label: { Text("Try it").font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 50).foregroundStyle(ChatDesign.canvas).background(Color.primary, in: Capsule()) }.accessibilityIdentifier("images.try").padding(.horizontal, 30).padding(.bottom, 24)
        }.background(ChatDesign.canvas).buttonStyle(.plain)
    }
}
#endif
