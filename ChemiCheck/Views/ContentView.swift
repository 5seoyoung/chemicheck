import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var showCamera = false
    @State private var diagnosisVM = DiagnosisViewModel()
    @State private var showDiagnosis = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("홈", systemImage: "house") }
                .tag(0)

            // 진단 탭: tap 시 카메라 시트 오픈
            Color.clear
                .tabItem { Label("진단", systemImage: "viewfinder") }
                .tag(1)

            MyProductsView()
                .tabItem { Label("내 제품", systemImage: "list.bullet") }
                .tag(2)

            ChatAgentView()
                .tabItem { Label("AI 상담", systemImage: "bubble.left.and.bubble.right") }
                .tag(3)

            MyPageView()
                .tabItem { Label("마이", systemImage: "person") }
                .tag(4)
        }
        .tint(Color.brandNavy)
        .onChange(of: selectedTab) { old, new in
            if new == 1 {
                showCamera = true
                selectedTab = old
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(
                onCapture: { image in
                    showCamera = false
                    Task {
                        await diagnosisVM.analyzeImage(image, for: appState.familyProfile)
                        await MainActor.run {
                            showDiagnosis = true
                        }
                    }
                },
                onDemoSelect: { product in
                    diagnosisVM.loadProduct(product, for: appState.familyProfile)
                    appState.addRecentProduct(product)
                    showCamera = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showDiagnosis = true
                    }
                }
            )
        }
        .sheet(isPresented: $showDiagnosis) {
            if let product = diagnosisVM.currentProduct {
                DiagnosisResultView(
                    product: product,
                    adjustedRiskLevel: diagnosisVM.adjustedRiskLevel ?? product.riskLevel,
                    familyWarnings: diagnosisVM.familyWarnings,
                    alternatives: diagnosisVM.alternatives
                )
            } else if diagnosisVM.isAnalyzing {
                AnalyzingView(step: diagnosisVM.analysisStep)
            }
        }
    }
}

// MARK: - 분석 진행 뷰

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
    ContentView()
        .environment(AppState())
}
