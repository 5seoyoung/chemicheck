import SwiftUI

struct DiagnosisResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let product: Product
    let adjustedRiskLevel: RiskLevel
    let familyWarnings: [String]
    let alternatives: [Alternative]

    @State private var selectedAlternative: Alternative? = nil
    @State private var showChemicalDetail: Chemical? = nil
    @State private var isRegistered = false
    @State private var riskBarAnimated: CGFloat = 0
    @State private var airQuality: AirKoreaAPIService.AirQualityInfo? = nil
    @State private var showAIChat = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 제품 정보 카드
                    productHeaderCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 14)

                    // 우리집 위험도 카드
                    riskCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // 검출 화학물질
                    chemicalsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // 사용 가이드
                    usageGuideSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // 대체재
                    if !alternatives.isEmpty {
                        alternativesSection
                            .padding(.bottom, 20)
                    }

                    // AI 상담 버튼
                    aiChatButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                    // 등록 버튼
                    registerButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("진단 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.bgSecondary)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { shareProduct() } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.brandNavy)
                    }
                }
            }
        }
        .sheet(item: $selectedAlternative) { alt in
            AlternativeDetailView(alternative: alt)
        }
        .sheet(item: $showChemicalDetail) { chem in
            ChemicalDetailSheet(chemical: chem)
        }
        .sheet(isPresented: $showAIChat) {
            ChatAgentView(contextProduct: product)
        }
        .onAppear {
            isRegistered = appState.registeredProducts.contains(where: { $0.id == product.id })
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.15)) {
                riskBarAnimated = CGFloat(adjustedRiskLevel.rawValue) / 5.0
            }
            Task {
                airQuality = await AirKoreaAPIService.shared.fetchAirQuality()
            }
        }
    }

    // MARK: - 제품 정보 카드

    private var productHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.bgSecondary)
                    .frame(width: 56, height: 56)
                Image(systemName: product.imageSystemName)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.brandNavy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(product.category.rawValue) · \(product.brand)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - 우리집 위험도 카드

    private var riskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("우리집 위험도")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(adjustedRiskLevel.color)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(adjustedRiskLevel.rawValue)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(adjustedRiskLevel.color)
                    Text("/5")
                        .font(.system(size: 16))
                        .foregroundStyle(adjustedRiskLevel.color.opacity(0.55))
                }
            }

            // 5단계 세그먼트 바
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { i in
                    Capsule()
                        .fill(i <= adjustedRiskLevel.rawValue
                              ? segmentColor(i)
                              : Color.separator)
                        .frame(height: 7)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.06), value: riskBarAnimated)
                }
            }

            // 가족 경고 문구
            if !familyWarnings.isEmpty || !appState.familyProfile.vulnerableGroups.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text(adjustedRiskLevel.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(adjustedRiskLevel.color)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(adjustedRiskLevel.backgroundColor)
                        .clipShape(Capsule())

                    Text(familyWarnings.first ?? adjustedRiskLevel.familyWarning)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [adjustedRiskLevel.backgroundColor, adjustedRiskLevel.backgroundColor.opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func segmentColor(_ i: Int) -> Color {
        switch i {
        case 1: return Color.riskSafe
        case 2: return Color.riskLow
        case 3: return Color.riskMedium
        case 4: return Color.riskHigh
        default: return Color.riskCritical
        }
    }

    // MARK: - 검출 화학물질

    private var chemicalsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("검출 화학물질")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("식약처 독성 DB")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(product.chemicals.enumerated()), id: \.element.id) { idx, chem in
                    if idx > 0 { Divider() }
                    chemicalRow(chem)
                        .onTapGesture { showChemicalDetail = chem }
                }
            }
            .cardStyle()
        }
    }

    private func chemicalRow(_ chemical: Chemical) -> some View {
        HStack(spacing: 12) {
            Text(chemical.name)
                .font(.system(size: 14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(chemical.riskLevel.badgeLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(chemical.riskLevel.color)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(chemical.riskLevel.backgroundColor)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - 사용 가이드

    private var usageGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("사용 가이드")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.brandNavy)
                        .font(.system(size: 16))
                    Text(product.usageGuide)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                }
                .padding(14)
                .cardStyle()

                if product.ventilationMinutes > 0 {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.riskSafeBg)
                                .frame(width: 40, height: 40)
                            Image(systemName: "wind")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.brandGreen)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("권장 환기 시간")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                            Text("최소 \(product.ventilationMinutes)분")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.brandGreen)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .cardStyle()
                }

                // 에어코리아 대기질 (Tier 2.2)
                if let aq = airQuality {
                    HStack(spacing: 10) {
                        Image(systemName: aq.isGoodForVentilation ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(aq.isGoodForVentilation ? Color.brandGreen : Color.riskMedium)
                        Text(aq.ventilationMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("에어코리아")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(12)
                    .background(aq.isGoodForVentilation ? Color.greenMist : Color.butterMist)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: - 대체재

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("더 안전한 대체재")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("전체 보기")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.brandNavy)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(alternatives) { alt in
                        AlternativeCard(alternative: alt) { selectedAlternative = alt }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - 공유

    private func shareProduct() {
        let riskText = "위험도 \(adjustedRiskLevel.rawValue)/5단계 (\(adjustedRiskLevel.label))"
        let chemText = product.chemicals.isEmpty ? "" : "\n주요 성분: \(product.chemicals.prefix(3).map(\.name).joined(separator: ", "))"
        let text = "케미체크 진단 결과\n\n제품: \(product.name) (\(product.brand))\n\(riskText)\(chemText)\n\n자세한 성분 정보는 케미체크 앱에서 확인하세요."
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = windowScene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }

    // MARK: - AI 상담 버튼

    private var aiChatButton: some View {
        Button {
            showAIChat = true
        } label: {
            HStack(spacing: 10) {
                TFIcon.aiAvatar(size: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("이 제품에 대해 AI에게 물어보기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.lavender)
                    Text("임신·영유아·반려동물 관련 질문 즉시 답변")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lavender.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lavender.opacity(0.5))
            }
            .padding(16)
            .background(Color.lavenderSoft)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.lavender.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 등록 버튼

    private var registerButton: some View {
        Button {
            if isRegistered {
                appState.unregisterProduct(product)
                isRegistered = false
            } else {
                appState.registerProduct(product)
                isRegistered = true
            }
        } label: {
            Label(
                isRegistered ? "내 제품에서 제거" : "내 제품으로 등록하기",
                systemImage: isRegistered ? "minus.circle" : "plus.circle.fill"
            )
        }
        .primaryButton()
        .opacity(isRegistered ? 0.65 : 1.0)
    }
}

// MARK: - Chemical Detail Sheet

struct ChemicalDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chemical: Chemical

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(chemical.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text(chemical.englishName)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                        Text("CAS \(chemical.casNumber)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textTertiary)
                        Text(chemical.riskLevel.badgeLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(chemical.riskLevel.color)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                            .background(chemical.riskLevel.backgroundColor)
                            .clipShape(Capsule())
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    if !chemical.concerns.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("주요 위험 유형")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            FlowLayout(spacing: 8) {
                                ForEach(chemical.concerns, id: \.rawValue) { concern in
                                    Text(concern.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(chemical.riskLevel.color)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 10)
                                        .background(chemical.riskLevel.backgroundColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(16)
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("건강 영향")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        ForEach(chemical.effects, id: \.self) { effect in
                            Label(effect, systemImage: "exclamationmark.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("특별 주의 대상")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        if chemical.infantRisk   { Label("영유아 — 특별 주의 필요",       systemImage: "figure.and.child.holdinghands").font(.system(size: 13)).foregroundStyle(Color.riskHigh) }
                        if chemical.pregnantRisk { Label("임산부 — 특별 주의 필요",       systemImage: "person.fill.badge.plus").font(.system(size: 13)).foregroundStyle(Color.riskHigh) }
                        if chemical.allergyRisk  { Label("알레르기 보유자 — 주의 필요",   systemImage: "cross.case.fill").font(.system(size: 13)).foregroundStyle(Color.riskMedium) }
                        if chemical.petRisk      { Label("반려동물 — 특별 주의 필요",     systemImage: "pawprint.fill").font(.system(size: 13)).foregroundStyle(Color.riskMedium) }
                    }
                    .padding(16)
                    .cardStyle()
                }
                .padding(20)
            }
            .background(Color.bgPrimary)
            .navigationTitle("성분 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var row: CGFloat = 0
        var rowWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width + (rowWidth > 0 ? spacing : 0) > maxWidth {
                height += row + spacing; row = size.height; rowWidth = size.width
            } else {
                rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
                row = max(row, size.height)
            }
        }
        return CGSize(width: maxWidth, height: height + row)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    let product = DummyDataLoader.shared.products.first!
    DiagnosisResultView(
        product: product,
        adjustedRiskLevel: .medium,
        familyWarnings: ["18개월 자녀 호흡기 자극 가능. 환기 30분 필수"],
        alternatives: []
    )
    .environment(AppState())
}
