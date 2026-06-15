import SwiftUI

struct ChatAgentView: View {
    var contextProduct: Product? = nil

    @State private var chatVM = ChatAgentViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if chatVM.messages.isEmpty {
                            welcomeHeader
                                .padding(.bottom, 8)
                        }
                        LazyVStack(spacing: 12) {
                            ForEach(chatVM.messages) { message in
                                MessageBubble(message: message).id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 8)
                }
                .onChange(of: chatVM.messages.count) {
                    if let lastId = chatVM.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    if chatVM.messages.isEmpty {
                        quickPromptsBar
                    }
                    Divider().opacity(0.4)
                    inputBar(vm: Bindable(chatVM))
                }
                .padding(.bottom, 100)
                .background(Color(hex: "#F3FAF5"))
            }
            .background(Color(hex: "#F3FAF5"))
            .navigationTitle(contextProduct.map { "\($0.name) AI 상담" } ?? "AI 안전 상담")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { chatVM.clearHistory() } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.brandNavy)
                    }
                }
            }
            .onAppear { chatVM.contextProduct = contextProduct }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            ZStack {
                Circle()
                    .fill(Color.lavenderSoft)
                    .frame(width: 88, height: 88)
                Image(systemName: "cpu.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.lavender)
            }

            VStack(spacing: 6) {
                Text("AI 화학안전 상담사")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.navyDeep)
                Text("식약처·환경부 데이터 기반으로\n궁금한 것을 무엇이든 물어보세요")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if let p = chatVM.contextProduct {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.lavenderSoft)
                            .frame(width: 36, height: 36)
                        Image(systemName: p.imageSystemName)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.lavender)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("현재 제품 기준 상담")
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
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(p.riskLevel.backgroundColor)
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(Color.lavenderMist)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.lavender.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 4)
            }

            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                Text("AI 답변은 참고용이며 의료적 판단은 전문의 상담을 권장해요")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Color.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Quick Prompts

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chatVM.quickPrompts) { prompt in
                    Button {
                        Task { await chatVM.send(prompt.text, familyProfile: appState.familyProfile) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon).font(.system(size: 12))
                            Text(prompt.text).font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.brandNavy)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.brandNavy.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    // MARK: - Input Bar (@Bindable 파라미터로 전달)

    @ViewBuilder
    private func inputBar(vm: Bindable<ChatAgentViewModel>) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("화학제품에 대해 물어보세요...", text: vm.inputText, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.vertical, 10)
                    .padding(.leading, 14)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.separator, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            Button { sendMessage() } label: {
                ZStack {
                    Circle()
                        .fill(chatVM.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                              ? Color.textTertiary : Color.brandGreen)
                        .frame(width: 42, height: 42)
                        .shadow(color: Color.brandGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                    Image(systemName: chatVM.isTyping ? "stop.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(hex: "#F3FAF5"))
    }

    private func sendMessage() {
        if chatVM.isTyping { chatVM.cancelCurrentRequest(); return }
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
                ZStack {
                    Circle().fill(Color.lavenderSoft).frame(width: 32, height: 32)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14)).foregroundStyle(Color.lavender)
                }
                aiBubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                userBubble
            }
        }
    }

    private var aiBubble: some View {
        Group {
            if message.isTyping {
                TypingIndicator()
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textPrimary)
                        .textSelection(.enabled)
                        .lineSpacing(3)

                    if !message.sources.isEmpty {
                        Divider()
                        HStack(spacing: 6) {
                            ForEach(message.sources, id: \.self) { source in
                                HStack(spacing: 4) {
                                    Image(systemName: "building.columns.fill").font(.system(size: 9))
                                    Text(source).font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(Color.brandNavy)
                                .padding(.vertical, 3).padding(.horizontal, 7)
                                .background(Color.navySoft)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
        }
    }

    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(LinearGradient(
                colors: [Color.brandGreen, Color(hex: "#18865A")],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.brandGreen.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textTertiary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(animating ? 1.3 : 0.9)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.18),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    ChatAgentView().environment(AppState())
}
