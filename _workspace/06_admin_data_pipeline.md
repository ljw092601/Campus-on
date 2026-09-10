# 관리자 데이터 입력 파이프라인 설계 (학사일정 · 학식)

> 상태: **합의 확정 — Claude 초안 → Codex 검토(06_review_codex.md) → 2라운드 합의 완료** (2026-09-10)
> 확정 합의안은 §7. §1~§6은 초안 원문이며 §7과 충돌 시 §7이 우선.
> 배경: 학사일정·학식은 학교 API 제공 불가 확정. 비개발자 관리자가 직접 입력해야 함.
> 결정된 방향: Google Sheets(입력) + Apps Script(동기화) + Firestore(저장) + 앱은 Firestore 리포지토리로 읽기.

## 1. Firestore 컬렉션 스키마

### 1-1. `academic_events` (학사일정)

문서 ID: 슬러그 (예: `2026-fall-registration`). Apps Script가 `연도-일정명` 기반으로 생성.

| 필드 | 타입 | 예시 | 비고 |
|---|---|---|---|
| `title_ko` | string | "2학기 수강신청" | 필수 |
| `title_en` | string | "Fall course registration" | 필수 |
| `category` | string | `registration` | `semester\|registration\|exam\|holiday\|graduation` |
| `start` | string | "2026-08-10" | YYYY-MM-DD (기존 `AcademicEvent.fromJson`이 DateTime.parse로 파싱) |
| `end` | string \| null | "2026-08-14" | 단일 일정이면 null |
| `updatedAt` | timestamp | — | 동기화 시각 |

기존 앱 엔티티 `AcademicEvent.fromJson`과 필드명 일치 → 앱 코드 수정 불필요.

### 1-2. `cafeterias` (식당 정적 정보) — 신규 분리

식당 이름/운영시간/캠퍼스는 거의 안 바뀌므로 일별 문서에서 분리.

문서 ID: `seunghak-student` 등 (기존 mock id 유지).

| 필드 | 타입 | 비고 |
|---|---|---|
| `name_ko` / `name_en` | string | |
| `campus` | string | `seunghak\|gudeok\|bumin` |
| `hours_ko` / `hours_en` | string | |
| `facilityId` | string | 지도 핀 연결 (예: `s02`) |
| `mealTypes` | array | 제공 식사 슬롯 (예: `["breakfast","lunch","dinner"]`) |

### 1-3. `dining_menus` (일별 식단)

문서 ID: `<cafeteriaId>_<YYYY-MM-DD>` (예: `seunghak-student_2026-09-14`).

| 필드 | 타입 | 비고 |
|---|---|---|
| `cafeteriaId` | string | `cafeterias` 문서 참조 |
| `date` | string | "2026-09-14" |
| `meals` | array | `[{type: "lunch", items: ["제육볶음", ...], price: 5500}, ...]` — 기존 `Meal.fromJson`과 일치 |
| `updatedAt` | timestamp | |

앱의 `FirestoreDiningRepository.getMenus(date)`: `cafeterias` 전체 + 해당 날짜 `dining_menus` 쿼리(`where date ==`) 후 조인해 `CafeteriaMenu` 구성. 메뉴 문서가 없는 식당 = meals 빈 배열(= 휴무/미등록).

**미결(논의 필요) D1**: 메뉴 미등록과 휴무 구분. 현재 엔티티는 `meals.isEmpty == 휴무`. 관리자가 입력을 안 한 날과 실제 휴무를 구분할지? → 초안: 구분하지 않고 "오늘은 운영하지 않아요" 문구를 "식단이 등록되지 않았어요"로 통합 교체하는 안 vs `isClosed` 필드 추가 안.

## 2. 보안 규칙

```
academic_events, cafeterias, dining_menus: read: true, write: false
```

쓰기는 Firestore REST API(v1) + Google OAuth(IAM) 경로만 사용 → 보안 규칙의 영향을 받지 않음. 관리자 Google 계정에 Firebase 프로젝트 IAM 역할 `Cloud Datastore User`만 부여. **서비스 계정 키를 시트/스크립트에 심지 않는다.**

