<!-- 생성: 2026-09-10, Codex CLI 0.149.0 (읽기 전용 샌드박스) 전체 리포 감사. 짝 문서: 07_analysis_claude.md -->
# Codex 분석 결과

## 1. plan.md 정합성

### 일치 요약

리포지토리의 현재 추적 파일과 코드를 대조한 결과 다음 주장은 확인됐다.

- **§1~§5 기본 아키텍처**: Flutter, Riverpod, go_router, Firebase/Firestore, Kakao Map, ARB 기반 한·영 구조가 실제 의존성과 코드에 반영돼 있다. 근거: `_workspace/02_app_code/pubspec.yaml:10-50`, `lib/app.dart:19-34`, `lib/core/router/app_router.dart:41-184`.
- **§8 앱 골격 및 기능**: 홈·지도·시설·가이드·검색·설정·즐겨찾기·학식·학사일정·강의실 검색 라우트가 존재한다. 근거: `lib/core/router/app_router.dart:53-184`.
- **가이드 18종**: mock 데이터와 시드 JSON 모두 18개이며 전부 published임을 검사하는 테스트가 있다. 근거: `test/guide_flow_test.dart:4417-4426`, `tool/firestore_seed/guide_items.seed.json`.
- **시설·층별 안내 수량**: 시드 JSON 직접 파싱 결과 시설 48개, 층별 안내 문서 34개, 층 행 249개다. §9의 수량 주장과 일치한다. 근거: `tool/firestore_seed/facilities.seed.json`, `tool/firestore_seed/building_floors.seed.json`.
- **층별 안내 lazy load/cache**: 별도 `building_floors` 컬렉션과 단건 조회, `Source.cache` 폴백이 구현돼 있다. 근거: `lib/data/firestore/firestore_paths.dart:23-24`, `firestore_floor_guide_repository.dart:19-35`.
- **강의실 검색은 placeholder**: 문서가 밝힌 대로 실제 호실 데이터가 아니라 층별 시설명에서 임시 호수를 생성한다. 근거: `lib/presentation/providers/classroom_providers.dart:23-28`.
- **학식 상태 구분**: `open/closed/unpublished`가 엔티티와 화면에 반영돼 있다. 근거: `lib/domain/entities/dining_menu.dart:40-55`, `presentation/dining/dining_menu_screen.dart:202-218`.
- **학사연도 3월~익년 2월**: 현재 로컬 날짜를 기준으로 필터링한다. 근거: `lib/domain/entities/academic_event.dart:38-43`, `presentation/calendar/academic_calendar_screen.dart:38`.
- **기능별 Firestore 플래그**: `USE_FIRESTORE`, `USE_FIRESTORE_CALENDAR`, `USE_FIRESTORE_DINING`이 독립적으로 구현됐다. 근거: `lib/core/config/firebase_init.dart:13-30`, `presentation/providers/repository_providers.dart:38-74`.
- **§13 컬렉션·동기화 구조**: `academic_events`, `cafeterias`, `dining_menus`, `admin_sync_runs`, UUID ID, 식당-날짜 ID, allowlist, 락, 감사로그가 코드에 존재한다. 근거: `tool/admin_sheets/Config.gs:10-17`, `Validation.gs:13-27,60-79`, `Sync.gs:9-25`, `Audit.gs:1-28`.
- **학사일정 atomic full-replace**: 기존 ID 조회 후 upsert와 stale delete를 하나의 commit에 넣는다. 근거: `tool/admin_sheets/Sync.gs:44-65`.
- **시크릿 파일 Git 제외**: `env.json`, `google-services.json`, `GoogleService-Info.plist`, `serviceAccount.json`, `.clasp.json`은 ignore 대상이고 현재 Git 추적 파일 목록에 포함되지 않는다. 로컬에는 `env.json`, Android `google-services.json`, `.clasp.json`이 존재하며 서비스 계정 키는 발견되지 않았다.
- **테스트 수**: 정적 검색 기준 `test`/`testWidgets` 선언은 정확히 78개다.
- **관련 문서**: `01_ux_design.md`, `02_app_architecture.md`, `03_api_integration.md`, `05_qa_report.md`, `06_review_codex.md`가 모두 존재한다.
- **언급된 주요 커밋**: `6a68df2`, `bc3de56`, `8432306`, `7698468`, `0697da6` 등이 현재 Git 이력에 존재한다.

