# 관리자 데이터 입력 파이프라인 설계 리뷰

검토 대상: `_workspace/06_admin_data_pipeline.md`  
검토 범위: 설계 검토 전용. 원 설계 문서는 수정하지 않았다.  
판정 요약: D1 조건부 / D2 반대 / D3 조건부 / D4 조건부 / D5 조건부

## 먼저 고쳐야 할 사항

1. **긴급 보안 조치:** `tool/firestore_seed/serviceAccount.json`이 현재 로컬에 실제 존재한다. Git에는 추적되지 않고 `.gitignore`에도 등록돼 있지만, 키 파일은 복사·백업·터미널 출력 등으로 유출될 수 있으므로 해당 서비스 계정 키를 Google Cloud IAM에서 즉시 폐기/회전하고 로컬 파일을 제거해야 한다. 이후 seed도 Application Default Credentials 또는 단기 impersonation으로 바꾸는 편이 낫다. “새 파이프라인에는 키를 심지 않는다”만으로 기존 키 위험이 해소되지 않는다.
2. **학사일정 full-replace는 현재 UX와 결합하면 데이터 손실을 만든다.** 설계는 오류 행을 제외하고 정상 행만 업로드한다고 하면서 컬렉션 전체를 시트 기준으로 prune한다. 예를 들어 기존 일정 한 행의 날짜를 잘못 입력하면 그 행은 업로드 집합에서 빠지고, prune이 기존 Firestore 문서를 삭제한다.
3. **문서의 “엔티티 필드명 일치 → 앱 코드 수정 불필요”는 정확하지 않다.** `AcademicEvent.fromJson`은 필수 `id`를 요구하지만 Firestore 본문에는 `id`가 없고 문서 ID에만 있다. 기존 `firestore_paths.dart`처럼 문서 ID를 JSON에 주입하는 adapter 함수가 반드시 필요하다. 또한 컬렉션 경로 상수와 매퍼도 추가해야 한다.

## D1 — 학식 미등록과 휴무 구분

**입장: 조건부** — 반드시 구분하되, 단일 `isClosed` 불리언보다 명시적인 상태 enum을 권장한다.

현재 `CafeteriaMenu.isClosed`는 `meals.isEmpty`이고, `DiningRepository` 계약에도 “휴무 식당은 빈 meals로 반환”한다고 적혀 있다. 화면은 `isClosed`일 때 `dining_closed`(“오늘은 운영하지 않아요” / “Closed today”)를 표시한다. 따라서 문서 누락을 빈 배열로 조인하면 관리자의 입력 누락을 사실상 “휴무”라고 잘못 공지한다. 국제학생에게 운영 여부는 행동을 바꾸는 정보라서 미등록과 휴무를 합치면 안 된다.

권장 모델은 `status: open | closed | unpublished`(필요하면 `holidayClosed`, `soldOut` 추가)이다. 식당×날짜 문서가 없으면 `unpublished`, 문서가 있고 `status == closed`면 명시적 휴무, `open`이면 meals를 요구한다. 앱 엔티티도 `DiningAvailability` 같은 enum을 추가하고 `isClosed`는 파생 getter로 남기면 기존 화면 변경 범위를 줄일 수 있다. 최소안으로 `isClosed`를 추가할 수 있지만 문서 부재를 표현할 세 번째 상태가 여전히 필요하므로 nullable bool은 피하는 것이 좋다.

시트에도 식사별 행만 둘 것이 아니라 식당×날짜에 대해 “운영 상태”를 입력할 방법이 있어야 한다. 휴무는 별도 상태 행 또는 날짜별 식당 상태 열로 명시하고, `open`인데 meals가 0개인 문서는 검증 오류로 막아야 한다.

## D2 — 시트 삭제 반영 정책

**입장: 반대** — 학사일정 무조건 full-replace/prune과 학식 무기한 upsert-only 모두 운영상 안전하지 않다.

### 학사일정

