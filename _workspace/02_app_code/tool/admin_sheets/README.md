# Campus-On 관리자 Sheets 동기화 도구

Google Sheets를 비개발자용 입력 화면으로 사용하고, 바운드 Apps Script가 Firestore REST API에 학사일정·식당·학식 데이터를 게시한다. Firebase 프로젝트는 `android/app/google-services.json`의 `project_id`와 동일한 `campus-f4748`로 `Config.gs`에 고정되어 있다.

## 파일 구성

- `appsscript.json`: Asia/Seoul timezone과 고정 OAuth scopes
- `Config.gs`: 프로젝트·컬렉션 상수, 한국어→앱 enum allowlist, 시트 열 정의, 기본 식당 8곳, 예시 식단
- `Setup.gs`: 메뉴, 시트 템플릿 생성·정비, 옛 학식 양식 마이그레이션, 예시 탭
- `Validation.gs`: 행/그룹 검증 (학사일정·식당·학식), 메뉴 항목·운영시간 파서
- `Firestore.gs`: OAuth 기반 Firestore REST client 및 atomic commit
- `Sync.gs`: 학사일정·식당(full replace)과 학식(upsert) 동기화, LockService
- `Audit.gs`: 비공개 `admin_sync_runs` 감사로그
- `sync_safety.test.mjs`, `dining_format.test.mjs`: Node 로컬 테스트 (`clasp push` 대상 아님)
- `.claspignore`: `.gs`와 `appsscript.json`만 푸시
- `ADMIN_GUIDE.md`: 비개발자 관리자용 안내

## 시트(탭) 구성

| 탭 | 역할 | 동기화 | Firestore |
|---|---|---|---|
| `학사일정` | 학사일정 전체 | 학사일정 동기화 (full replace) | `academic_events/<event_id>` |
| `식당` | 식당 목록·운영시간 | 식당 동기화 (full replace) | `cafeterias/<식당ID>` |
| `학식` | 날짜별 식단 | 학식 동기화 (그룹 upsert) | `dining_menus/<식당ID>_<YYYY-MM-DD>` |
| `예시` | 학식 입력 예시 2일치 | 없음 | — |
| `안내` | 요약 안내 | 없음 | — |

### `식당` 탭 열

| 열 | 헤더 | 규칙 | Firestore 필드 |
|---|---|---|---|
| A | 식당ID | 필수, `^[a-z0-9-]+$`, 중복 금지 | 문서 ID |
| B | 이름(국문) | 필수, 중복 금지 (학식 탭 드롭다운이 이 열을 참조) | `name_ko` |
| C | 이름(영문) | 필수 | `name_en` |
| D | 캠퍼스 | 드롭다운 승학/구덕/부민 | `campus: seunghak\|gudeok\|bumin` |
| E | 운영시간 | `HH:mm-HH:mm`을 쉼표로 나열, 시작<종료, 구간 겹침 금지, 비우면 `[]` | `hours: [{open, close}]` (시작 시각순 정렬) |
| F | 운영 비고(국문) | 선택 | `hours_ko` (비우면 null) |
| G | 운영 비고(영문) | 선택 | `hours_en` (비우면 null) |
| H | 지도 건물ID | 선택, `^[a-z0-9-]+$` | `facilityId` (비우면 null) |
| I | 표시 순서 | 정수 0~9999 | `order` |
| J | 동기화 결과 | 스크립트가 기록 | — |

문서 예시 (`cafeterias/seunghak-student`):

```json
{
  "name_ko": "학생회관 식당",
  "name_en": "Student Union Cafeteria",
  "campus": "seunghak",
  "hours": [
    { "open": "09:00", "close": "09:30" },
    { "open": "10:00", "close": "14:30" },
    { "open": "15:00", "close": "16:30" }
  ],
  "hours_ko": "천원의아침밥 09:00부터 선착순",
  "hours_en": "₩1,000 breakfast from 09:00, first come",
  "facilityId": "s02",
  "order": 2,
  "updatedAt": "<timestamp>"
}
```

### `학식` 탭 열

한 행 = 한 식당·한 날짜의 섹션 하나(시간대 × 유형). 같은 식당·날짜의 행들이 문서 한 건으로 합쳐진다.