### 불일치·과장·누락

1. **“Firestore 모드로 실배포 가능”은 현재 체크아웃 기준 과장**

   - `plan.md:160`은 서버 데이터가 완전히 최신이고 실배포 가능하다고 표시한다.
   - 그러나 모든 Firestore 플래그의 기본값이 false다. 근거: `lib/core/config/firebase_init.dart:13-26`.
   - Android `google-services.json`과 iOS `GoogleService-Info.plist`가 Git에서 제외되어 깨끗한 체크아웃만으로 재현 가능한 빌드가 아니다.
   - Android 릴리스는 debug 키로 서명된다. 근거: `android/app/build.gradle.kts:33-38`.
   - plan 자체도 실배포 플래그 적용을 미완료로 남겼다. 근거: `plan.md:393`.
   - 따라서 정확한 상태는 “데이터·코드 준비, 배포 구성 미완료”다.

2. **Firebase 설정 파일 설명이 실제 내용과 모순**

   - `lib/firebase_options.dart:1-18`은 파일이 “PLACEHOLDER — NOT REAL CREDENTIALS”이며 잘못된 프로젝트로 연결되지 않게 실패한다고 설명한다.
   - 실제로는 `campus-f4748`의 Android/iOS API key, app ID, project ID가 들어 있다. 근거: 같은 파일 `:46-60`.
   - Firebase client 설정은 원래 비밀이 아니지만, 잘못된 주석 때문에 운영자가 실설정을 placeholder로 오인할 수 있다.

3. **§13의 “오류 문서 격리”는 일부 저장소에만 적용**

   - `plan.md:374`는 앱 저장소 전반이 “오류 문서 격리”를 제공하는 것처럼 기술한다.
   - 학사일정만 문서별 `try/catch`로 malformed 문서를 건너뛴다. 근거: `firestore_academic_calendar_repository.dart:43-49`.
   - 학식은 `cafeteriaMenuFromDocs` 변환을 보호하지 않아 잘못된 식당 문서 하나가 전체 메뉴 요청을 실패시킬 수 있다. 근거: `firestore_dining_repository.dart:96-99`, `firestore_paths.dart:75-88`.
   - 시설·가이드는 `snap.docs.map(...)` 전체 변환이므로 문서 하나의 형식 오류가 목록 전체를 실패시킨다. 근거: `firestore_facility_repository.dart:31-38`, `firestore_guide_repository.dart:23-30`.

4. **“모든 읽기 경로 캐시 폴백” 표현은 제한 조건이 빠짐**

   - `plan.md:153`은 모든 읽기 경로에 cache fallback이 있다고 주장한다.
   - 네트워크 요청이 `FirebaseException`을 던질 때만 명시적 캐시 조회가 수행된다. 파싱 오류나 기타 Dart 예외에는 폴백하지 않는다. 근거: `firestore_facility_repository.dart:31-49`, `firestore_guide_repository.dart:23-41`.
   - 최초 실행 후 오프라인인 경우 캐시 자체가 없으므로 사용할 수 없다. mock 데이터로 자동 전환하는 로직도 없다.

5. **“서비스 계정 키 미사용”은 정책과 현재 파일 상태만 확인됨**

   - 로컬 키 파일은 발견되지 않았고 Git에서도 추적되지 않는다.
   - 하지만 시드 도구는 `serviceAccount.json`이 있으면 여전히 우선 사용한다. 근거: `tool/firestore_seed/seed.mjs:37-45`.
   - 기존 키가 GCP에서 실제 폐기·회전됐는지는 **미확인**이다. 저장소만으로 IAM/GCP 상태를 검증할 수 없다.

