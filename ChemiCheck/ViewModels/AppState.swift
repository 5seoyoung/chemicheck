import SwiftUI
import Combine

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    var familyProfile: FamilyProfile {
        didSet { saveFamilyProfile() }
    }
    var recentProducts: [Product] = []
    var registeredProducts: [Product] = []
    var notificationBadgeCount: Int = 0
    var pendingRecall: RecallNotification? = nil

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.familyProfile = AppState.loadFamilyProfile()
        loadRegisteredProducts()
        loadRecentProducts()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func addRecentProduct(_ product: Product) {
        var p = product
        recentProducts.removeAll { $0.id == p.id }
        recentProducts.insert(p, at: 0)
        if recentProducts.count > 20 { recentProducts = Array(recentProducts.prefix(20)) }
        saveRecentProducts()
    }

    func registerProduct(_ product: Product) {
        guard !registeredProducts.contains(where: { $0.id == product.id }) else { return }
        registeredProducts.append(product)
        saveRegisteredProducts()
        // 등록 즉시 회수 목록 매칭 검사
        checkRecallMatch(for: product)
    }

    func unregisterProduct(_ product: Product) {
        registeredProducts.removeAll { $0.id == product.id }
        saveRegisteredProducts()
    }

    // MARK: - 회수 자동 매칭 (Tier 2.1)

    private func checkRecallMatch(for product: Product) {
        guard let entry = RecallCuratedLoader.shared.findMatch(for: product) else { return }
        let notification = RecallNotification(
            product: product,
            reason: entry.violationType,
            date: ISO8601DateFormatter().date(from: entry.recallDate + "T00:00:00Z") ?? Date(),
            severity: .critical,
            refundGuide: entry.refundContact,
            agencyName: entry.reportNumber.contains("식약처") ? "식품의약품안전처" : "환경부"
        )
        pendingRecall = notification
        notificationBadgeCount += 1
        NotificationService.shared.sendRecallNotification(product: product)
    }

    func simulateRecallNotification() {
        let recalled = registeredProducts.first(where: { $0.isRecalled })
            ?? registeredProducts.first
            ?? DummyDataLoader.shared.products.first(where: { $0.id == "prod_006" })
        guard let product = recalled else { return }

        let notification = RecallNotification(
            product: product,
            reason: "차아염소산나트륨 농도가 허용 기준(4%)을 초과하여 환경부 회수 명령이 내려졌습니다.",
            date: Date(),
            severity: .critical,
            refundGuide: "구매처(마트, 온라인몰)에서 영수증 없이 전액 환불 가능합니다. 제조사 고객센터(1588-0000)에서도 수거 신청이 가능합니다.",
            agencyName: "환경부"
        )
        pendingRecall = notification
        notificationBadgeCount += 1
        NotificationService.shared.sendRecallNotification(product: product)
    }

    // MARK: - Persistence

    private func saveFamilyProfile() {
        if let data = try? JSONEncoder().encode(familyProfile) {
            UserDefaults.standard.set(data, forKey: "familyProfile")
        }
    }

    private static func loadFamilyProfile() -> FamilyProfile {
        guard let data = UserDefaults.standard.data(forKey: "familyProfile"),
              let profile = try? JSONDecoder().decode(FamilyProfile.self, from: data)
        else { return FamilyProfile() }
        return profile
    }

    private func saveRegisteredProducts() {
        if let data = try? JSONEncoder().encode(registeredProducts) {
            UserDefaults.standard.set(data, forKey: "registeredProducts")
        }
    }

    private func loadRegisteredProducts() {
        guard let data = UserDefaults.standard.data(forKey: "registeredProducts"),
              let products = try? JSONDecoder().decode([Product].self, from: data)
        else { return }
        registeredProducts = products
    }

    private func saveRecentProducts() {
        if let data = try? JSONEncoder().encode(recentProducts) {
            UserDefaults.standard.set(data, forKey: "recentProducts")
        }
    }

    private func loadRecentProducts() {
        guard let data = UserDefaults.standard.data(forKey: "recentProducts"),
              let products = try? JSONDecoder().decode([Product].self, from: data)
        else { return }
        recentProducts = products
    }
}