| 열 | 헤더 | 규칙 | Firestore 필드 |
|---|---|---|---|
| A | 날짜 | 날짜 셀 | 문서 ID의 `YYYY-MM-DD`, `date` |
| B | 식당 | 드롭다운 = `식당` 탭 B열 | 문서 ID의 식당ID, `cafeteriaId` |
| C | 시간대 | 아침/점심/저녁/종일 | `sections[].slot: breakfast\|lunch\|dinner\|allDay` |
| D | 유형 | 정식/일품/양분식/천원의아침밥 | `sections[].kind: set\|alacarte\|snack\|thousandWon` |
| E | 메뉴 | 줄바꿈 또는 쉼표로 항목 구분. 항목 끝 숫자(`7,500원`, `6000`)는 항목 가격 | `sections[].items: [{name, price?}]` |
| F | 가격 | 섹션 가격. 정식·천원의아침밥은 필수, 일품·양분식은 비움 | `sections[].price` |
| G | 비고 | 선택 | `sections[].note` |
| H | 상태 | 게시/휴무/게시취소 | `status: open\|closed\|unpublished` |
| I | 동기화 결과 | 스크립트가 기록 | — |

검증 규칙:

| 규칙 | 오류 위치 |
|---|---|
| 날짜·식당·상태는 필수, 식당은 `식당` 탭의 유효한 행 이름이어야 함 | 해당 행 (그룹 불가) |
| 게시 행: 시간대·유형·메뉴 필수 | 해당 행 |
| 정식·천원의아침밥: 가격 열 필수, 항목 가격 금지 | 해당 행 |
| 일품·양분식: 가격 열 비움, 항목 가격은 선택 | 해당 행 |
| 가격·항목 가격은 0~100000 정수 (쉼표·`원` 허용) | 해당 행 |
| 같은 식당·날짜 안에서 (시간대, 유형) 조합 중복 금지 — 같은 시간대의 정식+일품은 허용 | 뒤에 오는 행 |
| 같은 식당·날짜의 상태는 모두 같아야 함 | 그룹 전체 |
| 게시 그룹은 섹션 1개 이상 | 그룹 전체 |
| 휴무/게시취소 행은 시간대·유형·메뉴·가격·비고 비움, 그룹당 1행 | 해당 행 / 두 번째 행부터 |

문서 예시 (`dining_menus/seunghak-student_2026-10-13`):

```json
{
  "cafeteriaId": "seunghak-student",
  "date": "2026-10-13",
  "status": "open",
  "sections": [
    { "slot": "breakfast", "kind": "thousandWon", "price": 1000, "note": "09:00부터 선착순",
      "items": [{ "name": "훈제오리솥밥" }] },
    { "slot": "allDay", "kind": "set", "price": 6000,
      "items": [{ "name": "돈육김치찌개" }, { "name": "계란말이" }, { "name": "밥" }, { "name": "깍두기" }] },
    { "slot": "allDay", "kind": "alacarte",
      "items": [{ "name": "국밥", "price": 6000 }, { "name": "돈까스", "price": 7500 }, { "name": "연어포케", "price": 9000 }] },
    { "slot": "allDay", "kind": "snack",
      "items": [{ "name": "김밥", "price": 3500 }, { "name": "핫도그", "price": 2500 }] }
  ],
  "updatedAt": "<timestamp>"
}
```

휴무·게시취소 문서는 `sections: []`에 `status`만 다르다. `meals` 필드는 더 이상 쓰지 않는다 (앱은 옛 `meals` 문서도 읽을 수 있지만 새로 쓰지 않는다).

## 사전 준비

1. Google Cloud Console에서 Firebase 프로젝트 `campus-f4748`를 연다.
2. Firestore API가 활성화되어 있는지 확인한다.
3. 동기화를 실행할 전용 관리자 Google 그룹 또는 계정에 필요한 IAM을 부여한다. 우선 `Cloud Datastore User`로 동작을 검증하되, 운영 전 Firestore 문서 읽기/쓰기/삭제/commit에 필요한 권한만 가진 custom role을 검토한다.
4. 일반 시트 편집자에게 IAM을 주지 않는다. 동기화 실행자는 전용 관리자여야 한다.
5. 서비스 계정 JSON 키를 Apps Script, Sheet, Script Properties에 저장하지 않는다. 인증은 실행 사용자의 `ScriptApp.getOAuthToken()`만 사용한다.

Apps Script 프로젝트는 반드시 Firebase와 같은 **표준 Google Cloud 프로젝트**에 연결해야 한다. Apps Script 편집기에서 프로젝트 설정 → Google Cloud Platform(GCP) 프로젝트 변경을 선택하고 `campus-f4748`의 프로젝트 번호를 지정한다.

## clasp로 설치

Apps Script API를 활성화하고 Node.js 및 `clasp`를 설치한 뒤 실행한다.

