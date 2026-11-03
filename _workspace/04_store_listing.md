# Google Play 제출 초안 — 동아메이트 (DONG-A-MATE)

- 작성일: 2026-10-27 · 대상: Google Play Console(개인 개발자 계정) · iOS는 범위 밖
- 패키지: `io.github.ljw092601.campuson` · 현재 pubspec `version: 0.2.0+2` → 출시 시 `1.0.0+N`
- 근거: `02_app_code`(pubspec, AndroidManifest, `lib/l10n/app_*.arb`, `location_service.dart`, `map_screen.dart`), `00_input.md`, `01_ux_design.md`
- 글자 수는 Play Console 기준(유니코드 문자 수, 공백·줄바꿈 포함)으로 스크립트로 셌다. 붙여넣기 후 Console 카운터로 한 번 더 확인할 것.

> **비공식 고지 문구**: 모든 언어의 전체 설명 끝에 "동아대학교 공식 앱이 아니며 학교와 제휴 관계가 없다"는 줄을 넣었다. 대학 본부의 공식 승인(서면)을 받으면 이 줄을 지우고, 그때는 "동아대" 명칭을 앱 이름에 넣는 것도 검토할 수 있다.
>
> **앱 이름에 학교명을 넣지 않은 이유**: Play의 사칭(Impersonation)·지식재산권 정책상, 승인 없이 기관명을 제목에 넣으면 "공식 앱으로 오인"될 수 있어 반려·정지 위험이 있다. 학교명·키워드는 짧은 설명과 전체 설명에 고지 문구와 함께 넣는다.

---

## 1. 스토어 등록정보 (언어별)

기본 언어: **한국어(ko-KR)** · 번역 추가: **영어(en-US)**, **중국어 간체(zh-CN)**, **베트남어(vi)**

### 1-1. 한국어 (ko-KR)

| 항목 | 내용 | 글자 수 |
|---|---|---|
| 앱 이름 (≤30) | `동아메이트: 유학생 캠퍼스 가이드` | 18 |
| 짧은 설명 (≤80) | `동아대 유학생을 위한 캠퍼스 지도·강의실 찾기·비자 행정 가이드·학사일정·학식을 한 곳에` | 49 |

전체 설명 (≤4000) — 1407자

<!-- ko_full -->
```text
동아대학교에 온 외국인 유학생을 위한 캠퍼스 생활 가이드, 동아메이트입니다.
강의실 위치, 비자·외국인등록 같은 행정 절차, 학사일정, 오늘의 학식을 한국어·영어·중국어(간체)·베트남어로 한 곳에서 확인하세요.
로그인 없이 바로 쓸 수 있고, 광고와 유료 결제가 없습니다.

■ 이런 걸 할 수 있어요
• 캠퍼스 지도: 승학·구덕·부민 캠퍼스의 건물과 편의시설을 카카오맵 위에서 확인
• 강의실 찾기: "0301"처럼 강의실 번호나 건물 이름으로 검색하면 층별 도면에서 위치를 표시
• 행정 가이드: 비자·외국인등록·체류연장, 기숙사·주거, 은행·휴대폰·교통카드, 건강보험·병원, 수강신청·증명서, 긴급연락처까지 단계별 안내
• 학사일정: 수강신청·시험·방학 등 다가오는 일정을 한눈에
• 오늘의 학식: 식당별 메뉴, 가격, 운영시간(휴게시간 포함)
• 즐겨찾기: 자주 가는 건물과 시설을 저장
• 4개 언어 화면과 라이트·다크·시스템 화면 모드

■ 캠퍼스 지도와 시설 안내
건물을 누르면 층별 안내와 편의시설 정보를 볼 수 있습니다. 위치 권한을 허용하면 지도에 내 위치가 표시되어 지금 어느 건물 근처인지 바로 알 수 있어요. 위치 정보는 기기 안에서 지도 표시에만 쓰이고 저장하거나 서버로 보내지 않습니다.

■ 강의실 번호로 바로 찾기
시간표에 적힌 강의실 번호를 입력하면 해당 건물과 층 도면에서 강의실 위치를 표시합니다. 처음 가보는 건물에서도 헤매지 않아요.

■ 유학생 행정 가이드
한국 생활을 시작할 때 꼭 필요한 절차를 주제별로 정리했습니다. 외국인등록증 신청, 체류기간 연장, 국민건강보험, 은행 계좌 개설, 휴대폰 개통, 교통카드, 수강신청과 증명서 발급까지 준비물과 순서를 차근차근 확인하세요.

■ 학사일정과 학식
수강신청 기간, 시험, 방학 같은 학사일정과 캠퍼스별 학식 메뉴·가격·운영시간을 확인할 수 있습니다. 정보는 운영진이 업데이트하며, 한 번 불러온 내용은 인터넷이 약할 때도 볼 수 있습니다.

■ 언어 안내
화면과 행정 가이드는 한국어·영어·중국어(간체)·베트남어로 제공됩니다. 층별 안내의 공간 이름과 학식 메뉴는 번역된 항목만 선택한 언어로 보이고, 나머지는 건물 표지판과 맞추기 위해 한국어로 표시됩니다.

■ 개인정보
회원가입·로그인이 없고, 개인정보를 수집하지 않습니다. 즐겨찾기·언어·화면 모드 설정은 기기에만 저장됩니다.
개인정보처리방침: https://ljw092601.github.io/Campus-on/privacy/
문의: donga.campus.on@gmail.com

동아대 유학생, 교환학생, 어학연수생이라면 지금 동아메이트를 설치하고 캠퍼스 생활을 더 쉽게 시작하세요.

※ 동아메이트는 학생이 만든 비공식 앱으로, 동아대학교의 공식 앱이 아니며 동아대학교와 제휴 관계가 없습니다. 정확한 행정 정보는 학교 및 관계 기관 공지를 함께 확인하세요.
```

