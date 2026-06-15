import Foundation

final class FoodDrugAPIService {
    static let shared = FoodDrugAPIService()
    private init() { loadCache() }

    private var cache: [CacheEntry] = []

    // MARK: - Public API

    /// OCR로 추출한 화학물질명 배열 → Chemical 배열 반환 (캐시 우선, 캐시 미스 시 폴백)
    func matchChemicals(from names: [String]) async -> [Chemical] {
        var results: [Chemical] = []
        var unmatchedNames: [String] = []

        for name in names {
            if let entry = findInCache(name) {
                results.append(entry.toChemical())
            } else {
                unmatchedNames.append(name)
            }
        }

        // 캐시 미스 처리: 1) chemicals.json 큐레이션 → 2) LocalDB 7,189건 순으로 조회
        for name in unmatchedNames {
            // 1차: 큐레이션 chemicals.json
            if let chem = DummyDataLoader.shared.chemicals.first(where: {
                $0.name.localizedCaseInsensitiveContains(name) ||
                $0.englishName.localizedCaseInsensitiveContains(name)
            }) {
                if !results.contains(where: { $0.id == chem.id }) {
                    results.append(chem)
                }
                continue
            }
            // 2차: LocalDB SQLite 7,189건
            if let dbChem = DummyDataLoader.shared.chemicalByName(name) {
                if !results.contains(where: { $0.id == dbChem.id }) {
                    results.append(dbChem)
                }
            }
        }

        return results
    }

    /// 감지된 화학물질로 기존 DB 제품 중 가장 잘 맞는 제품 검색
    func findBestMatchingProduct(for chemicals: [Chemical]) -> Product? {
        let detectedNames = Set(chemicals.map { $0.name })
        let allProducts = DummyDataLoader.shared.products

        let scored: [(Product, Int)] = allProducts.map { product in
            let productChemNames = Set(product.chemicals.map { $0.name })
            let overlap = detectedNames.intersection(productChemNames).count
            return (product, overlap)
        }

        let best = scored.max(by: { $0.1 < $1.1 })
        guard let (product, score) = best, score > 0 else { return nil }
        return product
    }

    /// 감지된 화학물질로 동적 스캔 Product 생성
    func buildScannedProduct(chemicals: [Chemical], rawText: String = "") -> Product {
        let maxRisk = chemicals.map(\.riskLevel.rawValue).max() ?? 1
        let riskLevel = RiskLevel(rawValue: maxRisk) ?? .safe
        let category = inferCategory(from: chemicals, text: rawText)
        let ventilation = ventilationMinutes(for: riskLevel)

        return Product(
            id: "scan_\(UUID().uuidString.prefix(8))",
            name: extractProductName(from: rawText) ?? "스캔된 제품",
            brand: extractBrand(from: rawText) ?? "라벨 스캔",
            category: category,
            riskLevel: riskLevel,
            chemicals: chemicals,
            usageGuide: usageGuide(for: riskLevel, chemicals: chemicals),
            ventilationMinutes: ventilation,
            certifications: [],
            alternativeIds: suggestAlternativeIds(for: riskLevel),
            isRegistered: false,
            isRecalled: false,
            recallReason: nil,
            imageSystemName: imageIcon(for: category),
            scanDate: Date()
        )
    }

    // MARK: - 캐시 로딩

    private func loadCache() {
        guard let url = Bundle.main.url(forResource: "chemicals_cache", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }
        cache = raw.compactMap(CacheEntry.init)
    }

    // MARK: - 캐시 탐색

    private func findInCache(_ name: String) -> CacheEntry? {
        let lowered = name.lowercased()
        return cache.first { entry in
            entry.name.lowercased() == lowered ||
            entry.englishName.lowercased() == lowered ||
            entry.aliases.contains { $0.lowercased() == lowered } ||
            entry.aliases.contains { lowered.contains($0.lowercased()) } ||
            lowered.contains(entry.name.lowercased())
        }
    }

    // MARK: - 추론 헬퍼

    private func inferCategory(from chemicals: [Chemical], text: String) -> ProductCategory {
        let names = chemicals.map { $0.name + $0.englishName }
        let joined = (names.joined() + text).lowercased()

        if joined.contains("차아염소산") || joined.contains("hypochlorite") || joined.contains("곰팡") { return .bathroom }
        if joined.contains("세탁") || joined.contains("laundry") || joined.contains("섬유") { return .laundry }
        if joined.contains("주방") || joined.contains("dish") || joined.contains("kitchen") { return .kitchen }
        if joined.contains("방향") || joined.contains("fragrance") || joined.contains("향료") { return .airFreshener }
        if joined.contains("살균") || joined.contains("disinfect") || joined.contains("sanitize") { return .disinfectant }
        if joined.contains("살충") || joined.contains("insect") || joined.contains("모기") { return .insecticide }
        if joined.contains("표백") || joined.contains("bleach") || joined.contains("과산화수소") { return .bleach }
        if joined.contains("아기") || joined.contains("베이비") || joined.contains("영유아") || joined.contains("baby") { return .babyHygiene }
        return .multipurpose
    }

