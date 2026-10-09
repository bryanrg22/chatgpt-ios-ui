#if os(iOS)
    import SwiftUI
    struct FeedbackView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var issue = "None"
        @State private var details = ""
        var onSubmit: (String, String) -> Void
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Color.clear.frame(width: 44)
                    Spacer()
                    Text("Feedback").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        GlassCircle(symbol: "xmark")
                    }.accessibilityLabel("Close feedback")
                }.padding(.bottom, 14)
                Text("What could have been better?").font(.system(size: 17, weight: .semibold)).padding(.horizontal, 16)
                    .padding(.bottom, 4)
                Menu {
                    Picker("Issue", selection: $issue) {
                        ForEach(
                            [
                                "Visual quality", "Incorrect or incomplete", "Not what I asked for", "Slow or buggy",
                                "Style or tone", "Safety or legal concern", "Other", "None"
                            ], id: \.self
                        ) { Text($0) }
                    }
                } label: {
                    HStack {
                        Text("Issue")
                        Spacer()
                        Text(issue).foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundStyle(.secondary)
                    }.font(.system(size: 17)).padding(16).background(ChatDesign.raised, in: Capsule())
                }.menuOrder(.fixed)
                VStack(alignment: .trailing) {
                    TextField("Share details (optional)", text: $details, axis: .vertical).lineLimit(6...6).font(
                        .system(size: 17)
                    )
                    .onChange(of: details) { _, value in if value.count > 2000 { details = String(value.prefix(2000)) }
                    }
                    Text("\(details.count) / 2000").font(.system(size: 13)).foregroundStyle(.secondary)
                }.padding(16).background(ChatDesign.raised, in: RoundedRectangle(cornerRadius: 25))
                Text(
                    "This offline demo passes your feedback to its host integration. No conversation is sent to OpenAI."
                ).font(.system(size: 13)).foregroundStyle(.secondary).padding(.horizontal, 16).lineSpacing(3)
                Spacer()
                Button {
                    onSubmit(issue, details)
                } label: {
                    Text("Send").font(.system(size: 17, weight: .semibold)).foregroundStyle(.black).frame(
                        maxWidth: .infinity
                    ).frame(height: 54).background(.white.opacity(0.65), in: Capsule())
                }.padding(.horizontal, 16)
            }.padding(16).padding(.bottom, 12).background(ChatDesign.surface).buttonStyle(.plain)
        }
    }
#endif
