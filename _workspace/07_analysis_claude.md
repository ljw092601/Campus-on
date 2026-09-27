# Claude 분석 결과 — 동아메이트 전체 코드 감사

> 생성: 2026-09-10 · 대상: main @ `9a18575` · 짝 문서: `07_analysis_codex.md`
>
> **방법론**: Claude Code 워크플로 오케스트레이션으로 12개 에이전트 실행.
> 6개 차원을 병렬 분석(plan 정합성·보안·Apps Script 파이프라인·앱 데이터 계층 = **Opus**, UI/다국어/접근성·테스트/빌드 = **Sonnet**)한 뒤,
> 각 차원의 발견사항을 같은 모델의 검증 에이전트가 **적대적으로 재검증**(파일 재확인, 반박 시도, 심각도 조정)했다.
> 결과: 발견 57건 중 **56건 확정, 1건 반박·제외**. 검증자가 심각도를 낮춘 항목 12건(각 항목에 표기).

## 종합 요약

**plan.md 정합성**: 핵심 주장(아키텍처, 시드 수량 48/18/34/3, 플래그 3종 기본 false, firestore.rules 구성, ADC 키리스 전환, §13 파이프라인 구현, 테스트 78건)은 모두 실제와 일치한다. 불일치는 전부 "문서가 코드보다 낡은" 방향이다: ①폐기된 '학교 API 확인 예정' 전제가 §4·§11·앱 배너 문구·코드 주석에 잔존, ②main에 이미 있는 GPS 내 위치·주변 장소 검색 기능이 plan에 미기록(스토어 심사·개인정보처리방침에 직결), ③최근 지도 3커밋 미반영, ④`firebase_options.dart`의 "PLACEHOLDER" 주석이 실값과 모순, ⑤시드 README가 academic_events를 시드 대상으로 잘못 안내.

**심각도 분포** (검증 조정 후): high 3 · medium 21 · low 31 · info 1. critical 없음 — 시크릿 유출·인증 우회·데이터 파괴 수준의 결함은 발견되지 않았다. 시크릿 관리(gitignore + 전 커밋 이력 검사)와 firestore.rules는 양호로 확정.

**최우선 조치 (high + 교차 확인된 medium)**:
1. **릴리즈 준비 3종** — Android release가 debug 키 서명(+R8 미적용)이고, Firestore 3플래그를 켜는 릴리즈 절차가 없어 플래그 누락 시 production이 조용히 mock 데이터로 돌아간다. 스토어 배포 전 차단 이슈. (§2·§6 교차 확인)
2. **오프라인 오표기** — 오프라인/빈 캐시에서 컬렉션 조회가 예외 없이 빈 목록을 돌려줘 "검색 결과 없음"·"식단 미등록"으로 표시된다. 학식은 §7 합의("캐시 부재와 미등록 구분")의 명시적 위반. `isFromCache` 확인 코드가 lib 전체에 0건.
3. **malformed 문서 격리 부재** — 문서별 try/catch가 학사일정에만 있고 facilities/guide_items/dining에는 없어 문서 1건이 화면 전체를 무너뜨린다.
4. **Apps Script 검증 우회** — `allowlist[label]`의 프로토타입 체인 조회로 enum 검증을 우회해 오염 값이 문서 ID·status 필드까지 도달(§7 문서 ID 원칙 위반). `hasOwnProperty` 체크 한 줄로 수정 가능. 삭제 확인창이 UUID만 보여줘 full-replace 안전장치가 형식화된 문제도 함께.
5. **테스트·CI 공백** — Firestore 리포지토리 6종·Apps Script 607줄·seed.mjs·rules 전부 자동 테스트 0건, CI 부재. 캐시 리셋 같은 미묘한 로직이 회귀 가드 없이 유지되고 있다.
6. **접근성 대비 미달** — 오늘자 핀 팔레트 동기화로 필터 칩 선택 상태의 흰 글자가 5개 카테고리 색과 WCAG AA(4.5:1) 미달(3.39~3.87, 계산 검증됨).

**차원 간 중복 항목**(각 차원 관점을 보존하기 위해 본문에 그대로 둠): debug 서명(§2 medium/§6 high — 배포 시점 기준 §6이 타당), firebase_options "PLACEHOLDER" 주석(§1·§2·§4), OAuth 스코프 과다(§2 low/§3 medium), Firestore 리포지토리 테스트 부재(§4·§6).

---

## 1. plan.md 정합성 — Opus

**전반 평가**: plan.md 297줄의 주요 주장은 대체로 리포 실상과 일치했다. 검증 결과 일치한 항목: 섹션 8의 Flutter 골격(Riverpod+go_router)·i18n·카카오맵·3탭 구조(app_shell.dart 3개 destination)·`/guide`의 `/home` 자식 이관과 redirect(app_router.dart), 패키지명 `io.github.ljw092601.campuson`(Android namespace/applicationId + iOS PRODUCT_BUNDLE_IDENTIFIER), 시드 수량(facilities 48/승학24·구덕15·부민9, guide_items 18 전부 published, building_floors 34·층 249, cafeterias 3, name_en 누락 0), `academic_events`가 seed.mjs COLLECTIONS에서 실제로 제외된 점, 플래그 3종(`USE_FIRESTORE`/`USE_FIRESTORE_CALENDAR`/`USE_FIRESTORE_DINING`)이 기본 false이고 `anyFirestoreEnabled` OR로 Firebase 초기화를 게이트하는 점, firestore.rules의 신규 3컬렉션 공개 read + `admin_sync_runs` 기본 deny, ADC 키리스 전환(`.firebaserc` 존재·serviceAccount.json 부재), gitignore(env.json/google-services.json/serviceAccount.json/.clasp.json — 추적된 시크릿 0건), 섹션 13의 Apps Script 구현(LockService·atomic commit·삭제 diff 확인 다이얼로그·`unpublished` tombstone·admin_sync_runs·README/ADMIN_GUIDE), 테스트 78건(test/ 디렉터리 실제 78개), 섹션 10의 `classroom_providers.dart` placeholder 파생과 `TODO(room-data)`, `/map?focus=&floor=` 딥링크가 모두 확인됐다. 반면 plan.md는 최신 3커밋(지도 핀 교체·확대/축소 버튼·핀 크기)과 이미 main에 있는 GPS 내 위치 추적·주변 장소 검색 기능을 전혀 다루지 않으며, 섹션 4·11과 앱 문구·주석 곳곳에 "학교 API 연동 예정"이라는 폐기된 전제가 남아 있다. 섹션 13-4의 시트 테스트 데이터 정리·IAM 부여 항목은 리포 외부 상태라 검증 불가이며, `03_api_integration.md`는 2주차 산출물 성격상 신규 컬렉션이 없어 별도 결함으로 보지 않았다.

### [medium] 섹션 4·서두에 '학교 공식 API 미확인' 전제가 그대로 남아 §7-4의 'API 제공 불가 확정'과 모순

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:75`
- **내용**: plan.md 134행(§7-4)과 §13은 2026-09-10에 학사일정·학식 모두 학교 API를 받을 수 없음이 확정돼 관리자 시트 파이프라인으로 전환·가동됐다고 명시한다. 그러나 14행('공식 API 존재 여부는 확인 필요'), 75행('공식 API 존재 여부는 아직 미확인 → API 확인되면 연동'), 82행('❓ 공식 API 확인 후 결정'), 156행의 미체크 항목 '국제교류처에 데이터/API 제공 가능 여부 문의'가 그대로 남아 있어 같은 문서 안에서 데이터 소스 전략이 상반되게 읽힌다. 실제 코드는 이미 `FirestoreDiningRepository`/`FirestoreAcademicCalendarRepository`와 `tool/admin_sheets/` 동기화 경로만 구현돼 있다.
- **권고**: §4 표와 서두 14행을 '학교 API 불가 → 관리자 시트 입력(§13)'으로 갱신하고, 156행 항목은 콘텐츠 검수 협조 요청으로 범위를 좁히거나 취소선 처리하라.
- **검증 노트**: plan.md를 직접 열어 14행('공식 API 존재 여부는 확인 필요'), 75행('아직 미확인 → API 확인되면 연동'), 82행('❓ 공식 API 확인 후 결정'), 85행 액션아이템, 156행 미체크 항목이 그대로 남아 있음을 확인했다. 반면 134행(§7-4)과 §13 전체(360~394행)는 2026-09-10에 'API 제공 불가 확정'과 시트→Firestore 파이프라인 '구축·가동'을 선언하며, 코드 쪽도 FirestoreDiningRepository/FirestoreAcademicCalendarRepository와 tool/admin_sheets/만 존재한다. 같은 문서 안에서 데이터 소스 전략이 정면 충돌하는 것이 맞으며 medium 심각도도 과장이 아니다.

### [medium] 앱 사용자 문구가 여전히 '학교 API 연동 후 실제 메뉴가 표시됩니다'라고 안내

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/l10n/app_ko.arb:60`
- **내용**: `dining_placeholder_notice`(ko 60행)는 '지금은 예시 식단이에요. 학교 API 연동 후 실제 메뉴가 표시됩니다.', en 61행도 'once the school API is connected'로 적혀 있어 plan.md §7-4의 'API 제공 불가 확정'과 정면으로 어긋나는 안내를 사용자에게 노출한다. 같은 전제의 잔재가 `dining_menu_screen.dart` 17행 주석(`TODO(dining-api)`)과 `mock_dining_repository.dart` 6행에도 남아 있다. mock 모드에서만 표시되긴 하지만 현재 기본 실행 모드가 mock이라 실제로 보이는 문구다.
- **권고**: 배너 문구를 '관리자가 식단을 등록하면 실제 메뉴가 표시됩니다' 취지로 교체하고 `TODO(dining-api)` 주석도 관리자 파이프라인 기준으로 갱신하라.
- **검증 노트**: app_ko.arb 60행 `dining_placeholder_notice`가 '지금은 예시 식단이에요. 학교 API 연동 후 실제 메뉴가 표시됩니다.', app_en.arb 61행이 'once the school API is connected'임을 직접 확인했다. dining_menu_screen.dart 17행 주석 `TODO(dining-api)`도 남아 있고, 배너는 77행 `if (!useFirestoreDining)` 가드 뒤에 있지만 플래그 기본값이 false이며 plan.md 393행이 '실배포 빌드에 USE_FIRESTORE_DINING=true 적용'을 아직 미체크로 두고 있어 현재 빌드에서는 실제로 노출된다. 사용자 대면 문구가 확정 사실과 반대라 medium이 타당하다.

### [medium] plan.md에 GPS '내 위치' 추적과 주변 장소 검색 기능이 전혀 기록되지 않음

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:141`
- **내용**: main에는 `lib/data/services/location_service.dart`, `lib/presentation/providers/location_providers.dart`, `domain/entities/user_location.dart`·`nearby_place.dart`와 `map_screen.dart`의 실시간 위치 추적 FAB(권한 거부/GPS 꺼짐 스낵바 분기)·`/map?nearby=` 카카오 키워드 검색이 구현돼 있고(커밋 8c9cebd, 01e2231), `pubspec.yaml`에 `geolocator`·`flutter_compass` 의존성까지 추가돼 있다. 그런데 plan.md 어디에도 '내 위치', 위치 권한, 주변 장소 검색에 대한 항목이 없어(§8 체크리스트·§9·§10 모두 미언급) 범위 문서와 실제 앱 기능이 어긋난다. 위치 수집은 스토어 심사·개인정보처리방침에 직접 영향을 주는 항목이라 누락 비용이 크다.
- **권고**: §8 체크리스트에 GPS 내 위치·주변 장소 검색 완료 항목을 추가하고, §6-1/스토어 준비 항목에 위치 권한 고지·개인정보처리방침 반영을 명시하라.
- **검증 노트**: plan.md 전체에서 '내 위치/위치 권한/GPS/geolocator/주변 장소' 검색 결과는 67행의 Phase 2 후보 '주변 맛집' 한 줄뿐이고, 구현 사실을 기록한 항목은 §8·§9·§10 어디에도 없다. 실제로는 lib/data/services/location_service.dart·presentation/providers/location_providers.dart·domain/entities/user_location.dart·nearby_place.dart가 존재하고 map_screen.dart 156~204행에 권한 거부/GPS 꺼짐 분기 스낵바와 myLocation FAB(406~408행), 375~387행의 `?nearby=` 검색이 있으며 pubspec 43~44행에 geolocator·flutter_compass, AndroidManifest 5~6행에 ACCESS_COARSE/FINE_LOCATION 권한까지 선언돼 있다. 위치 권한은 스토어 심사·개인정보처리방침 항목이라 medium 유지가 맞다.

### [low] 섹션 4 표의 지도 연동 방식이 'Google Maps/네이버 지도'로 남아 실제 카카오맵 구현과 불일치

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:79`
- **내용**: §4 표 79행은 캠퍼스 지도를 'Google Maps/네이버 지도 위에 시설 좌표 오버레이'로 기술하지만, 같은 문서 13·93행은 카카오맵 SDK 확정이라고 적고 있고 실제 구현도 `pubspec.yaml`의 `kakao_map_plugin: ^0.3.1`과 `lib/presentation/map/widgets/campus_map_view.dart`(카카오 `keywordSearch`·`MarkerIcon`)로 카카오맵 전용이다. 초안 시절 표가 갱신되지 않고 남은 잔재다.
- **권고**: §4 표의 지도 행을 '카카오맵 SDK 위 시설 좌표 오버레이'로 수정하라.
- **검증 노트**: plan.md 79행이 'Google Maps/네이버 지도 위에 시설 좌표 오버레이'로 남아 있는 반면 13행·93행은 카카오맵 SDK 확정이라고 적고 있다. 실제 구현도 pubspec.yaml 38행 kakao_map_plugin ^0.3.1, campus_map_view.dart 5행 `import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao`로 카카오맵 전용이며 Google/Naver 의존성은 전혀 없다. 초안 잔재가 맞고, 같은 문서 안에 정정 서술이 두 곳 있어 오독 위험은 낮으므로 low가 적절하다.

