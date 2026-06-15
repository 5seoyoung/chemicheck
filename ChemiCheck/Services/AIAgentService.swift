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
        // 데모 모드: 사전 캐시 응답 (제품 컨텍스트 반영)
        if DemoModeManager.shared.isOn {
            return cached(for: question, product: product) ?? .fallback(question, product: product)
        }

        // 프록시 URL 없으면 바로 캐시 폴백
        guard !Config.proxyBaseURL.isEmpty,
              let url = URL(string: Config.proxyBaseURL + "/api/chat") else {
            return cached(for: question, product: product) ?? .fallback(question, product: product)
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
                return cached(for: question, product: product) ?? .fallback(question, product: product)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String ?? ""
            let sources = extractSources(from: content)

            return ChatResult(content: content, sources: sources)
        } catch {
            return cached(for: question, product: product) ?? .fallback(question, product: product)
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

    private func cached(for question: String, product: Product?) -> ChatResult? {
        let q = question.lowercased()
        guard let entry = fallbackCache.first(where: { entry in
            entry.keywords.contains { q.contains($0) }
        }) else { return nil }
        return ChatResult(content: productAwareContent(entry.answer, product: product), sources: entry.sources)
    }

    private func productAwareContent(_ base: String, product: Product?) -> String {
        guard let p = product else { return base }
        let chemicals = p.chemicals.prefix(3).map(\.name).joined(separator: "·")
        let header = "【\(p.name) | \(p.riskLevel.label)】\n주요 성분: \(chemicals)\n\n"
        return header + base
    }

    private func loadFallbackCache() {
        fallbackCache = [
            FallbackEntry(
                keywords: ["임신", "임산부", "pregnancy"],
                answer: "임신 중 생활화학제품 사용 시 각별한 주의가 필요합니다. 사용 전 라벨 성분을 확인하고, 반드시 고무장갑·마스크를 착용하세요. 사용 후 최소 30분 이상 충분히 환기하고, 임신 1·3분기에는 환경표지 인증 제품으로 교체를 권장합니다. [출처: 식품의약품안전처]",
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["아기", "영유아", "신생아", "세탁", "빨래"],
                answer: "영유아 의류 세탁 시 강한 계면활성제·형광증백제 성분이 포함된 제품은 피하세요. 아이세이프·퓨어베이비 인증 제품을 사용하고, 세탁 후 2회 이상 헹굼을 권장합니다. 잔류 화학성분이 아이 피부에 닿지 않도록 충분히 헹궈주세요. [출처: 대한소아과학회, 식품의약품안전처]",
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["고양이", "강아지", "반려동물", "펫"],
                answer: "반려동물, 특히 고양이는 사람보다 화학물질에 훨씬 민감합니다. 제품 사용 중에는 반드시 격리하고, 환기가 충분히 된 후(최소 30분) 접근을 허용하세요. 락스 등 염소 계열 성분은 고양이 간 독성이 보고되어 있으니 사용 후 잔류 없이 완전히 헹궈내세요. [출처: 환경부]",
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["환기", "얼마", "시간", "ventilation"],
                answer: "생활화학제품 사용 후 권장 환기 시간은 최소 20~30분입니다. 대기질에 따라 조정하세요: PM2.5 좋음 → 15분, 보통 → 30분, 나쁨 → 환기팬 사용 후 창문 열기. 환기 후에도 잔류 냄새가 남으면 추가 환기를 하세요. [출처: 환경부 생활화학제품 안전지침]",
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["버리", "폐기", "disposal", "처리"],
                answer: "화학제품은 하수구에 그냥 버리지 마세요. 소량은 물로 충분히 희석 후 배출하고, 대용량이나 위험성분은 지자체 유해폐기물 수거함을 이용하세요. 빈 용기는 내용물을 완전히 비운 뒤 일반 재활용 분리배출합니다. [출처: 환경부 폐기물 처리 지침]",
                sources: ["환경부"]
            ),
            FallbackEntry(
                keywords: ["대체", "alternative", "다른 제품", "안전한", "대체품"],
                answer: "더 안전한 대체재로는 환경표지 인증 제품(KEITI 초록누리에서 검색)을 추천합니다. 살균·소독엔 차아염소산수(HOCl) 기반 제품이, 세정엔 구연산·베이킹소다 조합이 저독성 대안입니다. 라벨에서 환경표지(에코마크) 마크를 확인하세요. [출처: KEITI 환경표지]",
                sources: ["KEITI"]
            ),
            FallbackEntry(
                keywords: ["알레르기", "아토피", "allergy"],
                answer: "알레르기·아토피가 있는 경우 향료, 파라벤, 계면활성제 성분에 민감하게 반응할 수 있습니다. 무향·무착색·저자극 인증 제품을 선택하고, 처음 사용 시 소량으로 피부 반응 테스트를 먼저 해보세요. [출처: 식품의약품안전처]",
                sources: ["식품의약품안전처"]
            ),
            FallbackEntry(
                keywords: ["피부", "눈", "접촉", "닿았", "contact"],
                answer: "피부에 닿은 경우 즉시 흐르는 물로 15분 이상 세척하세요. 눈에 들어간 경우에도 즉시 흐르는 물로 15분 이상 세척한 뒤 안과 방문을 권장합니다. 증상이 지속되거나 심하면 응급실을 방문하세요. [출처: 안전보건공단]",
                sources: ["안전보건공단"]
            ),
            FallbackEntry(
                keywords: ["흡입", "냄새", "어지", "머리", "inhale"],
                answer: "화학제품 흡입 후 두통·어지러움이 있다면 즉시 신선한 공기가 있는 곳으로 이동하세요. 증상이 지속되면 중독정보센터(☎1339)에 문의하거나 응급실을 방문하세요. 심한 경우 119에 신고하세요. [출처: 안전보건공단]",
                sources: ["안전보건공단"]
            ),
            FallbackEntry(
                keywords: ["섞", "혼합", "같이", "락스", "mix"],
                answer: "락스(차아염소산나트륨)와 산성 세제를 혼합하면 독성 염소 가스가 발생해 매우 위험합니다. 절대 다른 세제와 혼합하지 마세요. 다른 제품을 순서대로 사용할 경우 중간에 충분히 헹구고 나서 다음 제품을 사용하세요. [출처: 식품의약품안전처]",
                sources: ["식품의약품안전처"]
            )
        ]
    }
}

