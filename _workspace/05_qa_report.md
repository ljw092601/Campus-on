# QA 검수 보고서 — Campus-On UX 설계 (UX Mode)

> 검수자: qa-engineer · 작성일: 2026-07-10
> 검수 대상: `_workspace/01_ux_design.md`
> 배경 입력: `_workspace/00_input.md`, `plan.md`
> 범위: UX 설계 문서 품질만 검증 (코드/API/스토어 산출물 없음)

---

## 종합 판정 (라운드 1 반영 · 최종)

- **판정**: 🟢 **통과 (개발 착수 가능) — 남은 🔴 0건**
- **요약**: ux-designer가 라운드 0의 필수 수정 🔴-1(카테고리 분류 4곳 동기화)과 권장 개선 6건(🟡-1~6)을 **전부 반영**했다. 재검수 결과 4곳 카테고리 완전 일치, 딥링크 계약 단일화, `hours_ko/en` 분리, 개인정보처리방침 진입점, 탭 라벨 통일, CTA 반응형 규칙, 철자제안·공유 Phase 2 이월이 모두 확인됐고 **새로 유입된 모순 없음**. app-developer / api-integrator 핸드오프 가능 상태.

> 아래 "라운드 0"은 최초 검수 기록(원문 보존), "라운드 1 재검수"가 최신 판정이다.

---

## 라운드 1 재검수 (2026-07-10) — ux-designer 수정본 검증

### 재검수 판정 요약

| 항목 | 라운드 0 심각도 | 판정 | 근거(수정본 위치) |
|------|:---:|:---:|------|
| 🔴-1 카테고리 4곳 동기화 | 🔴 | ✅ **해소** | 4곳 완전 일치, emergency 분리, 고아 토큰 제거 (아래 상세) |
| 🟡-1 딥링크 계약 단일화 | 🟡 | ✅ **해소** | line 329·473–483 |
| 🟡-2 `hours_ko/en` 분리 | 🟡 | ✅ **해소** | line 704–705·254 |
| 🟡-4 개인정보처리방침 진입점 | 🟡 | ✅ **해소** | line 403·419 |
| 🟡-5 탭4 라벨 한/영 일치 | 🟡 | ✅ **해소** | line 81 "설정 / Settings" |
| 🟡-6 CTA 대형폰트 세로 스택 | 🟡 | ✅ **해소** | line 251 |
| 🟡-3 철자제안·공유 이월 / 즐겨찾기 유지 | 🟡 | ✅ **해소** | line 394·229·333 |

**남은 🔴: 0건 / 남은 🟡: 0건(모두 반영) / 신규 모순: 없음**

### 🔴-1 상세 — 시설 카테고리 4곳 동기화 검증 [해소]

시설 6종 = `building / classroom / dining / library / amenity / etc` 가 4곳에서 **완전 일치**함을 직접 확인:

| 검증 위치 | 라운드 0 상태 | 수정본 확인 | 판정 |
|-----------|--------------|-------------|:---:|
| `4.1 시설 액센트 표`(line 526–535) | emergency 오입(6종에 긴급 포함), etc 색 없음 | building/classroom/dining/library/amenity/**etc** 6종, `cat.etc #607D8B` 추가, emergency 제거 | ✅ |
| `8. Facility.category enum`(line 697) | etc 포함이나 액센트와 불일치 | `{building, classroom, dining, library, amenity, etc}` + 주석 "emergency 아님" | ✅ |
| `S1 홈 칩`(line 124–126) | 5칩 + [전체], etc 노출 안 됨 | [건물][강의실][식당][도서관][편의][기타] 6종, enum 주석 병기, [전체] 제거 | ✅ |
| `4.5 MarkerPin`(line 602) | "6색"만 표기(집합 불명) | "시설 6색(building/classroom/dining/library/amenity/etc)" + `cat.*` 토큰 매핑 | ✅ |

- **emergency 분리 확인**: line 537 주석으로 "emergency는 시설이 아닌 행정 가이드(S5) 카테고리"임을 명시하고, line 539–548에 **행정 가이드 전용 별도 액센트 표**(`guideCat.*`, immigration/housing/living/health/school/emergency 6종)로 분리됨. `AdminGuideCategory.id` enum(line 714)과도 일치.
- **고아 토큰 제거 확인**: `cat.emergency` 소멸 → `guideCat.emergency`로 정상 이관(시설 마커가 아닌 가이드 카테고리 아이콘에 매핑). 매핑 대상 없는 토큰 없음.
- **결론**: 🔴-1 **완전 해소**. 데이터 계약(enum)–디자인 토큰–화면–컴포넌트 4자 정합.

### 신규 모순 점검 (회귀)

- ✅ `S2/S3 필터 칩`의 `[전체]`(All)는 카테고리가 아닌 **필터 값**(`map_filter_all`)으로 홈 6칩과 역할이 다름 → 정상, 모순 아님.
- ✅ `guideCat.*` 일부 색상값이 `cat.*`와 중복(예: housing=building=#5B6BC0)이나, **시설 마커 vs 가이드 아이콘**으로 사용 맥락이 분리되어 충돌 없음. (팔레트 절약, 참고 수준)
- ✅ 딥링크 흐름도(line 473–474)·S7 인터랙션(line 329)·계약 규칙(line 477–483)이 "항상 S2 + 대표 Peek → [상세]로 S4" 단일 흐름으로 3자 일치. S4 직행 분기 잔재 없음.
- ✅ `relatedFacilityIds`(복수)로 통일, `?focus=<id1>,<id2>` fitBounds 규칙 명확. 단수 잔재(`relatedFacilityId`, `?focus=단건`) 소멸 확인.

---

## 라운드 0 (최초 검수) — 기록 보존

> 아래는 최초 검수 원문이다. 라운드 1에서 🔴-1 및 🟡-1~6 전부 해소됨.

- **판정(당시)**: 🟡 조건부 통과 (필수 수정 1건 반영 후 개발 착수 가능)
- **요약(당시)**: MVP 범위 정합성·네비게이션·다국어·A11y·HIG 정합성은 전반적으로 견고. 다만 **시설 카테고리 분류 체계가 3곳(데이터 enum · 홈 칩 · 액센트 컬러 표)에서 서로 모순**되어 필수 수정 1건 존재.

---

## Findings

### 🔴 필수 수정 (1건)

#### 🔴-1. 시설 카테고리 분류 체계가 문서 내 3곳에서 상호 모순 (담당: ux-designer)

- **위치**: `4.1 카테고리 액센트 표` / `8. 데이터 모델 Facility.category` / `S1 홈 시설 카테고리 칩` / `4.5 MarkerPin`
- **문제**: 시설 카테고리 집합이 문서마다 다르며, 그중 하나는 시설이 아닌 **행정 가이드** 개념이 섞여 들어감.

  | 출처 | 시설 카테고리 집합 |
  |------|---------------------|
  | 데이터 모델(line 679) `Facility.category` enum | building, classroom, dining, library, amenity, **etc** |
  | 홈 S1 칩(line 124) | 건물, 강의실, 식당, 도서관, 편의, [전체] |
  | 액센트 컬러 표(4.1, line 523–530) | 건물, 강의실, 식당, 도서관, 편의시설, **긴급/도움(emergency)** |
  | MarkerPin(line 584) | "카테고리 6색" |

- **근거**:
  1. `emergency`(긴급/도움)는 **행정 가이드 카테고리**(S5, `AdminGuideCategory` enum)이지 시설 카테고리가 아니다. 시설 마커에 매핑될 대상이 아님.
  2. 그 결과 시설 `etc` 카테고리는 **마커/아이콘 액센트 컬러가 정의되지 않음** → `MarkerPin`·`CategoryChip` 렌더 시 색상 미정(디폴트/누락 버그).
  3. `cat.emergency` 컬러 토큰은 시설 어디에도 매핑되지 않는 **고아 토큰**이 됨.
- **영향**: app-developer가 `MarkerPin`/`CategoryChip`/필터를 구현할 때 색-카테고리 매핑 테이블을 만들 수 없어 작업 중단·재확인 필요. api-integrator의 `Facility.category` enum 계약도 흔들림.
- **제안 수정**:
  - 시설 카테고리 6종을 하나로 확정(예: `building, classroom, dining, library, amenity, etc`)하고 3곳을 일치시킬 것.
  - 4.1 액센트 표에서 `긴급/도움(cat.emergency)`을 제거하고 `기타(cat.etc)` 컬러를 추가.
  - 행정 가이드용 색이 필요하면 **별도 표**(`guideCat.*`)로 분리하거나, S5가 아이콘만 쓰므로 생략 명시.
  - 홈 칩의 `[전체]`는 카테고리가 아닌 필터임을 주석으로 구분.

---

### 🟡 권장 개선

#### 🟡-1. 딥링크(행정→지도) 계약이 단수/복수·목적지에서 모호 (담당: ux-designer)
- **위치**: `3. 딥링크`(line 475) / `S7`(line 327) / 데이터 모델(line 712)
- **문제**:
  - 모델은 `relatedFacilityIds: string[]`(복수)인데, 딥링크 규칙은 `relatedFacilityId`(단수, line 475)와 라우트 `/map?focus=<facilityId>`(단건)로 기술됨. **관련 시설이 2개 이상일 때 어느 마커를 포커스할지 미정.**
  - 관련 위치 카드 목적지가 곳에 따라 **"S2 지도 딥링크" 또는 "S4 시설 상세"**로 병기(line 327, 471)되어 기본 동작이 확정되지 않음.
- **근거**: 딥링크(행정→지도 마커 포커스)는 문서가 명시한 QA 회귀 대상(line 752)이자 핵심 셀링포인트인데, 계약이 갈리면 구현/테스트 기준이 흔들림.
- **제안**: (a) 카드 1장 = 시설 1건으로 두고 복수면 카드 N장 나열, 탭 시 해당 시설로 라우팅. (b) 기본 목적지를 "S2 지도(마커 selected + Peek 오픈)"으로 단일화하고 S4는 Peek의 [상세]로만 진입하도록 통일.

#### 🟡-2. `Facility.hours` 단일 필드가 다국어 원칙 위배 (담당: ux-designer → api-integrator 전달)
- **위치**: 데이터 모델(line 686) / `S4 운영시간`(line 244)
- **문제**: name/address/building/description은 모두 `_ko`/`_en`로 분리했는데 `hours: string?`만 단일. "09:00–22:00 **(평일)**"처럼 한글 라벨이 섞이면 영어 로케일에서 미번역 노출.
- **근거**: MVP 핵심 원칙 "모든 화면 한/영, 하드코딩 텍스트 0"(line 23).
- **제안**: `hours_ko`/`hours_en`로 분리하거나, 요일·시간을 구조화(`{day, open, close}[]`)해 라벨은 ARB 키로 렌더.

#### 🟡-3. 스코프 크리프 — MVP에 없던 기능 3종이 설계에 포함 (담당: ux-designer 검토)
- **위치**: 즐겨찾기(S10 + 전역 ☆), 검색 "철자 제안"(line 392, 624), 상세 공유 버튼 ⤴(S4/S7 line 228, 331)
- **문제**: `plan.md`/`00_input.md`의 MVP 범위(지도·시설 / 행정 틀 / 한·영 / 비로그인)에 **즐겨찾기·철자 제안·공유는 명시되지 않음.** 1인·1개월 일정에서 부가 부담.
  - 즐겨찾기: 전역 ☆ 토글 + 로컬 영속(Hive) + S10 + 스와이프 삭제 → 비용 중간.
  - 철자 제안(spell suggestion): 퍼지 매칭 필요 → MVP 대비 과설계.
  - 공유: 외부 딥링크가 Phase 2(line 478)인데 공유 페이로드 미정.
- **근거**: line 108 "1개월 안에 끝내려면 …을 반드시 지켜야 함. 범위 추가는 출시 후로."
- **제안**: 즐겨찾기는 유지하되 "축소 가능 항목"으로 표기, **철자 제안·공유 버튼은 Phase 2로 이월**하거나 공유 페이로드(텍스트 only)를 명시. 최소한 "선택/후순위"로 라벨링.

#### 🟡-4. 설정에 개인정보처리방침 진입점 부재 (담당: ux-designer)
- **위치**: `S9 설정 정보`(line 413–418)
- **문제**: 앱 소개/데이터 출처/문의/오픈소스 라이선스는 있으나 **개인정보처리방침(Privacy Policy) 링크가 없음.** `plan.md` 예산표(line 120)엔 방침 호스팅이 포함됨 → 스토어 심사 필수 항목.
- **제안**: 설정 정보 섹션에 "개인정보처리방침" 행 추가(외부/인앱 웹뷰). 위치 권한을 쓰므로 특히 필요.

#### 🟡-5. 탭4 라벨 한/영 불일치 (담당: ux-designer)
- **위치**: 사이트맵 `[탭4] 설정`(line 56) vs 탭 표 `설정 / More`(line 81)
- **문제**: 한글은 "설정"인데 영문은 "Settings"가 아닌 "More"로 표기 — 의미 불일치.
- **제안**: 설정/Settings 또는 더보기/More로 양 언어 의미를 통일.

#### 🟡-6. 대형 폰트(200%)에서 하단 고정 CTA 오버플로우 위험 (담당: ux-designer)
- **위치**: `S4`(line 246) `[지도에서 보기] [☎ 전화]` 2버튼 한 줄 고정
- **문제**: A11y 체크리스트는 "200%에서 스크롤 허용"(line 638)이나 **하단 고정 CTA는 스크롤 불가** → 2버튼 가로 배치가 대형 폰트/영문에서 줄바꿈·잘림.
- **제안**: 대형 텍스트 스케일에서 세로 스택으로 강등하는 규칙 명시(또는 아이콘+짧은 라벨 폴백).

---

### 🟢 양호 / 참고

- 🟢 **MVP 범위 정합성 우수**: 로그인·푸시·커뮤니티 제외가 정확히 지켜짐(비로그인, 즐겨찾기 로컬, FCM 없음). 행정은 "틀 + comingSoon 상태"로 자리표시자 처리(S7 Partial, `status` enum) — 요구와 정확히 일치.
- 🟢 **고아 화면 없음**: S1–S10 전 화면에 진입/이탈 경로 존재. 상세(S4/S7)의 탭바 유지 결정이 연속 탐색·딥링크와 정합.
- 🟢 **5상태 전 화면 정의**: Empty/Loading/Error/Success/Partial + 지도 Permission 폴백까지 화면별로 구체화 — QA 테스트 케이스화가 쉬움.
- 🟢 **A11y 설계 성숙**: 색 외 정보 3중(색+아이콘+라벨), 터치 48/44, 대비 기준, Locale 발음 지정, live region, 지도/목록 토글을 스크린리더 대체 경로로 제공.
- 🟢 **다국어 구조 견고**: ARB 키 컨벤션 `{screen}_{element}_{meaning}`, ICU 파라미터, 텍스트 팽창 30–50% 대응(Flexible/ellipsis), 카테고리 enum 키 고정으로 데이터-라벨 일원화.
- 🟢 **HIG/M3 분기 전략 타당**: 통일(색·타이포·아이콘·컴포넌트) vs 분기(`.adaptive` 6항목)로 한정 — 1인 개발 부담을 합리적으로 통제.
- 🟢 **실현성**: 화면 10개·상세 템플릿 2종·컴포넌트 15종 재사용으로 압축. 다만 카카오맵 Flutter 연동(커뮤니티 플러그인 의존)+Peek 시트+딥링크 카메라 이동이 최대 리스크 구간(2주차)임을 참고.
- 🟢 참고: 지도 권한 거부 시 캠퍼스 중심 폴백은 좋으나, 이때 리스트/Peek의 "거리(120m)" 산출 기준을 캠퍼스 중심으로 할지 명시하면 완결.

---

## 일관성 매트릭스 (화면 × 커버리지)

범례: ✅ 충족 / ⚠️ 부분·주의 / ❌ 미흡

| 화면 | 데이터필드 완결 | 네비(진입/이탈) | 다국어 | A11y | 종합 |
|------|:---:|:---:|:---:|:---:|:---:|
| S1 홈 | ✅ | ✅ | ✅ | ✅ | ✅ |
| S2 지도 | ⚠️(마커색 etc/emergency 🔴-1) | ✅ | ✅ | ⚠️(지도 SR, 토글로 완화) | ⚠️ |
| S3 시설 목록 | ✅ | ✅ | ✅ | ✅ | ✅ |
| S4 시설 상세 | ⚠️(hours 🟡-2, 카테고리색 🔴-1) | ✅ | ⚠️(hours) | ⚠️(200% CTA 🟡-6) | ⚠️ |
| S5 가이드 카테고리 | ✅ | ✅ | ✅ | ✅ | ✅ |
| S6 가이드 항목목록 | ✅ | ✅ | ✅ | ✅ | ✅ |
| S7 행정 상세 | ⚠️(relatedFacilityIds 🟡-1) | ⚠️(딥링크 목적지 🟡-1) | ✅ | ✅ | ⚠️ |
| S8 검색 | ✅ | ✅ | ✅ | ⚠️(철자제안 과설계 🟡-3) | ⚠️ |
| S9 설정 | ⚠️(개인정보방침 부재 🟡-4) | ✅ | ⚠️(라벨 More 🟡-5) | ✅ | ⚠️ |
| S10 즐겨찾기 | ✅ | ⚠️(진입 설정 단일, 허용) | ✅ | ✅ | ✅ |

---

## 관점별 판정 요약

| 검증 관점 | 판정 | 핵심 |
|-----------|:---:|------|
| 1. MVP 범위 정합성 | ⚠️ | 제외 항목 준수 우수. 단 즐겨찾기·철자제안·공유가 스코프 밖 추가(🟡-3) |
| 2. 화면/네비게이션 일관성 | ⚠️ | 고아 화면 없음. 딥링크 계약 단수/복수·목적지 모호(🟡-1) |
| 3. 접근성(A11y) | ✅ | 성숙. 200% 고정 CTA만 보완(🟡-6) |
| 4. 다국어(한/영) | ⚠️ | 구조 견고. hours 단일필드가 원칙 위배(🟡-2) |
| 5. iOS HIG / M3 정합성 | ✅ | 통일/분기 전략 타당 |
| 6. 데이터 필드 완결성 | ❌→수정필요 | 카테고리 분류 3중 모순(🔴-1), hours(🟡-2), relatedFacilityIds(🟡-1) |
| 7. 구현 실현성(1인·1개월·$500) | ⚠️ | 대체로 실현 가능. 스코프 크리프 정리 권장(🟡-3) |

---

## 테스트 커버리지 (UX 단계 — 문서 정합 검증)

| 영역 | 점검 수 | 통과 | 이슈 | 비고 |
|------|:---:|:---:|:---:|------|
| MVP 범위 정합 | 6 | 5 | 1 | 스코프 크리프 |
| 화면/네비 일관성 | 10화면 | 9 | 1 | 딥링크 계약 |
| 데이터 모델 정합 | 3모델 | 1 | 2 | 카테고리(🔴)·hours |
| 다국어 | 5 | 4 | 1 | hours |
| A11y | 11항목 | 10 | 1 | 200% CTA |
| HIG/M3 | 9항목 | 9 | 0 | — |

---

## 재검수 조건 (Re-verify)

- 🔴-1 반영 시: 4.1 액센트 표 / 8. `Facility.category` enum / S1 칩 / 4.5 MarkerPin 4곳의 카테고리 집합 **일치 여부** 재확인.
- 🟡-1·🟡-2 반영 시: 데이터 모델과 S7·S4 화면 필드 재대조.

## ux-designer 액션 아이템 (우선순위)

1. **[필수] 🔴-1** 시설 카테고리 6종 단일 확정 + 액센트 표/enum/홈칩/MarkerPin 동기화 (emergency 제거, etc 색 추가)
2. [권장] 🟡-1 딥링크 관련시설 단수/복수·목적지(S2 단일) 확정
3. [권장] 🟡-2 `hours` → `hours_ko/hours_en` 분리
4. [권장] 🟡-3 철자제안·공유 Phase 2 이월, 즐겨찾기 "축소가능" 표기
5. [권장] 🟡-4 설정에 개인정보처리방침 진입점 추가
6. [권장] 🟡-5 탭4 라벨 한/영 통일, 🟡-6 대형폰트 CTA 세로강등 규칙

---
---

# 2주차(코드) 교차검증 — 앱 골격 + 시설 화면 + 데이터 계층 (정적 검증)

> 검수일: 2026-07-10 · 대상: `02_app_code/`, `02_app_architecture.md`, `03_api_integration.md`
> 기준(SoT): `01_ux_design.md`(화면·토큰·§8 데이터모델·딥링크), `00_input.md`, `plan.md`
> 방식: Flutter 빌드 불가 환경 → 코드 리딩 기반 정적 검증

## 종합 판정 (2주차 · 라운드 3 실기기 런타임 검증 반영 · 최종)

- **판정**: 🟢 **2주차 통과 — 실기기(에뮬레이터) 런타임까지 검증 완료, 3주차 착수 가능 (남은 🔴 0건)**
- **요약(최종)**: 정적 검증(라운드 0/1) → 실제 컴파일·부팅(라운드 2) → **실기기 런타임(라운드 3)** 까지 3단계 전부 통과. 라운드 3에서 Android 에뮬레이터(Pixel_7)에 실제 빌드·설치·실행해 **홈(S1)·지도(S2 카카오 지도 실렌더)·i18n·라우팅이 화면상 정상 동작**함을 스크린샷으로 확인했다. 실기기에서만 드러나는 결함(Android compileSdk 36 요구, 매니페스트 네트워크 권한, 카카오맵 서비스 활성화)을 전부 해소. 남은 🔴 0건.

> "라운드 3"이 2주차 최신 판정이다. 라운드 0/1/2는 원문 보존.

---

## 라운드 2 — 실제 빌드 검증 (2026-07-14)

라운드 0/1은 "Flutter 빌드 불가 환경 → 코드 리딩 정적 검증"이었다. 이 라운드는 **Flutter stable SDK를 실제 설치(3.44.6 / Dart 3.12.2)하고 실제 컴파일·부팅**까지 수행해, 정적 검증으로 못 잡는 세 부류(서드파티 버전 해소·타입 분석·플러그인 API 시그니처)를 실증했다.

### 실행 파이프라인 결과

| 단계 | 명령 | 결과 |
|------|------|:---:|
| 의존성 해소 | `flutter pub get` | ✅ 71개 (intl 수정 후) |
| 다국어 생성 | gen-l10n (pub get 자동) | ✅ `lib/l10n/gen/` 3파일 |
| 정적 분석 | `flutter analyze` | 🟢 **No issues found!** |
| 부팅 스모크 | `flutter test` | 🟢 **All tests passed** (홈 탭 렌더) |

### 라운드 2에서 잡아 고친 결함

| # | 심각도 | 위치 | 내용 | 조치 |
|---|:---:|------|------|------|
| B1 | 🔴 차단 | `pubspec.yaml` | `flutter_localizations`가 `intl 0.20.2`를 고정 → `^0.19.0` 충돌로 `pub get` 실패 | `intl: ^0.20.2`로 상향 (API 호환) |
| B2 | 🔴 차단 | `campus_map_view.dart:57` | `kakao.LatLng`가 const 생성자 아님에 `const` 사용 → 컴파일 오류 | `const` 제거 |
| B3 | 🟡 | `campus_map_view.dart:42` | 미사용 `markerImageFor` (3주차 플레이스홀더) | 제거, doc 주석 정리 (3주차 재도입) |
| B4 | ℹ️ | `mock_data.dart` ×6 | `Facility(...)` const 미사용 | `const Facility(...)` |
| B5 | ℹ️ | `locale_provider.dart:3` | 불필요한 `flutter/widgets.dart` import | 제거 (`dart:ui`로 충분) |
| B6 | ℹ️ ×4 | `settings_stub_screen.dart` | 폐기된 `RadioListTile.groupValue/onChanged` (Flutter 3.32+) | `RadioGroup` 조상 패턴으로 마이그레이션 |
| B7 | ⚠️ 경고 | `l10n.yaml` | 폐기된 `synthetic-package` 옵션 | 제거 |

> B1·B2는 **정적 검증으로는 원리적으로 못 잡는** 실제 빌드 게이트 결함으로, 이번 실빌드의 핵심 성과다. 나머지는 신버전 SDK 기준 lint/폐기 API 정리.

### 검증 환경/한계

- 환경: Windows 11, Flutter 3.44.6 stable (git clone), Dart 3.12.2.
- `flutter analyze` + 위젯 스모크 테스트까지 실행. 실기기 런타임은 **라운드 3에서 수행**.
- 생성물 `lib/l10n/gen/`·`.dart_tool/`은 `.gitignore` 처리됨. `pubspec.lock`은 커밋 대상(생성 확인).

---

## 라운드 3 — 실기기(에뮬레이터) 런타임 검증 (2026-07-14)

라운드 2가 컴파일·부팅까지였다면, 이 라운드는 **Android 에뮬레이터(Pixel_7, API 36)에 실제 빌드·설치·실행**해 화면 동작과 카카오 지도 실렌더를 스크린샷으로 확인했다. `flutter create`로 android/ios 플랫폼 폴더 생성 후 `flutter run --dart-define=KAKAO_JS_KEY=…`로 구동.

### 화면 동작 결과 (스크린샷 확인)

| 화면 | 결과 |
|------|:---|
| S1 홈 | 🟢 시설 6종·행정 6종 카드, ko/EN 토글, 하단 4탭 정상 렌더 |
| S2 지도 | 🟢 **카카오 지도 타일 실렌더**(도로·지하철·랜드마크·kakao 로고·축척), 카테고리바·내위치 FAB 오버레이 |
| i18n / 라우팅 / 상태관리 | 🟢 부팅~네비게이션 정상, 치명적 예외 없음 |

### 라운드 3에서 잡아 고친 결함 (실기기에서만 발현)

| # | 심각도 | 위치 | 내용 | 조치 |
|---|:---:|------|------|------|
| C1 | 🔴 차단 | `android/app/build.gradle.kts`, `android/build.gradle.kts` | `webview_flutter_android`(kakao_map_plugin 의존)가 **compileSdk ≥ 36** 요구. Flutter 3.44 기본값(35)이라 `:kakao_map_plugin:checkDebugAarMetadata` 실패 | 앱 `compileSdk=36` + 루트에서 전 서브프로젝트 compileSdk 36 강제(평가상태 가드) |
| C2 | 🔴 차단 | `android/app/src/main/AndroidManifest.xml` | INTERNET 권한·cleartext 없음 → 카카오 WebView 지도 로드 불가 | `<uses-permission INTERNET>` + `android:usesCleartextTraffic="true"` |
| C3 | 🔴 차단 | `kakao_init.dart` / 카카오 콘솔 | 지도 흰 화면 + 콘솔 `kakao is not defined`. 실원인은 **카카오 "지도/로컬(OPEN_MAP_AND_LOCAL)" 서비스 비활성화** (`NotAuthorizedError`) | 초기화에 `baseUrl:'http://localhost'` 추가(도메인 정합) + **카카오 콘솔에서 카카오맵 서비스 활성화** (제품 설정→카카오맵→활성화 ON). 호스트에서 sdk.js HTTP 200 확인 후 실렌더 확인 |
| C4 | 🟡 | `test/widget_test.dart` | `flutter create`가 생성한 기본 카운터 테스트가 스모크와 충돌 | 삭제 (smoke_test.dart 유지) |

> C1~C3은 **정적 검증은 물론 `analyze`/`test`로도 못 잡는** 순수 런타임/인프라 결함으로, 실기기 실행의 핵심 성과다. 특히 C3(카카오맵 서비스 활성화)은 키·도메인이 아니라 **제품 활성화 토글**이 원인이었다.

### 검증 환경/한계

- 대상: Android 에뮬레이터 Pixel_7 (API 36). 카카오 JS 키는 `--dart-define`으로만 주입(파일 미저장).
- **iOS 런타임은 미수행**(macOS 필요). Firebase는 mock 모드(`USE_FIRESTORE` 미설정)로 실행 — 실 Firestore 연동은 `flutterfire configure` 후 별도 확인 필요.
- 지도 마커는 카카오 기본 핀(6색 커스텀 PNG는 3주차 예정). 실 캠퍼스 좌표 반영도 3주차.

---

## 라운드 1 재검수 (2026-07-10) — 변경 파일 검증

### 재검수 판정 요약

| 항목 | 라운드 0 | 판정 | 근거(변경 위치) |
|------|:---:|:---:|------|
| 🔴-C1 서비스 계정 키 .gitignore | 🔴 | ✅ **해소** | `.gitignore` L16-19 + `03_api_integration.md` §5 L150 정정 |
| 🟡-C1 pubspec.lock 커밋 | 🟡 | ✅ **해소** | `.gitignore` L7(무시 제거) |
| 🟡-C3 지도 Empty 스낵바 1회 | 🟡 | ✅ **해소** | `map_screen.dart` L52-65 `ref.listen` |

**남은 🔴: 0건 / 남은 🟡: 0건(3건 반영) / 신규 모순·회귀: 없음**

### 🔴-C1 상세 [해소]
- `.gitignore` L16-19에 주석과 함께 `tool/firestore_seed/serviceAccount.json`·`node_modules/` 추가됨 → 관리자 개인키·npm deps가 커밋 대상에서 제외.
- `03_api_integration.md` §5(L150)이 "the Admin service-account key lives only in `tool/firestore_seed/serviceAccount.json`, **which is git-ignored** (`02_app_code/.gitignore` — …) so it can never be committed"로 **정정** → 문서-현실 불일치 제거. (TODO의 미완 항목도 실질 완료.)
- **회귀 점검**: 두 패턴 모두 `tool/firestore_seed/` 하위/루트 `node_modules`만 겨냥 → 시드 JSON(`facilities.seed.json`/`guide_items.seed.json`)·`seed.mjs`·README는 그대로 추적됨(과다 무시 없음). ✅

### 🟡-C1 상세 [해소]
- `.gitignore` L7에서 `pubspec.lock` 라인이 제거되고 "애플리케이션은 재현 빌드 위해 커밋" 주석으로 대체 → lock 파일 추적됨.
- **회귀 점검**: `.dart_tool/`·`build/`·`.flutter-plugins`·`.packages`·`lib/l10n/gen/`(생성물)·시크릿(`*.env`/`env.json`) 등 정상 무시 항목은 그대로 유지 → 필요한 파일을 잘못 무시하거나 불필요한 산출물을 추적하지 않음. ✅

### 🟡-C3 상세 [해소]
- `map_screen.dart` L55-65: 스낵바가 `build()`의 `addPostFrameCallback`에서 **`ref.listen<AsyncValue<List<Facility>>>`로 이동**, `nextEmpty && !prevEmpty`(빈 결과로의 **상태 전이**)에서만 1회 노출.
- **회귀/충돌 점검**:
  - 마커 탭 → `setState(_selectedId)` 리빌드는 `filteredFacilitiesProvider` 값 불변 → `ref.listen` 미발화 → **재노출 없음**. ✅
  - 지속적 빈 상태(리빌드 반복)에서도 `prevEmpty==true`라 재발화 안 됨. ✅
  - 카카오 키 없음 시 `if (!AppConfig.hasKakaoKey) return;` 가드로 리스너 조기 반환 → 폴백 `ErrorStateView`(L107-115)와 스낵바 **중첩 없음**. ✅
  - `_buildMap` 내 기존 스낵바 블록은 제거되고 주석("handled once via ref.listen")으로 대체 → 이중 노출 경로 소멸. ✅
  - `ref.listen`은 `ConsumerState.build` 내 호출로 Riverpod 규약 준수(빌드당 1회 등록). ✅

---

## 라운드 0 (2주차 최초 검수) — 기록 보존

> 아래는 최초 검수 원문이다. 라운드 1에서 🔴-C1·🟡-C1·🟡-C3 전부 해소됨.

- **판정(당시)**: 🟡 조건부 진행 — 🔴 1건(서비스 계정 키 .gitignore 누락) 수정 후 3주차 착수
- **요약(당시)**: 아키텍처·데이터 계약·화면 구현이 UX/아키텍처 문서와 **매우 일관**. 도메인↔데이터↔UX §8 3자 필드 일치, Repository 시그니처 불변, Mock↔Firestore 토글 성립. **단 1건 보안 결함**(서비스 계정 키 `.gitignore` 누락)만 필수 수정이었음.

## Findings (2주차)

### 🔴 필수 수정 (1건)

#### 🔴-C1. Firebase Admin 서비스 계정 키가 `.gitignore`에 없음 — 키 커밋 위험 (담당: api-integrator)
- **위치**: `02_app_code/.gitignore` / `tool/firestore_seed/seed.mjs`(L28-30) / `03_api_integration.md` §5(L150)·TODO(L202)
- **문제**: 시더가 `tool/firestore_seed/serviceAccount.json`(Firestore **전체 관리자 권한** 개인키)을 읽는데, `.gitignore`에는 `*.env`·`env.json`만 있고 **`serviceAccount.json`/`node_modules/`가 없다.** 개발자가 README 지시대로 키를 생성한 뒤 `git add .` 하면 관리자 키가 그대로 커밋된다.
- **근거**:
  1. `03_api_integration.md` §5(L150)은 "the Admin service-account key lives only in the **untracked** `tool/firestore_seed/serviceAccount.json`"라고 **단언**하지만 실제 `.gitignore`는 그것을 untrack하지 않음 → **문서-현실 불일치**가 오히려 개발자를 안심시켜 키 유출을 유발.
  2. 같은 문서 Remaining TODO L202가 "`.gitignore`: add `tool/firestore_seed/serviceAccount.json` and `node_modules/`"라고 **미완 항목으로 자인**.
  3. QA 보안 체크리스트 필수 항목("서비스 계정 키 누출 방지(.gitignore)")에 직접 위배.
- **영향**: 관리자 키 유출 시 Firestore 임의 읽기/쓰기/삭제 가능 — MVP 보안의 단일 최악 시나리오. (현재 키 파일이 아직 없어 **예방적**이나, 생성 즉시 위험이 실현되므로 사전 차단 필수.)
- **제안 수정**(api-integrator, 2줄):
  ```
  # Firestore Admin SDK service-account key — NEVER commit
  tool/firestore_seed/serviceAccount.json
  node_modules/
  ```
  추가 후 §5 문구가 사실과 일치하게 됨.

### 🟡 권장 개선

- **🟡-C1 `pubspec.lock` gitignore (담당: app-developer)**: `.gitignore` L7이 `pubspec.lock`을 제외. 애플리케이션(패키지 아님)은 재현 가능 빌드를 위해 lock 커밋이 Flutter 공식 권장. 1인 MVP엔 경미하나, 플러그인(kakao_map_plugin 등) 버전 드리프트 방지 위해 커밋 권장.
- **🟡-C2 S3 정렬 컨트롤 미구현 (담당: app-developer, 계획된 이월)**: UX S3 와이어프레임의 정렬(거리순/이름순) 드롭다운이 `facility_list_screen.dart`에 없음. `common_sortDistance/Name` 문자열은 선언됨. 거리 계산이 위치권한(3주차) 의존이라 아키텍처 TODO에 명시 이월됨 — **정당한 지연**이나 3주차 잔여로 추적 필요.
- **🟡-C3 지도 Empty 스낵바 반복 노출 위험 (담당: app-developer)**: `map_screen.dart` L103-110, 필터 결과 0일 때 `addPostFrameCallback`에서 스낵바를 띄우는데 리빌드마다 재실행될 수 있음(clearSnackBars로 완화되나 근본 억제 아님). 플래그/`ScaffoldMessenger` 1회성 가드 권장.
- **🟡-C4 검색 결과→가이드 상세 스텁 라우팅 (담당: app-developer, 계획된 이월)**: `search_screen.dart` L220 가이드 결과 탭 시 `/guide`(스텁)로 이동, 카테고리/항목 컨텍스트 소실. S7이 3주차라 수용 가능하나 주석대로 3주차에 딥링크 연결 필요.

### 🟢 양호 (핵심 검증 통과)

- 🟢 **데이터 계약 3자 일치**: `Facility`/`AdminGuideItem` `fromJson` 필드명(`name_ko`, `hours_ko/en`, `relatedFacilityIds`, `categoryId`, `imageUrl`, `updatedAt`) = Firestore 스키마(§1) = UX §8. 시설 enum `{building…etc}`, unknown→`etc` 폴백이 엔티티(`fromId` orElse etc)·Firestore(§1 "unknown → etc") 양쪽 동일. `status` 기본 `comingSoon` 일치.
- 🟢 **인터페이스 시그니처 불변**: `FacilityRepository`/`GuideRepository`/`FavoritesRepository`가 도메인 인터페이스 = Mock 구현 = Firestore 구현에서 동일. api-integrator는 `repository_providers.dart` 2개 Provider와 `main.dart` init 훅(사전 승인됨)만 변경 → 화면·프로바이더·엔티티 무수정. **Mock↔Firestore 토글 성립**(`useFirestore` 단일 플래그).
- 🟢 **딥링크 계약 정합**: `/map?focus=<id1>,<id2>` 라우터 파싱(`app_router.dart` L50-54) → `MapScreen.focusIds` → `CampusMapView._applyFocus`(단건 `setCenter`/복수 `fitBounds`) + 대표(첫) 마커 Peek. UX 라운드1 계약과 일치. 시드 데이터 정합: `arc-issue.relatedFacilityIds=["oia-office"]`, `oia-office`가 `facilities.seed.json`에 존재.
- 🟢 **시설 6종·6색**: `FacilityCategory` enum 6종, `CategoryColors`가 시설6+가이드6을 분리 정의(UX 라운드1 반영), `forFacility`/`forGuide` 스위치 완비. 색+아이콘+라벨 3중(A11y).
- 🟢 **5상태 통일**: `state_views`(Skeleton/Empty/Error) + `AsyncValue.when`으로 S1-S4/S8 전 화면 처리. S4 Partial(결측 행 숨김, 이미지→카테고리 배너), 지도 Error(키없음/로드실패 폴백+목록 이동), 검색 Empty(최근검색/결과0).
- 🟢 **CTA 세로 스택**: `facility_detail_screen.dart` `_BottomCta` L296-320, `scale>=1.3 || width<340` 시 세로 전환, 각 버튼 48dp. UX §S4 A11y 규칙 반영.
- 🟢 **다국어**: ko/en ARB 키 패리티 일치(`nullable-getter:false`로 `AppLocalizations.of`가 non-null → 컴파일 안전). 로케일 폴백(`_pick`), 즉시 토글(`localeProvider`), enum→라벨 매핑 일원화(`category_labels`). hours_ko/en 분리 반영.
- 🟢 **보안(키/규칙)**: 카카오 키·Firebase 옵션 하드코딩 없음(`--dart-define`, `REPLACE_*` 플레이스홀더). `firestore.rules` 공개 read·클라 write 차단·default deny 타당. `env.json`/`*.env` gitignore됨.
- 🟢 **성능/무료티어**: 전체로드+클라필터+Firestore 영속캐시+`Source.cache` 폴백 → 캠퍼스 소량 데이터에 타당, Hive/Isar 미도입(근거 문서화, 과설계 회피). `allFacilitiesProvider` 단일 로드 공유(지도·목록 중복쿼리 없음), 검색은 캐시서브 0-read. Spark 50k read/day 내 여유 → $0.
- 🟢 **빌드 타당성(정적)**: import 해소·Provider override(`sharedPreferencesProvider`)·라우터 결선·테마 확장(`context.dimens`/`catColors`) 일관. `withValues`·`textScalerOf` 등 SDK ≥3.27 API와 pubspec 제약 정합. 카카오 결합은 `campus_map_view`/`kakao_init` 2파일 격리. (실행 검증은 불가 — pub get 후 gen-l10n·flutter create 전제.)
- 🟢 **스텁 범위 타당**: S5-S7(가이드)·S9/S10(설정·즐겨찾기)는 스텁, 즐겨찾기 저장 로직은 이미 동작(`LocalFavoritesRepository`). 2주차 계획(골격+시설+데이터)과 부합, 과설계 없음.

## 일관성 매트릭스 (화면 × 데이터필드 × 계약 × 보안)

범례: ✅ 충족 / ⚠️ 부분·주의 / ❌ 미흡 / — 해당없음

| 화면 | 데이터필드(§8) | Repository 계약 | 5상태 | 딥링크 | A11y | 비고 |
|------|:---:|:---:|:---:|:---:|:---:|------|
| S1 홈 | ✅ | ✅(정적+repo) | ✅ | ✅(→map/list) | ✅ | 가이드 타일 3주차 딥링크 이월 |
| S2 지도 | ✅ | ✅ getAll | ✅(+키없음 폴백) | ✅ focus파싱 | ⚠️ | 마커 6색 PNG·거리 3주차 |
| S3 목록 | ✅ | ✅ getAll/filter | ✅ | ✅(→detail) | ✅ | 🟡-C2 정렬 미구현 |
| S4 상세 | ✅(hours_ko/en) | ✅ getById | ✅ Partial | ✅(→map focus) | ✅ CTA세로 | — |
| S8 검색 | ✅ | ✅ search×2 | ✅ | ⚠️ | ✅ | 🟡-C4 가이드→스텁 |
| S5–S7 가이드 | — | ✅(계약선언) | — | — | — | 스텁(3주차) |
| S9/S10 설정·즐겨 | ✅ 로컬 | ✅ favorites | — | — | ✅ | 스텁, 저장로직 동작 |

| 계약/인프라 | 상태 | 근거 |
|------|:---:|------|
| 도메인 fromJson ↔ Firestore 스키마 ↔ UX §8 | ✅ | 필드명·enum·기본값 3자 일치 |
| Repository 시그니처(인터페이스=Mock=Firestore) | ✅ | 무수정 스왑 성립 |
| Mock↔Firestore 토글(화면 무영향) | ✅ | `useFirestore` 단일 플래그 |
| 카카오/Firebase 키 하드코딩 | ✅ 없음 | dart-define·REPLACE 플레이스홀더 |
| Firestore 보안 규칙 | ✅ | 공개read·write차단·default deny |
| **서비스 계정 키 .gitignore** | ❌ | **🔴-C1 누락** |
| 무료 티어(Spark) | ✅ | 세션당 수십 read, $0 |

## 테스트 커버리지 (2주차 정적)

| 영역 | 점검 | 통과 | 이슈 |
|------|:---:|:---:|:---:|
| 설계 정합(S1-S4/S8) | 5화면 | 5 | 0(경미 이월 2) |
| 데이터 계약 3자 | 3엔티티 | 3 | 0 |
| 인터페이스 불변/토글 | 3repo | 3 | 0 |
| 빌드 타당성(정적) | — | ✅ | 0 |
| 보안 | 5항목 | 4 | 1(🔴-C1) |
| 성능/무료티어 | — | ✅ | 0 |
| 접근성(코드범위) | — | ✅ | 0 |

## 다음 라운드 수정 요청

- **api-integrator [🔴-C1 필수]**: `.gitignore`에 `tool/firestore_seed/serviceAccount.json`·`node_modules/` 추가. 반영 후 재검수는 해당 파일만 확인.
- **app-developer [🟡, 비차단]**: 🟡-C1 pubspec.lock 커밋 정책 결정, 🟡-C3 지도 Empty 스낵바 1회성 가드. 🟡-C2/C4는 3주차 계획 항목으로 추적.