### 1-2. English (en-US)

| Field | Text | Chars |
|---|---|---|
| App name (≤30) | `Dong-A Mate: Campus Guide` | 25 |
| Short description (≤80) | `Campus map, classroom finder, visa guides & menus for Dong-A Univ. intl students` | 80 |

Full description (≤4000) — 2968 chars

<!-- en_full -->
```text
Dong-A Mate is a campus guide for international students at Dong-A University in Busan, Korea.
Find classrooms, follow visa and alien registration steps, check the academic calendar and today's cafeteria menu — in English, Korean, Simplified Chinese and Vietnamese.
No sign-up, no ads, no in-app purchases.

■ WHAT YOU CAN DO
• Campus map: buildings and facilities on Seunghak, Gudeok and Bumin campuses, on Kakao Map
• Classroom finder: search a room number like "0301" or a building name and see it on the floor plan
• Admin guides: visa, alien registration card (ARC), extension of stay, housing and dorms, bank account, phone, transit card, health insurance, hospitals, course registration, certificates and emergency contacts — step by step
• Academic calendar: course registration, exams and breaks at a glance
• Cafeteria menus: menus, prices and opening hours (including break times) for each cafeteria
• Favorites: save the buildings and facilities you visit often
• 4 languages, plus light, dark and system theme

■ CAMPUS MAP & FACILITIES
Tap a building to see its floor guide and facilities. Allow location access and your position appears on the map, so you always know which building you are near. Your location is used only on your device to draw the map — it is never stored or sent to a server.

■ FIND A CLASSROOM BY ROOM NUMBER
Type the room number from your timetable and Dong-A Mate highlights the room on the building's floor plan. No more getting lost in a building you have never been to.

■ ADMIN GUIDES FOR INTERNATIONAL STUDENTS
Everything you need when starting life in Korea, organized by topic: applying for your ARC, extending your stay, National Health Insurance, opening a bank account, getting a phone plan and a transit card, course registration and certificates. Check the documents you need and the order of each step.

■ ACADEMIC CALENDAR & CAFETERIA
See registration periods, exams and breaks, plus cafeteria menus, prices and hours for each campus. Information is updated by the app team, and content you have already loaded stays available on a weak connection.

■ ABOUT LANGUAGES
The screens and admin guides are available in Korean, English, Simplified Chinese and Vietnamese. In floor guides and cafeteria menus, translated entries appear in your language; the rest stay in Korean so they match the signs on the doors.

■ PRIVACY
No account and no personal data collection. Favorites, language and theme settings are stored only on your device.
Privacy policy: https://ljw092601.github.io/Campus-on/privacy/
Contact: donga.campus.on@gmail.com

International, exchange or language-program student at Dong-A University? Download Dong-A Mate and start campus life with confidence.

* Dong-A Mate is an unofficial, student-made app. It is not an official app of Dong-A University and is not affiliated with or endorsed by Dong-A University. Always confirm administrative details with the university and the relevant authorities.
```

