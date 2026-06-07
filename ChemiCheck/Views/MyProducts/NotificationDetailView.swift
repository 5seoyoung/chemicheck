import SwiftUI
import UIKit

struct NotificationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let notification: RecallNotification

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Severity banner
                    severityBanner

                    // Product info
                    productInfoCard

                    // Recall reason
                    recallReasonCard

                    // Immediate actions
                    immediateActionsCard

                    // Refund guide
                    refundGuideCard

                    // CTA Buttons
                    ctaButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationTitle("회수 고시 알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        appState.clearRecallNotification()
                        dismiss()
                    }
                }
            }
            .onAppear {
                appState.clearRecallNotification()
            }
        }
    }

    private var severityBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 36))
                .foregroundStyle(notification.severity.color)

            VStack(alignment: .leading, spacing: 4) {
                Text("회수·판매중지 고시")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(notification.severity.color)
                Text("즉시 사용을 중단해 주세요")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(notification.date.formatted(date: .long, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(notification.severity.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(notification.severity.color.opacity(0.4), lineWidth: 1.5)
        )
    }

    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("대상 제품")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.riskCritical.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: notification.product.imageSystemName)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.riskCritical)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.product.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(notification.product.brand)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                    Text(notification.product.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            HStack {
                Label(notification.agencyName, systemImage: "building.columns.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brandNavy)
                Text("회수 명령")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var recallReasonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("회수 사유", systemImage: "doc.text.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text(notification.reason)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .cardStyle()
    }

    private var immediateActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("즉시 조치 사항", systemImage: "exclamationmark.shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.riskCritical)

            VStack(spacing: 8) {
                actionRow(number: "1", text: "즉시 사용을 중단하세요", color: .riskCritical)
                actionRow(number: "2", text: "어린이 손에 닿지 않는 곳에 보관하세요", color: .riskHigh)
                actionRow(number: "3", text: "창문을 열어 충분히 환기하세요", color: .riskMedium)
                actionRow(number: "4", text: "이상 증상 발생 시 즉시 119 또는 병원을 방문하세요", color: .riskMedium)
            }
        }
        .padding(16)
        .background(Color.riskCritical.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.riskCritical.opacity(0.2), lineWidth: 1)
        )
    }

    private func actionRow(number: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(color)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }

    private var refundGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("환불 안내", systemImage: "creditcard.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text(notification.refundGuide)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .cardStyle()
    }

    private var ctaButtons: some View {
        VStack(spacing: 10) {
            Button {
                let phoneNumber = extractPhoneNumber(from: notification.refundGuide)
                if let url = URL(string: "tel://\(phoneNumber)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("제조사 고객센터 연결", systemImage: "phone.fill")
            }
            .primaryButton()

            Button { dismiss() } label: { Text("확인") }
            .secondaryButton()
        }
    }

    private func extractPhoneNumber(from text: String) -> String {
        let components = text.components(separatedBy: " / ")
        let first = components.first ?? text
        return first.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}

#Preview {
    let product = DummyDataLoader.shared.products.first(where: { $0.id == "prod_006" })!
    NotificationDetailView(
        notification: RecallNotification(
            product: product,
            reason: "차아염소산나트륨 농도가 허용 기준(4%)을 초과하여 환경부 회수 명령이 내려졌습니다.",
            date: Date(),
            severity: .critical,
            refundGuide: "구매처에서 영수증 없이 전액 환불 가능합니다.",
            agencyName: "환경부"
        )
    )
}