```text
npm install -g @google/clasp
clasp login
clasp create --type sheets --title "Campus-On 관리자 데이터"
```

생성된 `.clasp.json`의 `rootDir`을 이 디렉터리로 지정하거나, 이 디렉터리를 clasp 프로젝트 루트로 사용한다. 이후 다음을 실행한다.

```text
clasp status   # .claspignore 덕분에 *.gs 와 appsscript.json 만 보여야 한다
clasp push
clasp open
```

`.claspignore`가 `*.test.mjs`, `test/**`, `*.md`를 제외하므로 테스트·문서는 올라가지 않는다. `clasp create`가 새 스프레드시트를 만들었다면 그 스프레드시트를 사용한다. 기존 스프레드시트에 바인딩하려면 해당 컨테이너 바운드 스크립트의 script ID로 `.clasp.json`을 구성한다. `.clasp.json`은 배포 환경별 식별자이므로 저장소에 커밋하지 않는다.

## 수동 설치

1. 새 Google Sheets 문서를 만든다.
2. 확장 프로그램 → Apps Script를 연다.
3. 이 디렉터리의 각 `.gs` 파일과 같은 이름의 스크립트 파일을 만들고 내용을 붙여 넣는다.
4. 프로젝트 설정에서 “appsscript.json 매니페스트 파일을 편집기에 표시”를 켠다.
5. 기존 manifest를 이 디렉터리의 `appsscript.json` 내용으로 교체한다.
6. 위 사전 준비에 따라 표준 GCP 프로젝트를 연결하고 저장한다.
7. Apps Script 편집기에서 `setupAdminSheets`를 한 번 실행하고 권한 요청을 승인한다.
8. 스프레드시트를 새로고침하고 `동아메이트` 커스텀 메뉴가 보이는지 확인한다.

## 로컬 테스트

```text
node --test tool/admin_sheets/*.test.mjs
```

`.gs` 파일을 Node `vm` 컨텍스트에 로드해 순수 함수(메뉴 파싱, 가격 규칙, 그룹 검증, 운영시간, full-replace 삭제 목록, 마이그레이션)를 검증한다. Apps Script 전용 API(`SpreadsheetApp`, `UrlFetchApp`)는 호출하지 않는다.

## 기존 시트 업그레이드 (옛 학식 양식 → 새 양식)

`동아메이트 → 시트 초기화`를 실행하면:

1. `식당` 탭이 없으면 만들고 기본 식당 8곳을 채운다. 이미 데이터가 있으면 건드리지 않는다.
2. `학식` 탭 헤더가 옛 7열(`날짜 | 식당 | 식사 | 메뉴 (쉼표로 구분) | 가격 | 상태 | 동기화 결과`)이면 제자리에서 옮긴다: `유형` 열(D)과 `비고` 열(G)을 삽입하고, `식사` 값을 `시간대`로(조식→아침, 중식→점심, 석식→저녁), `유형`은 식사가 있던 행에 `정식`으로, 식당 이름은 `승학 학생식당→학생회관 식당`, `구덕 학생식당→구덕 제2캠퍼스 학생회관`으로 바꾼다. `부민 학생식당`은 대응 식당이 하나가 아니라 그대로 두고 알림에 건수를 보고하므로 관리자가 직접 고른다. 메뉴·가격은 그대로, 옛 동기화 결과는 지운다.
3. 헤더 보호, 드롭다운(식당 열은 `식당` 탭 B열 참조), 열 너비, 메뉴 열 줄바꿈을 다시 적용한다.
4. `예시` 탭을 새로 만들거나 덮어쓴다 (동기화 대상 아님).

마이그레이션은 한 번만 일어난다(헤더가 새 양식이면 건너뜀). 옛 행 중 정식인데 가격이 비어 있던 행은 새 규칙에서 오류가 되므로 동기화 전에 가격을 채워야 한다.

## 동기화 의미

