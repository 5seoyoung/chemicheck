import SwiftUI

@Observable
final class DiagnosisViewModel {
    var isAnalyzing: Bool = false
    var currentProduct: Product? = nil
    var adjustedRiskLevel: RiskLevel? = nil
    var familyWarnings: [String] = []
    var alternatives: [Alternative] = []

    private let riskCalculator = RiskCalculator()

    func analyzeDummyProduct(for profile: FamilyProfile) async {
        isAnalyzing = true
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s 로딩 시뮬레이션

        let products = DummyDataLoader.shared.products
        // 시연 시나리오: 욕실 곰팡이 제거제 or 랜덤 선택
        let product = products.randomElement() ?? products[0]
        currentProduct = product
        adjustedRiskLevel = riskCalculator.calculate(product: product, profile: profile)
        familyWarnings = riskCalculator.warnings(product: product, profile: profile)
        alternatives = product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }

        isAnalyzing = false
    }

    func loadProduct(_ product: Product, for profile: FamilyProfile) {
        currentProduct = product
        adjustedRiskLevel = riskCalculator.calculate(product: product, profile: profile)
        familyWarnings = riskCalculator.warnings(product: product, profile: profile)
        alternatives = product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }
    }

    func reset() {
        currentProduct = nil
        adjustedRiskLevel = nil
        familyWarnings = []
        alternatives = []
        isAnalyzing = false
    }
}