### 1-3. 简体中文 (zh-CN)

| 字段 | 文本 | 字数 |
|---|---|---|
| 应用名称 (≤30) | `Dong-A Mate：留学生校园指南` | 19 |
| 简短说明 (≤80) | `东亚大学留学生必备：校园地图、教室查找、签证与外国人登记指南、教务日程、学生餐菜单` | 41 |

完整说明 (≤4000) — 1024 字

<!-- zh_full -->
```text
Dong-A Mate（동아메이트）是为韩国釜山东亚大学外国留学生打造的校园生活指南。
查找教室位置、了解签证和外国人登录等行政手续、查看教务日程和今日学生餐，支持中文（简体）、韩语、英语、越南语。
无需注册登录，无广告，无应用内购买。

■ 主要功能
• 校园地图：在 Kakao 地图上查看乘鹤、九德、富民校区的建筑和便利设施
• 教室查找：输入"0301"这样的教室编号或建筑名称，在楼层平面图上显示位置
• 行政指南：签证、外国人登录证、延长滞留、宿舍与住房、银行开户、手机开通、交通卡、健康保险、医院、选课、证明书、紧急联系方式，分步骤说明
• 教务日程：选课、考试、放假等日程一目了然
• 今日学生餐：各食堂菜单、价格、营业时间（含休息时间）
• 收藏：保存常去的建筑和设施
• 四种界面语言，支持浅色、深色和跟随系统主题

■ 校园地图与设施
点击建筑即可查看楼层指南和设施信息。允许位置权限后，地图上会显示你的位置，随时知道自己在哪栋楼附近。位置信息仅在设备上用于显示地图，不会被保存或发送到服务器。

■ 用教室编号直接查找
输入课表上的教室编号，即可在该建筑的楼层平面图上标出教室位置，第一次去的楼也不会迷路。

■ 留学生行政指南
按主题整理了在韩国开始生活时必须办理的手续：申请外国人登录证、延长滞留期限、国民健康保险、银行开户、手机开通、交通卡、选课和证明书发放。逐步确认所需材料和办理顺序。

■ 教务日程与学生餐
查看选课期间、考试、放假等教务日程，以及各校区学生餐的菜单、价格和营业时间。信息由运营团队更新，已加载的内容在网络不佳时也能查看。

■ 语言说明
界面和行政指南提供韩语、英语、中文（简体）、越南语。楼层指南的空间名称和学生餐菜单只有已翻译的条目显示为所选语言，其余保留韩语，以便与门上的标识牌一致。

■ 隐私
无需账号，不收集个人信息。收藏、语言和主题设置仅保存在你的设备上。
隐私政策：https://ljw092601.github.io/Campus-on/privacy/
联系方式：donga.campus.on@gmail.com

如果你是东亚大学的留学生、交换生或语学研修生，现在就下载 Dong-A Mate，轻松开始校园生活。

※ Dong-A Mate 是由学生制作的非官方应用，并非东亚大学官方应用，与东亚大学无任何隶属或合作关系。具体行政信息请以学校及相关机构的公告为准。
```

### 1-4. Tiếng Việt (vi)

| Mục | Nội dung | Ký tự |
|---|---|---|
| Tên ứng dụng (≤30) | `Dong-A Mate: Cẩm nang du học` | 28 |
| Mô tả ngắn (≤80) | `Bản đồ trường, tìm phòng học, visa, thẻ cư trú, lịch học vụ, thực đơn ĐH Dong-A` | 79 |

Mô tả đầy đủ (≤4000) — 2906 ký tự

