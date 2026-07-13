# App Architecture Document — Campus-On (Week 2)

> mobile-app-builder / App Dev Mode (app-developer)
> 근거: `_workspace/01_ux_design.md` (S1–S10, 디자인 토큰, 데이터 모델, 딥링크) · `_workspace/00_input.md`
> 코드: `_workspace/02_app_code/`

## Technology Stack

- **Framework**: Flutter (iOS + Android), SDK `>=3.27.0`, Dart `>=3.6.0`
- **Language**: Dart
- **State Management**: **Riverpod** (`flutter_riverpod ^2.5.1`) — plain providers, no code-gen(build_runner) 의존
- **Navigation**: **go_router ^14.2.0** (`StatefulShellRoute.indexedStack`, 하단 4탭 + 탭별 스택)
- **Local DB**: `shared_preferences ^2.2.3` (즐겨찾기·언어·최근검색 — 전면 로컬)
- **Map**: **카카오맵** (`kakao_map_plugin ^0.3.1`) — `CampusMapView` 위젯 한 곳에 격리
- **i18n**: `intl ^0.20.2` (flutter_localizations 고정 버전과 정합) + ARB(ko/en), `flutter gen-l10n`
- **Network**: 없음(week 2). Firestore 클라이언트는 api-integrator가 Repository 구현으로 주입
- **Icons**: `material_symbols_icons` (1세트 통일, iOS/Android 공통)
- **DI**: Riverpod Provider 그래프 (`main()`에서 `SharedPreferences` override)

## 상태관리·라우팅 선택 근거

- **Riverpod (plain, no codegen)**: 1인·1개월 제약 → build_runner/freezed 없이 컴파일되도록 순수 `Notifier`/`FutureProvider`/`StateProvider` 사용. Provider override로 mock↔실데이터 교체가 한 줄. 테스트 용이(`ProviderScope(overrides:)`).
- **go_router `StatefulShellRoute`**: UX 문서 §3의 "탭별 독립 Stack + 상세에서도 탭바 유지" 요구를 표준 기능으로 충족. 딥링크 `/map?focus=<ids>`를 URL 쿼리로 자연스럽게 표현. 검색(S8)은 루트 내비게이터 전체화면 라우트.
- **MVVM/Clean 지향**: domain(엔티티·Repository 인터페이스) → data(구현) → presentation(providers=ViewModel 역할, screens=View). 화면은 인터페이스에만 의존.

## Project Structure (feature-first + layered)

```
lib/
├── main.dart                     — 진입점(prefs·Kakao init·ProviderScope override)
├── app.dart                      — MaterialApp.router(테마·locale·라우터 결선)
├── core/
│   ├── config/app_config.dart    — Kakao 키 주입(--dart-define), 캠퍼스 중심 좌표
│   ├── router/app_router.dart     — go_router(4 branch + /search + 딥링크)
│   └── theme/
│       ├── app_dimens.dart        — ThemeExtension: spacing/radius/elevation/touch
│       ├── category_colors.dart   — ThemeExtension: 시설6 + 가이드6 액센트
│       └── app_theme.dart         — ColorScheme(라이트/다크)·타이포·extensions
├── l10n/
│   ├── app_en.arb / app_ko.arb    — 문자열({screen}_{element}_{meaning})
│   └── gen/                        — gen-l10n 산출물(pub get 시 생성)
├── domain/
│   ├── entities/                   — Facility, AdminGuideItem, FavoriteRef (+ enums)
│   └── repositories/               — *Repository 인터페이스(계약)
├── data/
│   ├── mock/mock_data.dart         — 개발용 시드
│   └── repositories/               — Mock* 구현 + LocalFavoritesRepository
└── presentation/
    ├── providers/                  — locale/repository/facility/favorites/search
    ├── shell/app_shell.dart        — 적응형 하단 탭바(Nav/Cupertino)
    ├── shared/                      — category_labels + 재사용 위젯
    ├── home/  map/  facility/  search/   — 구현 화면(S1/S2/S3·S4/S8)
    ├── guide/                       — S5–S7 스텁
    └── settings/                    — S9 스텁(+언어 스위치) · S10 스텁
```

## Layers

| Layer | 위치 | 책임 |
|-------|------|------|
| Domain | `lib/domain` | 엔티티(로케일 폴백 로직 포함), Repository 인터페이스. 프레임워크 비의존(단, 아이콘 매핑은 편의상 enum에 포함) |
| Data | `lib/data` | Repository 구현(week2=Mock/Local). api-integrator가 Firestore 구현 추가 |
| Presentation | `lib/presentation` | Riverpod providers(ViewModel), 화면·위젯(View) |

## Per-Screen Implementation Spec

