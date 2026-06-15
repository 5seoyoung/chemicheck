# 케미체크 (ChemiCheck) 기술 보고서

**팀명:** MediX  
**플랫폼:** iOS 17.0+ (iPhone)  
**번들 ID:** com.medix.chemicheck  
**기술 스택:** Swift 5.10 · SwiftUI · Swift Concurrency · SQLite3 C API · Cloudflare Workers  
**코드 규모:** Swift 41개 파일, 약 6,800줄

---

## 1. 앱 개요

케미체크는 생활화학제품 라벨을 스마트폰 카메라로 촬영하면 성분을 자동으로 인식하고, 우리 가족 구성원(영유아·임산부·알레르기·노약자·반려동물)에 맞는 맞춤형 위험도를 실시간으로 제공하는 iOS 앱입니다. 화학물질안전원·환경부·한국환경공단 등 국가중점데이터를 결합해 **7,189종 화학물질·214,815개 제품·5,723건 위반 이력**을 온디바이스 SQLite DB로 탑재하고, AI 상담 에이전트를 통해 누구나 쉽게 화학물질 위험을 이해할 수 있도록 설계되었습니다.

---

## 2. 시스템 아키텍처

### 2.1 전체 구조

```
[사용자 iPhone]
    │
    ├── Camera / 갤러리 입력
    │       │
    │       ▼
    │   OCRService (Apple Vision Framework)
    │       │ 텍스트 추출 · 4단계 화학물질명 파싱
    │       │
    │       ▼
    │   LocalDBService (SQLite3 C API)           ← 온디바이스 52MB DB
    │       │ chemicals: 7,189종  (화학물질안전원)
    │       │ products:  214,815개 (환경부 KEITI)
    │       │ recalls:   5,723건  (환경부 위반정보)
    │       ▼
    │   FoodDrugAPIService (큐레이션 캐시 폴백)
    │       │ 100개 화학물질 상세 + 12개 큐레이션 폴백
    │       ▼
    │   RiskCalculator (5규칙 위험도 엔진)
    │       │ 가족 프로필 × 화학물질 속성 → 위험도
    │       ▼
    │   DiagnosisResultView
    │
    ├── AirKoreaAPIService ──────────────────── 한국환경공단 에어코리아 API
    │       │ PM2.5 · PM10 · O3 실시간 조회
    │       ▼
    │   환기 가이드 (대기질 연동)
    │
    ├── AIAgentService ─────────── HTTPS ────── Cloudflare Workers (프록시)
    │       │                                          │
    │       │ 시스템 프롬프트 + 제품 컨텍스트           ▼
    │       │                              Anthropic Claude API
    │       ▼
    │   ChatAgentView (자연어 상담)
    │
    └── NotificationService (UNUserNotificationCenter)
            │ 회수 고시 푸시 · 일일 점검 알림
            ▼
        RecallCuratedLoader (LocalDB 5,723건 + 큐레이션 31건 매칭)
```

### 2.2 파일 구조