6. **§7·§13의 외부 운영 사실은 미확인**

   다음은 코드나 Git 이력이 아니라 외부 상태이므로 독립 확인할 수 없었다.

   - 학교 API 제공 불가 확정 여부
   - Firestore 서울 리전 및 현재 서버 문서 수
   - 배포된 보안 규칙 버전
   - Apps Script 실제 배포·시트 입력·Firestore E2E 성공
   - 카카오 콘솔 도메인/SDK 활성 상태
   - Pixel 7 및 실기기 스크린샷 결과
   - 관리자 IAM 역할 및 기존 키 폐기 여부

   관련 주장: `plan.md:134,147,160,162,164,178-191,375,378-381`.

7. **검증 명령의 현재 재실행은 미확인**

   - 소스상 테스트 선언은 78개지만 현재 환경에는 `flutter` 실행 파일이 없어 `flutter analyze --no-pub`와 `flutter test --no-pub`를 재실행하지 못했다.
   - 따라서 `plan.md:352`, `plan.md:381`의 과거 성공 기록은 Git 문서상 존재하나 현재 HEAD에서의 실제 통과 여부는 **미확인**이다.

8. **§6 일정은 계획과 현재 상태가 혼재**

   - 1개월 로드맵은 여전히 “4주차 출시 준비” 구조지만 `plan.md:166-170`에는 스토어 메타데이터·개인정보처리방침·심사·iOS 실기기 검증이 미완료다.
   - 따라서 문서 상단의 “MVP 기능 완료”는 기능 구현 의미로는 타당하지만 출시 준비 완료로 해석하면 부정확하다.

9. **§11 설명 일부가 과거 상태**

   - `presentation/dining/dining_menu_screen.dart:15-17`과 `mock_dining_repository.dart:5-6`은 여전히 “학교 API 대기”라고 설명한다.
   - 확정 설계는 관리자 입력 파이프라인이므로 plan §11·§13과 코드 주석이 불일치한다.

10. **층별 안내 콘텐츠 규모 표현 주의**

   - §9의 “249층 행”은 맞다. 실제 방/시설 문자열은 2,876개다.
   - `plan.md:161`의 “2천여 건”은 대략적으로 맞지만 정확한 현재 시드 기준은 2,876개다.

## 2. 취약점

### Android 릴리스가 debug 키로 서명됨

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/android/app/build.gradle.kts:33-38`
- **설명:** release 빌드가 명시적으로 debug signing config를 사용한다. 유출되기 쉬운 공용 debug 키에 배포 신뢰가 묶이고, 스토어 정식 서명·업데이트 체계와 호환되지 않는다. plan의 “릴리즈 APK” 표현도 실제 운영 릴리스와 혼동될 수 있다.
- **권고:** Play App Signing을 사용하고 업로드 키를 별도 keystore 및 CI secret로 관리한다. production release에서 debug signing 사용 시 빌드가 실패하도록 구성한다.

### Apps Script 실행자에게 프로젝트 범위의 광범위한 IAM 권한 필요

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/appsscript.json:6-10`, `_workspace/06_admin_data_pipeline.md:125`, `tool/admin_sheets/README.md:80`
- **설명:** `cloud-platform` OAuth scope와 계획된 `Cloud Datastore User` 역할은 앱의 세 컬렉션보다 훨씬 넓다. Firestore REST 호출은 보안 규칙을 우회하므로 해당 계정 또는 수정된 Apps Script가 허용 목록 밖의 문서까지 읽고 쓸 수 있다. 컬렉션 allowlist는 현재 소스의 실수만 줄일 뿐 IAM 경계가 아니다.
- **권고:** 허용된 컬렉션/동작만 수행하는 Cloud Functions 또는 Cloud Run 프록시를 두고 서버 측에서 관리자 인증·스키마 검증을 강제한다. 직접 IAM 방식을 유지한다면 전용 계정과 검증된 custom role을 사용하고 Apps Script 편집 권한을 엄격히 분리한다.

