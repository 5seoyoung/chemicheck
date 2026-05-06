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
            CameraView { product in
                diagnosisVM.loadProduct(product, for: appState.familyProfile)
                appState.addRecentProduct(product)
                showCamera = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showDiagnosis = true
                }
            }
        }
        .sheet(isPresented: $showDiagnosis) {
            if let product = diagnosisVM.currentProduct {
                DiagnosisResultView(
                    product: product,
                    adjustedRiskLevel: diagnosisVM.adjustedRiskLevel ?? product.riskLevel,
                    familyWarnings: diagnosisVM.familyWarnings,
                    alternatives: diagnosisVM.alternatives
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
