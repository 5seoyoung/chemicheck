import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showCamera = false
    @State private var showAIChat = false
    @State private var showDiagnosis = false
    @State private var diagnosisVM = DiagnosisViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var gaugeProgress: CGFloat = 0

    // MARK: - Computed

    private var safetyScore: Int {
        let products = appState.registeredProducts.isEmpty
            ? Array(DummyDataLoader.shared.products.prefix(4))
            : appState.registeredProducts
        if products.isEmpty { return 87 }
        let avg = Double(products.map(\.riskLevel.rawValue).reduce(0, +)) / Double(products.count)
        return max(0, min(100, Int(100 - (avg - 1) * 22)))
    }
    private var scoreLabel: String {
        switch safetyScore {
        case 90...100: return "매우 안전"
        case 75..<90:  return "안전"
        case 55..<75:  return "보통"
        case 35..<55:  return "주의 필요"
        default:       return "위험"
        }
    }
    private var scoreColor: Color {
        switch safetyScore {
        case 75...100: return Color.brandGreen
        case 55..<75:  return Color(hex: "#FF9845")
        default:       return Color(hex: "#FF5252")
        }
    }
    private var warnCount: Int  { appState.registeredProducts.filter { $0.riskLevel.rawValue >= 3 }.count }
    private var safeCount: Int  { appState.registeredProducts.filter { $0.riskLevel.rawValue <= 2 }.count }
    private var totalCount: Int { max(appState.registeredProducts.count, 1) }
    private var recallCount: Int { appState.notificationBadgeCount }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)

                    heroCameraCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                    scoreCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                    quickStatsRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                    exposureMapSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                    if !appState.recentProducts.isEmpty {
                        recentSection
                            .padding(.bottom, 20)
                    }

                    alternativesSection
                        .padding(.bottom, 20)

                    aiBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 110)
                }
            }
            .background(Color(hex: "#F3FAF5").ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(
                onCapture: { image in
                    showCamera = false
                    diagnosisVM.reset()
                    diagnosisVM.isAnalyzing = true
                    showDiagnosis = true
                    Task {
                        await diagnosisVM.analyzeImage(image, for: appState.familyProfile)
                        if let p = diagnosisVM.currentProduct { appState.addRecentProduct(p) }
                    }
                },
                onDemoSelect: { product in
                    diagnosisVM.loadProduct(product, for: appState.familyProfile)
                    appState.addRecentProduct(product)
                    showCamera = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showDiagnosis = true }
                }
            )
        }
        .sheet(isPresented: $showDiagnosis) {
            if let p = diagnosisVM.currentProduct {
                DiagnosisResultView(product: p,
                    adjustedRiskLevel: diagnosisVM.adjustedRiskLevel ?? p.riskLevel,
                    familyWarnings: diagnosisVM.familyWarnings,
                    alternatives: diagnosisVM.alternatives)
            } else if diagnosisVM.isAnalyzing {
                AnalyzingView(step: diagnosisVM.analysisStep)
            }
        }
        .sheet(item: $selectedProduct) { p in
            DiagnosisResultView(product: p, adjustedRiskLevel: p.riskLevel, familyWarnings: [],
                alternatives: p.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) })
        }
        .sheet(isPresented: $showAIChat) { ChatAgentView() }
        .onAppear { animateScore() }
        .onChange(of: appState.registeredProducts.count) { animateScore() }
    }

    private func animateScore() {
        withAnimation(.spring(response: 1.4, dampingFraction: 0.8).delay(0.15)) {
            gaugeProgress = CGFloat(safetyScore) / 100.0
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("안녕하세요 👋")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                Text("오늘도 안전한 하루 보내세요!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .kerning(-0.3)
            }
            Spacer()
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Button { appState.selectedTab = 1 } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    if recallCount > 0 {
                        ZStack {
                            Circle().fill(Color(hex: "#FF5252")).frame(width: 18, height: 18)
                            Text("\(min(recallCount, 9))").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        }
                        .offset(x: 3, y: -3)
                    }
                }
                Circle()
                    .fill(Color.brandNavy.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.brandNavy)
                    )
            }
        }
    }

    // MARK: - Hero Camera Card

    private var heroCameraCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("가장 빠른 진단 방법")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.brandGreen)
                .padding(.vertical, 4).padding(.horizontal, 10)
                .background(Color.white.opacity(0.65))
                .clipShape(Capsule())

                Text("사진 한 장으로\n진단하기")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "#1A3A2A"))
                    .lineSpacing(2)

                Text("라벨을 찍으면 AI가 성분을 분석해\n가족 맞춤 위험도를 알려드려요.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#3A6A4A"))
                    .lineSpacing(2)

                Button { showCamera = true } label: {
                    Label("촬영하기", systemImage: "camera.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 11).padding(.horizontal, 20)
                        .background(Color.brandGreen)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandGreen.opacity(0.45), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.leading, 20).padding(.vertical, 20)

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 88, height: 88)
                    .blur(radius: 2)
                Image(systemName: "camera.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.brandGreen)
                    .shadow(color: Color.brandGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 16)
        }
        .background(
            LinearGradient(colors: [Color(hex: "#DDF5E9"), Color(hex: "#C4ECDA")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.brandGreen.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        HStack(spacing: 18) {
            // Speedometer gauge
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.greenSoft, lineWidth: 9)
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: 0.75 * gaugeProgress)
                    .stroke(
                        LinearGradient(colors: [Color.brandGreen, Color(hex: "#1A9060")],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(135))
                    .animation(.spring(response: 1.4, dampingFraction: 0.8).delay(0.15), value: gaugeProgress)
                VStack(spacing: 1) {
                    Text("\(safetyScore)")
                        .font(.system(size: 23, weight: .bold, design: .monospaced))
                        .foregroundStyle(scoreColor)
                    Text("/100")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.textTertiary)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 11))
                        .foregroundStyle(scoreColor)
                }
                .offset(y: 6)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Text("✨")
                    Text(scoreLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(scoreColor)
                }
                .padding(.vertical, 3).padding(.horizontal, 9)
                .background(Color.greenSoft)
                .clipShape(Capsule())

                Text("\(scoreLabel)해요!")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .kerning(-0.2)

                Text("우리집 등록 제품 평균 위험도 기준")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 3) {
                    Image(systemName: "arrow.up").font(.system(size: 9, weight: .bold))
                    Text("지난주 대비 +5")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.brandGreen)
                .padding(.vertical, 3).padding(.horizontal, 8)
                .background(Color.greenSoft)
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            Button { appState.selectedTab = 1 } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            quickStatCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color(hex: "#FF9845"), iconBg: Color(hex: "#FFF0E0"),
                value: appState.registeredProducts.isEmpty ? "-" : "\(warnCount)개",
                label: "주의 필요 제품",
                sub: appState.registeredProducts.isEmpty ? "등록 후 확인" : "전체의 \(Int(Double(warnCount)/Double(totalCount)*100))%",
                barColor: Color(hex: "#FF9845"),
                fraction: Double(warnCount) / Double(totalCount)
            )
            quickStatCard(
                icon: "checkmark.shield.fill",
                iconColor: Color(hex: "#4A8FD9"), iconBg: Color(hex: "#E0EEFA"),
                value: appState.registeredProducts.isEmpty ? "-" : "\(safeCount)개",
                label: "안전 제품",
                sub: appState.registeredProducts.isEmpty ? "등록 후 확인" : "전체의 \(Int(Double(safeCount)/Double(totalCount)*100))%",
                barColor: Color(hex: "#4A8FD9"),
                fraction: Double(safeCount) / Double(totalCount)
            )
            quickStatCard(
                icon: "megaphone.fill",
                iconColor: Color(hex: "#FF5252"), iconBg: Color(hex: "#FFE8E8"),
                value: "\(recallCount)건",
                label: "회수 알림",
                sub: recallCount > 0 ? "새로운 회수 고시" : "이상 없음",
                barColor: Color(hex: "#FF5252"),
                fraction: recallCount > 0 ? 1.0 : 0.0
            )
        }
    }

    private func quickStatCard(icon: String, iconColor: Color, iconBg: Color,
                               value: String, label: String, sub: String,
                               barColor: Color, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBg).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16)).foregroundStyle(iconColor)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            Text(sub)
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
                .lineLimit(1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.separatorSoft).frame(height: 4)
                    Capsule().fill(barColor)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Exposure Map

    private struct RoomInfo {
        let icon: String; let name: String; let count: Int; let dot: Color
    }
    private var rooms: [RoomInfo] {[
        RoomInfo(icon: "bathtub.fill",   name: "욕실",   count: 8, dot: Color(hex: "#FF9845")),
        RoomInfo(icon: "fork.knife",     name: "주방",   count: 6, dot: Color.brandGreen),
        RoomInfo(icon: "bed.double.fill",name: "아기방", count: 4, dot: Color(hex: "#FFD966")),
        RoomInfo(icon: "washer.fill",    name: "세탁실", count: 5, dot: Color(hex: "#FF9845")),
    ]}

    private var exposureMapSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 5) {
                    Text("우리집 노출 맵")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
                Button { appState.selectedTab = 1 } label: {
                    Text("전체 보기 >")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.brandNavy)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(rooms, id: \.name) { room in
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: "#E6F3F5"))
                                .frame(width: 42, height: 42)
                            Image(systemName: room.icon)
                                .font(.system(size: 19))
                                .foregroundStyle(Color(hex: "#5BA4B0"))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(room.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text("\(room.count)개 제품")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.textTertiary)
                        }
                        Spacer(minLength: 0)
                        Circle().fill(room.dot).frame(width: 9, height: 9)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color(hex: "#F4F9FA"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(hex: "#EAF7F9").opacity(0.5), Color.white],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("최근 진단")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                NavigationLink {
                    RecentProductsView()
                } label: {
                    Text("전체 보기 >")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.brandNavy)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.recentProducts.prefix(6)) { p in
                        recentCard(p)
                            .onTapGesture { selectedProduct = p }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func recentCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(product.riskLevel.backgroundColor)
                    .frame(width: 66, height: 66)
                Image(systemName: product.imageSystemName)
                    .font(.system(size: 30))
                    .foregroundStyle(product.riskLevel.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(product.brand)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }
            Text(product.riskLevel.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(product.riskLevel.color)
                .padding(.vertical, 3).padding(.horizontal, 8)
                .background(product.riskLevel.backgroundColor)
                .clipShape(Capsule())
            if let d = product.scanDate {
                Text(d, format: .dateTime.month().day())
                    .font(.system(size: 9))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(width: 94)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Alternatives

    private var alternativesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("안전한 대체재 추천")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("전체 보기 >")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brandNavy)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DummyDataLoader.shared.alternatives.prefix(6)) { alt in
                        alternativeCard(alt)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func alternativeCard(_ alt: Alternative) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.greenSoft)
                        .frame(width: 66, height: 66)
                    Image(systemName: alt.imageSystemName)
                        .font(.system(size: 28))
                        .foregroundStyle(Color.brandGreen)
                }
                if alt.certifications.contains(.ecoLabel) {
                    Text("환경표지")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 2).padding(.horizontal, 5)
                        .background(Color.brandGreen)
                        .clipShape(Capsule())
                        .offset(x: -2, y: -7)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(alt.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(alt.brand)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }
            Text("안전")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.brandGreen)
                .padding(.vertical, 3).padding(.horizontal, 8)
                .background(Color.greenSoft)
                .clipShape(Capsule())
        }
        .frame(width: 94)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - AI Banner

    private var aiBanner: some View {
        Button { appState.selectedTab = 2 } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.lavenderSoft).frame(width: 52, height: 52)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 24)).foregroundStyle(Color.lavender)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("궁금한 성분이 있나요?")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Color.navyDeep)
                    Text("AI 안전 코치가 쉽고 친절하게 알려드려요")
                        .font(.system(size: 11)).foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Text("AI 상담하기 >")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.lavender)
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(Color.lavenderSoft)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(LinearGradient(colors: [Color.lavenderMist, Color.white],
                                       startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.lavender.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView().environment(AppState())
}
