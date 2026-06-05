import Foundation

// MARK: - AIAgentService
// Claude API는 앱에 직접 키를 넣지 않음.
// 프록시 서버(Cloudflare Workers / Vercel Functions)를 통해 호출.
// Config.proxyBaseURL 에 배포한 프록시 URL을 설정해두면 즉시 동작.

final class AIAgentService {
    static let shared = AIAgentService()
    private init() { loadFallbackCache() }

    private var fallbackCache: [FallbackEntry] = []

    // MARK: - 메인 호출

    func ask(question: String, product: Product?, familyProfile: FamilyProfile) async -> ChatResult {
        // 데모 모드: 사전 캐시 응답
        if DemoModeManager.shared.isOn {
            return cached(for: question) ?? .fallback(question)
        }

        // 프록시 URL 없으면 바로 캐시 폴백
        guard !Config.proxyBaseURL.isEmpty,
              let url = URL(string: Config.proxyBaseURL + "/api/chat") else {
            return cached(for: question) ?? .fallback(question)
        }

        let systemPrompt = buildSystemPrompt(product: product, familyProfile: familyProfile)
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 600,
            "system": systemPrompt,
            "messages": [["role": "user", "content": question]]
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return cached(for: question) ?? .fallback(question)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String ?? ""
            let sources = extractSources(from: content)

            return ChatResult(content: content, sources: sources)
        } catch {
            return cached(for: question) ?? .fallback(question)
        }
    }

    // MARK: - 시스템 프롬프트

    private func buildSystemPrompt(product: Product?, familyProfile: FamilyProfile) -> String {
        var prompt = """
        당신은 생활화학제품 안전 전문 AI 상담사입니다.
        식품의약품안전처, 환경부, 안전보건공단의 공식 데이터를 기반으로 답변하세요.
        의료적 판단이 필요한 경우 반드시 전문의·약사 상담을 권유하세요.
        모든 답변 마지막에 [출처: 기관명] 형식으로 출처를 명시하세요.
        답변은 200자 이내로 간결하게 작성하세요.
        근거 없는 단정적 표현은 사용하지 마세요.

        사용자 가족 구성원: \(familyProfile.memberSummary)
        """
        if let p = product {
            prompt += """

            현재 진단 제품:
            - 제품명: \(p.name) (\(p.brand))
            - 위험도: \(p.riskLevel.rawValue)단계 (\(p.riskLevel.label))
            - 포함 성분: \(p.chemicals.map(\.name).joined(separator: ", "))
            """
        }
        return prompt
    }

    private func extractSources(from text: String) -> [String] {
        let patterns = ["식약처", "식품의약품안전처", "환경부", "안전보건공단", "KEITI"]
        return patterns.filter { text.contains($0) }
    }

    // MARK: - 폴백 캐시

    private func cached(for question: String) -> ChatResult? {
        let q = question.lowercased()
        return fallbackCache.first { entry in
            entry.keywords.contains { q.contains($0) }
        }.map { ChatResult(content: $0.answer, sources: $0.sources) }
    }

    private func loadFallbackCache() {
        fallbackCache = [
            FallbackEntry(
                keywords: ["임신", "임산부", "pregnancy"],
                answer: """
                현재 제품에 포함된 차아염소산나트륨은 임신 중 흡입·피부 노출 시 주의가 필요합니다.
                사용 시 반드시 고무장갑·N95 마스크를 착용하고 30분 이상 환기하세요.
                임신 1·3분기에는 환경표지 인증 제품으로 교체를 권장합니다. [출처: 식품의약품안전처]
                """,
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["아기", "영유아", "신생아", "세탁"],
                answer: """
                영유아 의류 세탁 시 이 제품은 계면활성제·방부제 잔류 위험이 있어 주의가 필요합니다.
                세탁 후 2회 이상 헹굼을 권장하며, 아이세이프·퓨어베이비 인증 제품으로 교체를 추천합니다.
                [출처: 대한소아과학회, 식품의약품안전처]
                """,
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["고양이", "강아지", "반려동물", "펫"],
                answer: """
                반려동물, 특히 고양이는 사람보다 화학물질 민감성이 높습니다.
                사용 중 반드시 격리하고 환기 후 접근을 허용하세요.
                차아염소산나트륨은 고양이 간 독성이 보고된 바 있으니 잔류 없이 헹궈내세요. [출처: 환경부]
                """,
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["환기", "얼마", "시간", "ventilation"],
                answer: """
                이 제품의 권장 환기 시간은 최소 20~30분입니다.
                현재 대기질에 따라 조정하세요: PM2.5 좋음 → 15분, 보통 → 30분, 나쁨 → 환기팬 사용.
                환기 후 잔류 냄새가 나면 추가 환기하세요. [출처: 환경부 생활화학제품 안전지침]
                """,
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["버리", "폐기", "disposal", "처리"],
                answer: """
                화학제품은 하수구에 버리지 마세요. 소량은 물로 희석 후 배출, 대용량은 지자체 유해폐기물 수거함을 이용하세요.
                빈 용기는 내용물을 비운 뒤 일반 재활용 분리배출합니다. [출처: 환경부 폐기물 처리 지침]
                """,
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["대체", "alternative", "다른 제품", "안전한"],
                answer: """
                더 안전한 대체재로는 환경표지 인증 제품(KEITI 초록누리 검색)을 추천합니다.
                차아염소산수(HOCl) 기반 살균제나 구연산·베이킹소다 조합 세정제가 저독성 대안입니다. [출처: KEITI 환경표지]
                """,
                sources: ["KEITI"]
            ),
            FallbackEntry(
                keywords: ["알레르기", "아토피", "allergy"],
                answer: """
                알레르기·아토피 보유자는 향료, 파라벤, 계면활성제에 민감할 수 있습니다.
                무향·무착색·저자극 인증 제품을 선택하고, 처음 사용 시 소량 피부 테스트를 권장합니다. [출처: 식품의약품안전처]
                """,
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["피부", "눈", "접촉", "닿았", "contact"],
                answer: """
                피부에 닿은 경우: 즉시 흐르는 물로 15분 이상 세척하세요.
                눈에 들어간 경우: 즉시 흐르는 물로 15분 이상 세척 후 안과 방문을 권장합니다.
                증상이 지속되면 응급실을 방문하세요. [출처: 안전보건공단]
                """,
                sources: ["안전보건공단"]
            ),
            FallbackEntry(
                keywords: ["흡입", "냄새", "어지", "머리", "inhale"],
                answer: """
                흡입 후 두통·어지러움이 있다면 즉시 신선한 공기 환경으로 이동하세요.
                증상이 지속되면 중독 정보 센터(1339)에 문의하거나 응급실을 방문하세요. [출처: 안전보건공단]
                """,
                sources: ["안전보건공단"]
            ),
            FallbackEntry(
                keywords: ["섞", "혼합", "같이", "락스", "mix"],
                answer: """
                락스(차아염소산나트륨)와 산성 세제를 혼합하면 염소 가스가 발생해 매우 위험합니다.
                절대 혼합하지 마세요. 다른 제품 사용 후 충분히 헹구고 다른 세제를 사용하세요. [출처: 식품의약품안전처]
                """,
                sources: ["식품의약품안전처"]
            )
        ]
    }
}

// MARK: - Supporting Types

struct ChatResult {
    let content: String
    let sources: [String]

    static func fallback(_ question: String) -> ChatResult {
        ChatResult(
            content: "죄송합니다. 현재 AI 상담 서버에 연결할 수 없습니다. 식약처(1577-1255) 또는 중독정보센터(1339)에 문의해 주세요.",
            sources: []
        )
    }
}

private struct FallbackEntry {
    let keywords: [String]
    let answer: String
    let sources: [String]
}
