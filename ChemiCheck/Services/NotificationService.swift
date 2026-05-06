import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func sendRecallNotification(product: Product) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 회수 고시 알림"
        content.body = "\(product.name) — 즉시 사용을 중단하고 상세 내용을 확인하세요."
        content.sound = .defaultCritical
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "recall_\(product.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendDailyCheckNotification() {
        let content = UNMutableNotificationContent()
        content.title = "케미체크"
        content.body = "등록된 제품 안전 상태를 확인했어요. 모두 이상 없습니다."
        content.sound = .default

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