| 화면 | 파일 | ViewModel(Provider) | 핵심 상태 | 데이터원 |
|------|------|---------------------|-----------|----------|
| S1 홈 | `presentation/home/home_screen.dart` | `localeProvider`, `facilityCategoryFilterProvider` | 언어, 선택 카테고리 | 정적 enum(+week3 카운트) |
| S2 지도 | `presentation/map/map_screen.dart` | `filteredFacilitiesProvider`, 로컬 `_selectedId` | 필터, 선택 마커, focusIds | `FacilityRepository.getAll` |
| S3 목록 | `presentation/facility/facility_list_screen.dart` | `filteredFacilitiesProvider`, `favoritesProvider` | 필터, 즐겨찾기 | `getAll` |
| S4 상세 | `presentation/facility/facility_detail_screen.dart` | `facilityByIdProvider(id)`, `favoritesProvider` | 단건 로드, 즐겨찾기, 폰트스케일 | `getById` |
| S8 검색 | `presentation/search/search_screen.dart` | `searchQueryProvider`, `searchSegmentProvider`, `searchResultsProvider`, `recentSearchesProvider` | 쿼리(디바운스300ms), 세그먼트, 최근검색 | `Facility/Guide.search` |
| S5–S7 가이드 | `presentation/guide/guide_stub_screen.dart` | — | — | (week 3) |
| S9 설정 | `presentation/settings/settings_stub_screen.dart` | `localeProvider` | 언어 즉시전환 | 로컬 |
| S10 즐겨찾기 | `presentation/settings/favorites_stub_screen.dart` | (`favoritesProvider` 저장 동작 중) | — | 로컬 |

각 화면 5상태(정상/로딩/빈/에러/부분): `AsyncValue.when` + `EmptyStateView`/`ErrorStateView`/`SkeletonList`(`shared/widgets/state_views.dart`)로 통일. S4는 결측 필드 행 숨김(Partial), 하단 CTA는 폰트 200%/좁은 폭에서 세로 스택 전환.

## State Management Design

| 상태 | 타입 | 초기값 | 변경 트리거 |
|------|------|--------|-------------|
| `localeProvider` | `NotifierProvider<Locale>` | prefs 저장값→디바이스→en | 홈 토글 / 설정 라디오 |
| `facilityCategoryFilterProvider` | `StateProvider<FacilityCategory?>` | null(전체) | 필터칩 / 홈 카테고리칩 |
| `allFacilitiesProvider` | `FutureProvider<List<Facility>>` | 로딩 | 최초 / `invalidate`(재시도·pull-refresh) |
| `filteredFacilitiesProvider` | `Provider<AsyncValue<List>>` | 파생 | all/filter 변경 |
| `facilityByIdProvider(id)` | `FutureProvider.family` | 로딩 | 상세 진입 / 재시도 |
| `favoritesProvider` | `AsyncNotifier<Set<String>>` | 로컬 로드 | 별 토글(낙관적) |
| `searchQueryProvider` | `StateProvider<String>` | '' | 입력 디바운스 300ms |
| `searchResultsProvider` | `FutureProvider<SearchResults>` | 파생 | query/segment 변경 |
| `recentSearchesProvider` | `NotifierProvider<List<String>>` | 로컬(최대8) | 검색 제출 |

## Repository 인터페이스 계약 (→ api-integrator)

**교체 지점**: `lib/presentation/providers/repository_providers.dart`. mock 반환부만 Firestore 구현으로 바꾸면 화면·프로바이더는 무수정. 인터페이스는 `lib/domain/repositories/`.

```dart
// FacilityRepository — 캠퍼스 소량 데이터 → 전체 로드 후 클라 필터 권장
Future<List<Facility>> getAll();              // 실패 시 throw → 화면 Error 상태
Future<Facility?>       getById(String id);   // 없으면 null → 화면 Error/none
Future<List<Facility>>  getByIds(List<String> ids);  // 지도 딥링크 fitBounds용
Future<List<Facility>>  search(String query); // name_ko/name_en, 대소문자 무시 contains

// GuideRepository — week2는 검색 인덱스만 사용, 상세(S7)는 week3
Future<List<AdminGuideItem>> getAllItems();
Future<List<AdminGuideItem>> search(String query);   // title_ko/title_en
Future<AdminGuideItem?>      getById(String id);

// FavoritesRepository — 로컬 전용(구현 완료, 서버 불필요)
Future<List<FavoriteRef>> getAll();
Future<void> add(FavoriteRef ref);
Future<void> remove(FavoriteType type, String id);
Future<bool> isFavorite(FavoriteType type, String id);
```

계약 세부:
- 반환 엔티티는 `Facility`/`AdminGuideItem`(둘 다 `fromJson`/`toJson` 제공 — Firestore 문서 매핑에 사용). 카테고리 enum id는 문자열 필드명과 1:1(`building`… / `immigration`…).
- 실패는 예외로 던짐(프리젠테이션의 `AsyncValue.error` → Error UI + `common_retry`). 부분 결측은 정상 반환하되 `null` 필드로.
- `search`는 현재 클라 필터. Firestore로 옮겨도 시그니처 유지(내부만 교체).
- 오프라인/캐싱(Hive/Isar) 전략은 UX 문서 §8 참고 — 구현체 내부 관심사, 인터페이스 불변.

## Kakao Maps 키 주입 방식