### Android 전역 cleartext 통신 허용

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/android/app/src/main/AndroidManifest.xml:7-11`, `lib/presentation/map/widgets/kakao_init.dart:10-15`
- **설명:** Kakao WebView의 `http://localhost` 때문에 앱 전체에 `usesCleartextTraffic="true"`가 적용됐다. 이 설정은 다른 라이브러리나 향후 코드의 임의 HTTP 요청까지 허용해 평문 트래픽·중간자 공격 표면을 넓힌다.
- **권고:** Android Network Security Config로 localhost만 예외 허용하고 기본 cleartext는 차단한다. WebView가 실제로 loopback 예외 없이 작동 가능한지도 검증한다.

### 공개 Firestore 읽기에 App Check·남용 억제가 없음

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/firestore.rules:16-48`
- **설명:** 여섯 콘텐츠 컬렉션이 인증·App Check 없이 전 세계 공개 읽기다. 개인정보는 없어도 전체 데이터 스크래핑과 자동화된 반복 읽기로 Firebase 비용·쿼터가 소진될 수 있다.
- **권고:** Firebase App Check 적용, 예산 알림·쿼터·사용량 모니터링을 구성한다. 정적이고 공개적인 데이터라면 CDN/정적 JSON 배포가 더 적합한지도 검토한다.

### 동기화 성공과 감사로그가 원자적이지 않음

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/Sync.gs:53-64,111-137`, `Audit.gs:23-28`
- **설명:** 콘텐츠 commit 후 별도 요청으로 감사로그를 저장하며, 감사로그 실패는 경고만 내고 삼킨다. 따라서 실제 게시가 성공했지만 `admin_sync_runs` 기록이 없는 상태가 가능하다. “모든 run 감사로그 기록”이라는 §7 D5 보장과 다르다.
- **권고:** 콘텐츠 write와 감사 문서를 동일 Firestore commit에 포함하거나, 최소한 감사로그 실패를 전체 작업 실패/재조정 대상으로 기록한다. 별도 외부 로그에도 commit 식별자를 남긴다.

### 학사일정 전체 삭제 사고 가능

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/Sync.gs:44-58,68-76`
- **설명:** 시트가 비어 있으면 기존 Firestore 일정 전부가 stale로 판단된다. 확인창은 있지만 삭제 대상이 20개를 넘으면 일부 ID만 표시하고, 권한 있는 사용자의 오조작 한 번으로 전체 일정이 삭제될 수 있다.
- **권고:** 빈 시트 publish 금지, 삭제 비율/건수 임계치, 두 단계 승인, 직전 snapshot 자동 보관, expected revision precondition을 추가한다.

### 입력 텍스트 길이와 문서 크기 제한 부재

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/Validation.gs:83-99,135-145`
- **설명:** 제목·메뉴 항목 수·각 문자열 길이에 제한이 없다. 권한 있는 사용자의 과도한 입력으로 Firestore 1MiB 문서 제한을 초과하거나 앱 화면에 비정상적으로 큰 데이터를 전달할 수 있다.
- **권고:** 필드별 최대 길이, 메뉴 항목 수, 총 UTF-8 byte 크기를 검증하고 Firestore 스키마 한도보다 충분히 낮게 제한한다.

### 서비스 계정 키 fallback이 남아 있음

- **심각도:** low
- **파일:라인:** `_workspace/02_app_code/tool/firestore_seed/seed.mjs:37-45`
- **설명:** 확정안은 ADC 키리스 전환이지만, 로컬에 `serviceAccount.json`이 생기면 도구가 경고 후 그대로 사용한다. 키 기반 운영이 조용히 재도입될 수 있다. 현재 키 파일은 발견되지 않았으며 기존 GCP 키 폐기는 **미확인**이다.
- **권고:** fallback을 제거하고 키 파일이 있으면 즉시 실패시킨다. GCP IAM에서 기존 키 폐기를 별도로 확인한다.

### Apps Script 배포 식별자 노출 범위

