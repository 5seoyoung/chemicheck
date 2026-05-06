import Foundation

enum ProductCategory: String, Codable, CaseIterable {
    case bathroom      = "욕실 세정제"
    case laundry       = "세탁 세제"
    case kitchen       = "주방 세정제"
    case airFreshener  = "방향제"
    case disinfectant  = "살균제"
    case insecticide   = "살충제"
    case multipurpose  = "다목적 세정제"
    case bleach        = "표백제"
}

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let category: ProductCategory
    var riskLevel: RiskLevel
    let chemicals: [Chemical]
    let usageGuide: String
    let ventilationMinutes: Int
    let certifications: [String]
    let alternativeIds: [String]
    var isRegistered: Bool
    var isRecalled: Bool
    let recallReason: String?
    let imageSystemName: String
    let scanDate: Date?

    var adjustedRiskLevel: RiskLevel {
        riskLevel
    }
}

struct RecallNotification: Identifiable {
    let id = UUID()
    let product: Product
    let reason: String
    let date: Date
    let severity: RiskLevel
    let refundGuide: String
    let agencyName: String
}
