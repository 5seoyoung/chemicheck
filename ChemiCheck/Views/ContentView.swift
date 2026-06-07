import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var showCamera = false
    @State private var diagnosisVM = DiagnosisViewModel()
    @State private var showDiagnosis = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F3FAF5").ignoresSafeArea()

            // 활성 탭만 렌더링
            Group {
                if selectedTab == 0 {
                    HomeView(selectedTab: $selectedTab)
                } else if selectedTab == 1 {
                    NavigationStack { MyProductsView() }
                } else if selectedTab == 2 {
                    NavigationStack { ChatAgentView() }
                } else {
                    NavigationStack { MyPageView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .sheet(isPresented: $showCamera) {
            CameraView(
                onCapture: { image in
                    showCamera = false
                    Task {
                        await diagnosisVM.analyzeImage(image, for: appState.familyProfile)
                        await MainActor.run {
                            if let p = diagnosisVM.currentProduct { appState.addRecentProduct(p) }
                            showDiagnosis = true
                        }
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
                DiagnosisResultView(
                    product: p,
                    adjustedRiskLevel: diagnosisVM.adjustedRiskLevel ?? p.riskLevel,
                    familyWarnings: diagnosisVM.familyWarnings,
                    alternatives: diagnosisVM.alternatives
                )
            } else if diagnosisVM.isAnalyzing {
                AnalyzingView(step: diagnosisVM.analysisStep)
            }
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.separatorSoft).frame(height: 1)

            HStack(alignment: .bottom, spacing: 0) {
                tabButton(icon: "house.fill",                       label: "홈",         tag: 0)
                tabButton(icon: "shippingbox.fill",                 label: "내 제품",    tag: 1)

                Button { showCamera = true } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.brandGreen, Color(hex: "#18865A")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.brandGreen.opacity(0.5), radius: 12, x: 0, y: 5)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .offset(y: -16)

                tabButton(icon: "bubble.left.and.bubble.right.fill", label: "AI 상담",    tag: 2)
                tabButton(icon: "person.fill",                       label: "마이페이지", tag: 3)
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.white)

            Color.white.frame(height: 34)
        }
    }

    @ViewBuilder
    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tag }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTab == tag ? Color.brandNavy : Color.textTertiary)
                Text(label)
                    .font(.system(size: 9, weight: selectedTab == tag ? .bold : .regular))
                    .foregroundStyle(selectedTab == tag ? Color.brandNavy : Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Analyzing View

struct AnalyzingView: View {
    let step: AnalysisStep
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(Color.greenSoft, lineWidth: 5)
                        .frame(width: 88, height: 88)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            LinearGradient(colors: [Color.brandGreen, Color.greenDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.brandNavy)
                }
                VStack(spacing: 8) {
                    Text(step.rawValue.isEmpty ? "분석 준비 중..." : step.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("식약처·환경부 데이터와 비교 중이에요")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                HStack(spacing: 8) {
                    ForEach([AnalysisStep.ocr, .matching, .calculating], id: \.rawValue) { s in
                        Capsule()
                            .fill(stepActive(s) ? Color.brandGreen : Color.separator)
                            .frame(height: 4)
                    }
                }
                .frame(width: 120)
            }
            .padding(40)
        }
    }

    private func stepActive(_ s: AnalysisStep) -> Bool {
        let order: [AnalysisStep] = [.ocr, .matching, .calculating]
        let ci = order.firstIndex(of: step) ?? 0
        let si = order.firstIndex(of: s) ?? 0
        return si <= ci
    }
}

#Preview {
    ContentView().environment(AppState())
}