    private func extractProductName(from text: String) -> String? {
        // 제품명 추출 시도: 첫 줄 또는 대문자 단어 클러스터
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let candidate = lines.first(where: { $0.count > 2 && $0.count < 30 })
        return candidate
    }

    private func extractBrand(from text: String) -> String? {
        let knownBrands = ["유한락스", "홈케어", "피죤", "테크", "비트", "퍼실", "옥시", "클린업", "하이트", "레이"]
        let lowered = text.lowercased()
        return knownBrands.first { lowered.contains($0.lowercased()) }
    }

    private func ventilationMinutes(for level: RiskLevel) -> Int {
        switch level {
        case .safe:    return 0
        case .low:     return 10
        case .medium:  return 20
        case .high:    return 30
        case .critical: return 60
        }
    }

    private func usageGuide(for level: RiskLevel, chemicals: [Chemical]) -> String {
        switch level {
        case .safe:
            return "안전한 성분으로 구성되어 있습니다. 일반적인 사용 방법을 따르세요."
        case .low:
            return "사용 후 물로 충분히 헹궈 주세요. 환기를 권장합니다."
        case .medium:
            let concerns = chemicals.flatMap { $0.concerns }.map { $0.rawValue }
            if concerns.contains("respiratory") {
                return "사용 시 마스크를 착용하고 충분히 환기하세요. 눈·피부 접촉을 피하세요."
            }
            return "반드시 장갑을 착용하고 사용 후 환기하세요. 어린이 손이 닿지 않는 곳에 보관하세요."
        case .high:
            return "반드시 고무장갑·마스크 착용 후 사용하세요. 사용 전후 30분 이상 환기 필수. 영유아·임산부 접근 금지."
        case .critical:
            return "사용을 즉시 중단하고 환경부·식약처 안전 지침을 확인하세요. 전문가 상담을 권장합니다."
        }
    }

    private func suggestAlternativeIds(for level: RiskLevel) -> [String] {
        guard level.rawValue >= 3 else { return [] }
        let all = DummyDataLoader.shared.alternatives
        let safer = all.filter { $0.riskLevel.rawValue <= 2 }.prefix(3)
        return safer.map { $0.id }
    }

    private func imageIcon(for category: ProductCategory) -> String {
        switch category {
        case .bathroom:    return "bubbles.and.sparkles.fill"
        case .laundry:     return "washer.fill"
        case .kitchen:     return "fork.knife"
        case .airFreshener: return "wind"
        case .disinfectant: return "cross.case.fill"
        case .insecticide: return "ant.fill"
        case .multipurpose: return "spray.and.sparkles"
        case .bleach:      return "drop.fill"
        case .babyHygiene: return "figure.and.child.holdinghands"
        }
    }
}

// MARK: - CacheEntry

private struct CacheEntry {
    // chemicals_cache.json은 영문 key 사용, ChemicalConcern rawValue는 한국어이므로 매핑 필요
    static func mapConcern(_ str: String) -> ChemicalConcern? {
        let map: [String: ChemicalConcern] = [
            "respiratory":  .respiratory,
            "endocrine":    .endocrine,
            "carcinogenic": .carcinogenic,
            "skin":         .skin,
            "neurotoxic":   .neurotoxic,
            "aquatic":      .aquatic,
            "allergen":     .allergen
        ]
        return ChemicalConcern(rawValue: str) ?? map[str.lowercased()]
    }
    let id: String
    let name: String
    let englishName: String
    let casNumber: String
    let aliases: [String]
    let riskLevel: Int
    let concerns: [String]
    let effects: [String]
    let infantRisk: Bool
    let pregnantRisk: Bool
    let allergyRisk: Bool
    let petRisk: Bool

    init?(_ dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let englishName = dict["englishName"] as? String,
              let casNumber = dict["casNumber"] as? String,
              let riskLevel = dict["riskLevel"] as? Int else { return nil }

        self.id = id
        self.name = name
        self.englishName = englishName
        self.casNumber = casNumber
        self.riskLevel = riskLevel
        self.aliases = dict["aliases"] as? [String] ?? []
        self.concerns = dict["concerns"] as? [String] ?? []
        self.effects = dict["effects"] as? [String] ?? []
        self.infantRisk = dict["infantRisk"] as? Bool ?? false
        self.pregnantRisk = dict["pregnantRisk"] as? Bool ?? false
        self.allergyRisk = dict["allergyRisk"] as? Bool ?? false
        self.petRisk = dict["petRisk"] as? Bool ?? false
    }

    func toChemical() -> Chemical {
        let rl = RiskLevel(rawValue: riskLevel) ?? .safe
        let concernObjs = concerns.compactMap { CacheEntry.mapConcern($0) }
        return Chemical(
            id: id,
            name: name,
            englishName: englishName,
            casNumber: casNumber,
            riskLevel: rl,
            concerns: concernObjs,
            effects: effects,
            infantRisk: infantRisk,
            pregnantRisk: pregnantRisk,
            allergyRisk: allergyRisk,
            petRisk: petRisk
        )
    }
}