<!-- vi_full -->
```text
Dong-A Mate là cẩm nang đời sống học đường dành cho du học sinh quốc tế tại Đại học Dong-A (Busan, Hàn Quốc).
Tìm phòng học, xem các bước làm visa và thẻ cư trú người nước ngoài, lịch học vụ và thực đơn nhà ăn hôm nay — bằng tiếng Việt, tiếng Hàn, tiếng Anh và tiếng Trung giản thể.
Không cần đăng ký, không quảng cáo, không mua hàng trong ứng dụng.

■ TÍNH NĂNG CHÍNH
• Bản đồ khuôn viên: tòa nhà và tiện ích của các cơ sở Seunghak, Gudeok, Bumin trên Kakao Map
• Tìm phòng học: nhập số phòng như "0301" hoặc tên tòa nhà để xem vị trí trên sơ đồ tầng
• Hướng dẫn hành chính: visa, thẻ cư trú (ARC), gia hạn lưu trú, ký túc xá và nhà ở, tài khoản ngân hàng, điện thoại, thẻ giao thông, bảo hiểm y tế, bệnh viện, đăng ký môn học, giấy chứng nhận, liên lạc khẩn cấp — từng bước một
• Lịch học vụ: đăng ký môn học, thi cử, kỳ nghỉ trong nháy mắt
• Thực đơn nhà ăn: món ăn, giá và giờ mở cửa (kể cả giờ nghỉ) của từng nhà ăn
• Yêu thích: lưu tòa nhà và tiện ích bạn hay đến
• 4 ngôn ngữ, giao diện sáng, tối hoặc theo hệ thống

■ BẢN ĐỒ VÀ TIỆN ÍCH
Chạm vào tòa nhà để xem hướng dẫn theo tầng và tiện ích. Khi cho phép quyền vị trí, vị trí của bạn hiện trên bản đồ để biết mình đang ở gần tòa nhà nào. Vị trí chỉ được dùng trên thiết bị để hiển thị bản đồ, không được lưu hay gửi lên máy chủ.

■ TÌM PHÒNG HỌC BẰNG SỐ PHÒNG
Nhập số phòng trong thời khóa biểu, Dong-A Mate sẽ đánh dấu phòng trên sơ đồ tầng của tòa nhà. Không còn lạc đường ở tòa nhà lần đầu đến.

■ HƯỚNG DẪN HÀNH CHÍNH CHO DU HỌC SINH
Các thủ tục cần thiết khi bắt đầu cuộc sống ở Hàn Quốc được sắp xếp theo chủ đề: làm thẻ cư trú, gia hạn lưu trú, Bảo hiểm Y tế Quốc dân, mở tài khoản ngân hàng, đăng ký điện thoại, thẻ giao thông, đăng ký môn học và cấp giấy chứng nhận. Kiểm tra giấy tờ cần chuẩn bị và thứ tự từng bước.

■ LỊCH HỌC VỤ VÀ NHÀ ĂN
Xem thời gian đăng ký môn học, lịch thi, kỳ nghỉ, cùng thực đơn, giá và giờ mở cửa nhà ăn của từng cơ sở. Thông tin do nhóm vận hành cập nhật; nội dung đã tải vẫn xem được khi mạng yếu.

■ VỀ NGÔN NGỮ
Giao diện và hướng dẫn hành chính có bằng tiếng Hàn, tiếng Anh, tiếng Trung giản thể và tiếng Việt. Trong hướng dẫn theo tầng và thực đơn nhà ăn, các mục đã dịch hiển thị bằng ngôn ngữ của bạn; các mục còn lại giữ tiếng Hàn để khớp với biển tên trên cửa.

■ QUYỀN RIÊNG TƯ
Không cần tài khoản, không thu thập dữ liệu cá nhân. Mục yêu thích, ngôn ngữ và giao diện chỉ được lưu trên thiết bị của bạn.
Chính sách quyền riêng tư: https://ljw092601.github.io/Campus-on/privacy/
Liên hệ: donga.campus.on@gmail.com

Bạn là du học sinh, sinh viên trao đổi hay học viên khóa tiếng tại Đại học Dong-A? Hãy tải Dong-A Mate ngay để bắt đầu cuộc sống học đường dễ dàng hơn.

* Dong-A Mate là ứng dụng không chính thức do sinh viên phát triển, không phải ứng dụng chính thức của Đại học Dong-A và không liên kết với Đại học Dong-A. Vui lòng xác nhận thông tin hành chính với nhà trường và cơ quan liên quan.
```

### 1-5. ASO 키워드 메모

| 언어 | 핵심 키워드(설명 내 자연 반복) |
|---|---|
| ko | 동아대, 유학생, 캠퍼스 지도, 강의실 찾기, 비자, 외국인등록, 학사일정, 학식, 교환학생 |
| en | Dong-A University, international students, campus map, classroom finder, visa, ARC, academic calendar, cafeteria menu, Busan |
| zh-CN | 东亚大学, 留学生, 校园地图, 教室查找, 签证, 外国人登录证, 教务日程, 学生餐, 釜山 |
| vi | Đại học Dong-A, du học sinh, bản đồ, tìm phòng học, visa, thẻ cư trú, lịch học vụ, nhà ăn, Busan |

