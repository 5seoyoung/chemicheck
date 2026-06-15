import Foundation
import SQLite3

// MARK: - DB Record Types

struct ChemicalDBRecord {
    let id: Int
    let nameKr: String
    let nameEn: String
    let casNumber: String
    let riskLevel: Int
    let symptomGeneral: String
    let symptomInhale: String
    let symptomSkin: String
    let symptomEye: String
    let symptomOral: String

    func toChemical() -> Chemical {
        let level = RiskLevel(rawValue: riskLevel) ?? .low
        let effects = [symptomGeneral, symptomInhale]
            .filter { !$0.isEmpty }
            .map { String($0.prefix(120)) }
        var concerns: [ChemicalConcern] = []
        let combined = symptomGeneral + symptomInhale + symptomSkin
        if combined.contains("호흡") || combined.contains("흡입") { concerns.append(.respiratory) }
        if combined.contains("피부") { concerns.append(.skin) }
        if combined.contains("발암") { concerns.append(.carcinogenic) }
        if combined.contains("내분비") { concerns.append(.endocrine) }
        if combined.contains("알레르") { concerns.append(.allergen) }
        return Chemical(
            id: "db_\(id)",
            name: nameKr,
            englishName: nameEn,
            casNumber: casNumber,
            riskLevel: level,
            concerns: concerns,
            effects: effects,
            infantRisk: riskLevel >= 4,
            pregnantRisk: riskLevel >= 4,
            allergyRisk: riskLevel >= 3,
            petRisk: riskLevel >= 4
        )
    }
}

struct ProductDBRecord {
    let id: Int
    let productName: String
    let category: String
    let manufacturer: String
    let registrationNumber: String
    let isApproved: Int       // 0=신고, 1=승인, 2=자율공개
    let discloses: Bool
}

struct RecallDBRecord {
    let id: Int
    let productName: String
    let manufacturer: String
    let seller: String
    let actionType: String
    let actionDate: String
    let reportNumber: String
    let legalBasis: String
}

// MARK: - LocalDBService

final class LocalDBService {
    static let shared = LocalDBService()

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.chemicheck.localdb", qos: .userInitiated)

    // In-memory chemical name cache — written on dbQueue, read via dbQueue.sync
    private var _chemicalNames: [(nameKr: String, nameEn: String)] = []
    var chemicalNames: [(nameKr: String, nameEn: String)] {
        dbQueue.sync { _chemicalNames }
    }

    private init() {
        // Async so LocalDBService.shared never blocks the main thread
        dbQueue.async {
            self.openDatabase()
            self.preloadChemicalNames()
        }
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Setup

    private func openDatabase() {
        guard let srcURL = Bundle.main.url(forResource: "chemicheck", withExtension: "sqlite") else {
            return
        }
        let docsDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let destURL = docsDir.appendingPathComponent("chemicheck.sqlite")

        // Copy bundle → Caches on first launch (read-only bundle can't be opened directly on device)
        if !FileManager.default.fileExists(atPath: destURL.path) {
            try? FileManager.default.copyItem(at: srcURL, to: destURL)
        }

        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        if sqlite3_open_v2(destURL.path, &db, flags, nil) != SQLITE_OK {
            db = nil
        }
    }

    private func preloadChemicalNames() {
        guard let db else { return }
        let sql = "SELECT name_kr, name_en FROM chemicals WHERE name_kr != ''"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        var results: [(String, String)] = []
        results.reserveCapacity(7200)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let kr = string(stmt, 0)
            let en = string(stmt, 1)
            results.append((kr, en))
        }
        _chemicalNames = results
    }

    // MARK: - Chemical Queries

    func searchChemical(nameKr: String) -> ChemicalDBRecord? {
        query(sql: """
            SELECT id,name_kr,name_en,cas_number,risk_level,
                   symptom_general,symptom_inhale,symptom_skin,symptom_eye,symptom_oral
            FROM chemicals WHERE name_kr = ? LIMIT 1
            """, bindings: [nameKr], parse: parseChemical).first
    }

    func searchChemicalByEn(nameEn: String) -> ChemicalDBRecord? {
        query(sql: """
            SELECT id,name_kr,name_en,cas_number,risk_level,
                   symptom_general,symptom_inhale,symptom_skin,symptom_eye,symptom_oral
            FROM chemicals WHERE name_en LIKE ? LIMIT 1
            """, bindings: ["%\(nameEn)%"], parse: parseChemical).first
    }

