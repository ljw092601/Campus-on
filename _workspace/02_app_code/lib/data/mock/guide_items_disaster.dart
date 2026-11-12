import '../../domain/entities/admin_guide.dart';

/// r23 candidate: hazard-specific evacuation and advance preparation.
/// Written by 조사 코덱스; registration in MockData is the lead's responsibility.
/// Official pages were read on 2026-10-31 (KST); see report 04/076.
/// Busan page totals and dates conflict, so no site count, nearest campus
/// shelter, opening status or accessible route is asserted here.
/// App installation, alert settings and emergency reporting remain in
/// emergency-contacts. This candidate is not a final integration approval.
abstract final class DisasterGuides {
  static const List<AdminGuideItem> items = [
    AdminGuideItem(
      id: 'disaster-preparedness',
      categoryId: GuideCategory.emergency,
      searchAliasesKo: [
        '재난',
        '대피',
        '대피소',
        '지진',
        '태풍',
        '호우',
        '침수',
        '지진해일',
        '쓰나미',
        '민방위 대피소',
        '비상용품',
        '비상가방',
      ],
      searchAliasesEn: [
        'disaster',
        'evacuation',
        'shelter',
        'earthquake',
        'typhoon',
        'heavy rain',
        'flooding',
        'tsunami evacuation',
        'tsunami',
        'civil defence shelter',
        'emergency supplies',
        'emergency bag',
      ],
      titleKo: '재난별 대피와 사전 준비',
      titleEn: 'Disaster Preparedness',
      detailTitleKo: '재난별 대피 장소와 사전 준비',
      detailTitleEn: 'Disaster Preparedness — Where to Go and What to Prepare',
      summaryKo: '재난에 맞는 대피 장소 먼저',
      summaryEn: 'Match the shelter to the hazard',
      iconName: 'warning',
      overviewKo:
          '지진·호우·태풍·지진해일은 대피 행동과 장소가 다릅니다. '
          '이 가이드는 평소 준비와 장소 확인 방법을 안내하며, 실시간 대피 명령이나 학교별 집결지를 대신하지 않습니다.\n\n'
          '재난문자 앱 설치·알림 설정과 긴급 신고 방법은 아래 「긴급 연락처」 가이드에서 확인하세요.',
      overviewEn:
          'Earthquakes, heavy rain, typhoons and tsunamis call for different actions and destinations. '
          'This guide covers preparation and finding locations; it does not replace live evacuation instructions or campus plans.\n\n'
          'For the disaster-alert app, notification settings and emergency reporting, use the Emergency Contacts guide below.',
      checklistTitleKo: '평소 준비해 둘 것',
      checklistTitleEn: 'Prepare before an emergency',
      checklistKo: [
        '집·학교의 현재 주소와 건물 출구',
        '가족·친구의 연락처와 연락이 끊겼을 때 만날 곳',
        '물·간편식·손전등·휴대용 라디오·건전지·개인 상비약을 담은 휴대 가능한 가방',
        '이동에 도움이 필요하다면 함께 도울 사람과 건물의 대피 방법',
      ],
      checklistEn: [
        'Your home and campus addresses, and the building exits',
        'Family or friends to contact, and a meeting point if communication fails',
        'A bag you can carry with water, ready-to-eat food, a torch, a portable radio, batteries and personal medicines',
        'If you need help moving, someone who can assist and the evacuation arrangements for your building',
      ],
      checklistNoteKo: '가방은 꺼내기 쉬운 곳에 두고 식품·약의 유효기간을 확인하세요. 학교·기숙사의 이동 지원 방법은 평소 담당자에게 확인하세요.',
      checklistNoteEn: 'Keep the bag within easy reach and check food and medicine expiry dates. Ask your campus or dormitory staff in advance about mobility assistance.',
      stepsKo: [
        '현재 생활하는 지역에서 어떤 재난의 장소를 확인할지 구분합니다. 지진 옥외대피장소와 지진해일 긴급대피장소는 같은 목록이 아닙니다.',
        '아래 부산시 공식 안내에서 지역과 장소 이름을 확인하고, 재난이 닥치기 전에 이동 경로를 알아 둡니다.',
        '연락 방법·만날 곳·비상가방을 준비합니다. 실제 상황에서는 해당 재난의 행동요령과 현장 안내를 따릅니다.',
      ],
      stepsEn: [
        'Identify which hazard you are planning for where you live or study. Earthquake outdoor assembly sites and tsunami evacuation sites are separate lists.',
        'Use the Busan pages below to check the district and site names, and find a route before an emergency.',
        'Prepare contacts, a meeting point and an emergency bag. In an actual event, follow the guidance for that hazard and instructions on site.',
      ],
      topSections: [
        GuideSection(
          titleKo: '대피소 이름보다 재난 종류를 먼저',
          titleEn: 'Match the destination to the hazard',
          iconName: 'warning',
          noticeKo:
              '모든 대피소가 모든 재난에 안전한 것은 아닙니다\n'
              '지진의 옥외대피장소, 지진해일의 높은 대피 장소, 민방위 대피시설을 구별하세요. '
              '호우·태풍 때 침수 우려가 있는 지하 장소로 대피하지 마세요.',
          noticeEn:
              'A shelter is not safe for every kind of emergency\n'
              'Distinguish earthquake outdoor assembly sites, high-ground tsunami sites and civil defence shelters. '
              'Do not shelter in a flood-prone underground space during heavy rain or a typhoon.',
          links: [
            GuideLink(
              labelKo: '가이드 — 긴급 연락처',
              labelEn: 'Guide — Emergency Contacts',
              url: '/guide/item/emergency-contacts',
              descriptionKo: '재난 앱·알림 설정과 긴급 신고 방법',
              descriptionEn: 'Disaster-alert app settings and emergency reporting',
              iconName: 'call',
            ),
          ],
        ),
      ],
      sections: [
        GuideSection(
          titleKo: '지진 — 흔들릴 때와 멈춘 뒤를 구별',
          titleEn: 'Earthquake — during and after shaking',
          iconName: 'warning',
          stepsKo: [
            '실내에서 흔들리면 튼튼한 탁자 아래에서 몸을 보호하고 탁자 다리를 잡습니다.',
            '흔들림이 멈춘 뒤 밖으로 이동할 때는 계단을 이용합니다. 엘리베이터는 타지 않습니다.',
            '밖에서는 머리를 보호하며 건물에서 떨어져 운동장·공원 같은 넓은 곳으로 걸어서 이동합니다.',
          ],
          stepsEn: [
            'During indoor shaking, take cover under a sturdy table and hold its legs.',
            'After shaking stops, use the stairs if leaving the building. Do not use a lift.',
            'Outside, protect your head, keep clear of buildings and walk to an open area such as a playground or park.',
          ],
          footnoteKo: '※ 행정안전부 국민안전24 「지진」 행동요령. 페이지 갱신일은 미표시이며 2026-10-31 확인. 해안에서의 지진해일 위험은 다음 지진해일 절도 확인하세요.',
          footnoteEn: '※ Ministry of the Interior and Safety (MOIS), Safety24 earthquake guidance; no page revision date shown, checked 2026-10-31. At the coast, also see the tsunami section.',
        ),
        GuideSection(
          titleKo: '호우·태풍 — 침수 전에 안전한 곳으로',
          titleEn: 'Heavy rain and typhoon — leave flood risk early',
          iconName: 'warning',
          stepsKo: [
            '예보를 확인하고 저지대·지하 공간·산사태 위험 지역에서는 미리 안전한 곳으로 이동합니다.',
            '안전한 실내에서는 창문을 닫고 외출을 줄입니다. 다만 건물에 물이 들어오기 시작하면 머물지 말고 높은 곳이나 안전한 대피 장소로 즉시 이동합니다.',
            '하천·해안에 접근하지 말고, 물에 잠긴 도로·지하차도는 걷거나 차로 통과하지 않습니다.',
          ],
          stepsEn: [
            'Check forecasts and leave low-lying, underground or landslide-prone areas for safety before conditions worsen.',
            'In a safe indoor location, close windows and avoid going out. But if water starts entering the building, leave immediately for higher ground or a safe evacuation site.',
            'Keep away from rivers and the coast. Never cross a flooded road or underpass on foot or by vehicle.',
          ],
          footnoteKo: '※ 행정안전부 국민안전24 「호우」·「태풍」 행동요령. 두 페이지의 갱신일은 미표시이며 2026-10-31 확인.',
          footnoteEn: '※ MOIS Safety24 heavy-rain and typhoon guidance; no page revision dates shown, checked 2026-10-31.',
        ),
        GuideSection(
          titleKo: '지진해일 — 해안에서 높은 곳으로',
          titleEn: 'Tsunami — leave the coast for higher ground',
          iconName: 'warning',
          stepsKo: [
            '해안에서 지진을 느끼거나 지진해일 경보를 받으면 해안·하천에서 벗어나 높은 곳이나 지정된 지진해일 대피 장소로 신속히 이동합니다.',
            '파도가 여러 차례 올 수 있으므로 지진해일 특보가 해제될 때까지 높은 곳에 머뭅니다.',
          ],
          stepsEn: [
            'If you feel an earthquake at the coast or receive a tsunami warning, promptly leave the coast and rivers for higher ground or a designated tsunami evacuation site.',
            'Waves can arrive repeatedly. Stay on high ground until the tsunami advisory or warning is lifted.',
          ],
          footnoteKo: '※ 행정안전부 「지진! 미리 대비하고 알아두세요」(2021-08-27 게시)의 지진해일 행동요령과 국민안전24 지진 안내, 2026-10-31 확인. 과거 캠페인 일정이 아닌 기본 행동만 참고했습니다.',
          footnoteEn: '※ MOIS, “Prepare for earthquakes” (published 2021-08-27), tsunami guidance, and the Safety24 earthquake page; checked 2026-10-31. Only the safety guidance is used, not the old campaign schedule.',
        ),
        GuideSection(
          titleKo: '부산에서 장소를 확인하는 방법',
          titleEn: 'How to find locations in Busan',
          iconName: 'location_on',
          stepsKo: [
            '지진 옥외대피장소는 아래 부산시 해당 페이지의 지역 정보와 「지도 보기」 경로에서 확인합니다.',
            '지진해일은 별도 페이지의 구·군, 대피지구, 긴급대피장소 이름을 확인합니다. 지진 옥외대피장소와 혼동하지 마세요.',
            '재난이 닥치기 전에 현재 위치에서 가는 방법을 확인합니다. 지도 접속이 안 되거나 장소 이용이 불분명하면 평소 구·군 담당 부서나 학교·기숙사 담당자에게 확인하세요.',
          ],
          stepsEn: [
            'For earthquake outdoor assembly sites, use the district information and map link on the Busan earthquake-sites page below.',
            'For a tsunami, use the separate page to check the district, evacuation zone and emergency-site name. Do not confuse this with the earthquake outdoor-sites list.',
            'Check how to reach the location before an emergency. If the map is unavailable or site access is unclear, ask the district office or campus or dormitory staff in advance.',
          ],
          notes: [
            GuideNote(
              titleKo: '민방위 대피시설은 별도로 구별하세요',
              titleEn: 'Civil defence shelters are a separate category',
              linesKo: [
                '민방위 경보도 상황의 종류에 따라 행동이 달라집니다. 아래 비상대비 안내를 확인하고 현장 지시를 따르세요.',
              ],
              linesEn: [
                'Actions under a civil defence alert also depend on the situation. Check the emergency-preparedness guidance below and follow instructions on site.',
              ],
            ),
          ],
          noticeKo:
              '이 가이드는 학교별 집결지를 지정하지 않습니다\n'
              '승학·부민·구덕에서 가장 가까운 장소, 야간 개방 여부와 이동 지원은 확인되지 않았습니다. '
              '현재 재난문자와 현장 안내에 따라 행동하세요.',
          noticeEn:
              'This guide does not designate campus assembly points\n'
              'The nearest locations to Seunghak, Bumin or Gudeok, night-time access and mobility support have not been verified. '
              'Follow current emergency alerts and instructions on site.',
          footnoteKo:
              '※ 부산시 「지진 옥외대피장소」·「지진해일 긴급대피장소」, 2026-10-31 확인. '
              '각 페이지 안의 기준일·합계가 서로 맞지 않아 장소 총수는 싣지 않았습니다. '
              '민방위 구별은 행정안전부 국민안전24 「비상대비」 안내(갱신일 미표시, 같은 날 확인)를 따릅니다.',
          footnoteEn:
              '※ Busan earthquake outdoor-site and tsunami emergency-site pages, checked 2026-10-31. '
              'Dates and totals within the pages conflict, so no total is given. '
              'The civil defence distinction follows MOIS Safety24 emergency-preparedness guidance (no revision date shown, checked the same day).',
        ),
      ],
      tipsKo: [
        '장소와 경로는 평소 확인하세요. 대피가 급한 상황에서 지도 확인이나 짐 챙기느라 이동을 늦추지 마세요.',
        '비상용품은 본인이 운반할 수 있게 준비하고, 가족·친구와 연락 방법을 미리 정하세요.',
      ],
      tipsEn: [
        'Check destinations and routes in advance. When evacuation is urgent, do not delay it to browse maps or pack.',
        'Prepare supplies you can carry yourself and agree how to contact family or friends.',
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '행정안전부 — 지진 행동요령',
          labelEn: 'MOIS — Earthquake guidance',
          url: 'https://safekorea.go.kr/safekorea-kor/acts/nacts/action-guide.do?actsHeaderTitle=%EC%A7%80%EC%A7%84&category=earthQuake&menuSn=4',
          descriptionKo: '흔들릴 때 몸 보호와 흔들림이 멈춘 뒤 이동',
          descriptionEn: 'Protection during shaking and movement afterwards',
        ),
        GuideLink(
          labelKo: '행정안전부 — 호우 행동요령',
          labelEn: 'MOIS — Heavy-rain guidance',
          url: 'https://www.safekorea.go.kr/safekorea-kor/acts/nacts/action-guide.do?actsHeaderTitle=%ED%98%B8%EC%9A%B0&category=heavyRain&menuSn=4',
          descriptionKo: '침수 위험 지역과 물에 잠긴 도로 주의',
          descriptionEn: 'Flood-risk areas and flooded roads',
        ),
        GuideLink(
          labelKo: '행정안전부 — 태풍 행동요령',
          labelEn: 'MOIS — Typhoon guidance',
          url: 'https://www.safekorea.go.kr/safekorea-kor/acts/nacts/action-guide.do?actsHeaderTitle=%ED%83%9C%ED%92%8D&category=typhoon&menuSn=4',
          descriptionKo: '예보에 따른 사전 준비와 위험 지역 피하기',
          descriptionEn: 'Forecast-based preparation and avoiding risk areas',
        ),
        GuideLink(
          labelKo: '행정안전부 — 지진해일 행동요령 포함 안내',
          labelEn: 'MOIS — Guidance including tsunami safety',
          url: 'https://www.mois.go.kr/frt/bbs/type002/commonSelectBoardArticle.do?bbsId=BBSMSTR_000000000205&nttId=86685',
          descriptionKo: '2021-08-27 게시, 해안에서 높은 곳으로 대피하는 기본 행동',
          descriptionEn: 'Published 2021-08-27: basic action to leave the coast for higher ground',
        ),
        GuideLink(
          labelKo: '행정안전부 — 비상대비 행동요령',
          labelEn: 'MOIS — Emergency-preparedness guidance',
          url: 'https://www.safekorea.go.kr/safekorea-kor/acts/nacts/action-guide.do?actsHeaderTitle=%EB%B9%84%EC%83%81%EB%8C%80%EB%B9%84&category=stateOfEmergency&menuSn=4',
          descriptionKo: '민방위 대피시설 구별과 비상용품 준비',
          descriptionEn: 'Civil defence shelters and emergency supplies',
        ),
        GuideLink(
          labelKo: '부산시 — 지진 옥외대피장소',
          labelEn: 'Busan — Earthquake outdoor assembly sites',
          url: 'https://www.busan.go.kr/depart/ahfacilities06',
          descriptionKo: '지역별 정보와 지도 보기 경로',
          descriptionEn: 'District information and the map entry point',
        ),
        GuideLink(
          labelKo: '부산시 — 지진해일 긴급대피장소',
          labelEn: 'Busan — Tsunami emergency evacuation sites',
          url: 'https://www.busan.go.kr/depart/ahfacilities04',
          descriptionKo: '구·군별 대피지구와 긴급대피장소 이름',
          descriptionEn: 'Evacuation zones and emergency-site names by district',
        ),
      ],
    ),
  ];
}