```
ChemiCheck/
├── App/
│   ├── ChemiCheckApp.swift      RootView 패턴 (View 레벨 @State로 phase 관리)
│   └── Config.swift             API 키 환경변수 로더 (키 절대 하드코딩 금지)
├── Models/                      데이터 모델 6종
│   ├── Product.swift
│   ├── Chemical.swift           ChemicalConcern 7종 열거형 포함
│   ├── FamilyProfile.swift      가족 구성원 5종 + memberSummary 연산 프로퍼티
│   ├── RiskLevel.swift          5단계 위험도 (1=안전~5=위험)
│   ├── Alternative.swift
│   └── ChatMessage.swift
├── Services/                    핵심 비즈니스 로직
│   ├── OCRService.swift         4단계 화학물질명 파싱 (DB 0차 + alias 1차 + 정규식 2·3차)
│   ├── FoodDrugAPIService.swift 화학물질 로컬 캐시 + LocalDB 위임
│   ├── RiskCalculator.swift
│   ├── AIAgentService.swift
│   ├── AirKoreaAPIService.swift
│   ├── KEITIAPIService.swift
│   └── NotificationService.swift
├── ViewModels/
│   ├── AppState.swift           전역 상태 (SwiftUI @Observable)
│   ├── DiagnosisViewModel.swift OCR 파이프라인 오케스트레이터
│   ├── ChatAgentViewModel.swift @MainActor AI 채팅 상태
│   └── MyProductsViewModel.swift
├── Storage/
│   ├── LocalDBService.swift     SQLite3 C API 래퍼 — 온디바이스 52MB DB
│   ├── DummyDataLoader.swift    시드 데이터 + LocalDB 폴백 로더
│   ├── RecallCuratedLoader.swift LocalDB 5,723건 검색 + 큐레이션 31건
│   └── DummyData/
│       ├── chemicheck.sqlite    52MB SQLite DB (앱 번들 탑재)
│       ├── products.json        30개 시드 제품
│       ├── chemicals.json       12개 상세 큐레이션 화학물질
│       ├── chemicals_cache.json 100개 OCR 매칭 폴백 캐시
│       ├── alternatives.json    20개 대체재
│       └── recalls.json         31건 회수 고시 큐레이션
├── Theme/
│   └── Color+Extension.swift   브랜드 색상 (brandNavy #1A2F6E · brandGreen #22B573)
└── Views/                       32개 뷰 + 18개 컴포넌트
```

---

## 3. 핵심 기능 구현

### 3.1 OCR 기반 라벨 인식 파이프라인

**파일:** [OCRService.swift](../ChemiCheck/Services/OCRService.swift)

Apple Vision Framework의 `VNRecognizeTextRequest`를 사용하여 제품 라벨에서 텍스트를 추출합니다.

```
Camera/갤러리 이미지
        │
        ▼
VNRecognizeTextRequest
  - recognitionLanguages: ["ko-KR", "en-US"]  ← 한영 동시 인식
  - recognitionLevel: .accurate
  - usesLanguageCorrection: true
  - minimumTextHeight: 0.01
        │
        ▼
텍스트 정규화 (전각→반각, 연속 공백 제거)
        │
        ▼
4단계 화학물질명 파싱
  0단계: LocalDB 7,189건 전체 이름 in-memory 검색
          앱 시작 시 화학물질명 배열을 메모리에 pre-load (~350KB)
          한국어명 포함 검사 → 영어명 포함 검사 순으로 매칭
  1단계: 84개 alias 딕셔너리 직접 매칭
          (예: "락스" → "차아염소산나트륨", "BKC" → "벤잘코늄클로라이드")
  2단계: 한국어 화학명 패턴 정규식
          (나트륨·칼륨·염·산·알코올·글리콜·에테르·에스테르·옥사이드 계열)
  3단계: 영문 화학명 패턴 정규식
          (sodium X, X chloride, X hydroxide, X sulfate, Xanol, Xglycol 등)
        │
        ▼
표준화된 화학물질명 배열 → LocalDBService / FoodDrugAPIService로 전달
```

**alias 사전 규모:** 84개 표준명, 각 3~8개 표현 변형 등록 (500+ 표현 커버)  
**예시:** 차아염소산나트륨 → `["차아염소산나트륨", "Sodium Hypochlorite", "NaOCl", "차아염소산소다", "락스", "hypochlorite"]`

---

### 3.2 화학물질 데이터 매칭 엔진 (LocalDB + 큐레이션 캐시)

**파일:** [LocalDBService.swift](../ChemiCheck/Storage/LocalDBService.swift) / [FoodDrugAPIService.swift](../ChemiCheck/Services/FoodDrugAPIService.swift)

OCR로 추출된 화학물질명을 온디바이스 SQLite 데이터베이스와 매칭합니다.

```
화학물질명 배열 입력
        │
        ▼
LocalDBService.searchChemical(nameKr:) — SQLite 7,189건 한국어명 정확 매칭
        │   히트 → ChemicalDBRecord → toChemical() → Chemical 객체 반환
        │   미스
        ▼
LocalDBService.searchChemicalByEn(nameEn:) — 영어명 LIKE 검색
        │   히트 → Chemical 객체 반환
        │   미스
        ▼
FoodDrugAPIService — chemicals_cache.json 100개 폴백
        │   정확 일치: name, englishName, aliases 배열
        │   부분 문자열 매칭: contains()
        │
   히트 ──────────────────→ Chemical 객체 반환
        │ 미스
        ▼
chemicals.json 2차 탐색 (12개 상세 큐레이션 데이터)
        │
        ▼
매칭 실패 시 → 빈 배열 (OCR 폴백: 더미 데이터 3개)
```

