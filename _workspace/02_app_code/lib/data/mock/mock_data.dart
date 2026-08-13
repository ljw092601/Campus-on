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
