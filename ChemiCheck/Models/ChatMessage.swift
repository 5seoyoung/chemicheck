import Foundation

enum ChatRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp: Date
    var sources: [String]
    var isTyping: Bool

    init(role: ChatRole, content: String, sources: [String] = [], isTyping: Bool = false) {
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.sources = sources
        self.isTyping = isTyping
    }
}

struct QuickPrompt: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}
