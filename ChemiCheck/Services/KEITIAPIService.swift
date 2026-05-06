import Foundation

// Stage 2: 환경부 KEITI 초록누리 데이터 연동
final class KEITIAPIService {
    static let shared = KEITIAPIService()
    private init() {}

    // 환경표지 인증제품 조회
    func fetchEcoLabelProducts(category: String) async throws -> [EcoLabelProduct] {
        // Stage 2 구현 예정
        throw ServiceError.notImplemented
    }

    // 안전확인대상 생활화학제품 신고증명서 조회
    func fetchSafetyConfirmation(productName: String) async throws -> SafetyConfirmation? {
        // Stage 2 구현 예정
        throw ServiceError.notImplemented
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
        case notImplemented
        case networkError(Error)
    }
}
