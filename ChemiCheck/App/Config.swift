import Foundation

// MARK: - Config
// API 키 로드 우선순위:
//   1. Xcode Scheme 환경변수 (로컬 Debug 빌드, 개발 중 override용)
//   2. Info.plist 번들 값 (TestFlight·App Store 배포 빌드, project.yml Build Settings에서 주입)
// API 키는 절대 소스 코드에 직접 하드코딩하지 마세요.

struct Config {
    // Claude API 프록시 서버 URL (Cloudflare Workers)
    static let proxyBaseURL: String =
        ProcessInfo.processInfo.environment["PROXY_BASE_URL"]
        ?? Bundle.main.infoDictionary?["ChemiCheckProxyURL"] as? String
        ?? ""

    // 에어코리아 공공데이터 API 키
    static let airKoreaAPIKey: String =
        ProcessInfo.processInfo.environment["AIR_KOREA_API_KEY"]
        ?? Bundle.main.infoDictionary?["ChemiCheckAirKoreaKey"] as? String
        ?? ""

    // (미사용 예비) 식약처 API 키
    static let foodDrugAPIKey: String =
        ProcessInfo.processInfo.environment["FOOD_DRUG_API_KEY"] ?? ""
}
