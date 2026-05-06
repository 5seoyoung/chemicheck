import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showCamera = false
    @State private var showDiagnosis = false
    @State private var diagnosisVM = DiagnosisViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var gaugeProgress: CGFloat = 0

    private var safetyScore: Int {
        let products = appState.registeredProducts.isEmpty
            ? Array(DummyDataLoader.shared.products.prefix(4))
            : appState.registeredProducts
        if products.isEmpty { return 87 }
        let avg = Double(products.map(\.riskLevel.rawValue).reduce(0, +)) / Double(products.count)
        return max(0, min(100, Int(100 - (avg - 1) * 22)))
    }

    private var allProducts: [Product] { DummyDataLoader.shared.products }
    private var warnCount: Int { allProducts.filter { $0.riskLevel.rawValue >= 3 }.count }
    private var safeCount: Int { allProducts.filter { $0.riskLevel.rawValue <= 2 }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                // ── 라디얼 그라디언트 배경 (HTML s1-bg 재현) ──
                screenBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        headerSection
                            .padding(.horizontal, 18)
                            .padding(.top, 8)

                        scoreCard
                            .padding(.horizontal, 14)

                        quickCards
                            .padding(.horizontal, 14)

                        exposureMapCard
                            .padding(.horizontal, 14)

                        if !appState.recentProducts.isEmpty {
                            recentSection
                        }

                        productListSection
                            .padding(.horizontal, 14)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCamera) {
            CameraView { product in
                diagnosisVM.loadProduct(product, for: appState.familyProfile)
                appState.addRecentProduct(product)
                showCamera = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showDiagnosis = true }
            }
        }
        .sheet(isPresented: $showDiagnosis) {
            if let p = diagnosisVM.currentProduct {
                DiagnosisResultView(
                    product: p,
                    adjustedRiskLevel: diagnosisVM.adjustedRiskLevel ?? p.riskLevel,
                    familyWarnings: diagnosisVM.familyWarnings,
                    alternatives: diagnosisVM.alternatives
                )
            }
        }
        .sheet(item: $selectedProduct) { p in
            DiagnosisResultView(
                product: p,
                adjustedRiskLevel: p.riskLevel,
                familyWarnings: [],
                alternatives: p.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 1.4, dampingFraction: 0.8).delay(0.25)) {
                gaugeProgress = CGFloat(safetyScore) / 100.0
            }
        }
    }

    // MARK: - 배경 (HTML: radial-gradient at 20% top & 100% top)

    private var screenBackground: some View {
        ZStack {
            Color.bgPrimary

            // 왼쪽 상단 녹색 클라우드 (--green-soft)
            Circle()
                .fill(Color.greenSoft.opacity(0.8))
                .frame(width: 360, height: 260)
                .blur(radius: 72)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -80, y: -80)

            // 오른쪽 상단 라벤더 클라우드 (--lavender-soft)
            Circle()
                .fill(Color.lavenderSoft.opacity(0.65))
                .frame(width: 320, height: 240)
                .blur(radius: 68)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 80, y: -70)
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("안녕하세요, 지영님")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                Text("우리집 안전 점수")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .kerning(-0.5)
                HStack(spacing: 4) {
                    Text("이번 주도 좋아요")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.greenDeep)
                    TFIcon.sparkle(size: 18)
                }
                .font(.system(size: 15))
            }

            Spacer()

            // 벨 버튼 (white card + 알림 dot)
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.bgCard)
                    .frame(width: 38, height: 38)
                    .shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)

                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.navyDeep)
                    .frame(width: 38, height: 38)

                if appState.notificationBadgeCount > 0 {
                    Circle()
                        .fill(Color.peach)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.bgCard, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }
        }
    }

    // MARK: - Safety Score Card (HTML: .s1-score)

    private var scoreCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 원형 링 게이지
                ZStack {
                    Circle()
                        .stroke(Color.greenSoft, lineWidth: 9)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: gaugeProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.brandGreen, Color.greenDeep],
                                startPoint: .topTrailing, endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(safetyScore)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.greenDeep)
                        Text("/ 100")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("SAFETY SCORE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.greenDeep)
                        .kerning(1.0)

                    Text("매우 안전")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .kerning(-0.3)

                    Text("우리집 안전성이\n상위 12% 수준이에요")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(2)
                }

                Spacer()
            }
            .padding(18)

            // 트렌드 바 (점선 구분)
            Rectangle()
                .fill(Color.greenSoft)
                .frame(height: 1)
                .padding(.horizontal, 18)

            HStack {
                Text("지난주 대비")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                    Text("+5점 상승")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.greenDeep)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        // HTML: linear-gradient(135deg, #FFFFFF 0%, --green-mist 100%) + border 1px green-soft
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.bgCard, Color.greenMist],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                // 오른쪽 상단 글로우 (HTML ::before 재현)
                Circle()
                    .fill(Color.greenSoft.opacity(0.7))
                    .frame(width: 130, height: 130)
                    .blur(radius: 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 40, y: -40)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.greenSoft, lineWidth: 1)
        )
        .shadow(color: Color(hex: "#4A6B9C").opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Quick Cards 2개 (HTML: .s1-quick)

    private var quickCards: some View {
        HStack(spacing: 8) {
            // 주의 필요 (peach)
            quickCard(
                iconSF: "exclamationmark.circle",
                iconFg: Color.peachFg,
                iconBg: Color.peachSoft,
                value: "\(warnCount)",
                unit: "건",
                label: "주의 필요",
                barColor: Color.peach,
                barFraction: Double(warnCount) / Double(max(allProducts.count, 1))
            )
            // 안전 제품 (sky)
            quickCard(
                iconSF: "checkmark",
                iconFg: Color.skyFg,
                iconBg: Color.skySoft,
                value: "\(safeCount)",
                unit: "건",
                label: "안전 제품",
                barColor: Color.sky,
                barFraction: Double(safeCount) / Double(max(allProducts.count, 1))
            )
        }
    }

    private func quickCard(iconSF: String, iconFg: Color, iconBg: Color,
                           value: String, unit: String, label: String,
                           barColor: Color, barFraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 아이콘 (HTML: .s1-quick-icon, 28x28, radius 9px)
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 30, height: 30)
                Image(systemName: iconSF)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconFg)
            }
            .padding(.bottom, 8)

            // 숫자 (HTML: JetBrains Mono 17px)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.bottom, 2)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.textSecondary)
                .padding(.bottom, 8)

            // 얇은 바 (HTML: h:3px)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.separatorSoft).frame(height: 3)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * min(barFraction, 1), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.separatorSoft, lineWidth: 1)
        )
        .shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)
    }

    // MARK: - 우리집 노출 맵 (HTML: .s1-map, .s1-rooms 2x2 grid)

    private struct Room {
        let icon: AnyView
        let name: String
        let status: String
        let dotColor: Color
    }

    private var rooms: [Room] {[
        Room(icon: AnyView(TFIcon.bathroom(size: 28)), name: "욕실",   status: "주의 1건", dotColor: .peach),
        Room(icon: AnyView(TFIcon.kitchen(size: 28)),  name: "주방",   status: "안전",     dotColor: .brandGreen),
        Room(icon: AnyView(TFIcon.babyRoom(size: 28)), name: "아기방", status: "안전",     dotColor: .brandGreen),
        Room(icon: AnyView(TFIcon.laundry(size: 28)),  name: "세탁실", status: "주의 1건", dotColor: .butter),
    ]}

    private var exposureMapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("우리집 노출 맵")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("실시간")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.greenDeep)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.greenSoft)
                    .clipShape(Capsule())
            }

            // HTML: grid-template-columns: 1fr 1fr, gap 6px
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(rooms, id: \.name) { room in
                    roomCell(room)
                }
            }
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.separatorSoft, lineWidth: 1)
        )
        .shadow(color: Color.shadowColor, radius: 6, x: 0, y: 2)
    }

    // HTML: .s1-room { background: var(--surface-2); border-radius: 10px; padding: 8px 10px; }
    private func roomCell(_ room: Room) -> some View {
        HStack(spacing: 8) {
            room.icon

            VStack(alignment: .leading, spacing: 1) {
                Text(room.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(room.status)
                    .font(.system(size: 8.5))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(room.dotColor)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.bgSurface2)  // --surface-2: #F5F7FB
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - 최근 진단

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("최근 진단")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("전체 보기") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brandNavy)
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.recentProducts.prefix(6)) { p in
                        RecentScanCard(product: p) { selectedProduct = p }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - 제품 리스트

    private var productListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("제품 탐색")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("식약처 독성 DB")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.greenDeep)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.greenSoft)
                    .clipShape(Capsule())
            }

            LazyVStack(spacing: 8) {
                ForEach(allProducts) { product in
                    ProductCard(product: product) {
                        diagnosisVM.loadProduct(product, for: appState.familyProfile)
                        appState.addRecentProduct(product)
                        selectedProduct = product
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView().environment(AppState())
}