- **심각도:** low
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/.clasp.json:1-5`
- **설명:** `.clasp.json`에는 script ID와 parent spreadsheet ID가 있다. 현재 Git에서 추적되지 않고 ignore되어 있어 저장소 노출은 방지됐지만, 로컬 파일 백업·공유 시 내부 리소스 식별자가 노출될 수 있다. ID 자체만으로 권한을 얻지는 못한다.
- **권고:** 계속 Git 제외하고, 지원 자료·로그·스크린샷에 포함하지 않는다. 문서 공유 권한을 정기 점검한다.

### 시크릿 관리 확인 결과

- **심각도:** low
- **파일:라인:** `/.gitignore`, `_workspace/02_app_code/.gitignore`
- **설명:** `env.json`, Google 플랫폼 설정, 서비스 계정 키, `.clasp.json`은 현재 추적되지 않는다. `firebase_options.dart`의 Firebase API key는 클라이언트 식별 정보로서 서버 비밀은 아니지만 API key 제한 설정은 저장소에서 확인할 수 없다.
- **권고:** Kakao 키에는 허용 도메인·앱 제한을, Firebase API key에는 사용 API 제한을 적용한다. 해당 콘솔 설정은 **미확인**이다.

## 3. 약점·리스크

### Firestore malformed 문서 하나가 시설·가이드·학식 전체를 중단시킬 수 있음

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/lib/data/firestore/firestore_facility_repository.dart:31-38`, `firestore_guide_repository.dart:23-30`, `firestore_dining_repository.dart:90-99`
- **설명:** 목록 변환이 문서별 격리 없이 수행된다. Firestore에는 서버 측 스키마가 없고 관리자 경로는 보안 규칙도 우회하므로 잘못된 필드 타입 하나가 전체 화면 오류로 이어질 수 있다.
- **권고:** 모든 저장소에서 문서별 파싱 격리·로깅·오류 지표를 적용하고, 게시 전에 동일 Dart 스키마 또는 JSON Schema 기반 검증을 수행한다.

### 배포 플래그 누락 시 production에서도 mock 데이터 표시

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/lib/core/config/firebase_init.dart:13-26`, `presentation/providers/repository_providers.dart:38-74`, `plan.md:393`
- **설명:** 세 플래그 기본값이 모두 false다. 배포 명령에서 하나라도 빠지면 앱은 오류 없이 샘플 데이터로 실행된다. 이는 학사일정·식단 같은 시의성 높은 정보에서 특히 위험하다.
- **권고:** production flavor에서는 Firestore 플래그를 소스상 강제하고 mock repository 참조를 빌드 실패 조건으로 검사한다. 앱 내부에 데이터 환경/빌드 채널도 표시한다.

### 깨끗한 체크아웃의 Firebase 빌드 재현성이 없음

- **심각도:** high
- **파일:라인:** `/.gitignore`, `_workspace/02_app_code/.gitignore`, `lib/firebase_options.dart:9-14`, `plan.md:190`
- **설명:** 플랫폼 Firebase 설정 파일이 모두 Git 제외다. 현재 Android 파일은 로컬에 있지만 iOS plist는 발견되지 않았다. 신규 CI·개발 환경에서 별도 수동 복구 없이는 빌드가 실패할 수 있다.
- **권고:** Firebase client 설정은 비밀이 아니므로 추적하는 방안을 우선 검토한다. 제외를 유지한다면 CI에서 검증된 생성 단계와 존재 여부 사전검사를 자동화한다.

### 앱 시작 초기화 실패가 복구 불가능한 흰 화면으로 이어질 수 있음

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/lib/main.dart:10-30`
- **설명:** Firebase 초기화, SharedPreferences, Kakao 초기화를 모두 `runApp` 전에 await하며 최상위 오류 처리가 없다. 설정 누락·플러그인 예외가 나면 오류 UI나 재시도 없이 앱 자체가 뜨지 않는다.
- **권고:** 최소 앱 셸을 먼저 시작하거나 최상위 bootstrap 오류 화면을 제공한다. Kakao와 비핵심 초기화는 기능 단위로 격리한다.