full-replace 자체는 작은 기준 데이터셋에는 가능하지만 다음 조건 없이는 반대한다.

- 모든 행 검증이 성공한 경우에만 publish/prune한다. “오류 행 제외 후 정상 행 업로드” 모드에서는 절대 prune하지 않는다.
- 즉시 live 컬렉션을 건드리지 말고 staging/run 단위로 전체 스냅샷을 만든 뒤 검증 완료 후 활성 버전을 전환한다. 간단한 대안은 `academic_event_versions/{version}/events` + `metadata/activeVersion`이다.
- 삭제 예정 건수와 목록을 관리자에게 미리 보여주고 확인을 받으며, 직전 버전으로 rollback할 수 있어야 한다.
- 슬러그를 일정명에서 재생성하면 제목 수정이 delete+create가 되고 동일 연도·동일 제목 일정도 충돌한다. 시트에 변경되지 않는 숨김 `event_id`(UUID 또는 최초 생성 ID)를 저장해야 한다.

### 학식

upsert-only는 과거 보존에는 유리하지만 잘못 올린 미래 메뉴, 취소된 운영, 삭제된 식사 슬롯이 영원히 남는다. 삭제 대신 `status`, `deletedAt`/`archivedAt` 또는 관리자가 선택하는 “게시 취소” tombstone을 지원해야 한다. 보존 기간이 지난 메뉴는 TTL 또는 별도 정리 작업으로 삭제할 수 있다.

또한 한 행이 한 끼인데 Firestore 문서는 한 식당×날짜이므로, 동기화 시 같은 문서의 모든 끼니 행을 먼저 그룹화한 뒤 한 번에 써야 한다. 한 오류 행만 제외한 채 문서 전체를 덮어쓰면 기존의 다른 끼니를 우발적으로 지울 수 있다. 문서 단위가 완전하지 않으면 그 문서 전체를 실패시키는 것이 안전하다.

## D3 — Firestore 스키마와 조회/캐시

**입장: 조건부** — `cafeterias` 분리와 식당×날짜 문서 단위에는 동의하지만, 상태·버전·조회 범위를 보강해야 한다.

좋은 점은 다음과 같다.

- 기존 mock의 식당 ID, 이름, 캠퍼스, 운영시간, facility 연결을 그대로 정적 문서로 옮길 수 있다.
- 한 화면에서 한 날짜의 전체 식당을 보여 주므로 `dining_menus where date == YYYY-MM-DD`는 앱 접근 패턴과 맞는다. `date` 단일 equality 쿼리는 별도 composite index가 필요하지 않다.
- 식당 수와 메뉴 수가 작아서 클라이언트 조인의 비용은 MVP에서 충분히 감당할 수 있다.

보강점은 다음과 같다.

- `FirestorePaths`에 세 컬렉션 상수와 `academicEventFromDoc`/식당·메뉴 매퍼가 필요하다. 기존 패턴은 문서 ID 주입 및 `Timestamp` 정규화를 entity 밖에서 수행한다.
- `AcademicCalendarRepository.getEvents()` 계약은 시작일 정렬을 기대한다. Firestore 쿼리에 `orderBy('start')`를 쓰거나 파싱 후 명시적으로 정렬해야 한다.
- `cafeterias`를 매 날짜마다 다시 읽는 구현은 불필요하다. Riverpod에서 정적 목록을 별도 provider로 캐시하거나 리포지토리 내부에서 재사용하되, 변경 반영 정책도 정해야 한다.
- Firestore 오프라인 캐시는 “모든 날짜가 오프라인에서 된다”는 뜻이 아니다. 한 번도 읽지 않은 날짜는 캐시에 없다. 기존 리포지토리처럼 서버 실패 시 `Source.cache`를 시도하되, 빈 캐시와 실제 빈 결과를 구분하고 `unpublished` UI를 보여야 한다.
- 날짜 문자열은 현재 `DateTime.parse`/`YYYY-MM-DD`와 호환되지만 Apps Script의 스프레드시트 timezone에 따라 하루가 밀릴 수 있다. 시트 timezone을 `Asia/Seoul`로 고정하고 표시값을 직접 `yyyy-MM-dd`로 직렬화해야 한다.
- `mealTypes`는 정적 “가능 슬롯”이고 일별 `meals.type`은 실제 게시 슬롯이다. 중복 타입, 허용되지 않은 타입, 음수 가격, 빈 메뉴 문자열을 서버 측 동기화 검증에서 차단해야 한다.
- Firestore 한 문서 크기 제한에는 당장 닿지 않지만, 배열 전체 갱신이라 끼니별 동시 편집 충돌 가능성이 있다. 동기화는 문서 단위 단일 writer 및 optimistic precondition(직전 `updateTime`) 또는 run lock을 사용해야 한다.

