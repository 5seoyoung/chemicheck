import Foundation

// Stage 2: 식품의약품안전처 화학물질독성정보 API 연동
final class FoodDrugAPIService {
    static let shared = FoodDrugAPIService()
    private init() {}

    private let baseURL = "https://apis.data.go.kr/1471000/MdcinGrnIdntfcInfoService01"

    // 화학물질명으로 독성 정보 조회
    func fetchToxicityInfo(chemicalName: String) async throws -> ChemicalToxicityResponse {
        // Stage 2 구현 예정
        throw ServiceError.notImplemented
    }

    // 회수·판매중지 목록 조회
    func fetchRecallList(fromDate: Date) async throws -> [RecallItem] {
        // Stage 2 구현 예정
        throw ServiceError.notImplemented
    }

    struct ChemicalToxicityResponse: Codable {
        let chemicalName: String
        let casNumber: String
        let toxicityClass: String
        let healthEffects: [String]
    }

    struct RecallItem: Codable {
        let productName: String
        let manufacturer: String
        let recallDate: String
        let reason: String
        let agency: String
    }

    enum ServiceError: Error {
        case notImplemented
        case invalidAPIKey
        case networkError(Error)
    }
}
