import SwiftUI

struct QueryView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var inputText = ""
    @State private var answer = ""
    @FocusState private var focused: Bool
    @State private var placeholderIndex = 0

    private let placeholders = [
        "Try here: time in Tokyo",
        "Try here: days until Christmas",
        "Try here: first Monday in October",
        "Try here: +15 business days from today",
        "Try here: convert 3pm EST to London time",
        "Try here: is 2028 a leap year",
        "Try here: days left in Q3",
        "Try here: how long between Jan 1 and Oct 15",
        "Try here: last Friday of November",
        "Try here: what quarter is it",
        "Try here: how old is someone born June 5 1990",
        "Try here: business days in July",
        "Try here: when does Q4 start",
        "Try here: days left in the year",
    ]

    private var currentPlaceholder: String {
        settings.showRotatingPlaceholder
            ? placeholders[placeholderIndex % placeholders.count]
            : "Ask about time or dates…"
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Answer area
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
                    Button { answer = "" } label: {
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

                ZStack(alignment: .leading) {
                    // Rotating / static placeholder shown when empty and unfocused
                    if inputText.isEmpty && !focused {
                        Text(currentPlaceholder)
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .transition(.opacity)
                            .id(currentPlaceholder)
                    }
                    TextField("", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($focused)
                        .onSubmit { submit() }
                }

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
        .onAppear { startRotation() }
    }

    private func startRotation() {
        guard settings.showRotatingPlaceholder else { return }
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            guard settings.showRotatingPlaceholder else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                placeholderIndex += 1
            }
        }
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
