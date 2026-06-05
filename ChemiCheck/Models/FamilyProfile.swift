import Foundation

enum PetType: String, Codable, CaseIterable {
    case dog   = "강아지"
    case cat   = "고양이"
    case bird  = "조류"
    case other = "기타"
}

struct FamilyProfile: Codable {
    var hasInfant: Bool = false
    var infantAges: [Int] = []
    var hasPregnant: Bool = false
    var hasAllergyMember: Bool = false
    var allergyTypes: [String] = []
    var hasElderly: Bool = false
    var hasPet: Bool = false
    var petTypes: [PetType] = []

    var riskModifier: Int {
        var mod = 0
        if hasInfant      { mod += 1 }
        if hasPregnant    { mod += 1 }
        if hasAllergyMember { mod += 1 }
        if hasElderly     { mod += 1 }
        return mod
    }

    var memberSummary: String {
        var parts: [String] = []
        if hasInfant {
            let ages = infantAges.map { $0 == 0 ? "신생아" : "\($0)세" }.joined(separator: ", ")
            parts.append("영유아(\(ages))")
        }
        if hasPregnant    { parts.append("임산부") }
        if hasAllergyMember { parts.append("알레르기/아토피") }
        if hasElderly     { parts.append("노약자") }
        if hasPet {
            let pets = petTypes.map(\.rawValue).joined(separator: ", ")
            parts.append("반려동물(\(pets))")
        }
        return parts.isEmpty ? "가족 정보 없음" : parts.joined(separator: " · ")
    }

    var vulnerableGroups: [String] {
        var groups: [String] = []
        if hasInfant        { groups.append("영유아") }
        if hasPregnant      { groups.append("임산부") }
        if hasAllergyMember { groups.append("알레르기 보유자") }
        if hasElderly       { groups.append("노약자") }
        if hasPet           { groups.append("반려동물") }
        return groups
    }
}
