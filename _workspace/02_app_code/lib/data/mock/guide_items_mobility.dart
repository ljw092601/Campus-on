import '../../domain/entities/admin_guide.dart';

/// r23 new guide ④ (사용자 선택, 2026-10-31): driving in Korea and shared
/// e-scooters (personal mobility devices). No existing guide covers it — the
/// 38-guide extract has 0 hits for 킥보드·이동장치 and only one 「운전면허」 (a
/// mobile licence as ID in hospital-guide) (후보 C-L1, 감사 05/079·081).
///
/// The guide keeps three things apart, because students mix them up: ① a
/// licence from home on its own, ② an International Driving Permit (IDP), and
/// ③ a Korean licence (exchanged or newly taken). E-scooters come last: they
/// need a moped licence or higher, and with an IDP only if the permit says it
/// covers them. Which IDP entries count as «covering e-scooters» is not stated
/// in any official page found, so the guide never says a given IDP does or
/// does not allow scooters — it sends the reader to the licence office.
///
/// Kept apart from the others so the addition reviews as its own diff;
/// [MockData.guideItems] is expected to append this list (registration is the
/// lead's). Every source below was read on 2026-10-31 (M 작성보고 근거표); each
/// number carries its source and date in a footnote.
abstract final class MobilityGuides {
  static const List<AdminGuideItem> items = [
    // ── 운전면허·전동킥보드 ────────────────────────────────────────────
    // 공식 원문, 2026-10-31 14:31~14:36 열람(KST):
    //  · 법제처 생활법령 「외국인유학생 > 교통·운전 > 운전」(2026-10-15 기준)
    //    https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=2853&ccfNo=3&cciNo=3&cnpClsNo=2
    //    — 「외국에서 발급받은 외국운전면허증만으로는 한국에서 운전이 불가능합니다」, 국제면허는
    //    「대한민국에 입국하기 전에 본국에서 … 미리」 발급, 「입국한 날부터 1년 동안」(제96조제1항),
    //    외국인등록을 하지 않은 사람은 응시 불가(제82조제1항제7호), 취득 연령, 취득 절차 ①~⑦.
    //  · 국가법령정보센터 도로교통법(법률 제22067호, 2026-10-13 공포, 시행 2027-04-14 판 본문 —
    //    아래 조문은 이 개정의 대상이 아니어서 현행과 같다): 제96조제1항(제네바 1949·비엔나 1968
    //    협약·상호인정, 「입국한 날부터 1년」, 「운전할 수 있는 자동차의 종류는 … 기재된 것으로
    //    한정」), 제96조제2항(사업용 차 불가·대여 차 가능), 제2조제19호의2(개인형 이동장치 정의),
    //    제50조제4항·제10항.
    //  · 도로교통공단 안전운전 통합민원 「외국면허를 국내면허로 교환」(게시일 없음, 국가 목록
    //    「2026. 4. 6. 경찰청 고시」) https://www.safedriving.or.kr/diGuide/selectDiGuide05.do?menuCd=MN-PO-1213
    //    — 구비서류, 수수료(모바일IC 15,000원 / 일반 10,000원, 학과시험 응시료 10,000원),
    //    정식 면허(full license)만, 대사관 확인서·아포스티유(한국어·영어), 90일 체류 확인,
    //    「국내면허 2종 보통에 한함」(벨기에·폴란드·스페인·이탈리아·아일랜드 예외), 인정국은
    //    적성검사만·불인정국은 학과시험 40문항(한·영·중·베), 신체검사료 7,000원(1종 대형·특수
    //    8,000원), 17:00까지 접수, 고객센터 1577-1120.
    //    인정국 팝업 selectDiGuide07Pop.do(고시일 26.04.06), 회수·미회수 팝업 selectDiGuide06Pop.do.
    //  · 도로교통공단 「국제운전면허증」 https://www.safedriving.or.kr/diGuide/selectDiGuide10.do?menuCd=MN-PO-1215
    //    — 「한국은 제네바 협약국이므로 원칙적으로 제네바 협약국에서 발급받은 유효한 국제면허증
    //    으로 … 입국일로부터 1년간」, 「2002.1.1부터 비엔나 협약국에서 발급받은 유효한
    //    국제면허증으로도」, 미국 IAA 등 유사 국제면허(INTERNATIONAL DRIVING LICENSE) 사용 불가,
    //    영문 이름 철자 불일치 시 효력 불인정, 「중국의 경우 제네바 및 비엔나 협약국에 해당하지
    //    않으나 … 홍콩 … 마카오 … 발행된 국제면허증의 효력은 … 인정」.
    //    제네바 팝업 selectDiGuide11Pop.do, 비엔나 팝업 selectDiGuide12Pop.do(베트남·몽골·
    //    우즈베키스탄 등).
    //  · 외교부 해외안전여행 「운전면허 상호인정」(2026.8월 기준) https://0404.go.kr/bbs/contsPst/MST0000000000114/14/detail
    //    — 면허 교환을 위해 외국인 등록 필요, 경찰청이 매년 조사 후 고시.
    //  · 법제처 생활법령 「자동차 운전면허 > 자동차를 운전하려면?」(2026-10-15 기준, csmSeq=668)
    //    — 제2종 보통면허로 운전할 수 있는 차량에 「⑤ 원동기장치자전거」.
    //  · 법제처 생활법령 「전동킥보드 등 운전자」(2026-10-15 기준, csmSeq=1506)
    //    cciNo=1: 원동기장치자전거면허(또는 그 이상의 자동차면허), 16세 이상, 안전모 미착용 범칙금
    //    2만원(별표 8 제38호의2), 승차정원 전동킥보드 1명·초과 범칙금 4만원(별표 8 제3호의4),
    //    야간 등화·발광장치 1만원(제57호의2). cciNo=2: 자전거도로가 있으면 자전거도로로.
    //    cciNo=3: 무면허(킥보드 기재 국제면허·상호인정면허 없이 포함) 범칙금 10만원(별표 8
    //    제1호의4), 음주 0.03% 이상 금지·범칙금 10만원, 측정 불응 13만원.
    //  · 교차(다른 기관): 정책브리핑 2021-05-11 국무조정실·국토부·행안부·교육부·경찰청 「13일부터
    //    면허 있어야 전동 킥보드 운전 가능」 — 「무면허 운전 10만 원, 안전모 미착용 2만 원, 2인 이상
    //    탑승 4만 원」(시행 2021-05-13). 금액은 생활법령 현행 기준과 같다.
    // 킥보드 금액·요건의 현행 근거는 법제처(생활법령) 한 기관이고, 경찰청 등 교차 자료는 2021년
    // 시행 당시 보도자료다(감사 05/079 R-4). 국제면허 1년·면허 교환은 법제처+도로교통공단 두 기관.
    AdminGuideItem(
      id: 'driving-and-e-scooters',
      categoryId: GuideCategory.living,
      searchAliasesKo: ['운전', '운전면허', '면허 교환', '외국 면허', '국제운전면허증', '국제면허',
        '전동킥보드', '킥보드', '공유 킥보드', '개인형 이동장치', '원동기 면허', '운전면허시험장',
        '아포스티유', '안전모', '범칙금'],
      searchAliasesEn: ['driving', 'driving licence', 'licence exchange',
        'foreign licence', 'international driving permit', 'IDP', 'e-scooter',
        'kick scooter', 'shared e-scooter', 'personal mobility device',
        'moped licence', 'driver’s licence test centre', 'apostille', 'helmet',
        'traffic fine'],
      titleKo: '운전면허·전동킥보드',
      titleEn: 'Driving and E-scooters',
      detailTitleKo: '운전면허·전동킥보드 — 본국 면허·국제면허·한국 면허와 킥보드 규칙',
      detailTitleEn: 'Driving and E-scooters — Home Licences, International '
          'Permits, Korean Licences and Scooter Rules',
      summaryKo: '본국 면허론 운전 불가·킥보드도 면허',
      // 감사 05/082 R-5: 원문 「외국운전면허증만으로는 … 운전이 불가능」 강도에 맞춤(36폭).
      summaryEn: 'Home licence won\'t do · scooters too',
      iconName: 'badge',
      overviewKo: '한국에서 차나 전동킥보드를 몰려면 한국 법이 인정하는 면허가 있어야 합니다. '
          '본국에서 받은 운전면허증만으로는 한국에서 운전할 수 없습니다.\n\n'
          '쓸 수 있는 길은 세 가지입니다. ① 입국 전에 받아 온 국제운전면허증으로 입국일부터 '
          '1년 동안 운전하기, ② 본국 면허를 한국 면허로 교환하기, ③ 한국에서 면허시험을 봐서 '
          '새로 받기. 길거리 공유 전동킥보드도 원동기장치자전거 면허 이상이 있거나, 전동킥보드 '
          '등을 운전할 수 있다고 기재된 국제운전면허증 등이 있어야 탈 수 있습니다(아래 「어떤 '
          '면허가 있어야 하나요」).\n\n'
          '면허 교환 때 시험을 얼마나 면제받는지, 국제면허가 인정되는지는 면허를 받은 나라에 '
          '따라 다릅니다. 국가 목록과 금액은 바뀔 수 있어 출처와 기준 시점을 함께 적었습니다.',
      overviewEn: 'To drive a car or ride an e-scooter in Korea you need a '
          'licence that Korean law recognises. A licence from your home '
          'country is not enough on its own.\n\n'
          'There are three ways: ① drive for one year from your entry date on '
          'an International Driving Permit you got before coming, ② exchange '
          'your home licence for a Korean one, or ③ take the Korean driving '
          'test. Shared e-scooters on the street also need a moped licence or '
          'higher, or an International Driving Permit or similar stated as '
          'covering e-scooters (see «Which licence do I need?» below).\n\n'
          'How much of the test you skip when exchanging, and whether your '
          'permit is accepted, depend on the country that issued your licence. '
          'Country lists and fees can change, so each comes with its source '
          'and date.',
      topSections: [
        GuideSection(
          titleKo: '내 면허로 무엇을 할 수 있나요?',
          titleEn: 'What can I do with the licence I have?',
          iconName: 'compare_arrows',
          notes: [
            GuideNote(
              titleKo: '본국 운전면허증만 있다',
              titleEn: 'I only have my home-country licence',
              linesKo: [
                '그 면허증만으로는 한국에서 운전할 수 없습니다. 차도 전동킥보드도 마찬가지입니다.',
                '외국인등록을 마쳤다면 운전면허시험장에서 한국 면허로 교환을 신청할 수 있습니다. '
                    '아래 「준비물」과 「진행 순서」를 보세요.',
              ],
              linesEn: [
                'That licence alone does not let you drive in Korea — neither a '
                    'car nor an e-scooter.',
                'Once you have registered as a foreign resident, you can apply at '
                    'a driver’s licence test centre to exchange it for a Korean '
                    'licence. See «What to prepare» and the steps below.',
              ],
            ),
            GuideNote(
              titleKo: '국제운전면허증을 가지고 왔다',
              titleEn: 'I brought an International Driving Permit',
              linesKo: [
                '국제운전면허증은 본국에서 입국 전에 받아 와야 합니다. 한국은 제네바 협약(1949) '
                    '가입국이고, 비엔나 협약(1968) 나라에서 받은 국제면허증도 인정합니다.',
                '운전할 수 있는 기간은 입국한 날부터 1년입니다. 국제면허증 자체의 유효기간도 남아 '
                    '있어야 합니다.',
                '운전할 수 있는 차는 그 국제면허증에 적힌 종류로 한정됩니다. 사업용 차는 운전할 수 '
                    '없지만, 렌터카를 빌려 운전하는 것은 됩니다.',
                '1년 넘게 머물며 계속 운전하려면 한국 면허로 교환하거나 새로 받아야 합니다.',
              ],
              linesEn: [
                'You have to get the permit in your home country before you '
                    'come. Korea is a party to the 1949 Geneva Convention and also '
                    'accepts permits from 1968 Vienna Convention countries.',
                'You may drive on it for one year from the day you entered '
                    'Korea, and the permit itself must still be valid.',
                'You may drive only the vehicle types written on the permit. '
                    'Commercial vehicles are not allowed, but renting a car and '
                    'driving it is.',
                'To keep driving after a year, exchange your licence for a '
                    'Korean one or take the Korean test.',
              ],
            ),
            GuideNote(
              titleKo: '한국 면허를 새로 받고 싶다',
              titleEn: 'I want a Korean licence from scratch',
              linesKo: [
                '외국인등록을 하지 않은 사람은 운전면허시험에 응시할 수 없습니다. 외국인등록증부터 '
                    '받으세요.',
                '나이 기준: 제1종·제2종 보통면허 18세 이상, 원동기장치자전거 면허 16세 이상.',
              ],
              linesEn: [
                'You cannot sit the driving test until you have registered as a '
                    'foreign resident, so get your residence card first.',
                'Minimum age: 18 for a class 1 or class 2 ordinary licence, 16 '
                    'for a moped licence.',
              ],
            ),
          ],
          footnoteKo: '※ 법제처 생활법령 「외국인유학생 > 운전」(2026-10-15 기준), 도로교통법 '
              '제96조, 도로교통공단 「국제운전면허증」 안내 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on the Ministry of Government Legislation easy-law '
              'page for international students (as of 2026-10-15), Article 96 '
              'of the Road Traffic Act and the Road Traffic Authority page on '
              'International Driving Permits, checked 2026-10-31.',
        ),
      ],
      checklistTitleKo: '본국 면허를 한국 면허로 바꿀 때 준비물',
      checklistTitleEn: 'To exchange your home licence for a Korean one',
      checklistKo: [
        '본국 운전면허증 원본 (유효기간이 남은 정식 면허 — 임시·연습 면허는 교환 불가)',
        '여권 원본 (출국부터 입국까지 출입 기록을 확인할 수 있는 여권)',
        '외국인등록증 원본',
        '6개월 안에 찍은 컬러 사진 3장 (3.5×4.5cm)',
        '면허증에 대한 대사관 확인서 또는 아포스티유 인증서 (한국어 또는 영어)',
        '출입국사실증명서 (출생 연도부터 현재까지)',
        '발급 수수료 — 일반 10,000원 / 모바일IC 15,000원',
      ],
      checklistEn: [
        'Your home-country licence, original (a full licence that has not '
            'expired — temporary or learner licences cannot be exchanged)',
        'Your passport, original (one that shows your departures and entries)',
        'Your residence card, original',
        'Three colour photos taken within 6 months (3.5×4.5 cm)',
        'An embassy confirmation or apostille certificate for the licence (in '
            'Korean or English)',
        'A certificate of entry and exit records (from your birth year to '
            'today)',
        'Issuing fee — standard ₩10,000 / mobile IC ₩15,000',
      ],
      checklistOptionalTitleKo: '나라에 따라 더 필요해요',
      checklistOptionalTitleEn: 'Depending on your country',
      checklistOptionalKo: [
        '학과시험 응시료 10,000원 — 한국 면허를 인정하지 않는 나라의 면허일 때',
        '신체검사료 7,000원 — 시험장 신체검사실에서 적성검사를 받을 때',
        '면허증과 여권의 이름·생년월일이 다르면 같은 사람임을 증명하는 대사관 확인서 등',
      ],
      checklistOptionalEn: [
        'Written test fee ₩10,000 — if your licence is from a country that '
            'does not recognise Korean licences',
        'Medical check fee ₩7,000 — if you take the aptitude test at the test '
            'centre’s medical room',
        'If the name or date of birth differs between licence and passport, an '
            'embassy confirmation or other document proving it is you',
      ],
      checklistNoteKo: '도로교통공단은 대사관 확인서·아포스티유에 대해 「신청일로부터 1년 이내 '
          '발급한 운전면허에 대한 대사관 확인서 또는 아포스티유 인증서」라고 적고, 면허 발급국에서 '
          '90일 이상 체류한 사실이 확인되지 않으면 교환할 수 없다고 안내합니다. 내 서류가 맞는지는 '
          '방문 전에 운전면허시험장이나 도로교통공단 고객센터(1577-1120)에 확인하세요. '
          '(도로교통공단 「외국면허를 국내면허로 교환」, 2026-10-31 확인)',
      checklistNoteEn: 'The Road Traffic Authority words the embassy '
          'confirmation or apostille requirement as one «for a licence issued '
          'within 1 year of the application date», and says the exchange is '
          'refused if a stay of 90 days or more in the issuing country cannot be '
          'confirmed. Check your documents with the test centre or the '
          'Authority’s call centre (1577-1120) before you go. (Road Traffic '
          'Authority licence exchange page, checked 2026-10-31)',
      stepsKo: [
        '내 경우를 고른다. '
            '국제운전면허증으로 입국 후 1년 안만 운전할지, 본국 면허를 교환할지, 한국에서 새로 '
            '받을지 정합니다. 1년 넘게 운전할 생각이면 교환이나 새 면허가 필요합니다.',
        '국제운전면허증이라면 세 가지를 확인한다. '
            '제네바·비엔나 협약 나라의 정식 발급기관이 준 「International Driving Permit」인지, '
            '입국일부터 1년이 지나지 않았는지, 몰려는 차종이 면허증에 적혀 있는지 봅니다. '
            '영문 이름 철자가 여권과 다르면 효력을 인정받지 못합니다. 국제면허증과 본국 면허증·'
            '여권을 함께 가지고 다니세요.',
        '교환이라면 내 나라가 「한국 면허 인정 국가」인지 확인한다. '
            '도로교통공단의 「국내면허 인정 국가 보기」(경찰청 고시) 목록에 있으면 적성검사(신체검사)만, '
            '없으면 적성검사와 학과시험(객관식 40문항)을 봅니다. 미국·캐나다·인도처럼 주 단위로 '
            '정해진 나라도 있습니다.',
        '서류를 갖춰 운전면허시험장을 방문한다. '
            '본인이 직접 가야 하고 대리 접수는 안 됩니다. 부산에는 부산남부·부산북부 운전면허시험장이 '
            '있습니다. 교환은 시간이 오래 걸려 17:00까지 접수해야 하고, 학과시험을 봐야 하면 16:00 '
            '전에 가는 것이 좋습니다.',
        '서류 심사 → 적성검사(·학과시험) → 한국 면허 발급. '
            '교환으로 받는 면허는 원칙적으로 제2종 보통면허입니다(벨기에·폴란드·스페인·이탈리아·'
            '아일랜드 면허는 해당 종류로 교환 가능). 학과시험은 한국어·영어·중국어·베트남어 중에서 '
            '고릅니다. 서류가 부족하면 추가 제출을 요구받을 수 있습니다.',
        '한국 면허를 새로 받는다면 시험 순서를 따른다. '
            '외국인등록 후 교통안전교육 → 신체검사 → 학과시험 → 기능시험 순서이고, 제1종·제2종 '
            '보통면허는 이어서 연습면허를 받은 뒤 도로주행시험에 합격해야 발급됩니다. 그 밖의 면허'
            '(원동기장치자전거 면허 등)는 학과·기능시험에 합격하면 발급됩니다. 운전면허시험장에서 '
            '직접 보거나 자동차운전 전문학원을 통해 볼 수 있습니다.',
        '전동킥보드는 면허를 확인하고 탄다. '
            '원동기장치자전거 면허 이상(교환으로 받은 제2종 보통면허 포함)이 있거나, 국제운전면허증 '
            '등에 전동킥보드를 운전할 수 있다고 기재되어 있어야 합니다(아래 「어떤 면허가 있어야 '
            '하나요」). 안전모, '
            '혼자 타기, 음주 금지 등은 아래 「전동킥보드(개인형 이동장치) 규칙」을 보세요.',
      ],
      stepsEn: [
        'Pick your route. '
            'Decide whether you will drive on an International Driving Permit '
            'within one year of entry, exchange your home licence, or take the '
            'Korean test. If you will drive for longer than a year, you need an '
            'exchanged or new Korean licence.',
        'With an International Driving Permit, check three things. '
            'It must be an «International Driving Permit» from an official '
            'issuer in a Geneva or Vienna Convention country; one year from '
            'your entry date must not have passed; and the vehicle type you '
            'want to drive must be written on it. If the English spelling of '
            'your name differs from your passport, it is not accepted. Carry '
            'the permit together with your home licence and passport.',
        'For an exchange, check whether your country recognises Korean '
            'licences. '
            'If it is on the Road Traffic Authority’s list of countries that '
            'recognise Korean licences (a National Police Agency notice), you '
            'take only the aptitude (medical) test; if not, you also take a '
            'written test (40 multiple-choice questions). Some countries, such '
            'as the US, Canada and India, are listed state by state.',
        'Visit a driver’s licence test centre with your documents. '
            'You must go in person; nobody can apply for you. Busan has the '
            'Busan South and Busan North test centres. Exchanges take time, so '
            'apply by 17:00, and before 16:00 if you need the written test.',
        'Document check → aptitude test (and written test) → Korean licence. '
            'An exchange normally gives you a class 2 ordinary licence '
            '(licences from Belgium, Poland, Spain, Italy and Ireland can be '
            'exchanged for the matching class). The written test is in Korean, '
            'English, Chinese or Vietnamese. You may be asked for more '
            'documents if something is missing.',
        'For a new Korean licence, follow the test order. '
            'After registering as a foreign resident: traffic safety course → '
            'medical check → written test → skills test. For a class 1 or 2 '
            'ordinary licence you then get a learner’s licence and must pass '
            'the road test; other licences (such as a moped licence) are issued '
            'after the written and skills tests. You can take the tests at a '
            'test centre or through a registered driving school.',
        'Before riding an e-scooter, check your licence. '
            'You need a moped licence or higher (an exchanged class 2 ordinary '
            'licence counts), or an International Driving Permit or recognised '
            'foreign licence stated as covering e-scooters (see «Which licence '
            'do I need?» below). For helmets, riding alone and the drink-riding '
            'ban, see «E-scooter (personal mobility device) rules» below.',
      ],
      sections: [
        GuideSection(
          titleKo: '전동킥보드(개인형 이동장치) 규칙',
          titleEn: 'E-scooter (personal mobility device) rules',
          iconName: 'warning',
          bodyKo: '전동킥보드 같은 개인형 이동장치는 법에서 원동기장치자전거의 한 종류입니다. '
              '공유 킥보드 앱에서 빌릴 수 있는지와 관계없이, 타는 사람이 면허 요건을 갖춰야 '
              '합니다.',
          bodyEn: 'Under Korean law an e-scooter is a personal mobility device, a '
              'kind of moped. Whether or not a sharing app lets you rent one, the '
              'rider has to meet the licence rule.',
          notes: [
            GuideNote(
              titleKo: '어떤 면허가 있어야 하나요',
              titleEn: 'Which licence do I need?',
              linesKo: [
                '원동기장치자전거 면허 또는 그 이상의 자동차 면허(제2종 보통면허 등). 원동기장치'
                    '자전거 면허는 16세 이상이어야 받을 수 있습니다.',
                '국제운전면허증이나 상호인정외국면허증으로 타려면, 그 면허증이 「전동킥보드 등을 '
                    '운전할 수 있는 것으로 기재된」 것이어야 합니다. 어떤 표기가 여기에 해당하는지 '
                    '설명한 공식 안내는 찾지 못했습니다. 내 면허증으로 탈 수 있는지는 운전면허시험장이나 '
                    '도로교통공단(1577-1120)에 면허증을 보여 주고 확인하세요.',
              ],
              linesEn: [
                'A moped licence, or a higher motor-vehicle licence (such as a '
                    'class 2 ordinary licence). You must be 16 or older to get a '
                    'moped licence.',
                'To ride on an International Driving Permit or a recognised '
                    'foreign licence, it must be one «stated as covering '
                    'e-scooters and similar devices». We found no official '
                    'explanation of which entries count. Show your permit at a test '
                    'centre or ask the Road Traffic Authority (1577-1120) whether '
                    'it covers you.',
              ],
            ),
            GuideNote(
              titleKo: '탈 때 지킬 것과 범칙금',
              titleEn: 'Rules when riding, and fines',
              linesKo: [
                '면허 없이 탐(킥보드가 기재된 국제면허 등이 없는 경우 포함) — 범칙금 10만원',
                '안전모를 쓰지 않음 — 범칙금 2만원',
                '전동킥보드 승차정원은 1명 — 둘이 타면 범칙금 4만원',
                '술에 취한 상태(혈중알코올농도 0.03% 이상)로 탐 — 범칙금 10만원, 음주측정 거부 — '
                    '13만원',
                '밤에 등을 켜지 않거나 야광띠 등 발광장치를 착용하지 않음 — 범칙금 1만원',
                '자전거도로가 따로 있는 곳에서는 자전거도로로 다닙니다.',
              ],
              linesEn: [
                'Riding without a licence (including without a permit that covers '
                    'e-scooters) — ₩100,000 fine',
                'Riding without a helmet — ₩20,000 fine',
                'An e-scooter carries one person — riding two-up is a ₩40,000 '
                    'fine',
                'Riding drunk (blood alcohol 0.03% or more) — ₩100,000 fine; '
                    'refusing a breath test — ₩130,000',
                'At night, no lights on or no reflective or light-emitting gear — '
                    '₩10,000 fine',
                'Where there is a separate bicycle path, use it.',
              ],
            ),
          ],
          footnoteKo: '※ 법제처 생활법령 「전동킥보드 등 운전자」(2026-10-15 기준, 도로교통법 '
              '시행령 별표 8 인용) 기준, 2026-10-31 확인. 무면허 10만원·안전모 2만원·2인 탑승 '
              '4만원은 경찰청 등 관계부처의 2021-05-11 보도자료(2021-05-13 시행)와도 같습니다. '
              '금액은 법령 개정으로 바뀔 수 있습니다.',
          footnoteEn: '※ Based on the Ministry of Government Legislation easy-law '
              'pages for e-scooter riders (as of 2026-10-15, citing Annex 8 of '
              'the Road Traffic Act Enforcement Decree), checked 2026-10-31. The '
              '₩100,000, ₩20,000 and ₩40,000 fines match the 2021-05-11 press '
              'release by the National Police Agency and other ministries (in '
              'force from 2021-05-13). Amounts can change when the law is '
              'amended.',
        ),
        GuideSection(
          titleKo: '나라마다 다른 점 확인하기',
          titleEn: 'Checking what applies to your country',
          iconName: 'fact_check',
          notes: [
            GuideNote(
              titleKo: '국제운전면허증이 인정되는 나라',
              titleEn: 'Countries whose permits are accepted',
              linesKo: [
                '도로교통공단의 「제네바 협약국 보기」·「비엔나 협약국 보기」 목록으로 확인합니다. '
                    '예를 들어 베트남·몽골·우즈베키스탄은 비엔나 협약국 목록에 있습니다.',
                '도로교통공단은 중국이 제네바·비엔나 협약국에 해당하지 않으며, 홍콩·마카오에서 '
                    '발행한 국제면허증은 효력이 인정된다고 안내합니다.',
                '미국 IAA 등 정식 발급기관이 아닌 곳에서 받은 「INTERNATIONAL DRIVING LICENSE」 같은 '
                    '유사 국제면허는 쓸 수 없습니다.',
              ],
              linesEn: [
                'Check the Road Traffic Authority’s Geneva Convention and Vienna '
                    'Convention country lists. Vietnam, Mongolia and Uzbekistan, '
                    'for example, are on the Vienna list.',
                'The Authority says China is not a party to either convention, '
                    'while permits issued in Hong Kong and Macau are accepted.',
                'Look-alike documents such as an «INTERNATIONAL DRIVING LICENSE» '
                    'from an unofficial issuer (the Authority names the US IAA) '
                    'cannot be used.',
              ],
            ),
            GuideNote(
              titleKo: '면허 교환 때 시험이 면제되는 나라',
              titleEn: 'Countries whose licences skip the written test',
              linesKo: [
                '「국내면허 인정 국가」는 경찰청 고시로 정합니다(현재 목록 2026-04-06 고시). 예를 들어 '
                    '베트남·우즈베키스탄·일본은 목록에 있고, 중국·몽골은 목록에 없습니다.',
                '미국 오리건·아이다호·유타·네바다주는 인정 지역이어도 학과시험을 봅니다.',
                '교환할 때 본국 면허증을 돌려받는지는 나라마다 다릅니다. 도로교통공단의 「외국면허 '
                    '회수 국가·미회수 국가 보기」에서 확인하세요.',
                '목록에서 내 나라를 찾기 어렵거나 주·지역 단위로 나뉘어 있으면, 방문 전에 '
                    '운전면허시험장이나 도로교통공단(1577-1120)에 물어보세요.',
              ],
              linesEn: [
                'The list of countries that recognise Korean licences is set by '
                    'a National Police Agency notice (current list: notice of '
                    '2026-04-06). Vietnam, Uzbekistan and Japan, for example, are '
                    'on it; China and Mongolia are not.',
                'Oregon, Idaho, Utah and Nevada (US) are listed but still take '
                    'the written test.',
                'Whether you get your home licence back after the exchange '
                    'depends on the country — see the Authority’s list of '
                    'countries whose licences are kept or returned.',
                'If you cannot find your country, or it is listed by state or '
                    'region, ask a test centre or the Road Traffic Authority '
                    '(1577-1120) before you go.',
              ],
            ),
          ],
          footnoteKo: '※ 도로교통공단 「외국면허를 국내면허로 교환」의 국내면허 인정 국가 '
              '목록(2026-04-06 경찰청 고시)과 「국제운전면허증」의 협약국 목록 기준, 2026-10-31 '
              '확인. 목록은 고시 개정으로 바뀔 수 있습니다.',
          footnoteEn: '※ Based on the Road Traffic Authority’s list of countries '
              'recognising Korean licences (National Police Agency notice of '
              '2026-04-06) and its convention country lists, checked 2026-10-31. '
              'The lists can change when the notice is revised.',
        ),
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
            GuideNote(
              titleKo: '사고가 났다면',
              titleEn: 'If there is an accident',
              linesKo: [
                '다친 사람이 있으면 119, 경찰의 도움이 필요하면 112에 먼저 연락하세요. 연락할 곳은 '
                    '「사건·사고 대응」 가이드에 정리돼 있습니다.',
              ],
              linesEn: [
                'If anyone is hurt call 119, and 112 if you need the police. The '
                    '«Incident Response» guide lists who to contact.',
              ],
            ),
            GuideNote(
              titleKo: '면허 없이 다니려면',
              titleEn: 'Getting around without a licence',
              linesKo: [
                '버스·지하철은 「교통카드」 가이드를 보세요.',
              ],
              linesEn: [
                'For buses and the subway, see the «Transit Card» guide.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '🪪 국제운전면허증으로 운전할 때는 본국 면허증과 여권을 함께 가지고 다니세요.',
        '📅 입국일부터 1년이 지나면 국제면허증의 유효기간이 남아 있어도 운전할 수 없습니다.',
        '🛴 공유 킥보드도 안전모를 써야 합니다. 둘이 같이 타면 안 됩니다.',
      ],
      tipsEn: [
        '🪪 When driving on an International Driving Permit, carry your home '
            'licence and passport too.',
        '📅 One year after your entry date you can no longer drive on the '
            'permit, even if it has not expired.',
        '🛴 Shared e-scooters need a helmet too, and only one rider at a time.',
      ],
      phrases: [
        GuidePhrase(
          ko: '외국 운전면허증을 한국 면허로 교환하고 싶습니다. 필요한 서류를 확인해 주세요.',
          en: 'I would like to exchange my foreign driving licence for a Korean '
              'one. Could you check the documents I need?',
        ),
        GuidePhrase(
          ko: '이 국제운전면허증으로 전동킥보드를 탈 수 있나요?',
          en: 'Can I ride an e-scooter with this International Driving Permit?',
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '도로교통공단 — 외국면허를 국내면허로 교환',
          labelEn: 'Road Traffic Authority — exchanging a foreign licence',
          descriptionKo: '준비 서류·수수료, 국내면허 인정 국가와 회수 국가 목록',
          descriptionEn: 'Documents, fees, and the lists of recognising and '
              'licence-keeping countries (Korean)',
          url: 'https://www.safedriving.or.kr/diGuide/selectDiGuide05.do?menuCd=MN-PO-1213',
          iconName: 'swap_horiz',
        ),
        GuideLink(
          labelKo: '도로교통공단 — 국제운전면허증',
          labelEn: 'Road Traffic Authority — International Driving Permits',
          descriptionKo: '한국에서 인정되는 국제면허, 제네바·비엔나 협약국 목록',
          descriptionEn: 'Which permits are valid in Korea; Geneva and Vienna '
              'country lists (Korean)',
          url: 'https://www.safedriving.or.kr/diGuide/selectDiGuide10.do?menuCd=MN-PO-1215',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '생활법령 — 외국인유학생 운전',
          labelEn: 'Easy law — driving for international students',
          descriptionKo: '응시 자격·취득 절차·면허 교환·국제면허 1년',
          descriptionEn: 'Eligibility, test steps, exchange and the one-year '
              'permit rule (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=2853&ccfNo=3&cciNo=3&cnpClsNo=2',
          iconName: 'gavel',
        ),
        GuideLink(
          labelKo: '생활법령 — 전동킥보드 주행 전 준비',
          labelEn: 'Easy law — before riding an e-scooter',
          descriptionKo: '면허·안전모·승차정원과 범칙금',
          descriptionEn: 'Licence, helmet, rider limit and fines (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=1506&ccfNo=2&cciNo=1&cnpClsNo=1',
          iconName: 'gavel',
        ),
        GuideLink(
          labelKo: '생활법령 — 전동킥보드 금지 행위',
          labelEn: 'Easy law — what e-scooter riders must not do',
          descriptionKo: '무면허·음주·약물 운전과 범칙금',
          descriptionEn: 'Riding without a licence, drunk or drugged, and '
              'fines (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=1506&ccfNo=2&cciNo=3&cnpClsNo=2',
          iconName: 'gavel',
        ),
        GuideLink(
          labelKo: '도로교통공단 고객센터 1577-1120',
          labelEn: 'Road Traffic Authority call centre 1577-1120',
          descriptionKo: '면허 교환·국제면허 문의 · 외국어 채팅은 카카오톡 「한국도로교통공단 고객센터」',
          descriptionEn: 'Licence exchange and permit questions · foreign-language '
              'chat on the KakaoTalk channel of the Authority’s call centre',
          url: 'tel:15771120',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '가이드 — 외국인등록증(ARC) 발급',
          labelEn: 'Guide — Residence Card (ARC)',
          descriptionKo: '면허 교환·시험 응시 전에 필요',
          descriptionEn: 'Needed before an exchange or the test',
          url: '/guide/item/arc-issue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 사건·사고 대응',
          labelEn: 'Guide — Incident Response',
          descriptionKo: '사고가 나면 연락할 곳',
          descriptionEn: 'Who to contact after an accident',
          url: '/guide/item/incident-response',
          iconName: 'emergency',
        ),
        GuideLink(
          labelKo: '가이드 — 교통카드',
          labelEn: 'Guide — Transit Card',
          descriptionKo: '버스·지하철 이용',
          descriptionEn: 'Buses and the subway',
          url: '/guide/item/transit-card',
          iconName: 'directions_transit',
        ),
      ],
    ),
  ];
}
