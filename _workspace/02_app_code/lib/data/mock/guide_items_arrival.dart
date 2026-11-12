import '../../domain/entities/admin_guide.dart';

/// A1 — the arrival guide added in r19 (사용자 승인: 34개 유지 + 길잡이 1개 추가).
///
/// Why it exists: every piece of this was already in the catalogue, but each
/// guide states only its OWN precondition — the transit card needs nothing, the
/// bank may open a limited account, a postpaid line needs the residence card,
/// registration has a 90-day statutory deadline, and health insurance starts at
/// a different time for D-2 and D-4-1. Nothing told a new arrival what order to
/// do them in, and the app cannot link to a section (links are
/// `/guide/item/<id>` only) nor search one (the index covers title, detail
/// title, summary and aliases — not section bodies). So the sequence needed a
/// guide of its own rather than a paragraph inside `arc-issue`.
///
/// What it deliberately does NOT do:
/// - It does not restate the procedures. Each step names the action and links
///   to the guide that owns the detail.
/// - It does not use "2주" (or any single window) as a shared deadline. Only
///   the alien registration has one, and it is 90 days (조사 04/045 §2.1).
/// - It does not assume exchange, degree and language students share
///   conditions; the differences get their own section.
///
/// Sources were read by 조사 코덱스 on 2026-10-25 KST and are listed in
/// `D:\orca-audit-output\04_조사코덱스\045_행정가이드_공식근거조사_20261025.md`:
/// 출입국관리법 제31조(외국인등록) · 금융위원회 한도제한계좌 안내(2024-05-02 시행)
/// · 국민건강보험공단 외국인 가입자 관리 안내 · 한국관광공사 교통카드 안내.
/// Figures that the sources do not state for everyone (whether the ARC fee is
/// cash only, whether every carrier limits a passport-only line to prepaid) are
/// written as "확인하세요", not as facts.
abstract final class ArrivalGuide {
  static const List<AdminGuideItem> items = [
    AdminGuideItem(
      id: 'arrival-first-steps',
      categoryId: GuideCategory.immigration,
      // Without this the default is `comingSoon`: the detail screen would show
      // the placeholder instead of the content, and `orderGuideItems` — which
      // partitions published from coming-soon before keeping catalogue order —
      // would move this guide to the END of 입국·체류 instead of the front.
      status: GuideStatus.published,
      searchAliasesKo: [
        '입국',
        '입국 직후',
        '도착',
        '처음',
        '무엇부터',
        '순서',
        '첫 주',
        '정착',
        '입국 후 할 일',
      ],
      searchAliasesEn: [
        'arrival',
        'just arrived',
        'first steps',
        'what first',
        'order',
        'first week',
        'settling in',
        'after arriving',
      ],
      titleKo: '입국 후 처음 해야 할 일',
      titleEn: 'Your first steps after arriving',
      detailTitleKo: '입국 후 처음 해야 할 일 — 무엇이 먼저고 무엇을 같이 할 수 있나',
      detailTitleEn: 'After you arrive — what comes first, and what can run '
          'alongside',
      // 감사 05/062 F-1: 목록 행의 요약은 `maxLines: 2` + ellipsis 로 그려지고
      // 320dp 에서 2줄이 담는 양은 56~60폭이다. 네 절차를 열거한 앞판은 ko 60 ·
      // zh 61 · vi 160 폭이어서 **끝에 있던 「90일」이 가장 먼저 잘렸다** — r19 가
      // 드러내려던 숫자다. 그래서 숫자를 앞으로 빼고 짧게 썼다. 비교 범위를
      // 밝히는 일은 제목·notice·steps·tips 가 맡는다(여기서는 전체에 대한
      // 주장을 하지 않으므로 범위를 좁힐 대상이 없다).
      summaryKo: '외국인등록 90일 — 교통·통신·은행은 마감 없음',
      summaryEn: 'Registration: 90 days. Transit, phone, bank: no deadline',
      iconName: 'flight_takeoff',
      overviewKo: '이 가이드는 절차를 설명하지 않습니다. 무엇을 먼저 하고 무엇을 같이 할 수 '
          '있는지만 알려 주고, 각 단계에서 그 절차를 담은 가이드로 보냅니다.\n\n'
          '이 가이드에서 비교하는 외국인등록·교통카드·통신·은행 가운데 법정 신청 마감이 '
          '있는 것은 외국인등록입니다. 90일을 초과해 체류할 예정이면 입국한 날부터 90일 '
          '이내에 신청해야 합니다. 교통카드·휴대폰·은행은 외국인등록과 같이 진행할 수 '
          '있습니다. 다만 살 곳을 교외에서 구해 임대차계약을 했다면 금액 기준에 따라 '
          '계약일부터 30일 이내 신고 의무가 생길 수 있으니 「임대차 보증금 지키기」 '
          '가이드를 확인하세요. 이사 뒤 체류지 변경신고처럼 나중에 별도 기한이 생기는 '
          '절차와 건강보험의 체류자격별 적용 시점도 각 연결 가이드에서 확인하세요.\n\n'
          '건강보험은 체류자격에 따라 적용 시점이 다릅니다. 유학(D-2)과 어학연수(D-4-1)가 '
          '같지 않으니 아래에서 본인 자격을 확인하세요.',
      overviewEn: 'This guide does not explain the procedures. It only tells you '
          'what to do first and what can run in parallel, and sends you to the '
          'guide that owns each one.\n\n'
          'Of the steps compared here — registration, transit card, phone and '
          'bank — the one with a statutory filing deadline is the alien '
          'registration. If you will stay more than 90 days, you must apply '
          'within 90 days of arriving. The transit card, a phone line and a '
          'bank account can run alongside it. If you sign a lease off campus, '
          'though, the contract itself may have to be reported within 30 days '
          'depending on the rent and deposit — see the deposit guide. Steps '
          'that bring their own deadline later — reporting a move after you '
          'register — and when health insurance applies to your status are in '
          'the guides linked below.\n\n'
          'Health insurance starts at different times depending on your status '
          'of stay. Degree study (D-2) and language training (D-4-1) are not '
          'the same — check yours below.',
      topSections: [
        GuideSection(
          titleKo: '외국인등록·교통·통신·은행 — 신청 마감이 있는 것과 없는 것',
          titleEn: 'Registration, transit, phone, bank — what has a deadline',
          iconName: 'event_busy',
          notes: [
            GuideNote(
              titleKo: '⏰ 외국인등록 — 90일 법정 신청 마감',
              titleEn: '⏰ Alien registration — a 90-day statutory deadline',
              linesKo: [
                '90일을 초과해 체류할 예정이면 입국한 날부터 90일 이내에 신청합니다.',
                '국내에서 체류자격을 새로 받았거나 체류자격 변경허가를 받았다면 입국일 '
                    '기준 90일을 기다리지 말고 그 허가를 받을 때 신청합니다.',
                '교환학생도 자격 이름만으로 면제되지 않습니다. 실제 예정 체류기간이 90일을 '
                    '넘는지로 판단하세요.',
              ],
              linesEn: [
                'If you will stay more than 90 days, apply within 90 days of '
                    'the day you arrived.',
                'If you were granted a status of stay — or permission to change '
                    'it — inside Korea, do not wait out the 90 days: apply when '
                    'that permission is granted.',
                'Exchange students are not exempt because of the status name. '
                    'What matters is whether the stay will exceed 90 days.',
              ],
            ),
            GuideNote(
              titleKo: '✅ 교통카드·통신·은행 — 신청 마감 없이 병행',
              titleEn: '✅ Transit card, phone, bank — no deadline, run them '
                  'alongside',
              linesKo: [
                '교통카드는 외국인등록증이나 한국 계좌 없이 살 수 있습니다.',
                '여권으로 개통할 수 있는 선불 통신상품이 있습니다. 가능한 상품과 사용기간은 '
                    '통신사마다 다르니 확인하세요.',
                '은행 계좌는 외국인등록증을 받기 전에도 문의할 수 있습니다. 다만 개설이 '
                    '보장되지는 않습니다.',
              ],
              linesEn: [
                'You can buy a transit card without a residence card or a '
                    'Korean bank account.',
                'Some prepaid mobile products can be opened with a passport. '
                    'Which products, and for how long, differs by carrier — '
                    'check before you sign up.',
                'You can ask a bank about an account before your residence card '
                    'arrives, but no bank guarantees it will open one.',
              ],
            ),
          ],
          noticeKo: '초기 절차에 공통된 「도착 후 2주」 기한은 없습니다\n'
              '절차마다 기준이 다르고, 하나의 기간 안에 전부 끝내야 한다는 공식 안내는 '
              '없습니다. 이 가이드가 비교하는 외국인등록·교통카드·통신·은행 가운데 법정 '
              '신청 마감이 있는 것은 외국인등록의 90일입니다. 다만 이사 뒤 체류지 '
              '변경신고에는 15일의 별도 기한이 있고, 조건에 해당하는 주택 임대차계약에는 '
              '계약일부터 30일의 별도 신고기한이 생길 수 있으며, 건강보험에도 체류자격별 '
              '적용 시점이 있으므로 각 연결 가이드에서 확인하세요.',
          noticeEn: 'There is no shared "two weeks after arrival" window\n'
              'Each procedure has its own basis, and no official guidance says '
              'they must all be finished inside one period. Of the steps '
              'compared here — registration, transit card, phone and bank — '
              'the one with a statutory filing deadline is the registration, '
              'at 90 days. Reporting a move after you register carries its own '
              '15-day deadline, a qualifying lease must be reported within 30 '
              'days of signing, and health insurance starts at different times '
              'by status — check each in the guides linked below.',
          noticeIconName: 'warning',
          footnoteKo: '※ 외국인등록 기한과 예외는 「출입국관리법」 제31조 기준. 조사 04/045 '
              '§2.1, 2026-10-25 확인.',
          footnoteEn: '※ The registration deadline and its exceptions follow '
              'article 31 of the Immigration Act. Checked 2026-10-25.',
        ),
      ],
      checklistTitleKo: '도착해서 먼저 확인할 것',
      checklistTitleEn: 'Check these first',
      checklistKo: [
        '여권과 사증(비자)',
        '내 체류자격 — 유학(D-2) / 어학연수(D-4) / 교환학생(D-2-6) 중 어느 것인지',
        '예정 체류기간이 90일을 넘는지',
        '살 곳의 주소와 체류지 입증서류 — 임대차계약서, 기숙사 입사확인서 등',
        '학교 입학·재학 관련 서류',
      ],
      checklistEn: [
        'Your passport and visa',
        'Your status of stay — degree study (D-2), language training (D-4) or '
            'exchange (D-2-6)',
        'Whether your stay will exceed 90 days',
        'Your address and proof of it — a lease, a dormitory confirmation, and '
            'so on',
        'Your admission or enrolment documents',
      ],
      checklistNoteKo: '체류지 입증서류는 외국인등록 신청에 필요합니다. 살 곳을 먼저 정하면 '
          '나머지가 수월해집니다.',
      checklistNoteEn: 'Proof of your address is needed for the registration '
          'itself, so settling where you live first makes the rest easier.',
      stepsKo: [
        '살 곳과 체류지 입증서류를 확보한다. 외국인등록 신청에 필요합니다.',
        '90일을 초과해 체류할 예정이면 입국일부터 90일 이내에 외국인등록을 신청한다. '
            '외국인등록·교통카드·통신·은행 중 신청 마감이 있는 것은 이것뿐입니다. '
            '교외 임대차계약을 했다면 계약 신고기한을 따로 확인하세요.',
        '교통카드 구매, 여권으로 가능한 선불 통신, 은행 계좌 문의는 외국인등록과 같이 '
            '진행한다.',
        '외국인등록증을 받으면 은행에 거래한도 해제가 가능한지, 통신사에 체류기간·본인정보 '
            '갱신이 필요한지 확인한다.',
        '건강보험은 본인 체류자격의 적용 시점을 확인한다. D-2 와 D-4-1 이 다릅니다.',
      ],
      stepsEn: [
        'Secure where you will live and the document that proves it — the '
            'registration needs it.',
        'If your stay will exceed 90 days, apply for the alien registration '
            'within 90 days of arriving. Of the registration, transit card, '
            'phone and bank, this is the only one with a filing deadline — if '
            'you signed a lease, check its own reporting deadline.',
        'Buy a transit card, open a passport-eligible prepaid line and ask a '
            'bank about an account — all of this can run alongside.',
        'Once the residence card arrives, ask your bank whether the transaction '
            'limit can be lifted, and your carrier whether your stay period and '
            'identity details need updating.',
        'Check when health insurance applies to your own status: D-2 and D-4-1 '
            'differ.',
      ],
      sections: [
        GuideSection(
          titleKo: '체류자격에 따라 다른 것 — 건강보험',
          titleEn: 'What differs by status — health insurance',
          iconName: 'compare_arrows',
          bodyKo: '세 집단이 같은 조건이라고 가정하지 마세요. 은행·통신·교통카드는 '
              '체류자격보다 외국인등록증 보유 여부와 각 회사 기준이 중요하지만, '
              '건강보험은 체류자격 자체가 적용 시점을 가릅니다.',
          bodyEn: 'Do not assume the three groups share conditions. For banks, '
              'carriers and transit cards what matters is whether you hold the '
              'residence card and what each company requires — but for health '
              'insurance the status of stay itself decides when cover starts.',
          notes: [
            GuideNote(
              titleKo: '🎓 유학(D-2) 학위과정',
              titleEn: '🎓 Degree study (D-2)',
              linesKo: [
                '건강보험은 입국일에 지역가입자 자격을 얻는 것이 원칙입니다.',
                '외국인등록일이 입국일보다 늦으면 외국인등록일이 기준입니다.',
              ],
              linesEn: [
                'Cover as a local subscriber normally starts on the day you '
                    'arrived.',
                'If your registration date is later than your arrival date, the '
                    'registration date applies instead.',
              ],
            ),
            GuideNote(
              titleKo: '🔁 교환학생(D-2-6)',
              titleEn: '🔁 Exchange students (D-2-6)',
              linesKo: [
                'D-2 범주이므로 건강보험은 학위과정과 같은 원칙을 따릅니다.',
                '외국인등록은 자격 이름이 아니라 예정 체류기간이 90일을 넘는지로 판단합니다.',
              ],
              linesEn: [
                'This sits inside D-2, so health insurance follows the same '
                    'rule as degree study.',
                'For the registration, what matters is whether the stay exceeds '
                    '90 days — not the status name.',
              ],
            ),
            GuideNote(
              titleKo: '🗣 어학연수(D-4-1)',
              titleEn: '🗣 Language training (D-4-1)',
              linesKo: [
                '원칙적으로 국내 거주 6개월이 지난 뒤 지역가입 대상이 됩니다. D-2 와 '
                    '다릅니다.',
                '6개월을 세는 방법에는 출국기간에 관한 세부 규칙이 있습니다. 중간에 길게 '
                    '출국했다면 국민건강보험공단에 확인하세요.',
              ],
              linesEn: [
                'As a rule you become a local subscriber only after six months '
                    'of residence — unlike D-2.',
                'How those six months are counted has its own rules about time '
                    'spent outside Korea. If you left for a long period, check '
                    'with the National Health Insurance Service.',
              ],
            ),
          ],
          noticeKo: '「모든 유학생이 입국 즉시 가입된다」는 설명은 정확하지 않습니다\n'
              '본인 체류자격의 적용 시점을 건강보험 가입 가이드와 국민건강보험공단에서 '
              '확인하세요.',
          noticeEn: '"Every international student is covered on arrival" is not '
              'accurate\n'
              'Check when cover starts for your own status in the health '
              'insurance guide and with the NHIS.',
          noticeIconName: 'info',
          footnoteKo: '※ 국민건강보험공단 외국인 가입자 관리 안내와 「장기체류 재외국민 및 '
              '외국인에 대한 건강보험 적용기준」 기준. 조사 04/045 §2.4, 2026-10-25 확인. '
              '직장가입자·피부양자 요건이나 외국 보험에 따른 가입 제외는 개인별로 달라 이 '
              '가이드에서 다루지 않습니다.',
          footnoteEn: '※ Based on the National Health Insurance Service guidance '
              'for foreign subscribers, checked 2026-10-25. Workplace '
              'subscription, dependants and exemption through foreign insurance '
              'vary by person and are out of scope here.',
        ),
        GuideSection(
          titleKo: '외국인등록증을 받은 뒤',
          titleEn: 'Once the residence card arrives',
          iconName: 'badge',
          bodyKo: '카드를 받으면 먼저 개통하거나 개설해 둔 것들을 한 번 점검하세요. '
              '여기 적은 점검에는 법정 기한이 없지만 미루면 불편이 쌓입니다.',
          bodyEn: 'When the card arrives, go back over what you set up first. '
              'The checks listed here carry no statutory deadline, but putting '
              'them off piles up inconvenience.',
          notes: [
            GuideNote(
              titleKo: '🏦 은행',
              titleEn: '🏦 Bank',
              linesKo: [
                '한도제한계좌로 개설됐다면 거래목적을 보여 주는 서류를 내고 한도 해제가 '
                    '가능한지 문의하세요.',
                '한도 여부는 외국인등록증 유무만으로 정해지지 않고 거래목적 증빙과 은행 '
                    '기준으로 정해집니다.',
              ],
              linesEn: [
                'If your account was opened with transaction limits, ask what '
                    'document showing the purpose of the account would lift '
                    'them.',
                'Limits are not decided by whether you hold a residence card '
                    'alone — they follow the evidence of purpose and the bank\'s '
                    'own rules.',
              ],
            ),
            GuideNote(
              titleKo: '📱 통신사',
              titleEn: '📱 Mobile carrier',
              linesKo: [
                '여권으로 개통한 선불 회선은 사용기간이 정해져 있을 수 있습니다. 연장이나 '
                    '후불 전환 조건을 통신사에 확인하세요.',
                '외국인등록증을 받은 뒤 체류기간·본인정보 갱신이 필요한지도 함께 물어보세요.',
              ],
              linesEn: [
                'A prepaid line opened on a passport may have a fixed usable '
                    'period. Ask your carrier about extending it or moving to a '
                    'postpaid plan.',
                'Ask too whether your stay period and identity details need '
                    'updating now that you have the card.',
              ],
            ),
          ],
          footnoteKo: '※ 한도제한계좌의 1일 거래한도는 2024-05-02 시행 기준 창구 300만원, '
              'ATM 100만원, 전자금융 100만원이며 인터넷전문은행 등은 별도 한도를 둘 수 '
              '있습니다(금융위원회 안내, 2026-10-25 확인). 통신 선불상품의 사용기간은 '
              '사업자마다 달라 이 가이드에 고정 숫자를 적지 않았습니다 — 조사 04/045 '
              '§2.2·§2.3.',
          footnoteEn: '※ Under the rules in force since 2 May 2024, a '
              'limited-transaction account allows ₩3 million at a counter and '
              '₩1 million by ATM or electronic banking per day; internet-only '
              'banks may set their own (Financial Services Commission, checked '
              '2026-10-25). Prepaid validity differs by carrier, so no fixed '
              'figure is given here.',
        ),
      ],
      tipsKo: [
        '🪪 외국인등록·교통카드·통신·은행 중 신청 마감이 있는 것은 외국인등록뿐입니다 — '
            '나머지는 같이 진행하면 됩니다. 임대차계약 신고, 이사 뒤 변경신고, 건강보험은 '
            '각 가이드를 보세요.',
        // 감사 05/062 S-3: 계약서를 든 학생이 읽는 주거 팁에 임대차 신고 포인터가
        // 없었다. 값만 바꾼다(경로 추가 없음). 조건은 overview 와 같은 말로 둔다.
        '🏠 살 곳과 체류지 입증서류가 가장 먼저입니다. 외국인등록 신청에 필요합니다. '
            '교외에서 임대차계약을 했다면 금액 기준에 따라 계약일부터 30일 이내 신고 '
            '대상일 수 있습니다.',
        '🚌 교통카드는 외국인등록증이나 계좌 없이 바로 쓸 수 있습니다.',
        '🩺 건강보험 적용 시점은 D-2 와 D-4-1 이 다릅니다. 본인 자격을 확인하세요.',
        '📞 숫자와 조건이 회사·기관마다 달라, 이 가이드는 확인할 곳을 알려 줍니다.',
      ],
      tipsEn: [
        '🪪 Of the registration, transit card, phone and bank only the '
            'registration has a filing deadline — the rest can run alongside. '
            'For reporting a lease, reporting a move and health insurance, see '
            'their own guides.',
        '🏠 Somewhere to live, and proof of it, comes first: the registration '
            'needs it. If you sign a lease off campus, it may have to be '
            'reported within 30 days of signing, depending on the rent and '
            'deposit.',
        '🚌 A transit card works straight away, with no residence card or bank '
            'account.',
        '🩺 When health insurance starts differs between D-2 and D-4-1. Check '
            'your own status.',
        '📞 Figures and conditions differ by company and office, so this guide '
            'points you to where to check.',
      ],
      links: [
        GuideLink(
          labelKo: '가이드 — 외국인등록증(ARC) 발급',
          labelEn: 'Guide — Residence Card (ARC)',
          url: '/guide/item/arc-issue',
          descriptionKo: '90일 법정 신청 마감이 있는 단계. 준비물·절차·수수료',
          descriptionEn: 'The step with a 90-day deadline: documents and fee',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 교통카드',
          labelEn: 'Guide — Transit Card',
          url: '/guide/item/transit-card',
          descriptionKo: '도착 직후 바로 쓸 수 있는 것',
          descriptionEn: 'What works from the day you land',
          iconName: 'directions_transit',
        ),
        GuideLink(
          labelKo: '가이드 — 휴대폰 개통',
          labelEn: 'Guide — Getting a Mobile Plan',
          url: '/guide/item/mobile-plan',
          descriptionKo: '선불·후불과 외국인등록증 유무에 따른 차이',
          descriptionEn: 'Prepaid or postpaid, with or without the card',
          iconName: 'smartphone',
        ),
        GuideLink(
          labelKo: '가이드 — 은행 계좌 개설',
          labelEn: 'Guide — Opening a Bank Account',
          url: '/guide/item/bank-account',
          descriptionKo: '신분증과 거래목적 서류, 한도제한계좌',
          descriptionEn: 'ID, proof of purpose, and limited accounts',
          iconName: 'account_balance',
        ),
        GuideLink(
          labelKo: '가이드 — 건강보험 가입',
          labelEn: 'Guide — National Health Insurance',
          url: '/guide/item/health-insurance',
          descriptionKo: '체류자격별 적용 시점과 보험료',
          descriptionEn: 'When cover starts for your status, and the premium',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '가이드 — 체류지·등록사항 변경신고',
          labelEn: 'Guide — Reporting Address & Registration Changes',
          url: '/guide/item/address-and-registration-changes',
          descriptionKo: '등록 뒤 이사하면 15일 이내 신고',
          descriptionEn: 'After registering, a move must be reported in 15 days',
          iconName: 'edit_location_alt',
        ),
        GuideLink(
          labelKo: '가이드 — 국제교류과 방문 안내',
          labelEn: 'Guide — Visiting the OIA',
          url: '/guide/item/oia-visit',
          descriptionKo: '학교 확인이 필요하거나 판단이 어려울 때',
          descriptionEn: 'When you need the university, or are unsure',
          iconName: 'swap_horiz',
        ),
        // 조사 04/052 결함 3: overview·notice 가 임대차계약 신고기한을 언급하므로
        // 갈 곳이 있어야 한다. 배열 **끝**에 붙인다 — 번역 overlay 가 `links[N]`
        // 색인으로 붙어서, 중간에 끼우면 zh·vi 의 기존 링크 번역이 한 칸씩 밀린다.
        GuideLink(
          labelKo: '가이드 — 임대차 보증금 지키기',
          labelEn: 'Guide — Protecting Your Deposit',
          url: '/guide/item/rental-deposit-protection',
          descriptionKo: '교외 계약은 금액 기준에 따라 계약일부터 30일 이내 신고',
          descriptionEn: 'A qualifying lease must be reported within 30 days',
          iconName: 'home_work',
        ),
        // r23 D2 보강 7: 입국 「전」 단계(전자입국신고)는 visa-types 가 담당. 끝에 붙인다.
        GuideLink(
          labelKo: '가이드 — 비자 종류 안내',
          labelEn: 'Guide — Visa Types',
          url: '/guide/item/visa-types',
          descriptionKo: '입국 전 전자입국신고 대상 · 제외와 무료 공식 경로',
          descriptionEn: 'Before you land: who files the e-Arrival Card, free official route',
          iconName: 'flight_takeoff',
        ),
      ],
      durationKo: '외국인등록 90일 이내',
      durationEn: 'Registration within 90 days',
      difficulty: 1,
    ),
  ];
}