## 3. Google Sheets 양식

스프레드시트 1개, 시트(탭) 2장 + 안내 탭.

### 시트 "학사일정"
| 시작일 | 종료일(선택) | 일정명(국문) | 일정명(영문) | 분류 | 상태 |
- 시작일/종료일: 날짜 형식 데이터 검증
- 분류: 드롭다운 (학사/수강/시험/휴일/졸업 → category 매핑)
- 상태: 스크립트가 기록 (✅ 동기화됨 / ❌ 오류 메시지)
- 헤더 행 보호

### 시트 "학식"
| 날짜 | 식당 | 식사 | 메뉴 (쉼표로 구분) | 가격 | 상태 |
- 식당: 드롭다운 (승학/구덕/부민 학생식당 → cafeteriaId 매핑)
- 식사: 드롭다운 (조식/중식/석식)
- 한 행 = 한 식당의 한 끼. 주간 입력 시 지난주 블록 복사 → 날짜만 수정하는 흐름.

### 동기화 UX
- 커스텀 메뉴 "동아메이트 → Firestore로 동기화" 버튼
- 실행: 행 검증 → 오류 행은 빨간 배경 + 상태 칸에 한국어 사유 → 정상 행만 업로드 → 완료 다이얼로그(N건 반영)
- 인증: `ScriptApp.getOAuthToken()` (Apps Script의 GCP 프로젝트를 Firebase 프로젝트로 연결, scope `cloud-platform`)

**미결(논의 필요) D2**: 삭제 처리. 시트에서 행을 지우면 Firestore에서도 지워져야 하나? → 초안: 학사일정은 full-replace(컬렉션 전체를 시트 기준으로 맞춤, prune 포함), 학식은 upsert-only(같은 식당+날짜 문서만 덮어씀, 과거 데이터 보존).

## 4. 앱 변경

1. `FirestoreAcademicCalendarRepository` / `FirestoreDiningRepository` 구현 (기존 `FirestoreGuideRepository` 패턴)
2. `repository_providers.dart`에서 `useFirestore` 분기 (mock은 개발 모드 유지)
3. 학식 D1 결정에 따른 문구/엔티티 미세 수정
4. 테스트: fromJson 라운드트립 + fake Firestore 경로는 기존 관례를 따름

## 5. 산출물 목록

- `firestore.rules` 갱신
- `tool/admin_sheets/` — Apps Script 소스(clasp 구조) + 시트 템플릿 생성 스크립트 + 관리자용 안내문서(1장, 비개발자 대상)
- 앱 리포지토리 2종 + 테스트
- seed 파이프라인에 `academic_events`/`cafeterias` 초기 시드 추가 (mock → seed JSON 기존 흐름 재사용)

## 6. 논의 포인트 요약 (Codex 검토 요청)

- **D1**: 학식 미등록 vs 휴무 구분 방법
- **D2**: 시트 삭제 반영 정책 (학사일정 full-replace / 학식 upsert 초안)
- **D3**: 스키마 전반 — 특히 `dining_menus` 문서 단위(식당×날짜)와 `cafeterias` 분리가 적절한지, 쿼리 비용/오프라인 캐시 관점 이견 여부
- **D4**: Apps Script 인증 방식(OAuth/IAM) vs 서비스 계정 키 vs Cloud Functions 프록시 — 초안은 OAuth/IAM
- **D5**: 그 외 위험 요소나 더 나은 대안

## 7. 확정 합의안 (2026-09-10, Claude·Codex 2라운드 합의)

### 데이터 모델
- **D1**: `dining_menus` 문서에 `status: open | closed | unpublished` 추가. 문서 없음 = `unpublished`(미등록). `open`이면 meals 1개 이상 필수(검증). 앱 엔티티에 availability enum 추가, `isClosed`는 파생 getter로 유지.
- **학사일정 ID**: 시트에 불변 `event_id` 숨김 열(최초 동기화 시 생성, 이후 불변). 슬러그 재생성 방식 폐기.

