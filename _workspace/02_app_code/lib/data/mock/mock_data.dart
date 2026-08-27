import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/building_floors.dart';
import '../../domain/entities/facility.dart';
import 'building_data.g.dart';

/// In-app fixture data. Facilities/floors are the REAL Dong-A buildings
/// generated from the official campus map (building_data.g.dart — regenerate
/// via tool/floor_guide_parser/, never hand-edit). Guide items remain
/// hand-authored here. The Firestore seed is exported from this class
/// (tool/firestore_seed/export_seed_test.dart) so seed and app can't drift.
class MockData {
  const MockData._();

  /// 48 real campus buildings (승학 24 · 구덕 15 · 부민 9).
  static List<Facility> get facilities => BuildingData.facilities;

  /// Floor-by-floor guides for the 34 buildings that have them (249 floors).
  static List<BuildingFloors> get buildingFloors => BuildingData.floors;

  static final List<AdminGuideItem> guideItems = [
    // ── 입국·체류 (immigration) ──
    // Fully-published exemplar: exercises every S7 section so the template is
    // demonstrable end-to-end. All other items stay `comingSoon` placeholders
    // per the "틀 우선(structure-first)" scope.
    const AdminGuideItem(
      id: 'arc-issue',
      categoryId: GuideCategory.immigration,
      titleKo: '외국인등록증(ARC) 발급',
      titleEn: 'Alien Registration Card (ARC)',
      summaryKo: '입국 90일 이내 신청',
      summaryEn: 'Apply within 90 days of entry',
      overviewKo: '외국인등록증은 국내 체류·은행·통신 등 대부분의 생활 절차에 필요한 '
          '기본 신분증입니다. 입국 후 90일 이내에 신청해야 합니다.',
      overviewEn: 'The ARC is the core ID needed for most everyday procedures in '
          'Korea (banking, mobile plans, and more). Apply within 90 days of entry.',
      checklistKo: [
        '여권',
        '표준규격 증명사진 1매 (3.5×4.5cm)',
        '수수료 3만원',
        '재학증명서 또는 표준입학허가서',
      ],
      checklistEn: [
        'Passport',
        'One standard ID photo (3.5×4.5cm)',
        'Fee: KRW 30,000',
        'Certificate of enrollment or admission',
      ],
      stepsKo: [
        '하이코리아(hikorea.go.kr)에서 방문 예약',
        '관할 출입국·외국인청 방문 및 신청서 제출',
        '수수료 납부 후 접수증 수령',
        '약 2–3주 후 등록증 수령(우편 또는 방문)',
      ],
      stepsEn: [
        'Book a visit on HiKorea (hikorea.go.kr)',
        'Visit the immigration office and submit the application',
        'Pay the fee and receive the receipt',
        'Pick up the card in about 2–3 weeks (mail or in person)',
      ],
      links: [
        GuideLink(
          labelKo: '하이코리아 방문 예약',
          labelEn: 'HiKorea reservation',
          url: 'https://www.hikorea.go.kr',
        ),
      ],
      // b04 = 종합강의동(부민) — 국제교류과가 1F에 위치.
      relatedFacilityIds: ['b04'],
      durationKo: '예상 2–3주',
      durationEn: 'Approx. 2–3 weeks',
      difficulty: 2,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'stay-extension',
      categoryId: GuideCategory.immigration,
      titleKo: '체류기간 연장',
      titleEn: 'Extension of Stay',
      summaryKo: '신청 시기 · 준비서류 · 연장 방법',
      summaryEn: 'When to apply, required documents & process',
      iconName: 'event_repeat',
      overviewKo: '현재 허가받은 체류기간을 넘어서 한국에 계속 머무르려면 체류기간이 끝나기 전에 '
          '체류기간 연장 허가를 받아야 합니다.\n\n'
          '유학생은 본인의 체류자격(D-2, D-4 등)과 개인 상황에 따라 필요한 서류와 연장 가능 '
          '기간이 달라질 수 있습니다.\n\n'
          '체류기간이 만료되기 전에 필요한 서류와 신청 방법을 미리 확인하는 것이 중요합니다.',
      overviewEn: 'To keep living in Korea beyond the stay period you were '
          'granted, you need an extension of stay — and you have to get it '
          'before the current period ends.\n\n'
          'For students, the documents you need and how long you can extend for '
          'depend on your status of stay (D-2, D-4, and so on) and on your own '
          'situation.\n\n'
          'Check what you need and how to apply well before your stay period '
          'expires.',
      // Placed above the checklist: what you have to know first is the window
      // you can apply in, not the paperwork.
      topSections: [
        GuideSection(
          titleKo: '언제 신청해야 하나요?',
          titleEn: 'When should I apply?',
          iconName: 'event_repeat',
          bodyKo: '체류기간 연장은 현재 체류기간 만료 4개월 전부터 만료일까지 신청할 수 '
              '있습니다.\n\n'
              '외국인등록증에 표시된 체류기간 만료일을 미리 확인하고 여유 있게 준비하세요.',
          bodyEn: 'You can apply from four months before your current stay '
              'period expires, up to the expiry date itself.\n\n'
              'Check the expiry date printed on your Residence Card (ARC) and '
              'give yourself plenty of time to get ready.',
          noticeKo: '체류기간 만료 전에 신청하세요.\n'
              '체류기간이 만료된 뒤 연장을 신청하면 범칙금 등 불이익이 발생할 수 있습니다.',
          noticeEn: 'Apply before your current stay period expires.\n'
              'Applying after the expiry date can result in a fine and other '
              'penalties.',
        ),
      ],
      checklistKo: [
        '여권',
        '외국인등록증(Residence Card / ARC)',
        '체류기간 연장허가 신청서',
        '수수료',
      ],
      checklistEn: [
        'Passport',
        'Residence Card (ARC)',
        'Application form for extension of stay',
        'The application fee',
      ],
      checklistOptionalTitleKo: '체류자격과 상황에 따라 필요할 수 있어요',
      checklistOptionalTitleEn: 'You may also need these depending on your visa '
          'and situation',
      checklistOptionalKo: [
        '재학증명서',
        '성적증명서',
        '등록금 납입 관련 증명서',
        '체류지 입증서류',
        '재정능력 입증서류',
        '기타 체류자격별 추가서류',
      ],
      checklistOptionalEn: [
        'Certificate of enrollment',
        'Academic transcript',
        'Proof of tuition payment',
        'Proof of where you live in Korea',
        'Proof that you can support yourself financially',
        'Any other document your status of stay calls for',
      ],
      checklistNoteKo: '※ 필요한 서류는 D-2, D-4 등 체류자격과 개인 상황에 따라 달라질 수 '
          '있습니다. 신청 전에 HiKorea 또는 학교 국제교류 관련 부서에서 최신 서류를 확인하세요.',
      checklistNoteEn: '※ Which documents you need depends on your status of '
          'stay (D-2, D-4, and so on) and on your own situation. Check the '
          'current list on HiKorea, or with your university\'s international '
          'office, before you apply.',
      sections: [
        GuideSection(
          titleKo: '신청 방법',
          titleEn: 'How to apply',
          iconName: 'format_list_numbered',
          stepsKo: [
            '외국인등록증에서 체류기간 만료일 확인',
            '본인의 체류자격(D-2 / D-4 등) 확인',
            'HiKorea 또는 학교에서 필요한 서류 확인',
            '필요한 서류 준비',
            'HiKorea 전자민원 또는 관할 출입국·외국인관서에서 신청',
            '심사 진행 및 결과 확인',
            '연장된 체류기간 확인',
          ],
          stepsEn: [
            'Check the expiry date on your Residence Card',
            'Check your status of stay (D-2, D-4, etc.)',
            'Check the required documents on HiKorea or with your school',
            'Get those documents ready',
            'Apply on HiKorea e-Application or at your immigration office',
            'Wait for the review and check the result',
            'Confirm your new stay period',
          ],
        ),
        GuideSection(
          titleKo: 'HiKorea 전자민원',
          titleEn: 'HiKorea e-Application',
          iconName: 'computer',
          bodyKo: '일부 체류기간 연장 업무는 HiKorea 전자민원을 통해 온라인으로 신청할 수 '
              '있습니다.',
          bodyEn: 'Some extension-of-stay applications can be submitted online '
              'through HiKorea e-Application.',
          noticeKo: '온라인 신청 가능 여부와 제출서류는 체류자격 및 신청 상황에 따라 달라질 수 '
              '있으므로 신청 전에 확인하세요.',
          noticeEn: 'Whether you can apply online — and which documents you have '
              'to submit — depends on your status of stay and your situation, so '
              'check before you start.',
        ),
        GuideSection(
          titleKo: '서류는 학생마다 다를 수 있습니다',
          titleEn: 'The documents differ from student to student',
          iconName: 'help',
          bodyKo: '인터넷에 있는 다른 학생의 준비서류를 그대로 따라가기보다 본인의 체류자격과 '
              '현재 상황에 맞는 서류를 확인하세요.',
          bodyEn: "Rather than copying another student's document list from the "
              'internet, check what your own status of stay and current '
              'situation actually require.',
          // 1345 is shown as text: the app has no tel: launch path yet, and this
          // guide is not the place to add one.
          noticeKo: '최신 정보는 HiKorea 또는 외국인종합안내센터 1345에서 확인할 수 있습니다.',
          noticeEn: 'For the latest information, check HiKorea or call the '
              'Immigration Contact Center at 1345.',
        ),
        GuideSection(
          titleKo: '알아두면 좋은 점',
          titleEn: 'Good to know',
          iconName: 'lightbulb',
          notes: [
            GuideNote(
              titleKo: '📅 미리 준비하세요',
              titleEn: '📅 Start early',
              linesKo: [
                '체류기간 만료 직전에 준비하기보다 미리 필요한 서류를 확인하고 신청하는 것이 '
                    '좋습니다.',
              ],
              linesEn: [
                'Check the documents and apply ahead of time rather than right '
                    'before your stay period ends.',
              ],
            ),
            GuideNote(
              titleKo: '🏠 주소가 바뀌었다면 확인하세요',
              titleEn: '🏠 If your address has changed',
              linesKo: [
                '한국에서 체류지가 변경되었다면 체류지 변경 신고가 필요한지 확인하세요.',
                '체류기간 연장 과정에서 현재 체류지를 증명하는 서류가 필요할 수 있습니다.',
              ],
              linesEn: [
                'If you have moved within Korea, check whether you need to '
                    'report the change of address.',
                'You may be asked for a document proving where you currently '
                    'live.',
              ],
            ),
            GuideNote(
              titleKo: '✈️ 해외 출국 계획이 있다면 확인하세요',
              titleEn: '✈️ If you are planning to travel abroad',
              linesKo: [
                '체류기간 연장 신청 전후로 해외 출국 계획이 있다면 출입국·외국인관서 또는 '
                    '외국인종합안내센터에서 절차를 미리 확인하는 것이 좋습니다.',
              ],
              linesEn: [
                'If you plan to leave Korea around the time you apply, check the '
                    'procedure in advance with your immigration office or the '
                    'Immigration Contact Center.',
              ],
            ),
            GuideNote(
              titleKo: '🎓 D-2 / D-4라도 조건이 같지 않아요',
              titleEn: '🎓 D-2 and D-4 are not the same',
              linesKo: [
                '같은 유학생이라도 학위과정, 어학연수, 체류자격 세부 유형에 따라 연장 조건과 '
                    '필요서류가 달라질 수 있습니다.',
              ],
              linesEn: [
                'Even among students, the conditions and documents can differ '
                    'between degree programs, language courses, and the '
                    'sub-types of each status.',
              ],
            ),
            GuideNote(
              titleKo: '🪪 연장 후 체류기간 확인',
              titleEn: '🪪 Check your new stay period',
              linesKo: [
                '연장 허가가 완료되면 변경된 체류기간이 정상적으로 반영되었는지 확인하세요.',
              ],
              linesEn: [
                'Once the extension is granted, make sure the new stay period is '
                    'reflected correctly.',
              ],
            ),
          ],
        ),
      ],
      links: [
        // Official 출입국/체류안내 → 체류기간연장 → 체류기간연장허가 절차/방법 page: the
        // 4-months-before window, the fine after expiry, and where to apply.
        GuideLink(
          labelKo: 'HiKorea 체류기간 연장 안내',
          labelEn: 'HiKorea — extension of stay',
          descriptionKo: '신청 시기 · 절차 · 체류자격별 안내',
          descriptionEn: 'When to apply, the procedure, and per-status guidance',
          url: 'https://www.hikorea.go.kr/info/InfoDatail.pt'
              '?CAT_SEQ=181&PARENT_ID=140',
        ),
        GuideLink(
          labelKo: 'HiKorea 전자민원',
          labelEn: 'HiKorea e-Application',
          descriptionKo: '온라인 민원 신청',
          descriptionEn: 'Apply online',
          url: 'https://www.hikorea.go.kr/cvlappl/CvlapplInfoPageR.pt',
          iconName: 'computer',
        ),
        // Study in Korea (NIIED, Ministry of Education); anchored at the
        // stay-extension block of the residence & stay page.
        GuideLink(
          labelKo: 'Study in Korea 체류 안내',
          labelEn: 'Study in Korea — residence & stay',
          descriptionKo: '유학생 비자 · 체류기간 관련 정보',
          descriptionEn: 'Visa and stay information for international students',
          url: 'https://www.studyinkorea.go.kr/eng/life/residenceAndStayInfo.do'
              '#stay-extension',
        ),
      ],
      durationKo: '서류 준비 + 심사 기간 별도',
      durationEn: 'Document prep + review time',
      difficulty: 2,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'visa-types',
      categoryId: GuideCategory.immigration,
      titleKo: '비자 종류 안내',
      titleEn: 'Visa Types',
      summaryKo: 'D-2 / D-4 차이',
      summaryEn: 'D-2 vs. D-4',
      overviewKo: '한국에서 공부하려는 외국인 학생은 본인의 학업 형태에 맞는 체류자격과 비자를 '
          '준비해야 합니다.\n\n'
          '동아대학교 외국인 학생에게 가장 관련이 큰 체류자격은 유학(D-2)과 일반연수(D-4)입니다.\n\n'
          'D-2는 주로 학위과정과 교환학생 과정에 참여하는 학생에게, D-4는 한국어연수 등 비학위 '
          '연수과정에 참여하는 학생에게 해당합니다.',
      overviewEn: 'To study in Korea you need the status of stay — and the visa '
          'that goes with it — that matches the kind of study you will be '
          'doing.\n\n'
          'For international students at Dong-A University the two that matter '
          'most are Study Abroad (D-2) and General Training (D-4).\n\n'
          'D-2 is generally for students on a degree or exchange program; D-4 is '
          'for students on a non-degree course such as Korean language training.',
      // The two visa types and the comparison have to land before the document
      // checklist — which of the two you are decides what you prepare.
      topSections: [
        GuideSection(
          titleKo: 'D-2 유학 비자',
          titleEn: 'D-2 Student Visa',
          iconName: 'school',
          bodyKo: 'D-2는 한국의 대학이나 대학원에서 정규 학위과정을 이수하거나 교환학생 등의 '
              '유학 활동을 하는 학생을 위한 체류자격입니다.',
          bodyEn: 'D-2 is the status of stay for students taking a formal degree '
              'program at a Korean university or graduate school, or studying '
              'here on an exchange program.',
          notes: [
            GuideNote(
              titleKo: '대표적인 유형',
              titleEn: 'Common sub-types',
              linesKo: [
                'D-2-2 — 학사과정',
                'D-2-3 — 석사과정',
                'D-2-4 — 박사과정',
                'D-2-6 — 교환학생',
              ],
              linesEn: [
                "D-2-2 — Bachelor's degree",
                "D-2-3 — Master's degree",
                'D-2-4 — Doctoral degree',
                'D-2-6 — Exchange student',
              ],
            ),
          ],
          noticeKo: '이런 학생에게 해당해요\n'
              '동아대학교 학부 · 대학원 · 교환학생 등 정규 교육과정에 참여하는 학생',
          noticeEn: 'Who is this for?\n'
              'Students on a formal Dong-A University program — undergraduate, '
              'graduate, or exchange.',
          noticeIconName: 'info',
          footnoteKo: '이외에도 전문학사, 연구과정 등 다른 D-2 세부 유형이 있으며 실제 '
              '체류자격은 입학 과정에 따라 달라질 수 있습니다.',
          footnoteEn: 'There are other D-2 sub-types as well — associate degree '
              'and research courses among them — and your actual status depends '
              'on the program you were admitted to.',
        ),
        GuideSection(
          titleKo: 'D-4 일반연수 비자',
          titleEn: 'D-4 General Training Visa',
          iconName: 'menu_book',
          bodyKo: 'D-4는 정규 학위과정이 아닌 어학연수나 기타 연수과정에 참여하는 학생을 위한 '
              '체류자격입니다.',
          bodyEn: 'D-4 is the status of stay for students on a language course or '
              'another training course rather than a formal degree program.',
          notes: [
            GuideNote(
              titleKo: '대표적인 유형',
              titleEn: 'Common sub-types',
              linesKo: [
                'D-4-1 — 한국어연수',
                'D-4-2 — 외국어연수',
              ],
              linesEn: [
                'D-4-1 — Korean language training',
                'D-4-2 — Foreign language training',
              ],
            ),
          ],
          noticeKo: '이런 학생에게 해당해요\n'
              '대학 부설 한국어교육기관 등에서 한국어 또는 기타 어학연수를 하는 학생',
          noticeEn: 'Who is this for?\n'
              'Students studying Korean or another language at a '
              'university-affiliated language institute or similar.',
          noticeIconName: 'info',
          footnoteKo: 'D-4에도 여러 세부 유형이 있으므로 실제 비자 종류는 본인이 참여하는 '
              '교육과정과 입학서류를 기준으로 확인하세요.',
          footnoteEn: 'D-4 has several sub-types too, so check your actual visa '
              'against the course you are joining and the documents your school '
              'issued.',
        ),
        // Two stacked note blocks rather than a table — a side-by-side grid
        // would either wrap badly or scroll horizontally at phone widths.
        GuideSection(
          titleKo: 'D-2 / D-4 비교',
          titleEn: 'D-2 vs. D-4 at a glance',
          iconName: 'compare_arrows',
          notes: [
            GuideNote(
              titleKo: 'D-2',
              titleEn: 'D-2',
              linesKo: [
                '학위과정 중심',
                '학부 · 석사 · 박사',
                '교환학생 등 포함',
                '정규 교육과정',
              ],
              linesEn: [
                'Built around degree programs',
                "Bachelor's, master's, doctoral",
                'Includes exchange students',
                'Formal academic programs',
              ],
            ),
            GuideNote(
              titleKo: 'D-4',
              titleEn: 'D-4',
              linesKo: [
                '비학위 연수과정 중심',
                '대표적으로 한국어연수',
                '어학연수 등',
                '연수과정',
              ],
              linesEn: [
                'Built around non-degree courses',
                'Most commonly Korean language training',
                'Language training and similar',
                'Training courses',
              ],
            ),
          ],
          noticeKo: '정규 학위과정 → D-2\n'
              '한국어 등 비학위 연수과정 → D-4',
          noticeEn: 'Degree program → D-2\n'
              'Non-degree training such as Korean language study → D-4',
          noticeIconName: 'lightbulb',
          footnoteKo: '실제 체류자격은 학교에서 발급받은 입학서류와 본인의 교육과정을 기준으로 '
              '확인하세요.',
          footnoteEn: 'Confirm your actual status against the admission documents '
              'your school issued and the course you are really taking.',
        ),
        GuideSection(
          titleKo: '비자 신청 기본 흐름',
          titleEn: 'How applying for a visa usually works',
          iconName: 'format_list_numbered',
          stepsKo: [
            '동아대학교 입학 또는 연수 허가',
            '본인의 과정에 맞는 D-2 / D-4 확인',
            '표준입학허가서 등 필요한 서류 준비',
            '비자 신청에 필요한 추가서류 확인',
            '대한민국 재외공관 등에서 비자 신청',
            '비자 발급 결과 확인',
            '비자 발급 후 한국 입국',
          ],
          stepsEn: [
            'Get admission or training approval from Dong-A University',
            'Check whether your course means D-2 or D-4',
            'Prepare the Certificate of Admission and other documents',
            'Check what extra documents the visa application needs',
            'Apply at a Korean embassy or consulate',
            'Check the result of your application',
            'Enter Korea once the visa has been issued',
          ],
          noticeKo: '신청 방법과 필요서류는 국적, 세부 체류자격, 신청하는 재외공관에 따라 '
              '달라질 수 있습니다.\n'
              '위 흐름은 일반적인 순서이며, 신청 전에 해당 공관의 공식 안내를 확인하세요.',
          noticeEn: 'How you apply, and what you have to submit, can differ by '
              'nationality, by the exact status of stay, and by the mission you '
              'apply to.\n'
              'The steps above are the usual order — check the official guidance '
              'of your own embassy or consulate before you apply.',
        ),
      ],
      checklistKo: [
        '여권',
        '증명사진',
        '표준입학허가서',
        '재정능력 입증서류',
      ],
      checklistEn: [
        'Passport',
        'ID photo',
        'Certificate of Admission',
        'Proof that you can support yourself financially',
      ],
      checklistOptionalTitleKo: '체류자격과 상황에 따라 추가될 수 있어요',
      checklistOptionalTitleEn: 'These may be added depending on your visa and '
          'situation',
      checklistOptionalKo: [
        '최종학력 입증서류',
        '재학 또는 학력 관련 증명서',
        '연수계획서',
        '가족관계 입증서류',
        '결핵검사 관련 서류',
        '기타 체류자격별 추가서류',
      ],
      checklistOptionalEn: [
        'Proof of your highest level of education',
        'Enrollment or academic certificates',
        'A study or training plan',
        'Proof of family relationship',
        'Tuberculosis screening documents',
        'Any other document your status of stay calls for',
      ],
      checklistNoteKo: '※ 실제 필요서류는 D-2 / D-4 세부 유형, 국적, 교육과정, 재외공관 '
          '등에 따라 달라질 수 있습니다. 신청 전에 공식 안내를 확인하세요.',
      checklistNoteEn: '※ The documents you actually need depend on your D-2 / '
          'D-4 sub-type, your nationality, your course, and the mission you '
          'apply to. Check the official guidance before you apply.',
      sections: [
        GuideSection(
          titleKo: '알아두면 좋은 점',
          titleEn: 'Good to know',
          iconName: 'lightbulb',
          notes: [
            GuideNote(
              titleKo: '🪪 비자와 외국인등록증은 달라요',
              titleEn: '🪪 A visa is not a Residence Card',
              linesKo: [
                '비자와 외국인등록증(Residence Card / ARC)은 같은 것이 아닙니다.',
                '한국에서 장기간 체류하는 학생은 입국 후 별도의 외국인등록 절차가 필요할 수 '
                    '있습니다.',
              ],
              linesEn: [
                'A visa and a Residence Card (ARC) are two different things.',
                'If you are staying in Korea long term you may need to register '
                    'as a foreign resident after you arrive.',
              ],
            ),
            GuideNote(
              titleKo: '💼 아르바이트는 자동으로 허용되지 않아요',
              titleEn: '💼 Part-time work is not automatic',
              linesKo: [
                'D-2 또는 D-4 비자를 가지고 있다고 해서 자유롭게 아르바이트를 할 수 있는 '
                    '것은 아닙니다.',
                '학생의 체류자격과 조건에 따라 시간제취업 허가가 필요할 수 있습니다.',
              ],
              linesEn: [
                'Holding a D-2 or D-4 visa does not by itself let you work part '
                    'time.',
                'Depending on your status and its conditions, you may need a '
                    'part-time work permit first.',
              ],
            ),
            GuideNote(
              titleKo: '🔄 교육과정이 바뀌면 확인하세요',
              titleEn: '🔄 If your course changes',
              linesKo: [
                '한국어연수에서 학부과정으로 진학하는 것처럼 학업 형태가 달라지면 현재 '
                    '체류자격이 새로운 활동에 맞는지 확인해야 합니다.',
                '체류자격 변경이 필요한지 HiKorea 또는 학교 국제교류 관련 부서에서 확인하세요.',
              ],
              linesEn: [
                'If the kind of study changes — moving from a Korean language '
                    'course into a degree program, say — check that your current '
                    'status still fits what you will be doing.',
                "Ask HiKorea or your university's international office whether "
                    'you need to change your status of stay.',
              ],
            ),
            GuideNote(
              titleKo: '📅 체류기간도 확인하세요',
              titleEn: '📅 Check your period of stay too',
              linesKo: [
                '비자를 발급받았더라도 한국에서 허가받은 체류기간을 확인하고, 계속 체류해야 '
                    '한다면 만료 전에 연장 절차를 준비하세요.',
              ],
              linesEn: [
                'Even once your visa is issued, check the stay period you were '
                    'granted — and if you need to stay longer, start the '
                    'extension before it expires.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '내 비자를 정확히 확인하세요',
          titleEn: 'Check your exact visa status',
          iconName: 'help',
          bodyKo: '친구나 다른 학생의 비자 종류를 기준으로 판단하지 말고 본인의 여권, '
              '사증발급 내용, 외국인등록정보 또는 학교에서 받은 서류를 확인하세요.',
          bodyEn: 'Do not go by what a friend or another student has. Check your '
              'own passport, the visa that was issued to you, your '
              'foreign-resident record, or the documents your school gave you.',
          noticeKo: '세부 체류자격과 필요한 절차는 학생마다 다를 수 있습니다.',
          noticeEn: 'The exact status of stay — and the steps that go with it — '
              'can differ from student to student.',
        ),
      ],
      links: [
        // Study in Korea (NIIED, Ministry of Education) — "학생비자 및 체류자격";
        // names the same D-2/D-4 sub-types listed above.
        GuideLink(
          labelKo: 'Study in Korea 비자 · 체류 안내',
          labelEn: 'Study in Korea — student visa & stay',
          descriptionKo: 'D-2 · D-4 종류와 유학생 체류정보',
          descriptionEn: 'D-2 and D-4 types, plus stay information for students',
          url: 'https://www.studyinkorea.go.kr/eng/plan/visaAndStay.do',
        ),
        // Korea Visa Portal (법무부) — the Visa Navigator, which filters visa
        // types by purpose of entry and length of stay.
        GuideLink(
          labelKo: 'Korea Visa Portal',
          labelEn: 'Korea Visa Portal',
          descriptionKo: '대한민국 비자 공식 정보 · 비자 내비게이터',
          descriptionEn: 'Official Korean visa information & Visa Navigator',
          url: 'https://www.visa.go.kr/openPage.do?MENU_ID=10101',
        ),
        // HiKorea 출입국/체류안내 → 사증(VISA): what a visa is, how it is issued,
        // fees, and the per-status issuance manual.
        GuideLink(
          labelKo: 'HiKorea 사증(비자) 안내',
          labelEn: 'HiKorea — visas (사증)',
          descriptionKo: '사증의 의미 · 발급절차 · 체류자격별 안내',
          descriptionEn: 'What a visa is, how it is issued, and per-status '
              'guidance',
          url: 'https://www.hikorea.go.kr/info/InfoDatail.pt'
              '?CAT_SEQ=144&PARENT_ID=11',
        ),
        // In-app: the two guides this page keeps pointing at. Same `/`-prefixed
        // internal-route convention the map links use (_LinkRow._isInternal).
        GuideLink(
          labelKo: '외국인등록증(ARC) 발급 안내',
          labelEn: 'Guide — Alien Registration Card (ARC)',
          descriptionKo: '앱 안에서 바로 보기',
          descriptionEn: 'Open the in-app guide',
          url: '/guide/item/arc-issue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '체류기간 연장 안내',
          labelEn: 'Guide — Extension of Stay',
          descriptionKo: '앱 안에서 바로 보기',
          descriptionEn: 'Open the in-app guide',
          url: '/guide/item/stay-extension',
          iconName: 'event_repeat',
        ),
      ],
      durationKo: '예상 5~10분',
      durationEn: 'Approx. 5–10 min',
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // ── 주거 (housing) ──
    const AdminGuideItem(
      id: 'dormitory',
      categoryId: GuideCategory.housing,
      titleKo: '기숙사 신청',
      titleEn: 'Dormitory Application',
      summaryKo: '학기별 신청 일정 확인',
      summaryEn: 'Check the per-semester schedule',
    ),
    const AdminGuideItem(
      id: 'off-campus-housing',
      categoryId: GuideCategory.housing,
      titleKo: '교외 주거 구하기',
      titleEn: 'Off-campus Housing',
      summaryKo: '원룸·하숙·보증금 안내',
      summaryEn: 'Studios, boarding, deposits',
    ),

    // ── 생활 인프라 (living) ──
    const AdminGuideItem(
      id: 'bank-account',
      categoryId: GuideCategory.living,
      titleKo: '은행 계좌 개설',
      titleEn: 'Open a Bank Account',
      summaryKo: '여권·외국인등록증 지참',
      summaryEn: 'Bring passport & ARC',
      iconName: 'account_balance',
      overviewKo: '은행 계좌는 은행 지점 방문을 통해 개설하는 것이 가장 일반적입니다. '
          '일부 은행은 모바일 앱을 통한 비대면 계좌 개설도 지원할 수 있으나, '
          '외국인등록증, 본인 명의 휴대폰, 모바일 외국인등록증 등 조건이 필요할 수 있습니다. '
          '은행마다 가능 여부와 필요 서류가 다르므로 방문 또는 신청 전 확인하는 것이 좋습니다.',
      overviewEn: 'Opening an account in person at a bank branch is the most common '
          'route. Some banks also offer app-based (non-face-to-face) account '
          'opening, but this may require an ARC, a phone number registered in '
          'your own name, or a mobile ARC. Availability and required documents '
          'differ by bank, so check before you visit or apply.',
      checklistKo: [
        '여권',
        '외국인등록증(ARC)',
        '학생증 또는 재학증명서',
        '체류지 확인 서류: 기숙사 확인서, 임대차계약서 등',
        '본인 명의 휴대폰 번호',
        '금융거래 목적 확인 서류: 재학증명서, 등록금 납부 관련 서류 등',
      ],
      checklistEn: [
        'Passport',
        'Alien Registration Card (ARC)',
        'Student ID or certificate of enrollment',
        'Proof of residence: dormitory confirmation, lease contract, etc.',
        'A phone number registered in your own name',
        'Proof of purpose for banking: certificate of enrollment, tuition '
            'payment documents, etc.',
      ],
      checklistNoteKo: '※ 은행마다 요구하는 서류가 다를 수 있으므로 방문 전 은행에 확인하는 것이 좋습니다.',
      checklistNoteEn: '※ Required documents vary by bank — check with the branch '
          'before your visit.',
      stepsKo: [
        '가까운 은행 방문',
        '번호표 발급 후 대기',
        '은행 직원에게 계좌 개설 요청',
        '신분증 및 필요 서류 제출',
        '신청서 작성',
        '통장, 체크카드, 인터넷뱅킹 또는 모바일뱅킹 신청',
      ],
      stepsEn: [
        'Visit a nearby bank branch',
        'Take a queue ticket and wait',
        'Tell the teller you want to open an account',
        'Submit your ID and the required documents',
        'Fill in the application form',
        'Request a bankbook, check card, and internet or mobile banking',
      ],
      tipsKo: [
        '일반적인 은행 영업시간은 평일 오전 9시부터 오후 4시까지입니다.',
        '외국인등록증이 없으면 일부 은행에서 계좌 개설이 제한될 수 있습니다.',
        '금융거래 목적을 증명하기 어려운 경우 한도제한계좌로 개설될 수 있습니다.',
        '한도제한계좌는 이체나 출금 한도가 제한될 수 있습니다.',
        '인터넷뱅킹과 모바일뱅킹을 함께 신청하면 송금과 잔액 확인이 편리합니다.',
        '해외송금은 은행마다 수수료와 환율이 다를 수 있으므로 비교 후 이용하는 것이 좋습니다.',
      ],
      tipsEn: [
        'Banks are usually open 09:00–16:00 on weekdays.',
        'Without an ARC, some banks may restrict account opening.',
        'If the purpose of banking is hard to prove, you may receive a '
            'limited-transaction account.',
        'A limited-transaction account can cap transfers and withdrawals.',
        'Applying for internet and mobile banking together makes transfers and '
            'balance checks easier.',
        'Overseas remittance fees and exchange rates differ by bank — compare '
            'before you send money.',
      ],
      phrases: [
        GuidePhrase(
          ko: '은행 계좌를 만들고 싶습니다.',
          en: 'I would like to open a bank account.',
        ),
      ],
      durationKo: '예상 30분~1시간',
      durationEn: 'Approx. 30 min – 1 hour',
      difficulty: 2,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'mobile-plan',
      categoryId: GuideCategory.living,
      titleKo: '휴대폰 개통',
      titleEn: 'Get a Mobile Plan',
      summaryKo: '선불·후불 요금제와 개통 방법',
      summaryEn: 'Prepaid vs. postpaid, and how to sign up',
      iconName: 'sim_card',
      overviewKo: '한국에서 은행, 배달앱, 온라인 쇼핑 등 다양한 서비스를 이용하려면 '
          '한국 휴대폰 번호가 있으면 편리합니다.\n\n'
          '외국인은 통신사 대리점이나 지점을 방문하여 개통하는 방법이 가장 간단합니다. '
          '일부 통신사와 알뜰폰은 온라인 개통도 지원하지만, 외국인은 본인확인 방법이나 '
          '체류자격에 따라 이용이 제한될 수 있습니다.\n\n'
          '처음 휴대폰을 개통하는 외국인 학생은 필요한 서류를 확인한 후 통신사 매장을 '
          '방문하는 것을 권장합니다.',
      overviewEn: 'A Korean mobile number makes everyday services — banking, '
          'delivery apps, online shopping — much easier to use.\n\n'
          'For foreign residents the simplest route is to sign up in person at a '
          'carrier store or branch. Some carriers and budget (MVNO) operators '
          'also support online sign-up, but identity verification and your visa '
          'status can limit what is available to you.\n\n'
          'If this is your first Korean line, check which documents you need and '
          'then visit a carrier store.',
      checklistKo: [
        '외국인등록증(ARC / Residence Card)',
        '여권',
        '사용할 휴대폰',
        '요금 납부를 위한 결제수단',
      ],
      checklistEn: [
        'Alien Registration Card (ARC / Residence Card)',
        'Passport',
        'The phone you will use',
        'A payment method for your bill',
      ],
      checklistOptionalKo: [
        '한국 주소',
        '본인 명의 은행계좌 또는 카드',
        '학생증 또는 재학증명서',
      ],
      checklistOptionalEn: [
        'A Korean address',
        'A bank account or card in your own name',
        'Student ID or certificate of enrollment',
      ],
      checklistNoteKo: '※ 필요한 서류와 결제 방법은 통신사, 요금제, 체류자격에 따라 '
          '달라질 수 있으므로 방문 전에 확인하세요.',
      checklistNoteEn: '※ Required documents and payment methods vary by carrier, '
          'plan, and visa status — check before you visit.',
      stepsKo: [
        'SKT · KT · LG U+ 또는 알뜰폰 요금제 비교',
        '선불 또는 후불 요금제 선택',
        '필요한 신분증과 서류 준비',
        '통신사 매장 방문 및 가입 신청',
        'USIM 또는 eSIM 개통',
        '전화 · 문자 · 데이터 정상 작동 확인',
        '필요한 경우 휴대폰 본인인증 가능 여부 확인',
      ],
      stepsEn: [
        'Compare plans from SKT, KT, LG U+, or a budget (MVNO) operator',
        'Choose a prepaid or a postpaid plan',
        'Prepare the ID and documents you need',
        'Visit a carrier store and apply',
        'Activate a USIM or eSIM',
        'Check that calls, texts, and data all work',
        'If you need it, check whether phone identity verification works',
      ],
      sections: [
        // Placed before the two plan sections so the reader can tell at a
        // glance which one applies to them.
        GuideSection(
          titleKo: '외국인등록증(ARC) 유무 안내',
          titleEn: 'With or without an ARC',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '외국인등록증이 아직 없나요?',
              titleEn: "Don't have an ARC yet?",
              linesKo: [
                '여권으로 가입 가능한 선불 SIM을 확인하세요.',
                '단, 휴대폰 본인인증이 제한될 수 있습니다.',
              ],
              linesEn: [
                'Look for a prepaid SIM you can sign up for with your passport.',
                'Note that phone identity verification may be limited.',
              ],
            ),
            GuideNote(
              titleKo: '외국인등록증이 있나요?',
              titleEn: 'Already have an ARC?',
              linesKo: ['본인 명의 휴대폰 개통을 권장합니다.'],
              linesEn: [
                'We recommend opening a line registered in your own name.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '선불 요금제',
          titleEn: 'Prepaid plans',
          iconName: 'payments',
          bodyKo: '선불 요금제는 사용할 요금을 미리 충전해서 사용하는 방식입니다.\n\n'
              '외국인등록증이 아직 없는 학생도 여권으로 개통 가능한 상품이 있어 '
              '한국에 처음 입국한 학생에게 유용할 수 있습니다.',
          bodyEn: 'With a prepaid plan you top up credit in advance and use it as '
              'you go.\n\n'
              'Some prepaid products can be opened with a passport before your '
              'ARC is issued, which helps if you have just arrived in Korea.',
          notes: [
            GuideNote(
              titleKo: '추천 대상',
              titleEn: 'Best for',
              linesKo: [
                '외국인등록증이 아직 없는 학생',
                '입국 직후 한국 전화번호가 필요한 학생',
                '단기간 체류하는 학생',
              ],
              linesEn: [
                'Students who do not have an ARC yet',
                'Students who need a Korean number right after arriving',
                'Students staying for a short period',
              ],
            ),
          ],
          noticeKo: '여권 정보로 개통한 선불 SIM은 일부 휴대폰 본인인증 서비스나 '
              'PASS 앱 이용이 제한될 수 있습니다.',
          noticeEn: 'A prepaid SIM opened with passport details may not work with '
              'some phone identity verification services or the PASS app.',
        ),
        GuideSection(
          titleKo: '후불 요금제',
          titleEn: 'Postpaid plans',
          iconName: 'receipt_long',
          bodyKo: '후불 요금제는 한 달 동안 사용한 통신요금을 나중에 납부하는 방식입니다.\n\n'
              '장기간 한국에서 생활하는 학생이라면 외국인등록증을 받은 후 본인 명의로 '
              '휴대폰 번호를 개통하는 것을 권장합니다.',
          bodyEn: 'With a postpaid plan you pay afterwards for the month you have '
              'used.\n\n'
              'If you will be living in Korea long term, we recommend opening a '
              'number in your own name once your ARC is issued.',
          notes: [
            GuideNote(
              titleKo: '추천 대상',
              titleEn: 'Best for',
              linesKo: [
                '외국인등록증을 발급받은 학생',
                '한국에서 장기간 생활하는 학생',
                '휴대폰 본인인증을 자주 이용해야 하는 학생',
              ],
              linesEn: [
                'Students who already have an ARC',
                'Students living in Korea long term',
                'Students who often need phone identity verification',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '한국의 주요 통신사는 SKT, KT, LG U+입니다.',
        '알뜰폰은 비교적 저렴하지만 외국인 가입 조건을 확인해야 합니다.',
        '휴대폰이 본인 명의로 등록되어 있는지가 중요합니다.',
        '가입 시 외국인등록증에 표시된 이름과 동일하게 정보를 등록하는 것이 좋습니다.',
        '해외에서 가져온 휴대폰은 한국 통신망 및 USIM/eSIM 지원 여부를 확인해야 합니다.',
      ],
      tipsEn: [
        'The major carriers in Korea are SKT, KT, and LG U+.',
        'Budget (MVNO) plans are cheaper, but check their conditions for '
            'foreign customers.',
        'Whether the line is registered in your own name matters a lot.',
        'Register your details exactly as they appear on your ARC.',
        'If you brought a phone from abroad, check that it supports Korean '
            'networks and USIM/eSIM.',
      ],
      phrases: [
        GuidePhrase(
          ko: '휴대폰을 개통하고 싶습니다.',
          en: 'I would like to sign up for a mobile plan.',
        ),
        GuidePhrase(
          ko: '외국인등록증 없이 개통할 수 있나요?',
          en: 'Can I sign up without an Alien Registration Card?',
        ),
      ],
      links: [
        GuideLink(
          labelKo: 'SKT 외국인 USIM 가입',
          labelEn: 'SKT — USIM sign-up for foreign residents',
          url: 'https://shop.tworld.co.kr/foreigner-counseling/unlocked-phone',
        ),
        GuideLink(
          labelKo: 'KT 외국인 개통 준비사항',
          labelEn: 'KT — what to prepare for activation',
          url: 'https://globalshop.kt.com/support/supportNeed.do',
        ),
        // Official LG U+ Global portal — the help-center article previously
        // linked here fails with Cloudflare 1034 for some users.
        GuideLink(
          labelKo: 'LG U+ 외국인 고객 안내',
          labelEn: 'LG U+ — info for foreign customers',
          url: 'https://mglobal.lguplus.com/',
        ),
        // In-app: opens S2 with a keyword search around campus, so store pins
        // land on the same map as the campus ones (`?nearby=`, router §3).
        GuideLink(
          labelKo: '가까운 통신사 매장 찾기',
          labelEn: 'Find a nearby carrier store',
          url: '/map?nearby=SKT%20%EB%8C%80%EB%A6%AC%EC%A0%90,'
              'KT%20%EB%8C%80%EB%A6%AC%EC%A0%90,'
              'LG%20%EC%9C%A0%ED%94%8C%EB%9F%AC%EC%8A%A4%20%EB%8C%80%EB%A6%AC%EC%A0%90',
          iconName: 'storefront',
        ),
      ],
      durationKo: '예상 당일',
      durationEn: 'Same day',
      difficulty: 1,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'transit-card',
      categoryId: GuideCategory.living,
      titleKo: '교통카드',
      titleEn: 'Transit Card',
      detailTitleKo: '교통카드 구매 및 충전',
      detailTitleEn: 'Buying & Recharging a Transit Card',
      summaryKo: '구매 · 충전 · 환승 이용법',
      summaryEn: 'Buying, recharging & transfers',
      iconName: 'directions_transit',
      overviewKo: '교통카드는 부산의 버스와 지하철 등 대중교통을 이용할 때 사용하는 '
          '충전식 카드입니다.\n\n'
          '현금으로 매번 요금을 내는 것보다 편리하며, 교통카드를 이용하면 대중교통 '
          '환승 시 할인 혜택을 받을 수 있습니다.\n\n'
          '외국인등록증이나 한국 은행계좌가 없어도 일반적인 선불 교통카드는 쉽게 '
          '구매할 수 있어 한국에 처음 입국한 학생도 바로 사용할 수 있습니다.',
      overviewEn: 'A transit card is a rechargeable card you tap to pay for '
          "Busan's buses, subway, and other public transport.\n\n"
          'It is easier than paying cash every trip, and it is what earns you '
          'the transfer discount between buses and the subway.\n\n'
          'You can buy a regular prepaid transit card without an ARC or a '
          'Korean bank account, so it works from your very first day in Korea.',
      checklistKo: [
        '교통카드 구매 비용',
        '충전할 금액',
        '현금 또는 사용 가능한 결제수단',
      ],
      checklistEn: [
        'The cost of the card itself',
        'The amount you want to load onto it',
        'Cash or another accepted payment method',
      ],
      checklistNoteKo: '※ 교통카드 종류와 구매처에 따라 결제 방법이 다를 수 있습니다.',
      checklistNoteEn: '※ Accepted payment methods vary by card type and by '
          'where you buy it.',
      sections: [
        GuideSection(
          titleKo: '구매 방법',
          titleEn: 'How to buy one',
          iconName: 'storefront',
          stepsKo: [
            '가까운 편의점 또는 지하철역 방문',
            '교통카드 판매 여부 확인',
            '교통카드 구매',
            '사용할 금액 충전',
            '버스 또는 지하철에서 카드 사용',
          ],
          stepsEn: [
            'Go to a nearby convenience store or subway station',
            'Ask whether they sell transit cards',
            'Buy the card',
            'Load the amount you want to use',
            'Tap it on a bus or at the subway gate',
          ],
          notes: [
            GuideNote(
              titleKo: '어디에서 구매할 수 있나요?',
              titleEn: 'Where can I buy one?',
              linesKo: [
                '편의점 — 가까운 편의점에서 교통카드 판매 여부를 확인하세요.',
                '지하철역 — 일부 지하철역 또는 교통카드 판매·충전 시설에서 구매할 수 있습니다.',
              ],
              linesEn: [
                'Convenience stores — check with the store nearest you, as not '
                    'every branch stocks them.',
                'Subway stations — some stations have a counter or machine that '
                    'sells and recharges cards.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '충전 방법',
          titleEn: 'How to recharge',
          iconName: 'payments',
          bodyKo: '교통카드 잔액이 부족하면 다시 충전하여 계속 사용할 수 있습니다.',
          bodyEn: 'When the balance runs low, just top the card up and keep '
              'using it.',
          stepsKo: [
            '편의점 또는 지하철역 충전기 방문',
            '교통카드를 충전기에 올리거나 직원에게 전달',
            '충전할 금액 선택',
            '결제',
            '충전 후 잔액 확인',
          ],
          stepsEn: [
            'Go to a convenience store or a recharge machine in a subway station',
            'Place the card on the machine, or hand it to the staff',
            'Choose how much to add',
            'Pay',
            'Check the new balance',
          ],
          noticeKo: '충전 가능한 장소와 결제 방식은 교통카드 종류에 따라 다를 수 있습니다.',
          noticeEn: 'Where you can recharge, and how you can pay, depends on the '
              'type of card.',
        ),
        GuideSection(
          titleKo: '사용 방법',
          titleEn: 'How to use it',
          iconName: 'contactless',
          notes: [
            GuideNote(
              titleKo: '버스',
              titleEn: 'Bus',
              linesKo: [
                '탈 때 — 버스 승차 단말기에 교통카드를 한 번 태그합니다.',
                '내릴 때 — 환승할 예정이라면 하차 단말기에 반드시 다시 태그하세요.',
              ],
              linesEn: [
                'Getting on — tap the card once on the reader by the door.',
                'Getting off — if you plan to transfer, you must tap again on '
                    'the reader as you exit.',
              ],
            ),
            GuideNote(
              titleKo: '지하철',
              titleEn: 'Subway',
              linesKo: [
                '들어갈 때 — 개찰구 단말기에 교통카드를 태그합니다.',
                '나올 때 — 목적지에서 다시 개찰구에 교통카드를 태그합니다.',
              ],
              linesEn: [
                'Entering — tap the card on the ticket gate.',
                'Exiting — tap it again on the gate at your destination.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '환승',
          titleEn: 'Transfers',
          iconName: 'swap_horiz',
          bodyKo: '부산에서는 교통카드를 이용해 버스와 지하철 등 대중교통을 환승하면 '
              '환승 할인 혜택을 받을 수 있습니다.\n\n'
              '환승 혜택을 받으려면 교통카드를 사용하고 버스에서 내릴 때도 반드시 '
              '카드를 태그해야 합니다.',
          bodyEn: 'In Busan, paying with a transit card gets you a transfer '
              'discount when you change between buses and the subway.\n\n'
              'To get it you must pay with the card — and tap it again when you '
              'get off the bus.',
          noticeKo: '버스에서 내릴 때도 꼭 카드를 찍으세요.\n'
              '환승 할인을 받으려면 하차할 때 교통카드를 태그해야 합니다.',
          noticeEn: 'Remember to tap your card when getting off the bus.\n'
              'Without that tap you lose the transfer discount.',
        ),
        GuideSection(
          titleKo: '어떤 교통카드를 사야 하나요?',
          titleEn: 'Which card should I buy?',
          iconName: 'help',
          bodyKo: '처음 한국에 온 학생이라면 가까운 편의점이나 지하철역에서 구매 가능한 '
              '일반 선불 교통카드를 이용하면 됩니다.\n\n'
              '특정 카드 브랜드를 반드시 선택할 필요는 없으며, 부산의 버스와 지하철에서 '
              '사용할 수 있는지 확인한 후 구매하세요.',
          bodyEn: 'If you have just arrived, a regular prepaid transit card from '
              'a nearby convenience store or subway station is all you need.\n\n'
              'No particular brand is required — just check that the card works '
              "on Busan's buses and subway before you buy it.",
        ),
        GuideSection(
          titleKo: '알아두면 좋은 점',
          titleEn: 'Good to know',
          iconName: 'lightbulb',
          notes: [
            GuideNote(
              titleKo: '잔액을 확인하세요',
              titleEn: 'Check your balance',
              linesKo: [
                '버스나 지하철을 이용하기 전에 교통카드에 충분한 잔액이 있는지 확인하세요.',
              ],
              linesEn: [
                'Make sure the card has enough balance before you board.',
              ],
            ),
            GuideNote(
              titleKo: '하차 태그',
              titleEn: 'Tap off the bus',
              linesKo: [
                '버스에서 환승할 예정이라면 내릴 때도 교통카드를 반드시 태그하세요.',
              ],
              linesEn: [
                'Planning to transfer? Tap the card again as you leave the bus.',
              ],
            ),
            GuideNote(
              titleKo: '지하철에서도 사용 가능',
              titleEn: 'Works on the subway too',
              linesKo: [
                '대부분의 일반 선불 교통카드는 부산 지하철과 시내버스 등에서 사용할 수 있습니다.',
              ],
              linesEn: [
                'Most regular prepaid cards work on the Busan subway and city '
                    'buses alike.',
              ],
            ),
            GuideNote(
              titleKo: '편의점에서 충전 가능',
              titleEn: 'Recharge at convenience stores',
              linesKo: [
                '많은 선불 교통카드는 편의점이나 지하철역에서 충전할 수 있습니다.',
              ],
              linesEn: [
                'Most prepaid cards can be topped up at convenience stores or '
                    'subway stations.',
              ],
            ),
            GuideNote(
              titleKo: '모바일 교통카드',
              titleEn: 'Mobile transit cards',
              linesKo: [
                '지원되는 스마트폰에서는 모바일 교통카드를 사용할 수도 있습니다.',
                '다만 휴대폰 기종, NFC 지원 여부, 운영체제 및 앱에 따라 이용 조건이 '
                    '달라질 수 있으므로 처음 입국한 학생에게는 실물 교통카드가 더 간단할 수 있습니다.',
              ],
              linesEn: [
                'Some phones can carry a transit card in an app instead.',
                'Whether it works depends on your phone model, NFC support, OS, '
                    'and the app — so a physical card is usually simpler when you '
                    'have just arrived.',
              ],
            ),
          ],
        ),
      ],
      links: [
        GuideLink(
          labelKo: '부산광역시 교통카드 안내',
          labelEn: 'Busan city — transit card guide',
          descriptionKo: '교통카드 종류 · 구매 · 충전 · 이용 안내',
          descriptionEn: 'Card types, buying, recharging, and how to use them',
          url: 'https://www.busan.go.kr/eng/bscard',
        ),
        GuideLink(
          labelKo: '이즐(EZL) 교통카드 안내',
          labelEn: 'EZL transit card',
          descriptionKo: '교통카드 구매 · 충전 · 사용 방법',
          descriptionEn: 'Buying, recharging, and using the card',
          url: 'https://www.myezl.com',
        ),
        // In-app: same `?nearby=` map search the mobile-plan guide uses.
        GuideLink(
          labelKo: '가까운 교통카드 구매 · 충전 장소',
          labelEn: 'Where to buy or recharge nearby',
          descriptionKo: '편의점 · 지하철역 찾기',
          descriptionEn: 'Find convenience stores & subway stations',
          url: '/map?nearby=%ED%8E%B8%EC%9D%98%EC%A0%90,'
              '%EC%A7%80%ED%95%98%EC%B2%A0%EC%97%AD',
          iconName: 'storefront',
        ),
      ],
      durationKo: '예상 10~20분',
      durationEn: 'Approx. 10–20 min',
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // ── 건강·보험 (health) ──
    const AdminGuideItem(
      id: 'health-insurance',
      categoryId: GuideCategory.health,
      titleKo: '건강보험 가입',
      titleEn: 'National Health Insurance',
      detailTitleKo: '외국인 유학생 국민건강보험 안내',
      detailTitleEn: 'National Health Insurance for International Students',
      summaryKo: '유학생 의무가입 안내',
      summaryEn: 'Mandatory for students',
      overviewKo: '한국에 체류하는 외국인 유학생은 체류자격과 체류기간에 따라 국민건강보험에 가입하게 됩니다. '
          '가입 후에는 병원 진료와 건강검진 등에서 내국인과 같은 기준의 건강보험 혜택을 받을 수 있습니다.\n\n'
          '별도로 가입 신청서를 제출하는 방식이 아니라, 가입 대상이 되면 '
          '국민건강보험공단에서 자동으로 가입 처리합니다.',
      overviewEn: 'International students staying in Korea are enrolled in the '
          'National Health Insurance depending on their visa status and period '
          'of stay. Once enrolled, students can receive National Health '
          'Insurance benefits for medical treatment, health checkups, and other '
          'covered services under the same general system as Korean '
          'nationals.\n\n'
          'In most cases, eligible international students are enrolled '
          'automatically by the National Health Insurance Service (NHIS), '
          'without submitting a separate enrollment application.',
      // Enrollment timing is a precondition, not a packing list — it has to be
      // read before "what to check", so it sits above the checklist.
      topSections: [
        GuideSection(
          titleKo: '언제 가입되나요?',
          titleEn: 'When does coverage start?',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: 'D-2 유학 비자',
              titleEn: 'D-2 Student Visa',
              linesKo: [
                '최초 입국한 경우: 외국인등록일부터 적용',
                '외국인등록 후 출국했다가 재입국한 경우: 재입국일부터 적용',
              ],
              linesEn: [
                'First entry into Korea: coverage begins from the date of '
                    'foreigner registration.',
                'Re-entry after foreigner registration: coverage generally '
                    'begins from the date of re-entry.',
              ],
            ),
            GuideNote(
              titleKo: 'D-4 일반연수 비자',
              titleEn: 'D-4 General Training Visa',
              linesKo: ['입국일로부터 6개월이 지난 후 가입'],
              linesEn: [
                'Enrollment generally begins six months after the date of entry '
                    'into Korea.',
              ],
            ),
          ],
          footnoteKo: '체류자격이나 개인 상황에 따라 적용 시점이 달라질 수 있으므로 '
              '본인의 정확한 가입일은 국민건강보험공단에서 확인하는 것이 좋습니다.',
          footnoteEn: 'The exact enrollment date may depend on your immigration '
              'and residence status. Check with NHIS if you are unsure about '
              'your individual case.',
        ),
      ],
      // The list is what to verify before an automatic enrolment, not a set of
      // documents to bring — the shared "준비물" heading would misread it.
      checklistTitleKo: '가입 전 확인사항',
      checklistTitleEn: 'Before you enroll',
      checklistKo: [
        '외국인등록 여부',
        '본인의 체류자격(D-2, D-4 등)',
        '국내에 신고된 체류지 주소',
        '국민건강보험공단에서 발송한 가입 안내문 또는 보험료 고지서',
        '보험료 납부 방법',
      ],
      checklistEn: [
        'Check whether your foreigner registration is complete.',
        'Check your visa status, such as D-2 or D-4.',
        'Make sure your registered address in Korea is correct.',
        'Check any enrollment notice or premium bill sent by NHIS.',
        'Check how you will pay your insurance premium.',
      ],
      checklistNoteKo: '※ 특히 체류지 주소가 변경되었다면 정확한 주소로 신고해야 합니다. '
          '건강보험 관련 안내문과 고지서가 등록된 국내 주소로 발송될 수 있습니다.',
      checklistNoteEn: '※ If you change your residence, make sure your '
          'registered address is updated — NHIS notices and premium bills may '
          'be sent to your registered address in Korea.',
      stepsKo: [
        '체류자격과 가입 시기를 확인합니다. D-2와 D-4는 국민건강보험 적용 시점이 다릅니다.',
        '외국인등록과 체류지 정보를 정확히 등록합니다. 공단은 등록된 체류정보를 바탕으로 가입을 처리합니다.',
        '가입 대상이 되면 자동으로 가입됩니다. 일반적으로 별도의 건강보험 가입 신청서를 제출할 필요가 없습니다.',
        '가입 안내와 보험료 고지 내용을 확인합니다. 가입 후 보험료와 납부기한을 확인합니다.',
        '정해진 기한 내에 보험료를 납부합니다.',
        '가입 상태에서 병원이나 약국 등 건강보험 적용 의료서비스를 이용합니다.',
      ],
      stepsEn: [
        'Check your visa status and enrollment date. The enrollment timing is '
            'different for D-2 and D-4 visa holders.',
        'Complete your foreigner registration and keep your Korean address up '
            'to date.',
        'NHIS automatically enrolls you when you become eligible. A separate '
            'enrollment application is generally not required.',
        'Check your enrollment notice and premium bill.',
        'Pay your premium by the stated due date.',
        'Once insured, you can use covered medical services at hospitals, '
            'clinics, pharmacies, and other eligible healthcare providers.',
      ],
      sections: [
        GuideSection(
          titleKo: '보험료와 유학생 경감',
          titleEn: 'Premiums and the student reduction',
          iconName: 'payments',
          bodyKo: '외국인 지역가입자의 보험료는 소득과 재산 등을 기준으로 산정됩니다. '
              '따라서 모든 유학생에게 동일한 고정 금액을 안내하기보다는, '
              '국민건강보험공단에서 발송한 본인의 고지서를 확인하는 것이 가장 정확합니다.\n\n'
              'D-2·D-4 유학생은 일정 요건을 충족하는 경우 보험료 경감 대상이 될 수 있습니다. '
              '현재 공식 안내에서는 D-2·D-4 등 대상 유학생이 소득 및 재산 요건을 충족할 경우 '
              '50% 경감 기준을 안내하고 있습니다.',
          bodyEn: 'Premiums for foreign regional subscribers are calculated '
              'based on factors such as income and property. For this reason, '
              'students should check their individual NHIS premium bill rather '
              'than relying on a single fixed monthly amount.\n\n'
              'D-2 and D-4 students may qualify for a premium reduction if they '
              'meet the applicable income and property requirements. Current '
              'official guidance provides a 50% reduction for eligible '
              'international students in these categories.',
          // Informative, not cautionary — the neutral glyph, not the warning.
          noticeKo: '보험료와 경감 기준은 변경될 수 있으므로, 고정된 월 보험료를 기준으로 삼기보다 '
              '최신 고지서 또는 국민건강보험공단 안내를 확인하세요.',
          noticeEn: 'Premiums and reduction rules may change. Always check your '
              'latest NHIS bill or official NHIS guidance.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '어떤 혜택을 받을 수 있나요?',
          titleEn: 'What does the insurance cover?',
          iconName: 'info',
          bodyKo: '국민건강보험에 가입하면 내국인과 같은 건강보험 제도 안에서 '
              '병원 진료, 건강검진 등 다양한 보험 혜택을 받을 수 있습니다.',
          bodyEn: 'After enrollment, international students can receive '
              'National Health Insurance benefits such as covered medical '
              'treatment and health checkups under the same national insurance '
              'system used by Korean nationals.',
          noticeKo: '다만 모든 진료가 건강보험 대상인 것은 아닙니다. '
              '예를 들어 미용 목적의 시술·수술 등 일부 비급여 의료서비스에는 '
              '건강보험이 적용되지 않을 수 있습니다.',
          noticeEn: 'However, not every medical service is covered. Certain '
              'non-covered services, including some cosmetic procedures, may '
              'require full payment by the patient.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '보험료를 체납하면 주의하세요',
          titleEn: 'Unpaid premiums can restrict your benefits',
          iconName: 'receipt_long',
          bodyKo: '보험료를 장기간 납부하지 않으면 건강보험 급여가 제한될 수 있습니다. '
              '현재 외국인 지역가입자의 보험급여 제한과 관련한 별도 규정이 있으므로, '
              '고지서를 받으면 납부기한을 확인하고 체납하지 않는 것이 중요합니다.',
          bodyEn: 'If insurance premiums remain unpaid, National Health '
              'Insurance benefits may be restricted under the rules applying to '
              'foreign regional subscribers. Check the due date on your bill '
              'and avoid overdue premiums.',
          // Real consequence → keeps the default warning glyph.
          noticeKo: '보험료 체납 상태라면 병원을 이용하기 전에 국민건강보험공단에 '
              '본인의 보험 적용 상태를 확인하세요.',
          noticeEn: 'If you have unpaid premiums, contact NHIS to confirm your '
              'current insurance coverage before using medical services.',
        ),
        GuideSection(
          titleKo: '문의',
          titleEn: 'Where to ask',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '국민건강보험공단',
              titleEn: 'National Health Insurance Service (NHIS)',
              linesKo: [
                '대표전화: 1577-1000',
                '외국어 상담: 1577-1000 → 외국인 전용 안내 선택, 또는 033-811-2000',
                '지원 언어: 영어, 중국어, 베트남어, 우즈베크어',
                '상담시간: 평일 09:00~18:00',
                '해외에서: +82-33-811-2001',
              ],
              linesEn: [
                'Main line: 1577-1000',
                'Foreign-language support: 1577-1000 → select the foreigner '
                    'service, or 033-811-2000',
                'Languages: English, Chinese, Vietnamese, Uzbek',
                'Hours: weekdays 09:00–18:00',
                'From outside Korea: +82-33-811-2001',
              ],
            ),
            GuideNote(
              titleKo: '동아대학교 국제지원팀',
              titleEn: 'Dong-A University International Support Team',
              linesKo: [
                '학교 생활·체류·유학생 지원과 관련해 학교 확인이 필요한 경우 문의할 수 있습니다.',
                '전화: 051-200-6446~8',
                '유학생 지원 문의: 051-200-6447',
                '이메일: global@donga.ac.kr',
              ],
              linesEn: [
                'Contact them when you need the university to confirm something '
                    'about student life, residence, or international student '
                    'support.',
                'Phone: 051-200-6446~8',
                'International student support: 051-200-6447',
                'Email: global@donga.ac.kr',
              ],
            ),
          ],
          footnoteKo: '보험료, 경감조건, 가입 기준은 제도 변경 가능성이 있으므로 '
              '최신 공식 안내를 확인하세요.',
          footnoteEn: 'Premiums, reduction requirements, and enrollment rules '
              'may change — always check the latest official guidance.',
        ),
      ],
      tipsKo: [
        'D-2와 D-4는 가입 시작 시점이 다릅니다.',
        '가입 대상이 되면 일반적으로 별도의 신청 없이 자동 가입됩니다.',
        '이사했다면 체류지 주소를 정확히 변경 신고하세요.',
        '보험료는 학생마다 달라질 수 있으므로 본인의 고지서를 기준으로 확인하세요.',
        '보험료 경감 여부도 개인의 소득·재산 등 조건에 따라 달라질 수 있습니다.',
        '확실하지 않은 경우 국민건강보험공단에 직접 문의하는 것이 가장 정확합니다.',
      ],
      tipsEn: [
        'D-2 and D-4 visa holders have different enrollment starting dates.',
        'Eligible students are generally enrolled automatically.',
        'Update your registered address if you move.',
        'Premium amounts can vary, so check your individual NHIS bill.',
        'Eligibility for a premium reduction depends on applicable conditions.',
        'Contact NHIS directly if you are unsure about your status.',
      ],
      links: [
        GuideLink(
          labelKo: '국민건강보험공단 외국인 건강보험 안내',
          labelEn: 'NHIS — Guidance for foreigners',
          url: 'https://www.nhis.or.kr/english/wbheaa02900m01.do',
          descriptionKo: '가입 대상·보험료·급여 범위와 외국어 상담 연락처',
          descriptionEn: 'Enrollment, premiums, coverage, and foreign-language '
              'contact numbers',
        ),
        GuideLink(
          labelKo: 'Study in Korea 국민건강보험 안내',
          labelEn: 'Study in Korea — National Health Insurance',
          url: 'https://www.studyinkorea.go.kr/ko/life/livingAndHousing.do',
          descriptionKo: 'D-2·D-4 가입 시기, 자동가입, 보험료 경감, 보험 혜택 안내',
          descriptionEn: 'Enrollment timing for D-2/D-4, automatic enrollment, '
              'premium reduction, and covered benefits',
        ),
        // In-app: coverage is processed off the foreigner registration, so the
        // ARC guide is the prerequisite step (same `/guide/item/…` route the
        // visa-types guide uses).
        GuideLink(
          labelKo: '가이드 — 외국인등록증(ARC) 발급',
          labelEn: 'Guide — Alien Registration Card (ARC)',
          url: '/guide/item/arc-issue',
          descriptionKo: '건강보험 적용은 외국인등록과 체류지 정보를 기준으로 처리됩니다.',
          descriptionEn: 'Coverage is processed from your foreigner '
              'registration and registered address.',
          iconName: 'badge',
        ),
      ],
      // No related location on purpose: the only candidate facility
      // (`oia-office`) is week-2 fixture data — placeholder phone and
      // coordinates — so pinning it would send students to a wrong address.
      // Reconnect once the facility list carries real campus data.
      status: GuideStatus.published,
    ),
    // Everything below comes from the clinic's own site (health.donga.ac.kr):
    // the two campus locations with their phone numbers, the weekday hours, and
    // the six-item service list. Nothing about fees, prescriptions, or whether a
    // doctor is on site is published there, so none of that is described here.
    const AdminGuideItem(
      id: 'campus-clinic',
      categoryId: GuideCategory.health,
      titleKo: '교내 보건소',
      titleEn: 'Campus Health Center',
      summaryKo: '위치 · 이용시간 · 보건 서비스',
      summaryEn: 'Locations, hours & health services',
      overviewKo: '보건진료소는 학교 안에서 응급처치와 건강상담 등 기본적인 보건 서비스를 받을 수 있는 곳입니다. '
          '수업 중에 다치거나 몸이 좋지 않을 때 캠퍼스를 벗어나지 않고 들를 수 있습니다.\n\n'
          '보건진료소의 공식 업무내용에 포함되지 않는 진료가 필요한 경우에는 '
          '병원이나 의원을 이용하세요.',
      overviewEn: 'The campus health clinic is where you can get first aid, '
          'health advice, and other basic health services without leaving '
          'campus — useful if you get hurt between classes or start feeling '
          'unwell during the day.\n\n'
          'For care that is not part of the clinic\'s official list of '
          'services, go to a hospital or a local clinic instead.',
      // Which campus you are on decides everything else on this page, so the
      // two locations come before the checklist.
      topSections: [
        GuideSection(
          titleKo: '어디에 있나요?',
          titleEn: 'Where can I find it?',
          iconName: 'location_on',
          bodyKo: '보건진료소는 승학캠퍼스와 부민캠퍼스 두 곳에 있습니다.',
          bodyEn: 'There are two campus health clinics — one on the Seunghak '
              'campus and one on the Bumin campus.',
          notes: [
            GuideNote(
              titleKo: '승학캠퍼스',
              titleEn: 'Seunghak campus',
              linesKo: ['학생회관(Q) 지하 1층', '전화 051-200-6331~2'],
              linesEn: [
                'Student Union Building (Q), basement floor 1',
                'Phone: 051-200-6331~2',
              ],
            ),
            GuideNote(
              titleKo: '부민캠퍼스',
              titleEn: 'Bumin campus',
              linesKo: ['법학전문대학원(LS) 1층', '전화 051-200-8465'],
              linesEn: [
                'Law School Building (LS), 1st floor',
                'Phone: 051-200-8465',
              ],
            ),
          ],
        ),
      ],
      // Not a packing list — these are things to settle before walking over.
      checklistTitleKo: '방문 전 확인',
      checklistTitleEn: 'Before you visit',
      checklistKo: [
        '이용하려는 캠퍼스와 보건진료소 위치',
        '이용시간(월~금 09:00~17:00)',
        '점심시간(12:00~13:00)',
        '문의가 필요한 경우 이용할 캠퍼스 보건진료소 연락처 확인',
        '어디가 어떻게 불편한지 미리 정리해 두기',
      ],
      checklistEn: [
        'Which campus you are going to, and where the clinic is in it.',
        'The opening hours: Monday to Friday, 09:00–17:00.',
        'The lunch break: 12:00–13:00.',
        'The phone number of that campus clinic, in case you need to ask first.',
        'A short note on your symptoms or what you need help with.',
      ],
      checklistNoteKo: '※ 이용시간과 업무내용은 동아대학교 보건진료소 공식 홈페이지 기준입니다. '
          '방문 전 공식 홈페이지에서 최신 안내를 확인하세요.',
      checklistNoteEn: '※ The hours and services listed here follow the '
          'Dong-A University Health Clinic\'s official website. Check the '
          'official website for the latest information before you go.',
      sections: [
        GuideSection(
          titleKo: '이용시간',
          titleEn: 'Opening hours',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '월요일 ~ 금요일',
              titleEn: 'Monday to Friday',
              linesKo: ['09:00 ~ 17:00', '점심시간 12:00 ~ 13:00'],
              linesEn: ['09:00 – 17:00', 'Lunch break 12:00 – 13:00'],
            ),
          ],
          noticeKo: '공식 안내에는 평일 이용시간만 나와 있습니다. '
              '주말과 공휴일 운영 여부는 안내되어 있지 않으므로, 평일 외에 방문해야 한다면 미리 전화로 확인하세요.',
          noticeEn: 'The official notice lists weekday hours only — it does not '
              'say whether the clinic opens on weekends or public holidays. '
              'Call ahead if you need to go outside weekday hours.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '어떤 도움을 받을 수 있나요?',
          titleEn: 'What services are available?',
          iconName: 'info',
          bodyKo: '보건진료소 공식 홈페이지에 안내된 업무내용은 다음과 같습니다.',
          bodyEn: 'The clinic\'s official website lists the following services.',
          notes: [
            GuideNote(
              titleKo: '업무내용',
              titleEn: 'Services',
              linesKo: [
                '응급처치',
                '외상 및 화상치료',
                '일반의약품 투약',
                '건강상담',
                '보건교육',
                '건강증진사업',
              ],
              linesEn: [
                'First aid',
                'Treatment for wounds and burns',
                'Over-the-counter medication',
                'Health counselling',
                'Health education',
                'Health promotion programmes',
              ],
            ),
          ],
          footnoteKo: '필요한 서비스가 가능한지 확실하지 않다면 방문 전에 전화로 문의하세요.',
          footnoteEn: 'If you are not sure whether the service you need is '
              'available, call the clinic before you go.',
        ),
        GuideSection(
          titleKo: '응급상황이라면',
          titleEn: 'In an emergency',
          iconName: 'help',
          bodyKo: '보건진료소는 학교 안에서 운영되는 보건 지원 시설이며, '
              '공식 안내된 이용시간은 평일 09:00~17:00입니다.',
          bodyEn: 'The campus clinic is a health support facility on campus, '
              'and its published hours are 09:00–17:00 on weekdays.',
          noticeKo: '의식이 없거나, 호흡이 어렵거나, 출혈이 심한 경우처럼 위급한 상황이라면 '
              '보건진료소를 찾아가거나 이용시간을 기다리지 말고 즉시 119에 신고하거나 '
              '가까운 응급의료기관으로 가세요.',
          noticeEn: 'If the situation is urgent — someone is unconscious, '
              'having trouble breathing, or bleeding heavily — do not go to '
              'the campus clinic or wait for it to open. Call 119 straight '
              'away or go to the nearest emergency room.',
        ),
        GuideSection(
          titleKo: '병원 진료가 필요하다면',
          titleEn: 'If you need to see a doctor',
          iconName: 'compare_arrows',
          bodyKo: '증상이 심하거나 낫지 않는 경우, 또는 보건진료소 업무내용에 없는 진료가 필요한 경우에는 '
              '병원이나 의원을 이용해야 합니다.\n\n'
              '한국에서 병원을 이용하는 절차가 익숙하지 않다면 아래 병원 이용 가이드를 함께 참고하세요. '
              '건강보험에 가입되어 있으면 병원 진료비 부담을 덜 수 있습니다.',
          bodyEn: 'If your symptoms are severe, do not improve, or need care '
              'that is not on the clinic\'s list of services, you should visit '
              'a hospital or a local clinic instead.\n\n'
              'If you are not used to how hospitals work in Korea, the hospital '
              'guide below walks through it. Being enrolled in the National '
              'Health Insurance also lowers what you pay for treatment.',
        ),
        GuideSection(
          titleKo: '문의',
          titleEn: 'Contact',
          iconName: 'info',
          notes: [
            GuideNote(
              titleKo: '승학캠퍼스 보건진료소',
              titleEn: 'Seunghak campus clinic',
              linesKo: ['학생회관(Q) 지하 1층', '051-200-6331~2'],
              linesEn: [
                'Student Union Building (Q), basement floor 1',
                '051-200-6331~2',
              ],
            ),
            GuideNote(
              titleKo: '부민캠퍼스 보건진료소',
              titleEn: 'Bumin campus clinic',
              linesKo: ['법학전문대학원(LS) 1층', '051-200-8465'],
              linesEn: ['Law School Building (LS), 1st floor', '051-200-8465'],
            ),
          ],
          footnoteKo: '위치·이용시간·업무내용은 보건진료소 공식 홈페이지에서 최신 내용을 확인할 수 있습니다.',
          footnoteEn: 'The clinic\'s official website has the current '
              'locations, hours, and list of services.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대학교 보건진료소',
          labelEn: 'Dong-A University Health Clinic',
          url: 'https://health.donga.ac.kr/',
          descriptionKo: '캠퍼스별 위치·연락처, 이용시간과 업무내용 공식 안내',
          descriptionEn: 'Official page with locations, phone numbers, opening '
              'hours, and services',
        ),
        // In-app: the two guides a student ends up needing when the clinic is
        // not the right place (same `/guide/item/…` route used elsewhere).
        GuideLink(
          labelKo: '가이드 — 병원 이용',
          labelEn: 'Guide — Visiting a Hospital',
          url: '/guide/item/hospital-guide',
          descriptionKo: '보건진료소에서 해결하기 어려운 경우 병원 이용 절차를 확인하세요.',
          descriptionEn: 'What to do when the campus clinic is not enough.',
          iconName: 'help',
        ),
        GuideLink(
          labelKo: '가이드 — 건강보험 가입',
          labelEn: 'Guide — National Health Insurance',
          url: '/guide/item/health-insurance',
          descriptionKo: '건강보험에 가입되어 있으면 병원 진료비 부담을 덜 수 있습니다.',
          descriptionEn: 'Being enrolled lowers what you pay for treatment.',
          iconName: 'payments',
        ),
      ],
      // Both buildings are real campus-map data (coordinates auto-extracted),
      // and the floor guide lists 보건진료소 on s02 B1F and b02 1F — so each
      // card lands on the right building, and the map switches campus for it.
      relatedFacilityIds: ['b02', 's02'],
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'hospital-guide',
      categoryId: GuideCategory.health,
      titleKo: '병원 이용',
      titleEn: 'Visiting a Hospital',
      summaryKo: '진료 절차·통역 지원',
      summaryEn: 'Process & interpretation',
    ),

    // ── 학교 행정 (school) ──
    const AdminGuideItem(
      id: 'course-registration',
      categoryId: GuideCategory.school,
      titleKo: '수강신청',
      titleEn: 'Course Registration',
      summaryKo: '일정 · 과목 선택 · 신청 방법',
      summaryEn: 'Schedule, course selection & registration',
      iconName: 'format_list_numbered',
      overviewKo: '수강신청은 매 학기 시작 전에 한 학기 동안 수강할 교과목을 학생이 직접 '
          '신청하는 절차입니다.\n\n'
          '학생은 본인의 최대 수강신청 가능학점 범위 안에서 원하는 과목을 선택하고 직접 '
          '시간표를 구성합니다.\n\n'
          '수강신청 일정은 학기마다 달라질 수 있으므로 동아대학교의 최신 학사공지를 반드시 '
          '확인해야 합니다.',
      overviewEn: 'Course registration is how you choose the courses you will '
          'take for the coming semester. You do it yourself, before the '
          'semester starts.\n\n'
          'You pick the courses you want within the maximum number of credits '
          'you are allowed to take, and build your own timetable.\n\n'
          'The registration period is different every semester, so always check '
          "Dong-A University's latest academic notices.",
      // Login comes before the checklist: an international freshman cannot even
      // open the registration system without knowing the exam-number rule.
      topSections: [
        GuideSection(
          titleKo: '로그인 방법',
          titleEn: 'How to log in',
          iconName: 'computer',
          bodyKo: '수강신청과 학사정보 확인은 동아대학교 학생정보 계정으로 로그인한 뒤 이용할 수 '
              '있습니다.',
          bodyEn: 'You register for courses — and check your academic '
              'information — after logging in with your Dong-A University '
              'student account.',
          notes: [
            GuideNote(
              titleKo: '학번이 이미 있는 학생',
              titleEn: 'If you already have a student ID number',
              linesKo: [
                '기존 학생정보 계정의 학번과 비밀번호로 로그인하세요.',
              ],
              linesEn: [
                'Log in with the student ID number and password of your '
                    'existing student account.',
              ],
            ),
            GuideNote(
              titleKo: '학번이 아직 없는 신입생',
              titleEn: 'If you are a new student without a student ID yet',
              linesKo: [
                '아이디: 동아대학교 원서접수 수험번호',
                '초기 비밀번호: 생년월일 6자리 + 지원 당시 휴대폰번호 뒤 4자리',
              ],
              linesEn: [
                'ID: the application (exam) number from your Dong-A University '
                    'admission application',
                'Initial password: your date of birth (6 digits) followed by '
                    'the last 4 digits of the mobile number you gave when you '
                    'applied',
              ],
            ),
          ],
          noticeKo: '학번이 발급되면\n'
              '학번이 발급된 이후에는 학번을 이용하여 학교 시스템에 로그인하세요.',
          noticeEn: 'Once your student ID number is issued\n'
              'From then on, use that student ID number to log in to the '
              "university's systems.",
          noticeIconName: 'badge',
          footnoteKo: '학번 조회에는 본인 명의 휴대폰 인증이 필요할 수 있으며, 비밀번호 초기화는 '
              '본인 명의 휴대폰 또는 이메일 인증을 이용할 수 있습니다.',
          footnoteEn: 'Looking up your student ID number may require verifying a '
              'mobile number registered in your own name. To reset a password '
              'you can verify with your own mobile number or your email.',
        ),
        // No flat "everyone gets N credits" claim: the 2026-2 registration
        // notice changes the engineering limit by 학번, and the 2024 booklet
        // lists four more per-department exceptions. The guide states the common
        // case and sends the student to the number the system shows them.
        GuideSection(
          titleKo: '최대 수강신청 학점',
          titleEn: 'Maximum course load',
          iconName: 'school',
          bodyKo: '대부분의 일반 학부 과정은 한 학기 최대 19학점까지 수강신청할 수 '
              '있습니다.\n\n'
              '다만 소속 대학·학과, 학번 및 학적 상태에 따라 최대 신청학점이 달라질 수 '
              '있으므로, 수강신청 전에 수강신청 시스템에서 본인의 신청 가능학점을 '
              '확인하세요.',
          bodyEn: 'On most undergraduate programs you can register for up to 19 '
              'credits in a semester.\n\n'
              'The limit can differ, though, by college and department, by the '
              'year your student ID number starts with, and by your enrollment '
              'status — so check the number the registration system shows for '
              'you before you register.',
          notes: [
            GuideNote(
              titleKo: '학과에 따라 달라질 수 있어요',
              titleEn: 'It differs by department',
              linesKo: [
                '2026학년도 제2학기 수강신청 안내 기준으로 공과대학은 2019학년도 이전 학번 '
                    '21학점, 2020학년도 이후 학번 19학점입니다.',
                '2024학년도 외국인 유학생 안내서에는 석당인재학부·의학과·의예과 24학점, '
                    '건축학과·간호학과 21학점처럼 학과별 차이가 안내되어 있었습니다.',
              ],
              linesEn: [
                'Per the 2026 second-semester registration notice, the College '
                    'of Engineering allows 21 credits for student IDs from 2019 '
                    'or earlier and 19 credits from 2020 onwards.',
                'The 2024 international-student booklet listed other exceptions '
                    'as well — 24 credits for Seokdang Honors, Medicine and '
                    'Pre-Medicine, and 21 for Architecture and Nursing.',
              ],
            ),
          ],
          noticeKo: '모든 학생이 19학점인 것은 아닙니다\n'
              '학과와 학번, 학적 상태에 따라 최대 신청학점이 더 높거나 낮을 수 있습니다.\n'
              '수강신청 시스템에 표시되는 본인의 신청 가능학점이 기준입니다.',
          noticeEn: 'Not every student gets 19 credits\n'
              'Your limit can be higher or lower depending on your department, '
              'your student ID year, and your enrollment status.\n'
              'The number the registration system shows for you is the one that '
              'counts.',
          noticeIconName: 'info',
          footnoteKo: '※ 위 학점 기준은 2026학년도 제2학기 수강신청 안내와 2024학년도 외국인 '
              '유학생 안내서를 정리한 것입니다. 학기마다 바뀔 수 있으므로 최신 수강신청 공지를 '
              '확인하세요.',
          footnoteEn: '※ These figures come from the 2026 second-semester '
              'registration notice and the 2024 international-student booklet. '
              'They can change every semester — check the latest registration '
              'notice.',
        ),
        // Carryover sits next to the credit limit because it only makes sense
        // as an addition to it: leftover credits raise next semester's cap.
        GuideSection(
          titleKo: '학점이월제',
          titleEn: 'Credit carryover',
          iconName: 'swap_horiz',
          bodyKo: '최대 수강신청 학점을 모두 사용하지 않은 경우, 남은 학점이 1~2학점이면 다음 '
              '학기로 이월하여 최대 수강신청 학점에 더해 사용할 수 있습니다.',
          bodyEn: 'If you do not use your whole course load, and 1–2 credits are '
              'left over, those credits carry over to the next semester and are '
              'added on top of your maximum course load then.',
          notes: [
            GuideNote(
              titleKo: '이월 가능한 학점 (최대 신청학점이 19학점인 경우)',
              titleEn: 'Credits eligible for carryover (with a 19-credit limit)',
              linesKo: [
                '18학점 신청 → 1학점 이월 가능',
                '17학점 신청 → 2학점 이월 가능',
                '16학점 신청 → 잔여 3학점이므로 이월 불가',
              ],
              linesEn: [
                'You registered for 18 credits → 1 credit carries over',
                'You registered for 17 credits → 2 credits carry over',
                'You registered for 16 credits → 3 left over, so nothing carries '
                    'over',
              ],
            ),
            GuideNote(
              titleKo: '적용 제외 대상',
              titleEn: 'Who it does not apply to',
              linesKo: [
                '산업공학과, 의과대학 의학과, 석당인재학부 소속 학생',
                '시간제 등록생, 그리고 타 대학에 적을 두고 있는 파견·교환학생',
                '조기졸업, 5년제 학·석사 등 학점 초과취득이 별도로 가능한 학생 (중복 적용되지 '
                    '않습니다)',
              ],
              linesEn: [
                'Students in Industrial Engineering, the School of Medicine, or '
                    'Seokdang Honors',
                'Part-time registered students, and visiting or exchange '
                    'students enrolled at another university',
                'Students who can already exceed the credit limit another way — '
                    'early graduation, the 5-year combined BA/MA — since the two '
                    'do not stack',
              ],
            ),
            GuideNote(
              titleKo: '외국인 학생은 어떻게 되나요?',
              titleEn: 'What about international students?',
              linesKo: [
                '동아대학교 정규 학위과정에 재학 중인 외국인 학생이 외국 국적이라는 이유만으로 '
                    '학점이월제에서 제외된다는 내용은 현재 공식 수강신청 안내에서 확인되지 '
                    '않습니다.',
                '다만 타 대학에 소속된 파견·교환학생은 학점이월제 적용 대상에서 제외됩니다.',
              ],
              linesEn: [
                'The official registration notice does not say that '
                    'international students on a degree program at Dong-A are '
                    'excluded from carryover because of their nationality.',
                'Visiting and exchange students enrolled at another university, '
                    'however, are excluded.',
              ],
            ),
          ],
          noticeKo: '이월 학점은 그 학기에 쓰지 않으면 사라집니다\n'
              '이월된 학점을 해당 학기에 사용하지 않으면 다시 다음 학기로 이월되지 않고 '
              '소멸됩니다.\n'
              '수강취소 기간에 취소한 학점은 이월되지 않습니다.\n'
              '학점이월제 적용 제외 대상이 있으므로 본인의 적용 여부를 확인하세요.',
          noticeEn: 'Carried credits expire if you do not use them\n'
              'Credits carried into a semester do not roll over again — if you '
              'do not use them that semester, they are gone.\n'
              'Credits you drop during the withdrawal period do not carry '
              'over.\n'
              'Some students are excluded from carryover, so check whether it '
              'applies to you.',
          footnoteKo: '※ 학점이월제 내용은 2026학년도 제2학기 수강신청 안내 기준입니다. 이월 '
              '조건과 적용 제외 대상은 학기마다 달라질 수 있으므로 최신 수강신청 공지를 '
              '확인하세요.',
          footnoteEn: '※ The carryover rules here follow the 2026 '
              'second-semester registration notice. The conditions and the '
              'exclusions can change each semester — check the latest '
              'registration notice.',
        ),
      ],
      checklistTitleKo: '신청 전 확인',
      checklistTitleEn: 'Before registration',
      checklistKo: [
        '학번과 비밀번호 확인',
        '이번 학기 개설 교과목 확인',
        '본인의 최대 수강신청 가능학점 확인',
        '전공필수 / 전공선택 / 교양 등 이수구분 확인',
        '수업시간 중복 여부 확인',
        '강의실 및 캠퍼스 확인',
        '재수강 여부 확인',
        '외국인 유학생 필수이수교과목 확인',
      ],
      checklistEn: [
        'Your student ID number and password',
        'The courses offered this semester',
        'Your own maximum credits for the semester',
        'Course type — major required, major elective, general education',
        'Whether any class times overlap',
        'The classroom and the campus',
        'Whether a course counts as a retake',
        'The required courses for international students',
      ],
      checklistNoteKo: '※ 이수구분, 최대 신청학점, 재수강 기준은 학년도와 학과에 따라 달라질 수 '
          '있으므로 신청 전에 최신 학사안내를 확인하세요.',
      checklistNoteEn: '※ Course types, credit limits, and retake rules can '
          'differ by academic year and department — check the latest academic '
          'guidance before you register.',
      sections: [
        GuideSection(
          titleKo: '수업 내용을 미리 확인하세요',
          titleEn: 'Check what the course actually covers',
          iconName: 'menu_book',
          bodyKo: '과목명만 보고 신청하지 말고 강의계획서, 수업방식, 평가방법 등을 '
              '확인하세요.',
          bodyEn: 'Do not register based on the course title alone. Check the '
              'syllabus, how the class is taught, and how it is graded.',
        ),
        GuideSection(
          titleKo: '수강신청 방법',
          titleEn: 'How to register',
          iconName: 'format_list_numbered',
          bodyKo: '동아대학교 홈페이지 → 학사안내 → 수강신청 및 수강정정 → 로그인 순서로 '
              '접속할 수 있습니다.',
          bodyEn: 'You can get there from the university homepage: 학사안내 '
              '(Academic Information) → 수강신청 및 수강정정 (Course registration & '
              'add/drop) → log in.',
          stepsKo: [
            '동아대학교 수강신청 시스템 접속',
            '학번과 비밀번호로 로그인',
            '이번 학기 개설 교과목 확인',
            '전공 · 교양 · 시간 · 학점 확인',
            '원하는 교과목 신청',
            '수강확정 / 탈락 여부 확인',
            '최종 수강신청 내역 확인',
          ],
          stepsEn: [
            'Open the Dong-A University registration system',
            'Log in with your student ID number and password',
            'Check the courses offered this semester',
            'Check the course type, time, and credits',
            'Register for the courses you want',
            'Check whether each course was confirmed or dropped',
            'Check your final registration list',
          ],
          noticeKo: '수강신청은 보통 학기가 시작되기 전에 진행되지만 정확한 기간은 매 학기 '
              '학사공지로 안내됩니다. 신청 전에 최신 공지를 확인하세요.',
          noticeEn: 'Registration normally takes place before the semester '
              'begins, but the exact dates are announced each semester in the '
              'academic notices. Check them before you register.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '수강확정 · 탈락',
          titleEn: 'Confirmation & rejection',
          iconName: 'compare_arrows',
          bodyKo: '교과목을 신청했다고 해서 모든 과목이 바로 최종 확정되는 것은 아닐 수 '
              '있습니다.\n\n'
              '신청 인원과 수강제한 인원 등에 따라 수강확정 또는 탈락 결과가 발생할 수 있으므로 '
              '신청 후 반드시 결과를 확인해야 합니다.',
          bodyEn: 'Registering for a course does not always mean your place in '
              'it is final.\n\n'
              'Depending on how many students applied and the enrollment limit, '
              'a course can come back confirmed or dropped — so you have to '
              'check the result after you register.',
          notes: [
            GuideNote(
              titleKo: '탈락한 과목이 있다면',
              titleEn: 'If one of your courses was dropped',
              linesKo: [
                '개설 학과에 증원 가능 여부를 문의할 수 있습니다.',
                '탈락자 수강신청 기간에 해당 과목 또는 다른 과목을 다시 신청할 수 있습니다.',
                '탈락자 수강신청 기간에는 남은 정원에 대해 선착순으로 확정될 수 있습니다.',
              ],
              linesEn: [
                'You can ask the department that offers it whether the limit '
                    'can be raised.',
                'During the re-registration period for dropped students you can '
                    'apply for that course again, or for a different one.',
                'In that period the remaining seats can be filled on a '
                    'first-come, first-served basis.',
              ],
            ),
          ],
          noticeKo: '신청 후 결과를 꼭 확인하세요\n'
              '수강신청 버튼을 눌렀다고 끝난 것이 아닙니다. 수강확정 또는 탈락 여부를 반드시 '
              '다시 확인하세요.',
          noticeEn: 'Check your registration result\n'
              'Pressing the register button is not the end of it. Go back and '
              'check whether each course was confirmed or dropped.',
        ),
        GuideSection(
          titleKo: '수강정정',
          titleEn: 'Course add/drop',
          iconName: 'swap_horiz',
          bodyKo: '수강신청 후 과목을 변경해야 한다면 학교에서 정한 수강정정 기간을 이용할 수 '
              '있습니다.',
          bodyEn: 'If you need to change your courses after registering, you can '
              'do it during the add/drop period set by the university.',
          stepsKo: [
            '수강정정 희망 교과목 확인',
            '교과목 추가 또는 변경',
            '수강확정 / 탈락 여부 재확인',
            '최종 신청내역 확인',
          ],
          stepsEn: [
            'Decide which courses you want to change',
            'Add or swap the courses',
            'Check again whether they were confirmed or dropped',
            'Check your final registration list',
          ],
          notes: [
            GuideNote(
              titleKo: '수강정정 이후의 수강취소 기간',
              titleEn: 'The withdrawal period after add/drop',
              linesKo: [
                '수강정정이 끝난 뒤 별도의 수강취소 기간이 있을 수 있습니다.',
                '이 기간에는 이미 신청한 교과목의 취소만 가능하며 새로운 과목을 추가할 수 '
                    '없습니다.',
              ],
              linesEn: [
                'There may be a separate course-withdrawal period after add/drop '
                    'closes.',
                'In that period you can only cancel a course you already '
                    'registered for — you cannot add a new one.',
              ],
            ),
          ],
          noticeKo: '수강정정은 보통 학기 초에 진행되지만 정확한 일정은 매 학기 학사공지에서 '
              '확인하세요.',
          noticeEn: 'Add/drop normally runs at the start of the semester, but '
              'check the exact dates in the academic notices for that semester.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '최종 수강신청 확인',
          titleEn: 'Check your final registration',
          iconName: 'receipt_long',
          noticeKo: '최종 수강신청 내역을 확인하세요\n'
              '수강확정 후에는 수강신청 확인서를 확인하여 교과목, 분반, 재수강 여부 등을 '
              '정확하게 확인하세요.\n'
              '최종 수강신청 확인서에 기재되지 않은 교과목은 실제로 수업에 참여하더라도 학점과 '
              '성적이 인정되지 않을 수 있습니다.',
          noticeEn: 'Check your final course registration\n'
              'Once registration is confirmed, open your course registration '
              'confirmation and check every course, section, and retake flag.\n'
              'A course that is not on that confirmation may not earn you '
              'credits or a grade, even if you attend the classes.',
        ),
        GuideSection(
          titleKo: '외국인 유학생 필수이수교과목',
          titleEn: 'Required courses for international students',
          iconName: 'menu_book',
          bodyKo: '2024학년도 외국인 유학생 안내서 기준으로, 2023학년도 이후 외국인 '
              '특별전형으로 입학한 학부 신입생 중 한국어트랙 학생이 대상입니다. 편입학자는 '
              '제외됩니다.\n\n'
              'TOPIK 성적과 관계없이 지정된 외국인 유학생 필수교과목을 이수해야 합니다.',
          bodyEn: 'Per the 2024 international-student booklet, this applies to '
              'undergraduate freshmen admitted through the international '
              'special admission from 2023 onwards who are on the Korean '
              'language track. Transfer students are not included.\n\n'
              'You have to take the designated required courses regardless of '
              'your TOPIK score.',
          notes: [
            GuideNote(
              titleKo: '1학기 (2024 안내서 기준)',
              titleEn: 'First semester (per the 2024 booklet)',
              linesKo: [
                '대학한국어Ⅰ — 3학점 / 필수교양',
                '한국어발표와작문Ⅰ — 3학점 / 필수교양',
                '한류속한국어와한국문화Ⅰ — 2학점 / 토대교양',
              ],
              linesEn: [
                '대학한국어Ⅰ (College Korean I) — 3 credits / required general '
                    'education',
                '한국어발표와작문Ⅰ (Korean Presentation & Writing I) — 3 credits / '
                    'required general education',
                '한류속한국어와한국문화Ⅰ (Korean Language & Culture in the Korean Wave I) '
                    '— 2 credits / foundation general education',
              ],
            ),
            GuideNote(
              titleKo: '2학기 (2024 안내서 기준)',
              titleEn: 'Second semester (per the 2024 booklet)',
              linesKo: [
                '대학한국어Ⅱ — 3학점 / 필수교양',
                '한국어발표와작문Ⅱ — 3학점 / 필수교양',
                '한류속한국어와한국문화Ⅱ — 2학점 / 토대교양',
              ],
              linesEn: [
                '대학한국어Ⅱ (College Korean II) — 3 credits / required general '
                    'education',
                '한국어발표와작문Ⅱ (Korean Presentation & Writing II) — 3 credits / '
                    'required general education',
                '한류속한국어와한국문화Ⅱ (Korean Language & Culture in the Korean Wave '
                    'II) — 2 credits / foundation general education',
              ],
            ),
          ],
          noticeKo: '필수과목 시간이 겹친다면\n'
              '학과에서 지정한 다른 영역의 필수 교과목이 외국인 유학생 필수교과목과 겹치는 경우 '
              '학과 지정 과목을 우선 수강할 수 있습니다.\n'
              '외국인 유학생 필수교과목은 이후 학기에 이수할 수 있지만 졸업 전까지 반드시 '
              '이수해야 합니다.',
          noticeEn: 'If a required course clashes with another one\n'
              'If a required course designated by your department overlaps with '
              'a required course for international students, you may take the '
              "department's course first.\n"
              'You can then take the international-student course in a later '
              'semester — but you must complete it before you graduate.',
          noticeIconName: 'info',
          footnoteKo: '※ 위 과목명과 적용 대상은 2024학년도 외국인 유학생 안내서 기준입니다. '
              '교육과정은 변경될 수 있으므로 최신 필수이수교과목은 국제교류과 또는 해당 학년도 '
              '학사안내를 확인하세요.',
          footnoteEn: '※ The course names and who they apply to are from the '
              '2024 international-student booklet. Curricula change, so check '
              'the current required courses with the Office of International '
              'Affairs or in the academic guidance for your year.',
        ),
        GuideSection(
          titleKo: '반드시 기간 안에 신청하세요',
          titleEn: 'Register within the period',
          iconName: 'event_repeat',
          noticeKo: '수강신청을 하지 않으면 학점 취득이 불가능합니다\n'
              '등록금을 납부했더라도 지정된 기간에 수강신청을 하지 않으면 해당 학기의 학점을 '
              '취득할 수 없고 이수학기로 인정되지 않을 수 있습니다.\n'
              '반드시 정해진 기간 안에 수강신청을 완료하세요.',
          noticeEn: 'No registration means no credits\n'
              'Even if you have paid tuition, not registering during the set '
              'period can mean you earn no credits for that semester, and it '
              'may not count as a completed semester.\n'
              'Make sure you finish registration within the period.',
          footnoteKo: '※ 2024학년도 외국인 유학생 안내서에는 이 경우 이미 납부한 등록금이 '
              '반환되지 않는다고 안내되어 있습니다. 등록·학적 관련 규정은 변경될 수 있으므로 '
              '최신 학사규정을 확인하세요.',
          footnoteEn: '※ The 2024 international-student booklet states that '
              'tuition already paid is not refunded in this case. Tuition and '
              'student-record rules can change, so check the current academic '
              'regulations.',
        ),
        GuideSection(
          titleKo: '꼭 알아두세요',
          titleEn: 'Good to know',
          iconName: 'lightbulb',
          notes: [
            GuideNote(
              titleKo: '📅 일정은 매 학기 달라져요',
              titleEn: '📅 The schedule changes every semester',
              linesKo: [
                '수강신청과 수강정정 일정은 매 학기 달라질 수 있으므로 최신 학사공지를 '
                    '확인하세요.',
              ],
              linesEn: [
                'Registration and add/drop dates change from semester to '
                    'semester — check the latest academic notices.',
              ],
            ),
            GuideNote(
              titleKo: '✅ 확정 여부를 확인하세요',
              titleEn: '✅ Confirm that you actually got the course',
              linesKo: [
                '신청한 과목이 탈락할 수 있으므로 수강확정 결과를 반드시 확인하세요.',
              ],
              linesEn: [
                'A course you applied for can still be dropped, so always check '
                    'the confirmation result.',
              ],
            ),
            GuideNote(
              titleKo: '🧾 수강신청 확인서를 확인하세요',
              titleEn: '🧾 Read your registration confirmation',
              linesKo: [
                '최종 신청 과목, 분반, 재수강 여부 등을 확인하세요.',
              ],
              linesEn: [
                'Check the final courses, the section numbers, and whether '
                    'anything is flagged as a retake.',
              ],
            ),
            GuideNote(
              titleKo: '🏫 캠퍼스를 확인하세요',
              titleEn: '🏫 Check which campus a class is on',
              linesKo: [
                '동아대학교는 여러 캠퍼스를 운영하므로 연속된 수업의 캠퍼스가 다른 경우 '
                    '이동시간을 고려하세요.',
              ],
              linesEn: [
                'Dong-A University runs several campuses. If two back-to-back '
                    'classes are on different campuses, allow for the travel '
                    'time.',
              ],
            ),
            GuideNote(
              titleKo: '🔁 재수강 여부를 확인하세요',
              titleEn: '🔁 Check how a retake is counted',
              linesKo: [
                '동일 교과목 또는 유사·대체교과목을 재수강하는 경우 재수강 처리 여부를 '
                    '확인하세요.',
                '2024학년도 안내서에서는 재수강 횟수에 제한을 두고 F 성적에 예외를 두고 '
                    '있었습니다. 재수강 규정은 변경될 수 있으므로 최신 학사안내를 확인하세요.',
              ],
              linesEn: [
                'If you retake the same course, or a similar/substitute course, '
                    'check whether it is processed as a retake.',
                'The 2024 booklet limited how often a course could be retaken, '
                    'with an exception for an F grade. Retake rules can change '
                    '— check the latest academic guidance.',
              ],
            ),
          ],
          footnoteKo: '외국인 유학생의 학사 및 학교생활 관련 문의는 동아대학교 국제교류과 또는 '
              '소속 학과사무실에서 확인할 수 있습니다.',
          footnoteEn: 'For academic or student-life questions, international '
              'students can ask the Dong-A University Office of International '
              'Affairs or their own department office.',
        ),
      ],
      links: [
        // Current registration portal — this is what 학사안내 → 수강신청 및 수강정정 on
        // donga.ac.kr points at (the legacy sugang.donga.ac.kr host no longer
        // serves it).
        GuideLink(
          labelKo: '동아대학교 수강신청',
          labelEn: 'Dong-A University course registration',
          descriptionKo: '교과목 신청 · 수강확정 확인',
          descriptionEn: 'Register for courses and check the result',
          url: 'https://dxsugang.donga.ac.kr/',
          iconName: 'computer',
        ),
        // Official single sign-on page — students sign in with their student ID
        // number and their existing password, then reach the academic and
        // student-information services from there.
        GuideLink(
          labelKo: '동아대학교 통합로그인',
          labelEn: 'Dong-A University single sign-on',
          descriptionKo: '학사 · 학생정보 서비스 이용',
          descriptionEn: 'Sign in for academic and student information services',
          url: 'https://login.donga.ac.kr/login?rd_c_p=checked',
          iconName: 'badge',
        ),
        // 학사공지 board — where each semester's registration and add/drop dates
        // are actually announced.
        GuideLink(
          labelKo: '동아대학교 학사공지',
          labelEn: 'Dong-A University academic notices',
          descriptionKo: '최신 수강신청 일정 · 학사 안내',
          descriptionEn: 'The latest registration dates and academic notices',
          url: 'https://www.donga.ac.kr/kor/CMS/Board/Board.do?mCode=MN171',
        ),
      ],
      durationKo: '10~30분',
      durationEn: '10–30 minutes',
      difficulty: 2,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'certificate-issue',
      categoryId: GuideCategory.school,
      titleKo: '증명서 발급',
      titleEn: 'Certificate Issuance',
      summaryKo: '온라인 · 자동발급기 · 방문 발급',
      summaryEn: 'Online, kiosk & in-person issuance',
      iconName: 'receipt_long',
      overviewKo: '동아대학교에서는 재학증명서, 성적증명서, 졸업증명서 등 학교생활과 비자·취업·장학 '
          '신청에 필요한 각종 증명서를 발급할 수 있습니다.\n\n'
          '증명서는 인터넷, 교내 자동발급기, 어디서나민원(FAX), 우편 또는 학사관리과 방문 등 '
          '여러 방법으로 발급할 수 있습니다.\n\n'
          '일반적인 재학·성적·졸업 관련 증명서는 먼저 인터넷 발급 가능 여부를 확인하는 것이 가장 '
          '편리합니다.',
      overviewEn: 'At Dong-A University you can issue the certificates you need '
          'for student life and for visa, job or scholarship applications — an '
          'enrollment certificate, a transcript, a graduation certificate and '
          'more.\n\n'
          'There are several ways to get one: online, from a certificate kiosk '
          'on campus, through the "certificate by fax" civil-service desks, by '
          'post, or in person at the Office of Academic Affairs.\n\n'
          'For the usual enrollment, transcript and graduation certificates, '
          'the easiest thing is to check first whether you can issue it '
          'online.',
      // The "checklist" card is reused as the certificate menu: what you can
      // ask for, with the caveat that availability depends on your record.
      checklistTitleKo: '발급 가능한 증명서',
      checklistTitleEn: 'Certificates you can issue',
      checklistKo: [
        '재학증명서',
        '재적증명서',
        '휴학증명서',
        '제적증명서',
        '졸업(학위수여)증명서',
        '졸업(학위수여)예정증명서',
        '성적증명서',
        '수료증명서',
        '복학예정증명서',
      ],
      checklistEn: [
        'Certificate of Enrollment (재학증명서)',
        'Certificate of Registration (재적증명서)',
        'Certificate of Leave of Absence (휴학증명서)',
        'Certificate of Removal from the Register (제적증명서)',
        'Graduation / Degree Certificate (졸업증명서)',
        'Certificate of Expected Graduation (졸업예정증명서)',
        'Academic Transcript (성적증명서)',
        'Certificate of Completion (수료증명서)',
        'Certificate of Expected Reinstatement (복학예정증명서)',
      ],
      checklistNoteKo: '대부분의 증명서는 국문과 영문 모두 발급할 수 있습니다.\n'
          '※ 증명서 종류와 학적 상태에 따라 인터넷 또는 자동발급기로 발급할 수 없는 경우가 '
          '있습니다. 졸업예정증명서처럼 학부는 마지막 학기(8학기) 등록 이후에만 발급되는 등 '
          '조건이 붙는 증명서도 있으므로, 필요한 증명서가 지금 발급 가능한지 먼저 확인하세요.',
      checklistNoteEn: 'Most of these come in both Korean and English.\n'
          '※ Depending on the certificate and on your enrollment status, some '
          'cannot be issued online or at a kiosk. Some also have conditions — '
          'an expected-graduation certificate, for instance, is only issued to '
          'undergraduates once they have registered for their final (8th) '
          'semester. Check that the one you need is available to you right '
          'now.',
      sections: [
        // Online first: it is the only route an international student can
        // complete without walking to a specific building.
        GuideSection(
          titleKo: '가장 간단한 방법 — 인터넷 발급',
          titleEn: 'The simplest way — issue it online',
          iconName: 'computer',
          bodyKo: '동아대학교 인터넷 증명발급 서비스를 이용하면 필요한 증명서를 온라인으로 신청한 '
              '뒤 파일 또는 프린터로 발급할 수 있습니다.\n\n'
              '동아대학교 증명서발급 페이지의 「인터넷증명발급」에서 접속할 수 있습니다.',
          bodyEn: "With Dong-A University's online certificate service you "
              'apply for the certificate you need on the web, then save it as a '
              'file or print it out.\n\n'
              'You reach it from the university\'s certificate page, under '
              '「인터넷증명발급」 (online certificate issuance).',
          notes: [
            GuideNote(
              titleKo: '한눈에 보기',
              titleEn: 'At a glance',
              linesKo: [
                '소요시간: 즉시 발급',
                '결제: 휴대폰 소액결제 또는 신용카드',
                '발급 형태: 파일 저장 또는 프린터 출력',
              ],
              linesEn: [
                'How long it takes: issued immediately',
                'Payment: mobile carrier billing or credit card',
                'What you get: a file to save, or a printout',
              ],
            ),
          ],
          stepsKo: [
            '동아대학교 증명서발급 페이지 접속',
            '인터넷증명발급 선택',
            '로그인 또는 본인확인',
            '필요한 증명서 선택',
            '발급 매수 및 정보 확인',
            '수수료 결제',
            '파일 또는 프린터로 발급',
          ],
          stepsEn: [
            'Open the Dong-A University certificate page',
            'Choose 인터넷증명발급 (online certificate issuance)',
            'Log in, or verify your identity',
            'Pick the certificate you need',
            'Check the number of copies and your details',
            'Pay the fee',
            'Save it as a file, or print it',
          ],
          noticeKo: '영문 증명서를 처음 발급한다면\n'
              '영문 증명서는 학교 시스템에 영문 성명을 먼저 등록해야 발급할 수 있습니다. '
              '아래 「영문 증명서가 필요한가요?」를 먼저 확인하세요.',
          noticeEn: 'Issuing an English certificate for the first time?\n'
              'You have to register your name in English on the university '
              'system before an English certificate can be issued. Read "Need '
              'an English certificate?" below first.',
          noticeIconName: 'badge',
          footnoteKo: '※ 2024학년도 외국인 유학생 안내서에는 인터넷 증명발급 대상이 재학생·휴학생·'
              '졸업생·제적생으로 안내되어 있었습니다. 대상과 발급 경로는 변경될 수 있으므로 학교 '
              '증명서발급 페이지의 최신 안내를 확인하세요.',
          footnoteEn: '※ The 2024 international-student booklet listed enrolled, '
              'on-leave, graduated and removed students as eligible for online '
              'issuance. Eligibility and the service itself can change — check '
              "the latest notice on the university's certificate page.",
        ),
        // Kiosk locations follow the dedicated 증명서자동발급기 page, not the 2024
        // booklet (which still puts the 승학 machine in the 본부 basement).
        GuideSection(
          titleKo: '교내 증명서 자동발급기',
          titleEn: 'Certificate kiosks on campus',
          iconName: 'location_on',
          bodyKo: '교내 증명서 자동발급기에서도 국문·영문 증명서를 즉시 출력할 수 있습니다.\n\n'
              '소요시간은 즉시이며, 학번과 학생정보 시스템 비밀번호로 본인 확인을 합니다.',
          bodyEn: 'You can also print Korean and English certificates on the '
              'spot from a certificate kiosk on campus.\n\n'
              'It takes only a moment: you identify yourself with your student '
              'ID number and your student-information system password.',
          notes: [
            GuideNote(
              titleKo: '설치 위치',
              titleEn: 'Where the kiosks are',
              linesKo: [
                '승학캠퍼스: 인문과학대학 로비',
                '부민캠퍼스: 사회과학대학 로비',
                '구덕캠퍼스: 구덕캠퍼스에서 증명서 발급이 필요한 경우 의과대학 행정지원실에 '
                    '문의하세요.',
              ],
              linesEn: [
                'Seunghak campus: lobby of the College of Humanities '
                    '(인문과학대학)',
                'Bumin campus: lobby of the College of Social Sciences '
                    '(사회과학대학)',
                'Gudeok campus: there is no kiosk — ask the College of Medicine '
                    'administrative office if you need a certificate there.',
              ],
            ),
            GuideNote(
              titleKo: '이용시간',
              titleEn: 'When you can use them',
              linesKo: [
                '공식 안내상 연중 24시간 이용할 수 있습니다.',
                '다만 건물 보안상 폐쇄에 따라 실제 이용시간이 달라질 수 있습니다.',
              ],
              linesEn: [
                'The official notice says they are available 24 hours a day, '
                    'all year round.',
                'In practice the hours can change, because the building itself '
                    'may be locked for security.',
              ],
            ),
            GuideNote(
              titleKo: '결제 방법',
              titleEn: 'How to pay',
              linesKo: ['현금', '휴대폰', '체크카드', '신용카드'],
              linesEn: [
                'Cash',
                'Mobile carrier billing',
                'Debit card',
                'Credit card',
              ],
            ),
            GuideNote(
              titleKo: '자동발급기로 발급할 수 없는 서류',
              titleEn: 'What the kiosk cannot issue',
              linesKo: [
                '학적부 사본 — 학사관리과',
                '장학금 수혜 확인서 — 학생복지과 장학팀',
                '입학성적증명서 — 입학관리과',
                '대학원 학적부 사본 — 각 대학원 행정지원실',
              ],
              linesEn: [
                'A copy of your student record (학적부) — Office of Academic '
                    'Affairs',
                'Scholarship award confirmation — Student Welfare, scholarship '
                    'team',
                'Admission score certificate — Office of Admissions',
                'Graduate-school student record — your graduate school office',
              ],
            ),
          ],
          stepsKo: [
            '자동발급기에서 학부 또는 대학원 선택',
            '학번과 비밀번호 입력',
            '증명서 종류 선택',
            '발급 매수 확인',
            '수수료 결제',
            '증명서 출력',
          ],
          stepsEn: [
            'At the kiosk, choose undergraduate or graduate school',
            'Enter your student ID number and password',
            'Pick the type of certificate',
            'Check the number of copies',
            'Pay the fee',
            'Take the printed certificate',
          ],
          noticeKo: '건물이 닫히면 이용할 수 없어요\n'
              '연중 24시간 운영이 원칙이지만 건물 보안상 폐쇄에 따라 이용시간이 달라질 수 '
              '있습니다.\n'
              '늦은 시간에 방문하기 전에 건물 개방 여부를 먼저 확인하세요.',
          noticeEn: 'You cannot use a kiosk in a locked building\n'
              'They are meant to run 24 hours a day all year, but the hours '
              'change when a building is closed for security.\n'
              'Check that the building is open before going late at night.',
          footnoteKo: '※ 2024학년도 외국인 유학생 안내서에는 승학캠퍼스 자동발급기가 본부건물 '
              '지하 1층 ATM 옆, 이용시간 08:30~22:00으로 안내되어 있었습니다. 이 페이지는 '
              '동아대학교 증명서자동발급기 공식 안내의 최신 위치와 이용시간을 따릅니다.',
          footnoteEn: '※ The 2024 international-student booklet placed the '
              'Seunghak kiosk next to the ATM in the basement of the main '
              'administration building, open 08:30–22:00. This page follows the '
              "location and hours on the university's current certificate-kiosk "
              'notice instead.',
        ),
        GuideSection(
          titleKo: '기타 발급 방법',
          titleEn: 'Other ways to get a certificate',
          iconName: 'storefront',
          bodyKo: '인터넷 발급과 자동발급기 외에도 다음 방법을 이용할 수 있습니다.',
          bodyEn: 'Besides online issuance and the kiosks, these routes are '
              'available.',
          notes: [
            GuideNote(
              titleKo: '어디서나민원(FAX)',
              titleEn: 'Certificate by fax (어디서나민원)',
              linesKo: [
                '정부24 또는 전국 시·군·구청, 교육청, 주민센터 등을 통해 증명서 발급을 신청할 '
                    '수 있습니다.',
                '이용시간: 평일 09:00~17:00',
                '소요시간: 약 2시간 이내',
                '운영시간과 처리시간은 변경될 수 있으므로 신청 전에 최신 안내를 확인하세요.',
              ],
              linesEn: [
                'You can apply through Government24 (정부24) or at a city, '
                    'county or district office, an education office, or a '
                    'community service center anywhere in Korea.',
                'Hours: weekdays 09:00–17:00',
                'How long it takes: usually within about 2 hours',
                'Hours and processing times can change, so check the current '
                    'notice before you go.',
              ],
            ),
            GuideNote(
              titleKo: '온라인 우편발송',
              titleEn: 'Online postal delivery',
              linesKo: [
                '학교의 우편 증명서 발송 서비스를 통해 증명서를 우편으로 받을 수 있습니다.',
                '국내: 약 1~4일 (주말·공휴일 제외)',
                '해외: 국가별로 다릅니다.',
                '결제: 휴대폰 소액결제 또는 신용카드',
              ],
              linesEn: [
                "The university's postal certificate service mails the "
                    'certificate to you.',
                'Within Korea: about 1–4 days (weekends and holidays excluded)',
                'Overseas: it depends on the country.',
                'Payment: mobile carrier billing or credit card',
              ],
            ),
            GuideNote(
              titleKo: '우체국 민원우편',
              titleEn: 'Post-office civil-service mail',
              linesKo: [
                '전국 우체국에서 민원우편으로 증명서 발급을 신청할 수도 있습니다.',
                '약 3~5일이 걸리며, 지역에 따라 달라질 수 있습니다.',
              ],
              linesEn: [
                'Any post office in Korea can take a civil-service mail request '
                    'for a certificate.',
                'It takes about 3–5 days, and can be longer depending on the '
                    'region.',
              ],
            ),
            GuideNote(
              titleKo: '학사관리과 방문',
              titleEn: 'In person at the Office of Academic Affairs',
              linesKo: [
                '인터넷이나 자동발급기로 처리하기 어려운 증명서는 학사관리과에서 직접 '
                    '발급하거나 문의할 수 있습니다.',
                '운영시간: 평일 09:00~17:00 (12:00~13:00 제외)',
                '토요일·일요일·공휴일과 개교기념일에는 운영하지 않습니다.',
                '문의: 051-200-6090~1',
              ],
              linesEn: [
                'For anything the website or the kiosk cannot handle, the '
                    'Office of Academic Affairs issues it at the counter, or '
                    'tells you what to do.',
                'Hours: weekdays 09:00–17:00 (closed 12:00–13:00)',
                'Closed on Saturdays, Sundays, public holidays and the '
                    "university's foundation day.",
                'Phone: 051-200-6090~1',
              ],
            ),
          ],
          noticeKo: '우편이 이미 발송되었다면\n'
              '증명서가 이미 발송 완료된 경우 발급 취소 및 결제 취소가 불가능할 수 있습니다.',
          noticeEn: 'Once it is in the post\n'
              'When a certificate has already been marked as sent, you may no '
              'longer be able to cancel the request or the payment.',
        ),
        GuideSection(
          titleKo: '영문 증명서가 필요한가요?',
          titleEn: 'Need an English certificate?',
          iconName: 'badge',
          bodyKo: '영문 증명서를 처음 발급하는 경우 학교 시스템에 영문 성명이 등록되어 있어야 '
              '합니다.\n\n'
              '발급 전에 등록된 영문 이름이 여권의 영문 이름과 정확하게 일치하는지 확인하는 것을 '
              '권장합니다.',
          bodyEn: 'The first time you issue a certificate in English, your name '
              'in English has to be registered on the university system.\n\n'
              'Before you issue anything, check that the English name on record '
              'matches the one in your passport exactly.',
          notes: [
            GuideNote(
              titleKo: '영문 성명 등록 경로',
              titleEn: 'Where to register your English name',
              linesKo: [
                '동아대학교 통합정보시스템에 로그인한 뒤 학생정보 → 학적변동 → 개인정보변경에서 '
                    '영문 성명을 등록합니다.',
                '자동발급기에서 영문 증명서를 뽑을 때에도 영문 성명이 먼저 등록되어 있어야 '
                    '합니다.',
              ],
              linesEn: [
                'Sign in to the Dong-A Integrated Information System, then go '
                    'to Student Information → Academic Status → Personal '
                    'Information and register your name in English.',
                'This applies to the kiosks too — an English certificate will '
                    'not print until the English name is registered.',
              ],
            ),
          ],
          noticeKo: '여권과 철자가 같아야 해요\n'
              '비자·입학·취업 서류는 여권과 철자나 띄어쓰기가 다르면 반려될 수 있습니다.\n'
              '등록할 때 여권을 보고 그대로 입력하세요.',
          noticeEn: 'The spelling has to match your passport\n'
              'Visa, admission and employment documents can be rejected if the '
              'spelling or spacing differs from your passport.\n'
              'Copy it from the passport exactly when you register it.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '특수한 증명서가 필요한 경우',
          titleEn: 'When you need something special',
          iconName: 'info',
          bodyKo: '제출기관이 일반 증명서와 다른 형식을 요구하는 경우에는 발급 방법이 '
              '달라집니다.',
          bodyEn: 'When the institution receiving the document asks for '
              'something other than a standard certificate, the way you get it '
              'changes.',
          notes: [
            GuideNote(
              titleKo: '석차가 표시된 성적증명서',
              titleEn: 'A transcript showing your class rank',
              linesKo: [
                '성적증명서에 석차를 기재해야 하는 경우 학사관리과에 문의하세요.',
              ],
              linesEn: [
                'If your transcript has to show your class rank, ask the Office '
                    'of Academic Affairs.',
              ],
            ),
            GuideNote(
              titleKo: 'Sealing(밀봉) 또는 압인',
              titleEn: 'Sealing or an embossed stamp',
              linesKo: [
                '해외 대학, 비자, 취업기관 등 제출기관에서 밀봉(Sealing)이나 압인 등 별도 '
                    '형식을 요구하는 경우 일반 인터넷 발급만으로 충분하지 않을 수 있습니다.',
                '제출기관의 요구사항을 먼저 확인한 뒤 학사관리과에 문의하세요.',
              ],
              linesEn: [
                'Overseas universities, immigration offices and employers often '
                    'require a sealed envelope or an embossed stamp — a plain '
                    'online printout may not be accepted.',
                'Find out exactly what the receiving institution requires, then '
                    'ask the Office of Academic Affairs.',
              ],
            ),
            GuideNote(
              titleKo: '학적부 사본',
              titleEn: 'A copy of your student record (학적부)',
              linesKo: [
                '학적부 사본은 일반 인터넷 발급이나 자동발급기로 발급할 수 없는 경우가 있으며 '
                    'FAX민원 또는 학사관리과 데스크를 이용해야 할 수 있습니다.',
              ],
              linesEn: [
                'A copy of your student record often cannot be issued online or '
                    'at a kiosk — you may have to use the certificate-by-fax '
                    'route or the Office of Academic Affairs counter.',
              ],
            ),
          ],
          footnoteKo: '※ 학적부, 그리고 일정 시점 이전 졸업자의 증명서 등은 인터넷 발급이나 '
              '자동발급기로 발급할 수 없는 경우가 있습니다.',
          footnoteEn: '※ Student records, and certificates for students who '
              'graduated before a certain date, are among the documents that '
              'cannot always be issued online or at a kiosk.',
        ),
        GuideSection(
          titleKo: '통합정보시스템에서 발급하는 서류',
          titleEn: 'Documents available through the Integrated Information '
              'System',
          iconName: 'payments',
          bodyKo: '일부 등록금·장학 관련 서류는 일반 증명서 발급 서비스가 아니라 동아대학교 '
              '통합정보시스템에서 직접 조회하거나 출력할 수 있습니다.',
          bodyEn: 'Some tuition and scholarship documents do not come from the '
              'certificate service at all — you look them up and print them '
              'yourself in the Dong-A Integrated Information System.',
          notes: [
            GuideNote(
              titleKo: '여기서 발급하는 서류',
              titleEn: 'What you get there',
              linesKo: [
                '등록금(학생회비) 납입 확인서',
                '교육비 납입 증명서',
                '장학금 수혜 확인서',
              ],
              linesEn: [
                'Tuition (and student-union fee) payment confirmation',
                'Certificate of education expenses paid',
                'Scholarship award confirmation',
              ],
            ),
          ],
          noticeKo: '바로 발급됩니다\n'
              '통합정보시스템에 로그인한 뒤 해당 메뉴에서 즉시 조회하고 출력할 수 있습니다.',
          noticeEn: 'Available immediately\n'
              'Sign in to the Integrated Information System and you can view '
              'and print them straight away.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '꼭 알아두세요',
          titleEn: 'Good to know',
          iconName: 'lightbulb',
          notes: [
            GuideNote(
              titleKo: '🌐 인터넷 발급부터 확인하세요',
              titleEn: '🌐 Check online issuance first',
              linesKo: [
                '일반적인 재학·성적·졸업 관련 증명서는 인터넷으로 즉시 발급할 수 있는지 먼저 '
                    '확인하세요.',
              ],
              linesEn: [
                'For an ordinary enrollment, transcript or graduation '
                    'certificate, check first whether you can just issue it '
                    'online in a minute.',
              ],
            ),
            GuideNote(
              titleKo: '🇬🇧 영문 이름을 확인하세요',
              titleEn: '🇬🇧 Check your English name',
              linesKo: [
                '영문 증명서 발급 전 학교에 등록된 영문 이름과 여권의 영문 이름이 일치하는지 '
                    '확인하세요.',
              ],
              linesEn: [
                'Before issuing anything in English, make sure the English name '
                    'registered at the university matches your passport.',
              ],
            ),
            GuideNote(
              titleKo: '📄 모든 증명서가 온라인 발급되는 것은 아니에요',
              titleEn: '📄 Not every certificate can be issued online',
              linesKo: [
                '학적부 사본이나 특수한 형태의 증명서는 별도의 발급 절차가 필요할 수 있습니다.',
              ],
              linesEn: [
                'A copy of your student record, or a certificate in a special '
                    'format, may need a separate procedure.',
              ],
            ),
            GuideNote(
              titleKo: '🔏 해외 제출 요건을 확인하세요',
              titleEn: '🔏 Check the requirements of the receiving institution',
              linesKo: [
                '해외 대학·기관에 제출하는 경우 Sealing, 압인, 석차 표기 등 별도 요구사항이 '
                    '있는지 먼저 확인하세요.',
              ],
              linesEn: [
                'If the document goes to a university or an office abroad, ask '
                    'them first whether they need sealing, an embossed stamp, '
                    'or your class rank on it.',
              ],
            ),
            GuideNote(
              titleKo: '💰 수수료는 발급 전에 확인하세요',
              titleEn: '💰 Check the fee before you issue',
              linesKo: [
                '증명서 수수료는 증명서 종류와 학적 상태에 따라 다릅니다.',
                '2024학년도 외국인 유학생 안내서에 안내된 금액은 현재와 다를 수 있으므로, 실제 '
                    '결제 단계나 동아대학교 최신 공식 안내에서 금액을 확인하세요.',
              ],
              linesEn: [
                'The fee depends on the certificate and on your enrollment '
                    'status.',
                'The amounts printed in the 2024 international-student booklet '
                    'may no longer be current — check the figure shown at the '
                    "payment step, or the university's latest official notice.",
              ],
            ),
          ],
          footnoteKo: '증명서 발급 관련 문의는 동아대학교 학사관리과(051-200-6090~1)에서 확인할 '
              '수 있습니다.',
          footnoteEn: 'For questions about certificates, contact the Dong-A '
              'University Office of Academic Affairs on 051-200-6090~1.',
        ),
      ],
      links: [
        // Official 생활정보 → 증명서발급 page: the certificate table, every
        // issuing route, and the caveats live here.
        GuideLink(
          labelKo: '동아대학교 증명서 발급 안내',
          labelEn: 'Dong-A University certificate issuance',
          descriptionKo: '발급 방법 · 증명서 종류 · 유의사항',
          descriptionEn: 'How to issue, certificate types, and what to watch for',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN200',
          iconName: 'receipt_long',
        ),
        // What the "인터넷증명발급 바로가기" on that page actually points at.
        GuideLink(
          labelKo: '인터넷 증명발급',
          labelEn: 'Online certificate issuance',
          descriptionKo: '온라인 즉시 발급',
          descriptionEn: 'Issue it online, right away',
          url: 'https://dx.donga.ac.kr/certificate/login.jsp',
          iconName: 'computer',
        ),
        // Integrated Information System — where the tuition/scholarship
        // documents and the English-name registration actually live.
        GuideLink(
          labelKo: '동아대학교 통합정보시스템',
          labelEn: 'Dong-A University Integrated Information System',
          descriptionKo: '등록금 · 교육비 · 장학 관련 증명 확인',
          descriptionEn: 'Tuition, education-cost and scholarship documents',
          url: 'https://dx.donga.ac.kr/',
          iconName: 'badge',
        ),
        // Dedicated kiosk page — the authority for the locations above.
        GuideLink(
          labelKo: '증명서 자동발급기 안내',
          labelEn: 'Certificate kiosk guide',
          descriptionKo: '설치 위치 · 이용시간',
          descriptionEn: 'Where the kiosks are and when they are open',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN284',
          iconName: 'location_on',
        ),
      ],
      // 승학 인문과학대학 = s01(대학본부 및 인문과학대학), 부민 사회과학대학 = b04(종합강의동).
      relatedFacilityIds: ['s01', 'b04'],
      durationKo: '즉시~수일',
      durationEn: 'Instant to a few days',
      difficulty: 1,
      status: GuideStatus.published,
    ),
    // Content follows the current library site (library.donga.ac.kr), checked
    // 2026-08-27. The 2024 international-student booklet is the background
    // source; where the two disagree — opening hours above all — the live site
    // wins and the booklet figure only ever appears as an attributed footnote.
    const AdminGuideItem(
      id: 'library-guide',
      categoryId: GuideCategory.school,
      titleKo: '도서관 이용안내',
      titleEn: 'Library Guide',
      summaryKo: '대출 · 열람실 · 모바일 이용증',
      summaryEn: 'Borrowing, study rooms & mobile ID',
      iconName: 'menu_book',
      overviewKo: '동아대학교에는 승학캠퍼스의 한림도서관, 부민캠퍼스의 부민도서관과 법학도서분관, '
          '구덕캠퍼스의 의학도서분관이 있습니다.\n\n'
          '도서 대출과 반납뿐 아니라 열람실, 그룹스터디실, 전자자료, 학술DB, 캠퍼스간 대출 등 '
          '다양한 서비스를 이용할 수 있습니다.\n\n'
          '외국인 학생도 동아대학교 학생 계정과 학생증 또는 모바일 이용증을 이용하여 도서관 '
          '서비스를 사용할 수 있습니다.',
      overviewEn: 'Dong-A University has four libraries: Hallim Library on the '
          'Seunghak campus, Bumin Library and the Law Library Branch on the '
          'Bumin campus, and the Medical Library Branch on the Gudeok '
          'campus.\n\n'
          'They are not only for borrowing and returning books — you can also '
          'use study rooms and group study rooms, read e-journals and academic '
          'databases, and have a book sent over from another campus.\n\n'
          'As an international student you use the same services as everyone '
          'else: log in with your Dong-A University account and identify '
          'yourself with your student ID card or with the mobile library ID in '
          'the library app.',
      topSections: [
        // Which library you want comes before anything you do inside it.
        GuideSection(
          titleKo: '도서관 위치',
          titleEn: 'Where the libraries are',
          iconName: 'location_on',
          bodyKo: '이용하려는 캠퍼스의 도서관을 먼저 확인하세요. 자료실 구성과 층 위치는 도서관마다 '
              '다릅니다.',
          bodyEn: 'Start with the library on your own campus — each one is laid '
              'out differently and holds a different collection.',
          notes: [
            GuideNote(
              titleKo: '승학캠퍼스 — 한림도서관',
              titleEn: 'Seunghak campus — Hallim Library',
              linesKo: [
                '승학캠퍼스의 대표 도서관으로 자료실, 열람실, 그룹스터디실 등을 이용할 수 있습니다.',
                '건물: S10 한림도서관',
                '문의: 051-200-6273',
              ],
              linesEn: [
                'The main library on the Seunghak campus: collections, study '
                    'rooms and group study rooms.',
                'Building: S10, Hallim Library',
                'Phone: 051-200-6273',
              ],
            ),
            GuideNote(
              titleKo: '부민캠퍼스 — 부민도서관',
              titleEn: 'Bumin campus — Bumin Library',
              linesKo: [
                '부민캠퍼스 국제관에 위치하며 자료실, 열람실, 그룹스터디실 등을 이용할 수 있습니다.',
                '건물: B05 국제관 5~10층',
                '문의: 051-200-8434',
              ],
              linesEn: [
                'Inside the International Building on the Bumin campus: '
                    'collections, study rooms and group study rooms.',
                'Building: B05, International Building, floors 5–10',
                'Phone: 051-200-8434',
              ],
            ),
            GuideNote(
              titleKo: '부민캠퍼스 — 법학도서분관',
              titleEn: 'Bumin campus — Law Library Branch',
              linesKo: [
                '법학전문대학원 건물에 위치하며 법학 관련 자료를 이용할 수 있습니다.',
                '건물: B02 법학전문대학원 1층',
                '문의: 051-200-8441',
              ],
              linesEn: [
                'In the Law School building, for legal collections.',
                'Building: B02, Law School, 1st floor',
                'Phone: 051-200-8441',
              ],
            ),
            GuideNote(
              titleKo: '구덕캠퍼스 — 의학도서분관',
              titleEn: 'Gudeok campus — Medical Library Branch',
              linesKo: [
                '의학·간호 분야의 자료를 이용할 수 있는 도서분관입니다.',
                '건물: G05 (구덕캠퍼스)',
                '문의: 051-240-2938',
              ],
              linesEn: [
                'A branch library for medicine and nursing.',
                'Building: G05 (Gudeok campus)',
                'Phone: 051-240-2938',
              ],
            ),
          ],
          footnoteKo: '※ 건물·층과 연락처는 도서관 홈페이지 「찾아오시는 길」 기준입니다. 각 층에 무엇이 '
              '있는지는 홈페이지의 「층별 안내」에서 확인할 수 있습니다.',
          footnoteEn: '※ Buildings, floors and phone numbers follow the '
              '"Directions" page on the library website. What sits on each '
              'floor is shown on its "Floor guide" page.',
        ),
        // The one thing to set up before a first visit.
        GuideSection(
          titleKo: '처음 이용한다면',
          titleEn: 'Using the library for the first time',
          iconName: 'smartphone',
          bodyKo: '동아대학교 도서관 앱의 모바일 이용증을 먼저 준비해 두면 도서관에서 할 수 있는 일이 '
              '대부분 휴대폰 하나로 해결됩니다.',
          bodyEn: 'Set up the mobile library ID in the Dong-A University '
              'Library app first — after that your phone covers almost '
              'everything you do in the library.',
          stepsKo: [
            'App Store 또는 Google Play에서 「동아대학교 도서관」 앱 설치',
            '동아대학교 통합정보시스템 계정으로 로그인',
            '앱 화면 오른쪽 위의 「이용증」 메뉴 선택',
            '모바일 이용증 확인',
            '도서관 출입 · 도서 대출 · 좌석배정 등에 사용',
          ],
          stepsEn: [
            'Install the "동아대학교 도서관" app from the App Store or Google Play',
            'Log in with your Dong-A University integrated information system '
                'account',
            'Open the ID card (이용증) menu at the top right of the app',
            'Your mobile library ID appears on screen',
            'Show it to enter the library, borrow books and take a seat',
          ],
          notes: [
            GuideNote(
              titleKo: '학생증도 그대로 사용할 수 있어요',
              titleEn: 'Your student ID card still works',
              linesKo: [
                '실물 학생증으로도 도서관에 출입하고 도서를 대출할 수 있습니다.',
                '학생증과 모바일 이용증 중 편한 것을 사용하면 됩니다.',
              ],
              linesEn: [
                'You can still use the plastic student ID card to enter the '
                    'library and borrow books.',
                'Use whichever is easier for you — the card or the app.',
              ],
            ),
          ],
          noticeKo: '모바일 이용증을 준비하세요\n'
              '동아대학교 도서관 앱의 모바일 이용증은 도서관 출입, 도서 대출, 열람실 좌석배정 등에 '
              '사용할 수 있습니다.',
          noticeEn: 'Set up your mobile library ID\n'
              'The mobile library ID in the app is what identifies you when you '
              'enter the library, borrow a book or take a seat in a study room.',
          noticeIconName: 'badge',
          footnoteKo: '※ 학생증의 사용처(학생 확인용, 도서 대출, 열람실 이용)와 무료 발급 안내는 '
              '2024학년도 외국인 유학생 안내서 기준입니다. 학생증 발급 절차는 학사관리과 안내를 '
              '확인하세요.',
          footnoteEn: '※ What the student ID card is used for (identification, '
              'borrowing, study rooms) and the fact that it is issued free of '
              'charge come from the 2024 international-student booklet. For how '
              'to get one, check with the Office of Academic Affairs.',
        ),
      ],
      sections: [
        GuideSection(
          titleKo: '도서 대출',
          titleEn: 'Borrowing Books',
          iconName: 'menu_book',
          bodyKo: '대출 데스크 또는 무인대출기를 이용하여 학생증이나 모바일 이용증으로 도서를 '
              '대출할 수 있습니다.',
          bodyEn: 'Borrow at the loan desk, or by yourself at a self-checkout '
              'machine, using your student ID card or your mobile library ID.',
          notes: [
            GuideNote(
              titleKo: '대출 책수와 기간',
              titleEn: 'How many books, for how long',
              linesKo: [
                '학부 재학생: 10책 / 14일',
                '대학원생: 10책 / 30일',
                '비전임교원 · 직원: 10책 / 30일',
                '전임교원: 30책 / 90일',
              ],
              linesEn: [
                'Undergraduate students: 10 books for 14 days',
                'Graduate students: 10 books for 30 days',
                'Non-tenured teaching staff and staff: 10 books for 30 days',
                'Full-time faculty: 30 books for 90 days',
              ],
            ),
            GuideNote(
              titleKo: '대출기간을 연장할 수 있어요',
              titleEn: 'You can extend the loan',
              linesKo: [
                '대출한 자료는 반납예정일 전에 재대출할 수 있습니다.',
                '재대출은 최초 대출기간과 동일한 기간으로 1회만 가능합니다.',
                '예약자가 있거나 연체 중인 경우 재대출이 제한됩니다.',
                '신청: 도서관 홈페이지 로그인 → My Library → 대출/재대출/예약조회 → 대출 및 재대출',
              ],
              linesEn: [
                'Renew a book before its due date and you keep it longer.',
                'You can renew once, for the same length as the original loan.',
                'You cannot renew a book someone has reserved, or while you have '
                    'anything overdue.',
                'Where: log in to the library website → My Library → '
                    '대출/재대출/예약조회 (loans, renewals & reservations) → '
                    '대출 및 재대출',
              ],
            ),
          ],
          noticeKo: '대출할 수 없는 자료도 있어요\n'
              '학위논문과 연속간행물은 대출되지 않습니다. 무인대출기는 기기가 설치된 도서관에서만 '
              '이용할 수 있습니다.',
          noticeEn: 'Some materials cannot be taken out\n'
              'Theses and periodicals are for use inside the library only. '
              'Self-checkout machines are available only at the libraries that '
              'have one.',
          noticeIconName: 'info',
        ),
        GuideSection(
          titleKo: '반납 · 연체',
          titleEn: 'Returns & Overdue Items',
          iconName: 'event_repeat',
          bodyKo: '대출한 도서는 한림도서관, 부민도서관, 법학도서분관, 의학도서분관 중 어느 곳에서도 '
              '반납할 수 있습니다.\n\n'
              '도서관이 문을 닫은 시간에는 무인반납함을 이용하세요.',
          bodyEn: 'Return a book to any of the four libraries — Hallim, Bumin, '
              'the Law Library Branch or the Medical Library Branch. It does '
              'not have to go back where you borrowed it.\n\n'
              'When the library is closed, use a book return box.',
          notes: [
            GuideNote(
              titleKo: '무인반납함 위치',
              titleEn: 'Where the return boxes are',
              linesKo: [
                '한림도서관: 한림도서관 2층',
                '부민도서관: 국제관 1층, 지하 1층',
                '법학도서분관: 도서관 입구',
                '의학도서분관: 간호대 1층',
              ],
              linesEn: [
                'Hallim Library: 2nd floor of the library',
                'Bumin Library: International Building, 1st floor and basement '
                    '1st floor',
                'Law Library Branch: at the library entrance',
                'Medical Library Branch: 1st floor of the Nursing building',
              ],
            ),
          ],
          noticeKo: '반납일을 꼭 확인하세요\n'
              '대출한 자료를 연체하면 일정 기간 도서 대출이 제한될 수 있습니다. 현재 규정은 '
              '1책당 연체 1일마다 대출중지 1일입니다.',
          noticeEn: 'Keep an eye on the due date\n'
              'Returning late suspends your borrowing for a while: the current '
              'rule is one day of suspension per book per day overdue.',
        ),
        GuideSection(
          titleKo: '열람실 이용',
          titleEn: 'Study Room & Seat Reservation',
          iconName: 'school',
          bodyKo: '열람실 좌석은 동아대학교 도서관 앱에서 예약한 뒤 인증(발권확정)해야 이용할 수 '
              '있습니다.',
          bodyEn: 'Seats in the study rooms are booked in the library app — and '
              'a booking only becomes a seat once you check in.',
          stepsKo: [
            '동아대학교 도서관 앱에 통합정보시스템 계정으로 로그인',
            '「열람실 예약」 선택',
            '도서관 선택',
            '열람실 선택',
            '좌석 선택 후 예약 완료',
            '20분 이내에 예약 인증(발권확정)',
            '좌석 이용',
            '이용 종료 후 앱에서 좌석 반납',
          ],
          stepsEn: [
            'Log in to the library app with your integrated information system '
                'account',
            'Choose 열람실 예약 (reserve a seat)',
            'Pick the library',
            'Pick the study room',
            'Pick a seat and confirm the booking',
            'Check in within 20 minutes to confirm the seat',
            'Use your seat',
            'Release the seat in the app when you leave',
          ],
          notes: [
            GuideNote(
              titleKo: '인증 방법은 두 가지예요',
              titleEn: 'Two ways to check in',
              linesKo: [
                '열람실 안에서 앱의 「예약인증」 선택 — 비콘 인증이므로 블루투스를 켜 두세요.',
                '도서관 안의 좌석배정기(키오스크)에서 모바일 이용증을 인식',
              ],
              linesEn: [
                'Tap 예약인증 (confirm booking) in the app while you are in the '
                    'study room — it uses Bluetooth beacons, so keep Bluetooth '
                    'on.',
                'Or scan your mobile library ID at a seat kiosk inside the '
                    'library.',
              ],
            ),
            GuideNote(
              titleKo: '이용 후 좌석을 반납하세요',
              titleEn: 'Release your seat when you are done',
              linesKo: [
                '이용이 끝난 뒤 앱에서 좌석 반납을 완료하세요.',
                '앱의 「나의자리」에서 현재 예약·발권된 좌석과 사용 이력을 확인할 수 있습니다.',
              ],
              linesEn: [
                'Finish by releasing the seat in the app so someone else can '
                    'use it.',
                'Under 나의자리 (my seat) you can see your current booking and '
                    'your past usage.',
              ],
            ),
          ],
          noticeKo: '예약만 하면 끝이 아니에요\n'
              '좌석 예약 후 20분 이내에 인증하여 발권확정을 해야 이용할 수 있습니다. 정해진 시간 '
              '안에 인증하지 않으면 예약이 취소될 수 있습니다.',
          noticeEn: 'Booking a seat is only half of it\n'
              'You have 20 minutes to check in and confirm the seat. If you do '
              'not, the booking can be cancelled.',
          footnoteKo: '※ 그룹스터디실은 도서관 홈페이지에서 별도로 신청합니다. 신청 조건과 이용 시간은 '
              '도서관 홈페이지의 안내를 확인하세요.',
          footnoteEn: '※ Group study rooms are booked separately on the library '
              'website. Check the site for who can book one and for how long.',
        ),
        GuideSection(
          titleKo: '캠퍼스간 대출',
          titleEn: 'Inter-Campus Loan',
          iconName: 'compare_arrows',
          bodyKo: '필요한 책이 다른 캠퍼스 도서관에 있는 경우 캠퍼스간 대출을 신청하여 원하는 '
              '도서관에서 받을 수 있습니다.\n\n'
              '신청하려는 자료가 내가 있는 캠퍼스의 도서관에 없을 때 이용할 수 있습니다.',
          bodyEn: 'If the book you need is held on another campus, request an '
              'inter-campus loan and collect it at the library you choose.\n\n'
              'It applies when the item is not held by the library on your own '
              'campus.',
          stepsKo: [
            '도서관 홈페이지 로그인',
            '자료 검색',
            '도서 상세정보 확인',
            '캠퍼스간 대출 신청',
            '수령할 도서관 선택',
            '도착 안내 확인 후 수령',
          ],
          stepsEn: [
            'Log in to the library website',
            'Search for the book',
            'Open its detail page',
            'Request an inter-campus loan',
            'Choose where you want to collect it',
            'Wait for the arrival notice, then pick it up',
          ],
          notes: [
            GuideNote(
              titleKo: '수령할 수 있는 도서관',
              titleEn: 'Where you can collect it',
              linesKo: [
                '한림도서관 (승학캠퍼스)',
                '부민도서관 (부민캠퍼스)',
                '법학도서분관 (부민캠퍼스)',
                '의학도서분관 (구덕캠퍼스)',
              ],
              linesEn: [
                'Hallim Library (Seunghak campus)',
                'Bumin Library (Bumin campus)',
                'Law Library Branch (Bumin campus)',
                'Medical Library Branch (Gudeok campus)',
              ],
            ),
            GuideNote(
              // Not "Good to know" — that is the l10n heading of the tips
              // section further down, and the two must stay distinguishable.
              titleKo: '알아둘 점',
              titleEn: 'Things to know',
              linesKo: [
                '대출기간은 일반 대출과 동일합니다.',
                '반납은 우리 대학의 모든 도서관에서 할 수 있습니다(취업지원실 제외).',
                '자료 도착 후 보관 기간은 3일입니다.',
                '금요일 오후 2시 이후 신청분은 다음 주 월요일에 처리됩니다.',
              ],
              linesEn: [
                'The loan period is the same as an ordinary loan.',
                'You can return it at any library of the university (except the '
                    'Career Support Office).',
                'Once it arrives it is held for 3 days.',
                'Requests made after 2 p.m. on Friday are processed the '
                    'following Monday.',
              ],
            ),
          ],
          noticeKo: '신청한 책은 꼭 찾아가세요\n'
              '신청한 자료를 3회 이상 대출하지 않으면 해당 학기 동안 캠퍼스간 대출 서비스를 '
              '이용할 수 없습니다.',
          noticeEn: 'Do collect what you request\n'
              'If you fail to pick up requested items three times, you lose '
              'access to the inter-campus loan service for the rest of the '
              'semester.',
        ),
        GuideSection(
          titleKo: '전자자료 · 논문 이용',
          titleEn: 'E-resources & Papers',
          iconName: 'computer',
          bodyKo: '동아대학교 도서관 홈페이지에 로그인하면 전자저널, 학술DB 등 다양한 전자자료를 '
              '이용할 수 있습니다.\n\n'
              '교외에서는 도서관의 교외접속 서비스를 이용해야 할 수 있습니다.',
          bodyEn: 'Log in to the library website and you can read e-journals, '
              'academic databases and other electronic resources.\n\n'
              'From off campus you may need the library\'s off-campus access '
              'service to reach them.',
          notes: [
            GuideNote(
              titleKo: '교외접속 이용 방법',
              titleEn: 'How off-campus access works',
              linesKo: [
                '별도의 프로그램 설치 없이 도서관 홈페이지에 로그인하면 이용할 수 있습니다.',
                'Edge, Chrome, Safari, Firefox 등 대부분의 브라우저를 지원합니다.',
                '전자자료에 바로 접속할 때는 도서관 홈페이지 메인의 「교외접속」을 On으로 '
                    '설정하세요.',
              ],
              linesEn: [
                'Nothing to install — just log in to the library website.',
                'Most browsers work: Edge, Chrome, Safari and Firefox.',
                'When you go straight to a resource, switch 교외접속 (off-campus '
                    'access) to On on the library home page first.',
              ],
            ),
          ],
          noticeKo: '학교 밖에서도 논문을 볼 수 있어요\n'
              '교외접속 서비스를 이용하면 학교 밖에서도 교내와 동일하게 전자저널과 학술DB를 '
              '이용할 수 있습니다.',
          noticeEn: 'You can read papers from outside the campus too\n'
              'With off-campus access, e-journals and databases work from home '
              'exactly as they do on campus.',
          noticeIconName: 'computer',
        ),
        // Hours change every term. The page leads with "check before you go"
        // and the concrete table is explicitly dated, never presented as fixed.
        GuideSection(
          titleKo: '운영시간',
          titleEn: 'Opening Hours',
          iconName: 'info',
          bodyKo: '도서관 운영시간은 학기, 방학, 시험기간에 따라 달라집니다.\n\n'
              '방문 전에 동아대학교 도서관 홈페이지에서 오늘의 운영시간을 확인하세요. 홈페이지 '
              '메인에 실시간 이용시간이 표시됩니다.',
          bodyEn: 'Opening hours change between term time, the vacation and the '
              'exam period.\n\n'
              "Check today's hours on the library website before you go — the "
              'home page shows the live opening hours.',
          notes: [
            GuideNote(
              titleKo: '2026년 8월 확인 기준',
              titleEn: 'As listed in August 2026',
              linesKo: [
                '자료실(한림 · 부민 · 법학도서분관): 학기 중 평일 09:00~20:00, 방학 중 평일 '
                    '09:00~17:00',
                '의학도서분관 자료실: 평일 09:00~17:00',
                '열람실: 매일 07:00~24:00',
                '자료실은 토요일 휴실, 일요일과 공휴일은 휴관',
              ],
              linesEn: [
                'Collections (Hallim, Bumin, Law Branch): 09:00–20:00 on '
                    'weekdays in term time, 09:00–17:00 during the vacation',
                'Medical Library Branch collection: 09:00–17:00 on weekdays',
                'Study rooms: 07:00–24:00, every day',
                'Collections are closed on Saturdays; everything is closed on '
                    'Sundays and public holidays',
              ],
            ),
          ],
          noticeKo: '운영시간은 방문 전에 확인하세요\n'
              '도서관 운영시간은 학기, 방학, 시험기간에 따라 달라질 수 있습니다. 방문 전에 '
              '동아대학교 도서관 홈페이지에서 오늘의 운영시간을 확인하세요.',
          noticeEn: 'Check opening hours before visiting\n'
              'Hours change with the term, the vacation and the exam period. '
              "Look up today's hours on the library website before you set off.",
          noticeIconName: 'info',
          footnoteKo: '※ 2024학년도 외국인 유학생 안내서에는 자료실 09:00~22:00, 열람실 '
              '05:00~24:00으로 안내되어 있었습니다. 현재 도서관 홈페이지의 이용시간과 다르므로 '
              '홈페이지의 실시간 이용시간을 기준으로 하세요.',
          footnoteEn: '※ The 2024 international-student booklet listed '
              '09:00–22:00 for the collections and 05:00–24:00 for the study '
              'rooms. Those no longer match the library website — go by the '
              'live hours shown there.',
        ),
      ],
      tipsKo: [
        '📱 모바일 이용증 — 도서관 앱의 모바일 이용증을 이용하면 출입, 대출, 좌석배정 등을 '
            '편리하게 이용할 수 있습니다.',
        '📚 다른 캠퍼스의 책도 신청 가능 — 필요한 자료가 다른 캠퍼스에 있다면 캠퍼스간 대출 '
            '서비스를 확인하세요.',
        '🔄 다른 도서관에서도 반납 가능 — 대출한 도서는 한림 · 부민 · 법학 · 의학도서분관 중 '
            '다른 도서관에서도 반납할 수 있습니다.',
        '⏰ 운영시간 확인 — 시험기간과 방학에는 운영시간이 달라질 수 있으므로 방문 전 '
            '확인하세요.',
        '💻 전자자료 — 도서관 홈페이지를 통해 전자저널, 학술DB 등 다양한 전자자료를 이용할 수 '
            '있습니다.',
      ],
      tipsEn: [
        '📱 Mobile library ID — the ID in the library app covers entry, '
            'borrowing and seat booking in one place.',
        '📚 Books from other campuses — if what you need is held elsewhere, use '
            'the inter-campus loan service.',
        '🔄 Return anywhere — a borrowed book can go back to Hallim, Bumin, the '
            'Law Branch or the Medical Branch, whichever is closest.',
        '⏰ Check the hours — they change during exam periods and vacations, so '
            'look them up before you go.',
        '💻 E-resources — e-journals and academic databases are all reachable '
            'through the library website.',
      ],
      links: [
        GuideLink(
          labelKo: '동아대학교 도서관',
          labelEn: 'Dong-A University Library',
          descriptionKo: '자료검색 · 운영시간 · 도서관 서비스',
          descriptionEn: 'Search, opening hours and library services',
          url: 'https://library.donga.ac.kr/',
        ),
        GuideLink(
          labelKo: 'DAU Library English',
          labelEn: 'DAU Library English',
          descriptionKo: '영문 도서관 홈페이지',
          descriptionEn: 'Library information for international students',
          url: 'https://library.donga.ac.kr/en/',
        ),
        GuideLink(
          labelKo: '오늘의 운영시간',
          labelEn: "Today's opening hours",
          descriptionKo: '도서관별 · 실별 이용시간',
          descriptionEn: 'Hours for each library and each room',
          url: 'https://library.donga.ac.kr/about-our-library/library-hours/',
          iconName: 'event_repeat',
        ),
        GuideLink(
          labelKo: '모바일 이용증 안내',
          labelEn: 'Mobile library ID',
          descriptionKo: '도서관 앱 · 모바일 이용증 사용 방법',
          descriptionEn: 'How to set up and use the ID in the app',
          url: 'https://library.donga.ac.kr/libaray-services/mobile-service/'
              'mobile-id-card/',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '열람실 좌석배정 안내',
          labelEn: 'Seat reservation',
          descriptionKo: '좌석 예약 · 인증 · 반납 방법',
          descriptionEn: 'Booking, checking in and releasing a seat',
          url: 'https://library.donga.ac.kr/libaray-services/mobile-service/'
              'mobile-seat-allocation/',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '캠퍼스간 대출 안내',
          labelEn: 'Inter-campus loan',
          descriptionKo: '다른 캠퍼스 도서 신청',
          descriptionEn: 'Request a book held on another campus',
          url: 'https://library.donga.ac.kr/libaray-services/using-materials/'
              'inter-campus-loan/',
          iconName: 'compare_arrows',
        ),
        GuideLink(
          labelKo: '교외접속 서비스',
          labelEn: 'Off-campus access',
          descriptionKo: '학교 밖에서 전자저널 · 학술DB 이용',
          descriptionEn: 'Read e-journals and databases from off campus',
          url: 'https://library.donga.ac.kr/libaray-services/off-campus-access/',
          iconName: 'computer',
        ),
      ],
      // 한림도서관(승학) / 국제관 = 부민도서관(부민) / 법학전문대학원 = 법학도서분관(부민) /
      // 구덕교육동 2,3호관 2F = 의학도서분관(구덕). All four already exist in the
      // building data — no new coordinates were invented for this guide.
      relatedFacilityIds: ['s10', 'b05', 'b02', 'g05'],
      durationKo: '5~10분',
      durationEn: '5–10 minutes',
      difficulty: 1,
      status: GuideStatus.published,
    ),
    // Department name, phone/fax, transport and the live Q&A / 상담신청 boards
    // follow global.donga.ac.kr, checked 2026-08-27. The room code and the team
    // email come from the 2024 booklet and are attributed as such — the office
    // site gives the campus address but not the room.
    const AdminGuideItem(
      id: 'oia-visit',
      categoryId: GuideCategory.school,
      titleKo: '국제교류과 방문 안내',
      titleEn: 'International Affairs Office',
      detailTitleKo: '대외국제처 국제교류과 방문 안내',
      detailTitleEn: 'International Affairs Office Guide',
      summaryKo: '비자 · 체류 · 장학 · 유학생 지원',
      summaryEn: 'Visa, stay, scholarships & student support',
      iconName: 'swap_horiz',
      overviewKo: '동아대학교 대외국제처 국제교류과는 외국인 유학생의 입학, 학사, 체류, 장학, '
          '기숙사, 상담 및 국제교류 프로그램 등을 지원하는 부서입니다.\n\n'
          '비자나 체류 관련 학교 확인이 필요하거나 외국인 유학생 지원 프로그램, 장학, 학교생활 '
          '관련 문의가 있는 경우 국제교류과에 문의할 수 있습니다.\n\n'
          '업무에 따라 담당자와 필요한 서류가 다를 수 있으므로 방문 전에 공식 공지나 담당 부서를 '
          '확인하는 것이 좋습니다.',
      overviewEn: 'The Office of International Affairs (대외국제처 국제교류과) is the '
          'department that supports international students — admissions, '
          'academic matters, stay and visa, scholarships, dormitories, '
          'counseling and exchange programmes.\n\n'
          'Go to them when you need the university to confirm something for a '
          'visa or stay application, or when you have a question about student '
          'support programmes, scholarships or life at Dong-A.\n\n'
          'Different services are handled by different staff members and need '
          'different documents, so check the office notices — or which '
          'department actually handles it — before you go.',
      topSections: [
        // First question a student has is whether this is even the right desk.
        GuideSection(
          titleKo: '어떤 일로 방문할 수 있나요?',
          titleEn: 'What can I ask about?',
          iconName: 'help',
          bodyKo: '문의하려는 내용이 국제교류과 업무인지 먼저 확인하세요. 국제교류과는 외국인 유학생 '
              '유치와 지원, 해외 대학과의 협정 체결, 해외 한국어 센터 운영 등을 담당합니다.',
          bodyEn: 'Check first that what you need is actually handled here. The '
              'office recruits and supports international students, signs '
              'agreements with universities abroad, and runs the Korean '
              'language centres.',
          notes: [
            GuideNote(
              titleKo: '🪪 체류 · 비자',
              titleEn: '🪪 Stay & visa',
              linesKo: [
                '외국인등록 관련 문의',
                '체류기간 연장 관련 문의',
                '체류자격 변경',
                '시간제취업 관련 학교 확인',
                '기타 출입국·체류 관련 학교 지원',
              ],
              linesEn: [
                'Questions about alien registration',
                'Questions about extending your period of stay',
                'Changing your status of stay',
                'University confirmation for part-time work',
                'Other university support for immigration and stay matters',
              ],
            ),
            GuideNote(
              titleKo: '🎓 학사 · 학교생활',
              titleEn: '🎓 Academics & student life',
              linesKo: [
                '외국인 유학생 학사 관련 문의',
                '학교생활 상담',
                '유학생 지원 프로그램',
                '학과 또는 학교생활 관련 지원이 필요한 경우',
              ],
              linesEn: [
                'Academic questions specific to international students',
                'Counseling about student life',
                'Support programmes for international students',
                'When you need help with something at your department or on '
                    'campus',
              ],
            ),
            GuideNote(
              titleKo: '💰 장학 · 생활지원',
              titleEn: '💰 Scholarships & living support',
              linesKo: [
                '외국인 유학생 장학 관련 문의',
                '기숙사 및 생활지원 관련 안내',
                '외국인 학생 지원제도',
              ],
              linesEn: [
                'Questions about scholarships for international students',
                'Dormitories and living support',
                'Support schemes for international students',
              ],
            ),
            GuideNote(
              titleKo: '🌏 국제교류',
              titleEn: '🌏 Exchange programmes',
              linesKo: [
                '교환학생 프로그램',
                '해외파견 프로그램',
                '국제교류 프로그램',
                '한국인·외국인 학생 교류 프로그램',
              ],
              linesEn: [
                'Exchange student programmes',
                'Overseas dispatch programmes',
                'International exchange programmes',
                'Programmes that bring Korean and international students '
                    'together',
              ],
            ),
          ],
          noticeKo: '출입국 민원을 대신 처리하는 곳은 아니에요\n'
              '국제교류과는 학교 단체접수 또는 학교 확인이 필요한 업무를 지원할 수 있습니다. '
              '신청과 심사 자체는 출입국·외국인청에서 진행합니다.',
          noticeEn: 'It is not an immigration office\n'
              'The office can help where a group application through the '
              'university, or a confirmation from the university, is needed. '
              'The application itself is filed with — and decided by — the '
              'immigration office.',
          noticeIconName: 'info',
          footnoteKo: '※ 국제교류과가 모든 학사 업무를 처리하지는 않습니다. 전공 수강신청이나 학과 '
              '세부 사항은 소속 학과사무실에 문의해야 할 수 있습니다.',
          footnoteEn: '※ Not every academic matter goes through this office. '
              'Registering for your major courses and department-specific rules '
              'are usually handled by your own department office.',
        ),
        GuideSection(
          titleKo: '위치',
          titleEn: 'Where the office is',
          iconName: 'location_on',
          bodyKo: '국제교류과 사무실은 부민캠퍼스 종합강의동 1층에 있습니다. 법학전문대학원(B02) 옆, '
              '취업지원실 인근입니다.',
          bodyEn: 'The office is on the 1st floor of the General Lecture '
              'Building on the Bumin campus — next to the Law School building '
              '(B02) and near the Career Support Office.',
          notes: [
            GuideNote(
              titleKo: '부민캠퍼스',
              titleEn: 'Bumin campus',
              linesKo: ['종합강의동 1층 BC-0116-3'],
              linesEn: [
                'General Lecture Building, 1st floor, room BC-0116-3',
              ],
            ),
            GuideNote(
              titleKo: '주소',
              titleEn: 'Address',
              linesKo: [
                '부산광역시 서구 구덕로 225 (부민동 2가)',
                '우편번호 49236',
              ],
              linesEn: [
                '225 Gudeok-ro, Seo-gu, Busan (Bumin-dong 2-ga)',
                'Postal code 49236',
              ],
            ),
            GuideNote(
              titleKo: '지하철',
              titleEn: 'By subway',
              linesKo: [
                '부산지하철 1호선 토성역 2번 출구에서 동아대학교 부민캠퍼스 방향으로 이동하세요.',
                '2번 출구에서 약 3분 거리입니다.',
              ],
              linesEn: [
                'Take Busan Metro Line 1 to Toseong station and leave by Exit 2, '
                    'heading towards the Dong-A University Bumin campus.',
                'It is about a 3-minute walk from Exit 2.',
              ],
            ),
            GuideNote(
              titleKo: '버스',
              titleEn: 'By bus',
              linesKo: [
                '동아대학교 부민캠퍼스 정류소 하차',
                '일반 15, 16, 40, 70, 81, 123, 126, 161, 190 / 좌석 58-1',
              ],
              linesEn: [
                'Get off at the Dong-A University Bumin Campus stop',
                'Regular buses 15, 16, 40, 70, 81, 123, 126, 161, 190; '
                    'express bus 58-1',
              ],
            ),
          ],
          footnoteKo: '※ 호실 번호(BC-0116-3)는 2024학년도 외국인 유학생 안내서 기준입니다. '
              '사무실이 이전될 수 있으므로 방문 전 국제교류과 홈페이지의 「찾아오시는 길」을 '
              '확인하세요.',
          footnoteEn: '※ The room number (BC-0116-3) comes from the 2024 '
              'international-student booklet. Offices do move — check the '
              '"Directions" page on the office website before you go.',
        ),
      ],
      // The checklist card is reused as the "before you visit" list; the four
      // items are checks to make, not documents everyone has to bring.
      checklistTitleKo: '방문 전 확인',
      checklistTitleEn: 'Before You Visit',
      checklistKo: [
        '방문 목적 확인 — 비자, 체류, 장학, 교환학생 등 문의 내용에 따라 담당자가 다를 수 있습니다.',
        '관련 공지 확인 — 외국인등록, 체류기간 연장 등은 학교 단체접수 기간이 별도로 운영될 수 '
            '있으므로 방문 전에 국제교류과 공지를 확인하세요.',
        '필요한 서류 확인 — 업무에 따라 여권, 외국인등록증, 신청서, 재학증명서 등 필요한 서류가 '
            '달라질 수 있습니다.',
        '온라인 문의 먼저 확인 — 간단한 질문은 국제교류과 홈페이지의 Q&A를 먼저 이용할 수 '
            '있습니다.',
      ],
      checklistEn: [
        'Know what you are asking about — visa and stay, scholarships, exchange '
            'programmes and so on are each handled by a different person.',
        'Read the notices first — alien registration and stay extensions are '
            'sometimes filed as a group through the university within a set '
            'period, which the office announces.',
        'Find out which documents you need — depending on the service that may '
            'be your passport, your ARC, an application form or an enrollment '
            'certificate.',
        'Try online first — for a simple question, the Q&A board on the office '
            'website is quicker than a visit.',
      ],
      checklistNoteKo: '※ 위 서류가 모든 방문에 필요한 것은 아닙니다. 방문 전에 해당 업무의 공지 '
          '또는 담당자에게 필요한 서류를 확인하세요.\n'
          '※ 사무실 운영시간은 국제교류과 홈페이지에 별도로 안내되어 있지 않습니다. 방문 전 '
          '국제교류과 홈페이지 또는 전화로 운영시간을 확인하세요.',
      checklistNoteEn: '※ Those documents are not required for every visit. '
          'Check the notice for your particular service, or ask the staff, '
          'before you set off.\n'
          '※ The office website does not publish opening hours. Check the '
          'website or call before visiting.',
      stepsKo: [
        '문의하려는 업무 확인',
        '국제교류과 최신 공지 확인',
        '필요한 서류 확인',
        '국제교류과 방문 또는 온라인 문의',
        '담당자에게 문의',
        '추가 제출 또는 후속 절차 확인',
      ],
      stepsEn: [
        'Work out exactly what you need',
        'Check the latest notices from the office',
        'Find out which documents that service needs',
        'Visit the office, or ask online',
        'Talk to the staff member who handles it',
        'Check what you still have to submit or do next',
      ],
      sections: [
        GuideSection(
          titleKo: '연락처',
          titleEn: 'Contact',
          iconName: 'smartphone',
          bodyKo: '국제교류과는 국제교류팀과 국제지원팀으로 구성되어 있습니다. 업무에 따라 담당자가 '
              '다르므로 대표번호로 먼저 문의하세요.',
          bodyEn: 'The office has two teams — the International Exchange Team '
              'and the International Support Team. Which staff member helps you '
              'depends on what you need, so start with the main numbers.',
          notes: [
            GuideNote(
              titleKo: '국제교류과 대표 연락처',
              titleEn: 'Main contact',
              linesKo: [
                '전화: 051-200-6442~4, 6446~8',
                '팩스: 051-200-6445',
              ],
              linesEn: [
                'Phone: 051-200-6442~4, 6446~8',
                'Fax: 051-200-6445',
              ],
            ),
            GuideNote(
              titleKo: '외국인 유학생 지원 문의',
              titleEn: 'International student support',
              linesKo: [
                '유학생 학사 지원·상담 및 기숙사 관련: 051-200-6447',
              ],
              linesEn: [
                'Academic support, counseling and dormitory matters for '
                    'international students: 051-200-6447',
              ],
            ),
          ],
          noticeKo: '운영시간은 미리 확인하세요\n'
              '국제교류과 홈페이지에 사무실 운영시간이 별도로 안내되어 있지 않습니다. 방문 전 '
              '국제교류과 홈페이지 또는 전화로 운영시간을 확인하세요.',
          noticeEn: 'Check the opening hours in advance\n'
              'The office website does not list its opening hours. Check the '
              'website, or call, before you visit.',
          noticeIconName: 'info',
          footnoteKo: '※ 2024학년도 외국인 유학생 안내서에는 유학생 지원(체류·장학·기숙사) 문의 '
              '이메일이 global@donga.ac.kr로 안내되어 있었습니다. 담당자와 업무분장은 변경될 수 '
              '있으므로 최신 정보는 국제교류과 홈페이지의 「구성원 안내」에서 확인하세요.',
          footnoteEn: '※ The 2024 international-student booklet gave '
              'global@donga.ac.kr as the address for student support (stay, '
              'scholarships, dormitories). Staff and their duties change — for '
              'the current list see "구성원 안내" (staff) on the office website.',
        ),
      ],
      tipsKo: [
        '📌 업무마다 담당자가 달라요 — 비자·체류, 장학, 교환학생 등 문의 내용에 따라 담당자가 '
            '다를 수 있습니다.',
        '📄 필요한 서류를 먼저 확인하세요 — 체류 및 출입국 관련 업무는 정해진 제출서류가 있는 '
            '경우가 많으므로 공식 공지를 먼저 확인하세요.',
        '📅 단체접수 기간이 있을 수 있어요 — 외국인등록이나 체류기간 연장 등 일부 업무는 학교에서 '
            '단체접수를 지원할 수 있습니다. 개인 신청 전에 해당 학기의 국제교류과 공지를 '
            '확인하세요.',
        '💬 간단한 질문은 온라인으로 — 국제교류과 홈페이지의 Q&A 게시판에서 방문 전에 온라인으로 '
            '문의할 수 있습니다.',
        '🏫 학과 업무는 학과사무실에서 — 전공 수업, 학과별 졸업요건, 과목 증원 등 학과 고유 '
            '업무는 소속 학과사무실에 문의해야 할 수 있습니다.',
      ],
      tipsEn: [
        '📌 Different services have different staff members — visa and stay, '
            'scholarships and exchange programmes are each someone else\'s desk.',
        '📄 Check the documents first — immigration and stay services usually '
            'have a fixed list of what to submit, published in the notice.',
        '📅 There may be a group application period — the university sometimes '
            'files alien registrations or stay extensions as a group. Check the '
            "semester's notices before you apply on your own.",
        '💬 Ask online for small things — the Q&A board on the office website '
            'saves you the trip.',
        '🏫 Contact your department office for department-specific matters — '
            'major courses, graduation requirements and adding a full class are '
            'your department\'s business, not this office\'s.',
      ],
      links: [
        GuideLink(
          labelKo: '동아대학교 대외국제처 국제교류과',
          labelEn: 'Dong-A University Office of International Affairs',
          descriptionKo: '공지 · 유학생 지원 · 국제교류 프로그램',
          descriptionEn: 'Notices, student support and exchange programmes',
          url: 'https://global.donga.ac.kr/',
        ),
        GuideLink(
          labelKo: '국제교류과 찾아오시는 길',
          labelEn: 'Directions to the office',
          descriptionKo: '위치 · 교통편 · 연락처',
          descriptionEn: 'Location, transport and contact details',
          url: 'https://global.donga.ac.kr/global/CMS/Contents/Contents.do'
              '?mCode=MN025',
          iconName: 'directions_transit',
        ),
        GuideLink(
          labelKo: '외국인 유학생 공지',
          labelEn: 'Notices for international students',
          descriptionKo: '비자 · 체류 · 장학 · 학교생활 안내',
          descriptionEn: 'Visa, stay, scholarships and campus life',
          url: 'https://global.donga.ac.kr/global/CMS/Board/Board.do?mCode=MN066',
          iconName: 'info',
        ),
        GuideLink(
          labelKo: '국제교류과 Q&A',
          labelEn: 'Office Q&A board',
          descriptionKo: '방문 전 온라인 문의',
          descriptionEn: 'Ask a question online before visiting',
          url: 'https://global.donga.ac.kr/global/CMS/Board/Board.do?mCode=MN067',
          iconName: 'help',
        ),
        GuideLink(
          labelKo: '국제교류 프로그램 상담신청',
          labelEn: 'Exchange programme counseling',
          descriptionKo: '교환학생 · 어학연수 등 프로그램 상담',
          descriptionEn: 'Counseling for exchange and language programmes',
          url: 'https://global.donga.ac.kr/global/CMS/Board/Board.do?mCode=MN077',
          iconName: 'swap_horiz',
        ),
        // In-app route (UX doc §3): opens the map focused on 종합강의동.
        GuideLink(
          labelKo: '지도에서 국제교류과 위치 보기',
          labelEn: 'View the International Affairs Office on the map',
          descriptionKo: '부민캠퍼스 종합강의동',
          descriptionEn: 'General Lecture Building, Bumin campus',
          url: '/map?focus=b04',
          iconName: 'location_on',
        ),
      ],
      relatedFacilityIds: ['b04'], // 종합강의동(부민) 1F 국제교류과
      durationKo: '10~30분',
      durationEn: '10–30 minutes',
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // ── 긴급·도움 (emergency) ──
    // Read in an emergency, so it is deliberately short and front-loaded: the
    // 112/119 split first, the call row inside each number's own section, and
    // no duration/difficulty meta at all. 1345 is NOT here — it is immigration
    // counselling, not an emergency line (it stays on the visa guides).
    const AdminGuideItem(
      id: 'emergency-contacts',
      categoryId: GuideCategory.emergency,
      titleKo: '긴급 연락처',
      titleEn: 'Emergency Contacts',
      summaryKo: '112 · 119 긴급신고 안내',
      summaryEn: 'Police 112 · Fire & Ambulance 119',
      topSections: [
        GuideSection(
          titleKo: '긴급상황 안내',
          titleEn: 'In an emergency',
          iconName: 'emergency',
          noticeKo: '지금 즉시 위험한 상황인가요?\n'
              '범죄 · 폭행 · 위협 등 경찰의 도움이 필요하면 112\n'
              '화재 · 사고 · 부상 · 응급환자 · 구조가 필요하면 119',
          noticeEn: 'Are you in immediate danger?\n'
              'Crime, assault, threats — anything you need the police for: 112\n'
              'Fire, an accident, an injury, a medical emergency, someone who '
              'needs rescuing: 119',
          noticeIconName: 'emergency',
        ),
        GuideSection(
          titleKo: '112 — 경찰',
          titleEn: '112 — Police',
          iconName: 'local_police',
          bodyKo: '범죄 피해를 입었거나 신변의 위협을 받고 있는 등 즉각적인 경찰 도움이 필요한 '
              '경우 112에 신고하세요.',
          bodyEn: 'Call 112 when you need the police right now — you have been '
              'the victim of a crime, or you are being threatened.',
          links: [
            GuideLink(
              labelKo: '112 전화하기',
              labelEn: 'Call 112',
              url: 'tel:112',
              iconName: 'call',
            ),
          ],
          notes: [
            GuideNote(
              titleKo: '이런 상황에서 전화하세요',
              titleEn: 'Call when',
              linesKo: [
                '폭행 또는 위협을 받고 있을 때',
                '절도 · 강도 등 범죄 피해를 입었을 때',
                '스토킹 등 즉각적인 경찰 도움이 필요할 때',
                '위험한 범죄 상황을 목격했을 때',
              ],
              linesEn: [
                'You are being assaulted or threatened',
                'You have been robbed, or something was stolen from you',
                'You are being stalked, or otherwise need the police now',
                'You witness a dangerous crime',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '119 — 화재 · 구조 · 구급',
          titleEn: '119 — Fire · Rescue · Ambulance',
          iconName: 'local_fire_department',
          bodyKo: '화재, 사고, 구조 또는 응급환자가 발생한 경우 119에 신고하세요.',
          bodyEn: 'Call 119 for a fire, an accident, a rescue, or a medical '
              'emergency.',
          links: [
            GuideLink(
              labelKo: '119 전화하기',
              labelEn: 'Call 119',
              url: 'tel:119',
              iconName: 'call',
            ),
          ],
          notes: [
            GuideNote(
              titleKo: '이런 상황에서 전화하세요',
              titleEn: 'Call when',
              linesKo: [
                '불이 났을 때',
                '사람이 크게 다쳤을 때',
                '의식이 없거나 호흡에 문제가 있을 때',
                '교통사고 등으로 구조가 필요할 때',
                '즉각적인 응급의료 도움이 필요한 경우',
              ],
              linesEn: [
                'There is a fire',
                'Someone is badly injured',
                'Someone is unconscious, or having trouble breathing',
                'Someone has to be freed after a traffic accident',
                'Someone needs emergency medical help right now',
              ],
            ),
          ],
        ),
      ],
      sections: [
        GuideSection(
          titleKo: '신고할 때 알려주세요',
          titleEn: 'What to tell the operator',
          iconName: 'format_list_numbered',
          stepsKo: [
            '어떤 일이 발생했는지',
            '현재 위치',
            '다친 사람이 있는지',
            '현재 상황이 계속 위험한지',
            '신고자의 연락 가능한 전화번호',
          ],
          stepsEn: [
            'What has happened',
            'Where you are',
            'Whether anyone is hurt',
            'Whether the situation is still dangerous',
            'A phone number they can reach you on',
          ],
          noticeKo: '위치를 먼저 알려주세요\n'
              '정확한 주소를 모르더라도 학교 이름, 캠퍼스, 건물 이름 또는 주변의 큰 건물을 '
              '알려주세요.\n'
              '· 동아대학교 승학캠퍼스\n'
              '· 동아대학교 부민캠퍼스\n'
              '· 동아대학교 구덕캠퍼스',
          noticeEn: 'Tell them your location first\n'
              'You do not need the exact address — the name of the university, '
              'the campus, the building, or a large landmark nearby is enough.\n'
              '· Dong-A University, Seunghak Campus\n'
              '· Dong-A University, Bumin Campus\n'
              '· Dong-A University, Gudeok Campus',
          noticeIconName: 'location_on',
        ),
        // Both languages always show: the title carries one, the line the
        // other, so the caller can read the Korean out loud either way.
        GuideSection(
          titleKo: '긴급상황 표현',
          titleEn: 'Emergency phrases',
          iconName: 'translate',
          bodyKo: '한국어로 말하기 어렵다면 아래 문장을 그대로 읽어도 됩니다.',
          bodyEn: 'If speaking Korean is hard, just read the Korean line out '
              'loud.',
          notes: [
            GuideNote(
              titleKo: '경찰이 필요합니다',
              titleEn: 'I need the police.',
              linesKo: ['I need the police.'],
              linesEn: ['경찰이 필요합니다'],
            ),
            GuideNote(
              titleKo: '구급차를 보내주세요',
              titleEn: 'Please send an ambulance.',
              linesKo: ['Please send an ambulance.'],
              linesEn: ['구급차를 보내주세요'],
            ),
            GuideNote(
              titleKo: '불이 났습니다',
              titleEn: 'There is a fire.',
              linesKo: ['There is a fire.'],
              linesEn: ['불이 났습니다'],
            ),
            GuideNote(
              titleKo: '사람이 다쳤습니다',
              titleEn: 'Someone is injured.',
              linesKo: ['Someone is injured.'],
              linesEn: ['사람이 다쳤습니다'],
            ),
            GuideNote(
              titleKo: '저는 동아대학교에 있습니다',
              titleEn: 'I am at Dong-A University.',
              linesKo: ['I am at Dong-A University.'],
              linesEn: ['저는 동아대학교에 있습니다'],
            ),
            GuideNote(
              titleKo: '한국어를 잘 못합니다',
              titleEn: "I don't speak Korean well.",
              linesKo: ["I don't speak Korean well."],
              linesEn: ['한국어를 잘 못합니다'],
            ),
          ],
        ),
      ],
      tipsKo: [
        '🚨 112와 119는 긴급신고 번호입니다 — 긴급한 상황에서만 이용하세요.',
        '📍 위치를 확인하세요 — 신고하기 전에 가능하면 현재 캠퍼스와 건물 이름을 확인하세요.',
        '📱 휴대전화로 바로 신고할 수 있습니다 — 지역번호 없이 112 또는 119를 입력하세요.',
        '🗣 한국어가 어렵다면 — 한국어를 잘 하지 못한다고 먼저 알리고 천천히 현재 상황과 위치를 '
            '설명하세요.',
      ],
      tipsEn: [
        '🚨 112 and 119 are emergency lines — use them only for emergencies.',
        '📍 Know where you are — check the campus and building name before you '
            'call if you can.',
        '📱 Dial straight from your phone — just 112 or 119, no area code.',
        '🗣 If Korean is hard — say so first, then describe what is happening '
            'and where you are, slowly.',
      ],
      links: [
        GuideLink(
          labelKo: '경찰청 112신고 안내',
          labelEn: 'Korean National Police — 112',
          descriptionKo: '범죄 · 긴급 경찰 신고',
          descriptionEn: 'Crime and emergency police reports',
          url: 'https://www.112.go.kr/',
          iconName: 'local_police',
        ),
        GuideLink(
          labelKo: '소방청 119신고 안내',
          labelEn: 'National Fire Agency — 119',
          descriptionKo: '화재 · 구조 · 구급 신고',
          descriptionEn: 'Fire, rescue and ambulance reports',
          url: 'https://www.nfa.go.kr/nfa/safetyinfo/emergencyservice/'
              '119emergencydeclaration/',
          iconName: 'local_fire_department',
        ),
      ],
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'incident-response',
      categoryId: GuideCategory.emergency,
      titleKo: '사건·사고 대응',
      titleEn: 'Incident Response',
      summaryKo: '분실·도난·사고 시 대응',
      summaryEn: 'Loss, theft, accidents',
    ),
    const AdminGuideItem(
      id: 'counseling',
      categoryId: GuideCategory.emergency,
      titleKo: '상담 창구',
      titleEn: 'Counseling',
      summaryKo: '심리·생활 상담 안내',
      summaryEn: 'Wellbeing & life support',
    ),
  ];
}
