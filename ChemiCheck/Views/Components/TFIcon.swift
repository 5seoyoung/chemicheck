import SwiftUI

/// Tossface-style icon: SF Symbol centered in a colored rounded container.
/// Design rules: bold weight symbol, pastel bg, matching fg, generous padding.
struct TFIcon: View {
    let symbol: String
    let fg: Color
    let bg: Color
    var size: CGFloat = 44
    var iconRatio: CGFloat = 0.44
    var cornerRadius: CGFloat? = nil  // nil → circle

    var body: some View {
        ZStack {
            if let r = cornerRadius {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(bg)
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .fill(bg)
                    .frame(width: size, height: size)
            }
            Image(systemName: symbol)
                .font(.system(size: size * iconRatio, weight: .bold))
                .foregroundStyle(fg)
        }
    }
}

// MARK: - Semantic presets (Tossface colour pairing)

extension TFIcon {
    /// 🤖 AI 아바타 — brandNavy sparkles on gradient-ish navy-soft
    static func aiAvatar(size: CGFloat = 56) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.navySoft, Color.lavenderSoft],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color.brandNavy)
        }
    }

    /// 🛁 욕실 — drop, sky
    static func bathroom(size: CGFloat = 30) -> TFIcon {
        TFIcon(symbol: "drop.fill", fg: Color.skyFg, bg: Color.skySoft,
               size: size, cornerRadius: size * 0.3)
    }

    /// 🍳 주방 — fork.knife, butter
    static func kitchen(size: CGFloat = 30) -> TFIcon {
        TFIcon(symbol: "fork.knife", fg: Color.butterFg, bg: Color.butterSoft,
               size: size, cornerRadius: size * 0.3)
    }

    /// 🛏️ 아기방 — moon.stars.fill, lavender
    static func babyRoom(size: CGFloat = 30) -> TFIcon {
        TFIcon(symbol: "moon.stars.fill", fg: Color.lavender, bg: Color.lavenderSoft,
               size: size, cornerRadius: size * 0.3)
    }

    /// 🧺 세탁실 — wind, navy
    static func laundry(size: CGFloat = 30) -> TFIcon {
        TFIcon(symbol: "wind", fg: Color.brandNavy, bg: Color.navySoft,
               size: size, cornerRadius: size * 0.3)
    }

    /// 🚨 리콜 경고 — exclamationmark.triangle.fill, riskCritical
    static func recall(size: CGFloat = 32) -> TFIcon {
        TFIcon(symbol: "exclamationmark.triangle.fill",
               fg: Color.riskCritical, bg: Color.riskCritical.opacity(0.13),
               size: size, cornerRadius: size * 0.3)
    }

    /// 🏠 우리집 — house.fill, navy
    static func home(size: CGFloat = 22) -> TFIcon {
        TFIcon(symbol: "house.fill", fg: Color.brandNavy, bg: Color.navySoft,
               size: size, cornerRadius: size * 0.3)
    }

    /// ✨ 반짝임 — sparkles, butter
    static func sparkle(size: CGFloat = 18) -> TFIcon {
        TFIcon(symbol: "sparkles", fg: Color.butterFg, bg: Color.clear,
               size: size, cornerRadius: 0)
    }

    // MARK: - 출처 뱃지
    /// 🏛 식약처
    static func mfds(size: CGFloat = 16) -> some View {
        sourceBadge(symbol: "building.columns.fill", label: "식약처",
                    fg: Color.brandNavy, bg: Color.navySoft)
    }

    /// 🌿 환경부
    static func moe(size: CGFloat = 16) -> some View {
        sourceBadge(symbol: "leaf.fill", label: "환경부",
                    fg: Color.greenDeep, bg: Color.greenSoft)
    }

    /// 🔬 안전보건공단
    static func kosha(size: CGFloat = 16) -> some View {
        sourceBadge(symbol: "cross.case.fill", label: "안전보건공단",
                    fg: Color.skyFg, bg: Color.skySoft)
    }

    private static func sourceBadge(symbol: String, label: String,
                                    fg: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(fg)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(fg)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .background(bg)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            TFIcon.bathroom()
            TFIcon.kitchen()
            TFIcon.babyRoom()
            TFIcon.laundry()
        }
        HStack(spacing: 12) {
            TFIcon.recall()
            TFIcon.home()
            TFIcon.sparkle()
        }
        TFIcon.aiAvatar(size: 84)
        HStack(spacing: 8) {
            TFIcon.mfds()
            TFIcon.moe()
            TFIcon.kosha()
        }
    }
    .padding()
}
