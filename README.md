# 케미체크 (ChemiCheck)

> 라벨 사진 한 장으로 우리 가족 맞춤 생활화학제품 안전 분석

<br>

## 소개

케미체크는 생활화학제품 라벨을 카메라로 촬영하면 포함된 화학물질의 독성 정보를 즉시 분석하고, 영유아·임산부·알레르기·반려동물 등 가족 구성원에 맞게 조정된 위험도를 제공하는 iOS 앱입니다.

식품의약품안전처 화학물질독성 DB, 환경부 KEITI, 안전보건공단 데이터를 기반으로 하며, AI 상담사를 통해 제품별 안전 사용법과 더 안전한 대체재를 추천합니다.

<br>

## 주요 기능

| 기능 | 설명 |
|---|---|
| **라벨 OCR 스캔** | 카메라로 제품 라벨 촬영 → Apple Vision 텍스트 인식 |
| **화학물질 분석** | 검출 성분별 독성 등급 · 우려 유형 · 건강 영향 제공 |
| **가족 맞춤 위험도** | 영유아·임산부·알레르기·반려동물 프로필 기반 1–5단계 보정 |
| **우리집 노출 맵** | 공간별(욕실·주방·아기방·세탁실) 위험 현황 시각화 |
| **AI 안전 상담** | Claude 기반 화학제품 안전 Q&A (식약처·환경부·안전보건공단 출처 명시) |
| **대체재 추천** | 위험 성분 없는 환경표지 인증 대체 제품 제안 |
| **회수·판매중지 알림** | 등록 제품의 정부 회수 고시 실시간 푸시 알림 |
| **내 제품 관리** | 등록 제품 보관함 + 위험도 추적 |

<br>

## 스크린샷

> Stage 1 UI 완성 기준 (더미 데이터)

| 홈 | 진단 결과 | AI 상담 |
|---|---|---|
| 안전 점수 · 노출 맵 | 위험도 카드 · 성분 목록 | 가족 맞춤 AI 답변 |

<br>

## 기술 스택

- **플랫폼**: iOS 17.0+
- **언어**: Swift 5.9
- **UI 프레임워크**: SwiftUI (`@Observable`, `NavigationStack`, `TabView`)
- **상태 관리**: `@Observable` + `AppState` (UserDefaults 영속)
- **OCR**: Apple Vision Framework (`VNRecognizeTextRequest`)
- **카메라**: AVFoundation
- **알림**: `UNUserNotificationCenter`
- **프로젝트 관리**: XcodeGen 2.45.4
- **AI**: Anthropic Claude API (Stage 2)
- **외부 API**: 식약처 공공데이터 / 환경부 KEITI / 에어코리아 (Stage 2)

<br>

## 아키텍처

```
ChemiCheck/
├── App/
│   └── ChemiCheckApp.swift          # 진입점, AppState 환경 주입
├── Models/
│   ├── Product.swift                # 제품 + RecallNotification
│   ├── Chemical.swift               # 화학물질 + ChemicalConcern
│   ├── FamilyProfile.swift          # 가족 프로필 + 위험도 보정 계수
│   ├── RiskLevel.swift              # 1–5단계 위험도 열거형
│   ├── Alternative.swift            # 대체재
│   └── ChatMessage.swift            # AI 채팅 메시지
├── ViewModels/
│   ├── AppState.swift               # 전역 상태 (@Observable)
│   ├── DiagnosisViewModel.swift     # 진단 흐름 제어
│   ├── ChatAgentViewModel.swift     # AI 채팅 상태
│   └── MyProductsViewModel.swift   # 제품 검색 필터
├── Services/
│   ├── RiskCalculator.swift         # 가족 프로필 기반 위험도 규칙 엔진
│   ├── OCRService.swift             # Apple Vision OCR
│   ├── AIAgentService.swift         # Claude / OpenAI API 래퍼
│   ├── FoodDrugAPIService.swift     # 식약처 독성 DB API
│   ├── KEITIAPIService.swift        # 환경부 KEITI API
│   ├── AirKoreaAPIService.swift     # 에어코리아 대기질 API
│   └── NotificationService.swift   # 로컬 푸시 알림
├── Storage/
│   ├── DummyDataLoader.swift        # JSON 파싱 싱글턴
│   └── DummyData/                   # 제품 9 · 화학물질 12 · 대체재 8
├── Theme/
│   └── Color+Extension.swift        # 디자인 시스템 색상 + cardStyle / primaryButton
└── Views/
    ├── ContentView.swift            # 5탭 루트 + 카메라 시트 제어
    ├── Onboarding/                  # 스플래시 · 온보딩 5단계
    ├── Home/                        # 홈 (안전 점수 · 노출 맵)
    ├── Camera/                      # 카메라 뷰 + 데모 제품 선택
    ├── Diagnosis/                   # 진단 결과 · 성분 상세 · 대체재 상세
    ├── MyProducts/                  # 내 제품 · 회수 알림 상세
    ├── ChatAgent/                   # AI 상담 채팅
    ├── Profile/                     # 마이페이지 · 가족 프로필 수정
    └── Components/                  # TFIcon · ProductCard · RiskBadge · AlternativeCard
```