- Play에는 키워드 필드가 없으므로 앞 3줄(접기 전 노출)에 학교명·유학생·지도·비자·학식을 모두 넣었다.
- 키워드 나열(스터핑)은 Play 메타데이터 정책 위반이므로 문장 안에만 배치했다. 순위·평점·"최고/1위" 같은 표현은 넣지 않았다.

---

## 2. 카테고리 · 태그 · 연락처

| 항목 | 권장값 | 비고 |
|---|---|---|
| 앱/게임 | 앱 | |
| 카테고리 | **교육(Education)** | 대안: 여행 및 지역정보(Travel & Local). 지도 앱 경쟁이 적은 쪽보다 "학생 대상 교육 보조"가 검색 의도와 맞음 |
| 태그(최대 5) | 후보: 대학/캠퍼스, 학생, 지도, 가이드, 외국어/국제 | Console의 태그 목록에서 가장 가까운 항목을 고를 것(목록이 수시로 바뀌어 정확한 명칭은 Console에서 확인) |
| 이메일 (필수, 공개) | donga.campus.on@gmail.com | |
| 웹사이트 (선택) | https://ljw092601.github.io/Campus-on/ | gh-pages 루트 `index.html` 존재. 내용이 앱 소개인지 확인 |
| 전화 (선택) | 비워둠 | 개인 계정이면 공개 노출되므로 생략 권장 |
| 개인정보처리방침 URL | https://ljw092601.github.io/Campus-on/privacy/ | 앱 내 설정 화면 링크와 동일해야 함 |
| 가격 | 무료 | 무료로 게시 후 유료 전환 불가 |
| 국가/지역 | 대한민국 필수, 그 외 전체 또는 주요 유학생 출신국(베트남·중국 등) | 해외 체류 중 설치 수요 고려 시 전체 국가 권장 |

---

## 3. 데이터 보안(Data safety) 양식

### 3-0. 코드로 확인한 사실 (읽기 전용 확인)

| 항목 | 확인 결과 | 위치 |
|---|---|---|
| 권한 | `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` 만 선언. 백그라운드 위치 없음 | `android/app/src/main/AndroidManifest.xml` |
| 위치 사용 | `geolocator`로 권한 요청·위치 스트림 → `map_screen.dart`에서 지도에 내 위치 마커 표시 및 가까운 캠퍼스 전환에만 사용. 서버 전송 코드 없음 | `lib/data/services/location_service.dart`, `lib/presentation/map/map_screen.dart` |
| 나침반 | `flutter_compass`(센서, 별도 권한 없음) — 마커 방향 표시 | 같은 파일 |
| 원격 데이터 | `firebase_core` + `cloud_firestore` 읽기 전용. Analytics·Crashlytics·광고 SDK 없음 | `pubspec.yaml` |
| 로컬 저장 | `shared_preferences`(즐겨찾기·언어·테마) | |
| 지도 | `kakao_map_plugin` / `webview_flutter`(Kakao Maps JS SDK) | `lib/presentation/map/widgets/kakao_init.dart` |
| 외부 링크 | `url_launcher`로 외부 브라우저/전화 등 열기(앱 밖) | `lib/presentation/shared/external_links.dart` |
| 백업 | `android:allowBackup="false"` | Manifest |

### 3-1. 질문별 답변 (Play Console 문구)

**데이터 수집 및 보안**

| 질문 | 답변 | 근거 |
|---|---|---|
| Does your app collect or share any of the required user data types? (앱에서 필수 사용자 데이터 유형을 수집하거나 공유하나요?) | **No** | 아래 설명 참고 |

- 이 질문에 **No**로 답하면 이후 암호화·삭제 요청 문항은 나오지 않고, 스토어에는 "개발자가 수집하는 데이터 없음 / 제3자와 공유하는 데이터 없음"으로 표시된다.
- **위치**: Play 정의상 "기기 안에서만 처리되고 기기 밖으로 전송되지 않는 데이터"는 수집이 아니다. 위치는 지도 마커와 캠퍼스 자동 전환에만 쓰이고 앱 서버·Firestore로 보내지 않는다.
- **Firestore**: 공개 콘텐츠를 읽기만 하며 사용자 식별자·기기 ID를 쓰지 않는다. 요청 시 IP 주소가 전송되지만 Play 양식의 필수 데이터 유형 목록에는 IP가 독립 항목으로 없고, 통신 자체에 필요한 범위다.
- **Kakao 지도**: 지도 타일·SDK 요청이 Kakao로 가는 것은 지도 표시를 위한 일반 네트워크 요청이다.
- **즐겨찾기·설정**: 기기 로컬 저장, 백업 비활성화.

