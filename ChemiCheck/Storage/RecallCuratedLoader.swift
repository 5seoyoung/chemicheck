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
        let searchTerms = ([product.name, product.brand, product.category.rawValue]
            + product.chemicals.map { $0.name })
            .map { $0.lowercased() }

        return entries.first { entry in
            // 1차: 제품명 직접 매칭
            if entry.productName.lowercased().contains(product.name.lowercased()) { return true }
            if product.name.lowercased().contains(entry.productName.lowercased()) { return true }
            // 2차: 키워드 중 2개 이상 일치
            let matchCount = entry.keywords.filter { kw in
                searchTerms.contains { $0.contains(kw.lowercased()) }
            }.count
            return matchCount >= 2
        }
    }
}