### 오프라인 전략이 “최초 성공 이후”에만 유효

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/lib/core/config/firebase_init.dart:47-52`, `firestore_floor_guide_repository.dart:20-35`
- **설명:** Firestore 캐시는 이전 동기화 데이터가 있어야 한다. 설치 직후 오프라인이면 시설·가이드·층별 안내가 모두 실패하며 번들 mock 데이터로 폴백하지 않는다.
- **권고:** 핵심 캠퍼스·가이드 데이터를 앱 번들 snapshot으로 포함하고 `network → cache → bundled seed` 순서의 명시적 폴백을 구현한다.

### Firestore 캐시 크기 무제한

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/lib/core/config/firebase_init.dart:49-52`
- **설명:** `CACHE_SIZE_UNLIMITED`는 운영 기간과 데이터 확장에 따라 앱 저장 공간이 계속 증가할 수 있다. 현재 데이터는 작지만 dining 문서는 날짜별로 누적되는 구조다.
- **권고:** 합리적인 cache 상한을 두고 오래된 식단 문서의 보존·TTL 정책을 확정한다.

### 식당 메타데이터가 세션 동안 갱신되지 않음

- **심각도:** low
- **파일:라인:** `_workspace/02_app_code/lib/data/firestore/firestore_dining_repository.dart:23-47`
- **설명:** cafeterias 목록은 repository lifetime 동안 캐시된다. 영업시간·시설 링크를 관리자가 수정해도 앱을 재시작하기 전까지 이전 값이 유지될 수 있다.
- **권고:** TTL 또는 refresh 동작을 추가하고 앱 resume/사용자 새로고침 시 갱신한다.

### 날짜·타임존이 기기 로컬 시간에 의존

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/lib/presentation/calendar/academic_calendar_screen.dart:38`, `presentation/dining/dining_menu_screen.dart:26-29`, `domain/entities/academic_event.dart:56-65`
- **설명:** 관리 파이프라인은 Asia/Seoul로 날짜를 생성하지만 앱의 “오늘”과 현재 학년도는 `DateTime.now()`의 기기 타임존을 사용한다. 해외 타임존·잘못 설정된 기기에서는 한국 기준 오늘의 식단이나 학년 전환이 하루 어긋날 수 있다.
- **권고:** 캠퍼스 기능의 기준 날짜를 Asia/Seoul로 명시적으로 계산하고 날짜 전용 타입 또는 timezone 패키지를 사용한다.

### 사용자 데이터 손상과 저장 실패가 조용히 무시됨

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/lib/data/repositories/local_favorites_repository.dart:15-30`, `presentation/providers/favorites_provider.dart:35-38`
- **설명:** 즐겨찾기 JSON 파싱 실패 시 빈 목록으로 대체하고 저장 실패도 UI 계층에서 삼킨다. 사용자는 데이터가 사라졌거나 저장되지 않았다는 사실을 알 수 없다.
- **권고:** 손상 데이터 백업, 로깅, 저장 성공 여부 확인, 사용자 오류 메시지와 재시도를 추가한다.

