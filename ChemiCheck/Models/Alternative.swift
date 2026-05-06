import Foundation

enum CertificationType: String, Codable, CaseIterable {
    case ecoLabel           = "환경표지 인증"
    case naturalIngredients = "천연성분"
    case allIngredients     = "전성분 공개"
    case dermatologistTested = "피부과 테스트 완료"
    case babyFriendly       = "영유아 안전 인증"
    case organic            = "유기농 인증"
}

struct Alternative: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let riskLevel: RiskLevel
    let certifications: [CertificationType]
    let price: String
    let availableAt: [String]
    let description: String
    let category: String
    let imageSystemName: String
}
