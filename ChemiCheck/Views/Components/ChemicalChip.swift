import SwiftUI

struct ChemicalChip: View {
    let chemical: Chemical
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(chemical.riskLevel.color)
                    .frame(width: 7, height: 7)
                Text(chemical.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text("Lv.\(chemical.riskLevel.rawValue)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(chemical.riskLevel.color)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(chemical.riskLevel.backgroundColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ChemicalListRow: View {
    let chemical: Chemical

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(chemical.riskLevel.backgroundColor)
                        .frame(width: 42, height: 42)
                    Text("\(chemical.riskLevel.rawValue)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(chemical.riskLevel.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(chemical.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(chemical.englishName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                RiskBadge(level: chemical.riskLevel, size: .small)
            }

            if !chemical.concerns.isEmpty {
                HStack(spacing: 5) {
                    ForEach(chemical.concerns.prefix(3), id: \.rawValue) { concern in
                        Text(concern.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(chemical.riskLevel.color)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(chemical.riskLevel.backgroundColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
