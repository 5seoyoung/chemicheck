import Foundation

// MARK: - Config
// API 키는 절대 git에 커밋하지 마세요.
// 환경변수 또는 .env 파일(.gitignore)로 관리하세요.

struct Config {
    // Claude API 프록시 서버 URL (Cloudflare Workers / Vercel Functions)
    // 배포 후 아래에 입력: 예) "https://chemicheck-proxy.your-account.workers.dev"
    static let proxyBaseURL: String =
        ProcessInfo.processInfo.environment["PROXY_BASE_URL"] ?? ""

    // 에어코리아 공공데이터 API 키
    // https://www.data.go.kr → 한국환경공단_에어코리아_대기오염정보 → 인증키 발급
    static let airKoreaAPIKey: String =
        ProcessInfo.processInfo.environment["AIR_KOREA_API_KEY"] ?? ""

    // (미사용 예비) 식약처 API 키
    static let foodDrugAPIKey: String =
        ProcessInfo.processInfo.environment["FOOD_DRUG_API_KEY"] ?? ""
}