> **불확실 / 보수적 대안**: "내 위치"로 지도를 이동하면 그 주변 타일이 Kakao에 요청되므로 대략적 위치가 간접적으로 드러난다고 볼 여지가 있다. 심사에서 지적되면 아래처럼 바꾼다.
> - 수집: **위치 > 대략적인 위치(Approximate location)** — Collected: Yes / Shared: No(서비스 제공업체 처리이므로 "공유" 아님) / Processed ephemerally: **Yes** / Required or optional: **Optional**(권한 거부 시에도 앱 사용 가능) / Purpose: **App functionality**
> - 데이터 전송 시 암호화: **Yes**(HTTPS 전용, cleartext 차단) / 삭제 요청 방법: 저장하지 않으므로 해당 없음 → 개인정보처리방침에 명시
> - 이 경우 개인정보처리방침에도 "지도 제공을 위해 Kakao에 지도 요청이 전송됨"을 적어 두어야 일관성이 맞다(현재 방침 문구 확인 필요).

**출시 전 직접 확인할 것**
- 병합된 매니페스트(`build/app/intermediates/merged_manifests/...`)에 `com.google.android.gms.permission.AD_ID`가 없는지. 있으면 "광고 ID" 선언이 필요하다.
- Firebase SDK가 Installations/측정 모듈을 끌어오지 않는지(현재 의존성상으로는 없음).

### 3-2. 관련 선언

| 항목 | 답변 |
|---|---|
| 광고 ID(Advertising ID) 사용 | **No** (광고·분석 SDK 없음, 위 매니페스트 확인 전제) |
| 위치 권한(백그라운드) 선언 | 해당 없음 — 포그라운드 전용이라 별도 양식 불필요 |
| 민감한 권한(SMS·통화기록·모든 파일 접근 등) | 해당 없음 |

---

## 4. 앱 콘텐츠 섹션

### 4-1. 앱 액세스 권한 (App access)
- **All functionality in my app is available without any access restrictions** (모든 기능을 제한 없이 이용 가능) — 로그인·회원가입·지역 제한 없음. 테스트 계정 불필요.
- 참고: 위치 권한을 거부해도 지도·검색·가이드 모두 사용 가능하다는 점을 심사 메모에 적어도 된다.

### 4-2. 광고 (Ads)
- **No, my app does not contain ads**

### 4-3. 콘텐츠 등급 (IARC 설문)

| 질문 | 답변 |
|---|---|
| 이메일 | donga.campus.on@gmail.com |
| 카테고리 | **Reference, News, or Educational** (참고자료·뉴스·교육) |
| 폭력 / 성적 콘텐츠 / 욕설 / 공포 | 모두 No |
| 규제 약물(마약·알코올·담배) 묘사·언급 | No (학식 메뉴에 주류 없음) |
| 도박 / 모의 도박 | No |
| 사용자 간 상호작용·소통(채팅, UGC 공유) | No |
| 사용자 위치를 다른 사용자와 공유 | No (위치는 기기 내 지도 표시만) |
| 디지털 상품 구매 | No |
| 제한 없는 인터넷 접근(앱 내 웹 브라우저) | No — 지도 WebView는 Kakao 지도 전용, 외부 링크는 시스템 브라우저로 열림 |
| 행정 가이드의 긴급연락처·사건사고 안내 | 정보 제공일 뿐 폭력 묘사 아님 |

예상 등급: **GRAC 전체이용가 / ESRB Everyone / PEGI 3 / USK 0**

### 4-4. 타겟층 및 콘텐츠 (Target audience and content)
- 타겟 연령대: **18세 이상(18 and over)** 만 선택 — 대학 재학생 대상. 13세 미만을 고르지 않으므로 가족 정책(Families) 대상이 아니다.
- "아동의 관심을 끌 수 있는 앱인가?" → **No**
- 스토어 등록정보에 아동 대상 표현 없음.

### 4-5. 기타 선언