**LocalDBService 스레드 안전 설계:**

```swift
// Serial queue로 모든 SQLite 작업 직렬화
private let dbQueue = DispatchQueue(label: "com.chemicheck.localdb", qos: .userInitiated)

// init()이 메인 스레드를 블로킹하지 않도록 async 초기화
private init() {
    dbQueue.async {
        self.openDatabase()
        self.preloadChemicalNames()  // 7,189개 이름을 메모리 배열로 로드
    }
}

// 모든 쿼리는 dbQueue.sync — init async 완료 대기 자동 처리
private func query<T>(sql: String, ...) -> [T] {
    dbQueue.sync { () -> [T] in /* SQLite3 C API */ }
}
```

**위험도 → 가족 구성원별 리스크 자동 추론 (ChemicalDBRecord.toChemical()):**

| 조건 | 플래그 |
|------|--------|
| riskLevel >= 4 | infantRisk = true (영유아 위험) |
| riskLevel >= 4 | pregnantRisk = true (임산부 위험) |
| riskLevel >= 3 | allergyRisk = true (알레르기 주의) |
| riskLevel >= 4 | petRisk = true (반려동물 위험) |

---

### 3.3 가족 맞춤 위험도 산정 알고리즘

**파일:** [RiskCalculator.swift](../ChemiCheck/Services/RiskCalculator.swift)

단순히 제품의 기본 위험도를 보여주는 것이 아니라, 가족 구성원에 따라 동적으로 위험도를 재산정합니다.

```
기본 위험도 (1~5단계)
        │
        ▼
가족 프로필 5규칙 적용 (순서대로, 최대 5단계 캡)

  규칙 1 — 영유아 × 호흡기 자극 성분 → +1
  규칙 2 — 임산부 × 내분비 교란 물질 → +1
  규칙 3 — 알레르기 × 알레르겐 성분  → +1
  규칙 4 — 반려동물 × 신경독성·수생독성 → +1
  규칙 5 — 노약자 × 호흡기 성분 (위험도 3이상) → +1
        │
        ▼
보정된 위험도 + 가족별 경고 메시지 생성
  "영유아 위험 — 차아염소산나트륨이(가) 영유아에게 위험할 수 있어요"
  "임산부 주의 — CMIT/MIT 포함. 환경부 지정 주의 성분이에요"
  "반려동물 위험 — 벤잘코늄클로라이드 노출 주의. 사용 시 격리 필요해요"
```

**FamilyProfile 데이터 모델:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `hasInfant` | Bool | 영유아 여부 |
| `infantAges` | [Int] | 나이 (0=신생아) |
| `hasPregnant` | Bool | 임산부 여부 |
| `hasAllergyMember` | Bool | 알레르기/아토피 |
| `hasElderly` | Bool | 노약자 여부 |
| `hasPet` | Bool | 반려동물 여부 |
| `petTypes` | [PetType] | 강아지·고양이·조류·기타 |

---

### 3.4 진단 파이프라인 오케스트레이터

**파일:** [DiagnosisViewModel.swift](../ChemiCheck/ViewModels/DiagnosisViewModel.swift)

전체 분석 흐름을 단계별로 관리하며, 사용자에게 진행 상태를 실시간으로 표시합니다.

```
analyzeImage() 호출
        │
  Step 1: OCR 텍스트 추출 (5초 타임아웃)
        │  analysisStep: .ocr → "라벨 인식 중..."
  Step 2: 화학물질명 파싱 (4단계 OCRService)
        │  analysisStep: .matching → "화학물질 분석 중..."
  Step 3: LocalDB 7,189건 매칭 → Chemical 배열
        │
  Step 4: 제품 등록 여부 확인 (products 214,815건)
        │  analysisStep: .calculating → "우리집 기준 계산 중..."
  Step 5: RiskCalculator → 보정 위험도 + 경고
        │  analysisStep: .done
  Step 6: 회수 이력 확인 (recalls 5,723건)
        │
        ▼
  DiagnosisResultView 표시 (에어코리아 환기 가이드 포함)
```

