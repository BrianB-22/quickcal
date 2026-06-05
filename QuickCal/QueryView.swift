import SwiftUI

struct QueryView: View {
    @State private var inputText = ""
    @State private var answer = ""
    @State private var isAnswering = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Answer area — only shown when there's something to say
            if !answer.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.tint)
                        .font(.system(size: 13))
                        .padding(.top, 1)
                    Text(answer)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {
                        answer = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Divider()
            }

            // Input row
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("Ask about time or dates…", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($focused)
                    .onSubmit { submit() }

                if !inputText.isEmpty {
                    Button { submit() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.tint)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .animation(.easeInOut(duration: 0.18), value: answer)
        .animation(.easeInOut(duration: 0.12), value: inputText.isEmpty)
    }

    private func submit() {
        let q = inputText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        let result = QueryEngine.answer(q)
        withAnimation {
            answer = result.isEmpty ? "I couldn't figure that one out. Try rephrasing." : result
        }
        inputText = ""
    }
}