### [low] 섹션 11 제목·11-2가 아직 '학교 API 연동 대기'로 서술돼 11-1·섹션 13과 충돌

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:312`
- **내용**: 312행 제목은 '오늘의 학식 (2026-08-31 구현 완료, API 연동 대기)', 328행은 '예시 식단 안내 배너(API 연동 전임을 명시)'라고 적혀 있으나, 바로 아래 11-1(316~319행)과 §13은 API 불가 확정 후 관리자 시트 입력으로 전환 완료라고 선언한다. 실제 코드도 `dining_menu_screen.dart` 77~80행에서 배너를 `useFirestoreDining`이 꺼진 mock 모드에서만 노출하도록 바꿔 놓아, 제목·11-2 서술만 옛 상태로 남아 있다.
- **권고**: §11 제목을 '(관리자 입력 전환 완료)'로 바꾸고 11-2의 배너 설명을 'mock 모드에서만 표시되는 예시 데이터 안내'로 고쳐라.
- **검증 노트**: plan.md 312행 제목이 '(2026-08-31 구현 완료, API 연동 대기)', 328행이 '"예시 식단" 안내 배너(API 연동 전임을 명시)'로 확인된다. 바로 아래 316~319행(11-1)과 335행은 'API 제공 불가 확정 → 관리자 입력 파이프라인 대체 완료'라고 적어 자기모순이며, dining_menu_screen.dart 77~81행은 `if (!useFirestoreDining)` 가드로 배너를 mock 모드에만 노출하도록 이미 바뀌어 있다. 문서 제목·11-2만 옛 상태로 남은 것이 맞다.

### [low] 최신 지도 관련 3커밋(핀 교체·확대/축소 버튼·핀 크기)이 plan.md에 미반영

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:208`
- **내용**: plan.md 최종 갱신 커밋은 0697da6이고, 이후 b4279d5(핀 이미지 6종 교체 + 카테고리 색을 핀 팔레트로 동기화 — `category_colors.dart` 변경), 4a47c11(지도 확대/축소 버튼 + `CampusMapZoomHandle` 신설 + l10n 2키), 9a18575(핀 렌더 40x50→32x40 축소)가 main에 올라갔다. 문서 4행은 여전히 '최종 갱신: 2026-09-10 · 상태: … 가동'까지만 적고 있어 §8 진행 로그가 HEAD보다 3커밋 뒤처져 있다. 특히 153행의 '6색 커스텀 마커' 서술은 색만 다른 옛 핀 기준이라 현재의 카테고리별 아이콘 핀과 설명이 다르다.
- **권고**: §8에 지도 핀 리디자인·줌 컨트롤 항목을 추가하고 153행의 마커 설명을 카테고리 아이콘 핀 기준으로 갱신하라.
- **검증 노트**: `git log -1 --format=%H -- plan.md`가 0697da6을 반환해 이후 b4279d5·4a47c11·9a18575 3커밋이 문서에 미반영임을 확인했다. b4279d5는 핀 PNG 6종을 카테고리별 아이콘 핀으로 교체하고 category_colors.dart를 핀 실측색으로 동기화했으며, CampusMapZoomHandle이 campus_map_view.dart 42행에 신설돼 map_screen.dart 73행에서 쓰인다. plan.md 153행의 '지도 6색 커스텀 마커'는 '색만 다른 동일 핀' 시절 서술이라 현재와 다르다. 문서 지연 자체는 low가 적절하다.

### [low] 섹션 8의 릴리즈 APK 배포 상태가 실제 파일과 불일치

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `plan.md:203`
- **내용**: 203행은 '바탕화면 `dongamate-main-<커밋>.apk`로 배포 중 (현재 6e2807c)'라고 적었지만, 바탕화면에는 `Campus-On.apk`(2026-07-15 생성) 한 개만 존재하고 `dongamate-main-*.apk`는 없다(`find /Desktop -maxdepth 2 -iname '*.apk'` 결과 1건). 또한 6e2807c는 현재 HEAD(9a18575)보다 9커밋 뒤라 학사일정 카드·관리자 파이프라인·지도 변경이 모두 빠진 빌드다.
- **권고**: 현재 배포 중인 APK 파일명·커밋을 실제 상태로 갱신하거나, 최신 커밋으로 재빌드한 뒤 항목을 다시 적어라.
- **검증 노트**: plan.md 203행의 '바탕화면 dongamate-main-<커밋>.apk로 배포 중 (현재 6e2807c)'는 확인되나, 바탕화면 검색 결과 APK는 Campus-On.apk(7월 15일 생성) 1건뿐이고 dongamate-main-* 파일은 없다. 다만 '6e2807c가 HEAD보다 9커밋 뒤'라는 서술은 부정확하다 — `git rev-list --count 6e2807c..HEAD`는 18을 반환하므로 실제 격차는 18커밋이며, 이는 지적의 방향을 강화한다. 단순 문서 최신화 이슈라 low가 맞다.

### [low] 02_app_architecture.md가 제거된 '하단 4탭' 구조를 그대로 기술

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_architecture.md:12`
- **내용**: plan.md 197행은 '하단 탭 4→3개(홈/지도/설정), 가이드 탭 제거'를 완료로 표시하고 실제 `app_shell.dart`도 홈·지도·설정 3개 destination만 만든다. 그러나 plan.md 144행이 현행 아키텍처 산출물로 지목하는 `02_app_architecture.md`는 12행에서 여전히 'StatefulShellRoute.indexedStack, 하단 4탭'이라고 적고 있으며, 이후 추가된 학식·학사일정 리포지토리와 `/home/guide` 이관도 반영돼 있지 않다(문서 내 '학식'·'academic' 검색 0건).
- **권고**: 아키텍처 문서의 탭 구조·라우트 트리·리포지토리 목록을 3탭 + 학식/학사일정 리포지토리 기준으로 갱신하라.
- **검증 노트**: _workspace/02_app_architecture.md 12행이 'go_router ^14.2.0 (StatefulShellRoute.indexedStack, 하단 4탭 + 탭별 스택)'로 남아 있고, 문서 내 '학식/academic/dining' 검색 결과는 0건임을 확인했다(plan.md 197행은 3탭 전환을 완료로 기록). 다만 이 문서는 1행 제목이 'App Architecture Document — Campus-On (Week 2)'로 2주차 시점 스냅샷임을 스스로 밝히고 있고, 13행에는 geolocator/LocationService가 이미 기술돼 있어 '완전히 방치된 문서'는 아니다. plan.md 144행이 이를 산출물로 지목하는 이상 갱신은 필요하나 low가 적정하다.

### [low] 시드 README가 academic_events를 '초기 시드 대상'으로 설명해 seed.mjs·plan과 모순

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/firestore_seed/README.md:24`
- **내용**: README 24행 표는 `academic_events`를 시드 컬렉션으로 나열하고 27행은 'academic_events / cafeterias는 ONE-TIME starters'라고 설명하지만, `seed.mjs`의 COLLECTIONS 상수에는 facilities·guide_items·building_floors·cafeterias만 있고 주석은 'academic_events is NOT uploaded at all'이라고 못박는다. plan.md 160행도 'academic_events는 관리자 시트 소유라 시드 대상에서 영구 제외'라고 적어 README만 틀린 상태다. 실제 `academic_events.seed.json`에는 샘플 14건이 들어 있어, README를 믿고 수동 업로드하면 관리자 소유 컬렉션에 샘플 일정이 섞일 수 있다.
- **권고**: README 표에서 academic_events 행을 '스키마 문서용, 업로드 안 함'으로 바로잡고 27행 문장도 cafeterias만 가리키도록 수정하라.
- **검증 노트**: tool/firestore_seed/README.md 24행 표에 `academic_events | academic_events.seed.json | immutable event id | never` 행이 있고 27행이 'academic_events / cafeterias are ONE-TIME starters'라고 적혀 있으나, seed.mjs 64~69행 COLLECTIONS에는 facilities·guide_items·building_floors·cafeterias만 있고 60~63행 주석이 'academic_events is NOT uploaded at all ... schema documentation only'라고 명시한다. plan.md 160행의 '영구 제외'와도 어긋나 README만 틀린 상태이며, academic_events.seed.json에 실제로 14건의 샘플이 들어 있어 수동 업로드 시 관리자 소유 컬렉션 오염 가능성도 실재한다.

### [low] firebase_options.dart 헤더 주석이 실값을 담고도 'PLACEHOLDER — NOT REAL CREDENTIALS'라고 선언

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/firebase_options.dart:1`
- **내용**: 파일 1행은 'PLACEHOLDER — NOT REAL CREDENTIALS', 16~18행은 '실수로 USE_FIRESTORE=true로 켜면 초기화에서 즉시 실패한다'고 적혀 있지만, 46~58행의 android/ios 옵션은 실제 프로젝트 `campus-f4748`의 appId·apiKey·번들 ID를 담고 있다. `firebase_init.dart` 38행 주석도 동일한 옛 서술을 반복한다. plan.md 164행·160행이 'Firebase 실연동 완료 / Firestore 모드로 실배포 가능 상태'라고 선언한 것과 어긋나, 문서만 보고 Firestore 모드가 불가능하다고 오판할 여지가 있다.
- **권고**: 두 파일의 주석을 '실 프로젝트 campus-f4748 설정이 커밋돼 있으며 google-services.json은 gitignore라 체크아웃마다 재발급 필요' 취지로 갱신하라.
- **검증 노트**: firebase_options.dart 1행 'PLACEHOLDER — NOT REAL CREDENTIALS'와 16~18행 '값들은 명백한 placeholder라 실수로 USE_FIRESTORE=true를 켜면 initializeApp에서 fail fast'라는 서술을 확인했으나, 46~58행 android/ios 옵션은 projectId `campus-f4748`, 실 appId(1:1051782345606:...), 실 apiKey, iosBundleId `io.github.ljw092601.campuson`로 모두 실값이다. firebase_init.dart 38행 주석도 '커밋된 firebase_options.dart는 placeholder'라고 같은 옛 서술을 반복한다. plan.md 160·164행의 'Firestore 모드로 실배포 가능 상태'와 어긋나 오판 여지가 있으나 런타임 동작에는 영향이 없어 low가 적절하다.

### [info] 앱 문의 이메일 주소가 현재 프로젝트 운영 계정과 다름

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/core/config/app_config.dart:32`
- **내용**: `AppConfig.contactEmail`은 `donga.campus.on@gmail.com`이고 설정 화면(`settings_info_screen.dart` 42·48행)의 '문의하기'가 이 주소로 메일을 연다. 이 세션의 프로젝트 계정은 `donga.campus.on2@gmail.com`으로 숫자 2가 붙어 있어, 둘 중 하나가 사용되지 않는 주소일 가능성이 있다. plan.md 151행은 '문의하기' 진입점 구현만 완료로 기록할 뿐 실제 수신 주소를 명시하지 않아 대조할 기준이 없다.
- **권고**: 수신 가능한 실제 주소를 확인해 `contactEmail`을 확정하고, 스토어 심사용 연락처와 함께 plan.md §8 스토어 준비 항목에 명시하라.
- **검증 노트**: app_config.dart 32행 `contactEmail = 'donga.campus.on@gmail.com'`이 확인되고, settings_info_screen.dart 40행 `_sendEmail(AppConfig.contactEmail)`·47행 SelectableText가 이 주소를 메일 앱 실행과 화면 표기에 함께 사용한다. 세션 프로젝트 계정 donga.campus.on2@gmail.com과 숫자 2 하나 차이라는 불일치는 사실이지만, 어느 쪽이 실제 수신 가능한 주소인지는 코드/문서만으로는 판정할 수 없다. 확인이 필요한 대조 항목이라는 점에서 info 수준이 적절하다.

## 2. 보안: 규칙·시크릿·플랫폼 설정 — Opus

**전반 평가**: 시크릿 관리는 전반적으로 양호하다. `env.json`, `android/app/google-services.json`, `tool/admin_sheets/.clasp.json`은 모두 로컬에 존재하지만 `git check-ignore`로 무시 상태가 확인되고, `git ls-files`에도 없으며 전체 59개 커밋 히스토리를 `--diff-filter=A`로 훑어도 이들 파일이 추가된 적이 없고 32자리 헥사(카카오 키 형태) 문자열도 전 커밋 블롭에서 검출되지 않았다. `firestore.rules`는 공개 6개 컬렉션(facilities/guide_items/building_floors/academic_events/cafeterias/dining_menus)에 read-only, write 전면 deny를 걸고 `admin_sync_runs`는 규칙에 아예 없어 말미의 `match /{document=**}` 기본 deny로 비공개가 유지된다 — 앱이 실제 접근하는 컬렉션(FirestorePaths)과도 정확히 일치한다. Apps Script 쪽은 문서 ID를 allowlist 매핑과 UUID 정규식으로만 만들어 시트 셀 값이 경로에 주입되지 않으며 서비스 계정 키도 심겨 있지 않다. 반면 안드로이드 빌드 설정(디버그 키 서명, 앱 전역 cleartext, allowBackup 미지정)과 `firebase_options.dart`의 "PLACEHOLDER" 주석-실제 키 불일치, `seed.mjs`의 serviceAccount.json fallback 잔존, `cloud-platform` OAuth 스코프가 개선 지점이다.

### [medium] release 빌드가 공개된 디버그 키스토어로 서명됨

- **분류**: 취약점 · **검증**: ✅ 검증 확정 (분석가 제시 high → 검증자 조정 medium)
- **위치**: `_workspace/02_app_code/android/app/build.gradle.kts:37`
- **내용**: buildTypes.release가 `signingConfig = signingConfigs.getByName("debug")`로 되어 있어 릴리스 APK/AAB가 안드로이드 SDK에 동봉된 공용 디버그 키스토어(비밀번호 android, 모든 개발 머신이 동일)로 서명된다. 이 개인키는 사실상 공개된 값이므로 배포된 APK를 제3자가 동일 서명으로 재패키징해 '정품 업데이트'로 위장할 수 있고, 서명 기반 권한·키해시 검증도 무의미해진다. 루트 .gitignore에 `**/android/key.properties`가 이미 예약돼 있는 것으로 보아 실제 릴리스 서명 설정은 아직 도입 전이다.
- **권고**: 업로드 키스토어를 생성해 `key.properties`(gitignore 유지)에서 읽는 release signingConfig를 추가하고, 디버그 서명으로 만든 산출물은 어떤 경로로도 배포하지 마라.
- **검증 노트**: android/app/build.gradle.kts 33~39행에서 buildTypes.release가 실제로 `signingConfig = signingConfigs.getByName("debug")`이며, 위에 Flutter 템플릿의 TODO 주석이 그대로 남아 있고 key.properties를 읽는 코드도 전혀 없어 릴리스 서명 설정이 미도입인 것도 사실이다. 다만 아직 스토어에 배포된 빌드가 없고(서명 관련 커밋·keystore 파일 부재) 이 값이 Flutter 신규 프로젝트 기본값이라 현재 시점에 악용 가능한 상태는 아니므로, 실제로는 '릴리스 차단 이슈'에 해당해 high보다 medium이 적정하다.