**타임아웃 처리:** `withThrowingTaskGroup`으로 OCR 5초 타임아웃 구현. 실패 시 자동으로 더미 데이터 폴백  
**데모 모드:** 마이페이지 제목 3회 탭으로 활성화. 시연 중 API 연결 없이 사전 큐레이션 데이터로 실행

---

### 3.5 AI 상담 에이전트 (Claude API 연동)

**파일:** [AIAgentService.swift](../ChemiCheck/Services/AIAgentService.swift) / [cloudflare-worker/worker.js](../cloudflare-worker/worker.js)

API 키를 앱 바이너리에 포함시키지 않는 **프록시 아키텍처**를 채택했습니다.

```
[앱] ChatAgentView
        │ 질문 + 제품 컨텍스트
        ▼
AIAgentService.ask()
        │ POST https://chemicheck-proxy.inmani1555.workers.dev/api/chat
        ▼
[Cloudflare Workers 프록시]  ← ANTHROPIC_API_KEY는 여기 Secret으로 관리
        │ x-api-key 헤더 추가
        ▼
Anthropic API (claude-sonnet-4-6)
        │ max_tokens: 600, timeout: 10초
        ▼
AIAgentService → ChatAgentViewModel → 화면 표시
```

**시스템 프롬프트 동적 구성:**

```
당신은 생활화학제품 안전 전문 AI 상담사입니다.
식품의약품안전처, 환경부, 안전보건공단의 공식 데이터를 기반으로 답변하세요.
답변은 200자 이내로 간결하게 작성하세요.
모든 답변 마지막에 [출처: 기관명] 형식으로 출처를 명시하세요.

사용자 가족 구성원: 영유아(2세) · 알레르기/아토피   ← 자동 삽입
현재 진단 제품:
  - 제품명: 유한락스 (유한양행)
  - 위험도: 4단계 (위험)
  - 포함 성분: 차아염소산나트륨, 계면활성제   ← 자동 삽입
```

**오프라인 폴백 캐시 10개:**

| 키워드 | 주제 |
|--------|------|
| 임신·임산부 | 임산부 사용 가이드 |
| 아기·영유아 | 아기 빨래 주의사항 |
| 고양이·강아지·펫 | 반려동물 격리 방법 |
| 환기·얼마·시간 | 환기 시간 가이드 |
| 버리·폐기 | 화학제품 폐기 방법 |
| 대체·안전한 | 친환경 대체재 추천 |
| 알레르기·아토피 | 알레르기 유발 성분 |
| 피부·눈·접촉 | 응급 처치 요령 |
| 흡입·냄새 | 흡입 시 대처법 |
| 섞다·혼합·락스 | 혼합 금지 성분 |

---

### 3.6 에어코리아 대기질 연동

**파일:** [AirKoreaAPIService.swift](../ChemiCheck/Services/AirKoreaAPIService.swift)

진단 결과 화면에 실시간 대기질 데이터를 결합하여 환기 권장 시간을 동적으로 계산합니다.

```
에어코리아 API (data.go.kr)
  /ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty
  시도명: "서울", timeout: 5초
        │
        ▼
PM2.5 수치 → 환기 권장 시간 계산
  좋음 (0-15㎍/㎥)  → 15분 환기 가능
  보통 (16-35㎍/㎥) → 30분 환기 권장
  나쁨 (36-75㎍/㎥) → 창문 닫고 환기팬 사용
  매우나쁨 (75+)    → 환기 자제, 공기청정기 사용
        │
        ▼
진단 결과 화면 하단 환기 가이드 메시지 표시
"현재 PM2.5 보통 (18㎍/㎥) — 환기 30분 권장"
```

---

### 3.7 회수 고시 알림 시스템

**파일:** [RecallCuratedLoader.swift](../ChemiCheck/Storage/RecallCuratedLoader.swift) / [AppState.swift](../ChemiCheck/ViewModels/AppState.swift)

제품 등록 시 즉시 LocalDB 5,723건 + 큐레이션 31건과 자동 매칭합니다.

