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
      summaryKo: '재학·성적증명 발급',
      summaryEn: 'Enrollment & transcripts',
    ),
    const AdminGuideItem(
      id: 'library-guide',
      categoryId: GuideCategory.school,
      titleKo: '도서관 이용 안내',
      titleEn: 'Library Guide',
      summaryKo: '대출·열람실 이용',
      summaryEn: 'Borrowing & reading rooms',
      relatedFacilityIds: ['s10'], // 한림도서관(승학)
    ),
    const AdminGuideItem(
      id: 'oia-visit',
      categoryId: GuideCategory.school,
      titleKo: '국제교류처 방문 안내',
      titleEn: 'Visiting the OIA',
      summaryKo: '위치·상담 시간',
      summaryEn: 'Location & hours',
      relatedFacilityIds: ['b04'], // 종합강의동(부민) 1F 국제교류과
    ),

    // ── 긴급·도움 (emergency) ──
    const AdminGuideItem(
      id: 'emergency-contacts',
      categoryId: GuideCategory.emergency,
      titleKo: '긴급 연락처',
      titleEn: 'Emergency Contacts',
      summaryKo: '112·119·1345 안내',
      summaryEn: '112 · 119 · 1345',
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