### [low] 안드로이드 앱 전역 cleartext HTTP 허용

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/android/app/src/main/AndroidManifest.xml:11`
- **내용**: `<application android:usesCleartextTraffic="true">`가 릴리스 포함 모든 빌드에 적용되어 앱의 모든 도메인에 대해 평문 HTTP 통신이 허용된다. 같은 목적(카카오 WebView의 `http://localhost` origin, kakao_init.dart의 baseUrl)에 대해 iOS는 `NSAppTransportSecurity > NSAllowsLocalNetworking`만 켜 로컬로 한정했는데 안드로이드만 전역 해제라 비대칭이다. 이 상태에서는 향후 실수로 http URL이 들어가도 차단되지 않고 중간자 공격에 노출된다.
- **권고**: `usesCleartextTraffic`를 제거하고 `network_security_config.xml`에 localhost/127.0.0.1 도메인만 `cleartextTrafficPermitted="true"`로 예외 처리하라.
- **검증 노트**: AndroidManifest.xml 11행에 `android:usesCleartextTraffic="true"`가 있고 android/ 전체에 network_security_config가 없어 전역 허용이 맞으며, iOS는 Info.plist 82~86행에 NSAppTransportSecurity > NSAllowsLocalNetworking만 두어 비대칭이라는 지적도 정확하다. 다만 lib/ 전체를 grep한 결과 http:// 문자열은 kakao_init.dart의 `http://localhost`(WebView origin) 뿐이라 현재 평문으로 나가는 원격 엔드포인트가 없어 실제 중간자 노출은 없고, 장래 실수에 대한 하드닝 격차이므로 low가 적정하다.

### [low] 카카오 JS 키가 APK/WebView에서 추출 가능하고 Referer 제한은 우회 가능

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/presentation/map/widgets/kakao_init.dart:13`
- **내용**: 키는 `String.fromEnvironment('KAKAO_JS_KEY')`(app_config.dart:19)로 주입되지만 dart-define 값은 컴파일 시 상수로 바이너리에 박히고, `AuthRepository.initialize(appKey: ..., baseUrl: 'http://localhost')`를 통해 WebView 페이지 안에서도 그대로 사용되므로 배포본에서 추출이 가능하다. 유일한 방어선인 카카오 콘솔 웹 플랫폼 도메인 제한이 `http://localhost`인데, README.md:57이 스스로 `curl -H "Referer: http://localhost"`로 200이 나오는 것을 정상 확인 절차로 제시할 만큼 이 Referer는 누구나 위조할 수 있어 사실상 제한 효과가 없다. 즉 키 유출 시 제3자의 쿼터 소진·과금 남용을 막을 장치가 없다.
- **권고**: 카카오 콘솔에서 쿼터·사용량 알림을 설정하고 키 회전 절차를 문서화하며, 가능하면 네이티브 앱 키(패키지명+키해시 제한) 사용이나 서버 프록시 경유로 전환을 검토하라.
- **검증 노트**: app_config.dart 19~20행의 `String.fromEnvironment('KAKAO_JS_KEY')`는 컴파일 타임 상수로 바이너리에 박히고, kakao_init.dart 13~16행이 그 값을 `AuthRepository.initialize(appKey: ..., baseUrl: 'http://localhost')`로 WebView에 넘기는 것, README.md 57행이 `curl -H "Referer: http://localhost"`를 자가진단으로 제시하는 것까지 모두 원문대로 확인된다. 그러나 JS 키는 웹/WebView 지도 연동에서 구조적으로 공개될 수밖에 없는 클라이언트 식별자이고, 유출 시 영향이 지도 쿼터 남용에 한정되며 서버 시크릿·사용자 데이터에는 닿지 않으므로 medium은 과대평가로 보인다.

### [low] firebase_options.dart에 실제 프로젝트 키가 커밋되어 있으나 '플레이스홀더'로 문서화됨

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/firebase_options.dart:47`
- **내용**: 파일 상단 주석은 "PLACEHOLDER — NOT REAL CREDENTIALS"라고 선언하고 firebase_init.dart:38도 "committed firebase_options.dart is a placeholder ... will fail fast"라고 하지만, 실제 값은 projectId `campus-f4748`, appId `1:1051782345606:...`, apiKey `AIzaSyB16Bfo...`/`AIzaSyARb5TT...`로 firebase.json·.firebaserc의 실제 프로젝트와 일치하는 진짜 설정이다. 같은 정보를 담은 `google-services.json`은 루트 .gitignore 36행에서 커밋 금지 대상인데 동일 키가 dart 파일로는 커밋돼 있어 시크릿 정책이 서로 어긋나며, "플레이스홀더라 빨리 실패한다"는 안전장치 설명도 더 이상 사실이 아니다.
- **권고**: 주석을 실제 상태에 맞게 고치고(또는 파일도 gitignore 대상으로 통일), GCP 콘솔에서 두 API 키에 Android 패키지명/iOS 번들ID 애플리케이션 제한과 API 제한을 걸어라.
- **검증 노트**: firebase_options.dart 1행이 "PLACEHOLDER — NOT REAL CREDENTIALS", 17~18행이 '빨리 실패한다'고 주장하지만 47~59행 값(projectId campus-f4748, appId 1:1051782345606:..., apiKey AIzaSyB16Bfo.../AIzaSyARb5TT...)이 firebase.json의 실제 프로젝트·appId와 정확히 일치하므로 주석이 사실과 다르다는 지적은 확인된다(firebase_init.dart 38행도 동일한 낡은 설명). 다만 같은 파일 11~13행이 이미 "Firebase app config is public by design; access is gated by firestore.rules"라고 밝히고 있고 이는 Firebase 공식 입장과 일치하므로, 이번 건의 실질은 시크릿 유출이 아니라 '오도하는 주석 + google-services.json 무시 정책과의 불일치'라 low가 적정하다.

### [low] seed.mjs에 serviceAccount.json 자격증명 fallback이 남아 있음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/firestore_seed/seed.mjs:38`
- **내용**: `if (existsSync(saPath))`이면 경고만 출력하고 `cert(JSON.parse(readFileSync(saPath)))`로 서비스 계정 키를 그대로 사용한다. 설계 문서 §7(_workspace/06_admin_data_pipeline.md:126)은 기존 키를 폐기하고 ADC로 전환하기로 확정했고 현재 해당 파일은 로컬에 존재하지 않지만, 경로에 파일 하나만 다시 놓이면 규칙을 우회하는 전체 DB 쓰기 권한 키 경로가 조용히 되살아난다. 경고가 실패로 이어지지 않아 실수를 막지 못한다.
- **권고**: fallback을 삭제해 ADC만 지원하거나, 최소한 명시적 `--service-account` 플래그 없이는 키 파일 발견 시 즉시 종료하도록 바꿔라.
- **검증 노트**: seed.mjs 37~44행이 실제로 `existsSync(saPath)`일 때 console.warn만 찍고 `cert(JSON.parse(readFileSync(saPath)))`로 초기화하며, 06_admin_data_pipeline.md 126행의 §7 확정안(기존 키 폐기 후 ADC 전환)과 어긋나는 경로가 남아 있는 것이 맞다. .gitignore 34행이 `**/serviceAccount.json`을 커밋 금지로 막고 있고 파일도 현재 없어 즉시 위험은 없으나, 경고가 실패로 이어지지 않는다는 지적 자체는 정확하며 low 등급도 적정하다.

### [low] Apps Script가 필요 이상으로 넓은 cloud-platform OAuth 스코프를 요구

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/appsscript.json:9`
- **내용**: 매니페스트가 `https://www.googleapis.com/auth/cloud-platform`을 선언하는데, Firestore.gs는 `ScriptApp.getOAuthToken()` 토큰으로 Firestore REST(documents GET/PATCH/:commit)만 호출한다. cloud-platform은 승인한 사용자의 GCP 리소스 전반에 대한 접근을 허용하므로, 스크립트를 실행하는 관리자마다 필요 범위를 크게 넘는 토큰이 발급된다. 설계 문서 §7(:125)도 '최소권한 custom role 검증'을 요구하고 있어 스코프 축소가 그 취지에 맞는다.
- **권고**: oauthScopes를 `https://www.googleapis.com/auth/datastore`로 좁혀 재배포하고, IAM은 설계대로 Cloud Datastore User만 관리자 그룹에 부여하라.
- **검증 노트**: appsscript.json 9행의 `cloud-platform` 선언과, Firestore.gs가 2·52·58행에서 `firestore.googleapis.com/v1/...`에만 `ScriptApp.getOAuthToken()`을 쓰는 점을 확인했다(다른 .gs 파일에도 추가 googleapis 호출 없음) — 따라서 `auth/datastore`로 축소 가능하다는 지적은 타당하다. 다만 tool/admin_sheets/README.md 20~21·80행이 '일반 시트 편집자에게 IAM 금지', '.gs 편집 권한을 전용 관리자/개발자로 제한'이라는 보완 통제를 이미 문서화하고 있어 실제 악용 경로가 좁으므로 medium보다 low가 맞다.

### [low] android:allowBackup 미지정으로 앱 데이터 자동 백업/추출 허용

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/android/app/src/main/AndroidManifest.xml:7`
- **내용**: application 태그에 `android:allowBackup`, `android:fullBackupContent`, `dataExtractionRules`가 모두 없어 안드로이드 기본값(백업 허용)이 적용된다. 현재 앱은 로그인이 없어 저장 데이터가 shared_preferences 설정과 Firestore 오프라인 캐시(firebase_init.dart의 persistenceEnabled: true) 수준이라 민감도는 낮지만, 캐시된 콘텐츠와 앱 상태가 클라우드 백업 및 기기 간 전송 대상이 된다.
- **권고**: application 태그에 `android:allowBackup="false"`를 명시하거나, 백업이 필요하면 Firestore 캐시 디렉터리를 제외하는 dataExtractionRules를 정의하라.
- **검증 노트**: AndroidManifest.xml 7~11행의 application 태그에 label/name/icon/usesCleartextTraffic만 있고 android/ 전체 grep에서 allowBackup·fullBackupContent·dataExtractionRules가 한 건도 나오지 않아 기본값(백업 허용)이 적용되는 것이 맞다. 로그인이 없어 저장 데이터가 shared_preferences와 firebase_init.dart 49~52행의 오프라인 캐시 수준이라는 완화 서술도 코드와 일치하므로 low 등급이 적정하다.

### [low] 보안 규칙 에뮬레이터 테스트가 없어 규칙 회귀를 검증할 수단이 없음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/firestore.rules:55`
- **내용**: 설계 문서 §7(_workspace/06_admin_data_pipeline.md:131)은 'rules emulator 테스트 추가'를 명시했으나 `firebase.json`에는 emulators 블록이 없고 test/ 디렉터리에도 규칙 테스트가 없다(academic_calendar_test.dart 등 6개 모두 앱 단위 테스트). 특히 `admin_sync_runs` 비공개는 명시 규칙이 아니라 말미의 `match /{document=**} { allow read, write: if false; }` 기본 deny에만 의존하므로, 누군가 상위에 넓은 match를 추가하면 감사 로그(작성자 이메일 포함)가 조용히 공개될 수 있다.
- **권고**: firebase.json에 firestore 에뮬레이터를 추가하고 @firebase/rules-unit-testing으로 공개 6개 컬렉션의 read 허용/write 거부와 admin_sync_runs read 거부를 검증하는 테스트를 CI에 넣어라.
- **검증 노트**: firebase.json에 emulators 키가 0건이고 test/ 6개 파일은 모두 Flutter 위젯·유닛 테스트(rules 문자열 매치도 guide_flow_test.dart의 안내문 텍스트일 뿐)여서 06_admin_data_pipeline.md 131행의 'rules emulator 테스트 추가'가 미이행인 것이 맞다. firestore.rules에 admin_sync_runs 전용 match가 없고 55~57행의 `match /{document=**} { allow read, write: if false; }`에만 의존하는 것도 사실이며, Firestore 규칙은 match 간 합집합(OR) 평가라 상위에 넓은 allow가 추가되면 기본 deny가 이를 막지 못한다는 지적도 기술적으로 정확하다. 다만 50~52행에 '공개 read 규칙을 추가하지 말라'는 경고 주석이 이미 있어 low가 적정하다.

## 3. 관리자 데이터 파이프라인 (Apps Script) — Opus

**전반 평가**: 전반적으로 §7 합의안의 핵심 골격(학사일정 full-replace 단일 atomic commit + 삭제 diff 확인, 학식 그룹 단위 덮어쓰기 + unpublished tombstone, ADC/키리스 OAuth, admin_sync_runs 감사로그, LockService)은 구현되어 있고, 컬렉션명·문서 ID를 allowlist로만 만든다는 원칙도 코드 구조상 지켜져 있다. 다만 검증 계층의 핵심인 `allowlisted_`가 `allowlist[label]`로 프로토타입 체인까지 조회하기 때문에 `constructor`/`toString`/`__proto__` 같은 값으로 allowlist를 우회할 수 있고, 그 결과 시트 값이 그대로 `dining_menus` 문서 ID와 `status`/`category` 필드에 들어가 §7의 "문서 ID는 시트 값이 아닌 allowlist 매핑으로만 생성" 원칙이 깨진다. §7이 명시한 "불변 event_id"는 코드로 강제되지 않고 열 숨김과 안내문에만 의존하며, 삭제 확인 다이얼로그가 UUID만 보여줘 안전장치로서 실질적 기능을 하지 못한다. 학식은 §7이 문서 단위 원자성을 요구했는데 구현은 모든 정상 그룹을 단일 commit으로 묶어, Firestore 오류 하나로 정상 그룹까지 전부 실패하며 ADMIN_GUIDE의 "다른 정상 그룹은 게시됩니다" 서술과도 어긋난다. 그 밖에 OAuth 스코프 과다(`cloud-platform`, `spreadsheets`), 스프레드시트 타임존 미고정으로 인한 날짜 하루 밀림 위험, 감사로그가 동기화 실행자와 같은 토큰으로 쓰이고 시작 레코드가 없어 무결성이 약한 점, 전송 계층의 재시도 부재가 주요 잔여 리스크다.

### [medium] allowlisted_의 프로토타입 체인 조회로 enum allowlist 우회 가능

