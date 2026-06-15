import SwiftUI
import UIKit

struct MyPageView: View {
    @Environment(AppState.self) private var appState
    @State private var showProfileEdit = false
    @State private var titleTapCount = 0
    @State private var showDemoPanel = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Profile card
                    profileCard
                        .padding(.horizontal, 16)

                    // Stats row
                    statsRow
                        .padding(.horizontal, 16)

                    // Settings
                    settingsCard
                        .padding(.horizontal, 16)

                    // About
                    aboutCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "#F3FAF5").ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showProfileEdit) { ProfileEditView() }
        .sheet(isPresented: $showDemoPanel) { DemoModePanel() }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.brandNavy.opacity(0.15), Color.brandNavy.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(Color.brandNavy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("우리 가족")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text("🏠")
                    }
                    Text(appState.familyProfile.memberSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            Button { showProfileEdit = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil").font(.system(size: 12, weight: .semibold))
                    Text("가족 프로필 수정")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.brandNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.navySoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        // 숨김 제스처: 프로필 카드 상단 4회 탭 → 데모 패널
        .onTapGesture {
            titleTapCount += 1
            if titleTapCount >= 4 { titleTapCount = 0; showDemoPanel = true }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            miniStatCard(
                icon: "camera.viewfinder", color: Color.brandNavy,
                bg: Color.navySoft,
                value: "\(appState.recentProducts.count)",
                label: "진단 횟수"
            )
            miniStatCard(
                icon: "shippingbox.fill", color: Color.brandGreen,
                bg: Color.greenSoft,
                value: "\(appState.registeredProducts.count)",
                label: "등록 제품"
            )
            miniStatCard(
                icon: "bell.badge.fill", color: Color(hex: "#FF5252"),
                bg: Color(hex: "#FFE8E8"),
                value: "\(appState.registeredProducts.filter { $0.isRecalled }.count)",
                label: "회수 알림"
            )
        }
    }

    private func miniStatCard(icon: String, color: Color, bg: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bg).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("설정")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                settingsRow(icon: "person.3.fill", bg: Color.navySoft, iconColor: Color.brandNavy,
                            title: "가족 프로필 관리") { showProfileEdit = true }
                separator
                settingsRow(icon: "bell.fill", bg: Color(hex: "#FFF0E0"), iconColor: Color(hex: "#FF9845"),
                            title: "알림 설정") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                separator
                settingsRow(icon: "lock.fill", bg: Color.greenSoft, iconColor: Color.brandGreen,
                            title: "개인정보 처리방침") {
                    if let url = URL(string: "https://5seoyoung.github.io/chemicheck/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                separator
                settingsRow(icon: "doc.text.fill", bg: Color.lavenderSoft, iconColor: Color.lavender,
                            title: "이용약관") {
                    if let url = URL(string: "https://5seoyoung.github.io/chemicheck/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }
                separator
                settingsRow(icon: "questionmark.circle.fill", bg: Color.bgSecondary, iconColor: Color.textTertiary,
                            title: "고객 지원") {
                    if let url = URL(string: "mailto:inmani1555@gmail.com?subject=케미체크 문의") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private var separator: some View {
        Divider().padding(.leading, 56)
    }

    private func settingsRow(icon: String, bg: Color, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(bg).frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14)).foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.vertical, 13).padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - About Card

    private var aboutCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("케미").foregroundStyle(Color.brandNavy)
                Text("체크").foregroundStyle(Color.brandGreen)
            }
            .font(.system(size: 17, weight: .bold))

            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · MediX")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)

            Text("본 서비스는 참고 목적으로 제공됩니다.\n의료적 판단은 반드시 전문의 상담을 받으세요.")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            HStack(spacing: 8) {
                Text("식약처").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.textTertiary)
                    .padding(.vertical, 3).padding(.horizontal, 8)
                    .background(Color.bgSecondary).clipShape(Capsule())
                Text("환경부").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.textTertiary)
                    .padding(.vertical, 3).padding(.horizontal, 8)
                    .background(Color.bgSecondary).clipShape(Capsule())
                Text("에어코리아").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.textTertiary)
                    .padding(.vertical, 3).padding(.horizontal, 8)
                    .background(Color.bgSecondary).clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - 데모 모드 패널

struct DemoModePanel: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var isDemoOn = DemoModeManager.shared.isOn
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isDemoOn) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("데모 모드")
                                .font(.system(size: 15, weight: .semibold))
                            Text("카메라 캡처 → 시나리오 제품 자동 선택\nClaude API → 사전 캐시 응답")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .onChange(of: isDemoOn) { _, v in DemoModeManager.shared.isOn = v }
                } header: {
                    Text("시연 설정")
                } footer: {
                    Text("심사위원이 직접 조작 시 OFF로 전환하세요.")
                        .font(.system(size: 11))
                }

                Section("고정값 (데모 모드 ON 시)") {
                    demoRow(icon: "wind", color: .brandGreen, label: "에어코리아", value: "PM2.5 보통 · 환기 30분")
                    demoRow(icon: "exclamationmark.triangle.fill", color: .riskCritical, label: "회수 알림", value: "자동 트리거")
                    demoRow(icon: "sparkles", color: .brandNavy, label: "AI 상담", value: "사전 캐시 응답")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("앱 전체 초기화 (처음부터 시작)")
                                .font(.system(size: 15))
                        }
                    }

                    Button(role: .destructive) {
                        DemoModeManager.shared.isOn = false; isDemoOn = false
                    } label: { Text("데모 모드 OFF로 초기화").font(.system(size: 15)) }
                } footer: {
                    Text("전체 초기화 시 가족 프로필·등록 제품·최근 기록이 모두 삭제되고 온보딩 화면부터 다시 시작합니다.")
                        .font(.system(size: 11))
                }
            }
            .navigationTitle("개발자 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
            .confirmationDialog("앱 전체 초기화", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("초기화하고 처음부터 시작", role: .destructive) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appState.resetAll()
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("가족 프로필, 등록 제품, 최근 기록이 모두 삭제됩니다.")
            }
        }
    }

    private func demoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            Text(label).font(.system(size: 14))
            Spacer()
            Text(value).font(.system(size: 13)).foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - 데모 모드 매니저

final class DemoModeManager {
    static let shared = DemoModeManager()
    private init() {}

    var isOn: Bool {
        get {
            if ProcessInfo.processInfo.environment["DEMO_MODE_FORCE"] == "1" { return true }
            if UserDefaults.standard.object(forKey: "demoMode") == nil { return true }
            return UserDefaults.standard.bool(forKey: "demoMode")
        }
        set { UserDefaults.standard.set(newValue, forKey: "demoMode") }
    }
}

#Preview {
    MyPageView().environment(AppState())
}
