import Vision
import UIKit

final class OCRService {
    static let shared = OCRService()
    private init() {}

    // MARK: - OCR 텍스트 추출

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: " "))
            }
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.01

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - 화학물질명 파싱

    func parseChemicalNames(from rawText: String) -> [String] {
        let text = normalize(rawText)
        var found: Set<String> = []

        // 0차: LocalDB 7189건 화학물질명 직접 매칭 (한/영 모두)
        let dbNames = LocalDBService.shared.chemicalNames
        for entry in dbNames {
            if !entry.nameKr.isEmpty, text.localizedCaseInsensitiveContains(entry.nameKr) {
                found.insert(entry.nameKr)
            } else if !entry.nameEn.isEmpty, entry.nameEn.count >= 4,
                      text.localizedCaseInsensitiveContains(entry.nameEn) {
                found.insert(entry.nameKr.isEmpty ? entry.nameEn : entry.nameKr)
            }
        }

        // 1차: 알려진 화학물질명 직접 매칭 (aliases 포함)
        for entry in chemicalAliasMap {
            for alias in entry.value {
                if text.localizedCaseInsensitiveContains(alias) {
                    found.insert(entry.key)
                    break
                }
            }
        }

        // 2차: 한국어 화학명 패턴 정규식 (나트륨, 칼륨, 산, 염 계열)
        let koreanPatterns = [
            "[가-힣]+나트륨", "[가-힣]+칼륨", "[가-힣]+칼슘",
            "[가-힣]+암모늄", "[가-힣]+클로라이드", "[가-힣]+설페이트",
            "[가-힣]+염", "[가-힣]+산", "[가-힣]+알코올", "[가-힣]+글리콜",
            "[가-힣]+에테르", "[가-힣]+에스테르", "[가-힣]+옥사이드"
        ]
        for pattern in koreanPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)
                for m in matches {
                    if let r = Range(m.range, in: text) {
                        found.insert(String(text[r]))
                    }
                }
            }
        }

        // 3차: 영문 화학명 패턴
        let engPatterns = [
            "sodium\\s+[a-z]+", "potassium\\s+[a-z]+",
            "[a-z]+\\s+chloride", "[a-z]+\\s+hydroxide",
            "[a-z]+\\s+sulfate", "[a-z]+\\s+oxide",
            "[a-z]+\\s+acid", "[a-z]+anol", "[a-z]+glycol"
        ]
        for pattern in engPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)
                for m in matches {
                    if let r = Range(m.range, in: text) {
                        found.insert(String(text[r]).trimmingCharacters(in: .whitespaces))
                    }
                }
            }
        }

        return Array(found)
    }

    // MARK: - 텍스트 정규화

    private func normalize(_ text: String) -> String {
        var result = text
        // 전각 → 반각
        result = result.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? result
        // 연속 공백 정리
        result = result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
        return result
    }

    // MARK: - 화학물질명 alias 사전
    // key: 표준 화학물질명(DB 매칭용), value: 라벨에 등장할 수 있는 표현들

    private let chemicalAliasMap: [String: [String]] = [
        "차아염소산나트륨": ["차아염소산나트륨", "Sodium Hypochlorite", "NaOCl", "차아염소산소다", "락스", "hypochlorite"],
        "수산화나트륨": ["수산화나트륨", "Sodium Hydroxide", "NaOH", "가성소다", "caustic soda"],
        "계면활성제": ["계면활성제", "surfactant", "surface active agent", "음이온계면활성제", "비이온계면활성제", "양이온계면활성제"],
        "에탄올": ["에탄올", "Ethanol", "에틸알코올", "Ethyl Alcohol", "alcohol", "알코올"],
        "벤잘코늄클로라이드": ["벤잘코늄클로라이드", "Benzalkonium Chloride", "BKC", "BAC", "benzalkonium"],
        "향료": ["향료", "Fragrance", "Parfum", "fragrance", "향", "방향"],
        "파라벤": ["파라벤", "Paraben", "methylparaben", "propylparaben", "부틸파라벤", "메틸파라벤"],
        "프로필렌글리콜": ["프로필렌글리콜", "Propylene Glycol", "PG", "1,2-propanediol"],
        "CMIT/MIT": ["CMIT", "MIT", "클로로메틸이소티아졸리논", "메틸이소티아졸리논", "Methylisothiazolinone", "Chloromethylisothiazolinone", "isothiazolinone"],
        "PHMG": ["PHMG", "폴리헥사메틸렌구아니딘", "Polyhexamethylene Guanidine"],
        "톨루엔": ["톨루엔", "Toluene", "toluol", "메틸벤젠"],
        "벤젠": ["벤젠", "Benzene", "benzol"],
        "트리클로산": ["트리클로산", "Triclosan", "트리클로로페놀", "triclosan"],
        "메탄올": ["메탄올", "Methanol", "메틸알코올", "Methyl Alcohol", "wood alcohol"],
        "아세톤": ["아세톤", "Acetone", "디메틸케톤", "dimethyl ketone", "propanone"],
        "암모니아": ["암모니아", "Ammonia", "NH3", "암모니아수"],
        "이소프로판올": ["이소프로판올", "Isopropanol", "이소프로필알코올", "Isopropyl Alcohol", "IPA", "2-propanol"],
        "글리세린": ["글리세린", "Glycerin", "Glycerol", "글리세롤"],
        "구연산": ["구연산", "Citric Acid", "시트르산", "citrate"],
        "탄산나트륨": ["탄산나트륨", "Sodium Carbonate", "소다회", "soda ash", "Na2CO3"],
        "과산화수소": ["과산화수소", "Hydrogen Peroxide", "H2O2", "hydrogen peroxide"],
        "포름알데히드": ["포름알데히드", "Formaldehyde", "폼알데하이드", "HCHO", "formalin", "포르말린"],
        "나프탈렌": ["나프탈렌", "Naphthalene", "naphthalin", "나프탈린"],
        "소디움라우릴설페이트": ["소디움라우릴설페이트", "Sodium Lauryl Sulfate", "SLS", "sodium dodecyl sulfate", "SDS", "라우릴황산나트륨"],
        "인산": ["인산", "Phosphoric Acid", "H3PO4", "orthophosphoric acid"],
        "붕사": ["붕사", "Borax", "사붕산나트륨", "Sodium Tetraborate", "sodium borate"],
        "염화나트륨": ["염화나트륨", "Sodium Chloride", "NaCl", "식염", "소금"],
        "초산": ["초산", "Acetic Acid", "아세트산", "acetic acid", "식초산"],
        "살리실산": ["살리실산", "Salicylic Acid", "salicylate"],
        "에틸렌글리콜": ["에틸렌글리콜", "Ethylene Glycol", "모노에틸렌글리콜", "MEG", "glycol"],
        // 방부제 계열
        "메틸파라벤": ["메틸파라벤", "methylparaben", "methyl paraben"],
        "에틸파라벤": ["에틸파라벤", "ethylparaben", "ethyl paraben"],
        "프로필파라벤": ["프로필파라벤", "propylparaben", "propyl paraben"],
        "부틸파라벤": ["부틸파라벤", "butylparaben", "butyl paraben"],
        "페녹시에탄올": ["페녹시에탄올", "phenoxyethanol", "2-phenoxyethanol"],
        "소르빈산칼륨": ["소르빈산칼륨", "potassium sorbate", "sorbate"],
        "안식향산나트륨": ["안식향산나트륨", "sodium benzoate", "벤조산나트륨"],
        "이미다졸리디닐우레아": ["이미다졸리디닐우레아", "imidazolidinyl urea", "germall"],
        "DMDM하이단토인": ["DMDM하이단토인", "DMDM hydantoin"],
        "메틸이소티아졸리논": ["메틸이소티아졸리논", "methylisothiazolinone"],
        // 계면활성제 계열
        "소디움라우레스설페이트": ["소디움라우레스설페이트", "sodium laureth sulfate", "SLES", "라우레스황산나트륨"],
        "코카미도프로필베타인": ["코카미도프로필베타인", "cocamidopropyl betaine", "CAPB"],
        "알킬폴리글루코사이드": ["알킬폴리글루코사이드", "alkyl polyglucoside", "APG", "코코글루코사이드"],
        "노닐페놀에톡실레이트": ["에톡시레이트", "nonylphenol", "NPE"],
        // 향료 성분
        "리모넨": ["리모넨", "limonene", "d-limonene"],
        "리날로올": ["리날로올", "linalool"],
        "제라니올": ["제라니올", "geraniol"],
        "벤질알코올": ["벤질알코올", "benzyl alcohol"],
        "신남알데히드": ["신남알데히드", "cinnamaldehyde", "계피향"],
        "쿠마린": ["쿠마린", "coumarin"],
        "머스크향료": ["머스크", "musk", "인공사향"],
        // 용매
        "에틸렌글리콜모노부틸에테르": ["에틸렌글리콜모노부틸에테르", "EGMBE", "2-butoxyethanol", "부톡시에탄올"],
        "트리에탄올아민": ["트리에탄올아민", "triethanolamine", "TEA"],
        // 내분비교란 물질
        "프탈레이트": ["프탈레이트", "phthalate", "DEHP", "DBP"],
        "비스페놀A": ["비스페놀A", "bisphenol A", "BPA"],
        "에톡시레이트": ["노닐페놀에톡실레이트", "nonylphenol ethoxylate", "nonylphenol"],
        // 산화제·산·염기
        "과초산": ["과초산", "peracetic acid", "PAA", "과아세트산"],
        "염산": ["염산", "hydrochloric acid", "HCl"],
        "수산화칼륨": ["수산화칼륨", "potassium hydroxide", "KOH", "가성칼리"],
        "과탄산나트륨": ["과탄산나트륨", "sodium percarbonate", "산소계표백제"],
        // 살생물제·살충제
        "클로르헥시딘": ["클로르헥시딘", "chlorhexidine", "CHG"],
        "사이페르메트린": ["사이페르메트린", "cypermethrin"],
        "델타메트린": ["델타메트린", "deltamethrin"],
        "알레트린": ["알레트린", "allethrin"],
        "DEET": ["DEET", "디에틸톨루아미드"],
        "은나노": ["은나노", "nano silver", "나노실버"],
        // 기타
        "탄산수소나트륨": ["탄산수소나트륨", "sodium bicarbonate", "베이킹소다", "중조"],
        "형광증백제": ["형광증백제", "optical brightener", "OBA", "형광물질"],
        "EDTA": ["EDTA", "에틸렌디아민테트라아세트산"],
        "벤조페논": ["벤조페논", "benzophenone"],
        "오르토페닐페놀": ["오르토페닐페놀", "OPP", "ortho-phenylphenol"]
    ]
}