- **분류**: 취약점 · **검증**: ✅ 검증 확정 (분석가 제시 high → 검증자 조정 medium)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Validation.gs:141`
- **내용**: `allowlisted_`는 `const mapped = allowlist[labelValue]`로 값을 찾는데, `ACADEMIC_CATEGORIES`/`CAFETERIAS`/`MEAL_TYPES`/`DINING_STATUSES`는 `Object.freeze`된 일반 객체 리터럴이라 `Object.prototype`을 상속한다. 따라서 셀에 `constructor`, `toString`, `valueOf`, `hasOwnProperty`, `__proto__` 등을 넣으면 상속 프로퍼티가 반환되어 `if (!mapped)`를 통과하고 검증이 성공한 것으로 처리된다. 예컨대 상태 열에 `toString`을 넣으면 `status`가 함수 객체가 되어 Sync.gs:115의 `group.status === 'open'` 비교가 모두 거짓이 되고, Firestore.gs:87의 fallback으로 `"function toString() { [native code] }"`가 `status` 필드에 그대로 게시된다. Setup.gs:72의 `setAllowInvalid(false)` 시트 검증은 붙여넣기·규칙 삭제·setup 이후 추가된 행에서는 적용되지 않으므로 스크립트 측 검증이 실질적 유일 방어선이다.
- **권고**: `Object.prototype.hasOwnProperty.call(allowlist, labelValue)`로 자기 소유 키인지 먼저 확인하거나 allowlist를 `Map`으로 바꾸고, 매핑 결과가 `typeof mapped === 'string'`이며 사전에 정의된 값 집합에 속하는지 추가로 단언하라.
- **검증 노트**: Validation.gs:143의 `allowlist[labelValue]`는 Object.freeze된 객체 리터럴에 대해서도 Object.prototype 상속 프로퍼티를 그대로 반환하므로 'toString'·'constructor'·'__proto__' 입력 시 mapped가 truthy가 되어 `if (!mapped)` 방어를 통과하는 것이 맞고, Firestore.gs:78-87의 encodeValue_는 function 타입을 어느 분기도 잡지 못해 마지막 `String(value)`로 떨어져 "function toString() { [native code] }"가 게시된다. Setup.gs:63-67이 학식 시트의 날짜·식당·식사·상태 열에만 목록 검증을 걸어두었고 붙여넣기로 규칙이 교체될 수 있다는 점도 사실이다. 다만 이 경로는 이미 신뢰된 시트 편집자가 JS 내부 프로퍼티명을 의도적으로 입력해야만 성립하고 경로 탈출·권한 상승은 없어 영향이 데이터 오염에 한정되므로 high보다는 medium이 적정하다.

### [medium] 우회된 allowlist 값이 dining_menus 문서 ID로 직접 유입됨 (§7 문서 ID 생성 원칙 위반)

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정 (분석가 제시 high → 검증자 조정 medium)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Validation.gs:68`
- **내용**: `const key = `${cafeteriaId}_${dateString}`;`는 그룹 키이자 그대로 Firestore 문서 ID(Sync.gs:111의 `group.id`)로 쓰인다. 정상 경로에서는 `cafeteriaId`가 CAFETERIAS의 값이라 안전하지만, 위 프로토타입 우회로 `cafeteriaId`가 임의 문자열(또는 `__proto__` 입력 시 `[object Object]`)이 되면 시트 셀 내용이 문서 ID에 그대로 들어간다. 이는 06_admin_data_pipeline.md §7 인증·보안 항목의 "문서 ID·컬렉션명은 시트 값이 아닌 allowlist 매핑으로만 생성"과 정면으로 어긋나며, 공개 read 컬렉션에 정리 불가능한 쓰레기 문서가 영구히 남는다(학식은 prune이 없어 삭제 경로가 없음).
- **권고**: 문서 ID를 만들기 직전에 `Object.values(CAFETERIAS).includes(cafeteriaId)`와 `/^[a-z0-9-]+_\d{4}-\d{2}-\d{2}$/` 형태의 최종 형식 검사를 두어, 매핑 단계가 뚫려도 ID 생성 단계에서 차단하라.
- **검증 노트**: Validation.gs:68의 key가 Sync.gs:111 `group.id`를 거쳐 Firestore.gs:6 documentName_의 문서 ID로 그대로 쓰이는 흐름은 확인되며, Sync.gs 학식 경로에는 deleteWrite_ 호출이 전혀 없고 seed.mjs:18-21도 admin 소유 컬렉션을 prune에서 제외하므로 '삭제 경로 없음'도 사실이다. 06_admin_data_pipeline.md:125의 문구도 인용대로다. 그러나 이 항목은 1번의 프로토타입 우회가 성립해야만 발생하는 파생 결과이고 정상 경로에서는 allowlist 값만 ID에 들어가므로 독립된 별개 결함이 아니며, 1번과 같은 등급(medium)으로 묶는 것이 맞다.

### [medium] event_id 불변성이 코드로 강제되지 않고 형식 검증도 헐거움

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정 (분석가 제시 high → 검증자 조정 medium)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Setup.gs:54`
- **내용**: §7은 "시트에 불변 event_id 숨김 열(최초 동기화 시 생성, 이후 불변)"을 요구하지만, `configureAcademicSheet_`는 `sheet.hideColumns(7)`로 숨기기만 하고 보호하지 않으며 `protectHeader_`(Setup.gs:38)는 1행만 보호한다. 편집자가 열을 다시 표시해 UUID를 바꾸면 원래 문서는 staleIds에 들어가 삭제되고 새 문서가 생성되는데, 이 정체성 교체는 어디에도 로그로 남지 않는다. 게다가 Validation.gs:24의 `/^[0-9a-f-]{36}$/i`는 8-4-4-4-12 구조를 검사하지 않아 하이픈 36개 같은 임의 문자열도 통과한다. 또한 UUID는 Validation.gs:16에서 검증 이전에 시트에 즉시 기록되므로, 검증 실패로 게시가 중단된 실행도 시트를 영구 변경한다.
- **권고**: setup 시 7열(2행 이하)에도 `protect()`를 걸어 동기화 실행 계정 외 편집을 막고, 정규식을 `/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i`로 강화하라.
- **검증 노트**: Setup.gs:54는 hideColumns(7)만 하고 protectHeader_(Setup.gs:38)는 `getRange(1, 1, 1, columnCount)`로 1행만 보호하므로 데이터 행의 event_id 열은 무보호가 맞고, Validation.gs:24의 `/^[0-9a-f-]{36}$/i`가 8-4-4-4-12 구조를 검사하지 않는 것도 사실이며, Validation.gs:14-17이 rowErrors 계산 전에 시트에 UUID를 기록하는 것도 확인된다. 다만 ID 교체가 곧바로 삭제로 이어지려면 Sync.gs:47의 확인 대화상자를 통과해야 하고 finishRun_은 deleteCount를 기록하므로 '어디에도 로그가 없다'는 서술은 과장이다(삭제된 ID 목록이 안 남는 것은 맞음). 숨김 열을 다시 표시해 편집해야 하는 조건까지 감안해 medium이 적정하다.

### [medium] 학사일정 삭제 확인 창이 UUID만 표시해 안전장치로 작동하지 않음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Sync.gs:69`
- **내용**: `confirmAcademicDeletes_`는 `staleIds.slice(0, 20).map(id => `• ${id}`)`로 문서 ID(UUID)만 나열한다. ADMIN_GUIDE.md:33은 관리자에게 "목록이 의도한 삭제인지 확인"하라고 지시하지만, 관리자는 UUID만 보고는 그것이 어떤 일정인지 알 수 없어 사실상 무조건 '예'를 누르게 된다. §7이 full-replace의 방어선으로 둔 "삭제 예정 diff를 관리자에게 확인받고"가 실질적으로 무력화되며, event_id 오염이나 시트 행 실수 삭제가 그대로 통과한다.
- **권고**: `listDocumentIds_` 대신 `title_ko`·`start` 필드까지 읽어와 삭제 목록에 "일정명 (시작일)" 형태로 표시하고, 삭제 건수가 전체의 일정 비율을 넘으면 별도 경고를 띄워라.
- **검증 노트**: Sync.gs:69가 `staleIds.slice(0, 20).map(id => \`• ${id}\`)`로 UUID만 나열하는 것이 맞고, ADMIN_GUIDE.md:33과 :80이 관리자에게 '목록/문서 ID를 확인'하라고 지시하는데 정작 일정명은 화면에 없다. 06_admin_data_pipeline.md:115의 '삭제 예정 diff를 관리자에게 확인받고'라는 방어선이 사실상 형식적으로 남는다는 지적은 타당하다. 게다가 Firestore.gs:16의 listDocumentIds_는 이미 문서 본문 전체를 받아온 뒤 title_ko를 버리고 있어(13번 참조) 제목 표시 비용이 0인데도 쓰지 않고 있다는 점에서 medium 유지가 적절하다.

### [medium] 감사로그가 동기화 실행자와 동일한 권한으로 기록되고 시작 레코드가 없음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Audit.gs:10`
- **내용**: `finishRun_`은 실행 종료 시점에만 `upsertDocument_(CONFIG.collections.syncRuns, run.id, record)`를 호출하며, 데이터 쓰기와 같은 `ScriptApp.getOAuthToken()`을 쓴다. firestore.rules는 REST+IAM 경로에 적용되지 않으므로(rules 파일 주석 및 README:22 참조) 동기화 실행자는 자신의 `admin_sync_runs` 문서를 PATCH·DELETE로 임의 수정·삭제할 수 있어 로그가 tamper-evident하지 않다. 더 심각한 것은 시작 레코드가 없다는 점으로, commit 성공 후 Sync.gs:121의 행별 `setRowResult_` 루프에서 6분 실행 한도에 걸리거나 브라우저가 닫히면 데이터는 게시된 채 감사 기록이 전혀 남지 않는다. Audit.gs:25-28은 기록 실패를 toast로만 알리고 진행시키므로 이 공백이 조용히 발생한다.
- **권고**: 락 획득 직후 `started` 상태 레코드를 먼저 쓰고 종료 시 갱신하는 2단계 기록으로 바꾸고, 감사로그는 별도 IAM(append-only 서비스) 또는 Cloud Logging 등 실행자 권한으로 지울 수 없는 경로로 분리하라.
- **검증 노트**: newRun_(Audit.gs:1-8)은 로컬 객체만 만들고 실제 쓰기는 finishRun_(Audit.gs:24)의 upsertDocument_ 한 번뿐이므로 시작 레코드 부재는 사실이며, firestore.rules:34-36 주석이 'REST API with IAM auth, which bypasses these rules'라고 명시해 rules가 방어가 되지 않는다는 전제도 확인된다. commit 성공 후 Sync.gs:121의 행별 setRowResult_ 루프에서 실행이 중단되면 데이터만 게시되고 감사 기록이 남지 않으며, Audit.gs:25-28이 실패를 toast로만 알리는 것도 맞다. 다만 §7(:130)은 run 기록만 요구하고 tamper-evidence는 요구하지 않으므로 변조 가능성은 계획 위반이 아닌 추가 하드닝 사항이다.

### [medium] OAuth 스코프 과다 (cloud-platform 및 전체 spreadsheets)

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/appsscript.json:9`
- **내용**: 매니페스트가 `https://www.googleapis.com/auth/cloud-platform`을 요구하는데, 이 토큰은 승인한 관리자 계정의 GCP 전체 API(GCS, BigQuery, IAM, Compute 등)에 접근 가능하다. Firestore REST v1은 훨씬 좁은 `https://www.googleapis.com/auth/datastore` 스코프를 지원하므로 이 범위는 불필요하게 넓다. 또한 스크립트는 `SpreadsheetApp.getActive()`/`getUi()`/`toast`만 사용하는 컨테이너 바운드 스크립트인데도 사용자의 모든 스프레드시트에 접근하는 `.../auth/spreadsheets`를 요구한다. §7이 "scope manifest 고정"과 최소권한 custom role을 요구한 취지에 비추어 스코프 자체도 최소화 대상이다.
- **권고**: `cloud-platform`을 `https://www.googleapis.com/auth/datastore`로, `spreadsheets`를 `https://www.googleapis.com/auth/spreadsheets.currentonly`로 교체하고 재승인 후 동작을 검증하라.
- **검증 노트**: appsscript.json:9에 `cloud-platform`이 그대로 들어있고, Firestore.gs의 호출은 v1 REST의 documents get/commit/patch뿐이라 훨씬 좁은 `auth/datastore`로 충분하다. 스크립트가 쓰는 시트 API는 SpreadsheetApp.getActive()/getUi()/toast와 Setup.gs의 보호 설정뿐이라 컨테이너 바운드용 `spreadsheets.currentonly`로 대체 가능한데도 전체 `auth/spreadsheets`를 요구하는 것도 사실이다. §7(:125)이 'scope manifest 고정'과 최소권한 custom role을 요구한 취지와 어긋나므로 medium 유지가 타당하다.

### [medium] 공백·타입 강제 변환으로 가격 검증과 빈 행 판정이 우회됨

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Validation.gs:88`
- **내용**: `blank_`(Validation.gs:157)는 `''`·null·undefined만 빈 값으로 보고 trim을 하지 않는다. 그 결과 가격 셀에 공백만 있으면 `blank_`가 false가 되고 `Number('   ')`가 0으로 강제 변환되어 `Number.isInteger(0) && 0 >= priceMin(0)` 조건을 통과, 가격 미입력이 '0원'으로 게시된다(같은 이유로 `Number(true)`는 1로 통과). 반대로 휴무/게시취소 행에서는 같은 공백이 Validation.gs:101의 `!blank_(v[4])`를 참으로 만들어 근거 없는 오류를 내며, `isBlankRow_`도 공백 행을 유효 행으로 취급해 학사일정에서는 UUID까지 발급한 뒤 전체 게시를 영구히 차단한다. 아울러 `requiredText_`와 메뉴 항목에는 길이·개수 상한이 없어 대용량 셀이 문서 크기 한도를 넘겨 commit 전체를 실패시킬 수 있다.
- **권고**: `blank_`를 문자열일 때 `String(value).trim() === ''`로 판정하도록 바꾸고, 가격은 `typeof v === 'number'`인 경우만 허용하며 제목·메뉴 항목에 글자 수와 항목 수 상한을 추가하라.
- **검증 노트**: blank_(Validation.gs:157)에 trim이 없고 Setup.gs의 configureDiningSheet_는 1·2·3·6열에만 목록/날짜 검증을 걸어 가격 열(5열)에는 아무 시트 검증이 없어, 공백만 든 셀이 Validation.gs:88의 `!blank_(v[4])`를 통과하고 Number('   ')가 0이 되어 Number.isInteger(0) && 0 >= priceMin(0) 조건을 그대로 만족하는 경로가 성립한다. 휴무/게시취소 행에서 같은 공백이 Validation.gs:101의 오탐을 만드는 것과 isBlankRow_가 공백 행을 유효 행으로 취급하는 것도 코드대로다. 다만 학사일정에서 '전체 게시를 영구히 차단'한다는 표현은 과장으로, 해당 행에 오류 메시지가 표시되므로 삭제·수정으로 즉시 해소된다.

### [low] 학식 동기화가 모든 정상 그룹을 단일 commit으로 묶어 그룹 격리가 깨짐

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Sync.gs:119`
- **내용**: §7은 학식의 원자성 단위를 "문서 1개를 원자적으로 덮어쓰기"로 정의했는데, 구현은 `commitWrites_(writes)` 한 번에 모든 validGroups를 넣고 실패 시 catch에서 전 그룹을 실패 처리한다(Sync.gs:123-127). 그 결과 Firestore 오류 하나로 검증을 통과한 정상 그룹까지 전부 게시되지 않아, ADMIN_GUIDE.md:59의 "다른 정상 그룹은 게시됩니다"라는 서술과 어긋난다. 또한 Sync.gs:108에서 그룹 수가 500을 넘으면 청킹 없이 예외를 던져 학기 단위 일괄 입력이 아예 불가능해진다.
- **권고**: 학식은 문서 단위 원자성만 필요하므로 writes를 500건 단위로 청크 커밋하고, 청크별 성공/실패를 그룹에 매핑해 부분 성공을 결과 열과 감사로그에 정확히 반영하라.
- **검증 노트**: Sync.gs:119-127이 전체 validGroups를 한 번의 commitWrites_로 보내고 실패 시 모든 행을 실패 표시 후 rethrow하는 것은 사실이다. 다만 §7(06_admin_data_pipeline.md:116)의 '문서 1개를 원자적으로 덮어쓰기'와 '그룹 내 한 행이라도 오류면 해당 문서 전체 실패'는 검증 단계의 격리를 뜻하고 코드는 Sync.gs:91-106에서 이를 지키고 있어 §7 위반이라기보다 Firestore 오류 시에만 드러나는 ADMIN_GUIDE.md:59와의 서술 불일치다. 또한 500 그룹 한도는 식당 3곳 기준 166일치로 ensureRows_(1000행) 시트에서 사실상 도달하지 않아 '학기 단위 입력 불가'는 과장이며, 실제 피해는 재시도로 회복 가능한 가용성 문제라 low가 적정하다.

