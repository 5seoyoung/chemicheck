import Foundation

final class RiskCalculator {
    func calculate(product: Product, profile: FamilyProfile) -> RiskLevel {
        var level = product.riskLevel.rawValue

        // Infant + respiratory chemicals → +1
        if profile.hasInfant {
            let hasRespiratory = product.chemicals.contains { chem in
                chem.concerns.contains(.respiratory) && chem.infantRisk
            }
            if hasRespiratory { level = min(level + 1, 5) }
        }

        // Pregnant + endocrine disruptors → +1
        if profile.hasPregnant {
            let hasEndocrine = product.chemicals.contains { chem in
                chem.concerns.contains(.endocrine) && chem.pregnantRisk
            }
            if hasEndocrine { level = min(level + 1, 5) }
        }

        // Allergy + allergen chemicals → +1
        if profile.hasAllergyMember {
            let hasAllergen = product.chemicals.contains { chem in
                chem.concerns.contains(.allergen) && chem.allergyRisk
            }
            if hasAllergen { level = min(level + 1, 5) }
        }

        // Pet (especially cat) + neurotoxic/aquatic chemicals → +1
        if profile.hasPet {
            let hasPetRisk = product.chemicals.contains { chem in
                chem.petRisk && (chem.concerns.contains(.neurotoxic) || chem.concerns.contains(.aquatic))
            }
            if hasPetRisk { level = min(level + 1, 5) }
        }

        // Elderly (senior) → +1 for respiratory or neurotoxic chemicals
        if profile.hasElderly {
            let hasElderlyRisk = product.chemicals.contains { chem in
                (chem.infantRisk || chem.concerns.contains(.respiratory)) && chem.riskLevel.rawValue >= 3
            }
            if hasElderlyRisk { level = min(level + 1, 5) }
        }

        return RiskLevel(rawValue: level) ?? product.riskLevel
    }

    func warnings(product: Product, profile: FamilyProfile) -> [String] {
        var warnings: [String] = []

        if profile.hasInfant {
            let chemicals = product.chemicals.filter { $0.infantRisk }
            if !chemicals.isEmpty {
                warnings.append("영유아 위험 — \(chemicals.map(\.name).joined(separator: ", "))이(가) 영유아에게 위험할 수 있어요")
            }
        }

        if profile.hasPregnant {
            let chemicals = product.chemicals.filter { $0.pregnantRisk }
            if !chemicals.isEmpty {
                warnings.append("임산부 주의 — \(chemicals.map(\.name).joined(separator: ", ")) 포함. 환경부 지정 주의 성분이에요")
            }
        }

        if profile.hasAllergyMember {
            let chemicals = product.chemicals.filter { $0.allergyRisk }
            if !chemicals.isEmpty {
                warnings.append("알레르기 유발 가능 — \(chemicals.map(\.name).joined(separator: ", "))이(가) 알레르기를 유발할 수 있어요")
            }
        }

        if profile.hasElderly {
            let chemicals = product.chemicals.filter { $0.concerns.contains(.respiratory) && $0.riskLevel.rawValue >= 3 }
            if !chemicals.isEmpty {
                warnings.append("노약자 주의 — \(chemicals.map(\.name).joined(separator: ", ")) 호흡기 자극 가능. 충분한 환기 필요해요")
            }
        }

        if profile.hasPet {
            let chemicals = product.chemicals.filter { $0.petRisk }
            if !chemicals.isEmpty {
                warnings.append("반려동물 위험 — \(chemicals.map(\.name).joined(separator: ", ")) 노출 주의. 사용 시 격리 필요해요")
            }
        }

        return warnings
    }
}
