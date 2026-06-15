import Foundation

struct RecallEntry {
    let recallId: String
    let productName: String
    let manufacturer: String
    let reportNumber: String
    let violationType: String
    let recallDate: String
    let refundContact: String
    let description: String
    let keywords: [String]
}

final class RecallCuratedLoader {
    static let shared = RecallCuratedLoader()
    private init() { load() }

    private(set) var entries: [RecallEntry] = []

    private func load() {
        guard let url = Bundle.main.url(forResource: "recalls_curated", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        entries = raw.compactMap { dict in
            guard let id = dict["recallId"] as? String,
                  let name = dict["productName"] as? String,
                  let mfg = dict["manufacturer"] as? String,
                  let report = dict["reportNumber"] as? String,
                  let vtype = dict["violationType"] as? String,
                  let date = dict["recallDate"] as? String,
                  let refund = dict["refundContact"] as? String,
                  let desc = dict["description"] as? String else { return nil }
            let keywords = dict["keywords"] as? [String] ?? []
            return RecallEntry(recallId: id, productName: name, manufacturer: mfg,
                               reportNumber: report, violationType: vtype,
                               recallDate: date, refundContact: refund,
                               description: desc, keywords: keywords)
        }
    }

    /// 제품명·브랜드·카테고리 기준으로 회수 목록 매칭
    func findMatch(for product: Product) -> RecallEntry? {
        // 1차: 공개 데이터 SQLite (생활화학제품 위반정보 5723건)
        let dbRecalls = LocalDBService.shared.searchRecalls(productName: product.name, limit: 5)
        if let first = dbRecalls.first {
            return RecallEntry(
                recallId: "DB_\(first.id)",
                productName: first.productName,
                manufacturer: first.manufacturer,
                reportNumber: first.reportNumber,
                violationType: first.actionType.isEmpty ? "생활화학제품 안전기준 위반" : first.actionType,
                recallDate: first.actionDate,
                refundContact: "구매처 문의",
                description: "환경부 생활화학제품 안전관리법에 따른 조치. 출처: \(first.legalBasis)",
                keywords: product.name.components(separatedBy: " ")
            )
        }

        // 2차: 큐레이션 JSON (recalls_curated.json)
        let searchTerms = ([product.name, product.brand, product.category.rawValue]
            + product.chemicals.map { $0.name })
            .map { $0.lowercased() }

        return entries.first { entry in
            if entry.productName.lowercased().contains(product.name.lowercased()) { return true }
            if product.name.lowercased().contains(entry.productName.lowercased()) { return true }
            let matchCount = entry.keywords.filter { kw in
                searchTerms.contains { $0.contains(kw.lowercased()) }
            }.count
            return matchCount >= 2
        }
    }

    /// 최신 위반 목록 (홈 화면 알림용)
    func recentRecallEntries(limit: Int = 10) -> [RecallEntry] {
        LocalDBService.shared.recentRecalls(limit: limit).map { rec in
            RecallEntry(
                recallId: "DB_\(rec.id)",
                productName: rec.productName,
                manufacturer: rec.manufacturer,
                reportNumber: rec.reportNumber,
                violationType: rec.actionType.isEmpty ? "생활화학제품 안전기준 위반" : rec.actionType,
                recallDate: rec.actionDate,
                refundContact: "구매처 문의",
                description: "환경부 생활화학제품 안전관리법 위반. \(rec.legalBasis)",
                keywords: rec.productName.components(separatedBy: " ")
            )
        }
    }
}
