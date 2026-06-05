import SwiftUI

struct RecentProductsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedProduct: Product? = nil

    var body: some View {
        Group {
            if appState.recentProducts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.textTertiary)
                    Text("아직 진단한 제품이 없어요")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("카메라로 제품 라벨을 스캔하면\n진단 이력이 여기에 쌓여요")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.recentProducts) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(product.riskLevel.backgroundColor)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: product.imageSystemName)
                                        .foregroundStyle(product.riskLevel.color)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.textPrimary)
                                    Text(product.brand)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.textSecondary)
                                }
                                Spacer()
                                RiskBadge(level: product.riskLevel, size: .small)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indices in
                        var updated = appState.recentProducts
                        updated.remove(atOffsets: indices)
                        appState.recentProducts = updated
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle("최근 진단 이력")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            DiagnosisResultView(
                product: product,
                adjustedRiskLevel: product.riskLevel,
                familyWarnings: [],
                alternatives: product.alternativeIds.compactMap { DummyDataLoader.shared.alternative(for: $0) }
            )
        }
    }
}
