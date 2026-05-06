import SwiftUI

struct ProductCard: View {
    let product: Product
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 14) {
                // 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(product.riskLevel.backgroundColor)
                        .frame(width: 50, height: 50)
                    Image(systemName: product.imageSystemName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(product.riskLevel.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(product.brand)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                        Text("·")
                            .foregroundStyle(Color.textTertiary)
                        Text(product.category.rawValue)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textTertiary)
                    }
                    if !product.chemicals.isEmpty {
                        Text("성분 \(product.chemicals.count)개 분석")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.brandGreen)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    RiskBadge(level: product.riskLevel, size: .small)
                    if product.isRecalled {
                        Label("회수", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .background(Color.riskCritical)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct RecentScanCard: View {
    let product: Product
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(product.riskLevel.backgroundColor)
                            .frame(width: 40, height: 40)
                        Image(systemName: product.imageSystemName)
                            .font(.system(size: 16))
                            .foregroundStyle(product.riskLevel.color)
                    }
                    Spacer()
                    RiskBadge(level: product.riskLevel, size: .small)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(product.brand)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(12)
            .frame(width: 155)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