    func searchChemicalByCAS(cas: String) -> ChemicalDBRecord? {
        query(sql: """
            SELECT id,name_kr,name_en,cas_number,risk_level,
                   symptom_general,symptom_inhale,symptom_skin,symptom_eye,symptom_oral
            FROM chemicals WHERE cas_number = ? LIMIT 1
            """, bindings: [cas], parse: parseChemical).first
    }

    // MARK: - Product Queries

    func searchProduct(name: String) -> ProductDBRecord? {
        query(sql: """
            SELECT id,product_name,category,manufacturer,registration_number,
                   is_approved,discloses_ingredients
            FROM products WHERE product_name LIKE ? LIMIT 1
            """, bindings: ["%\(name)%"], parse: parseProduct).first
    }

    func isProductRegistered(name: String) -> Bool {
        searchProduct(name: name) != nil
    }

    // MARK: - Recall Queries

    func searchRecalls(productName: String, limit: Int = 20) -> [RecallDBRecord] {
        query(sql: """
            SELECT id,product_name,manufacturer,seller,action_type,
                   action_date,report_number,legal_basis
            FROM recalls WHERE product_name LIKE ? LIMIT \(limit)
            """, bindings: ["%\(productName)%"], parse: parseRecall)
    }

    func recentRecalls(limit: Int = 30) -> [RecallDBRecord] {
        query(sql: """
            SELECT id,product_name,manufacturer,seller,action_type,
                   action_date,report_number,legal_basis
            FROM recalls ORDER BY action_date DESC LIMIT \(limit)
            """, bindings: [], parse: parseRecall)
    }

    // MARK: - Generic Query (always runs on dbQueue — waits for async init if needed)

    private func query<T>(sql: String, bindings: [String],
                           parse: (OpaquePointer?) -> T?) -> [T] {
        dbQueue.sync { () -> [T] in
            guard let db else { return [] }
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
            defer { sqlite3_finalize(stmt) }
            for (i, val) in bindings.enumerated() {
                sqlite3_bind_text(stmt, Int32(i + 1), (val as NSString).utf8String, -1, nil)
            }
            var results: [T] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let item = parse(stmt) { results.append(item) }
            }
            return results
        }
    }

    // MARK: - Row Parsers

    private func parseChemical(_ stmt: OpaquePointer?) -> ChemicalDBRecord? {
        guard let stmt else { return nil }
        return ChemicalDBRecord(
            id: Int(sqlite3_column_int(stmt, 0)),
            nameKr:         string(stmt, 1),
            nameEn:         string(stmt, 2),
            casNumber:      string(stmt, 3),
            riskLevel:      Int(sqlite3_column_int(stmt, 4)),
            symptomGeneral: string(stmt, 5),
            symptomInhale:  string(stmt, 6),
            symptomSkin:    string(stmt, 7),
            symptomEye:     string(stmt, 8),
            symptomOral:    string(stmt, 9)
        )
    }

    private func parseProduct(_ stmt: OpaquePointer?) -> ProductDBRecord? {
        guard let stmt else { return nil }
        return ProductDBRecord(
            id:                 Int(sqlite3_column_int(stmt, 0)),
            productName:        string(stmt, 1),
            category:           string(stmt, 2),
            manufacturer:       string(stmt, 3),
            registrationNumber: string(stmt, 4),
            isApproved:         Int(sqlite3_column_int(stmt, 5)),
            discloses:          sqlite3_column_int(stmt, 6) == 1
        )
    }

    private func parseRecall(_ stmt: OpaquePointer?) -> RecallDBRecord? {
        guard let stmt else { return nil }
        return RecallDBRecord(
            id:           Int(sqlite3_column_int(stmt, 0)),
            productName:  string(stmt, 1),
            manufacturer: string(stmt, 2),
            seller:       string(stmt, 3),
            actionType:   string(stmt, 4),
            actionDate:   string(stmt, 5),
            reportNumber: string(stmt, 6),
            legalBasis:   string(stmt, 7)
        )
    }

    private func string(_ stmt: OpaquePointer?, _ col: Int32) -> String {
        guard let stmt,
              let raw = sqlite3_column_text(stmt, col) else { return "" }
        return String(cString: raw)
    }
}
