import Photos
import UIKit

// MARK: - LabelImageSaver
// 앱 최초 실행 시 번들 라벨 이미지 6장을 사진 앱 "케미체크 샘플" 앨범에 저장.
// 이후 갤러리(PhotosPicker)에서 바로 선택 가능.

final class LabelImageSaver {
    static let shared = LabelImageSaver()
    private init() {}

    private let savedKey = "labelImagesSavedV1"

    private let labels: [(assetName: String, displayName: String)] = [
        ("label_bleach",         "락스 라벨"),
        ("label_air_freshener",  "방향제 라벨"),
        ("label_detergent",      "세제 라벨"),
        ("label_washer_cleaner", "세탁조클리너 라벨"),
        ("label_disinfectant",   "소독제 라벨"),
        ("label_deodorizer",     "탈취제 라벨"),
    ]

    func saveIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: savedKey) else { return }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self else { return }
            guard status == .authorized || status == .limited else { return }
            self.performSave()
        }
    }

    private func performSave() {
        var albumPlaceholderId: String?

        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "케미체크 샘플")
            albumPlaceholderId = req.placeholderForCreatedAssetCollection.localIdentifier
        }) { [weak self] success, _ in
            guard success, let self, let pid = albumPlaceholderId else { return }

            let albums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [pid], options: nil)
            guard let album = albums.firstObject else { return }

            PHPhotoLibrary.shared().performChanges({
                guard let addReq = PHAssetCollectionChangeRequest(for: album) else { return }
                var placeholders: [PHObjectPlaceholder] = []
                for label in self.labels {
                    if let image = UIImage(named: label.assetName),
                       let placeholder = PHAssetChangeRequest.creationRequestForAsset(from: image).placeholderForCreatedAsset {
                        placeholders.append(placeholder)
                    }
                }
                addReq.addAssets(placeholders as NSArray)
            }) { success, _ in
                if success {
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: self.savedKey)
                    }
                }
            }
        }
    }
}