<br>

## 핵심 로직 — 위험도 보정 엔진

가족 프로필에 따라 제품의 기본 위험도를 최대 +3단계까지 상향 조정합니다.

```swift
// RiskCalculator.swift
func calculate(product: Product, profile: FamilyProfile) -> RiskLevel {
    var level = product.riskLevel.rawValue

    // 영유아 + 호흡기 자극 성분 → +1
    if profile.hasInfant && product.chemicals.contains(where: {
        $0.concerns.contains(.respiratory) && $0.infantRisk
    }) { level = min(level + 1, 5) }

    // 임산부 + 내분비 교란 성분 → +1
    if profile.hasPregnant && product.chemicals.contains(where: {
        $0.concerns.contains(.endocrine) && $0.pregnantRisk
    }) { level = min(level + 1, 5) }

    // 알레르기 보유자 + 알레르겐 → +1
    if profile.hasAllergyMember && product.chemicals.contains(where: {
        $0.concerns.contains(.allergen) && $0.allergyRisk
    }) { level = min(level + 1, 5) }

    return RiskLevel(rawValue: level) ?? product.riskLevel
}
```

<br>

## 개발 단계

### Stage 1 — UI 셸 + 더미 데이터 ✅ 완료

- [x] 전체 5탭 화면 UI 완성 (홈 · 진단 · 내 제품 · AI 상담 · 마이)
- [x] 온보딩 (가족 프로필 5단계 설정)
- [x] 진단 결과 화면 (위험도 카드 · 성분 상세 · 대체재)
- [x] AI 상담 더미 응답 (7개 시나리오 키워드 매칭)
- [x] 회수 알림 시뮬레이션 + 로컬 푸시
- [x] 가족 프로필 기반 위험도 보정 규칙 엔진
- [x] UserDefaults 데이터 영속
- [x] 디자인 시스템 (파스텔 팔레트 · 그라디언트 · TFIcon 아이콘)

### Stage 2 — 실제 API 연동 🔜 진행 예정 (목표: 2026년 6월 20일)

- [ ] Apple Vision OCR → 라벨 텍스트 인식 활성화
- [ ] 식약처 화학물질독성정보 API 연동
- [ ] 환경부 KEITI 환경표지 인증 제품 DB 연동
- [ ] Claude API 실제 AI 상담 연결
- [ ] 에어코리아 대기질 API → 환기 가이드 연동
- [ ] 회수·판매중지 목록 백그라운드 폴링 + 푸시 자동화

<br>

## 시작하기

### 요구 사항

- Xcode 16.0+
- iOS 17.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.45.4+

### 설치

```bash
git clone https://github.com/your-org/chemicheck.git
cd chemicheck
xcodegen generate
open ChemiCheck.xcodeproj
```

### Stage 2 API 키 설정 (선택)

실제 API 연동 시 환경변수로 키를 주입합니다. 절대 소스에 하드코딩하거나 git에 커밋하지 마세요.

```bash
export ANTHROPIC_API_KEY="your_key"
export FOOD_DRUG_API_KEY="your_key"
export AIR_KOREA_API_KEY="your_key"
```

<br>

## 데이터 출처

| 기관 | 데이터 | 용도 |
|---|---|---|
| 식품의약품안전처 | 화학물질독성정보 DB | 성분별 독성 등급 · 건강 영향 |
| 환경부 KEITI | 환경표지 인증 제품 · 안전확인 신고 | 대체재 추천 · 안전 인증 확인 |
| 안전보건공단 | 화학물질 MSDS | 작업환경 기준 참고 |
| 한국환경공단 에어코리아 | 대기오염정보 | 환기 최적 시간 가이드 |

<br>

## 라이선스

MIT License — 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
