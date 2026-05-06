import SwiftUI

enum RiskLevel: Int, Codable, CaseIterable {
    case safe = 1
    case low = 2
    case medium = 3
    case high = 4
    case critical = 5

    var label: String {
        switch self {
        case .safe:     return "안전"
        case .low:      return "주의"
        case .medium:   return "경고"
        case .high:     return "위험"
        case .critical: return "매우 위험"
        }
    }

    var shortLabel: String {
        switch self {
        case .safe:     return "안전"
        case .low:      return "낮음"
        case .medium:   return "보통"
        case .high:     return "높음"
        case .critical: return "위험"
        }
    }

    // 이미지 기준 배지 레이블 (위험 高/中/低, 안전, 매우 위험)
    var badgeLabel: String {
        switch self {
        case .safe:     return "안전"
        case .low:      return "위험 低"
        case .medium:   return "위험 中"
        case .high:     return "위험 高"
        case .critical: return "매우 위험"
        }
    }

    // 화면 상단 등급 표시
    var gradeLabel: String {
        switch self {
        case .safe:     return "매우 안전"
        case .low:      return "안전"
        case .medium:   return "주의"
        case .high:     return "위험"
        case .critical: return "매우 위험"
        }
    }

    var color: Color {
        switch self {
        case .safe:     return Color(hex: "#22B573")
        case .low:      return Color(hex: "#7DC63D")
        case .medium:   return Color(hex: "#F5A623")
        case .high:     return Color(hex: "#F03434")
        case .critical: return Color(hex: "#C00000")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .safe:     return Color.riskSafeBg
        case .low:      return Color.riskLowBg
        case .medium:   return Color.riskMediumBg
        case .high:     return Color.riskHighBg
        case .critical: return Color.riskCriticalBg
        }
    }

    var icon: String {
        switch self {
        case .safe:     return "checkmark.shield.fill"
        case .low:      return "exclamationmark.circle.fill"
        case .medium:   return "exclamationmark.triangle.fill"
        case .high:     return "xmark.shield.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var familyWarning: String {
        switch self {
        case .safe:     return "우리집 모든 구성원이 안전하게 사용할 수 있어요"
        case .low:      return "일반 사용은 괜찮지만 환기를 권장해요"
        case .medium:   return "우리집 주의 — 사용 시 주의가 필요해요"
        case .high:     return "우리집 위험 — 영유아·임산부는 특히 주의하세요"
        case .critical: return "우리집 위험 — 즉시 사용을 중단하고 환기하세요"
        }
    }
}
