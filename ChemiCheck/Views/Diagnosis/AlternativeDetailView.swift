import SwiftUI
import UIKit

struct AlternativeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let alternative: Alternative

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    heroSection
                        .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        // Certifications
                        if !alternative.certifications.isEmpty {
                            certificationsCard
                        }

                        // Description
                        descriptionCard

                        // Purchase info
                        purchaseCard

                        // CTA
                        Button("구매하러 가기") {
                            let query = alternative.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://search.shopping.naver.com/search/all?query=\(query)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .primaryButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("대체재 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.brandGreen.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: alternative.imageSystemName)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.brandGreen)
            }
            .padding(.top, 32)

            VStack(spacing: 6) {
                Text(alternative.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(alternative.brand)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }

            RiskBadge(level: alternative.riskLevel, size: .medium)

            Text(alternative.price)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var certificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인증 정보")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            FlowLayout(spacing: 8) {
                ForEach(alternative.certifications, id: \.rawValue) { cert in
                    CertificationBadge(cert: cert)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("제품 설명")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text(alternative.description)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .cardStyle()
    }

    private var purchaseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("구매처")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: 8) {
                ForEach(alternative.availableAt, id: \.self) { store in
                    HStack(spacing: 4) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 11))
                        Text(store)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.brandNavy)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.brandNavy.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    let alt = DummyDataLoader.shared.alternatives.first!
    AlternativeDetailView(alternative: alt)
}
