#if os(iOS)
    import SwiftUI

    /// The captured empty Sites directory. A host can supply loaded/search content
    /// without the package manufacturing an uncaptured populated layout.
    public struct SitesDestinationView: View {
        @Bindable private var state: ExplorePresentationState
        private let onSidebar: () -> Void
        private let onCreate: () -> Void
        private let content: ((String) -> AnyView?)?
        public init(
            state: ExplorePresentationState, onSidebar: @escaping () -> Void, onCreate: @escaping () -> Void,
            content: ((String) -> AnyView?)? = nil
        ) {
            self.state = state
            self.onSidebar = onSidebar
            self.onCreate = onCreate
            self.content = content
        }
        public var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onSidebar) { DrawerGlyph() }.accessibilityLabel("Open sidebar")
                    Spacer()
                    Text("Sites").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button(action: onCreate) { GlassCircle(symbol: "plus") }.accessibilityLabel("Create site")
                        .accessibilityIdentifier("sites.add")
                }.padding(.horizontal, 16).padding(.top, 2)
                GeometryReader { geometry in
                    if let view = content?(state.sitesQuery) {
                        view
                    } else {
                        VStack(spacing: 0) {
                            Image(systemName: "square.grid.2x2").font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("No sites yet").font(.system(size: 20, weight: .semibold)).padding(.top, 28)
                            Text("Create a site with ChatGPT and it will\nappear here.").font(.system(size: 20))
                                .foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3).padding(
                                    .top, 4)
                            Button(action: onCreate) {
                                Text("Create site").font(.system(size: 17, weight: .semibold)).padding(.horizontal, 21)
                                    .frame(height: 40).foregroundStyle(ChatDesign.canvas).background(
                                        Color.primary, in: Capsule())
                            }.padding(.top, 32).accessibilityIdentifier("sites.create")
                        }.frame(maxWidth: .infinity).padding(.top, min(70, geometry.size.height * 0.2))
                    }
                }
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").font(.system(size: 19)).foregroundStyle(.secondary)
                    TextField(
                        "Search sites", text: $state.sitesQuery,
                        prompt: Text("Search sites").foregroundStyle(Color(uiColor: .secondaryLabel))
                    ).font(.system(size: 17)).accessibilityIdentifier("sites.search")
                }.padding(.horizontal, 15).frame(height: 48).glassEffect(.regular, in: Capsule()).padding(
                    .horizontal, 34
                ).padding(.bottom, 0)
            }.background(ChatDesign.canvas).buttonStyle(.plain)
        }
    }
#endif