```
제품 등록 (AppState.registerProduct())
        │
        ├── isRecalled = true → 즉시 UNUserNotificationCenter 푸시
        │
        └── RecallCuratedLoader.findMatch()
                │ 1차: LocalDB 5,723건 실데이터 검색
                │ 2차: 큐레이션 recalls.json 31건 키워드 매칭
                ▼
          매칭 성공 → RecallNotification 생성
                      → pendingRecall 상태 업데이트
                      → notificationBadgeCount 증가
                      → 시스템 푸시 알림 발송
```

홈 화면 "최신 위반 알림" 섹션은 `LocalDBService.recentRecalls(limit: 30)`으로 조치일 기준 최신 30건을 실시간 조회합니다.

**알림 내용:**
- 제목: "⚠️ 회수 고시 알림"
- 본문: "제품명 — 즉시 사용을 중단하고 상세 내용을 확인하세요."
- 사운드: `.defaultCritical` (중요 알림음)
- 상세 화면: 위반 내용 · 환불 안내 · 담당 기관

---

### 3.8 안전 점수 대시보드

**파일:** [HomeView.swift](../ChemiCheck/Views/Home/HomeView.swift) / [MyProductsViewModel.swift](../ChemiCheck/ViewModels/MyProductsViewModel.swift)

등록된 제품들의 위험도 가중 평균으로 가정의 종합 안전 점수(0~100점)를 동적 산출합니다.

```
등록 제품 N개 × 위험도 (1~5)
        │
        ▼
안전 점수 = 100 - (가중 평균 위험도 - 1) / 4 × 100
  위험도 1(안전) → 100점
  위험도 3(주의) → 50점
  위험도 5(위험) → 0점
        │
        ▼
홈 화면 게이지 애니메이션 (0 → 점수 카운트업)
등록 0개 → "-" 표시
```

---

## 4. 서버 인프라 (Cloudflare Workers)

### 4.1 배포 아키텍처

Anthropic API 키를 앱 코드에 포함하지 않고, 서버리스 엣지 함수를 프록시로 사용합니다.

```
[앱 클라이언트]
  POST /api/chat
  Content-Type: application/json
  Body: { model, max_tokens, system, messages }
        │
        ▼
[Cloudflare Workers - 엣지 서버]
  - CORS preflight 처리 (OPTIONS 메서드)
  - /api/chat 경로 이외 404 반환
  - ANTHROPIC_API_KEY: Workers Secret으로 안전 관리
  - Anthropic API 키를 x-api-key 헤더로 주입
        │
        ▼
[Anthropic API]
  POST https://api.anthropic.com/v1/messages
  anthropic-version: 2023-06-01
```

### 4.2 보안 설계

| 항목 | 구현 방식 |
|------|-----------|
| API 키 관리 | Cloudflare Workers Secret (환경변수, 코드 외부) |
| iOS 앱 키 관리 | Xcode Build Settings `CHEMICHECK_PROXY_URL`, `CHEMICHECK_AIRKOREA_KEY` → Info.plist → Config.swift |
| Git 보안 | `.gitignore`로 키 파일 제외, Config.swift에서 `ProcessInfo.processInfo.environment` 로드 |
| HTTPS | 모든 API 통신 TLS 암호화 |
| 경로 제한 | `/api/chat` 경로만 허용, 그 외 404 |
| 개인정보 | 온디바이스 처리, 개인 데이터 외부 서버 미전송 |

---

## 5. 데이터 아키텍처

### 5.1 온디바이스 SQLite DB (chemicheck.sqlite, 52 MB)

앱 번들에 탑재된 오픈데이터 기반 SQLite 데이터베이스로, 인터넷 연결 없이 전체 기능이 동작합니다.

| 테이블 | 건수 | 출처 | 활용 |
|--------|------|------|------|
| chemicals | 7,189종 | 화학물질안전원 | OCR 0차 매칭 · 위험도·증상 조회 |
| products | 214,815개 | 환경부 KEITI | 제품 등록 여부 확인 · 인증 표시 |
| recalls | 5,723건 | 환경부 위반정보 | 제품 등록 즉시 회수 이력 검색 |