### 테스트 커버리지 공백

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/test/` 전체, `firestore.rules:10-11`
- **설명:** 78개 테스트는 존재하지만 다음 핵심 영역의 자동 테스트는 발견되지 않았다.
  - Firestore security rules emulator 테스트
  - Apps Script validation/sync/권한/500개 경계/전체 삭제 테스트
  - 실제 Firestore 저장소의 malformed 문서 및 cache fallback 테스트
  - Android release signing·network security 검사
  - iOS 빌드/실기기 및 접근성 회귀
  - clean checkout production build
- **권고:** Firebase Emulator Suite, Apps Script 로직의 순수 함수 분리, repository fake Firestore 테스트, CI의 Android release 빌드를 우선 추가한다.

### CI/CD와 스토어 배포 자동화 부재

- **심각도:** high
- **파일:라인:** 리포지토리 전체에서 `.github/workflows`, Fastlane, 배포 스크립트가 발견되지 않음
- **설명:** analyze/test/build, define 플래그, 플랫폼 설정, 서명, rules 배포를 사람의 로컬 명령에 의존한다. 문서에서 과거 검증을 완료로 표시해도 이후 커밋에 대한 회귀를 막지 못한다.
- **권고:** 최소한 analyze, test, seed JSON 검증, Android release build, rules emulator 테스트를 CI 필수 단계로 만든다.

### 개인정보처리방침 및 스토어 준비 미완료

- **심각도:** high
- **파일:라인:** `_workspace/02_app_code/lib/core/config/app_config.dart:31-39`, `plan.md:166-170`
- **설명:** 개인정보처리방침 URL은 기본 문자열만 존재하며 실제 호스팅 문서는 리포지토리에서 발견되지 않았다. 앱은 정밀 위치 권한을 요청하므로 정책·스토어 데이터 안전성 선언이 필요하다.
- **권고:** 공개 접근 가능한 실제 정책을 준비하고 수집·처리·보존·제3자 SDK를 명시한다. Google Play Data safety와 App Store Privacy Nutrition Labels를 실제 SDK 동작에 맞춰 작성한다.

### 위치 권한의 필요 범위가 넓음

- **심각도:** low
- **파일:라인:** `_workspace/02_app_code/android/app/src/main/AndroidManifest.xml:4-6`, `lib/data/services/location_service.dart:43-78`
- **설명:** 앱은 지도상의 현재 위치 표시를 위해 fine location과 high accuracy 연속 스트림을 사용한다. 기능상 가능하지만 배터리·개인정보 측면에서 비용이 크다.
- **권고:** approximate 위치로도 기능이 가능한지 검토하고, 지도 화면을 벗어나면 스트림이 확실히 취소되는 테스트를 추가한다.

### 데이터 최신성 표시와 운영 SLA 부재

- **심각도:** medium
- **파일:라인:** `_workspace/02_app_code/tool/admin_sheets/Validation.gs:38,105-107`, `lib/presentation/dining/dining_menu_screen.dart:202-218`
- **설명:** 문서에는 `updatedAt`이 기록되지만 앱은 마지막 갱신 시각이나 오래된 데이터 경고를 보여주지 않는다. 관리자가 동기화를 잊으면 학생은 오래된 학사·식단 정보를 최신으로 오인할 수 있다.
- **권고:** 화면에 최종 갱신 시각과 데이터 출처를 표시하고, 일정 기간 이상 오래된 데이터에 경고를 붙인다. 동기화 누락 알림과 운영 담당자 SLA를 둔다.

## 4. 종합 의견

핵심 기능의 코드·데이터 구조는 plan.md와 대체로 일치한다. 시설 48개, 가이드 18개, 층별 안내 34개/249층, 테스트 선언 78개, §7 합의안의 주요 파이프라인 구조도 실제 파일에 구현돼 있다. 특히 클라이언트 쓰기 차단, UUID/allowlist, 학사일정 단일 atomic commit, 학식의 `unpublished` 구분은 합의안을 충실히 반영한다.

다만 문서의 “가동”, “서버 최신”, “실배포 가능”, “E2E 검증 완료”에는 외부 상태와 과거 수동 검증이 섞여 있다. 현재 리포지토리만으로 확정할 수 있는 것은 코드와 로컬 데이터 준비 상태까지다. debug 릴리스 서명, 기본 mock 플래그, 누락 가능한 Firebase 플랫폼 파일, CI 부재 때문에 현재 상태를 production-ready로 보기는 어렵다.

출시 전 우선순위는 다음과 같다.

1. debug release 서명을 제거하고 production 빌드·플래그·Firebase 설정을 재현 가능하게 만든다.
2. Apps Script의 광범위한 IAM 경계를 축소하고 전체 삭제·감사로그 실패를 방어한다.
3. Firestore malformed 문서 격리와 최초 오프라인 bundled fallback을 구현한다.
4. rules/Apps Script/production build를 CI에서 자동 검증한다.
5. 개인정보처리방침, 스토어 선언, 데이터 최신성 운영 절차를 완료한다.

이 다섯 항목이 해소되기 전에는 plan.md의 상태를 “MVP 기능 구현 완료, 운영·보안·배포 준비 진행 중”으로 수정하는 것이 실제 리포지토리 상태에 가장 정확하다.