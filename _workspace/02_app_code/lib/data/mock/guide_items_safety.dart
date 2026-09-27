import '../../domain/entities/admin_guide.dart';

/// Guides added after the 2026-09-26 gap review (조사 04/029): the four places
/// where a student can lose money or fall foul of a local rule and the existing
/// 30 guides had no sequence of their own.
///
/// Kept apart from the others so each addition reviews as its own diff;
/// [MockData.guideItems] appends this list, so search, categories, the seed
/// export and the screens treat them exactly like the rest.
///
/// Every official source below was read on 2026-09-26. Where a step depends on
/// the building, the district or the supplier, the guide says so instead of
/// stating a number that would be wrong for half its readers: amounts, fees and
/// waiting times are deliberately absent unless the source states them for
/// everyone.
abstract final class SafetyGuides {
  static const List<AdminGuideItem> items = [
    // ── 이사·공과금 정산 ──────────────────────────────────────────────
    // 부산도시가스 전입·전출 신청(https://skens.com/busan/trans/trans.do, 고객센터
    // 1544-0009) · 부산광역시 상수도사업본부 자동납부 안내
    // (https://www.busan.go.kr/water/rateinfo01, 부산시 콜센터 051-120).
    // 전기 최종정산의 공개 경로는 확인하지 못했으므로 고지서의 공급자를 확인하는
    // 단계로 남긴다 (조사 04/029 §3.1).
    AdminGuideItem(
      id: 'moving-and-utilities',
      categoryId: GuideCategory.housing,
      searchAliasesKo: ['공과금', '전기요금', '가스요금', '수도요금', '관리비', '이사정산',
        '전출', '자동이체'],
      searchAliasesEn: ['utilities', 'electricity bill', 'gas bill', 'water bill',
        'maintenance fee', 'moving out', 'final bill', 'auto payment'],
      titleKo: '이사·공과금 정산',
      titleEn: 'Moving in and out: utilities',
      summaryKo: '입주·퇴거 때 전기·가스·수도·관리비 정리',
      summaryEn: 'Settling electricity, gas, water and fees',
      overviewKo: '교외에 살면 월세 말고도 전기·가스·수도와 관리비를 내야 합니다. 이 비용은 '
          '집마다 내는 방법이 다릅니다. 관리비에 포함된 집도 있고, 사용자가 직접 '
          '공급자에게 내는 집도 있습니다.\n\n'
          '문제는 들어갈 때보다 나갈 때 생깁니다. 계량기 숫자를 확인하지 않고 나오면 '
          '다음 사람이 쓴 요금이 내 이름으로 남거나, 반대로 내가 쓴 요금을 임대인이 '
          '보증금에서 빼기도 합니다.\n\n'
          '이 가이드는 입주·이사·출국 때 무엇을 확인하고 무엇을 사진으로 남겨야 하는지 '
          '순서대로 정리합니다. 공급자와 계약 명의는 집마다 다르므로, 고지서와 관리실에서 '
          '먼저 확인하는 단계부터 시작합니다.',
      overviewEn: 'Living off campus means bills beyond the rent: electricity, '
          'gas, water and a maintenance fee. How you pay them differs from one '
          'building to the next — some include them in the maintenance fee, '
          'others expect you to deal with each supplier yourself.\n\n'
          'The trouble usually comes when you leave. Move out without '
          'recording the meter and the next tenant\'s usage can end up in your '
          'name, or your own usage comes out of your deposit.\n\n'
          'This guide sets out, in order, what to check and what to photograph '
          'when you move in, move house, or leave the country. Because the '
          'supplier and the account holder differ by building, it starts by '
          'finding out who they actually are.',
            checklistKo: [
          '임대차계약서와 정확한 주소·호수',
          '입주일·퇴거일',
          '최근 고지서 또는 고객번호(있는 경우)',
          '계량기 사진(입주일·퇴거일)',
          '자동납부에 쓰는 계좌·카드 정보',
          '임대인·관리실 연락처',
          '본인확인 서류',
        ],
      checklistEn: [
          'Your lease and the exact address, including the unit number',
          'Move-in and move-out dates',
          'A recent bill or customer number, if you have one',
          'Photos of the meters, on the day you move in and the day you leave',
          'The account or card used for automatic payment',
          'Contact details for your landlord and the building office',
          'Photo ID',
        ],
      checklistNoteKo: '고지서가 없다면 관리실이나 임대인에게 «공급자와 고객번호»를 물어보세요. '
            '그것부터 알아야 나머지 절차가 진행됩니다.',
              stepsKo: [
          '계약서에서 관리비에 무엇이 포함되는지 확인한다'
              '관리비에 수도·인터넷이 포함된 집도 있고, 전기만 따로 내는 집도 있습니다. '
              '계약서에 적힌 항목과 실제 고지서를 맞춰 보세요.',
          '전기·가스·수도의 공급자와 명의를 확인한다'
              '고지서나 관리실을 통해 각 공급자와 현재 명의자를 확인합니다. '
              '명의가 임대인으로 되어 있으면 사용자가 직접 해지할 수 없는 경우가 있습니다.',
          '입주일에 계량기와 집 상태를 사진으로 남긴다'
              '전기·가스·수도 계량기 숫자가 보이게 찍고, 날짜가 남도록 저장하세요. '
              '퇴거 정산과 보증금 분쟁에서 가장 확실한 자료입니다.',
          '가스는 전입·전출 신청이 필요한지 확인한다'
              '부산도시가스는 전입·전출 신청을 받습니다. 방문이 필요한지, 언제 '
              '예약해야 하는지는 공식 페이지나 고객센터(1544-0009)에서 확인하세요.',
          '자동납부를 새로 등록하거나 해지한다'
              '상수도 자동납부는 납기 며칠 전까지 변경·해지해야 합니다. 기한은 '
              '공식 안내에서 확인하세요. 해지를 잊으면 이사 뒤에도 인출될 수 있습니다.',
          '퇴거일 계량값과 최종 정산내역을 문서로 받는다'
              '퇴거일에 계량기를 다시 찍고, 관리비·공과금 정산내역을 문서(메시지·이메일 등 '
              '기록이 남는 형태)로 받으세요.',
          '보증금 반환과 열쇠 인도 일정을 따로 정한다'
              '공과금 정산과 보증금 반환은 관련은 있지만 같은 절차가 아닙니다. '
              '반환 일정과 방법을 임대인과 따로 확정하세요.',
          '주소 변경과 출국 절차로 넘어간다'
              '이사하면 체류지 변경 신고가 필요합니다. 출국이라면 출국 전 정리 '
              '가이드의 순서를 함께 확인하세요.',
        ],
        stepsEn: [
          'Check what the maintenance fee covers'
              'Some buildings bundle water or internet into the '
              'maintenance fee; others bill electricity separately. Match what '
              'the lease lists against an actual bill.',
          'Find out the supplier and whose name the account is in'
              'Use the bill or the building office to identify each '
              'supplier and the current account holder. If the account is in '
              'the landlord\'s name, you may not be able to close it yourself.',
          'Photograph the meters and the flat on move-in day'
              'Photograph each meter so the numbers are legible, and keep '
              'the date on the file. This is the strongest evidence you will '
              'have in a move-out or deposit dispute.',
          'Check whether gas needs a move-in or move-out visit'
              'Busan City Gas takes move-in and move-out requests. Check '
              'the official page or call 1544-0009 to find out whether a visit '
              'is needed and how far ahead to book it.',
          'Set up or cancel automatic payment'
              'Water bill auto-payment has to be changed or cancelled a '
              'few days before the due date — check the official page for the '
              'exact cut-off. Forget it and money can still leave your account '
              'after you have moved.',
          'Get the closing meter readings and the final statement'
              'Photograph the meters again on the day you leave, and get '
              'the final statement of fees and utilities in writing — a '
              'message or email, something that leaves a record.',
          'Agree the deposit and key handover separately'
              'Settling the utilities and getting your deposit back are '
              'related but not the same process. Agree the date and method for '
              'the deposit with your landlord separately.',
          'Move on to the address change and departure steps'
              'Moving means you must report the change of address. If you '
              'are leaving Korea, follow the departure checklist as well.',
        ],
            sections: [
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
          GuideNote(
            titleKo: '집마다 다릅니다',
            titleEn: 'It differs by building',
            linesKo: ['이 가이드는 «모두 직접 해지하라»는 뜻이 아닙니다. 관리비 포함 범위와 '
                '계약 명의에 따라 해야 할 일이 달라지므로, 2단계에서 확인한 내용을 기준으로 '
                '움직이세요.'],
            linesEn: ['This guide does not say «close every account yourself». '
                'What you have to do depends on what the maintenance fee covers '
                'and whose name the account is in — work from what you found in '
                'step 2.'],
          ),
          GuideNote(
            titleKo: '금액·수수료는 적지 않았습니다',
            titleEn: 'No amounts or fees here',
            linesKo: ['요금과 수수료, 예약에 걸리는 날짜는 공급자와 시기에 따라 달라집니다. '
                '공식 페이지나 고객센터에서 그때의 값을 확인하세요.'],
            linesEn: ['Charges, fees and how long a booking takes vary by supplier '
                'and by season. Check the official page or the call centre for '
                'the figure that applies to you.'],
          ),
          ],
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '부산도시가스 전입·전출 신청',
          labelEn: 'Busan City Gas — move-in / move-out',
          url: 'https://skens.com/busan/trans/trans.do',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '부산도시가스 고객센터 1544-0009',
          labelEn: 'Busan City Gas call centre 1544-0009',
          url: 'tel:15440009',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '부산 상수도 자동납부 안내',
          labelEn: 'Busan Waterworks — automatic payment',
          url: 'https://www.busan.go.kr/water/rateinfo01',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '가이드 — 체류지·등록사항 변경신고',
          labelEn: 'Guide — Reporting a change of address',
          url: '/guide/item/address-and-registration-changes',
          iconName: 'assignment',
        ),
        GuideLink(
          labelKo: '가이드 — 임대차 보증금 지키기',
          labelEn: 'Guide — Protecting your deposit',
          url: '/guide/item/rental-deposit-protection',
          iconName: 'home',
        ),
      ],
    ),

    // ── 생활쓰레기·분리배출 ───────────────────────────────────────────
    // 부산광역시 생활쓰레기 안내(https://www.busan.go.kr/depart/ahwasteinfo01) ·
    // 환경부 「재활용품 분리배출 가이드라인」 · 부산시 외국인 지원 안내가 분리배출을
    // 외국인 생활교육 항목으로 명시한다 (조사 04/029 §3.2).
    AdminGuideItem(
      id: 'waste-and-recycling',
      categoryId: GuideCategory.living,
      searchAliasesKo: ['쓰레기', '분리수거', '분리배출', '종량제봉투', '음식물쓰레기',
        '대형폐기물', '이사쓰레기'],
      searchAliasesEn: ['waste', 'rubbish', 'recycling', 'food waste',
        'bulky waste', 'garbage bag', 'trash'],
      titleKo: '쓰레기 버리기·분리배출',
      titleEn: 'Waste and recycling',
      summaryKo: '일반·음식물·재활용·대형폐기물 배출 방법',
      summaryEn: 'General, food, recyclable and bulky waste',
      overviewKo: '한국에서는 쓰레기를 종류별로 나누어 정해진 봉투에 담아 정해진 장소와 '
          '시간에 내놓습니다. 규칙은 구·동·건물마다 다릅니다. 같은 부산 안에서도 '
          '봉투 종류와 배출 요일이 다를 수 있습니다.\n\n'
          '잘못 버리면 수거해 가지 않거나 스티커가 붙어 돌아오고, 반복되면 이웃·관리실과 '
          '갈등이 생기거나 행정상 불이익을 받을 수 있습니다.\n\n'
          '이 가이드는 «내가 사는 곳의 규칙을 어디서 확인하는지»부터 시작해, 품목을 '
          '어떻게 나누고 어디에 내놓는지 정리합니다. 품목이 애매하면 임의로 버리지 말고 '
          '구청이나 관리실에 확인하세요.',
      overviewEn: 'In Korea rubbish is separated by type, put in the '
          'prescribed bag, and left at a set place and time. The rules differ '
          'by district, by neighbourhood and by building — even within '
          'Busan the bags and the collection days are not the same everywhere.'
          '\n\n'
          'Get it wrong and the rubbish is left behind, often with a sticker '
          'on it. Repeatedly getting it wrong can mean friction with '
          'neighbours or the building office, and can carry administrative '
          'consequences.\n\n'
          'This guide starts with where to find the rules for your own '
          'address, then covers how to sort and where to leave each type. When '
          'an item is unclear, ask the district office or the building rather '
          'than guessing.',
            checklistKo: [
          '내 주소의 관할 구 이름',
          '건물의 배출 장소·요일(관리실 공지 또는 게시판)',
          '관할 지역에서 파는 종량제봉투',
        ],
      checklistEn: [
          'The district (구) your address belongs to',
          'Your building\'s collection point and days — from the notice board '
              'or the building office',
          'The official bags sold for that district',
        ],
      checklistNoteKo: '종량제봉투는 지역마다 다릅니다. 다른 구에서 산 봉투는 수거하지 않을 수 '
            '있으니 동네 편의점·마트에서 «이 동네 봉투»를 사세요.',
              stepsKo: [
          '주소의 관할 구와 건물 규칙을 확인한다'
              '건물 게시판·관리실 공지에 배출 장소와 요일이 적혀 있는 경우가 많습니다. '
              '없으면 관할 구청 안내를 확인하세요.',
          '일반·음식물·재활용·대형폐기물로 나눈다'
              '네 가지는 봉투도 배출 방법도 다릅니다. 음식물은 전용 봉투나 전용 '
              '수거함을 씁니다.',
          '재활용품은 비우고 헹구고 분리한다'
              '내용물을 비우고, 물로 헹구고, 라벨이나 뚜껑처럼 재질이 다른 부분을 '
              '분리합니다. 환경부 분리배출 가이드라인의 기본 원칙입니다.',
          '관할 지역의 봉투를 사서 담는다'
              '일반쓰레기와 음식물쓰레기는 지정된 봉투에 담아야 수거합니다.',
          '정해진 장소·시간에 내놓는다'
              '건물이나 구청이 안내한 장소와 시간을 지키세요. 시간 전에 내놓으면 '
              '수거되지 않고 남아 있을 수 있습니다.',
          '대형폐기물은 미리 신고한다'
              '가구·가전처럼 큰 물건은 관할 구청에 신고하고 수수료를 낸 뒤 '
              '스티커나 필증을 받아 붙여야 합니다. 절차와 금액은 구청 안내를 확인하세요.',
          '애매하면 버리기 전에 물어본다'
              '분류가 헷갈리는 물건은 임의로 버리지 말고 구청이나 관리실에 '
              '확인하세요.',
        ],
        stepsEn: [
          'Find your district and your building\'s rules'
              'The collection point and days are usually posted in the '
              'building. If not, check the district office\'s guidance.',
          'Sort into general, food, recyclable and bulky'
              'The four go out differently and in different bags. Food '
              'waste uses its own bag or its own bin.',
          'Empty, rinse and separate recyclables'
              'Empty the container, rinse it, and take off parts made of a '
              'different material such as labels or caps — the basic rule in '
              'the Ministry of Environment guideline.',
          'Buy the right bag and use it'
              'General and food waste are only collected in the '
              'designated bags.',
          'Put it out at the right place and time'
              'Follow the place and time your building or district gives. '
              'Put it out early and it may simply sit there.',
          'Report bulky waste in advance'
              'Furniture and appliances have to be reported to the '
              'district office, paid for, and labelled with the sticker or '
              'slip they issue. Check the district office for the procedure '
              'and the fee.',
          'When in doubt, ask before you throw it out'
              'If you cannot place an item, ask the district office or the '
              'building rather than guessing.',
        ],
            sections: [
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
          GuideNote(
            titleKo: '이사할 때가 가장 많이 나옵니다',
            titleEn: 'Moving produces the most of it',
            linesKo: ['이사 전에 대형폐기물 신고 일정을 먼저 잡으세요. 수거일이 며칠 뒤로 '
                '잡히면 퇴거일을 넘길 수 있습니다.'],
            linesEn: ['Book the bulky-waste collection before you move. If the '
                'date they give falls after your move-out day, you have a '
                'problem.'],
          ),
          ],
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '부산광역시 생활쓰레기 안내',
          labelEn: 'Busan — household waste',
          url: 'https://www.busan.go.kr/depart/ahwasteinfo01',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '환경부 재활용품 분리배출 가이드라인',
          labelEn: 'Ministry of Environment — recycling guideline',
          url: 'https://me.go.kr/home/web/public_info/read.do?publicInfoId=934&menuId=10357',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '가이드 — 교외주거 구하기',
          labelEn: 'Guide — Finding off-campus housing',
          url: '/guide/item/off-campus-housing',
          iconName: 'home',
        ),
      ],
    ),

    // ── 소비자 피해·환불 분쟁 ─────────────────────────────────────────
    // 한국소비자원 1372 소비자상담센터 · 소비자24 · 경찰 ECRM이 환불·배송·약관
    // 분쟁을 형사 사건과 구분해 안내한다 (조사 04/029 §3.3).
    AdminGuideItem(
      id: 'consumer-disputes',
      categoryId: GuideCategory.living,
      searchAliasesKo: ['환불', '소비자피해', '미배송', '계약분쟁', '중고거래', '1372',
        '소비자24'],
      searchAliasesEn: ['refund', 'consumer', 'not delivered', 'dispute',
        'second-hand', 'scam seller'],
      titleKo: '소비자 피해·환불 분쟁',
      titleEn: 'Refunds and consumer disputes',
      summaryKo: '결제 후 환불·미배송 문제를 푸는 순서',
      summaryEn: 'What to do when a purchase goes wrong',
      overviewKo: '물건이 오지 않거나, 설명과 다르거나, 환불을 거부당하는 일은 누구에게나 '
          '생깁니다. 한국에는 판매자와 해결되지 않을 때 상담하고 피해구제를 신청할 수 있는 '
          '공식 창구가 있습니다.\n\n'
          '중요한 것은 순서입니다. 먼저 증거를 남기고, 판매자에게 기록이 남는 방식으로 '
          '요구하고, 그래도 안 되면 1372 소비자상담센터에 상담합니다.\n\n'
          '처음부터 속일 의도가 있었던 경우(입금 후 잠적, 계정 탈취, 피싱 등)는 소비자 '
          '분쟁이 아니라 범죄입니다. 그때는 경찰 신고로 넘어가세요 — 아래 6단계에 적어 '
          '두었습니다.',
      overviewEn: 'Goods that never arrive, goods that are not what was '
          'described, a refund that is refused — it happens to everyone. Korea '
          'has official places to get advice and to file for redress when the '
          'seller will not put it right.\n\n'
          'What matters is the order. Keep the evidence first, put your '
          'demand to the seller in a form that leaves a record, and if that '
          'fails, take it to the 1372 consumer counselling centre.\n\n'
          'If you were deceived from the start — payment then silence, a '
          'hijacked account, phishing — that is a crime, not a consumer '
          'dispute, and it goes to the police instead. Step 6 covers that.',
            checklistKo: [
          '주문·결제 내역(화면 캡처 포함)',
          '판매자와 주고받은 대화·이메일',
          '상품 설명 페이지 캡처',
          '받은 물건의 사진(있다면)',
          '결제 수단 정보(카드사·간편결제 등)',
        ],
      checklistEn: [
          'The order and payment record, screenshots included',
          'Messages or emails exchanged with the seller',
          'A capture of the product description page',
          'Photos of what actually arrived, if anything did',
          'What you paid with — card company, payment app',
        ],
      checklistNoteKo: '대화가 삭제될 수 있는 앱을 썼다면 먼저 캡처해 두세요. 분쟁이 시작되면 '
            '판매자가 글을 내리는 경우가 많습니다.',
              stepsKo: [
          '추가 결제·원격제어 요구를 중단한다'
              '«해결해 주겠다»며 추가 결제나 원격제어 앱 설치를 요구하면 응하지 '
              '마세요. 피해가 커지는 전형적인 경로입니다.',
          '증거를 모아 저장한다'
              '주문 내역·대화·상품 설명을 캡처해 한곳에 모으세요.',
          '판매자에게 기록이 남는 방식으로 요구한다'
              '전화보다 메시지·이메일처럼 기록이 남는 방식으로 환불이나 이행을 '
              '요구하세요. 날짜와 요구 내용이 남아야 합니다.',
          '결제수단의 이의제기가 가능한지 확인한다'
              '카드나 간편결제에 따라 이의제기·결제취소 절차가 있을 수 있습니다. '
              '가능 여부와 기한을 해당 회사에 확인하세요.',
          '1372 소비자상담센터에 상담한다'
              '전화 1372로 분쟁 유형과 다음 절차를 상담할 수 있습니다. '
              '온라인은 소비자24를 이용합니다.',
          '해결되지 않으면 피해구제를 신청한다'
              '한국소비자원의 피해구제 대상과 신청 방법을 확인해 신청합니다.',
          '범죄가 의심되면 경찰로 넘어간다'
              '처음부터 속일 의도가 보이면 소비자 분쟁이 아니라 사기입니다. '
              '경찰 신고 경로와 금융사기 대응 가이드를 확인하세요.',
          '접수번호와 제출 자료를 보관한다'
              '상담·신청 번호, 제출한 자료, 받은 답변을 모아 두세요. 이후 '
              '절차에서 계속 필요합니다.',
        ],
        stepsEn: [
          'Stop paying and stop installing anything'
              'If someone offers to «fix it» in exchange for another '
              'payment or asks you to install a remote-control app, stop. That '
              'is how a small loss becomes a large one.',
          'Collect and save the evidence'
              'Capture the order, the conversation and the description, '
              'and keep them together.',
          'Put your demand to the seller in writing'
              'Use a message or email rather than a phone call, so the '
              'date and what you asked for are on record.',
          'Ask your payment provider about a chargeback'
              'Depending on the card or payment service there may be a '
              'dispute or cancellation process. Ask them whether it applies '
              'and by when.',
          'Call the 1372 consumer counselling centre'
              'Dial 1372 for advice on what kind of dispute this is and '
              'what comes next. Online, use 소비자24 (consumer.go.kr).',
          'File for redress if it is still unresolved'
              'Check what the Korea Consumer Agency\'s redress process '
              'covers and how to apply, then apply.',
          'If it looks like a crime, go to the police'
              'Where there was intent to deceive from the start it is '
              'fraud, not a consumer dispute. Use the police route and the '
              'financial-fraud guide.',
          'Keep the case number and what you submitted'
              'Keep the reference numbers, what you sent and what you were '
              'told. You will need them at every later step.',
        ],
            sections: [
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
          GuideNote(
            titleKo: '소비자 분쟁과 범죄는 창구가 다릅니다',
            titleEn: 'Disputes and crimes go to different places',
            linesKo: ['환불·배송·약관 다툼은 소비자 창구, 처음부터 속인 경우는 경찰입니다. '
                '어느 쪽인지 애매하면 1372에서 먼저 상담하세요.'],
            linesEn: ['Refunds, delivery and terms go to the consumer service; '
                'deliberate deception goes to the police. If you cannot tell '
                'which it is, start with 1372.'],
          ),
          ],
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '1372 소비자상담센터 전화',
          labelEn: 'Call 1372 — consumer counselling',
          url: 'tel:1372',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '한국소비자원 1372 안내',
          labelEn: 'Korea Consumer Agency — 1372',
          url: 'https://data.kca.go.kr/info/html/intro_info.html',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '가이드 — 금융사기·피싱 긴급 대응',
          labelEn: 'Guide — Fraud and phishing: act now',
          url: '/guide/item/financial-scam-response',
          iconName: 'emergency',
        ),
      ],
    ),

    // ── 금융사기·피싱 긴급 대응 ───────────────────────────────────────
    // 경찰청 ECRM 피해자 구제 안내(지급정지 → 신고·확인서 → 은행 피해구제) ·
    // 긴급 112 · 상담 182 (조사 04/029 §3.4).
    AdminGuideItem(
      id: 'financial-scam-response',
      categoryId: GuideCategory.emergency,
      searchAliasesKo: ['보이스피싱', '피싱', '사기송금', '지급정지', '금융사기',
        '대포통장', '악성앱'],
      searchAliasesEn: ['voice phishing', 'phishing', 'scam transfer',
        'payment suspension', 'fraud', 'malicious app'],
      titleKo: '금융사기·피싱 긴급 대응',
      titleEn: 'Fraud and phishing: act now',
      summaryKo: '송금 직후 지급정지·신고·피해구제 순서',
      summaryEn: 'Freeze, report, claim — in that order',
      overviewKo: '돈을 보낸 뒤에는 시간이 가장 중요합니다. 사기 계좌에서 돈이 빠져나가기 '
          '전에 지급정지를 요청해야 돌려받을 가능성이 생깁니다.\n\n'
          '순서는 지급정지 → 경찰 신고 → 은행 피해구제입니다. 은행은 경찰이 발급한 '
          '확인서를 요구하므로 세 절차가 이어져 있습니다.\n\n'
          '검찰·경찰·금융감독원이라며 «안전계좌로 옮기라»고 하는 전화는 없습니다. '
          '이미 앱을 설치했거나 인증번호를 알려 줬다면 아래 6단계를 함께 하세요.',
      overviewEn: 'Once the money has gone, time is everything. Getting a '
          'payment suspension on the receiving account before it is emptied is '
          'what makes recovery possible at all.\n\n'
          'The order is: freeze the account, report to the police, then claim '
          'through your bank. The bank will ask for the confirmation the '
          'police issue, which is why the three steps are linked.\n\n'
          'No prosecutor, police officer or financial regulator will ever ring '
          'you and tell you to move your money to a «safe account». If you '
          'have already installed an app or passed on a verification code, do '
          'step 6 as well.',
            checklistKo: [
          '이체 내역(은행 앱 화면 캡처)',
          '상대 계좌번호와 은행 이름',
          '통화·문자·메신저 기록',
          '신분증',
          '설치한 앱 이름(있다면)',
        ],
      checklistEn: [
          'The transfer record — a screenshot from your banking app',
          'The receiving account number and bank',
          'Call, text and messenger records',
          'Photo ID',
          'The name of any app you were asked to install',
        ],
      checklistNoteKo: '자료를 모으느라 지급정지를 미루지 마세요. 먼저 전화하고 나중에 '
            '정리해도 됩니다.',
              stepsKo: [
          '추가 송금·인증번호 전달·원격제어를 즉시 멈춘다'
              '통화를 끊고, 인증번호를 알려 주지 말고, 원격제어 앱을 열지 마세요.',
          '은행에 지급정지를 요청한다'
              '내가 보낸 은행과 상대 계좌의 은행 모두에 연락해 지급정지를 '
              '요청하세요. 가장 급한 단계입니다.',
          '경찰에 신고한다'
              '긴급하면 112. 온라인·방문 신고 방법은 경찰 ECRM 안내에서 '
              '확인하세요. 상담은 182입니다.',
          '필요한 확인서를 발급받는다'
              '경찰이 안내하는 사건사고사실확인원 등 은행 제출용 서류를 '
              '발급받습니다.',
          '은행에 피해구제를 신청한다'
              '확인서와 이체 내역을 제출해 피해구제를 신청하세요. 기한이 있으므로 '
              '은행이 안내한 날짜를 지키세요.',
          '비밀번호·인증수단을 안전한 기기에서 바꾼다'
              '악성 앱이 설치됐을 수 있으므로, 사기에 쓰인 기기가 아닌 안전한 '
              '기기에서 은행·이메일·메신저 비밀번호와 인증수단을 바꾸세요.',
          '접수번호와 기한을 기록한다'
              '경찰 신고번호, 은행 접수번호, 제출 기한을 적어 두고 안내에 따라 '
              '후속 조치를 하세요.',
        ],
        stepsEn: [
          'Stop sending money, codes and access — now'
              'Hang up, give no verification codes, and do not open any '
              'remote-control app.',
          'Ask the bank to freeze the account'
              'Contact both your own bank and the bank of the receiving '
              'account and ask for a payment suspension. This is the urgent '
              'one.',
          'Report it to the police'
              'In an emergency call 112. For online or in-person reporting '
              'follow the police ECRM guidance; 182 is the enquiry line.',
          'Get the confirmation document'
              'Obtain the document the police direct you to — the incident '
              'confirmation the bank will ask for.',
          'File the claim with your bank'
              'Submit the confirmation and the transfer record to claim. '
              'There are deadlines — keep the date the bank gives you.',
          'Change your passwords from a clean device'
              'A malicious app may still be watching. Change your banking, '
              'email and messenger passwords — and your verification methods — '
              'from a device that was not involved.',
          'Write down the case numbers and deadlines'
              'Note the police report number, the bank\'s reference and '
              'every deadline, then follow what each of them tells you next.',
        ],
            sections: [
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
          GuideNote(
            titleKo: '돌려받는다고 약속할 수는 없습니다',
            titleEn: 'No one can promise you get it back',
            linesKo: ['지급정지와 피해구제는 돈이 계좌에 남아 있을 때 효과가 있습니다. '
                '그래서 속도가 중요합니다. 결과는 사건마다 다릅니다.'],
            linesEn: ['A freeze and a claim work when the money is still in the '
                'account — which is why speed matters. Outcomes differ case by '
                'case.'],
          ),
          GuideNote(
            titleKo: '부끄러워할 일이 아닙니다',
            titleEn: 'This is not something to be ashamed of',
            linesKo: ['수법이 정교해서 누구나 당할 수 있습니다. 늦었다고 생각해도 신고하세요 '
                '— 같은 계좌의 다음 피해를 막습니다.'],
            linesEn: ['These are well-built operations and they catch careful '
                'people. Report it even if you think it is too late — it stops '
                'the same account taking someone else.'],
          ),
          ],
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '112 전화하기',
          labelEn: 'Call 112',
          url: 'tel:112',
          iconName: 'emergency',
        ),
        GuideLink(
          labelKo: '경찰 ECRM 피해자 구제 안내',
          labelEn: 'Police ECRM — help for victims',
          url: 'https://ecrm.police.go.kr/minwon/crs/quick/vichelp',
          iconName: 'link',
        ),
        GuideLink(
          labelKo: '가이드 — 사건·사고 대응',
          labelEn: 'Guide — If something happens',
          url: '/guide/item/incident-response',
          iconName: 'emergency',
        ),
        GuideLink(
          labelKo: '가이드 — 은행 계좌 개설',
          labelEn: 'Guide — Opening a bank account',
          url: '/guide/item/bank-account',
          iconName: 'account_balance',
        ),
      ],
    ),
  ];
}