- **학사일정·식당**: 시트 전체가 단일 source of truth다. 모든 행이 유효할 때만 기존 문서 ID를 조회하며, 새 전체 문서와 시트에 없는 기존 문서의 delete를 하나의 `documents:commit` 요청으로 보낸다. 삭제 예정 목록(식당은 `이름 [식당ID]`)을 확인창에서 보여주고, 확인 중 시트·서버가 바뀌면 중단한다. 게시+삭제 합계가 500건을 넘으면 중단된다. **식당ID를 바꾸면 옛 ID 문서는 삭제되고 새 ID 문서가 생긴다**; 옛 ID로 게시된 `dining_menus` 문서는 남지만 앱에서는 식당 목록에 없으므로 보이지 않는다.
- **학식**: 시트에 존재하는 식당×날짜 그룹만 갱신한다. 같은 그룹의 여러 섹션 행은 하나의 `sections` 배열로 합쳐져 문서 한 건으로 덮어써지고, 그룹에 오류가 있으면 해당 그룹은 쓰지 않는다. 정상 그룹이 500건을 넘으면 500건 단위로 나눠 커밋한다(그룹 단위 원자성은 유지). 시트에서 행을 없애도 과거 문서는 삭제되지 않으며, 게시를 내리려면 `게시취소` 행을 남겨 `status: unpublished` tombstone을 써야 한다.
- 학식 동기화는 `식당` 탭을 읽어 이름→ID를 만든다. `식당` 탭에서 오류가 있거나 이름이 중복된 행의 식당은 학식 탭에서 고를 수 없다. 식당을 새로 추가했다면 먼저 `식당 동기화`를 실행해야 앱에 그 식당이 보인다.

## 운영 및 장애 대응

- 동기화 중에는 Document Lock을 사용한다. “다른 관리자가 동기화 중” 메시지가 나오면 잠시 후 다시 실행한다.
- 삭제 확인창을 닫은 뒤 잠금을 다시 얻고 시트·서버 문서 버전을 재검사한다. 확인 중 변경되었다면 쓰기 없이 중단하므로 다시 실행해 삭제 대상을 확인한다. 기존 문서 갱신·삭제에는 `updateTime`, 새 문서에는 `exists: false` 조건을 붙여 검사 이후의 충돌도 커밋에서 거부한다.
- 학사일정·식당을 잘못 게시했다면 Google Sheets 버전 기록에서 이전 상태로 복원한 뒤 다시 동기화한다. 복원 후 숨김 `event_id` 열도 이전 값으로 돌아왔는지 확인한다.
- Firestore 오류가 발생하면 IAM, 표준 GCP 프로젝트 연결, Firestore API 활성화, `Config.gs`의 프로젝트 ID를 차례로 확인한다.
- 감사로그 기록 실패 toast가 뜨면 콘텐츠 반영 여부와 Cloud Logging을 확인하고 개발자에게 알린다.
- `admin_sync_runs`는 공개 데이터가 아니므로 Sheets 데이터 컬렉션과 같은 공개 rules를 적용하지 않는다.

## 배포 시 주의 (기존 시트·데이터 영향)

1. 새 코드를 `clasp push`한 뒤 **반드시 `시트 초기화`를 한 번 실행**해야 한다. 초기화 전에는 `학식` 탭이 옛 열 구조라 학식 동기화가 열을 잘못 읽는다(`식사` 열을 `시간대`로 읽는 등).
2. `식당` 탭이 새로 생기면 기본 8곳이 채워진다. 기존 `cafeterias` 컬렉션에는 `seunghak-student`, `gudeok-student`, `bumin-student` 3개 문서가 있으므로 첫 `식당 동기화`는 `bumin-student`를 삭제 목록으로 보여주고 나머지 2개는 덮어쓴다(이름·운영시간이 새 값으로 바뀜). 앱이 옛 `mealTypes` 필드를 쓰지 않는지 확인한 뒤 진행한다.
3. 옛 `dining_menus` 문서(`meals` 필드)는 그대로 남는다. 앱은 두 형태를 모두 읽지만, 새 양식으로 다시 동기화하면 그 날짜 문서는 `sections`로 교체된다. `bumin-student_*` 문서는 식당 삭제 후 앱에 노출되지 않는다.
4. 마이그레이션은 제자리 편집이므로 실행 전 Google Sheets 버전 기록(파일 → 버전 기록 → 현재 버전 이름 지정)으로 복원 지점을 만든다.

## 보안 주의

이 도구는 컬렉션명과 문서 ID를 코드의 allowlist, 불변 UUID, `식당` 탭에서 검증된 `^[a-z0-9-]+$` 식당 ID 조합으로만 만든다. 식당 ID는 시트 값이지만 정규식·중복 검증을 통과한 값만 쓰이며, 학식 탭은 이름으로만 식당을 가리킨다. `.gs` 코드를 바꿀 수 있는 사람은 사실상 게시 로직을 바꿀 수 있으므로 Apps Script 편집 권한도 전용 관리자/개발자로 제한한다. 저장소의 기존 `tool/firestore_seed/serviceAccount.json` 키는 별도 합의대로 GCP에서 폐기·회전하고 로컬에서 삭제해야 하며, 이 도구에서는 사용하지 않는다.
