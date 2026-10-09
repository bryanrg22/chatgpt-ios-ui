import Foundation

public struct MemorySummarySection: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var text: String
    public init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

/// Fictional, app-owned display data. Refreshing/deleting never touches a real account or memory service.
public struct MemorySummaryPresentationState: Equatable, Sendable {
    public private(set) var sections: [MemorySummarySection]
    public private(set) var isEnabled = true
    public private(set) var updatedLabel = "Updated 10 hours ago"
    public init(sections: [MemorySummarySection] = Self.samples) { self.sections = sections }
    public mutating func refresh() {
        guard isEnabled else { return }
        updatedLabel = "Updated just now"
    }
    public mutating func deleteAndTurnOff() {
        sections = []
        isEnabled = false
        updatedLabel = "Memory is off"
    }
    public static let samples = [
        MemorySummarySection(
            id: "overview", title: "Overview",
            text:
                "You’re Alex Morgan, a designer who enjoys building thoughtful digital products and exploring new creative tools. You’re working on a small personal project while developing your skills through reading, practical experiments, and conversations with other makers. You like to break ambitious ideas into manageable steps and keep a clear record of what you have learned. Your long-term goal is to create useful, approachable experiences that help people in everyday life. Outside your work, you enjoy visiting museums, walking in new neighborhoods, planning weekend trips, and finding time for a good book."
        ),
        MemorySummarySection(
            id: "learning", title: "Education And Learning",
            text:
                "You prefer clear, visual explanations with each intermediate step shown. You often ask for examples before moving on to more advanced concepts. Your current learning plan combines design fundamentals, introductory programming, and practical writing exercises. You find it helpful to revisit a topic over several short sessions and summarize what you learned in your own words. Beyond formal classes, you enjoy independent projects that turn an abstract idea into something you can try and improve."
        ),
        MemorySummarySection(
            id: "preferences", title: "Interests And Preferences",
            text:
                "You appreciate simple layouts, readable typography, and a calm visual style. When planning a new project, you like to compare a few concrete options and choose a small first step. You prefer a useful example over a long list of unfamiliar terms."
        )
    ]
}

#if os(iOS)
    import SwiftUI

    struct MemoryDestinationView: View {
        @Bindable var state: ChatState
        @State private var showsAbout = false
        @State private var confirmsDelete = false
        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        state.goBack()
                    } label: {
                        GlassCircle(symbol: "chevron.left")
                    }.accessibilityLabel("Back")
                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        Text("Memory summary").font(.system(size: 17, weight: .semibold))
                        Text(state.memorySummary.updatedLabel).font(.system(size: 13)).foregroundStyle(.secondary)
                    }.accessibilityElement(children: .combine)
                    Spacer(minLength: 0)
                    Menu {
                        Button("About memory", systemImage: "info.circle") { showsAbout = true }
                        Button("Refresh summary", systemImage: "arrow.triangle.2.circlepath") {
                            state.memorySummary.refresh()
                        }.disabled(!state.memorySummary.isEnabled)
                        Button("Delete and turn off memory", systemImage: "trash", role: .destructive) {
                            confirmsDelete = true
                        }
                        .disabled(!state.memorySummary.isEnabled)
                    } label: {
                        GlassCircle(symbol: "ellipsis")
                    }
                    .menuOrder(.fixed).accessibilityLabel("Memory options").accessibilityIdentifier("memory.options")
                }.padding(.horizontal, 16).padding(.top, 2).padding(.bottom, 22)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(state.memorySummary.sections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title).font(.system(size: 17, weight: .semibold)).accessibilityAddTraits(
                                    .isHeader)
                                Text(section.text).font(.system(size: 17)).lineSpacing(5).fixedSize(
                                    horizontal: false, vertical: true)
                            }
                        }
                        if !state.memorySummary.isEnabled {
                            Text("Memory is off").font(.system(size: 17, weight: .semibold))
                            Text("The sample memory summary has been deleted.").font(.system(size: 17)).foregroundStyle(
                                .secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 24)
                }.scrollIndicators(.hidden)
            }
            .accessibilityHidden(showsAbout)
            .buttonStyle(.plain)
            .background(Color.adaptive(dark: 0.13, light: 1).ignoresSafeArea())
            .overlay {
                if showsAbout {
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { showsAbout = false }
                            .accessibilityHidden(true)
                        aboutPanel.padding(.horizontal, 8).padding(.bottom, 8)
                    }.ignoresSafeArea(edges: .bottom)
                }
            }
            .confirmationDialog("Delete sample memory?", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("Delete and turn off", role: .destructive) {
                    state.memorySummary.deleteAndTurnOff()
                    state.referenceMemory = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This only clears the fictional summary in this offline demo.")
            }
        }
        private var aboutPanel: some View {
            VStack(spacing: 8) {
                Text("About memory").font(.system(size: 20, weight: .semibold)).accessibilityAddTraits(.isHeader)
                Text(
                    "ChatGPT automatically remembers important information about you, and keeps it up to date. This summary page is a brief overview of what’s been remembered — not a complete list."
                )
                .font(.system(size: 17)).lineSpacing(2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button {
                        state.onAction(.openDestination("Learn more about memory"))
                        showsAbout = false
                    } label: {
                        Text("Learn more").frame(maxWidth: .infinity).frame(height: 54)
                            .overlay { Capsule().strokeBorder(.primary.opacity(0.1), lineWidth: 1) }
                    }.accessibilityIdentifier("memory.learnMore")
                    Button {
                        showsAbout = false
                    } label: {
                        Text("Got it").foregroundStyle(Color.adaptive(dark: 0, light: 1)).frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.adaptive(dark: 1, light: 0), in: Capsule())
                    }.accessibilityIdentifier("memory.gotIt")
                }.font(.system(size: 17, weight: .medium)).padding(.top, 16)
            }.padding(24).background(Color.adaptive(dark: 0.19, light: 0.96), in: RoundedRectangle(cornerRadius: 36))
                .buttonStyle(.plain).accessibilityElement(children: .contain).accessibilityIdentifier(
                    "memory.aboutPanel")
        }
    }
#endif
