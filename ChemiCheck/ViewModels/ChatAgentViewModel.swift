import SwiftUI

@Observable
final class ChatAgentViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isTyping: Bool = false
    var currentProduct: Product? = nil

    let quickPrompts: [QuickPrompt] = [
        QuickPrompt(text: "임신 중에 써도 돼?", icon: "person.fill.checkmark"),
        QuickPrompt(text: "아기 옷 빨래에 써도 돼?", icon: "tshirt.fill"),
        QuickPrompt(text: "고양이가 있는데 위험해?", icon: "pawprint.fill"),
        QuickPrompt(text: "이 제품 버릴 때 어떻게 해?", icon: "trash.fill"),
        QuickPrompt(text: "환기는 얼마나 해야 해?", icon: "wind"),
        QuickPrompt(text: "더 안전한 대체품 알려줘", icon: "arrow.triangle.2.circlepath")
    ]

    func send(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        inputText = ""

        isTyping = true
        let typingMsg = ChatMessage(role: .assistant, content: "", isTyping: true)
        messages.append(typingMsg)

        try? await Task.sleep(nanoseconds: 1_500_000_000)

        messages.removeLast()
        let response = generateDummyResponse(for: text)
        messages.append(response)
        isTyping = false
    }

    func clearHistory() {
        messages = []
    }

    // MARK: - Dummy Responses

    private func generateDummyResponse(for question: String) -> ChatMessage {
        let q = question.lowercased()

        if q.contains("임신") || q.contains("임산부") || q.contains("pregnancy") {
            return ChatMessage(
                role: .assistant,
                content: """
                현재 제품에는 **차아염소산나트륨(Sodium Hypochlorite)**이 포함되어 있어 \
                임신 중 사용 시 각별한 주의가 필요합니다.

                **권고 사항:**
                • 가급적 사용을 피하고, 꼭 사용해야 한다면 반드시 고무장갑과 N95 마스크를 착용하세요
                • 사용 중 및 사용 후 최소 30분 이상 창문을 열어 환기하세요
                • 흡입 시 어지러움, 메스꺼움이 느껴지면 즉시 신선한 공기 환경으로 이동하세요

                임신 1·3분기에는 화학물질 노출에 특히 민감하므로 \
                환경표지 인증 제품으로 교체하시는 것을 강력히 권장합니다.
                """,
                sources: ["식품의약품안전처 화학물질독성DB", "환경부 생활화학제품 안전지침 (2024)"]
            )
        }

        if q.contains("아기") || q.contains("영유아") || q.contains("신생아") || q.contains("세탁") {
            return ChatMessage(
                role: .assistant,
                content: """
                영유아(0~36개월) 의류 세탁 시 이 제품은 **주의**가 필요합니다.

                포함된 **계면활성제**와 **방부제 성분**이 아이의 민감한 피부에 \
                잔류할 경우 피부 자극이나 알레르기를 유발할 수 있습니다.

                **추천 대안:**
                • '아이세이프 베이비 세탁 세제' (영유아 안전 인증, 피부과 테스트 완료)
                • '퓨어베이비 세탁 세제' (형광증백제·파라벤·향료 무첨가)

                현재 제품 사용 시에는 세탁 후 **2회 이상 헹굼**을 권장합니다.
                """,
                sources: ["대한소아과학회 생활환경 가이드라인", "식약처 영유아 용품 안전기준 (2023)"]
            )
        }

        if q.contains("고양이") || q.contains("강아지") || q.contains("반려") || q.contains("pet") {
            return ChatMessage(
                role: .assistant,
                content: """
                이 제품은 반려동물, 특히 **고양이**가 있는 가정에서 매우 위험할 수 있습니다.

                **고양이에게 특히 위험한 이유:**
                • 고양이는 간에서 특정 화학물질을 대사하는 효소가 없어 독성 축적
                • 차아염소산나트륨 흡입 시 호흡기 심각한 자극
                • 발바닥 패드로 바닥에 남은 잔류물 흡수 가능

                **안전 수칙:**
                • 사용 시 반려동물을 반드시 다른 방으로 격리하세요
                • 바닥 청소 후 깨끗한 물로 재세척 후 동물 접근 허용
                • 증상(구토, 침 흘림, 호흡 곤란) 발견 시 즉시 동물병원 방문
                """,
                sources: ["한국수의학회 반려동물 독성 가이드", "환경부 생활화학제품 안전지침"]
            )
        }

        if q.contains("버릴") || q.contains("폐기") || q.contains("처리") || q.contains("분리수거") {
            return ChatMessage(
                role: .assistant,
                content: """
                생활화학제품은 **일반 쓰레기로 버리면 안 됩니다.** 올바른 처리 방법을 안내해 드릴게요.

                **올바른 폐기 방법:**

                🔵 **내용물이 남은 경우**
                환경부 지정 폐기물 수거 업체 또는 지자체 폐기물 처리 센터에 문의하세요.
                절대 하수구나 변기에 버리지 마세요 (수질 오염).

                🟢 **용기만 남은 경우**
                내용물을 완전히 비운 후 플라스틱 분리수거 가능합니다.

                📞 **문의:** 환경부 콜센터 1800-0880

                남은 화학제품을 다른 용기에 옮기거나 섞어서 버리는 것은 절대 금지입니다.
                """,
                sources: ["환경부 폐기물 처리 가이드", "한국환경공단 생활폐기물 처리지침"]
            )
        }

        if q.contains("환기") || q.contains("얼마나") {
            return ChatMessage(
                role: .assistant,
                content: """
                이 제품 사용 후 권장 환기 시간은 **최소 30분**입니다.

                **환기 가이드:**
                • 창문 양쪽을 열어 맞통풍을 만들어 주세요
                • 욕실 환풍기도 함께 가동하세요
                • 사용 중에도 마스크·장갑을 착용하세요

                **오늘 현재 외부 미세먼지 농도를 고려할 때:**
                (실제 연동 시 에어코리아 API 기반으로 표시됩니다)

                환기 완료 후 영유아나 반려동물이 해당 공간에 들어올 수 있도록 \
                충분한 시간을 확보하세요.
                """,
                sources: ["환경부 생활화학제품 안전 가이드라인 (2024)"]
            )
        }

        if q.contains("대체") || q.contains("대안") || q.contains("다른 제품") || q.contains("바꿔") {
            return ChatMessage(
                role: .assistant,
                content: """
                이 제품보다 안전한 대체재를 추천해 드릴게요!

                **환경표지 인증 추천 제품:**

                🥇 **에코하우스 욕실 클리너** (위험도 1단계 · 안전)
                → 시트르산+식물성 계면활성제, 환경표지 인증, ₩12,900

                🥈 **베이킹소다 욕실 클리너** (위험도 1단계 · 안전)
                → 100% 천연성분, 영유아 안전 인증, ₩8,900

                🥉 **내추럴클린 스케일 제거제** (위험도 1단계 · 안전)
                → 시트르산 기반, 환경표지 인증, ₩9,500

                세 제품 모두 환경부 환경표지 인증을 받은 안전한 대안입니다.
                영유아·임산부 가정에서도 안심하고 사용할 수 있어요.
                """,
                sources: ["한국환경공단 환경표지 인증 데이터베이스 (2024)", "KEITI 초록누리"]
            )
        }

        // 기본 응답
        return ChatMessage(
            role: .assistant,
            content: """
            안녕하세요! 케미체크 AI 상담사입니다. 🛡️

            현재 제품(\(currentProduct?.name ?? "스캔된 제품"))에 대해 무엇이든 물어보세요.

            **질문 예시:**
            • "이 제품 임신 중에 써도 돼?"
            • "아기 옷 빨래에 쓸 수 있어?"
            • "고양이가 있는데 위험해?"
            • "더 안전한 대체품 알려줘"
            • "환기는 얼마나 해야 해?"

            모든 답변은 식품의약품안전처, 환경부 공식 데이터를 기반으로 제공됩니다.
            의료적 판단이 필요한 경우 전문의 상담을 권장합니다.
            """,
            sources: []
        )
    }
}