### [low] 스프레드시트 타임존이 고정되지 않아 날짜가 하루 밀릴 수 있음

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Setup.gs:11`
- **내용**: §7 D5는 "날짜는 Asia/Seoul 고정 + yyyy-MM-dd 직접 직렬화"를 요구하고 Validation.gs:149는 `Utilities.formatDate(date, CONFIG.timeZone, 'yyyy-MM-dd')`로 서울 기준 포맷을 쓴다. 그러나 `getValues()`가 날짜 셀을 Date로 변환할 때 기준이 되는 것은 appsscript.json의 스크립트 타임존이 아니라 **스프레드시트 자체의 타임존**(파일 → 설정)이며, `setupAdminSheets`는 `ss.setSpreadsheetTimeZone`을 한 번도 호출하지 않는다. 스프레드시트가 예컨대 America/Los_Angeles로 생성되면 2026-08-10 셀이 현지 자정 Date가 되고 서울 기준 포맷 시 2026-08-11로 밀려, 학사일정 `start`/`end`와 학식 문서 ID(`..._YYYY-MM-DD`)가 모두 하루 어긋난다.
- **권고**: `setupAdminSheets`에서 `SpreadsheetApp.getActive().setSpreadsheetTimeZone(CONFIG.timeZone)`를 호출하고, 동기화 진입 시 스프레드시트 타임존이 `CONFIG.timeZone`과 다르면 게시를 중단하도록 가드를 추가하라.
- **검증 노트**: admin_sheets 전체에 setSpreadsheetTimeZone 호출이 없음을 grep으로 확인했고, §7(:129)이 Asia/Seoul 고정을 요구하는 것도 사실이라 '스프레드시트 타임존 미고정'이라는 지적 자체는 유효하다. 다만 제시된 예시는 방향이 틀렸다 — America/Los_Angeles(UTC-7) 자정은 KST로 같은 날 16:00이라 밀리지 않으며, 실제로 날짜가 어긋나는 것은 UTC+9보다 동쪽(호주·뉴질랜드 등) 타임존이고 그때도 하루 '앞'이 아니라 하루 '뒤로' 당겨진다. 관리자 계정이 한국 로케일로 시트를 만드는 기본 상황에서는 재현되지 않아 low가 적정하다.

### [low] 학사일정 read-then-write가 원자적이지 않고 락 범위가 스프레드시트 단위에 그침

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Sync.gs:44`
- **내용**: `listDocumentIds_`로 기존 ID를 읽고(Sync.gs:44) `commitWrites_`로 삭제를 포함해 커밋할 때까지(Sync.gs:58) precondition(`currentDocument.updateTime`)이 전혀 없어 전형적인 TOCTOU다. 보호 수단인 `LockService.getDocumentLock()`(Sync.gs:11)은 해당 스프레드시트 문서 범위이므로, 관리자가 시트를 '사본 만들기'로 복제해 동기화하면 서로 다른 락이 잡히고 복사본 기준으로 컬렉션 전체가 full-replace되어 원본 데이터가 삭제된다. 또한 `confirmAcademicDeletes_`의 `ui.alert`가 락을 쥔 채 무한정 대기하므로, 관리자가 응답하지 않으면 실행 한도까지 다른 관리자가 차단된다.
- **권고**: `getScriptLock()`으로 범위를 넓히고 Firestore에 동기화 소유권/세대 문서(예: `admin_sync_runs/_lease`)를 두어 read 시점 상태와 다르면 커밋을 거부하도록 하며, 삭제 확인 다이얼로그는 락 획득 이전 또는 락을 잠시 놓은 상태에서 받아라.
- **검증 노트**: Sync.gs:44의 listDocumentIds_와 Sync.gs:58의 commitWrites_ 사이에 currentDocument precondition이 전혀 없어 TOCTOU 구조인 것은 코드로 확인되고, LockService.getDocumentLock()이 문서 범위인 것도 맞다. 그러나 '사본 만들기' 시나리오는 검증하지 못했다 — 복사본은 새 Apps Script 프로젝트가 되어 GCP 프로젝트 연결과 Firestore API 활성화가 끊기므로 REST 호출이 성공한다는 보장이 없다. 또 tryLock(1000) 실패 시 다른 관리자는 안내 메시지만 받고 종료되며 alert 대기도 6분 실행 한도로 끝나므로, 실제 경합 창은 IAM을 가진 또 다른 관리자가 별도 도구로 동시에 쓰는 경우로 제한돼 low가 적정하다.

### [low] Firestore REST 클라이언트에 재시도·백오프가 없고 원문 오류가 시트·감사로그로 노출됨

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Firestore.gs:65`
- **내용**: `firestoreRequest_`는 2xx가 아니면 즉시 예외를 던지며 429/503/ABORTED 같은 일시적 오류에 대한 재시도나 지수 백오프가 없다. 500건짜리 단일 commit은 경합 시 ABORTED가 날 확률이 낮지 않은데, 이 경우 학사일정은 전체 게시가 통째로 실패하고 관리자는 ADMIN_GUIDE.md:74 지침에 따라 개발자에게 문의하는 것 외에 할 수 있는 일이 없다. 또한 `parsed.error.message` 원문이 Sync.gs:125를 통해 시트 셀과 `admin_sync_runs.errors`에 그대로 기록되어 프로젝트 ID·리소스 경로가 시트 열람자 전원에게 노출된다.
- **권고**: 429/5xx/ABORTED에 대해 `Utilities.sleep` 기반 지수 백오프 재시도(3회 정도)를 추가하고, 시트에는 요약 메시지와 run id만 쓰고 원문은 `console.error`로만 남겨라.
- **검증 노트**: Firestore.gs:65-68이 2xx가 아니면 곧바로 throw하고 429/503/ABORTED 재시도가 없는 것, Sync.gs:125와 Sync.gs:20을 통해 오류 원문이 시트 셀과 admin_sync_runs.errors로 흘러가는 것 모두 사실이다. 다만 정보 노출 주장은 약하다 — projectId 'campus-f4748'은 Config.gs와 android/app/google-services.json에 이미 들어 있는 공개 식별자이고 시트 열람자는 전용 관리자로 한정된다. ABORTED 확률 서술도 클라이언트 write가 rules로 전면 차단되고 LockService로 직렬화되는 환경에서는 근거가 약해, 재시도 부재라는 견고성 결함만 남는 low가 맞다.

### [low] listDocumentIds_가 필드 마스크 없이 문서 본문 전체를 내려받음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Firestore.gs:9`
- **내용**: `listDocumentIds_`는 ID만 필요한데도 `pageSize=300`으로 `documents` 목록을 요청해 각 문서의 모든 필드를 함께 받아온 뒤 `doc.name`에서 ID만 추출한다. 학사일정 문서가 수백 건으로 늘어나면 매 동기화마다 불필요한 페이로드와 읽기 비용이 발생하고, UrlFetch 응답 크기 및 Apps Script 6분 실행 한도에 대한 여유가 줄어든다. 이 호출은 학사일정 full-replace의 필수 선행 단계라 실패 시 게시 전체가 중단된다.
- **권고**: 쿼리에 `mask.fieldPaths=__name__`을 추가해 이름만 받아오도록 바꾸고, 페이지 크기를 API 상한에 맞춰 올려 왕복 횟수를 줄여라.
- **검증 노트**: Firestore.gs:9-19의 쿼리 파라미터는 pageSize와 showMissing뿐이고 mask.fieldPaths가 없어 각 문서의 전체 필드를 받은 뒤 doc.name에서 ID만 잘라내는 것이 맞으며, 이 호출이 Sync.gs:44에서 commit보다 앞서므로 실패 시 게시 전체가 중단되는 것도 사실이다. 학사일정 규모가 연 수백 건 수준이라 실무 영향은 크지 않아 low가 적정하다. 참고로 이미 받아오고 있는 본문을 활용하면 4번의 삭제 확인 창에 일정명을 추가 비용 없이 표시할 수 있어, 두 항목을 함께 고치는 편이 낫다.

### 검증에서 반박되어 제외된 항목

- **documentName_이 컬렉션·문서 ID를 검증·인코딩 없이 리소스 경로에 보간** (`_workspace/02_app_code/tool/admin_sheets/Firestore.gs:5`, 원심각도 medium) — 반박 근거: 핵심 논거인 '비대칭'은 오히려 올바른 API 사용이다 — upsertDocument_(Firestore.gs:44)는 URL 경로를 만들기 때문에 encodeURIComponent가 필요하지만, documentName_(Firestore.gs:6)이 만드는 값은 commit 본문의 리소스 name 필드라 인코딩하면 문서 ID에 %XX가 그대로 박히는 버그가 된다. 또 도달 가능한 악용도 없다 — 학사일정 ID는 Validation.gs:24 정규식에 '/'가 포함될 수 없고, 학식 ID는 프로토타입 우회로 오염돼도 "function ... { [native code] }"나 "[object Object]"처럼 슬래시 없는 문자열이라 경로 탈출이 성립하지 않는다. 신뢰 경계 방어를 추가하자는 하드닝 제안으로서만 의미가 있어 medium은 과하다.

## 4. 앱 데이터 계층 — Opus

**전반 평가**: 데이터 계층의 골격(도메인 인터페이스 → mock/Firestore 2중 구현 → 플래그 스왑 → Riverpod 프로바이더)은 매우 깔끔하게 분리돼 있고, 특히 지적받았던 cafeterias 세션 캐시의 빈 결과/에러 메모이즈 버그는 `??=` + `.then`/`.catchError` 리셋으로 정확히 고쳐져 있으며 `anyFirestoreEnabled` 초기화 게이트와 firestore.rules(전 컬렉션 클라이언트 write deny, admin_sync_runs 기본 deny)도 §7 합의대로 구현돼 있다. 다만 오프라인 처리의 핵심 전제가 취약하다 — 전체 전략이 `on FirebaseException` → `Source.cache` 폴백 하나에 걸려 있는데 컬렉션 `.get()`은 오프라인에서 예외 대신 (비어 있을 수 있는) 캐시 스냅샷을 돌려주고, lib 전체에서 `metadata.isFromCache`를 확인하는 코드가 한 줄도 없어 '오프라인'이 '검색 결과 없음'·'식단 미등록'으로 둔갑한다. 후자는 §7이 명시한 "캐시 부재와 미등록 구분" 요구와 정면으로 어긋나는 plan-mismatch다. 또한 malformed 문서 방어가 학사일정에만 있고 facilities/guide_items/dining_menus에는 없어 문서 1건이 화면 전체를 죽일 수 있으며, status 폴백이 누락 시 open·미지 값 시 closed로 떨어져 D1이 막으려던 오표기가 남아 있다. 비용 측면에서는 인덱스 추가 필요는 없으나 guide_items 18문서·207KB를 카운트/카테고리/검색이 각각 전량 재조회하는 구조가 낭비이고, academicYearOf의 기기 로컬 시간 의존과 3/1 경계 전환은 신학년도 미입력 시 화면을 통째로 비운다. 마지막으로 Firestore 리포지토리 5종에 대한 테스트가 전무해(fake_cloud_firestore 미의존) 위 로직 전부가 회귀 가드 없이 유지되고 있다.

### [medium] 오프라인/빈 캐시에서 컬렉션 조회가 에러 대신 빈 목록으로 귀결 → "검색 결과 없음"으로 오인 표시

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 high → 검증자 조정 medium)
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_facility_repository.dart:31`
- **내용**: 모든 Firestore 리포지토리의 오프라인 전략이 `on FirebaseException` → `Source.cache` 폴백 하나에 의존하는데, 컬렉션 `.get()`은 기본 source(serverAndCache)에서 오프라인일 때 예외를 던지지 않고 로컬 캐시를 그대로 반환한다(캐시가 비어 있으면 빈 스냅샷). 즉 첫 실행이 오프라인이면 `_loadAll()`이 예외 없이 빈 리스트를 반환하고, `facility_list_screen.dart:50-58`은 이를 `EmptyStateView(title: l.list_empty_noResult, actionLabel: 필터 초기화)`로 렌더한다 — 사용자에게는 '오프라인'이 아니라 '검색 결과 없음/필터 문제'로 보인다. 실제로 `grep -n "isFromCache|metadata" -r lib/` 결과 lib 전체에서 스냅샷 메타데이터를 확인하는 코드가 단 한 줄도 없어, 캐시 출처/신선도를 구분할 수단 자체가 없다.
- **권고**: `QuerySnapshot.metadata.isFromCache`(+`docs.isEmpty`)를 확인해 '오프라인·캐시 없음'을 별도 예외나 별도 상태로 승격시키고, 화면은 EmptyState 대신 오프라인 안내+재시도를 띄우도록 분기하라. 캐시에서 온 데이터에는 '오프라인·마지막 동기화' 배지를 붙이는 것도 함께 검토할 만하다.
- **검증 노트**: firestore_facility_repository.dart:31-40의 _loadAll()은 `on FirebaseException`에만 캐시 폴백을 걸고, 컬렉션 쿼리 `.get()`은 오프라인일 때 예외 없이 캐시 스냅샷(빈 경우 빈 목록)을 돌려주므로 에러 경로가 실행되지 않는 것이 맞다. facility_list_screen.dart:48-58이 빈 리스트를 `list_empty_noResult` + `common_resetFilter`로 렌더하는 것도 확인했고, lib 전체 grep에서 isFromCache/metadata/hasPendingWrites 사용이 0건이라 캐시 출처를 구분할 수단이 없다는 서술도 사실이다. 다만 이 경로는 USE_FIRESTORE 계열 플래그가 켜졌을 때만 활성화(기본 false, 현재 mock 모드)되고 데이터 손상이 아닌 오표기 수준이라 high보다는 medium이 적정하다.

### [medium] §7 합의 "캐시 부재와 미등록 구분"이 학식 메뉴 조회에서 구현되지 않음

- **분류**: plan 불일치 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_dining_repository.dart:77`
- **내용**: 설계 확정안 §7 앱(D3)은 "서버 실패 시 Source.cache fallback + 캐시 부재와 미등록 구분(`unpublished` UI 문구 별도)"을 요구한다. 그러나 `_menusFor()`는 서버 실패 시 `Source.cache` 결과를 빈 스냅샷이어도 그대로 반환하며, 주석 자체가 "An empty cache result is indistinguishable from 'nothing published for this date', and both render as `unpublished` — safe to return"라고 명시해 구분을 포기했다. 그 결과 서버 장애/오프라인 상태에서 세 식당 전부가 "오늘 식단이 아직 등록되지 않았어요"(`dining_unpublished`)로 표시되고, 에러 상태·재시도 버튼은 아예 뜨지 않는다. 관리자가 정상 등록해 둔 날에도 사용자에게는 미등록으로 보이는 오정보다.
- **권고**: 캐시 폴백 결과가 비어 있으면 `DataRepositoryException`을 던지거나 별도 '오프라인' 상태로 표현해 `unpublished`와 분리하고, 화면에서 재시도 경로를 노출하라.
- **검증 노트**: 06_admin_data_pipeline.md:121이 "서버 실패 시 Source.cache fallback + 캐시 부재와 미등록 구분(unpublished UI 문구 별도)"을 명시하는데, firestore_dining_repository.dart:74-81의 주석이 그 구분을 명시적으로 포기하고 빈 캐시 스냅샷을 그대로 반환한다. cafeteriaMenuFromDocs(firestore_paths.dart:80-83)가 menuData null이면 status='unpublished'로 만들고 dining_menu_screen.dart:204-210이 이를 `dining_unpublished`로 렌더하므로, 서버 실패·오프라인에서 전 식당이 '미등록'으로 보이고 에러/재시도 UI는 뜨지 않는다는 결과도 코드상 일치한다.

