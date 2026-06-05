import SwiftUI

struct ChatAgentView: View {
    var contextProduct: Product? = nil

    @State private var chatVM = ChatAgentViewModel()
    @State private var scrollProxy: ScrollViewProxy? = nil
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Welcome header
                            if chatVM.messages.isEmpty {
                                welcomeHeader
                                    .padding(.bottom, 8)
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(chatVM.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .padding(.top, 8)
                    }
                    .onAppear { scrollProxy = proxy }
                    .onChange(of: chatVM.messages.count) {
                        if let lastId = chatVM.messages.last?.id {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        }
                    }
                }

                // Quick prompts
                if chatVM.messages.isEmpty {
                    quickPromptsBar
                }

                Divider()

                // Input bar
                inputBar
            }
            .background(Color.bgPrimary)
            .navigationTitle(contextProduct.map { "\($0.name) AI 상담" } ?? "AI 화학물질 상담")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        chatVM.clearHistory()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.brandNavy)
                    }
                }
            }
            .onAppear {
                chatVM.contextProduct = contextProduct
            }
        }
    }

    private var welcomeHeader: some View {
        VStack(spacing: 20) {
            TFIcon.aiAvatar(size: 84)
                .padding(.top, 36)

            VStack(spacing: 5) {
                Text("케미체크 AI 상담사")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("화학제품 안전에 관한 무엇이든 물어보세요")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // 제품 컨텍스트 배너
            if let p = chatVM.contextProduct {
                HStack(spacing: 10) {
                    Image(systemName: p.imageSystemName)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.lavender)
                        .frame(width: 36, height: 36)
                        .background(Color.lavenderSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("현재 제품")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.lavender)
                        Text(p.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(p.riskLevel.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(p.riskLevel.color)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(p.riskLevel.backgroundColor)
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(Color.lavenderSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lavender.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 4)
            }

            HStack(spacing: 6) {
                TFIcon.mfds()
                TFIcon.moe()
                TFIcon.kosha()
            }

            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                Text("AI 답변은 참고용이며 의료 판단은 전문의 상담을 권장해요")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Color.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 24)
    }

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chatVM.quickPrompts) { prompt in
                    Button {
                        Task { await chatVM.send(prompt.text, familyProfile: appState.familyProfile) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 13))
                            Text(prompt.text)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.brandNavy)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.brandNavy.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.brandNavy.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .foregroundStyle(Color.textTertiary)
                    .font(.system(size: 16))

                TextField("화학제품에 대해 물어보세요...", text: $chatVM.inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.separator, lineWidth: 1)
            )

            Button {
                sendMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(chatVM.inputText.isEmpty ? Color.separator : Color.brandNavy)
                        .frame(width: 40, height: 40)
                    Image(systemName: chatVM.isTyping ? "stop.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(chatVM.inputText.isEmpty && !chatVM.isTyping)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bgPrimary)
    }

    private func sendMessage() {
        if chatVM.isTyping {
            chatVM.cancelCurrentRequest()
            return
        }
        let text = chatVM.inputText
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task { await chatVM.send(text, familyProfile: appState.familyProfile) }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                // Avatar
                TFIcon.aiAvatar(size: 32)
                bubbleContent
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                userBubble
            }
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.isTyping {
                TypingIndicator()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey(message.content))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textPrimary)
                        .textSelection(.enabled)
                        .lineSpacing(3)

                    if !message.sources.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 5) {
                            Text("참고 데이터")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                            HStack(spacing: 6) {
                                ForEach(message.sources, id: \.self) { source in
                                    HStack(spacing: 4) {
                                        Image(systemName: "building.columns.fill")
                                            .font(.system(size: 9))
                                        Text(source)
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundStyle(Color.brandNavy)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 7)
                                    .background(Color.bgSecondary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)
            }
        }
    }

    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#304E82"), Color(hex: "#3D6196")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.brandNavy.opacity(0.14), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textTertiary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear {
            phase = 1
        }
    }
}

#Preview {
    ChatAgentView()
        .environment(AppState())
}
