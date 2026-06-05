import SwiftUI

@Observable
final class ChatAgentViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isTyping: Bool = false
    var contextProduct: Product?
    private var currentTask: Task<Void, Never>?

    let quickPrompts: [QuickPrompt] = [
        QuickPrompt(text: "임신 중에 써도 돼?", icon: "person.fill.checkmark"),
        QuickPrompt(text: "아기 옷 빨래에 써도 돼?", icon: "tshirt.fill"),
        QuickPrompt(text: "고양이가 있는데 위험해?", icon: "pawprint.fill"),
        QuickPrompt(text: "이 제품 버릴 때 어떻게 해?", icon: "trash.fill"),
        QuickPrompt(text: "환기는 얼마나 해야 해?", icon: "wind"),
        QuickPrompt(text: "더 안전한 대체품 알려줘", icon: "arrow.triangle.2.circlepath")
    ]

    func send(_ text: String, familyProfile: FamilyProfile = FamilyProfile()) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !isTyping else { cancelCurrentRequest(); return }

        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        inputText = ""
        isTyping = true
        messages.append(ChatMessage(role: .assistant, content: "", isTyping: true))

        currentTask = Task {
            let result = await AIAgentService.shared.ask(
                question: text,
                product: contextProduct,
                familyProfile: familyProfile
            )
            guard !Task.isCancelled else { return }
            messages.removeLast()
            messages.append(ChatMessage(role: .assistant, content: result.content, sources: result.sources))
            isTyping = false
        }
        await currentTask?.value
    }

    func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
        if messages.last?.isTyping == true { messages.removeLast() }
        isTyping = false
    }

    func clearHistory() {
        cancelCurrentRequest()
        messages = []
    }
}
