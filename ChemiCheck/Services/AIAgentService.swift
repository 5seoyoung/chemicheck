import Foundation

// Stage 2: Anthropic Claude API / OpenAI API 연동
final class AIAgentService {
    static let shared = AIAgentService()
    private init() {}

    private let anthropicEndpoint = "https://api.anthropic.com/v1/messages"
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    // Stage 2: 실제 API 호출 구현
    func askClaude(
        question: String,
        product: Product?,
        familyProfile: FamilyProfile
    ) async throws -> String {
        // TODO Stage 2: APIキー를 Config.swift에서 로드
        // let apiKey = Config.anthropicAPIKey

        let systemPrompt = buildSystemPrompt(product: product, familyProfile: familyProfile)
        let _ = systemPrompt // suppress unused warning

        // Placeholder - Stage 2에서 실제 API 호출
        throw APIError.notImplemented
    }

    private func buildSystemPrompt(product: Product?, familyProfile: FamilyProfile) -> String {
        var context = """
        당신은 생활화학제품 안전 전문 AI 상담사입니다.
        식품의약품안전처, 환경부, KEITI의 공식 데이터를 기반으로 답변하세요.
        의료적 판단이 필요한 경우 반드시 전문의 상담을 권장하세요.
        모든 답변에는 출처를 명시하세요.

        사용자 가족 구성원:
        \(familyProfile.memberSummary)
        """

        if let product = product {
            context += """

            현재 조회 중인 제품:
            - 제품명: \(product.name)
            - 브랜드: \(product.brand)
            - 위험도: \(product.riskLevel.rawValue)단계 (\(product.riskLevel.label))
            - 포함 화학물질: \(product.chemicals.map(\.name).joined(separator: ", "))
            """
        }

        return context
    }

    enum APIError: Error {
        case notImplemented
        case networkError(Error)
        case decodingError
        case apiKeyMissing
    }
}

// Stage 2 설정 파일
struct Config {
    // ⚠️ Stage 2에서 실제 API 키 입력 (절대 git에 커밋하지 말 것)
    static let anthropicAPIKey: String = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    static let openAIAPIKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let foodDrugAPIKey: String = ProcessInfo.processInfo.environment["FOOD_DRUG_API_KEY"] ?? ""
    static let airKoreaAPIKey: String = ProcessInfo.processInfo.environment["AIR_KOREA_API_KEY"] ?? ""
}
