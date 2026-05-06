import Foundation
import CoreLocation

// Stage 2: 한국환경공단 에어코리아 대기오염정보 API 연동
final class AirKoreaAPIService {
    static let shared = AirKoreaAPIService()
    private init() {}

    private let baseURL = "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc"

    func fetchAirQuality(location: CLLocation) async throws -> AirQualityInfo {
        // Stage 2 구현 예정
        throw ServiceError.notImplemented
    }

    struct AirQualityInfo: Codable {
        let pm25Grade: String        // 초미세먼지 등급
        let pm25Value: Double        // 초미세먼지 농도 (㎍/㎥)
        let pm10Grade: String        // 미세먼지 등급
        let pm10Value: Double        // 미세먼지 농도 (㎍/㎥)
        let o3Grade: String          // 오존 등급
        let stationName: String      // 측정소명

        // 환기 가이드: 외부 대기질이 좋을 때 환기 권장
        var ventilationRecommended: Bool {
            pm25Grade == "좋음" || pm25Grade == "보통"
        }

        var ventilationMessage: String {
            if ventilationRecommended {
                return "현재 대기질이 \(pm25Grade)이에요. 환기하기 좋은 시간이에요!"
            } else {
                return "현재 미세먼지가 \(pm25Grade)이에요. 창문 환기 후 환기팬을 사용하세요."
            }
        }
    }

    enum ServiceError: Error {
        case notImplemented
        case locationPermissionDenied
        case networkError(Error)
    }
}
