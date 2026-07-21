# Campus-On 개발 참여 가이드

동아대학교 외국인 유학생을 위한 캠퍼스 안내 앱(Flutter, iOS+Android)입니다.
이 문서 하나로 클론부터 실행·기여까지 가능하도록 정리했습니다.

## 1. 저장소 구조

```
plan.md                      ← 기획·로드맵·진행 체크리스트 (먼저 읽기)
CONTRIBUTING.md              ← 이 문서
_workspace/
├── 01_ux_design.md          ← UX/화면 설계 (S1~S10 화면 번호의 출처)
├── 02_app_code/             ← Flutter 앱 (실제 개발은 여기서)
├── 02_app_architecture.md   ← 아키텍처 문서 (계층 구조, 상태 관리)
├── 03_api_integration.md    ← Firestore 스키마·데이터 계층 명세
└── 05_qa_report.md          ← QA 이력 (라운드 1~5, 알려진 이슈·결정 근거)
```

앱 코드 계층(`02_app_code/lib/`): `domain/`(엔티티·인터페이스) ← `data/`(mock + Firestore 구현) ← `presentation/`(화면, Riverpod) + `core/`(라우터·테마·설정). 자세한 건 `02_app_architecture.md` 참고.

## 2. 개발 환경 준비

1. **Flutter SDK** stable 채널 설치 (3.44.x에서 검증됨) — https://docs.flutter.dev/get-started/install
2. Android Studio + Android 에뮬레이터 (또는 실기기). **compileSdk 36** 필요 — SDK Manager에서 Android API 36 설치
3. 클론 후:

```bash
git clone https://github.com/ljw092601/Campus-on.git
cd Campus-on/_workspace/02_app_code
flutter pub get        # gen-l10n도 자동 실행됨 (lib/l10n/gen/ 생성)
flutter analyze        # 통과 기준: No issues
flutter test           # 통과 기준: 전부 그린
```

> `AppLocalizations` 못 찾는다는 오류가 나면 `flutter gen-l10n`을 먼저 실행하세요.
> ARB(`lib/l10n/app_ko.arb`/`app_en.arb`)를 수정한 뒤에도 마찬가지입니다.

## 3. 실행 모드

| 모드 | 명령 | 용도 |
|------|------|------|
| **기본 (mock)** | `flutter run` | UI 개발 — 별도 키 없이 전 화면 동작 (지도만 "로드 실패" 폴백) |
| **+ 카카오 지도** | `flutter run --dart-define-from-file=env.json` | 지도 화면 개발 |
| **+ 실 데이터** | 위 명령에 `--dart-define=USE_FIRESTORE=true` 추가 | Firestore 연동 확인 |

`env.json`은 `02_app_code/` 안에 직접 만듭니다 (**gitignore 대상 — 절대 커밋 금지**):

```json
{ "KAKAO_JS_KEY": "팀장에게_받은_카카오_JS_키" }
```

## 4. 팀장(ljw092601)에게 받아야 하는 것

| 항목 | 필요한 경우 | 비고 |
|------|-------------|------|
| 카카오맵 JS 키 | 지도 화면 작업 | 카카오 콘솔은 팀장 계정 관리 |
| `google-services.json` | Android에서 `USE_FIRESTORE=true` 실행 | `02_app_code/android/app/`에 배치. 또는 Firebase 프로젝트(`campus-f4748`) 멤버로 초대받아 `flutterfire configure` 실행 |
| Firestore 서비스 계정 키 | 시드 데이터 업로드 (보통 팀장만) | `tool/firestore_seed/serviceAccount.json` — **전체 DB 권한이므로 커밋·공유 엄금** |

## 5. 데이터(시설·가이드) 수정 워크플로

콘텐츠의 단일 소스는 **`lib/data/mock/mock_data.dart`** 입니다. 시드 JSON은 자동 생성물이니 직접 수정하지 마세요.

```bash
# 1) mock_data.dart 수정 (시설 좌표, 가이드 콘텐츠 등)
# 2) 시드 JSON 재생성
flutter test tool/firestore_seed/export_seed_test.dart
# 3) Firestore 업로드 (서비스 계정 키 보유자만 — 보통 팀장이 PR 머지 후 실행)
node tool/firestore_seed/seed.mjs --overwrite
```

키가 없는 팀원은 1~2번까지만 하고 PR을 올리면 됩니다.

## 6. 브랜치·PR 규칙

- `main` 직접 푸시 금지 — 기능 브랜치(`이름/기능` 예: `hong/notice-screen`)에서 작업 후 PR
- PR 전 체크: `flutter analyze` No issues + `flutter test` 통과
- 사용자에게 보이는 문자열은 **하드코딩 금지** — 반드시 ARB(한/영 양쪽)에 추가 (QA 감사 기준: ko↔en 키 완전 일치)
- 화면·상태 규칙(로딩/빈/오류/부분/성공 5-state), 접근성 기준은 `05_qa_report.md`의 감사 항목 참고

## 7. 자주 걸리는 함정 (QA에서 실제로 겪은 것)

- **지도 흰 화면 + `kakao is not defined`**: 키 문제가 아니라 카카오 콘솔의 "카카오맵 서비스 활성화" 토글 문제였음 (해결됨 — 새 키를 쓸 때만 해당)
- **에뮬레이터에서 전화/외부링크 무동작**: Android `<queries>`/iOS `LSApplicationQueriesSchemes` 필요 (이미 반영됨 — 새 scheme 추가 시 같은 작업 필요)
- **첫 지도 진입에 마커 미표시**: `kakao_map_plugin`은 `onMapCreated`에서 마커를 직접 넣어야 함 (`campus_map_view.dart` 참고)
- 패키지명은 `io.github.ljw092601.campuson` — `com.example.*`로 되돌리면 Play 등록이 거부됩니다
