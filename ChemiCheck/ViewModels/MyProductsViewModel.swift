import SwiftUI

@Observable
final class MyProductsViewModel {
    var searchText: String = ""

    func filteredProducts(from appState: AppState) -> [Product] {
        if searchText.isEmpty { return appState.registeredProducts }
        return appState.registeredProducts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }

    func recalledProducts(from appState: AppState) -> [Product] {
        appState.registeredProducts.filter { $0.isRecalled }
    }
}