| 항목 | 답변 |
|---|---|
| 뉴스 앱 여부 (News apps) | **No** |
| 정부 앱 여부 (Government apps) | **No** (정부·공공기관 개발/대행 아님) |
| 금융 기능 (Financial features) | **My app doesn't provide any financial features** (은행 가이드는 정보 제공만) |
| 건강 앱 (Health apps) | **해당 없음** — 건강보험·병원 안내는 정보 제공이며 건강 기능 아님 |
| 코로나19 관련 앱 | No |
| 데이터 보안 | 3장 참고 |
| 개인정보처리방침 | https://ljw092601.github.io/Campus-on/privacy/ |

---

## 5. 그래픽 에셋 체크리스트

| 에셋 | Play 규격 | 현재 상태 | 할 일 |
|---|---|---|---|
| 앱 아이콘 | 512×512, 32비트 PNG(알파 허용), ≤1MB | 루트 `donga-mate-icon.png` = 582×582 RGBA, 약 395KB | 512×512로 리사이즈. Play가 모서리 라운드·그림자를 자동 적용하므로 원본에 넣지 말 것 |
| 그래픽 이미지(Feature graphic) | 1024×500, JPEG 또는 24비트 PNG(**알파 없음**), ≤15MB | 없음. 루트 `donga-mate.png`(1254×1254 RGB)는 소스로만 활용 가능 | 브랜드 색 배경 + 로고 + "유학생 캠퍼스 가이드" 한 줄. 좌우 가장자리에 핵심 요소 배치 금지(잘림) |
| 휴대전화 스크린샷 | 2~8장, PNG/JPEG, 각 변 320~3840px, 긴 변 ≤ 짧은 변×2. 추천 노출용은 1080px 이상 | gh-pages `presentation/img/*.png` = 390×844(비율 2.16 → **규격 초과**, 해상도 부족) | 에뮬레이터/실기기에서 1080×1920 또는 1080×2160으로 새로 캡처. 기존 이미지는 구도 참고용 |
| 7·10인치 태블릿 스크린샷 | 선택 | 없음 | 생략 가능(태블릿 레이아웃 최적화 전까지) |
| 홍보 동영상 | 선택(YouTube URL) | 없음 | 생략 |

### 5-1. 스크린샷 구성안 (언어별 캡션)

캡션은 상단 텍스트 + 하단 앱 화면 구성. 언어별로 같은 화면을 해당 언어 UI로 캡처한다(설정 > 언어 변경 후 캡처).

| 순서 | 화면 (참고 이미지) | ko | en | zh-CN | vi |
|---|---|---|---|---|---|
| 1 | 홈 (`home.png`) | 유학생 캠퍼스 생활, 한 앱으로 | Campus life made easy | 留学生校园生活，一个应用搞定 | Đời sống du học trong một ứng dụng |
| 2 | 캠퍼스 지도 (`map.png`, `map_peek.png`) | 건물·편의시설을 지도에서 바로 | Every building on one map | 建筑和设施一图看清 | Mọi tòa nhà trên một bản đồ |
| 3 | 강의실 찾기 (`classroom_highlight.png`) | 강의실 번호만 입력하면 끝 | Type a room number, find it | 输入教室编号即可找到 | Nhập số phòng là tìm thấy |
| 4 | 층별 안내 (`building.png`) | 처음 가는 건물도 층별로 | Floor-by-floor building guide | 楼层指南，不再迷路 | Hướng dẫn từng tầng |
| 5 | 행정 가이드 (`guide.png`) | 비자·외국인등록 단계별 안내 | Visa & ARC, step by step | 签证与外国人登录分步指南 | Visa và thẻ cư trú từng bước |
| 6 | 학사일정 (`calendar.png`) | 수강신청·시험 일정 놓치지 않게 | Never miss registration or exams | 选课、考试日程不错过 | Không lỡ lịch đăng ký, lịch thi |
| 7 | 오늘의 학식 (`dining.png`) | 오늘 학식 메뉴·가격·시간 | Today's menus, prices & hours | 今日学生餐菜单·价格·时间 | Thực đơn, giá, giờ mở cửa hôm nay |
| 8 | 설정 (`settings.png`) | 4개 언어 · 다크 모드 지원 | 4 languages & dark mode | 支持4种语言和深色模式 | 4 ngôn ngữ và chế độ tối |

- 실제 데이터로 캡처(가짜 메뉴·일정 금지). 내 위치 마커가 찍힌 캡처는 실제 위치 노출에 주의.
- 학교 로고·엠블럼이 화면에 보이면 승인 없이는 가리거나 빼는 것이 안전하다.

