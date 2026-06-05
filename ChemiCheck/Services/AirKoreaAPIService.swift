import Foundation
import CoreLocation

final class AirKoreaAPIService {
    static let shared = AirKoreaAPIService()
    private init() {}

    private let baseURL = "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty"
    private let apiKey  = Config.airKoreaAPIKey

    // MARK: - 시도 실시간 대기질 조회

    func fetchAirQuality(sidoName: String = "서울") async -> AirQualityInfo {
        // 데모 모드: 고정값 반환
        if DemoModeManager.shared.isOn {
            return AirQualityInfo(pm25Grade: "보통", pm25Value: 18.0,
                                  pm10Grade: "보통", pm10Value: 38.0,
                                  o3Grade: "좋음", stationName: "서울")
        }

        guard !apiKey.isEmpty else { return .fallback }

        let params = [
            "serviceKey": apiKey,
            "returnType": "json",
            "numOfRows": "1",
            "pageNo": "1",
            "sidoName": sidoName,
            "ver": "1.0"
        ]

        var components = URLComponents(string: baseURL)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { return .fallback }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let response = json?["response"] as? [String: Any]
            let body     = response?["body"] as? [String: Any]
            let items    = (body?["items"] as? [[String: Any]])?.first

            let pm25Value = Double(items?["pm25Value"] as? String ?? "") ?? 0
            let pm10Value = Double(items?["pm10Value"] as? String ?? "") ?? 0
            let pm25Grade = gradeLabel(items?["pm25Grade"] as? String)
            let pm10Grade = gradeLabel(items?["pm10Grade"] as? String)
            let o3Grade   = gradeLabel(items?["o3Grade"] as? String)
            let station   = items?["stationName"] as? String ?? sidoName

            return AirQualityInfo(pm25Grade: pm25Grade, pm25Value: pm25Value,
                                  pm10Grade: pm10Grade, pm10Value: pm10Value,
                                  o3Grade: o3Grade, stationName: station)
        } catch {
            return .fallback
        }
    }

    private func gradeLabel(_ code: String?) -> String {
        switch code {
        case "1": return "좋음"
        case "2": return "보통"
        case "3": return "나쁨"
        case "4": return "매우나쁨"
        default:  return "알수없음"
        }
    }

    // MARK: - AirQualityInfo

    struct AirQualityInfo {
        let pm25Grade: String
        let pm25Value: Double
        let pm10Grade: String
        let pm10Value: Double
        let o3Grade: String
        let stationName: String

        /// 환기 권장 시간 (분)
        var ventilationMinutes: Int {
            switch pm25Grade {
            case "좋음":     return 15
            case "보통":     return 30
            case "나쁨":     return 0   // 창문 닫고 환기시설 사용
            case "매우나쁨": return 0
            default:         return 20
            }
        }

        /// 환기 안내 메시지
        var ventilationMessage: String {
            switch pm25Grade {
            case "좋음":
                return "현재 대기질 좋음 (\(Int(pm25Value))㎍/㎥) — 창문 환기 15분 적합해요"
            case "보통":
                return "현재 PM2.5 보통 (\(Int(pm25Value))㎍/㎥) — 환기 30분 권장"
            case "나쁨":
                return "현재 미세먼지 나쁨 — 창문 닫고 환기팬 사용을 권장해요"
            case "매우나쁨":
                return "미세먼지 매우 나쁨 — 환기 자제, 공기청정기 사용하세요"
            default:
                return "PM2.5 정보 없음 — 충분한 환기를 권장해요"
            }
        }

        var isGoodForVentilation: Bool {
            pm25Grade == "좋음" || pm25Grade == "보통"
        }

        static let fallback = AirQualityInfo(
            pm25Grade: "알수없음", pm25Value: 0,
            pm10Grade: "알수없음", pm10Value: 0,
            o3Grade: "알수없음", stationName: "—"
        )
    }
}
