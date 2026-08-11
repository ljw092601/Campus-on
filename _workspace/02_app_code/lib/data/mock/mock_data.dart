import '../../domain/entities/facility.dart';
import '../../domain/entities/admin_guide.dart';

/// Seed data for week-2 development. The api-integrator replaces the repository
/// implementations (not this file) with Firestore; this stays as fixtures for
/// tests / offline demo.
class MockData {
  const MockData._();

  static final List<Facility> facilities = [
    const Facility(
      id: 'lib-central',
      nameKo: '중앙도서관',
      nameEn: 'Central Library',
      category: FacilityCategory.library,
      lat: 35.1152,
      lng: 128.9688,
      addressKo: '캠퍼스 A동 옆',
      addressEn: 'Next to Building A',
      buildingKo: '도서관동',
      buildingEn: 'Library Hall',
      hoursKo: '09:00–22:00 (평일)',
      hoursEn: '09:00–22:00 (weekdays)',
      phone: '02-000-0001',
      descriptionKo: '열람실, 그룹스터디룸, 노트북 대여를 제공합니다.',
      descriptionEn: 'Reading rooms, group study rooms, laptop rentals.',
    ),
    const Facility(
      id: 'dining-union',
      nameKo: '학생회관 식당',
      nameEn: 'Student Union Cafeteria',
      category: FacilityCategory.dining,
      lat: 35.1144,
      lng: 128.9676,
      buildingKo: '학생회관 1F',
      buildingEn: 'Student Union 1F',
      hoursKo: '11:00–19:00',
      hoursEn: '11:00–19:00',
      phone: '02-000-0002',
    ),
    const Facility(
      id: 'bld-eng-3',
      nameKo: '공학관 3호관',
      nameEn: 'Engineering Building 3',
      category: FacilityCategory.building,
      lat: 35.1157,
      lng: 128.9671,
      buildingKo: 'E동',
      buildingEn: 'Building E',
    ),
    const Facility(
      id: 'cafe-on',
      nameKo: '카페 온',
      nameEn: 'Cafe On',
      category: FacilityCategory.amenity,
      lat: 35.1150,
      lng: 128.9693,
      hoursKo: '08:00–20:00',
      hoursEn: '08:00–20:00',
    ),
    const Facility(
      id: 'oia-office',
      nameKo: '국제교류처',
      nameEn: 'Office of International Affairs',
      category: FacilityCategory.building,
      lat: 35.1142,
      lng: 128.9690,
      buildingKo: 'A동 2F',
      buildingEn: 'Building A 2F',
      hoursKo: '09:00–17:00 (평일)',
      hoursEn: '09:00–17:00 (weekdays)',
      phone: '02-000-0003',
    ),
    const Facility(
      id: 'room-101',
      nameKo: '제1강의동 101호',
      nameEn: 'Lecture Hall 1 Room 101',
      category: FacilityCategory.classroom,
      lat: 35.1155,
      lng: 128.9681,
    ),
  ];

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
      relatedFacilityIds: ['oia-office'],
      durationKo: '예상 2–3주',
      durationEn: 'Approx. 2–3 weeks',
      difficulty: 2,
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'stay-extension',
      categoryId: GuideCategory.immigration,
      titleKo: '체류기간 연장',
      titleEn: 'Extend Period of Stay',
      summaryKo: '만료 4개월 전부터 신청 가능',
      summaryEn: 'Apply from 4 months before expiry',
    ),
    const AdminGuideItem(
      id: 'visa-types',
      categoryId: GuideCategory.immigration,
      titleKo: '비자 종류 안내',
      titleEn: 'Visa Types',
      summaryKo: 'D-2 / D-4 차이',
      summaryEn: 'D-2 vs. D-4',
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
      summaryKo: '선불·후불 요금제 비교',
      summaryEn: 'Prepaid vs. postpaid',
    ),
    const AdminGuideItem(
      id: 'transit-card',
      categoryId: GuideCategory.living,
      titleKo: '교통카드',
      titleEn: 'Transit Card',
      summaryKo: '충전·환승 이용법',
      summaryEn: 'Top-up & transfers',
    ),

    // ── 건강·보험 (health) ──
    const AdminGuideItem(
      id: 'health-insurance',
      categoryId: GuideCategory.health,
      titleKo: '건강보험 가입',
      titleEn: 'National Health Insurance',
      summaryKo: '유학생 의무가입 안내',
      summaryEn: 'Mandatory for students',
    ),
    const AdminGuideItem(
      id: 'campus-clinic',
      categoryId: GuideCategory.health,
      titleKo: '교내 보건소',
      titleEn: 'Campus Health Center',
      summaryKo: '이용 시간·기본 진료',
      summaryEn: 'Hours & basic care',
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
      summaryKo: '수강신청 기간·정정',
      summaryEn: 'Periods & add/drop',
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
      relatedFacilityIds: ['lib-central'],
    ),
    const AdminGuideItem(
      id: 'oia-visit',
      categoryId: GuideCategory.school,
      titleKo: '국제교류처 방문 안내',
      titleEn: 'Visiting the OIA',
      summaryKo: '위치·상담 시간',
      summaryEn: 'Location & hours',
      relatedFacilityIds: ['oia-office'],
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
