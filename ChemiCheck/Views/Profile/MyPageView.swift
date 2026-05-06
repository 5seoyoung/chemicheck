import SwiftUI

struct MyPageView: View {
    @Environment(AppState.self) private var appState
    @State private var showProfileEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile summary
                    profileHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    // Stats
                    statsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Settings sections
                    settingsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // About
                    aboutSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditView()
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.brandNavy.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.brandNavy)
            }

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("우리 가족")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    TFIcon.home(size: 24)
                }

                Text(appState.familyProfile.memberSummary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showProfileEdit = true
            } label: {
                Label("가족 프로필 수정", systemImage: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.brandNavy)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.brandNavy.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardStyle()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이용 현황")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                statCard(
                    value: "\(appState.recentProducts.count)",
                    label: "진단 횟수",
                    icon: "camera.viewfinder",
                    color: .brandNavy
                )
                statCard(
                    value: "\(appState.registeredProducts.count)",
                    label: "등록 제품",
                    icon: "shippingbox.fill",
                    color: .brandGreen
                )
                statCard(
                    value: "\(appState.registeredProducts.filter { $0.isRecalled }.count)",
                    label: "회수 알림",
                    icon: "bell.badge.fill",
                    color: .riskCritical
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("설정")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                settingsRow(icon: "person.3.fill", color: .brandNavy, title: "가족 프로필 관리") {
                    showProfileEdit = true
                }
                Divider().padding(.leading, 52)
                settingsRow(icon: "bell.fill", color: .riskMedium, title: "알림 설정") {}
                Divider().padding(.leading, 52)
                settingsRow(icon: "lock.fill", color: .brandGreen, title: "개인정보 처리방침") {}
                Divider().padding(.leading, 52)
                settingsRow(icon: "questionmark.circle.fill", color: .textTertiary, title: "고객 지원") {}
            }
            .cardStyle()
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Text("케미").foregroundStyle(Color.brandNavy)
                    Text("체크").foregroundStyle(Color.brandGreen)
                }
                .font(.system(size: 16, weight: .bold))
                Text("v1.0.0 · MediX")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            Text("본 서비스는 참고 목적으로 제공됩니다.\n의료적 판단은 전문의 상담을 받으세요.")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}

#Preview {
    MyPageView()
        .environment(AppState())
}
