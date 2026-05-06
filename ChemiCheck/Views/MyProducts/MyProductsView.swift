import SwiftUI

struct MyProductsView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = MyProductsViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var selectedRecall: RecallNotification? = nil
    @State private var showDemoAlert = false
    @State private var pulsing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Recall banner if any
                    if let recall = appState.pendingRecall {
                        recallBanner(recall)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            .onTapGesture { selectedRecall = recall }
                    }

                    // Empty or product list
                    if appState.registeredProducts.isEmpty {
                        emptyState
                    } else {
                        productsList
                    }

                    // Demo button
                    demoSection
                        .padding(.bottom, 100)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("내 제품")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $vm.searchText, prompt: "제품명, 브랜드 검색")
        }
        .sheet(item: $selectedProduct) { product in
            DiagnosisResultView(
                product: product,
                adjustedRiskLevel: product.riskLevel,
                familyWarnings: [],
                alternatives: product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }
            )
        }
        .sheet(item: $selectedRecall) { recall in
            NotificationDetailView(notification: recall)
        }
    }

    private func recallBanner(_ recall: RecallNotification) -> some View {
        HStack(spacing: 14) {
            // 펄스 아이콘
            ZStack {
                Circle()
                    .fill(Color.riskCritical.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .scaleEffect(pulsing ? 1.25 : 1.0)
                    .opacity(pulsing ? 0 : 0.7)
                    .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: pulsing)

                TFIcon.recall(size: 36)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("회수 고시 알림")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.riskCritical)
                    Text("즉시 확인")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.riskCritical.opacity(0.85))
                        .clipShape(Capsule())
                }
                Text("\(recall.product.name) — 즉시 사용 중단 권고")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.riskCritical.opacity(0.5))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.riskCritical.opacity(0.06), Color.riskCriticalBg.opacity(0.6)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.riskCritical.opacity(0.25), lineWidth: 1)
        )
        .onAppear { pulsing = true }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.bgSecondary)
                    .frame(width: 100, height: 100)
                Image(systemName: "shippingbox")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 8) {
                Text("등록된 제품이 없어요")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("진단 결과 화면에서 제품을 등록하면\n회수 고시 발생 시 즉시 알려드려요")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var productsList: some View {
        LazyVStack(spacing: 10) {
            // Recalled products first
            let recalled = vm.recalledProducts(from: appState)
            if !recalled.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("회수 대상")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.riskCritical)
                        .padding(.horizontal, 20)

                    ForEach(recalled) { product in
                        ProductCard(product: product) { selectedProduct = product }
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)

                Divider().padding(.horizontal, 20)
            }

            // All registered products
            Text("등록 제품 (\(appState.registeredProducts.count)개)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            ForEach(vm.filteredProducts(from: appState)) { product in
                ProductCard(product: product) { selectedProduct = product }
                    .padding(.horizontal, 20)
            }
        }
    }

    private var demoSection: some View {
        VStack(spacing: 12) {
            Divider().padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                Label("데모 기능", systemImage: "play.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.brandNavy)

                Text("회수 고시 알림 시뮬레이션을 탭하면 즉시 푸시 알림이 발송됩니다")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)

                Button {
                    appState.simulateRecallNotification()
                } label: {
                    Label("데모 회수 알림 발송", systemImage: "bell.badge.fill")
                }
                .primaryButton()
            }
            .padding(16)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.brandNavy.opacity(0.2), lineWidth: 1.5)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

#Preview {
    MyProductsView()
        .environment(AppState())
}