### 동기화 정책 (D2)
- **학사일정**: 전 행 검증 통과 시에만 게시. 기존 문서 ID를 먼저 읽어 write+delete를 **단일 atomic batch(500건 이하)**로 커밋 = 시트 기준 full-replace. 하나라도 오류면 전체 게시 중단(부분 게시 없음). 삭제 예정 diff를 관리자에게 확인받고, 롤백은 구글 시트 버전 이력으로 복원 후 재동기화. 버전 컬렉션(versioned publish)은 이 규모에서 채택하지 않음.
- **학식**: 시트에 '상태' 열(게시/휴무/게시취소). 동기화는 시트에 존재하는 (식당×날짜) 그룹만 대상 — 끼니 행을 그룹화해 문서 1개를 원자적으로 덮어쓰기. 상태는 그룹 단위 단일값, 게시취소는 삭제가 아닌 `status: unpublished` tombstone. 그룹 내 한 행이라도 오류면 해당 문서 전체 실패. 과거 문서 보존, TTL 정리는 후순위.

### 앱 (D3)
- `FirestorePaths`에 컬렉션 상수 + 문서 ID 주입/Timestamp 정규화 매퍼(기존 패턴 준수). 
- `academic_events`는 `orderBy('start')` 또는 파싱 후 명시 정렬. `cafeterias`는 provider 캐시로 날짜마다 재조회하지 않음.
- 서버 실패 시 `Source.cache` fallback + 캐시 부재와 미등록 구분(`unpublished` UI 문구 별도).
- 기능 플래그 분리: `USE_FIRESTORE_CALENDAR`, `USE_FIRESTORE_DINING` (기본 false, 기존 `USE_FIRESTORE`와 독립). `initFirebaseIfEnabled`는 세 플래그의 OR로 초기화.

### 인증·보안 (D4)
- Apps Script `ScriptApp.getOAuthToken()` + Firestore REST, scope manifest 고정. 전용 관리자 그룹에만 IAM 부여(일반 시트 편집자와 분리), 최소권한 custom role 검증. 문서 ID·컬렉션명은 시트 값이 아닌 allowlist 매핑으로만 생성. 운영자 확대 시 Cloud Functions 프록시로 이전 검토.
- **기존 `tool/firestore_seed/serviceAccount.json` 키는 GCP에서 폐기/회전하고 로컬 파일 삭제(사용자 액션 필요), seed.mjs는 ADC(gcloud auth application-default login)로 전환.**

### 운영 안전 (D5)
- Apps Script에서 엄격 검증: enum allowlist(관용 fallback 금지), `end < start`, 중복 event_id, 식당×날짜×끼니 중복, 빈 번역, 가격 범위, 날짜는 `Asia/Seoul` 고정 + `yyyy-MM-dd` 직접 직렬화.
- 모든 동기화 run을 `admin_sync_runs` 컬렉션에 기록(실행자·시각·건수·오류) — 공개 read 제외. LockService로 중복/동시 실행 방지.
- firestore.rules: `academic_events`, `cafeterias`, `dining_menus` 공개 read + 클라이언트 write 전면 deny. `admin_sync_runs`는 read/write 모두 deny. rules emulator 테스트 추가.
- 개발 seed(`tool/firestore_seed`)는 신규 운영 컬렉션을 `--prune` 대상에 넣지 않음(초기 시드 소유권과 운영 동기화 소유권 분리).

### 구현 분담
- **Claude**: 앱 코드(status enum, Firestore 리포지토리 2종, FirestorePaths, 플래그·firebase_init, l10n, 테스트), firestore.rules, seed ADC 전환·초기 시드.
- **Codex**: `tool/admin_sheets/` — Apps Script 소스, 시트 템플릿 생성 스크립트, 비개발자용 안내 문서.
- **사용자 액션 필요**: 기존 서비스 계정 키 폐기(GCP 콘솔), Apps Script GCP 프로젝트 연결, 관리자 그룹 IAM 부여.
