import SwiftUI

// HTML CSS 변수 → Swift 1:1 매핑
// --navy: #4A6B9C / --green: #5DBB94 / --peach: #FFB8A3
// --lavender: #B8A9D9 / --butter: #FFD68A / --sky: #9BC8E8
extension Color {

    // ─── Navy ────────────────────────────────────────────────
    static let brandNavy     = Color(hex: "#4A6B9C")  // --navy
    static let navyDeep      = Color(hex: "#2E4A73")  // --navy-deep
    static let navySoft      = Color(hex: "#E8EFF9")  // --navy-soft
    static let navyMist      = Color(hex: "#F4F8FE")  // --navy-mist

    // ─── Green ───────────────────────────────────────────────
    static let brandGreen    = Color(hex: "#5DBB94")  // --green
    static let greenDeep     = Color(hex: "#3A9B73")  // --green-deep
    static let greenSoft     = Color(hex: "#E3F5EC")  // --green-soft
    static let greenMist     = Color(hex: "#F1FAF5")  // --green-mist

    // ─── Peach ───────────────────────────────────────────────
    static let peach         = Color(hex: "#FFB8A3")  // --peach
    static let peachSoft     = Color(hex: "#FFE8E0")  // --peach-soft
    static let peachMist     = Color(hex: "#FFF5F1")  // --peach-mist
    static let peachFg       = Color(hex: "#C2553B")  // coral foreground

    // ─── Lavender ────────────────────────────────────────────
    static let lavender      = Color(hex: "#B8A9D9")  // --lavender
    static let lavenderSoft  = Color(hex: "#EFE8F7")  // --lavender-soft
    static let lavenderMist  = Color(hex: "#F8F4FC")  // --lavender-mist

    // ─── Butter ──────────────────────────────────────────────
    static let butter        = Color(hex: "#FFD68A")  // --butter
    static let butterSoft    = Color(hex: "#FFF1D1")  // --butter-soft
    static let butterMist    = Color(hex: "#FFFAEC")  // --butter-mist
    static let butterFg      = Color(hex: "#B07F2D")  // amber foreground

    // ─── Sky ─────────────────────────────────────────────────
    static let sky           = Color(hex: "#9BC8E8")  // --sky
    static let skySoft       = Color(hex: "#DCEEF9")  // --sky-soft
    static let skyMist       = Color(hex: "#EFF7FC")  // --sky-mist
    static let skyFg         = Color(hex: "#4781A6")  // sky foreground

    // ─── Surface & BG ────────────────────────────────────────
    static let bgPrimary     = Color(hex: "#FBFCFE")  // --surface
    static let bgCard        = Color(hex: "#FFFFFF")   // --bg
    static let bgSecondary   = Color(hex: "#E8EFF9")   // --navy-soft
    static let bgSurface2    = Color(hex: "#F5F7FB")   // --surface-2

    // ─── Text ────────────────────────────────────────────────
    static let textPrimary   = Color(hex: "#1F2937")   // --text-1
    static let textSecondary = Color(hex: "#5B6577")   // --text-2
    static let textTertiary  = Color(hex: "#97A0AF")   // --text-3

    // ─── Lines ───────────────────────────────────────────────
    static let separator     = Color(hex: "#EEF1F6")   // --line
    static let separatorSoft = Color(hex: "#F4F6FA")   // --line-soft
    static let shadowColor   = Color(hex: "#4A6B9C").opacity(0.06)

    // ─── Risk (RiskLevel.color 와 호환) ────────────────────────
    static let riskSafe      = Color(hex: "#5DBB94")
    static let riskLow       = Color(hex: "#5BAA32")
    static let riskMedium    = Color(hex: "#CC8800")
    static let riskHigh      = Color(hex: "#C2553B")  // peachFg
    static let riskCritical  = Color(hex: "#A82020")

    static let riskSafeBg     = Color(hex: "#E3F5EC")  // greenSoft
    static let riskLowBg      = Color(hex: "#F0FAE6")
    static let riskMediumBg   = Color(hex: "#FFF1D1")  // butterSoft
    static let riskHighBg     = Color(hex: "#FFE8E0")  // peachSoft
    static let riskCriticalBg = Color(hex: "#FFE8E0")

    // ─── Hex initializer ─────────────────────────────────────
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        h = h.hasPrefix("#") ? String(h.dropFirst()) : h
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb         & 0xFF) / 255
        )
    }
}

// ─── View Modifiers ──────────────────────────────────────────
extension View {
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color(hex: "#4A6B9C").opacity(0.06), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.separatorSoft, lineWidth: 1)
            )
    }

    func primaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#3A5A8C"), Color(hex: "#4A6B9C")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.navyDeep.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    func secondaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.brandNavy)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.navySoft)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
