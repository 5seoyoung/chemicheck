import SwiftUI

struct RiskBadge: View {
    let level: RiskLevel
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self { case .small: 12; case .medium: 16; case .large: 28 }
        }
        var levelFont: Font {
            switch self {
            case .small:  .system(size: 9, weight: .bold)
            case .medium: .system(size: 12, weight: .bold)
            case .large:  .system(size: 17, weight: .bold)
            }
        }
        var labelFont: Font {
            switch self {
            case .small:  .system(size: 11, weight: .bold)
            case .medium: .system(size: 14, weight: .bold)
            case .large:  .system(size: 18, weight: .bold)
            }
        }
        var hPad: CGFloat {
            switch self { case .small: 8; case .medium: 12; case .large: 18 }
        }
        var vPad: CGFloat {
            switch self { case .small: 4; case .medium: 7; case .large: 12 }
        }
        var radius: CGFloat {
            switch self { case .small: 8; case .medium: 11; case .large: 14 }
        }
    }

    var body: some View {
        HStack(spacing: size == .small ? 4 : 6) {
            Image(systemName: level.icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(level.color)

            Text(level.label)
                .font(size.labelFont)
                .foregroundStyle(level.color)
        }
        .padding(.vertical, size.vPad)
        .padding(.horizontal, size.hPad)
        .background(level.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: size.radius, style: .continuous))
    }
}

// 5단계 세그먼트 바
struct RiskLevelBar: View {
    let level: RiskLevel
    var width: CGFloat = 140

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                let active = i <= level.rawValue
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(active ? riskColor(i) : Color.separator)
                    .frame(width: (width - 16) / 5, height: 8)
                    .animation(.easeInOut(duration: 0.3).delay(Double(i) * 0.07), value: level)
            }
        }
        .frame(width: width)
    }

    private func riskColor(_ i: Int) -> Color {
        switch i {
        case 1: return Color.riskSafe
        case 2: return Color.riskLow
        case 3: return Color.riskMedium
        case 4: return Color.riskHigh
        default: return Color.riskCritical
        }
    }
}

// 큰 원형 위험도 표시
struct RiskCircleIndicator: View {
    let level: RiskLevel
    var size: CGFloat = 100
    @State private var animateTrim: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(level.backgroundColor)
                .frame(width: size, height: size)

            Circle()
                .stroke(level.color.opacity(0.15), lineWidth: 6)
                .frame(width: size - 10, height: size - 10)

            Circle()
                .trim(from: 0, to: animateTrim)
                .stroke(level.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: size - 10, height: size - 10)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: level.icon)
                    .font(.system(size: size * 0.28, weight: .semibold))
                    .foregroundStyle(level.color)
                Text("\(level.rawValue)단계")
                    .font(.system(size: size * 0.13, weight: .bold))
                    .foregroundStyle(level.color)
                Text(level.label)
                    .font(.system(size: size * 0.115, weight: .semibold))
                    .foregroundStyle(level.color.opacity(0.8))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateTrim = CGFloat(level.rawValue) / 5.0
            }
        }
        .onChange(of: level) {
            animateTrim = 0
            withAnimation(.easeOut(duration: 0.6)) {
                animateTrim = CGFloat(level.rawValue) / 5.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 8) {
            ForEach(RiskLevel.allCases, id: \.rawValue) { level in
                RiskBadge(level: level, size: .small)
            }
        }
        ForEach(RiskLevel.allCases, id: \.rawValue) { level in
            RiskBadge(level: level, size: .medium)
        }
        HStack(spacing: 20) {
            ForEach(RiskLevel.allCases, id: \.rawValue) { level in
                RiskCircleIndicator(level: level, size: 80)
            }
        }
        RiskLevelBar(level: .high)
    }
    .padding()
    .background(Color.bgPrimary)
}
