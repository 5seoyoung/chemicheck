# Beta App Review — Test Notes (English)

**App:** ChemiCheck — Household Chemical Safety Guide  
**Bundle ID:** com.medix.chemicheck  
**Version:** 1.0.0 (Build 1)  
**Category:** Utilities / Health & Fitness  
**Language:** Korean (한국어)

---

## What This App Does

ChemiCheck is a household chemical product safety guide for Korean consumers. Users photograph a product label (or select from their photo library), and the app:

1. Extracts ingredient text using Apple's Vision framework (OCR)
2. Matches detected chemical names against a local database of 100 chemicals (sourced from the Korean Ministry of Food and Drug Safety)
3. Calculates a customized risk level based on the user's family profile (presence of infants, pregnant members, allergy sufferers, elderly, or pets)
4. Provides an AI safety consultation powered by Claude (Anthropic) via a secure proxy server
5. Displays real-time air quality data (PM2.5) from Korea Environment Corporation (AirKorea) to recommend ventilation time
6. Alerts users if a registered product appears on the Ministry of Environment's recall list (31 curated entries)

**This app does not provide medical diagnoses.** It is an informational reference tool. All screens include appropriate disclaimers directing users to consult professionals for medical concerns.

---

## How to Test

### Step 1 — Onboarding
1. Launch the app. The splash screen appears (approx. 1.5 seconds).
2. On the onboarding screen, set up a family profile. For testing, enable: **Infant** (age 2), **Allergy member**.
3. Tap **"시작하기" (Get Started)**.

### Step 2 — Home Dashboard
- The home screen shows a **Safety Score** gauge (dynamic, based on registered products).
- With no products registered, the score displays as "—".
- Tap any recent product card (if present) or proceed to camera.

### Step 3 — Label Scan (Core Feature)
**Option A — Camera:**
1. Tap the camera button.
2. Point the camera at any cleaning product label (e.g., bleach, laundry detergent).
3. The app will extract text, match chemicals, and display results within 3–5 seconds.

**Option B — Demo Mode (Recommended for review):**
1. Go to **마이페이지 (My Page)** tab.
2. Tap the page title **"마이페이지"** three times quickly to activate Demo Mode.
3. Return to the home screen and tap the camera button.
4. The app will run a simulated scan with curated demo data — no actual camera needed.

### Step 4 — Diagnosis Result
- After scanning, the **Diagnosis Result** screen shows:
  - Risk level badge (1–5 scale, color coded)
  - Detected chemical list (tap any chemical for detail sheet)
  - Family-specific warnings (e.g., "Infant risk — sodium hypochlorite may be dangerous for infants")
  - Air quality–based ventilation recommendation
  - Safer alternative products
- Tap **"AI 상담 시작"** to open the AI consultation with the scanned product as context.

### Step 5 — AI Consultation (ChatAgentView)
1. In the AI chat screen, tap one of the quick prompts (e.g., "임신 중에 써도 돼?" = "Is this safe during pregnancy?").
2. The app sends the question along with the scanned product context to the AI proxy server.
3. A response appears within 5–10 seconds. If the network request times out, a pre-cached fallback answer is shown automatically.

### Step 6 — My Products & Recall Alert
1. From the Diagnosis Result screen, tap **"내 제품에 등록"** (Register to My Products).
2. Go to **내 제품 (My Products)** tab.
3. If the registered product matches a recall entry, a **recall alert notification** is triggered immediately (system push + in-app banner).
4. Tap the recall notification to view the detail screen (violation reason, refund guide, responsible agency).

### Step 7 — My Page & Profile Edit
1. Go to **마이페이지** tab.
2. Tap **"프로필 수정"** to edit family members.
3. Toggle different family member types and return to **내 제품** — the Safety Score will recalculate dynamically.

---

## Notes for Reviewers

**Network Requirements:**  
- AI consultation requires an internet connection to reach the Claude proxy server (`chemicheck-proxy.workers.dev`). If offline, a cached fallback response is shown automatically — no error state.
- AirKorea API requires internet. If unavailable, air quality info is hidden gracefully.
- All other features (OCR, chemical matching, recall alerts, family profile) work fully offline.

**No Account Required:**  
The app has no sign-in or account system. All user data (family profile, registered products) is stored locally on the device in `UserDefaults`.

**No In-App Purchases:**  
The app is free with no IAP.

**Camera & Photo Library:**  
Camera and photo library access are requested only when the user taps the scan button. Permissions are not requested at launch.

**Push Notifications:**  
Notification permission is requested once during onboarding. Push notifications are used exclusively for recall alerts — not for marketing.

**Medical Disclaimer:**  
The app displays the following disclaimer prominently on the My Page screen and in the onboarding flow:

> "케미체크는 생활화학제품 참고 정보를 제공하며, 의료적 진단·처방을 대체하지 않습니다. 건강 이상이 의심되는 경우 반드시 전문의 또는 약사와 상담하세요."

(English: "ChemiCheck provides reference information about household chemical products and does not replace medical diagnosis or prescription. If you suspect a health issue, please consult a physician or pharmacist.")

**Data Sources:**  
- Korean Ministry of Food and Drug Safety (식품의약품안전처) — chemical toxicity database
- Korean Ministry of Environment (환경부) — recall and suspension list
- Korea Environment Corporation AirKorea (한국환경공단 에어코리아) — air quality API
- KEITI (한국환경산업기술원) — eco-label certified product reference

---

## Demo Account

No account is required. Use Demo Mode (My Page title × 3 taps) for a fully scripted, network-independent test flow.

---

## Contact

**Developer:** MediX  
**Support Email:** inmani1555@gmail.com  
**Privacy Policy:** https://5seoyoung.github.io/chemicheck/privacy.html  
**Support URL:** https://5seoyoung.github.io/chemicheck/