비용을 더 줄이는 대안으로 식당 정적 정보를 일별 문서에 일부 중복할 수도 있지만, 식당 수가 적고 변경이 드문 현재에는 분리안이 더 일관적이다. 단, 실제 조회를 `date` 쿼리 한 번으로 끝내고 싶은 요구가 생기면 display name/campus만 snapshot으로 denormalize하는 절충안을 고려할 수 있다.

## D4 — Apps Script 인증

**입장: 조건부** — 서비스 계정 키 내장에는 명확히 반대하며, 초기 MVP에서 사용자 OAuth/IAM은 가능하지만 최소권한·운영성 검증 후에만 채택한다. 장기적으로는 검증 프록시가 낫다.

`ScriptApp.getOAuthToken()` + Firestore REST는 키리스라는 장점이 있다. 하지만 `Cloud Datastore User`는 이 세 컬렉션만으로 제한되는 Firestore Security Rules 권한이 아니라 프로젝트 데이터 접근 IAM 권한이다. 즉, 잘못된 Apps Script나 토큰 오용 시 다른 컬렉션에도 영향을 줄 수 있다. 시트 편집자마다 메뉴를 실행한다면 각 실행자에게 IAM 역할과 OAuth 동의가 필요하고, 관리자가 바뀔 때 온보딩/회수가 필요하다.

MVP에서 이 안을 쓴다면 다음을 조건으로 둔다.

- 전용 Google 그룹/관리자 계정에만 IAM을 주고 일반 시트 편집자와 분리한다.
- 별도 최소권한 custom IAM role이 실제 Firestore REST 쓰기에 충분한지 검증하고, 불가능하면 프로젝트를 콘텐츠 전용으로 분리하는 방안을 검토한다.
- Apps Script manifest의 scope를 고정하고, 실행 주체·대상 Firebase project/database를 화면에 표시하며, audit log와 동기화 run log를 남긴다.
- 문서 ID와 컬렉션 이름은 시트 값으로 직접 받지 않고 allowlist mapping으로만 생성한다.

운영자가 여러 명이거나 권한 관리가 중요하면 Cloud Run/Functions 프록시에 전용 서비스 계정을 붙이고 Google ID 토큰으로 허용된 관리자만 호출하게 하는 편이 낫다. 프록시는 스키마 검증, atomic publish, idempotency, 감사 로그, rate limit을 한곳에서 수행할 수 있다. 다만 인증 없는 공개 HTTP 함수나 시트에 저장한 shared secret은 서비스 계정 키와 마찬가지로 피해야 한다.

## D5 — 기타 위험과 대안

**입장: 조건부** — 전체 방향은 현실적인 MVP지만, 아래 항목을 설계 완료 조건으로 추가해야 한다.

### 데이터 무결성

