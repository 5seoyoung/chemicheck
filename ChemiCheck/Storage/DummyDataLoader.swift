import Foundation

final class DummyDataLoader {
    static let shared = DummyDataLoader()
    private init() {}

    private(set) var chemicals: [Chemical] = []
    private(set) var alternatives: [Alternative] = []
    private(set) var products: [Product] = []

    func loadAll() {
        chemicals = loadChemicals()
        alternatives = loadAlternatives()
        products = loadProducts()
    }

    func alternative(for id: String) -> Alternative? {
        alternatives.first { $0.id == id }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Private

    private func loadChemicals() -> [Chemical] {
        guard let url = Bundle.main.url(forResource: "chemicals", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return hardcodedChemicals() }
        let raw = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        return raw.compactMap(parseChemical)
    }

    private func loadAlternatives() -> [Alternative] {
        guard let url = Bundle.main.url(forResource: "alternatives", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        let raw = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        return raw.compactMap(parseAlternative)
    }

    private func loadProducts() -> [Product] {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        let raw = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        return raw.compactMap(parseProduct)
    }

    private func parseChemical(_ dict: [String: Any]) -> Chemical? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let englishName = dict["englishName"] as? String,
              let casNumber = dict["casNumber"] as? String,
              let riskInt = dict["riskLevel"] as? Int,
              let riskLevel = RiskLevel(rawValue: riskInt) else { return nil }

        let concernStrings = dict["concerns"] as? [String] ?? []
        let concerns = concernStrings.compactMap { ChemicalConcern(rawValue: $0) }
        let effects = dict["effects"] as? [String] ?? []

        return Chemical(
            id: id,
            name: name,
            englishName: englishName,
            casNumber: casNumber,
            riskLevel: riskLevel,
            concerns: concerns,
            effects: effects,
            infantRisk: dict["infantRisk"] as? Bool ?? false,
            pregnantRisk: dict["pregnantRisk"] as? Bool ?? false,
            allergyRisk: dict["allergyRisk"] as? Bool ?? false,
            petRisk: dict["petRisk"] as? Bool ?? false
        )
    }

    private func parseAlternative(_ dict: [String: Any]) -> Alternative? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let brand = dict["brand"] as? String,
              let riskInt = dict["riskLevel"] as? Int,
              let riskLevel = RiskLevel(rawValue: riskInt) else { return nil }

        let certStrings = dict["certifications"] as? [String] ?? []
        let certs = certStrings.compactMap { CertificationType(rawValue: $0) }

        return Alternative(
            id: id,
            name: name,
            brand: brand,
            riskLevel: riskLevel,
            certifications: certs,
            price: dict["price"] as? String ?? "",
            availableAt: dict["availableAt"] as? [String] ?? [],
            description: dict["description"] as? String ?? "",
            category: dict["category"] as? String ?? "",
            imageSystemName: dict["imageSystemName"] as? String ?? "leaf.fill"
        )
    }

    private func parseProduct(_ dict: [String: Any]) -> Product? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let brand = dict["brand"] as? String,
              let categoryStr = dict["category"] as? String,
              let riskInt = dict["riskLevel"] as? Int,
              let riskLevel = RiskLevel(rawValue: riskInt) else { return nil }

        let category = ProductCategory(rawValue: categoryStr) ?? .multipurpose
        let chemIds = dict["chemicalIds"] as? [String] ?? []
        let chems = chemIds.compactMap { cid in chemicals.first { $0.id == cid } }
        let altIds = dict["alternativeIds"] as? [String] ?? []

        return Product(
            id: id,
            name: name,
            brand: brand,
            category: category,
            riskLevel: riskLevel,
            chemicals: chems,
            usageGuide: dict["usageGuide"] as? String ?? "",
            ventilationMinutes: dict["ventilationMinutes"] as? Int ?? 0,
            certifications: dict["certifications"] as? [String] ?? [],
            alternativeIds: altIds,
            isRegistered: dict["isRegistered"] as? Bool ?? false,
            isRecalled: dict["isRecalled"] as? Bool ?? false,
            recallReason: dict["recallReason"] as? String,
            imageSystemName: dict["imageSystemName"] as? String ?? "shippingbox.fill",
            scanDate: nil
        )
    }

    private func hardcodedChemicals() -> [Chemical] {
        [
            Chemical(id: "chem_001", name: "차아염소산나트륨", englishName: "Sodium Hypochlorite",
                     casNumber: "7681-52-9", riskLevel: .high,
                     concerns: [.respiratory, .skin, .aquatic],
                     effects: ["호흡기 점막 자극", "눈·피부 심한 자극"],
                     infantRisk: true, pregnantRisk: true, allergyRisk: true, petRisk: true),
            Chemical(id: "chem_008", name: "식물성 계면활성제", englishName: "Plant-based Surfactant",
                     casNumber: "N/A", riskLevel: .safe,
                     concerns: [],
                     effects: ["천연 원료 유래", "생분해 가능"],
                     infantRisk: false, pregnantRisk: false, allergyRisk: false, petRisk: false)
        ]
    }
}