---

## 6. 출시 체크리스트

### 6-1. 계정·테스트 요건 (개인 개발자 계정)
- [ ] 개발자 계정 본인 인증(신원·연락처) 완료
- [ ] **비공개 테스트(Closed testing) 트랙에서 테스터 12명 이상이 14일 연속 옵트인** 유지 (2023-11-13 이후 생성된 개인 계정의 프로덕션 신청 요건)
  - 테스터 이메일 목록(Google 그룹 또는 이메일 리스트) 준비, 옵트인 링크 배포, 14일 동안 탈퇴하지 않도록 안내
  - 기간 중 피드백 반영 업데이트를 1~2회 올려 두면 프로덕션 신청 설문 답변에 유리
- [ ] 14일 경과 후 **프로덕션 액세스 신청**(테스트 방식·피드백·출시 준비 설문) → 승인 후 프로덕션 출시
- [ ] 선택: 그 전에 내부 테스트(Internal testing) 트랙으로 빌드 동작 먼저 확인

### 6-2. 빌드
- [ ] `pubspec.yaml` 버전 `0.2.0+2` → **`1.0.0+N`** (N = versionCode, 업로드할 때마다 반드시 이전보다 큰 정수. 예: 첫 업로드 `1.0.0+3`)
- [ ] **릴리스 서명 설정**: 현재 `android/app/build.gradle.kts`의 release가 `signingConfigs.getByName("debug")` → 업로드 키(`upload-keystore.jks` + `key.properties`, 저장소에 커밋 금지)로 교체해야 Play 업로드 가능
- [ ] **AAB 빌드**: `flutter build appbundle --release --dart-define=...`(카카오 JS 키 등 dart-define 전부 포함). APK가 아닌 `.aab` 업로드
- [ ] **Play App Signing** 사용(신규 앱 기본값). 업로드 키 분실 시 Console에서 재설정 가능하도록 키 백업
- [ ] 카카오 JS 키는 WebView origin `https://localhost` 기준이라 Play 앱 서명 키 해시 등록은 불필요 — 단, 릴리스 빌드에서 지도 로딩 실제 확인
- [ ] targetSdk가 Play의 현행 요구 수준 이상인지 확인(Flutter 기본값 사용 중. 2026년 기준 요구 API 레벨은 Console 안내로 재확인)
- [ ] 난독화/축소(R8) 사용 시 Kakao·Firestore 동작 회귀 테스트

### 6-3. 등록정보·정책
- [ ] 4개 언어 등록정보 입력(1장), 글자 수 Console 카운터로 재확인
- [ ] 아이콘 512, 그래픽 이미지 1024×500, 언어별 스크린샷 2~8장(5장)
- [ ] 데이터 보안 양식(3장)과 개인정보처리방침 내용 일치 확인 — 특히 위치·Kakao 관련 문구
- [ ] 개인정보처리방침 URL이 로그인 없이 열리고 PDF가 아닌 웹페이지인지 확인
- [ ] 콘텐츠 등급·타겟층·광고·앱 액세스·뉴스/정부/금융/건강 선언 완료(4장)
- [ ] 비공식 고지 문구 포함 확인(대학 승인 시 제거)
- [ ] 학교 로고·상표가 아이콘/그래픽/스크린샷에 들어가지 않았는지 확인

### 6-4. 기능 확인 (QA 전달용)
- [ ] 위치 권한 허용/거부/영구 거부 각각에서 크래시 없이 동작(거부 시 안내 스낵바)
- [ ] 오프라인·약한 네트워크에서 캐시된 콘텐츠 표시
- [ ] 4개 언어 전환, 라이트/다크/시스템 테마
- [ ] 개인정보처리방침·외부 링크가 깨지지 않음
- [ ] 강의실 번호 검색(예: 0301) 결과 표시

### 6-5. 출시 전략
- 첫 버전: **1.0.0**
- 트랙: 내부 테스트 → 비공개 테스트(12명·14일) → 프로덕션
- 프로덕션 단계적 출시: 20% → 50% → 100% (사용자 수가 적은 초기 앱이라 이틀 간격, 비정상 종료·ANR 지표 확인 후 확대)
- 출시 시점: 학기 시작·신입 유학생 입국 시기(2월말, 8월말) 직전 권장