- `AcademicEvent.fromJson`은 `id`와 `start` 타입/존재를 강제하며 잘못된 데이터 하나가 전체 목록 파싱을 실패시킬 수 있다. 업로드 전 Apps Script 검증만 믿지 말고 repository에서 문서별 오류를 식별 가능한 예외로 남기거나 잘못된 문서를 격리해야 한다.
- enum 파서는 모르는 category를 `semester`, 모르는 meal type을 `lunch`, 모르는 campus를 `seunghak`로 조용히 바꾼다. 관리자 데이터 오타가 정상 데이터처럼 보이는 위험이 있으므로 Apps Script에서 enum allowlist를 엄격 적용하고 테스트해야 한다.
- `end < start`, 중복 event ID, 같은 식당×날짜×끼니 중복, 빈 번역, 과도한 메뉴 길이, 가격 범위 검증이 필요하다.

### 동기화 안전성

- 모든 실행에 `runId`, 실행자, 시작/종료 시각, 입력 row count, 성공/실패/삭제 count, 오류 요약을 별도 audit 컬렉션 또는 로그에 남긴다.
- 중복 클릭과 동시에 열린 두 관리자의 실행을 막는 lock/idempotency가 필요하다.
- Firestore REST batch/transaction 한도와 Apps Script 실행 시간 제한을 고려해 chunking하되, live 데이터가 부분 상태로 보이지 않도록 versioned publish를 사용한다.
- 정상 행만 부분 업로드하는 UX는 “게시”와 “초안 검증”을 분리하는 편이 낫다. 먼저 전체 검증/미리보기, 이후 전체 성공 시 한 번에 게시한다.

### 공개 읽기와 개인정보

`firestore.rules`는 현재 세 기존 컬렉션만 공개 read이고 default deny다. 새 세 컬렉션을 명시적으로 공개해야 앱이 읽을 수 있다. 공개 데이터에 편집자 이메일, 내부 메모, 오류 메시지 또는 audit 정보를 섞지 말고 audit 컬렉션은 공개 규칙에서 제외해야 한다.

### 테스트 및 배포

- 단순 fromJson roundtrip 외에 Firestore 문서 ID 주입, Timestamp 무시/변환, 정렬, cache fallback, 문서 부재=`unpublished`, 명시 휴무, 일부 malformed 문서, 날짜 timezone을 테스트해야 한다.
- Rules emulator로 공개 read/클라이언트 write deny/default deny를 검증해야 한다.
- 현재 `tool/firestore_seed`는 고정 `COLLECTIONS` 맵과 각 컬렉션 전체 prune 구조다. `academic_events`/`cafeterias` 추가는 가능하지만 운영자가 관리하는 live 컬렉션을 개발 seed의 `--prune` 대상으로 넣으면 안 된다. 초기 seed와 운영 sync의 소유권을 분리해야 한다.
- `repository_providers.dart`의 현재 단일 `useFirestore` 플래그는 모든 repository를 함께 Firestore로 바꾼다. 새 구현을 붙이면 학사/학식 데이터 준비가 덜 된 환경에서 화면까지 전환된다. 컬렉션 준비 확인 또는 기능별 플래그/remote config가 안전하다.

## 권장 최종안

1. `cafeterias`는 정적 컬렉션으로 유지하고, `dining_menus`는 식당×날짜 문서를 유지한다.
2. 메뉴 문서에 `status`를 두고 문서 없음=`unpublished`, `closed`, `open`을 구분한다.
3. Sheets는 초안 입력 UI로만 사용하고, 전체 검증 → 변경 diff/삭제 확인 → versioned publish 순서로 동기화한다.
4. 학사일정은 불변 `event_id`를 사용하고 버전 스냅샷으로 publish/rollback한다. 학식 삭제는 tombstone 또는 명시적 게시 취소로 처리한다.
5. 초기에는 제한된 관리자 그룹의 OAuth/IAM을 쓸 수 있으나, 권한 범위가 과하면 전용 검증 프록시로 이동한다. 서비스 계정 JSON 키는 사용하지 않는다.
6. 개발 seed와 운영 콘텐츠 동기화를 분리하고, 앱 Firestore adapter·정렬·cache/미등록 상태 테스트를 추가한다.
