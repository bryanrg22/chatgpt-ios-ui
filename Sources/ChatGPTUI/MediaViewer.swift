#if os(iOS)
    import SwiftUI

    /// Full-screen image presentation shared by chat and Space. All image content
    /// comes from the host; editing, copying and downloading are typed intents.
    public struct MediaViewer: View {
        @Bindable private var state: MediaViewerState
        private let imageProvider: (ChatMedia) -> Image?
        private let videoProvider: (ChatMedia) -> AnyView?
        private let accessibilityContext: String
        private let menuTitle: String?
        public init(
            state: MediaViewerState, imageProvider: @escaping (ChatMedia) -> Image? = { _ in nil },
            videoProvider: @escaping (ChatMedia) -> AnyView? = { _ in nil }, accessibilityContext: String = "image",
            menuTitle: String? = nil
        ) {
            self.state = state
            self.imageProvider = imageProvider
            self.videoProvider = videoProvider
            self.accessibilityContext = accessibilityContext
            self.menuTitle = menuTitle
        }
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                    if let item = state.item {
                        if item.kind == .video {
                            video(item, in: geometry.size)
                            videoChrome(item, insets: geometry.safeAreaInsets)
                        } else {
                            media(item, in: geometry.size)
                                .contentShape(Rectangle())
                                .onTapGesture { state.toggleChrome() }
                                .accessibilityLabel(item.title.isEmpty ? "Image" : item.title)
                                .accessibilityIdentifier("media.image")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction(named: state.showsChrome ? "Hide controls" : "Show controls") {
                                    state.toggleChrome()
                                }
                            if state.showsChrome {
                                chrome(item, insets: geometry.safeAreaInsets)
                            }
                        }
                    }
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }.ignoresSafeArea().background(Color.black).foregroundStyle(.white).tint(.white)
                .preferredColorScheme(.dark).statusBarHidden(state.item?.kind != .video).buttonStyle(.plain)
        }
        private func video(_ item: ChatMedia, in size: CGSize) -> some View {
            Group {
                if let player = videoProvider(item) {
                    player
                } else if let poster = imageProvider(item) {
                    poster.resizable().scaledToFit()
                } else {
                    Image(systemName: "video").font(.system(size: 48)).foregroundStyle(.gray)
                }
            }.frame(width: size.width, height: size.height).clipped()
                .accessibilityIdentifier("media.video")
        }
        private func videoChrome(_ item: ChatMedia, insets: EdgeInsets) -> some View {
            VStack {
                HStack {
                    Button {
                        state.dismiss()
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }
                    .accessibilityLabel("Close video").accessibilityIdentifier("media.close")
                    Spacer()
                    Button {
                        state.perform(.requestVideoFit(item.id))
                    } label: {
                        GlassCircle(symbol: "arrow.down.right.and.arrow.up.left")
                    }
                    .accessibilityLabel("Fit video").accessibilityIdentifier("media.video.fit")
                }.padding(.horizontal, 16).padding(.top, max(insets.top, 59) + 8)
                Spacer()
            }
        }
        private func media(_ item: ChatMedia, in size: CGSize) -> some View {
            // The resolved image supplies its intrinsic aspect ratio. Fit it inside
            // the complete viewport, independently of the overlaid chrome.
            return Group {
                if let image = imageProvider(item) {
                    image.resizable().scaledToFit()
                } else {
                    Image(systemName: "photo").resizable().scaledToFit().foregroundStyle(.gray).padding(60)
                }
            }.frame(width: size.width, height: size.height)
        }

        private func chrome(_ item: ChatMedia, insets: EdgeInsets) -> some View {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        state.dismiss()
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }
                    .accessibilityLabel("Close \(accessibilityContext)").accessibilityIdentifier("media.close")
                    Spacer()
                    Menu {
                        if let menuTitle, !menuTitle.isEmpty { Text(menuTitle) }
                        Button {
                            state.toggleFavorite()
                        } label: {
                            Label(
                                state.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: "bookmark"
                            )
                        }
                    } label: {
                        GlassCircle(symbol: "ellipsis")
                    }
                    .menuOrder(.fixed).accessibilityLabel(
                        "\(accessibilityContext.prefix(1).uppercased())\(accessibilityContext.dropFirst()) options"
                    ).accessibilityIdentifier("media.options")
                    Button {
                        state.perform(.download(item.id))
                    } label: {
                        GlassCircle(symbol: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Download \(accessibilityContext)").accessibilityIdentifier("media.download")
                }.padding(.horizontal, 16).padding(.top, max(insets.top, 59) + 8)
                    .padding(.bottom, 22)
                    .background(
                        LinearGradient(
                            colors: [Color(white: 0.12), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
                Spacer(minLength: 0)
                HStack {
                    tool("Edit", symbol: "bubble.left.and.bubble.right", action: .edit(item.id))
                    Spacer()
                    tool("Resize", symbol: "viewfinder", action: .resize(item.id))
                    Spacer()
                    tool("Remove", symbol: "eraser", action: .remove(item.id))
                }.padding(.horizontal, 49).padding(.top, 22).padding(.bottom, max(insets.bottom, 34) + 12)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0), Color(white: 0.12)], startPoint: .top, endPoint: .bottom))
            }
        }
        private func tool(_ title: String, symbol: String, action: MediaAction) -> some View {
            Button {
                state.perform(action)
            } label: {
                VStack(spacing: 8) {
                    Group {
                        if title == "Edit" {
                            Image(systemName: "bubble.left").overlay {
                                Image(systemName: "plus").font(.system(size: 13, weight: .medium)).offset(y: -1)
                            }
                        } else {
                            Image(systemName: symbol)
                        }
                    }.font(.system(size: 23)).frame(width: 52, height: 52).glassEffect(
                        .regular.interactive(), in: Circle())
                    Text(title).font(.system(size: 13))
                }.contentShape(Rectangle())
            }.accessibilityLabel("\(title) \(accessibilityContext)").accessibilityIdentifier("media.tool.\(title)")
        }
    }
#endif
