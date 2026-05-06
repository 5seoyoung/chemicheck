import Foundation

enum ChemicalConcern: String, Codable, CaseIterable {
    case respiratory   = "호흡기 자극"
    case endocrine     = "내분비 교란"
    case carcinogenic  = "발암성 의심"
    case skin          = "피부 자극"
    case neurotoxic    = "신경독성"
    case aquatic       = "수생 독성"
    case allergen      = "알레르기 유발"
}

struct Chemical: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let englishName: String
    let casNumber: String
    let riskLevel: RiskLevel
    let concerns: [ChemicalConcern]
    let effects: [String]
    let infantRisk: Bool
    let pregnantRisk: Bool
    let allergyRisk: Bool
    let petRisk: Bool

    static func == (lhs: Chemical, rhs: Chemical) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
