# Campus-On 관리자 Sheets 동기화 도구

Google Sheets를 비개발자용 입력 화면으로 사용하고, 바운드 Apps Script가 Firestore REST API에 학사일정과 학식 데이터를 게시한다. Firebase 프로젝트는 `android/app/google-services.json`의 `project_id`와 동일한 `campus-f4748`로 `Config.gs`에 고정되어 있다.

## 파일 구성

- `appsscript.json`: Asia/Seoul timezone과 고정 OAuth scopes
- `Config.gs`: 프로젝트·컬렉션 상수 및 한국어→앱 enum allowlist
- `Setup.gs`: 메뉴와 시트 템플릿 생성
- `Validation.gs`: 엄격한 행/그룹 검증
- `Firestore.gs`: OAuth 기반 Firestore REST client 및 atomic commit
- `Sync.gs`: 학사일정/학식 동기화와 LockService
- `Audit.gs`: 비공개 `admin_sync_runs` 감사로그
- `ADMIN_GUIDE.md`: 비개발자 관리자용 안내

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
clasp push
clasp open
```

`clasp create`가 새 스프레드시트를 만들었다면 그 스프레드시트를 사용한다. 기존 스프레드시트에 바인딩하려면 해당 컨테이너 바운드 스크립트의 script ID로 `.clasp.json`을 구성한다. `.clasp.json`은 배포 환경별 식별자이므로 저장소에 커밋하지 않는다.

## 수동 설치

1. 새 Google Sheets 문서를 만든다.
2. 확장 프로그램 → Apps Script를 연다.
3. 이 디렉터리의 각 `.gs` 파일과 같은 이름의 스크립트 파일을 만들고 내용을 붙여 넣는다.
4. 프로젝트 설정에서 “appsscript.json 매니페스트 파일을 편집기에 표시”를 켠다.
5. 기존 manifest를 이 디렉터리의 `appsscript.json` 내용으로 교체한다.
6. 위 사전 준비에 따라 표준 GCP 프로젝트를 연결하고 저장한다.
7. Apps Script 편집기에서 `setupAdminSheets`를 한 번 실행하고 권한 요청을 승인한다.
8. 스프레드시트를 새로고침하고 `동아메이트` 커스텀 메뉴가 보이는지 확인한다.

## 최초 검증

1. Firebase Emulator 또는 별도 개발 프로젝트에서 먼저 실행한다. 개발 프로젝트를 쓰면 `Config.gs`의 `projectId`를 그 프로젝트 ID로 명시적으로 바꾼다.
2. 학사일정 1건을 입력해 문서 ID가 숨김 `event_id`와 같고, 본문 필드가 `title_ko`, `title_en`, `category`, `start`, `end`, `updatedAt`인지 확인한다.
3. 학식 게시/휴무/게시취소를 각각 실행해 `status`가 `open`/`closed`/`unpublished`로 저장되는지 확인한다.
4. `admin_sync_runs`에 실행자·시각·건수·오류가 기록되는지 확인한다.
5. 배포된 `firestore.rules`가 공개 콘텐츠 read만 허용하고 클라이언트 write 및 `admin_sync_runs` read/write를 거부하는지 emulator 테스트로 확인한다.

## 동기화 의미

학사일정은 시트 전체가 단일 source of truth다. 모든 행이 유효할 때만 기존 ID를 조회하며, 새 전체 문서와 시트에 없는 기존 문서의 delete를 하나의 `documents:commit` 요청으로 보낸다. 게시+삭제 합계가 500건을 넘으면 중단된다.

학식은 시트에 존재하는 식당×날짜 그룹만 갱신한다. 같은 그룹의 여러 끼니는 하나의 `meals` 배열로 합쳐져 문서 한 건으로 덮어써지고, 그룹에 오류가 있으면 해당 그룹은 쓰지 않는다. 시트에서 행을 없애도 과거 문서는 삭제되지 않으며, 게시를 취소하려면 `게시취소` 행을 남겨 `status: unpublished` tombstone을 써야 한다.

## 운영 및 장애 대응

- 동기화 중에는 Document Lock을 사용한다. “다른 관리자가 동기화 중” 메시지가 나오면 잠시 후 다시 실행한다.
- 학사일정을 잘못 게시했다면 Google Sheets 버전 기록에서 이전 상태로 복원한 뒤 다시 동기화한다. 복원 후 숨김 `event_id` 열도 이전 값으로 돌아왔는지 확인한다.
- Firestore 오류가 발생하면 IAM, 표준 GCP 프로젝트 연결, Firestore API 활성화, `Config.gs`의 프로젝트 ID를 차례로 확인한다.
- 감사로그 기록 실패 toast가 뜨면 콘텐츠 반영 여부와 Cloud Logging을 확인하고 개발자에게 알린다.
- `admin_sync_runs`는 공개 데이터가 아니므로 Sheets 데이터 컬렉션과 같은 공개 rules를 적용하지 않는다.

## 보안 주의

이 도구는 컬렉션명과 문서 ID를 코드의 allowlist 및 불변 UUID/식당 ID 조합으로만 만든다. `.gs` 코드를 바꿀 수 있는 사람은 사실상 게시 로직을 바꿀 수 있으므로 Apps Script 편집 권한도 전용 관리자/개발자로 제한한다. 저장소의 기존 `tool/firestore_seed/serviceAccount.json` 키는 별도 합의대로 GCP에서 폐기·회전하고 로컬에서 삭제해야 하며, 이 도구에서는 사용하지 않는다.
