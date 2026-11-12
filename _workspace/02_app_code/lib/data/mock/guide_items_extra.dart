import '../../domain/entities/admin_guide.dart';

/// Guides added in r21 beyond the two approved school guides (2026-10-30):
/// topics the 35 existing guides do not touch at all. The first is receiving
/// parcels and online orders from abroad — the personal customs clearance code
/// and the customs thresholds — which no existing guide mentions (조사
/// 30_생활_주거_건강 후보 1, 감사 05/067 ②-4: `통관·관세·세관·직구·소포·EMS` 0건).
///
/// Kept apart from the others so the addition reviews as its own diff;
/// [MockData.guideItems] is expected to append this list (registration is the
/// lead's), so search, categories, the seed export and the screens treat them
/// like the rest.
///
/// Every official source below was read on 2026-10-30 (W1 작성보고 근거표).
/// Thresholds and the code's validity rules change by notice, so each number
/// carries its source and date in a footnote. Rules that the Korea Customs
/// Service announced but no current official page states as in force are
/// written as «the press release says …», with where to check, never as fact.
/// Seller problems (refunds, non-delivery) belong to `consumer-disputes`; this
/// guide only links it. (r22 L1: the link to `mobile-plan` was dropped — the
/// portal's identity checks are simple authentication and joint or financial
/// certificates, with no carrier phone verification among them.)
abstract final class ExtraGuides {
  static const List<AdminGuideItem> items = [
    // ── 해외 소포·직구 받기 ────────────────────────────────────────────
    // 관세청 원문, 2026-10-30 열람(KST):
    //  · 특송물품 통관 https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?mi=2821&cntntsId=819
    //    — 목록통관 「미화 150불 이하(미국은 200불)」, 배제대상물품 표, 간이수입신고
    //    「150불(미국은 200불)을 초과하고 미화 2,000불 이하」, 일반수입신고 「2,000불을 초과」,
    //    「수하인의 정확한 개인통관고유부호가 제출되어야」, 「150불을 초과하는 경우 총과세가격
    //    전체에 대하여 과세」, 물품가격 정의. (17:17)
    //  · 우편물 통관 https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?mi=2822&cntntsId=820
    //    — 「해외 친지 등이 … 기증하는 물품 등 … 미화 150불 이하의 물품은 관세를 면세」,
    //    현장면세 우편물은 배달우체국으로, 과세대상은 세금을 내야 통관, 일반수입신고 대상
    //    「물품가격 미화 1,000불 초과」(관세사를 통하여). (17:20)
    //  · 해외직구(전자상거래) 통관절차 https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?mi=2835&cntntsId=827
    //    — 특송업체 반입은 특송통관, 우체국 반입은 우편통관, 「특송화물 또는 우편(EMS)」. (17:20)
    //  · 고객지원센터 FAQ(외국인 발급) https://www.customs.go.kr/call/ad/crmcc/selectFaqViewPage.do?mi=6822&cnslKnwlSrno=518
    //    — 「신분증(기간 만료 6개월 전의 여권, 외국인등록증 등) 사본을 가지고 세관에 방문하거나,
    //    … 인터넷 개인통관고유부호 발급시스템을 통하여 본인 인증절차 후」. (17:17)
    //  · 고객지원센터 https://www.customs.go.kr/call/main.do — 「전화 상담 (☎ 125)」, 「해외에서는
    //    82-2-3438-5199」, 「평일 09:00 ~ 18:00 주말/공휴일 휴무」. (17:20)
    //  · 전자상거래 통관포털 https://ecos.customs.go.kr/ (unipass.customs.go.kr 개인통관 메뉴가 이리로
    //    넘어간다) — 메뉴 「신규발급·조회/정보변경·수입통관내역 조회·도용신고·유효기간 갱신」,
    //    「방문발급 사전신청」, 공지 「'전자상거래 통관포털' 개설 안내(8월28일)」(2026-08-27):
    //    일회용 인증번호 시행 2026-08-28, 적용대상 「적용일자 이후 … 신규 발급자 또는 정보변경자」,
    //    「갱신(27년 발급자 생일 전후 30일)」. (17:17~17:18)
    //  · 보도자료 2025-06-18 「개인통관고유부호, 2026년부터는 매년 갱신해 주세요」(nttSn=10142854)
    //    — 「2026 년 이후 신규 발급자는 발급일을 기준으로 유효기간 1 년」, 「2026 년 이전 발급자는
    //    2027 년 본인 생일이 만료일」, 「만료일 전후 30 일 동안 갱신하지 않으면 … 자동 해지」,
    //    「2026 년부터 본격 도입」. (17:17) r22: 같은 내용을 아래 포털 FAQ 044 가 현행형으로
    //    적으므로 본문 근거에서는 뺐다(이력으로 남김).
    //  · 보도자료 2026-01-14 「관세청, 개인통관고유부호 검증 강화」(nttSn=10153725) — 2월 2일부터
    //    성명·전화번호·배송지 우편번호 대조, 「2025 년 11 월 21 일 이후 … 신규로 발급받거나 기존
    //    정보를 변경」한 사용자 우선 적용, 배송지 최대 20건, 「2026 년부터 … 유효기간 (1 년) 이
    //    도입됨에 따라」. (17:20)
    //  · 보도자료 2025-12-03 「개인통관고유부호 전용 발급시스템 긴급 구성·운영」(nttSn=10153023) —
    //    도용 확인 시 「도용당한 사람에게는 아무런 불이익이 발생하지 않는다」, 국민비서 알림. (17:20)
    //  · 보도자료 2026-10-26 「관세청, 해외직구 전용 통관 플랫폼 정식 개통」(nttSn=10181004) —
    //    포털 8월 28일 시범운영 → 정식 개통, 일회용 인증번호 제도. (17:19)
    //  · (r22, 2026-10-30 23:08~23:16 열람) 전자상거래 통관포털 자주 묻는 질문(68건, 모두
    //    2026-08-27 등록): 044 「26. 1. 1.부터 개인통관고유부호 유효기간(1년)이 도입」, 신규·
    //    정보변경·부호변경일부터 1년, 「만료일 전/후 30일 이내 갱신」, 「만료 30일 후 … 자동으로
    //    해지」, 「2025.12.31. 이전 발급자」 만료일 2027년 생일 / 048 외국인: 외국인등록번호
    //    실명인증, 「모바일신분증, 간편인증, 공동·금융인증서」, 외국인등록증이 없으면 「기간만료
    //    6개월 전의 여권」으로 세관 방문 / 046 우편번호가 등록 주소 20개에 들어야 통관 /
    //    003·028·066 협력인정업체. 자료실 「개인통관고유부호 메뉴 안내서」(’26.08.): 본인인증
    //    「간편인증/공동인증서/금융인증서」, 갱신 시 만료일부터 1년 연장·부호 불변, 재발급과
    //    해지 뒤 신규 발급은 합쳐 연 5회. 신규 발급 실명확인 팝업(로그인 전 공개 화면): 「외국인의
    //    경우 외국인등록번호를 입력해주세요」.
    // 법제처 생활법령 「의약품·건강기능식품 구매」(csmSeq=1504 cciNo=2 cnpClsNo=3) — 금지성분 제품은
    // 통관 금지, 합산 150달러 이하·자가사용 인정 시 면세, 기준은 고시 별표 11. (17:21) 생활법령의
    // 통관 절차 페이지는 관세청 페이지를 출처로 옮긴 것이라 근거로 따로 세지 않는다(감사 05/067 ④).
    // 보도자료와 포털 자료는 모두 관세청 한 기관의 문서라 근거 하나로 센다.
    AdminGuideItem(
      id: 'overseas-parcels-and-customs',
      categoryId: GuideCategory.living,
      searchAliasesKo: ['통관', '관세', '개인통관고유부호', '통관부호', '직구', '해외직구', '소포',
        '국제소포', '택배 통관', 'EMS', '세관', '면세 한도', '우편물 통관', '일회용 인증번호',
        '부호 갱신'],
      searchAliasesEn: ['customs clearance', 'customs duty', 'personal customs code',
        'customs code', 'direct purchase', 'overseas shopping', 'parcel',
        'international parcel', 'courier customs', 'EMS', 'customs office',
        'duty-free limit', 'postal customs', 'one-time verification code',
        'customs code renewal'],
      titleKo: '해외 소포·직구 받기',
      titleEn: 'Receiving Parcels from Abroad',
      detailTitleKo: '해외 소포·직구 받기 — 개인통관고유부호와 통관·면세 기준',
      detailTitleEn: 'Parcels and Online Orders from Abroad — Customs Code, '
          'Clearance and Duty-free Limits',
      summaryKo: '개인통관고유부호 먼저 · 면세 150달러',
      summaryEn: 'Customs code first · \$150 duty-free',
      iconName: 'receipt_long',
      overviewKo: '본국 가족이 보낸 소포나 해외 쇼핑몰에서 직접 산 물건(해외직구)은 한국에 들어올 '
          '때 세관 통관을 거칩니다. 특송업체로 오는 개인 물품은 받는 사람의 개인통관고유부호를 '
          '함께 내야 하므로, 주문하기 전에 부호부터 받아 두는 것이 좋습니다. 외국인도 받을 수 '
          '있습니다.\n\n'
          '통관 방법과 세금은 물건값, 보내는 방법(특송·우편), 물건의 종류에 따라 달라집니다. '
          '의약품·식품처럼 따로 확인이 필요한 물건도 있습니다.\n\n'
          '이 가이드는 부호 발급 → 주문할 때 입력 → 통관 기준 확인 → 세관 연락 대응 → 부호 '
          '갱신의 순서로 정리합니다. 금액과 부호 규칙은 바뀔 수 있어 출처와 기준 시점을 함께 '
          '적었습니다. 판매자와의 환불·미배송 문제는 「소비자 피해·환불 분쟁」 가이드를 보세요.',
      overviewEn: 'A parcel from your family back home, or something you bought '
          'directly from an overseas shop, goes through customs when it '
          'enters Korea. For personal goods sent by courier, the recipient’s '
          'personal customs clearance code has to be submitted, so get the '
          'code before you order. International residents can get one too.\n\n'
          'How the item is cleared and whether you pay tax depends on its '
          'price, how it is sent (courier or post) and what it is. Some '
          'items, such as medicines and food, need a separate check.\n\n'
          'This guide goes in order: get the code → enter it when you order → '
          'check the clearance rules → respond if customs contacts you → '
          'renew the code. Amounts and code rules can change, so each comes '
          'with its source and date. For refunds or orders that never '
          'arrived, see the «Refunds and consumer disputes» guide.',
      checklistKo: [
        '외국인등록증 (아직 없으면 여권 — 관세청 안내 표기: 「기간만료 6개월 전의 여권」)',
        '한국 휴대폰 번호',
        '이메일 주소 (일회용 인증번호를 받는 곳)',
        '물건을 받을 주소와 우편번호',
        '여권에 적힌 영문 이름',
        // r22 감사 073 R-4: 로그인 화면의 간편인증 예시(네이버·카카오 등)가 외국인에게도
        // 열리는지는 확인하지 못했다 — 사업자 이름은 적지 않는다.
        '온라인으로 발급하려면 인증 수단 하나: 간편인증 · 공동인증서 · 금융인증서',
      ],
      checklistEn: [
        'Residence card (or your passport if you do not have one yet — the '
            'customs FAQ says «passport valid beyond 6 months before expiry»)',
        'Your Korean mobile number',
        'An email address (one-time verification codes are sent there)',
        'The delivery address and its postcode',
        'Your name in English as on your passport',
        'To issue online, one way to verify yourself: simple authentication, '
            'a joint certificate or a financial certificate',
      ],
      checklistNoteKo: '온라인 발급은 외국인등록증의 이름과 외국인등록번호로 실명확인을 한 뒤 '
          '간편인증·공동인증서·금융인증서 중 하나로 본인인증을 합니다(포털 FAQ는 외국인에게 '
          '모바일 신분증도 적습니다). 외국인등록증이 아직 없거나 본인인증을 할 수 없으면 '
          '온라인으로는 받을 수 없으니, 신분증을 가지고 가까운 세관을 방문하세요.',
      checklistNoteEn: 'To issue online you first confirm your name and alien '
          'registration number from your residence card, then verify yourself '
          'with simple authentication, a joint certificate or a financial '
          'certificate (the portal FAQ also lists a mobile ID for international '
          'residents). If you do not have a residence card yet or cannot verify '
          'yourself online, you cannot get the code online — visit a nearby '
          'customs office with your ID.',
      stepsKo: [
        '개인통관고유부호를 받는다. '
            '관세청 전자상거래 통관포털(PC·모바일 웹)의 「개인통관고유부호 신규 발급」에서 '
            '실명확인과 본인인증을 하고 영문 이름·연락처·이메일(인증 필수)·배송지 주소를 넣으면 '
            '바로 발급됩니다. 외국인등록증이 없거나 온라인 인증이 안 되면 신분증을 가지고 가까운 '
            '세관을 방문해 받습니다. 포털의 「방문발급 사전신청」에서 신청서를 미리 써 두면 세관에서 '
            '작성 시간을 줄일 수 있습니다.',
        '받을 주소를 포털에 등록한다. '
            '2026년 2월 2일부터 통관할 때 성명·전화번호와 함께 배송지 우편번호가 등록 정보와 '
            '맞는지 대조합니다. 주소는 최대 20건까지 등록할 수 있고, 포털 FAQ는 배송지 우편번호가 '
            '등록한 주소에 들어 있어야 통관된다고 안내합니다. 주문 전에 받을 주소가 등록돼 있는지 '
            '확인하고, 기숙사에서 원룸으로 옮기는 것처럼 주소가 바뀌면 포털 정보도 고치세요.',
        '주문할 때 받는 사람 정보와 부호를 입력한다. '
            '쇼핑몰 주문창에 이름·주소·전화번호·개인통관고유부호를 등록 정보와 똑같이 적습니다. '
            '2026년 8월 28일 이후 부호를 새로 받았거나 정보를 바꿨거나 갱신했다면, 「인증하기」를 '
            '누른 뒤 이메일로 온 여섯 자리 일회용 인증번호를 주문창에 넣고 결제합니다. 주문한 뒤에 '
            '특송업체나 관세사가 인증번호를 물어 올 수도 있는데, 관세청은 내가 주문한 물건이면 '
            '알려 줘도 된다고 안내합니다. 가족이 특송업체로 보낼 때도 받는 사람 정보와 부호를 '
            '같은 방식으로 적어 달라고 하세요.',
        '물건값과 종류로 통관 기준을 확인한다. '
            '특송은 미화 150달러(미국에서 오면 200달러) 이하이면 목록통관, 그보다 비싸면 '
            '수입신고를 거칩니다. 150달러를 넘으면 일부가 아니라 전체 금액에 세금이 붙습니다. '
            '의약품·건강기능식품·식품류처럼 목록통관에서 빠지는 물건은 주문 전에 확인하세요. '
            '자세한 기준은 아래 「통관 기준 한눈에」에 있습니다.',
        '통관 진행을 조회하고, 연락이 오면 안내대로 처리한다. '
            '포털의 「수입통관내역 조회」에서 진행 상황을 볼 수 있습니다. 세금을 내야 하는 우편물은 '
            '세금을 내야 받을 수 있습니다. 무엇을 내라는 것인지 모르겠으면 관세청 고객지원센터(125)에 '
            '물어보세요.',
        '부호의 유효기간을 확인하고 갱신한다. '
            '2026년 1월 1일부터 개인통관고유부호에 1년 유효기간이 생겼습니다. 새로 받거나 정보를 '
            '바꾸거나 부호를 바꾼 날부터 1년이고, 만료일 전후 30일 안에 포털 「유효기간 갱신」에서 '
            '갱신하면 만료일부터 1년 늘어납니다. 만료 뒤 30일이 지나면 자동 해지되어 새로 '
            '발급받아야 하니, 「조회/정보변경」에서 내 만료일을 확인해 두세요.',
        '도용이 의심되면 바로 신고한다. '
            '내가 주문하지 않은 물건이 내 부호로 통관됐다면 포털의 「개인통관고유부호 도용신고」를 '
            '이용하세요. 관세청은 수사로 도용이 확인되면 도용당한 사람에게 불이익이 없다고 '
            '안내합니다. 신고가 처리되면 관세청은 기존 부호의 사용정지 · 부호변경(재발급) · '
            '해지 중 하나를 하라고 안내하고, 재발급과 해지 뒤 신규 발급은 합쳐 한 해에 '
            '5번까지입니다.',
      ],
      stepsEn: [
        'Get a personal customs clearance code. '
            'On the Korea Customs Service e-commerce customs portal (PC or '
            'mobile web), go to «New personal customs code», confirm your name '
            'and verify yourself, then enter your English name, contact details, '
            'email (it has to be verified) and delivery address — the code is '
            'issued straight away. If you have no residence card or cannot '
            'verify yourself online, visit a nearby customs office with your ID. '
            'Filling in the form in advance under «visit pre-application» on the '
            'portal saves time at the office.',
        'Register your delivery address on the portal. '
            'From 2 February 2026 customs checks the delivery postcode, as well '
            'as the name and phone number, against your registered details. You '
            'can register up to 20 addresses, and the portal FAQ says an item is '
            'cleared only if its delivery postcode is among them. Check the '
            'address is registered before you order, and if you move — from the '
            'dormitory to a studio, say — update the portal too.',
        'Enter the recipient details and the code when you order. '
            'Type your name, address, phone number and customs code in the '
            'checkout exactly as registered. If you got your code, changed your '
            'details or renewed it on or after 28 August 2026, press «verify», '
            'enter the six-digit one-time code sent to your email, then pay. A '
            'courier or customs broker may also ask for the code after you '
            'order; the Customs Service says you can give it to them if you '
            'placed the order. When family send a parcel by courier, ask them to '
            'write the recipient details and code the same way.',
        'Check the clearance rules for the price and the item. '
            'A courier item of US\$150 or less (US\$200 if it comes from the '
            'United States) is cleared on the manifest; above that it goes '
            'through an import declaration. Above US\$150 tax is charged on the '
            'whole amount, not just the excess. Check items excluded from '
            'manifest clearance — medicines, health supplements, food — before '
            'you order. «Clearance rules at a glance» below has the details.',
        'Track the clearance, and follow any notice you receive. '
            '«Import clearance history» on the portal shows progress. A '
            'taxable postal item is handed over only after the tax is paid. If '
            'you are unsure what you are being asked for, call the Korea '
            'Customs Service call centre (125).',
        'Check when your code expires and renew it. '
            'Since 1 January 2026 personal customs codes are valid for one year '
            '— from the day you got the code, changed your details or changed the '
            'code. Renewing under «renew validity» on the portal within 30 days '
            'either side of the expiry date extends it by one year from that '
            'date. A code is cancelled automatically 30 days after it expires and '
            'you would have to apply again, so check your expiry date under «look '
            'up / change details».',
        'Report misuse straight away. '
            'If something you did not order was cleared under your code, use '
            '«report misuse of a personal customs code» on the portal. The '
            'Customs Service says a person whose code was stolen suffers no '
            'disadvantage once an investigation confirms the misuse. Once the '
            'report is processed, the Customs Service advises suspending the '
            'old code, changing it (reissue) or cancelling it; reissues and new '
            'codes after cancelling are limited to five a year in total.',
      ],
      sections: [
        GuideSection(
          titleKo: '통관 기준 한눈에',
          titleEn: 'Clearance rules at a glance',
          iconName: 'fact_check',
          notes: [
            GuideNote(
              titleKo: '특송업체로 올 때',
              titleEn: 'Sent by courier',
              linesKo: [
                '미화 150달러 이하(미국은 200달러) — 개인이 쓸 물건이고 아래 배제 물품이 아니면 '
                    '목록통관(수입신고 없이 통관)',
                '150달러(미국 200달러) 초과 ~ 2,000달러 — 간이수입신고',
                '2,000달러 초과, 또는 목록통관·간이수입신고에서 빠지는 물건 — 일반수입신고',
                '150달러를 넘으면 총과세가격 전체에 세금이 붙습니다. 면세 범위 안이라도 담배소비세·'
                    '개별소비세 등은 과세됩니다.',
              ],
              linesEn: [
                'US\$150 or less (US\$200 from the United States) — personal-use '
                    'goods not on the excluded list below are cleared on the '
                    'manifest, without an import declaration',
                'Over US\$150 (US\$200) up to US\$2,000 — simplified import '
                    'declaration',
                'Over US\$2,000, or goods excluded from the two routes above — '
                    'regular import declaration',
                'Above US\$150, tax applies to the whole taxable value. Even '
                    'within the exemption, tobacco and individual consumption '
                    'taxes still apply.',
              ],
            ),
            GuideNote(
              titleKo: '우체국 국제우편(EMS 등)으로 올 때',
              titleEn: 'Sent by international post (EMS etc.)',
              linesKo: [
                '해외 가족 등이 보내는 선물 같은 물건은 미화 150달러 이하이면 관세를 면제하고, '
                    '세관이 현장면세한 우편물은 배달우체국을 거쳐 집으로 배달됩니다.',
                '세금이 붙은 우편물은 세금을 내야 받을 수 있습니다.',
                '물품가격 미화 1,000달러 초과 등은 관세사를 통해 수입신고해야 합니다.',
              ],
              linesEn: [
                'Gifts and similar items from family abroad worth US\$150 or less '
                    'are exempt from customs duty; mail cleared duty-free on the '
                    'spot is passed to your local delivery post office and '
                    'brought to your door.',
                'Taxable mail is handed over only after the tax is paid.',
                'Items over US\$1,000, among others, need an import declaration '
                    'through a licensed customs broker.',
              ],
            ),
            GuideNote(
              titleKo: '목록통관에서 빠지는 물건 (일부)',
              titleEn: 'Excluded from manifest clearance (selection)',
              linesKo: [
                '의약품 · 한약재 · 건강기능식품 · 식품류·주류·담배류 · 야생동물 관련 제품 · '
                    '검역 대상 농림축수산물 · 지식재산권 위반 의심물품 · 일부 화장품',
                '의약품·건강기능식품은 금지성분이 들어 있으면 통관되지 않습니다. 합산 가격이 미화 '
                    '150달러 이하이고 자가사용으로 인정되면 면세이며, 인정 기준은 관세청 고시에 '
                    '있습니다.',
              ],
              linesEn: [
                'Medicines · herbal medicine ingredients · health supplements · '
                    'food, alcohol and tobacco · wildlife products · '
                    'agricultural, livestock and fishery goods subject to '
                    'quarantine · suspected counterfeits · some cosmetics',
                'Medicines and health supplements containing banned ingredients '
                    'are refused. If the combined price is US\$150 or less and '
                    'the goods are accepted as for personal use, they are '
                    'duty-free; the criteria are in a Customs Service notice.',
              ],
            ),
          ],
          noticeKo: '물품가격에 무엇이 들어가나요 / 물건값에 더해 보내는 나라 안에서 생긴 세금·'
              '내륙운임·보험료 등이 포함됩니다. 한국까지 오는 국제운송비와 보험료는 명백히 구분될 '
              '때 뺄 수 있습니다.',
          noticeEn: 'What counts as the price / The goods plus taxes, inland '
              'freight and insurance in the sending country. International '
              'shipping and insurance to Korea can be left out when clearly '
              'separated.',
          noticeIconName: 'info',
          footnoteKo: '※ 관세청 「특송물품 통관」·「우편물 통관」 페이지(게시일 표기 없음)와 법제처 '
              '생활법령 「의약품·건강기능식품 구매」 기준, 2026-10-30 확인. 금액 기준은 고시 '
              '개정으로 바뀔 수 있습니다.',
          footnoteEn: '※ Based on the Korea Customs Service pages on courier '
              'and postal clearance (no posting date shown) and the Ministry of '
              'Government Legislation easy-law page on buying medicines and '
              'supplements, checked 2026-10-30. Thresholds can change when the '
              'notices are amended.',
        ),
        GuideSection(
          titleKo: '개인통관고유부호 — 2026년에 바뀐 것',
          titleEn: 'Personal customs code — what changed in 2026',
          iconName: 'badge',
          notes: [
            GuideNote(
              titleKo: '배송지 우편번호 대조',
              titleEn: 'Delivery postcode check',
              linesKo: [
                '2026년 2월 2일부터 성명·전화번호에 더해 배송지 우편번호까지 등록 정보와 맞아야 '
                    '지연 없이 통관됩니다. 관세청은 2025년 11월 21일 이후 부호를 새로 받거나 정보를 '
                    '바꾼 사람부터 먼저 적용하고, 유효기간 도입에 따라 대상을 차츰 넓힌다고 '
                    '알렸습니다.',
              ],
              linesEn: [
                'From 2 February 2026 the delivery postcode, as well as the name '
                    'and phone number, has to match your registered details for '
                    'clearance without delay. The Customs Service applied this '
                    'first to anyone who got a code or changed their details on or '
                    'after 21 November 2025, and said coverage would widen as codes '
                    'come under the new validity rule.',
              ],
            ),
            GuideNote(
              titleKo: '일회용 인증번호',
              titleEn: 'One-time verification code',
              linesKo: [
                // r21 감사 069 R-1 → r22 R3 D9: 협력인정업체 예외는 포털 FAQ 003·066
                // (2026-08-27 등록)으로 확인되어 확정형으로 적는다.
                '2026년 8월 28일 이후 부호를 새로 받거나 정보를 바꾸거나 갱신한 사람은 주문할 때 '
                    '이메일로 받은 일회용 인증번호를 입력합니다. 쇼핑몰에 따라 문자 등으로 받을 수도 '
                    '있습니다. 그 전에 받은 부호를 아직 바꾸거나 갱신하지 않았다면 예전처럼 부호만 '
                    '입력하고, 인증번호는 쇼핑몰로 바로 갑니다. 관세청 「협력인정업체」에서는 '
                    '본인인증을 한 회원이 자기 앞으로 주문할 때 부호와 인증번호 없이 주문할 수 '
                    '있습니다. 협력인정업체인지는 포털의 「관세청 등록업체 조회」에서 확인합니다.',
              ],
              linesEn: [
                'If you got a code, changed your details or renewed it on or '
                    'after 28 August 2026, you enter a one-time code sent to your '
                    'email when you order. Some shops send it by text message or '
                    'other channels instead. If your code is older and you have not '
                    'changed or renewed it, you enter the code as before and the '
                    'one-time code goes straight to the shop. At shops Korea Customs '
                    'recognises as partners, a verified member ordering for '
                    'themselves can order without the code or a one-time code; '
                    'check which shops are partners under the portal’s list of '
                    'registered e-commerce businesses.',
              ],
            ),
            GuideNote(
              titleKo: '유효기간과 갱신',
              titleEn: 'Validity and renewal',
              linesKo: [
                // r22 R3 D10: 신규 1년 · 전후 30일 갱신 · 자동 해지는 포털 FAQ 044·052
                // (2026-08-27 등록)와 메뉴 안내서(’26.08.)로 현행 확인. [2]의 2027년 생일
                // 규칙은 같은 FAQ 예시(2025-11-10 변경 → 2026-11-09 만료)와 어긋나
                // 「포털 FAQ가 안내합니다」와 「실제 만료일 확인」을 함께 둔다.
                '2026년 1월 1일부터 부호에 1년 유효기간이 있습니다. 새로 받은 날·정보를 바꾼 날·'
                    '부호를 바꾼(재발급) 날부터 1년이고, 갱신하면 만료일부터 1년 늘어나며 부호 번호는 '
                    '그대로입니다.',
                '갱신은 만료일 전후 30일 안에 포털의 「유효기간 갱신」에서 합니다. 만료 뒤 30일이 '
                    '지나면 자동 해지되어 새로 발급받아야 합니다.',
                '2025년 12월 31일 이전에 받은 부호는 만료일이 2027년 본인 생일로 정해진다고 포털 '
                    'FAQ가 안내합니다. 실제 만료일은 포털 「조회/정보변경」에서 내 부호로 확인하세요.',
              ],
              linesEn: [
                'Since 1 January 2026 codes are valid for one year from the day '
                    'you got the code, changed your details or had the code changed '
                    '(reissued). Renewing extends it by one year from the expiry '
                    'date, and the code number stays the same.',
                'Renew within 30 days either side of the expiry date from the '
                    '«renew validity» menu on the portal. A code is cancelled '
                    'automatically 30 days after it expires, and you then need a '
                    'new one.',
                'For codes issued on or before 31 December 2025, the portal FAQ '
                    'says the expiry date is set to your birthday in 2027. Check '
                    'your own code’s actual expiry date under «look up / change '
                    'details» on the portal.',
              ],
            ),
          ],
          footnoteKo: '※ 관세청 전자상거래 통관포털의 자주 묻는 질문·공지 '
              '「\'전자상거래 통관포털\' 개설 안내(8월28일)」·개인통관고유부호 메뉴 안내서(모두 '
              '2026-08-27 게시)와 관세청 보도자료(2026-01-14) 기준, 2026-10-30 확인.',
          footnoteEn: '※ Based on the Korea Customs Service e-commerce customs '
              'portal’s FAQ, its launch notice and its customs-code menu guide '
              '(all posted 27 August 2026) and a press release (14 January 2026), '
              'checked 2026-10-30.',
        ),
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
            GuideNote(
              titleKo: '판매자 문제는 다른 가이드에',
              titleEn: 'Seller problems are in another guide',
              linesKo: [
                '물건이 오지 않거나 환불을 거부당한 것은 통관이 아니라 판매자와의 분쟁입니다. '
                    '「소비자 피해·환불 분쟁」 가이드의 순서를 따르세요.',
              ],
              linesEn: [
                'An order that never arrived or a refused refund is a dispute '
                    'with the seller, not a customs matter. Follow the «Refunds '
                    'and consumer disputes» guide.',
              ],
            ),
            GuideNote(
              titleKo: '본인인증이 막히면',
              titleEn: 'If identity verification fails',
              linesKo: [
                '실명확인이 안 되면 외국인등록증에 적힌 이름을 대소문자·띄어쓰기·하이픈까지 똑같이 '
                    '넣었는지 먼저 확인하세요. 그래도 안 되면 포털 FAQ는 코리아크레딧뷰로(KCB) '
                    '고객센터(02-708-1000)에 실명 등록을 확인하라고 안내합니다. 온라인이 안 되면 '
                    '신분증을 가지고 세관을 방문하는 방법이 있습니다.',
              ],
              linesEn: [
                'If the name check fails, first make sure you typed the name '
                    'exactly as on your residence card, including capitals, spaces '
                    'and hyphens. If it still fails, the portal FAQ says to check '
                    'your name registration with the Korea Credit Bureau (KCB) '
                    'call centre (02-708-1000). If online issuing does not work, '
                    'you can visit a customs office with your ID.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '🧾 주문 내역과 결제 영수증을 보관하세요 — 통관 기준은 물품가격으로 정해집니다.',
        '🏠 이사하면 포털의 주소부터 고치세요. 우편번호가 다르면 통관이 늦어질 수 있습니다.',
        '🔔 행정안전부 국민비서에서 전자상거래 물품 통관 알림을 받도록 설정하면, 내 부호로 '
            '통관될 때 알림을 받을 수 있습니다.',
      ],
      tipsEn: [
        '🧾 Keep the order and payment receipt — the clearance route depends on '
            'the price.',
        '🏠 When you move, update the address on the portal first. A postcode '
            'mismatch can delay clearance.',
        '🔔 Turn on e-commerce clearance alerts in the government «Kookmin '
            'Biseo» notification service to be told whenever something is '
            'cleared under your code.',
      ],
      phrases: [
        GuidePhrase(
          ko: '개인통관고유부호를 발급받고 싶습니다. 외국인등록증과 여권을 가져왔습니다.',
          en: 'I would like to get a personal customs clearance code. I have '
              'brought my residence card and passport.',
        ),
        GuidePhrase(
          ko: '제 소포가 세관에서 멈춰 있다는 연락을 받았습니다. 무엇을 내야 하나요?',
          en: 'I was told my parcel is being held at customs. What do I need to '
              'submit?',
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '관세청 전자상거래 통관포털',
          labelEn: 'Korea Customs Service e-commerce customs portal',
          descriptionKo: '부호 발급·조회·정보변경·갱신, 방문발급 사전신청, 통관내역 조회 (PC·모바일 웹)',
          descriptionEn: 'Issue, look up, update and renew the code; visit '
              'pre-application; clearance tracking (PC or mobile web; Korean/English)',
          url: 'https://ecos.customs.go.kr/',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '관세청 — 특송물품 통관',
          labelEn: 'Korea Customs Service — courier clearance',
          descriptionKo: '목록통관·간이·일반 수입신고와 배제 물품',
          descriptionEn: 'Manifest, simplified and regular clearance; '
              'excluded items (Korean)',
          url: 'https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?mi=2821&cntntsId=819',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '관세청 — 우편물 통관',
          labelEn: 'Korea Customs Service — postal clearance',
          descriptionKo: '국제우편 면세·과세와 수령',
          descriptionEn: 'Duty-free and taxable international mail (Korean)',
          url: 'https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?mi=2822&cntntsId=820',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '관세청 FAQ — 외국인 부호 발급',
          labelEn: 'Customs FAQ — codes for international residents',
          descriptionKo: '외국인 발급 대상과 준비 신분증',
          descriptionEn: 'Eligibility and the ID to bring (Korean)',
          url: 'https://www.customs.go.kr/call/ad/crmcc/selectFaqViewPage.do?mi=6822&cnslKnwlSrno=518',
          iconName: 'help',
        ),
        GuideLink(
          labelKo: '생활법령 — 의약품·건강기능식품 구매',
          labelEn: 'Easy law — buying medicines and supplements',
          descriptionKo: '금지성분 확인과 자가사용 면세',
          descriptionEn: 'Banned ingredients and personal-use exemption '
              '(Korean)',
          url: 'https://www.easylaw.go.kr/CSP/CnpClsMainBtr.laf?popMenu=ov&csmSeq=1504&ccfNo=2&cciNo=2&cnpClsNo=3&menuType=onhunqna',
          iconName: 'gavel',
        ),
        GuideLink(
          labelKo: '관세청 고객지원센터 125',
          labelEn: 'Korea Customs Service call centre 125',
          descriptionKo: '평일 09:00~18:00 · 해외에서는 82-2-3438-5199',
          descriptionEn: 'Weekdays 09:00–18:00 · from abroad 82-2-3438-5199',
          url: 'tel:125',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '가이드 — 소비자 피해·환불 분쟁',
          labelEn: 'Guide — Refunds and consumer disputes',
          descriptionKo: '미배송·환불 거부는 판매자와의 분쟁',
          descriptionEn: 'Non-delivery and refused refunds',
          url: '/guide/item/consumer-disputes',
          iconName: 'storefront',
        ),
      ],
    ),
  ];
}