### [medium] facilities·guide_items·building_floors에는 문서 단위 malformed 방어가 없어 문서 1건이 화면 전체를 무너뜨림

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_facility_repository.dart:34`
- **내용**: `FirestoreAcademicCalendarRepository`만 문서별 try/catch로 malformed 문서를 스킵하고 로그를 남긴다(44-50행). 나머지 리포지토리는 `snap.docs.map(facilityFromDoc)` / `map(guideFromDoc)` 형태라 한 문서의 파싱 예외가 목록 전체를 실패시킨다. `Facility.fromJson`은 `(j['lat'] as num).toDouble()`(facility.dart:129)이라 `lat`이 없거나 문자열이면 TypeError, `Meal.fromJson`은 `s as String`(dining_menu.dart:32)이라 메뉴 항목에 숫자가 섞이면 TypeError가 나고, 학식 리포지토리에도 문서별 방어가 없다. 게다가 이 TypeError는 `on FirebaseException` 블록에 걸리지 않아 `DataRepositoryException`으로 감싸이지도 않은 채 그대로 UI까지 올라간다.
- **권고**: 학사일정과 동일하게 문서별 try/catch + debugPrint 스킵 패턴을 facilities/guide_items/building_floors/dining_menus 매핑에 적용하고, 파싱 예외도 `DataRepositoryException`으로 래핑하라.
- **검증 노트**: firestore_academic_calendar_repository.dart:43-50만 문서별 try/catch+debugPrint를 갖고, facility(34,46행)·guide(26,38행)·floor(23행)·dining 조인(getMenus 96-99행)은 방어가 없다. facility.dart:129 `(j['lat'] as num).toDouble()`, dining_menu.dart:32 `s as String` 캐스팅도 원문 그대로이며, TypeError는 `on FirebaseException`에 잡히지 않아 DataRepositoryException 래핑 없이 전파된다. 다만 UI는 AsyncValue.error로 받아 ErrorStateView를 띄우므로 크래시가 아닌 '목록 전체 실패'이고, facilities/guide_items는 시드 스크립트 소유·admin 컬렉션은 Apps Script 검증을 거치므로 현실적 유입 경로는 콘솔 수동 편집에 한정된다.

### [medium] 가이드/시설 전체 로드에 메모이즈가 없어 화면 이동·검색마다 컬렉션 전량 재조회

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_guide_repository.dart:23`
- **내용**: `FirestoreGuideRepository._loadAll()`은 호출마다 컬렉션 전체를 다시 `.get()` 하며, `getAllItems`·`getByCategory`·`search`가 각각 독립적으로 이를 호출한다. 프로바이더도 서로 재사용하지 않아(`guideItemsByCategoryProvider`는 `allGuideItemsProvider`가 아니라 `repo.getByCategory`를 호출) S5 카테고리 카운트 → S6 카테고리 진입 → S8 검색이 각각 전량 로드를 유발한다. 시드 기준 `guide_items`는 18문서·약 207KB(문서 평균 11.5KB, 최대 26.9KB)이고 검색은 title_ko/title_en만 쓰는데도 sections·links까지 전부 내려받는다. `facilities`(48문서)도 `getAll`/`getByIds`/`search`가 매번 `_loadAll()`을 재실행한다. 같은 레포 안의 학식 리포지토리는 정적 컬렉션을 `_cafeteriasFuture`로 메모이즈하고 있어 정책도 일관되지 않다.
- **권고**: 두 리포지토리에도 cafeterias와 같은 세션 캐시(명시적 무효화 포함)를 넣거나, 최소한 프로바이더 레벨에서 `allGuideItemsProvider`/`allFacilitiesProvider` 결과를 재사용해 카테고리·검색을 파생시켜라.
- **검증 노트**: firestore_guide_repository.dart:23-53,73-82와 facility 리포지토리 모두 호출마다 컬렉션 전체를 다시 get 하고, guideItemsByCategoryProvider(guide_providers.dart:25-28)가 allGuideItemsProvider를 재사용하지 않는 것도 사실이며, guide_items 시드 실측치도 18문서·207,322자·평균 11,518·최대 26,875로 발견사항 수치와 정확히 일치한다. 다만 프로바이더가 autoDispose가 아니어서 Riverpod가 결과를 앱 수명 동안 캐시하므로 '화면 이동마다'는 과장이고, 실제 반복 비용은 searchResultsProvider(search_provider.dart:24-40)가 디바운스된 질의어마다 재실행되며 facilities+guide_items 전량을 매번 내려받는 검색 경로에 집중된다.

### [medium] Firestore 리포지토리 5종에 대한 테스트가 전무 — 캐시·메모이즈 회귀 가드 없음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/pubspec.yaml:52`
- **내용**: `test/` 아래 6개 파일(`dining_repository_test.dart`, `academic_calendar_test.dart`, `floor_guide_test.dart`, `guide_flow_test.dart` 등)은 모두 mock 리포지토리와 엔티티 `fromJson`만 검증하고, `Firestore*Repository`를 인스턴스화하는 테스트는 하나도 없다. `pubspec.yaml`의 dev_dependencies에도 `fake_cloud_firestore`류 의존이 없어(53-60행) Firestore 경로를 테스트할 수단 자체가 갖춰져 있지 않다. 결과적으로 이번 감사 대상인 `_cafeteriasFuture`의 빈 결과/에러 리셋, `Source.cache` 폴백 분기, malformed 문서 스킵, cafeteria×menu 조인과 status 전파가 전부 회귀 가드 없이 방치돼 있다 — 특히 메모이즈 리셋은 마이크로태스크 실행 순서에 의존하는 미묘한 코드라 리팩터링 한 번에 조용히 깨질 수 있다.
- **권고**: `fake_cloud_firestore`를 dev_dependency로 추가해 빈 컬렉션→재시도, 서버 실패→캐시 폴백, malformed 문서 스킵, status 3종 전파를 최소 단위 테스트로 고정하라.
- **검증 노트**: test/ 아래 파일은 academic_calendar_test, classroom_providers_test, dining_repository_test, floor_guide_test, guide_flow_test, smoke_test 6개뿐이고, 전체 grep에서 `Firestore`는 주석 3곳에만 등장할 뿐 Firestore*Repository를 인스턴스화하는 테스트가 없다. pubspec.yaml:52-61 dev_dependencies에도 fake_cloud_firestore류 의존이 없어 테스트 수단 자체가 부재하다는 서술도 사실이다. 따라서 _cafeteriasFuture 리셋(마이크로태스크 순서 의존), Source.cache 분기, malformed 스킵, cafeteria×menu 조인·status 전파가 회귀 가드 없이 남아 있다는 결론이 성립한다.

### [low] cafeterias 세션 캐시에 무효화 경로가 없어 재시도·복구가 불가능

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_dining_repository.dart:38`
- **내용**: `_cafeteriasFuture`의 빈 결과/에러 메모이즈 버그는 제대로 고쳐져 있다 — `??=`는 파생 future를 동기적으로 저장하고, `.then`의 `if (docs.isEmpty) _cafeteriasFuture = null`과 `.catchError`의 리셋이 이후 마이크로태스크에서 실행되므로 실패·빈 결과는 다음 호출에 재시도된다. 문제는 '성공'으로 판정된 경우다. `_loadCafeterias()`는 서버 실패 시 `Source.cache` 문서가 비어 있지 않으면 성공으로 반환하므로(58-59행), 오프라인에서 한 번 로드하면 그 캐시 스냅샷이 세션 내내 고정된다. `diningRepositoryProvider`는 autoDispose가 아닌 `Provider`라 인스턴스가 앱 수명 동안 유지되고, 화면의 재시도는 `ref.invalidate(diningMenusProvider(_date))`뿐이라 cafeterias는 절대 다시 조회되지 않는다 — 관리자가 운영시간/식당명을 바꿔도 앱 재시작 전에는 반영되지 않는다.
- **권고**: `invalidateCafeterias()` 같은 명시적 무효화 API(또는 TTL)를 추가해 재시도/당겨서 새로고침 시 호출하고, 캐시 폴백으로 성공한 로드는 메모이즈 대상에서 제외하라.
- **검증 노트**: firestore_dining_repository.dart:38-48의 `??=` + then/catchError 리셋이 실패·빈 결과를 재시도한다는 반박부까지 코드와 일치하고, 51-65행에서 캐시 문서가 비어있지 않으면 성공 반환하는 것도 맞다. repository_providers.dart:63은 autoDispose 없는 Provider이고, lib 전체 invalidate 호출 12건 중 diningRepositoryProvider를 무효화하는 곳이 하나도 없어 세션 내 갱신 불가라는 결론도 확인된다. 다만 설계 문서 §7(120행)이 "cafeterias는 provider 캐시로 날짜마다 재조회하지 않음"을 의도적으로 요구했고 대상이 거의 변하지 않는 정적 컬렉션이므로 medium은 과하고 low가 적정하다.

### [low] 학식 status 폴백이 D1 취지와 어긋남 — 누락 시 open, 미지 값이면 '휴무'로 오표기

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_paths.dart:87`
- **내용**: `cafeteriaMenuFromDocs`는 메뉴 문서가 있을 때 `'status': menuData['status'] ?? 'open'`으로 기본값을 open으로 잡고, `DiningAvailability.fromId`는 미지 문자열에 null을 반환해 `CafeteriaMenu.status`가 레거시 규칙(`meals.isEmpty ? closed : open`)으로 떨어진다(dining_menu.dart:49-93). 두 가지 구멍이 생긴다: (1) status 필드가 없고 meals도 비어 있으면 open+빈 meals가 되어 `dining_menu_screen.dart:218-219`의 `else for (final meal in menu.meals)` 분기가 아무것도 렌더하지 않아 카드 본문이 통째로 빈 채 표시되고, (2) status에 오타/미지 값이 들어오면 빈 meals와 결합해 "오늘은 운영하지 않아요"로 표기된다 — D1이 막으려던 바로 그 오표기다. Apps Script 쪽 allowlist(`Config.gs:42-45`)와 `open`+무메뉴 금지 검증(`Validation.gs:117`)이 현재는 이를 막아주지만, 앱 자체 방어는 없고 콘솔 수동 수정·시드 경로는 검증을 우회한다.
- **권고**: status 누락이나 미지 값은 `open`이 아니라 `unpublished`로 폴백시키고, 'open인데 meals가 비어 있음'을 별도 상태로 잡아 화면이 빈 카드 대신 안내 문구를 내도록 하라.
- **검증 노트**: firestore_paths.dart:87 `menuData['status'] ?? 'open'`, dining_menu.dart:49-55(미지 값 → null) 및 91-93(레거시 폴백 meals.isEmpty ? closed : open) 모두 원문대로이며, dining_menu_screen.dart:218-219의 else 분기가 빈 meals에서 아무것도 렌더하지 않아 카드 본문이 비는 것도 코드상 성립한다. 다만 Config.gs:42-45 allowlist, Validation.gs:117의 open+무메뉴 금지, Sync.gs:114-115가 status를 항상 쓰는 구조라 정상 파이프라인으로는 재현 불가하고, dining_menus는 시드 대상도 아니어서(seed.mjs 65-68행) 유입 경로가 콘솔 수동 편집뿐이므로 low가 적정하다.