**DB 생성 파이프라인:**
```
open_data/ 원천 CSV·XLSX  →  scripts/build_database.py  →  chemicheck.sqlite (52 MB)
  (Python 3 + openpyxl)        빌드 전 1회 실행, 결과물을 앱 번들에 포함
```

### 5.2 활용 공공데이터

| 데이터셋 | 기관 | 원천 건수 → 탑재 건수 |
|----------|------|----------------------|
| 화학물질안전관리정보 | 화학물질안전원 | 7,190건 → 7,189종 |
| 안전확인대상 생활화학제품 (신고·승인) | 환경부 KEITI | 617,685건 → 214,815개 (유효 제품만) |
| 생활화학제품 위반정보 | 환경부 | 5,724건 → 5,723건 |
| 전성분 공개 제품 | KEITI | 2,040건 → 3,534개 플래그 |
| 자율안전정보공개제품 | 환경부 | 120건 → is_approved=2 마킹 |
| 에어코리아 대기오염정보 | 환경부 한국환경공단 | 실시간 API |

### 5.3 큐레이션 JSON 데이터 (DummyData/)

| 파일 | 항목 수 | 용도 |
|------|---------|------|
| chemicals_cache.json | 100개 | LocalDB 미스 시 폴백 캐시 |
| chemicals.json | 12개 | 상세 큐레이션 화학물질 (2차 폴백) |
| products.json | 30개 | 시드 제품 DB |
| alternatives.json | 20개 | 대체재 추천 DB |
| recalls.json | 31건 | 회수 고시 큐레이션 |

### 5.4 오프라인 폴백 전략

| 상황 | 폴백 |
|------|------|
| OCR 인식 실패 | 더미 데이터 3개로 진단 계속 |
| LocalDB 미스 | chemicals_cache.json 100개 → chemicals.json 12개 순차 탐색 |
| 에어코리아 API 실패 | `.fallback` (정보 없음 표시) |
| Claude API 실패 | 10개 사전 캐시 답변 매칭 |
| AI 캐시 미스 | "식약처(1577-1255)에 문의" 가이드 |

---

## 6. UI/UX 구현

### 6.1 화면 구성 (32개 뷰)

| 카테고리 | 뷰 | 설명 |
|----------|-----|------|
| 온보딩 | SplashView · OnboardingView | 앱 소개 · 가족 프로필 최초 설정 |
| 홈 | HomeView · RecentProductsView | 안전 점수 대시보드 · 최근 진단 이력 |
| 카메라 | CameraView | AVFoundation 카메라 + 갤러리 선택 |
| 진단 | DiagnosisResultView · ChemicalDetailSheet · AlternativeDetailView | 위험도 결과 · 성분 상세 · 대체재 |
| 내 제품 | MyProductsView · NotificationDetailView | 등록 제품 관리 · 회수 알림 상세 |
| AI 상담 | ChatAgentView | 제품 컨텍스트 연동 자연어 채팅 |
| 마이페이지 | MyPageView · ProfileEditView | 프로필 수정 · 개인정보처리방침 |
| 개발자 | DemoModePanel | 시연 모드 토글 (제목 3회 탭 숨김 진입) |

### 6.2 디자인 시스템

| 요소 | 사양 |
|------|------|
| 브랜드 컬러 | 네이비 #1A2F6E (brandNavy) · 그린 #22B573 (brandGreen) |
| UI 스타일 | 토스 스타일 (라운드 카드, 부드러운 그림자) |
| 위험도 배지 | 5단계 색상 코드 (초록→노랑→주황→빨강→진빨강) |
| 아이콘 | SF Symbols (TFIcon 래퍼로 일관성 유지) |

### 6.3 상태 관리 아키텍처

Swift 5.9+ `@Observable` 매크로를 활용한 최신 상태 관리:

```
@Observable AppState (전역 싱글톤)
  ├── familyProfile: FamilyProfile  ← UserDefaults 영속화
  ├── registeredProducts: [Product] ← UserDefaults 영속화
  ├── recentProducts: [Product]     ← UserDefaults 영속화 (최대 20개)
  └── pendingRecall: RecallNotification?

@Observable DiagnosisViewModel (뷰 생명주기 동기화)
  ├── analysisStep: AnalysisStep     ← 4단계 진행 상태
  └── adjustedRiskLevel: RiskLevel?  ← 가족 보정 위험도

@MainActor @Observable ChatAgentViewModel
  ├── messages: [ChatMessage]
  └── isTyping: Bool
```