- 하드코딩 금지. `AppConfig.kakaoJsKey = String.fromEnvironment('KAKAO_JS_KEY')`.
- 실행: `flutter run --dart-define=KAKAO_JS_KEY=...` 또는 `--dart-define-from-file=env.json`(`env.example.json` 복사).
- `main()`이 `initKakaoMap()` 호출 → 키 있으면 `AuthRepository.initialize`, 없으면 no-op(앱 부팅 유지).
- 키 없음/로드 실패 시 S2는 폴백 UI(`map_error_loadFailed` + 시설 목록 이동)로 강등, 크래시 없음.
- 플러그인 결합은 `presentation/map/widgets/campus_map_view.dart`·`kakao_init.dart` 두 파일에만 존재 → 플러그인 API 변동 시 국소 수정.

## Build / Run

```bash
cd _workspace/02_app_code
flutter create --platforms=android,ios --project-name campus_on .  # 네이티브 폴더 생성
flutter pub get            # gen-l10n 자동 실행 → lib/l10n/gen/
flutter run --dart-define-from-file=env.json
flutter test               # test/smoke_test.dart (부팅 스모크)
```

### pubspec 의존성
`flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `intl ^0.20.2`, `shared_preferences ^2.2.3`, `kakao_map_plugin ^0.3.1`, `material_symbols_icons ^4.2785.1`, `url_launcher ^6.3.0` / dev: `flutter_test`, `flutter_lints ^4.0.0`. (Flutter 3.44.6 stable에서 `pub get`·`analyze`·`test` 통과 확인 — QA 라운드 2.)

## Error Handling Strategy

| 오류 유형 | 처리 | 사용자 피드백 |
|-----------|------|----------------|
| 시설/목록 로드 실패 | `AsyncValue.error` → `invalidate` 재시도 | `ErrorStateView` + 다시 시도(+지도는 목록 폴백) |
| 카카오맵 로드 실패/키 없음 | S2 폴백 렌더 | "지도를 불러오지 못했어요" + 목록 이동 |
| 위치 권한 거부 | 캠퍼스 중심 폴백(week3 재요청) | 스낵바 안내 |
| 상세 단건 없음/실패 | Error 전면 | 다시 시도 |
| 필드 결측(Partial) | 해당 행 숨김, 이미지→카테고리 배너 | 빈 라벨 미표시 |
| 검색 실패 | Error 인라인 | 다시 시도 |
| 이미지 로드 실패 | `errorBuilder` → 카테고리 배너 | 무중단 |

## Handoff Notes for API Integrator

- `repository_providers.dart`의 3개 Provider가 유일한 교체 지점. `Mock*Repository` → `Firestore*Repository`(같은 인터페이스)로 바꾸고 override만 조정.
- 엔티티 `fromJson`은 UX §8 필드명(`name_ko`, `hours_en`, `relatedFacilityIds` 등)을 그대로 기대. Firestore 컬렉션 스키마를 이에 맞추거나 매핑 계층 추가.
- 캠퍼스 소량 → `getAll` 1회 로드 + 클라 필터 유지 권장. 오프라인 캐시(Hive/Isar)는 구현체 내부에서.
- 즐겨찾기·최근검색·언어는 서버 불필요(로컬 완료).
- `AppConfig` 외 Firebase 초기화 필요 시 `main()`에 `Firebase.initializeApp()` 추가(현재 미포함).

## Handoff Notes for QA Engineer

- 테스트 진입점: `test/smoke_test.dart`(부팅→홈). `ProviderScope(overrides:)`로 mock 주입 패턴 재사용.
- 5상태 회귀: 각 화면 `state_views.dart` 컴포넌트로 통일 → Loading/Empty/Error/Partial 스냅샷 대상.
- 딥링크 회귀: `/map?focus=id` 단건(setCenter) / 복수(fitBounds + 첫 마커 Peek) — `MapScreen(focusIds:)`.
- 한/영: `localeProvider.toggle()` 즉시 리빌드, S4 하단 CTA 폰트 200% 세로 전환, 리스트 오버플로우(ellipsis).
- A11y: 즐겨찾기 버튼 tooltip/Semantics, 카테고리칩 Semantics(selected), 터치 타깃 48dp.

## Remaining TODO (Week 3)

- **가이드 S5–S7**: 카테고리 리스트/항목/상세(접이식 4섹션·체크리스트·관련링크). `GuideRepository` 상세 메서드 활용, 홈 가이드 타일→해당 카테고리 딥링크.
- **설정 S9**: About/데이터출처/문의/개인정보처리방침(외부링크)/라이선스/버전.
- **즐겨찾기 S10**: 시설/가이드 세그먼트 목록 + 스와이프 삭제(저장 로직은 이미 동작).
- **지도**: 카테고리별 6색 마커 PNG 에셋(`CampusMapView.markerImageFor`), 내 위치 권한 흐름, 미니지도 Kakao static 이미지, 거리 계산(정렬).
- **오프라인 캐싱**: Hive/Isar + 오프라인 배너(api-integrator 협업).
- **폰트**: Pretendard 번들(pubspec 주석 처리됨).
- **홈 카운트 배지**: 카테고리별 시설/항목 수(원격, 실패 시 숨김).
```