### [low] academicYearOf가 기기 로컬 시간에 의존하고 3/1 경계에서 화면이 통째로 비어버릴 수 있음

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/domain/entities/academic_event.dart:40`
- **내용**: `academicYearOf(DateTime d) => d.month >= 3 ? d.year : d.year - 1`이고, 화면은 `AcademicEvent.academicYearOf(DateTime.now())`로 현재 학년도를 정한 뒤 다른 학년도 이벤트를 전부 필터링한다(`academic_calendar_screen.dart:38-47`). 이벤트 쪽 날짜는 `"2026-03-01"` 문자열을 `DateTime.parse`로 읽어 타임존 영향이 없지만, `DateTime.now()`는 기기 로컬 시간이라 기기 tz를 KST가 아닌 값(예: 본국 시간대로 맞춰 둔 유학생 폰)으로 두면 3/1 KST 당일에도 전년도 학년도가 선택될 수 있다. 더 큰 문제는 경계 동작 자체다 — 3/1 0시가 지나면 화면이 즉시 신학년도로 전환되는데, 관리자가 신학년도 일정을 아직 시트에 넣지 않았으면 "올해 등록된 학사일정이 아직 없어요"(`calendar_empty`)만 남고 방금까지 보이던 직전 학년도 일정이 통째로 사라진다. 연도 전환 중이라는 설명도, 연도 전환 UI도 없다.
- **권고**: 학년도 계산 기준 시각을 `Asia/Seoul` 고정(동기화 정책과 동일)으로 바꾸고, 현재 학년도 이벤트가 0건이면 직전 학년도로 폴백하거나 '신학년도 일정 준비 중' 문구로 구분해 빈 화면을 피하라.
- **검증 노트**: academic_event.dart:40의 정의와 academic_calendar_screen.dart:38-51(현재 학년도 외 이벤트 스킵, months 비면 calendar_empty)은 원문대로이고, DateTime.now()가 기기 로컬 tz라 3/1 경계 판정이 기기 설정에 좌우되는 것도 맞다. 다만 화면 주석 13-17행이 "다른 학년도 행은 존재하지만 학생에게 무의미하므로 필터링, 연도 스위처는 의도적으로 없음"이라고 명시한 설계 결정이고, 설계 §7상 관리자가 신학년도 일정을 미리 등록하는 전제이며 노출 구간이 연 1회 짧아 medium보다 low가 적정하다.

### [low] orderBy('start')가 start 없는 문서를 조용히 누락시키고, 학사일정은 연도 필터 없이 전량 조회

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_academic_calendar_repository.dart:25`
- **내용**: 쿼리가 `collection(academicEvents).orderBy('start')`인데, Firestore는 정렬 필드가 없는 문서를 결과에서 제외한다. 즉 `start` 필드가 누락된 문서는 44-50행의 malformed 스킵 로그조차 남기지 않고 사라져, 관리자가 등록했다고 믿는 일정이 앱에서 이유 없이 안 보이는 상황을 디버깅할 단서가 없다. 단일 필드 정렬이라 복합 인덱스는 필요 없지만(학식의 `where('date', isEqualTo:)`도 마찬가지), 화면은 현재 학년도만 쓰면서도 쿼리는 전 연도를 내려받는다 — 설계 §7이 과거 문서 보존·TTL 정리 후순위를 명시했으므로 컬렉션은 해마다 누적된다.
- **권고**: `start`가 문자열 `yyyy-MM-dd`인 점을 이용해 `where('start', isGreaterThanOrEqualTo: '<학년도>-03-01')` 범위 조건으로 학년도 단위 조회로 좁히고, 결과 건수와 스킵 건수를 함께 로깅해 누락을 관측 가능하게 하라.
- **검증 노트**: firestore_academic_calendar_repository.dart:25가 `orderBy('start')`뿐이고 Firestore가 정렬 필드 없는 문서를 결과에서 제외하는 것은 규격 동작이라, 44-50행의 malformed 스킵 로그에도 걸리지 않는다는 지적이 맞다. 화면(academic_calendar_screen.dart:38-47)이 현재 학년도만 쓰면서 쿼리에는 연도 조건이 없는 것도 확인했고, 설계 문서 116행이 과거 문서 보존·TTL 후순위를 명시해 누적 전제도 사실이다. 다만 Apps Script가 시작일 없는 행을 검증에서 걸러 full-replace로만 게시하므로 실제 유입 가능성은 낮고, low 등급은 적절하다.

### [low] family 프로바이더가 autoDispose가 아니어서 캐시가 무한 누적되고 재방문 시 갱신되지 않음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/providers/dining_providers.dart:8`
- **내용**: `diningMenusProvider`(날짜 키), `facilityByIdProvider`, `buildingFloorsProvider`, `guideByIdProvider`, `classroomEntriesProvider` 모두 `.autoDispose` 없는 `FutureProvider.family`다. 학식 화면의 날짜 이동은 하루 넘길 때마다 새 family 엔트리를 만들고, 이 엔트리들은 화면을 떠나도 ProviderContainer에 그대로 남아 앱 수명 동안 쌓인다. 동시에 한 번 조회한 날짜/시설/가이드는 다시 방문해도 캐시된 값이 그대로 나와, 관리자가 그 사이 Firestore를 갱신해도 명시적 `ref.invalidate` 없이는 새 데이터를 볼 수 없다.
- **권고**: id/날짜 기반 family에는 `.autoDispose`(필요하면 `ref.keepAlive()`로 선택적 유지)를 적용해 캐시 수명을 화면 수명에 묶어라.
- **검증 노트**: dining_providers.dart:8-11, facility_providers.dart:13-16과 49-52, guide_providers.dart:31-34, classroom_providers.dart:31-32 모두 `.autoDispose`가 없는 FutureProvider.family임을 확인했고, 화면들의 갱신 수단은 명시적 ref.invalidate(재시도 버튼·facility_list RefreshIndicator)뿐이다. 다만 각 엔트리가 담는 것은 소형 엔티티 리스트라 실질 메모리 압박은 작고, 실제 영향은 '앱 재시작 전까지 갱신 안 됨'이라는 신선도 문제에 가깝다 — low 등급이 적정하다.

### [low] firebase_options.dart가 실 프로젝트 설정인데 주석·초기화 문서는 여전히 "placeholder라 fail fast"라고 안내

- **분류**: 약점 · **검증**: ✅ 검증 확정 (분석가 제시 medium → 검증자 조정 low)
- **위치**: `_workspace/02_app_code/lib/firebase_options.dart:1`
- **내용**: 파일 헤더는 "PLACEHOLDER — NOT REAL CREDENTIALS"이고 16-18행은 "값이 명백한 placeholder라 실수로 `--dart-define=USE_FIRESTORE=true`로 실행해도 `Firebase.initializeApp`에서 즉시 실패한다"고 설명하지만, 실제 44-58행에는 `projectId: 'campus-f4748'`의 실 android/ios 옵션이 들어 있다. `firebase_init.dart:36-39`의 주석도 같은 낡은 전제를 반복한다. 따라서 플래그를 켠 개발/QA 실행은 fail fast 대신 곧바로 운영 Firestore에 붙으며, 코드 주석은 반대로 안내한다(문서화된 안전장치가 실제로는 없음). Firebase 앱 설정 자체는 공개 정보이므로 노출 문제는 아니지만, 개발용 프로젝트 분리가 없다는 점이 함께 드러난다.
- **권고**: 주석을 현재 상태에 맞게 갱신하고, dev/prod 프로젝트를 분리하거나 최소한 실행 시 어떤 projectId에 접속 중인지 로그로 남겨 운영 데이터에 붙는 실행을 인지할 수 있게 하라.
- **검증 노트**: firebase_options.dart:1의 "PLACEHOLDER — NOT REAL CREDENTIALS"와 16-18행의 fail-fast 설명이 46-60행의 실제 campus-f4748 android/ios 옵션과 정면으로 모순되고, firebase_init.dart:36-39도 같은 낡은 전제를 반복하는 것을 확인했다. 즉 문서화된 안전장치는 실재하지 않는다. 다만 firestore.rules가 모든 컬렉션에 대해 클라이언트 write를 차단(allow write: if false)하므로 실수 실행의 영향은 운영 데이터 읽기/과금에 그치고, 결함 자체는 낡은 주석 정리와 dev 프로젝트 분리 과제라 low가 적정하다.

## 5. UI·다국어·접근성 — Sonnet

**전반 평가**: ARB 키(app_ko.arb/app_en.arb) 163개는 한/영 완전 일치했고 lib/presentation 전역에 하드코딩된 한국어/영어 UI 문자열도 없었다(주석 제외). mock 전용 "예시" 배너(dining/calendar)는 useFirestoreDining/useFirestoreCalendar 플래그로 정확히 게이팅되어 있고, 학사일정 화면은 academicYearOf(3월 기준)로 당해 학년도만 필터링해 정책이 올바르게 반영되어 있다. 지도 화면의 3개 FAB(myLocation/zoomIn/zoomOut)는 heroTag가 모두 달라 충돌이 없고, 난이도 표시 등 일부 위젯은 Semantics/ExcludeSemantics를 적절히 사용한 모범 사례였다. 다만 최근(오늘자) 마커 PNG 교체와 칩 팔레트 동기화 과정에서 필터 칩 선택 시 흰 글자와 5개 시설 카테고리 색의 대비가 WCAG AA 기준(4.5:1)에 못 미치는 문제를 코드상 색상값으로 직접 계산해 확인했다. 그 외 Firestore 미시딩 시 학식 화면의 빈 상태 미처리, 즐겨찾기 화면의 에러/빈 상태 문구 혼동, 캠퍼스 선택기·지도 핀의 터치 타깃 축소, 언어 토글의 접근성 라벨 부재, 강의실 검색 화면의 재시도 버튼 누락 등 7건의 약점을 확인했다.

### [medium] 필터 칩 선택 상태 흰 글자, 5개 시설 카테고리 색과 WCAG AA 대비 미달

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/core/theme/category_colors.dart:46`
- **내용**: CategoryColors.standard의 시설 카테고리 색(building 0x7F77DD, classroom 0x378ADD, dining 0xD85A30, library 0x1D9E75, amenity 0xBA7517)을 흰색(scheme.onPrimary)과 WCAG 공식으로 계산하면 각각 대비비 3.76/3.59/3.87/3.39/3.72로, 일반 굵기 13px 텍스트에 필요한 4.5:1 기준에 모두 미달한다(etc만 6.49로 통과). category_chip.dart의 CategoryChip은 selected일 때 labelStyle color를 scheme.onPrimary(라이트 모드 흰색)로 고정하고 selectedColor를 이 카테고리 색으로 쓰므로, S2/S3의 CategoryFilterBar에서 이 5개 카테고리 칩을 선택하면 실제로 대비 미달 상태가 렌더링된다. 마커 PNG 6종을 오늘 새로 교체하면서(커밋 b4279d5) 칩 팔레트를 마커 색과 동기화했다는 주석이 있는데, 이때 텍스트 대비 검증이 빠진 것으로 보인다.
- **권고**: 칩이 selected일 때는 onPrimary 고정 대신 각 카테고리 색 배경에 맞는 전용 온컬러(어둡게 조정한 색 또는 다크 텍스트)를 계산해 쓰거나, 배경색 자체를 4.5:1을 만족하도록 더 어둡게 조정하라.
- **검증 노트**: category_colors.dart:46-52의 실제 HEX 값과 app_theme.dart:13의 onPrimary(0xFFFFFFFF)로 WCAG 공식을 직접 계산한 결과 building 3.76, classroom 3.59, dining 3.87, library 3.39, amenity 3.72, etc 6.49로 보고서 수치와 정확히 일치했다. category_chip.dart:29,34-37에서 selected일 때 labelStyle color와 avatar icon color가 모두 scheme.onPrimary로 고정되고 selectedColor가 카테고리색이며, category_filter_bar.dart:33-52에서 이 칩이 map_screen/facility_list_screen(S2/S3)에 그대로 쓰이는 것도 확인했다.

### [medium] Firestore 모드에서 cafeterias 컬렉션 미시딩 시 학식 화면이 빈 화면으로 남음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/dining/dining_menu_screen.dart:74`
- **내용**: FirestoreDiningRepository.getMenus는 cafeterias 컬렉션이 비어 있으면(관리자 시딩 전) 빈 리스트를 반환한다(firestore_dining_repository.dart 84-107). DiningMenuScreen은 useFirestoreDining이 true면 예시 배너를 정상적으로 숨기지만, menus가 빈 리스트일 때의 EmptyStateView 처리가 없어 for 루프가 아무것도 렌더링하지 않고 날짜 전환 헤더만 남은 빈 스크롤 영역이 표시된다. mock 모드는 항상 고정 카페테리아 목록이 있어 이 경로가 드러나지 않는다.
- **권고**: menus.isEmpty인 경우 EmptyStateView(예: '등록된 학식 정보가 없어요')를 분기 추가해 Firestore 시딩 전 상태를 안내하라.
- **검증 노트**: firestore_dining_repository.dart:38-48에서 cafeterias가 비면 빈 리스트를 반환하며 캐시도 재시도하도록 초기화만 할 뿐 예외를 던지지 않는다. dining_menu_screen.dart:66-88의 data 분기는 useFirestoreDining이 true면 배너를 숨기고(79행) menus가 빈 리스트일 때 for 루프가 아무것도 렌더링하지 않아 EmptyStateView 등 대체 UI가 전혀 없음을 확인했다.

### [low] 즐겨찾기 로드 실패가 '즐겨찾기 없음' 문구로 잘못 표시됨

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/settings/favorites_screen.dart:72`
- **내용**: favoriteFacilitiesProvider/favoriteGuideItemsProvider의 error 분기가 EmptyStateView(title: l.favorites_empty_facility / favorites_empty_guide)를 그대로 재사용한다. 해당 ARB 문자열은 '저장한 시설이 없어요' / '저장한 가이드가 없어요'로(app_ko.arb 186-187), 실제로는 SharedPreferences 읽기 실패 같은 오류 상황인데도 사용자에게는 단순히 저장한 항목이 없다는 메시지로 보여 원인 파악과 재시도를 막는다.
- **권고**: error 분기는 ErrorStateView(전용 에러 문구 + 재시도 버튼)로 분리해 empty 상태와 구분하라.
- **검증 노트**: favorites_screen.dart:72-73, 116-117에서 error 분기가 EmptyStateView(title: l.favorites_empty_facility/guide)를 그대로 쓰고, app_ko.arb:186-187 문자열이 '저장한 시설이 없어요.'/'저장한 가이드가 없어요.'임을 확인했다(정상 빈 상태는 title에 favorites_empty_title '아직 즐겨찾기가 없어요'를 쓰는 것과 대비). 또한 favorites_provider.dart:49-60을 보면 이 에러는 로컬 SharedPreferences뿐 아니라 allFacilitiesProvider(원격일 수 있음)의 에러도 whenData를 통해 전파되므로, 화면 주석의 '로컬이라 에러 없음' 전제보다 실제 도달 가능성이 더 높다.

### [low] 지도 캠퍼스 선택 세그먼트가 터치 타깃을 명시적으로 축소

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/map/widgets/campus_selector.dart:31`
- **내용**: CampusSelector의 SegmentedButton 스타일에 visualDensity: VisualDensity.compact와 tapTargetSize: MaterialTapTargetSize.shrinkWrap을 함께 지정해, Material 기본 최소 탭 영역 확장을 의도적으로 해제했다. 이 위젯은 S2 지도 화면 최상단에서 승학/구덕/부민 3개 캠퍼스를 전환하는 유일한 컨트롤이라 터치 타깃이 작아지면 손가락 조작 시 오탭 가능성이 커진다.
- **권고**: shrinkWrap 대신 기본 tapTargetSize(padded)를 사용하거나, 최소 44dp 높이를 보장하는 커스텀 패딩으로 대체하라.
- **검증 노트**: campus_selector.dart:31-34에서 ButtonStyle에 visualDensity: VisualDensity.compact와 tapTargetSize: MaterialTapTargetSize.shrinkWrap이 함께 지정되어 있음을 그대로 확인했다. 다만 이 위젯이 S2 지도 화면의 유일한 캠퍼스 전환 컨트롤이라는 설명도 맞지만, 실제 렌더 높이가 44dp 미만으로 떨어지는지는 텍스트 길이·패딩에 따라 달라 런타임 측정 없이는 단정하기 어려워 low 심각도는 적절해 보인다.

