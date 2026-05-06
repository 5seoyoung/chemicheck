import SwiftUI

struct AlternativeCard: View {
    let alternative: Alternative
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.greenSoft)
                            .frame(width: 42, height: 42)
                        Image(systemName: alternative.imageSystemName)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.brandGreen)
                    }
                    Spacer()
                    RiskBadge(level: alternative.riskLevel, size: .small)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(alternative.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(alternative.brand)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer(minLength: 0)

                if let cert = alternative.certifications.first {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.brandGreen)
                        Text(cert.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.brandGreen)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.greenSoft)
                    .clipShape(Capsule())
                }

                Text(alternative.price)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(14)
            .frame(width: 165, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct CertificationBadge: View {
    let cert: CertificationType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.brandGreen)
            Text(cert.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.brandGreen)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Color.greenSoft)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.brandGreen.opacity(0.25), lineWidth: 1))
    }
}
