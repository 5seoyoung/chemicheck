import Vision
import UIKit

// Stage 2: Apple Vision Framework OCR 구현
final class OCRService {
    static let shared = OCRService()
    private init() {}

    // 실제 OCR (Stage 2에서 활성화)
    func extractText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let texts = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: texts)
            }
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // 추출된 텍스트에서 화학물질명 파싱
    func parseChemicals(from texts: [String]) -> [String] {
        let chemicalKeywords = [
            "차아염소산나트륨", "Sodium Hypochlorite",
            "수산화나트륨", "Sodium Hydroxide",
            "계면활성제", "Surfactant",
            "에탄올", "Ethanol",
            "벤잘코늄클로라이드", "Benzalkonium Chloride",
            "향료", "Fragrance",
            "파라벤", "Paraben",
            "프로필렌글리콜", "Propylene Glycol"
        ]

        let fullText = texts.joined(separator: " ")
        return chemicalKeywords.filter { fullText.contains($0) }
    }
}