### [low] 지도 핀 렌더 크기가 오늘자 커밋으로 40x50→32x40으로 축소되어 최소 터치 타깃 이하

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/map/widgets/marker_icons.dart:19`
- **내용**: CategoryMarkerIcons의 width/height가 32/40(px)으로 정의되어 있고, 파일 상단 주석과 최근 git 커밋('지도 핀 렌더 크기 축소 40x50 -> 32x40')이 이 값이 오늘 줄어들었음을 확인해 준다. 이는 S2 지도의 주 인터랙션 요소인데 일반적으로 권장되는 최소 탭 영역(44dp 전후)보다 좁아, 밀집한 건물군에서 원하는 핀을 정확히 탭하기 어려워질 수 있다.
- **권고**: 시각적 핀 크기는 유지하되 MarkerIcon의 실제 히트 영역(anchor 포함 클릭 판정)은 44dp 이상이 되도록 별도 여유를 두거나, 밀집 구역에서는 클러스터링을 검토하라.
- **검증 노트**: marker_icons.dart:17-22에서 width=32, height=40(px)로 정의되어 있고 주석도 '원본 68x84를 작게 렌더링'이라 명시한다. git log(9a18575 '지도 핀 렌더 크기 축소 40x50 -> 32x40')로 오늘 축소된 것도 확인했으며, Kakao 지도 마커는 Flutter 위젯이 아닌 WebView 렌더이므로 탭 히트 영역이 이미지 크기에 더 직접적으로 좌우되어 권장 최소 탭 영역보다 좁다는 지적은 타당하다.

### [low] 홈 언어 토글 버튼에 접근성 라벨 부재 + 전용 ARB 문자열 미사용

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/home/home_screen.dart:102`
- **내용**: _LangToggle은 Semantics나 tooltip 없이 TextButton 안에 'KO', '  |  ', 'EN' 세 TextSpan을 직접 조립해 렌더링한다. 스크린 리더는 이를 그대로 읽어줘 '언어 전환' 같은 목적 설명이 없고, 정작 이 버튼을 위해 존재하는 것으로 보이는 ARB 키 home_appbar_langToggle('KO | EN', app_ko.arb 21)은 어디서도 참조되지 않는 죽은 키다.
- **권고**: TextButton을 Semantics(label: l.settings_language_title 류의 설명, button: true)로 감싸 스크린 리더용 라벨을 제공하고, 미사용 ARB 키는 정리하거나 실제로 이 버튼에 연결하라.
- **검증 노트**: home_screen.dart:102-112의 _LangToggle이 Semantics/tooltip 없이 TextButton 안에 TextSpan 3개(KO, ' | ', EN)를 조립하는 것을 확인했고, 같은 파일의 _HeroBanner(126-128행)는 Semantics(button:true, label:...)를 쓰는 것과 대비된다. lib 전체를 grep한 결과 home_appbar_langToggle 키는 app_en.arb/app_ko.arb 두 리소스 파일에만 존재하고 어떤 .dart 파일에서도 참조되지 않아 죽은 키라는 주장도 그대로 확인됐다.

### [low] 강의실 검색 화면의 전체 로드 실패가 재시도 버튼 없이 텍스트만 표시

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/presentation/classroom/classroom_search_screen.dart:77`
- **내용**: allFacilitiesProvider 로드 실패 시 error 분기가 Center(child: Text(l.common_loadFailed))만 렌더링해 재시도 수단이 전혀 없다. 같은 프로바이더(allFacilitiesProvider)의 오류를 다루는 map_screen.dart나 facility_list_screen.dart는 모두 ErrorStateView + common_retry 버튼을 제공하는 것과 대비되어, 앱 전반의 에러 상태 처리 일관성이 깨진다.
- **권고**: 다른 화면과 동일하게 ErrorStateView(message, retryLabel, onRetry: () => ref.invalidate(allFacilitiesProvider))로 교체하라.
- **검증 노트**: classroom_search_screen.dart:77에서 error 분기가 Center(child: Text(l.common_loadFailed))만 렌더링해 재시도 수단이 없음을 확인했다. 동일 allFacilitiesProvider를 쓰는 map_screen.dart(327행)와 facility_list_screen.dart(43-46행)는 모두 ErrorStateView + onRetry: ref.invalidate(allFacilitiesProvider) 패턴을 쓰고 있어, 앱 내 에러 상태 처리 일관성이 깨진다는 지적도 근거가 명확하다.

## 6. 테스트·빌드·배포 준비 — Sonnet

**전반 평가**: 테스트 스위트는 78개 모두 통과하고 flutter analyze도 클린하지만, 커버리지는 순수 mock 계층에 집중되어 있다. Firestore 리포지토리 6개(477줄)와 관리자 시트 Apps Script 파이프라인(Sync.gs 등 607줄)·Node 시더(seed.mjs)는 테스트가 전혀 없어, 실배포 시 사용될 데이터 조인·캐시 폴백·락 로직이 한 번도 검증되지 않는다. 릴리즈 빌드 설정도 미완성 상태다: Android release 빌드는 debug 서명 키를 그대로 쓰고 R8/ProGuard도 꺼져 있으며, plan.md에는 실배포용 Firestore 3플래그 적용이 체크되지 않은 TODO로 남아 있고 이를 자동화하는 빌드 스크립트도 없다. CI가 전혀 없어 이 모든 검증이 로컬 수동 실행에만 의존한다. 위젯 테스트도 지도/검색/시설/식당/설정 화면 자체에는 없고 guide 플로우에만 집중돼 있으며, 앱 버전 표기는 pubspec과 분리된 하드코딩 문자열로 관리된다.

### [high] Firestore 리포지토리 6종 테스트 전무

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/data/firestore/firestore_dining_repository.dart`
- **내용**: test/ 디렉터리 전체를 grep해도 firestore_*.dart 클래스를 import하는 테스트가 하나도 없다(dining_repository_test.dart, guide_flow_test.dart의 'firestore' 매치는 단순 주석/문자열일 뿐). FirestoreDiningRepository.getMenus()만 보더라도 cafeterias 세션 캐시(빈 컬렉션이면 무효화), dining_menus 날짜 쿼리와 cafeteriaId 조인, campus 정렬, Source.cache 폴백 등 실제 파이프라인 로직이 들어 있는데 이 경로가 한 번도 실행 검증된 적이 없다. FirestoreFacilityRepository/FloorGuideRepository/GuideRepository/AcademicCalendarRepository도 동일하게 미검증 상태다.
- **권고**: fake_cloud_firestore 등으로 각 Firestore 리포지토리에 대한 유닛 테스트를 추가해 조인·캐시 폴백·정렬 로직을 최소 1회씩 실행 검증하라.
- **검증 노트**: test/ 6개 파일 전체 grep 결과 firestore 매치는 dining_repository_test.dart의 주석 1건과 guide_flow_test.dart의 주석 2건뿐으로 실제 import는 전무하다. firestore_dining_repository.dart 본문을 재확인하니 _cafeteriasFuture 세션 캐시(빈 결과 시 무효화), dining_menus date 쿼리+cafeteriaId 조인, _campusOrder 정렬, Source.cache 폴백 로직이 그대로 존재해 발견사항 서술과 정확히 일치한다.

### [high] 릴리즈 빌드에 Firestore 3플래그 적용이 미완료·비자동화 상태

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `plan.md`
- **내용**: plan.md 13-4절에 `[ ] 실배포 빌드에 USE_FIRESTORE=true USE_FIRESTORE_CALENDAR=true USE_FIRESTORE_DINING=true 적용`이 체크되지 않은 TODO로 남아 있고, 지금까지 유일하게 기록된 릴리즈 빌드(plan.md 203행, 커밋 6e2807c)는 `flutter build apk --release --dart-define-from-file=env.json`로 카카오 키만 주입했을 뿐 Firestore 플래그는 포함하지 않았다. 세 플래그를 켜는 절차를 담은 스크립트나 문서화된 release용 env 파일 템플릿이 리포 어디에도 없다.
- **권고**: release 전용 env.release.json 템플릿(또는 빌드 스크립트)에 세 플래그를 고정으로 포함시키고, plan.md의 해당 항목을 완료 처리할 절차를 문서화하라.
- **검증 노트**: plan.md 393행에 `- [ ] 실배포 빌드에 USE_FIRESTORE=true ...` 미체크 TODO가 그대로 있고, 203행 기록된 유일한 릴리즈 빌드 명령(`flutter build apk --release --dart-define-from-file=env.json`)의 env.json에는 KAKAO_JS_KEY만 있고 Firestore 플래그는 없다. env.example.json도 카카오 키 템플릿뿐이라 release용 Firestore 플래그 템플릿/스크립트가 리포에 없다는 서술도 사실이다.

### [high] Android release 빌드가 debug 서명 키를 그대로 사용

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/android/app/build.gradle.kts:34`
- **내용**: `buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }`로, Flutter 템플릿이 생성한 TODO("Add your own signing config for the release build")가 그대로 남아 있다. 이 상태로는 Play Console에 업로드할 수 없고(스토어는 release 서명을 요구), 실기기 테스트용 APK도 debug 키로 서명된 채 배포되고 있다(plan.md 203행). minifyEnabled/shrinkResources도 설정돼 있지 않아 R8/ProGuard가 release 빌드에 적용되지 않는다.
- **권고**: key.properties(gitignore 대상)로 실제 release keystore를 구성하고 signingConfigs.release를 추가하며, minifyEnabled=true와 proguard 규칙 파일을 함께 적용하라.
- **검증 노트**: build.gradle.kts 원문을 재확인하니 `buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }`와 `// TODO: Add your own signing config for the release build.` 주석이 그대로 남아 있다. minifyEnabled/shrinkResources 설정도 파일 어디에도 없어 R8/ProGuard 미적용 주장도 사실과 일치한다.

### [medium] 관리자 시트 Apps Script/Node 시더에 자동화 테스트 없음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/tool/admin_sheets/Sync.gs`
- **내용**: Sync.gs(154줄, syncAcademicEvents/syncDiningMenus/runWithLock_ 등 락·조인 로직)와 Validation.gs·Firestore.gs 등 admin_sheets 파이프라인 607줄, 그리고 tool/firestore_seed/seed.mjs(merge/overwrite/prune 로직)에는 어떤 테스트도 붙어 있지 않다. firestore_seed/package.json의 test 스크립트도 `echo "Error: no test specified" && exit 1`로 사실상 비어 있다. 유일한 안전장치는 export_seed_test.dart의 MockData→JSON 왕복 검증뿐이며, 이는 시더 스크립트 자체나 시트 동기화 로직은 전혀 건드리지 않는다.
- **권고**: seed.mjs는 최소한 node:test로 merge/overwrite/prune 분기를 단위 테스트하고, Apps Script는 순수 로직을 별도 함수로 분리해 clasp+로컬 목으로라도 검증 경로를 마련하라.
- **검증 노트**: admin_sheets의 6개 .gs 파일 라인 수를 합산하면 39+56+88+102+154+168=607로 발견사항의 607줄과 정확히 일치하며 테스트 파일은 없다. firestore_seed/package.json의 test 스크립트도 `echo "Error: no test specified" && exit 1` 그대로이고, 유일한 관련 테스트는 export_seed_test.dart 하나뿐임을 확인했다.

### [medium] CI 파이프라인 부재

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `.github`
- **내용**: .github 디렉터리 자체가 리포에 존재하지 않아(find 결과 없음) flutter analyze/flutter test/빌드 검증이 전적으로 로컬 실행자 판단에 의존한다. 이번 감사에서 직접 실행한 결과 analyze는 통과(No issues found!)했고 test도 78개 전부 통과했지만, 이는 이번 감사에서 수동으로 확인한 것일 뿐 커밋마다 자동 검증되는 장치가 아니다.
- **권고**: GitHub Actions 등으로 push/PR 시 flutter analyze + flutter test를 자동 실행하는 워크플로를 추가하라.
- **검증 노트**: 리포 루트에 .github 디렉터리가 존재하지 않고(ls 실패), node_modules 내부 서드파티 패키지의 .github/workflows를 제외하면 프로젝트 자체 CI 워크플로 파일이 전혀 없다.

### [medium] 핵심 화면 다수에 위젯 테스트가 없음

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/test`
- **내용**: test/ 아래 6개 파일은 guide 플로우(guide_flow_test.dart)·학사일정·식당 리포지토리·강의실 코드 로직·층별 아코디언에 집중돼 있고, map_screen.dart, search_screen.dart, facility_list_screen.dart, facility_detail_screen.dart, dining_menu_screen.dart, settings_screen.dart/settings_info_screen.dart, classroom_search_screen.dart 자체를 pumpWidget으로 렌더링·상호작용하는 테스트는 하나도 없다. classroom_providers_test.dart는 화면이 아니라 provider(순수 로직)만 검증한다. 특히 dining_menu_screen.dart의 isUnpublished/isClosed 분기 렌더링(202~211행)은 엔티티 레벨(dining_repository_test.dart)로만 검증되고 실제 위젯 렌더는 미검증이다.
- **권고**: 최소한 지도/검색/식당/설정 화면에 대해 mock 리포지토리 기반의 스모크 위젯 테스트를 추가해 렌더링 크래시와 핵심 상태 분기(unpublished/closed 등)를 검증하라.
- **검증 노트**: test/ 디렉터리 전체에서 MapScreen/SearchScreen/FacilityListScreen/FacilityDetailScreen/DiningMenuScreen/SettingsScreen/SettingsInfoScreen/ClassroomSearchScreen 클래스명 매치가 0건이다. smoke_test.dart는 앱 전체를 pumpWidget해 홈 탭 텍스트만 확인할 뿐이고, dining_menu_screen.dart의 isUnpublished/isClosed 분기(200행 부근)는 위젯 렌더 테스트로 검증되지 않는다는 서술도 실제 코드와 일치한다.

### [low] 앱 버전 표기가 pubspec과 분리된 하드코딩 문자열

- **분류**: 약점 · **검증**: ✅ 검증 확정
- **위치**: `_workspace/02_app_code/lib/l10n/app_ko.arb:176`
- **내용**: 설정 화면의 `settings_version_value`는 ARB 파일에 "0.2.0 (MVP)"로 직접 하드코딩되어 있고(app_ko.arb 176행, app_en.arb 195행), pubspec.yaml의 `version: 0.2.0+2`(빌드 번호 +2)와는 별도로 수동 관리된다. 현재는 major.minor.patch 값이 우연히 일치하지만, PackageInfo.fromPlatform() 등으로 pubspec 값을 읽어오는 코드가 없어 다음 버전을 올릴 때 두 곳을 각각 고치지 않으면 표시값이 실제 빌드와 어긋난다.
- **권고**: package_info_plus 등을 도입해 설정 화면이 pubspec.yaml의 버전/빌드번호를 런타임에 읽어오도록 바꿔 단일 소스로 통일하라.
- **검증 노트**: app_ko.arb 176행, app_en.arb 195행 모두 `"settings_version_value": "0.2.0 (MVP)"`로 하드코딩돼 있고 pubspec.yaml은 `version: 0.2.0+2`로 별도 관리된다. lib 전체에서 PackageInfo 사용 매치가 0건이라 pubspec 값을 읽어오는 코드가 없다는 서술도 확인된다.