**스플래시 전환 안정성:** `App.body` 레벨 `@State` 재렌더링이 iOS 버전에 따라 불안정한 문제를 `RootView: View` 패턴으로 해결. `View` 레벨 `@State`는 SwiftUI가 완전히 보장.

---

## 7. Swift Concurrency 적용

모든 비동기 처리에 Swift Concurrency(async/await)를 사용하여 콜백 지옥을 제거하고 코드 가독성을 높였습니다.

```swift
// 파이프라인 전체를 하나의 흐름으로 표현
func analyzeImage(_ image: UIImage, for profile: FamilyProfile) async {
    let rawText = try await withTimeout(seconds: 5) {
        try await OCRService.shared.extractText(from: image)
    } ?? ""
    let chemicalNames = OCRService.shared.parseChemicalNames(from: rawText)
    let chemicals = await FoodDrugAPIService.shared.matchChemicals(from: chemicalNames)
    let product = FoodDrugAPIService.shared.buildScannedProduct(chemicals: chemicals)
    let adjusted = riskCalculator.calculate(product: product, profile: profile)
    await MainActor.run { currentProduct = product; adjustedRiskLevel = adjusted }
}
```

| 기술 | 적용 위치 |
|------|-----------|
| `async/await` | OCR·API 호출 전체 |
| `@MainActor` | ChatAgentViewModel (UI 스레드 보장) |
| `withThrowingTaskGroup` | OCR 5초 타임아웃 구현 |
| `Task { }` | ChatAgentViewModel 요청 취소 지원 |
| `@Observable` | AppState · DiagnosisViewModel · ChatAgentViewModel |
| `DispatchQueue.serial` | LocalDBService SQLite 직렬화 (async init · sync query) |

---

## 8. 기술적 차별점 요약

| 항목 | 일반 앱 | 케미체크 |
|------|---------|---------|
| 라벨 인식 | 바코드 스캔 | OCR 텍스트 추출 + 4단계 화학물질명 파싱 |
| 위험도 판단 | 단일 기준 | 가족 구성원 × 화학물질 속성 5규칙 조합 |
| 화학물질 DB | 소규모 하드코딩 | 7,189종 SQLite 온디바이스 DB (국가 공공데이터) |
| 제품 DB | 없음 | 214,815개 환경부 신고·승인 제품 전수 탑재 |
| 회수 알림 | 없음 | 5,723건 위반 DB + 즉시 자동 매칭 + 푸시 |
| AI 상담 | 없음 | 제품·가족 컨텍스트 자동 주입 Claude AI |
| 대기질 연동 | 없음 | 에어코리아 PM2.5 × 환기 가이드 실시간 결합 |
| API 키 보안 | 앱 내 하드코딩 위험 | Cloudflare Workers 프록시로 서버 측 관리 |
| 오프라인 | 기능 없음 | SQLite 7,189종 + 5,723건 로컬 탑재, 오프라인 완전 동작 |

---

## 9. 빌드 및 배포 환경

| 항목 | 내용 |
|------|------|
| 개발 환경 | Xcode 16, Swift 5.10 |
| 최소 타깃 | iOS 17.0 |
| 아키텍처 | arm64 (armv7 제거) |
| 의존성 | 외부 라이브러리 없음 (100% Apple SDK + Swift 표준 라이브러리) |
| 서버 | Cloudflare Workers (서버리스, 글로벌 엣지) |
| 개인정보처리방침 | GitHub Pages (docs/privacy.html) |
| 코드 규모 | Swift 41개 파일, 약 6,800줄, TODO/FIXME 0건 |
| DB 빌드 도구 | Python 3 + openpyxl + sqlite3 (scripts/build_database.py) |
| 프라이버시 선언 | PrivacyInfo.xcprivacy (NSPrivacyAccessedAPICategoryUserDefaults · FileTimestamp) |

---

*작성일: 2026.06.07 / 팀: MediX*