// MARK: - Supporting Types

struct ChatResult {
    let content: String
    let sources: [String]

    static func fallback(_ question: String, product: Product? = nil) -> ChatResult {
        let q = question.lowercased()
        let header = product.map { p -> String in
            let chemicals = p.chemicals.prefix(3).map(\.name).joined(separator: "·")
            return "【\(p.name) | \(p.riskLevel.label)】\n주요 성분: \(chemicals)\n\n"
        } ?? ""

        if q.contains("안녕") || q.contains("안녕하세요") || q.contains("hello") {
            return ChatResult(content: header + "안녕하세요! 저는 케미체크 AI 안전 상담사예요. 생활화학제품에 대한 궁금한 점을 무엇이든 물어보세요. 성분 위험성, 사용 주의사항, 대체재 추천 등을 도와드릴 수 있어요. [출처: 식품의약품안전처]", sources: ["식품의약품안전처"])
        }
        let body = product != nil
            ? "이 제품 사용 시 가장 중요한 것은 ① 라벨의 성분·주의사항 숙지, ② 사용 중 충분한 환기(최소 20분), ③ 피부·눈 접촉 즉시 세척입니다. 임신·영유아·반려동물이 있다면 위험도 등급을 반드시 확인하세요. 응급 상황 시 중독정보센터(☎1339)에 문의하세요. [출처: 식품의약품안전처, 환경부]"
            : "생활화학제품 사용 시 가장 중요한 것은 ① 사용 전 라벨 성분 확인, ② 사용 중 충분한 환기(최소 20분), ③ 피부·눈 접촉 주의입니다. 더 구체적인 성분·제품명을 알려주시면 맞춤 안내를 드릴 수 있어요. 응급 상황 시 중독정보센터(☎1339)에 문의하세요. [출처: 식품의약품안전처, 환경부]"
        return ChatResult(content: header + body, sources: ["식품의약품안전처", "환경부"])
    }
}

private struct FallbackEntry {
    let keywords: [String]
    let answer: String
    let sources: [String]
}
