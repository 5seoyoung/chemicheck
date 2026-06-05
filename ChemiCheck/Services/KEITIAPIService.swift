import Foundation

final class KEITIAPIService {
    static let shared = KEITIAPIService()
    private init() {}

    // 환경표지 인증제품 조회 — 현재 로컬 alternatives 데이터로 커버
    // REST API 연동 시 여기에 구현
    func fetchEcoLabelProducts(category: String) async -> [EcoLabelProduct] {
        return []
    }

    // 안전확인대상 생활화학제품 신고증명서 조회 — 현재 로컬 캐시로 커버
    func fetchSafetyConfirmation(productName: String) async -> SafetyConfirmation? {
        return nil
    }

    struct EcoLabelProduct: Codable {
        let name: String
        let brand: String
        let certNumber: String
        let category: String
        let validUntil: String
    }

    struct SafetyConfirmation: Codable {
        let productName: String
        let manufacturer: String
        let confirmNumber: String
        let approvalDate: String
        let chemicals: [String]
    }

    enum ServiceError: Error {
        case networkError(Error)
    }
}
