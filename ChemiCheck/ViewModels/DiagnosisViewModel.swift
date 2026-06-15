import SwiftUI
import UIKit

// MARK: - 분석 단계

enum AnalysisStep: String {
    case idle       = "분석 대기 중"
    case ocr        = "라벨 인식 중..."
    case matching   = "화학물질 분석 중..."
    case calculating = "우리집 기준 계산 중..."
    case done       = "완료"
}

// MARK: - DiagnosisViewModel

@Observable
final class DiagnosisViewModel {
    var isAnalyzing: Bool = false
    var analysisStep: AnalysisStep = .idle
    var currentProduct: Product? = nil
    var adjustedRiskLevel: RiskLevel? = nil
    var familyWarnings: [String] = []
    var alternatives: [Alternative] = []
    var analysisError: String? = nil

    private let riskCalculator = RiskCalculator()

    // MARK: - 실 OCR 파이프라인 (Tier 1.4)
    // Image → OCR → 화학물질 매칭 → 위험도 산출

    func analyzeImage(_ image: UIImage, for profile: FamilyProfile) async {
        // 데모 모드: 랜덤 더미 제품으로 시뮬레이션
        if DemoModeManager.shared.isOn {
            await analyzeDummyProduct(for: profile)
            return
        }

        await MainActor.run {
            isAnalyzing = true
            analysisStep = .ocr
            analysisError = nil
        }

        do {
            // Step 1: OCR 텍스트 추출 (5초 타임아웃)
            let rawText = try await withTimeout(seconds: 5) {
                try await OCRService.shared.extractText(from: image)
            } ?? ""

            await MainActor.run { analysisStep = .matching }

            // Step 2: 화학물질명 파싱
            let chemicalNames = OCRService.shared.parseChemicalNames(from: rawText)


            // Step 3: 캐시 매칭 → Chemical 배열
            let chemicals: [Chemical]
            if chemicalNames.isEmpty {
                // OCR이 아무것도 못 찾으면 기존 더미 fallback
                chemicals = DummyDataLoader.shared.chemicals.prefix(3).map { $0 }
            } else {
                chemicals = await FoodDrugAPIService.shared.matchChemicals(from: chemicalNames)
            }

            await MainActor.run { analysisStep = .calculating }

            // Step 4: 기존 DB에서 제품 매칭 시도, 없으면 동적 생성
            let product: Product
            if let matched = FoodDrugAPIService.shared.findBestMatchingProduct(for: chemicals) {
                product = matched
            } else {
                product = FoodDrugAPIService.shared.buildScannedProduct(chemicals: chemicals.isEmpty ? DummyDataLoader.shared.chemicals.prefix(2).map{$0} : chemicals, rawText: rawText)
            }

            // Step 5: 가족 프로필 기반 위험도 보정
            let adjusted = riskCalculator.calculate(product: product, profile: profile)
            let warnings = riskCalculator.warnings(product: product, profile: profile)
            let alts = product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }

            await MainActor.run {
                currentProduct = product
                adjustedRiskLevel = adjusted
                familyWarnings = warnings
                alternatives = alts
                analysisStep = .done
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                analysisError = "라벨 인식에 실패했습니다. 다시 시도해주세요."
                analysisStep = .idle
                isAnalyzing = false
                // 분석 실패 시 랜덤 더미 폴백
                fallbackToDummy(for: profile)
            }
        }
    }

    // MARK: - 더미 제품 직접 로드 (데모 모드 / 기존 흐름)

    func loadProduct(_ product: Product, for profile: FamilyProfile) {
        currentProduct = product
        adjustedRiskLevel = riskCalculator.calculate(product: product, profile: profile)
        familyWarnings = riskCalculator.warnings(product: product, profile: profile)
        alternatives = product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }
    }

    // MARK: - 데모 시뮬레이션 (시연 시나리오)

    func analyzeDummyProduct(for profile: FamilyProfile) async {
        await MainActor.run {
            isAnalyzing = true
            analysisStep = .ocr
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run { analysisStep = .matching }
        try? await Task.sleep(nanoseconds: 600_000_000)
        await MainActor.run { analysisStep = .calculating }
        try? await Task.sleep(nanoseconds: 400_000_000)

        let product = DummyDataLoader.shared.products.randomElement() ?? DummyDataLoader.shared.products.first ?? DummyDataLoader.shared.hardcodedFallbackProduct()
        await MainActor.run {
            loadProduct(product, for: profile)
            analysisStep = .done
            isAnalyzing = false
        }
    }

    // MARK: - 리셋

    func reset() {
        currentProduct = nil
        adjustedRiskLevel = nil
        familyWarnings = []
        alternatives = []
        isAnalyzing = false
        analysisStep = .idle
        analysisError = nil
    }

    // MARK: - Private

    private func fallbackToDummy(for profile: FamilyProfile) {
        let product = DummyDataLoader.shared.products.randomElement() ?? DummyDataLoader.shared.products.first ?? DummyDataLoader.shared.hardcodedFallbackProduct()
        loadProduct(product, for: profile)
    }

    // MARK: - 타임아웃 유틸

    private func withTimeout<T: Sendable>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T? {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            let result = try await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}
