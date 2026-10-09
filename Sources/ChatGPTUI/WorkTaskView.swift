#if os(iOS)
import SwiftUI

public struct WorkTaskView: View {
    @Bindable private var state: WorkTaskPresentationState
    private let onBack: () -> Void
    private let uploadedFilesContent: (() -> AnyView)?
    @FocusState private var composerFocused: Bool
    @State private var showsFiles = false
    public init(state: WorkTaskPresentationState, uploadedFilesContent: (() -> AnyView)? = nil, onBack: @escaping () -> Void) { self.state = state; self.uploadedFilesContent = uploadedFilesContent; self.onBack = onBack }
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(state.messages) { message in
                    if message.role == .user {
                        HStack {
                            Spacer(minLength: 64)
                            Text(message.text).font(.system(size: 17)).lineSpacing(6).padding(16)
                                .foregroundStyle(.white).background(Color(red: 4 / 255, green: 5 / 255, blue: 95 / 255), in: RoundedRectangle(cornerRadius: 24))
                        }
                    } else { Text(message.text).font(.system(size: 17)).lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading) }
                }
                Button { state.toggleActivity() } label: {
                    HStack(spacing: 8) { Text(state.status.rawValue); if state.status != .working { Image(systemName: state.activityExpanded ? "chevron.down" : "chevron.right").font(.system(size: 13, weight: .semibold)) } }
                        .font(.system(size: 17)).foregroundStyle(.secondary).frame(minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("work.status")
                if state.activityExpanded {
                    ForEach(state.traceItems) { item in Text(item.text).font(.system(size: 17)).lineSpacing(6).foregroundStyle(item.isSecondary ? Color.secondary : Color.primary).frame(maxWidth: .infinity, alignment: .leading) }
                }
            }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 24)
        }.scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) { header.padding(.horizontal, 16).padding(.bottom, 8).background(.bar) }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if state.clarificationIsPresented, let question = state.currentQuestion {
                    clarification(question).padding(.horizontal, 12).padding(.bottom, 10)
                } else { composer.padding(.horizontal, 34).padding(.bottom, 8) }
            }
            .background(ChatDesign.canvas.ignoresSafeArea()).buttonStyle(.plain)
            .sheet(isPresented: $showsFiles) { Group { if let uploadedFilesContent { uploadedFilesContent() } else { library } }.presentationDetents([.large]).presentationDragIndicator(.hidden) }
            .onChange(of: state.clarificationIsPresented) { _, presented in if presented { composerFocused = false } }
    }
    private var header: some View {
        HStack {
            Button(action: onBack) { GlassCircle(symbol: "chevron.left") }.accessibilityLabel("Back from Work task")
            Spacer(); Text("Work").font(.system(size: 17, weight: .semibold)); Spacer()
            Menu {
                Section(state.title) {
                    Button("Share", systemImage: "square.and.arrow.up") { state.onAction(.share) }
                    Button("Pin", systemImage: "pin") { state.onAction(.pin) }
                    Button("Add to project", systemImage: "folder") { state.onAction(.addToProject) }
                    Button("Uploaded files", systemImage: "paperclip") { state.onAction(.uploadedFiles); showsFiles = true }
                    Button("Find in chat", systemImage: "magnifyingglass") { state.onAction(.findInChat) }
                    Button("Archive", systemImage: "archivebox") { state.onAction(.archive) }
                    Button("Delete", systemImage: "trash", role: .destructive) { state.onAction(.delete) }
                }
            } label: { GlassCircle(symbol: "ellipsis") }.menuOrder(.fixed).accessibilityLabel("Work task menu").accessibilityIdentifier("work.menu")
        }.frame(height: 44)
    }
    private func clarification(_ question: WorkClarificationQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Button { state.moveQuestion(by: -1) } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).frame(width: 24, height: 32).contentShape(Rectangle()) }.disabled(!state.hasPreviousQuestion).accessibilityLabel("Previous question").accessibilityIdentifier("work.question.previous")
                Text("\(state.questionIndex + 1) of \(state.questions.count)").font(.system(size: 15)).foregroundStyle(.secondary).accessibilityIdentifier("work.question.progress")
                Button { state.moveQuestion(by: 1) } label: { Image(systemName: "chevron.right").font(.system(size: 18, weight: .semibold)).frame(width: 24, height: 32).contentShape(Rectangle()) }.disabled(!state.hasNextQuestion).accessibilityLabel("Next question").accessibilityIdentifier("work.question.next")
                Spacer()
                Button { state.closeClarification() } label: { Image(systemName: "xmark").font(.system(size: 19)).frame(width: 32, height: 32).contentShape(Rectangle()) }.accessibilityLabel("Close questions").accessibilityIdentifier("work.question.close")
            }
            Text(question.title).font(.system(size: 17, weight: .medium)).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("work.question.title")
            VStack(spacing: 0) {
                ForEach(question.options) { option in
                    Button { state.chooseOption(option.id) } label: {
                        Text(option.title).font(.system(size: 17)).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).contentShape(Rectangle())
                    }.accessibilityIdentifier("work.question.option.\(option.id)")
                    Divider()
                }
                HStack(spacing: 8) {
                    TextField("Or describe something else", text: $state.currentAnswerDraft, axis: .vertical)
                        .font(.system(size: 17)).lineLimit(1...3).submitLabel(.send).onSubmit { state.submitAnswerDraft() }.accessibilityIdentifier("work.question.draft")
                    Button { if state.currentAnswerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { state.skipQuestion() } else { state.submitAnswerDraft() } } label: {
                        Text(state.currentAnswerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Skip" : "Send")
                            .font(.system(size: 15, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 6).overlay(Capsule().stroke(.secondary.opacity(0.25), lineWidth: 1))
                    }.accessibilityIdentifier("work.question.submit")
                }.padding(.top, 8).frame(minHeight: 44)
            }
        }.padding(20).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
    }
    private var library: some View {
        ZStack {
            Color(white: 0.115).ignoresSafeArea()
            VStack(spacing: 16) { Image(systemName: "doc.text").font(.system(size: 28)); Text("No files yet").font(.system(size: 17)) }.foregroundStyle(.secondary)
        }.safeAreaInset(edge: .top) {
            HStack { Color.clear.frame(width: 44, height: 44); Spacer(); Text("Library").font(.system(size: 17, weight: .semibold)); Spacer(); Button { showsFiles = false } label: { GlassCircle(symbol: "xmark") }.accessibilityLabel("Close Work library") }.padding(16)
        }
    }
    private var composer: some View {
        HStack(spacing: 12) {
            Button { state.onAction(.attachments) } label: { Image(systemName: "plus").font(.system(size: 24)) }.accessibilityLabel("Work attachments")
            TextField(state.status == .working ? "Follow up" : "Work with ChatGPT", text: $state.followUpDraft, axis: .vertical).font(.system(size: 17)).lineLimit(1...6).focused($composerFocused).accessibilityIdentifier("work.composer")
            Button { state.onAction(.dictation) } label: { Image(systemName: "mic").font(.system(size: 22)) }.accessibilityLabel("Work dictation")
            Button {
                if state.status == .working { state.requestStop() }
                else if state.followUpDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { state.onAction(.voice) }
                else if state.sendFollowUp() { composerFocused = false }
            } label: {
                Group {
                    if state.status == .working { Image(systemName: "stop.fill").font(.system(size: 14)) }
                    else if state.followUpDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { VoiceBars() }
                    else { Image(systemName: "arrow.up").font(.system(size: 19, weight: .semibold)) }
                }.foregroundStyle(.white).frame(width: 34, height: 34).background(ChatDesign.blue, in: Circle())
            }.disabled(state.status == .working && state.stopRequested).accessibilityLabel(state.status == .working ? "Stop Work task" : state.followUpDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Work voice" : "Send Work follow-up").accessibilityIdentifier("work.primary")
        }.padding(.horizontal, 14).padding(.vertical, 7).glassEffect(.regular.interactive(), in: Capsule())
    }
}
#endif
