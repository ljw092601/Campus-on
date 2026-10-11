import '../../domain/entities/admin_guide.dart';

/// Guides added in the 2026-09 expansion (18 → 28 plan). Kept apart from the
/// original 18 in mock_data.dart so each addition reviews as its own diff;
/// [MockData.guideItems] appends this list, so seed export and screens treat
/// them exactly like the others.
///
/// Every rule below was read in the official source on the date noted in the
/// item's comment. Only guides whose core procedure is confirmed are listed —
/// drafts that are still missing a core source stay out of the app.
abstract final class ExpansionGuides {
  static const List<AdminGuideItem> items = [
    // part-time-work — 하이코리아 「체류민원 자격별 안내 매뉴얼」(2026-09-01 게시판,
    // 유학(D-2) 체류자격외 활동 › 시간제취업 활동 허가, 허용시간 표 '23.7. 시행)을
    // 2026-09-13에 원문으로 읽었다. 어학연수(D-4) 허용시간은 매뉴얼 표에 행이 없어
    // 스터디인코리아(국립국제교육원) 체류 안내 표를 출처로 밝히고 확인을 권한다.
    // 동아대 인증대학 여부: 법무부·교육부 2026-02-12 보도자료 붙임 명단(학위·어학연수 모두 포함).
    // 에이전트 A 근거팩(02/021)과 대조해 반영: 하이코리아 전자민원 CAT_SEQ 2189(수수료 면제,
    // 처리 10일/2개월)·2190(업체변경 신고, 14일/통상 3일), 시행규칙 제72조 수수료 표기 충돌,
    // 법 제20·46·94조, 동아대 국제교류과 VISA 정보(MN064)의 시간·업종 표기 차이.
    AdminGuideItem(
      id: 'part-time-work',
      categoryId: GuideCategory.immigration,
      // 조사 04/029 §4.1: the guide already covers unpaid wages and the 1350
      // route; these are the words students look for.
      searchAliasesKo: ['알바', '아르바이트', '시간제 취업', '일자리', '임금체불',
        '근로계약', '급여명세서', '노동청', '산재', '직장괴롭힘', '퇴직금'],
      searchAliasesEn: ['part-time job', 'work permit', 'side job', 'unpaid wages',
        'employment contract', 'payslip', 'labour office', 'workplace injury',
        'harassment at work', 'severance pay'],
      titleKo: '시간제취업(아르바이트) 허가',
      titleEn: 'Part-time Work Permission',
      detailTitleKo: '유학생 시간제취업 허가 받기',
      detailTitleEn: 'Getting Permission for Part-time Work',
      summaryKo: '일을 시작하기 전에 학교 확인과 출입국 허가',
      summaryEn: 'School confirmation and immigration permission before you start',
      iconName: 'work',
      overviewKo: '유학(D-2)이나 어학연수(D-4) 체류자격만으로 아르바이트를 할 수 있는 것은 '
          '아닙니다. 일을 시작하기 전에 학교 유학생 담당자의 확인을 받고, 출입국·외국인관서에서 '
          '시간제취업 허가(체류자격외 활동허가)를 받아야 합니다.\n\n'
          '학교 확인서는 허가가 아닙니다. 허가 여부와 조건은 출입국·외국인관서가 심사해 '
          '정하며, 허가를 받은 뒤에도 허가된 근무처와 허용 시간 안에서만 일할 수 있습니다.',
      overviewEn: 'Holding a student (D-2) or language-training (D-4) status does '
          'not by itself let you take a part-time job. Before you start, you '
          "need a confirmation from your university's international student "
          'adviser and permission for part-time work (permission for '
          'activities outside your status of stay) from the immigration '
          'office.\n\n'
          "The university's confirmation is not the permission. The "
          'immigration office reviews the application and sets the '
          'conditions, and even once permitted you may only work at the '
          'approved workplace and within the permitted hours.',
      topSections: [
        GuideSection(
          titleKo: '신청할 수 있나요?',
          titleEn: 'Can I apply?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '✅ 신청 대상',
              titleEn: '✅ Who can apply',
              linesKo: [
                '유학(D-2) 중 세부 자격 D-2-1~D-2-4, D-2-6, D-2-7: 입국 후 바로 신청할 수 '
                    '있습니다.',
                '어학연수(D-4-1, D-4-7)와 방문학생(D-2-8): 자격 변경일(사증을 받아 입국했다면 '
                    '입국일)부터 6개월이 지나야 신청할 수 있습니다.',
                '과정에 맞는 언어능력 기준(일반 과정은 한국어, 영어트랙은 인정되는 영어 기준)을 '
                    '갖추고, 학교 유학생 담당자의 확인을 받아야 합니다.',
              ],
              linesEn: [
                'Student (D-2) sub-types D-2-1 to D-2-4, D-2-6 and D-2-7: you '
                    'can apply straight after arrival.',
                'Language training (D-4-1, D-4-7) and visiting students '
                    '(D-2-8): only once 6 months have passed since your status '
                    'was changed (or since you entered Korea, if you came on '
                    'that visa).',
                'You need to meet the language standard for your programme '
                    '(Korean for regular programmes, an accepted English standard '
                    'for English-track programmes) and get a confirmation from '
                    "the university's international student adviser.",
              ],
            ),
            GuideNote(
              titleKo: '⛔ 허가가 제한될 수 있는 경우',
              titleEn: '⛔ When permission can be refused',
              linesKo: [
                '신청일 기준 직전 학기 평균 성적이 C학점(2.0) 미만이어서 학업과 병행하기 어렵다고 '
                    '판단되는 경우(어학연수 과정은 전체 이수 학기 평균 출석률 90% 미만)',
                '신청일 기준 최근 3개월 안에 허가 없이 일했거나 허가 조건을 어겨 처벌받은 경력이 '
                    '있는 경우',
                '정규 과정(전문학사 2년·학사 4년)이 끝난 뒤 학점 미달 등으로 졸업하지 못해 '
                    '예외적으로 체류허가를 받은 경우(석·박사 과정 수료 후 논문 준비생은 허용될 수 '
                    '있으나, 이 경우 주당 30시간까지이고 주말·공휴일·방학 무제한 규정은 적용되지 '
                    '않습니다. 학점·출석 미달로 졸업이 늦어진 경우는 제외)',
              ],
              linesEn: [
                'Your average grade in the previous semester is below C (2.0) '
                    'as of the application date and work is judged to get in '
                    'the way of study (for language courses: average attendance '
                    'below 90% across all completed terms).',
                'In the 3 months before applying you worked without '
                    'permission, or were penalised for breaking the conditions '
                    'of a permission.',
                'Your regular course (2-year associate or 4-year bachelor) has '
                    'ended and you were given stay only as an exception because '
                    'you have not met graduation requirements, such as missing '
                    'credits (thesis-stage master’s and doctoral students may be '
                    'allowed, but only up to 30 hours a week, and the unlimited '
                    'weekend, holiday and vacation rule does not apply; not if '
                    'graduation is delayed by missing credits or attendance).',
              ],
            ),
          ],
          footnoteKo: '※ 하이코리아 「체류민원 자격별 안내 매뉴얼」(2026년 9월 게시) 기준, '
              '2026-09-13 확인. 최종 판단은 출입국·외국인관서 심사로 정해집니다.',
          footnoteEn: '※ Based on the HiKorea stay-application manual by status '
              '(posted September 2026), checked 2026-09-13. The immigration '
              'office makes the final decision.',
        ),
        GuideSection(
          titleKo: '한 주에 몇 시간 일할 수 있나요?',
          titleEn: 'How many hours a week?',
          iconName: 'event_repeat',
          bodyKo: '과정에 맞는 언어능력 기준을 충족했는지에 따라 허용 시간이 달라집니다. 일반 '
              '과정은 TOPIK, 사회통합프로그램, 세종학당 중 하나로, 영어트랙은 인정되는 영어 '
              '시험으로 증명합니다.',
          bodyEn: 'Your permitted hours depend on whether you meet the language '
              'standard for your programme. Regular programmes show Korean with '
              'TOPIK, the Korea Immigration & Integration Program (KIIP) or King '
              'Sejong Institute courses; English-track programmes use an '
              'accepted English test.',
          notes: [
            GuideNote(
              titleKo: '📘 한국어 능력 기준',
              titleEn: '📘 Korean language requirement',
              linesKo: [
                '전문학사, 학사 1~2학년: TOPIK 3급 / 사회통합프로그램 3단계 이상 이수 또는 '
                    '사전평가 61점 이상 / 세종학당 중급1 이상 이수',
                '학사 3~4학년, 석·박사: TOPIK 4급 / 사회통합프로그램 4단계 이상 이수 또는 '
                    '사전평가 81점 이상 / 세종학당 중급2 이상 이수',
                '영어트랙 과정은 학년과 관계없이 TOEFL 530(CBT 197, iBT 71), IELTS 5.5, '
                    'CEFR B2, TEPS 601점(NEW TEPS 327점) 이상이면 기준을 충족한 것으로 봅니다'
                    '(영어 공용 국가 학생은 증빙 제출 면제).',
              ],
              linesEn: [
                'Associate degree, or bachelor’s years 1–2: TOPIK level 3 / '
                    'KIIP level 3 completed or a pre-test score of 61+ / King '
                    'Sejong Institute Intermediate 1 or above',
                'Bachelor’s years 3–4, master’s and doctoral: TOPIK level 4 / '
                    'KIIP level 4 completed or a pre-test score of 81+ / King '
                    'Sejong Institute Intermediate 2 or above',
                'On an English-track programme, TOEFL 530 (CBT 197, iBT 71), '
                    'IELTS 5.5, CEFR B2 or TEPS 601 (NEW TEPS 327) counts as '
                    'meeting the requirement in any year (students from '
                    'countries where English is an official language need not '
                    'submit proof).',
              ],
            ),
            GuideNote(
              titleKo: '⏱ 학위과정(D-2) 허용 시간',
              titleEn: '⏱ Degree students (D-2)',
              linesKo: [
                '한국어 기준 미충족: 전문학사·학사 주당 10시간, 석·박사 주당 15시간',
                '한국어 기준 충족: 학기 중 주중 전문학사·학사 25시간, 석·박사 30시간',
                '한국어 기준 충족 시 학기 중 주말·공휴일과 방학에는 시간 제한이 없습니다.',
                '한국어 기준을 충족하고 ① 인증대학 재학생이거나 ② 직전 학기 평균 A학점 이상이거나 '
                    '③ TOPIK 5급 이상(사회통합프로그램 5단계 이수 또는 종합평가 합격)이면 주중 '
                    '5시간이 더 허용됩니다(전문학사·학사 30시간, 석·박사 35시간).',
              ],
              linesEn: [
                'Korean requirement not met: 10 hours a week for associate and '
                    'bachelor’s students, 15 hours for master’s and doctoral '
                    'students.',
                'Korean requirement met: during term, up to 25 weekday hours '
                    'for associate and bachelor’s students, 30 for master’s and '
                    'doctoral students.',
                'If you meet the Korean requirement, there is no hour limit at '
                    'weekends and on public holidays during term, or during '
                    'vacations.',
                'If you meet the Korean requirement and (1) study at a '
                    'certified university, (2) averaged A or above last '
                    'semester, or (3) hold TOPIK level 5+ (or completed KIIP '
                    'level 5 or passed its comprehensive test), you get 5 more '
                    'weekday hours (30 for associate and bachelor’s, 35 for '
                    'master’s and doctoral).',
              ],
            ),
            GuideNote(
              titleKo: '🗣 어학연수(D-4) 허용 시간',
              titleEn: '🗣 Language students (D-4)',
              linesKo: [
                '어학연수(D-4)의 허용 시간은 한국어 기준(스터디인코리아 표: TOPIK 2급, '
                    '사회통합프로그램 2단계 이상 이수 또는 사전평가 41점 이상, 세종학당 초급2 이상 '
                    '이수) 충족 여부와 학교·성적 요건에 따라 달라집니다. 스터디인코리아 표는 기준 '
                    '미충족 10시간, 충족 20시간, 우대 25시간을 제시하며, 어학연수 행은 주말·방학에도 '
                    '같은 한도로 표시돼 있습니다. 본인의 시간 범위는 허가서에서 확인하세요.',
                '주말·방학 시간 제한 없음은 학위과정(D-2) 유학생에게만 적용됩니다.',
                '하이코리아 매뉴얼의 허용시간 표에는 어학연수 행이 따로 없으므로, 신청 전에 '
                    '하이코리아나 1345에서 본인에게 적용되는 시간을 확인하세요.',
              ],
              linesEn: [
                'For language trainees (D-4), permitted hours vary with the '
                    'Korean requirement (Study in Korea table: TOPIK level 2, '
                    'KIIP level 2 completed or a pre-test score of 41+, or King '
                    'Sejong Institute Beginner 2 or above) and school and grade '
                    'conditions. The Study in Korea table shows 10 hours without '
                    'the requirement, 20 with it and 25 with a bonus, and its '
                    'language-training row shows the same limit for weekends and '
                    'vacations. Check your exact limit on your permit.',
                'The “no limit at weekends and in vacations” rule applies only '
                    'to degree students (D-2).',
                'The HiKorea manual’s hours table has no separate row for '
                    'language training, so confirm your hours with HiKorea or '
                    '1345 before applying.',
              ],
            ),
          ],
          noticeKo: '동아대학교는 법무부·교육부가 2026년 2월 12일 발표한 교육국제화역량 '
              '인증대학 명단(학위과정·어학연수과정)에 포함되어 있습니다. 인증은 매년 점검되므로 '
              '신청할 때 우대 시간이 적용되는지 함께 확인하세요. 우대 대상이어도 허가는 따로 '
              '받아야 합니다.',
          noticeEn: 'Dong-A University is on the list of certified universities '
              '(degree and language programmes) announced by the Ministry of '
              'Justice and Ministry of Education on 12 February 2026. '
              'Certification is reviewed every year, so check that the extra '
              'hours apply when you apply. Even if they do, you still need '
              'the permission.',
          noticeIconName: 'info',
          footnoteKo: '※ 동아대학교 국제교류과 「VISA 정보」 페이지(게시일 표기 없음)는 주중 '
              '허용시간을 어학연수 25시간·학사 30시간·석박사 35시간으로, 허용 업종에 「제조업 '
              '불가」로 적고 있어 위 매뉴얼 기준과 표기가 다릅니다. 실제 적용 시간과 업종은 '
              '국제교류과와 하이코리아에서 확인하세요.',
          footnoteEn: "※ Dong-A's Office of International Affairs “VISA "
              'information” page (no posting date) lists weekday hours as 25 '
              'for language students, 30 for bachelor’s and 35 for master’s and '
              'doctoral students, and says manufacturing is not allowed — '
              'different from the manual above. Confirm your hours and '
              'permitted jobs with the office and HiKorea.',
        ),
      ],
      checklistKo: [
        '통합신청서(신고서), 여권, 외국인등록증',
        '외국인 유학생 시간제 취업 확인서 — 학교 유학생 담당자가 작성',
        '표준근로계약서 사본 — 시급, 근무 내용, 근무 시간이 적혀 있어야 함',
        '사업자등록증 사본과 고용주 신분증 사본',
        '한국어(영어트랙은 영어) 능력 증빙서류',
        '성적 또는 출석 증명서 — 유학생정보시스템으로 확인되면 생략',
      ],
      checklistEn: [
        'Integrated application form, passport and Residence Card',
        'Confirmation of part-time employment for international students — '
            "filled in by the university's international student adviser",
        'Copy of the standard employment contract — it must show the hourly '
            'wage, the work and the working hours',
        "Copy of the business registration certificate and of the employer's "
            'ID',
        'Proof of Korean (or, on an English track, English) ability',
        'Transcript or attendance certificate — not needed if the '
            'international student information system already shows it',
      ],
      checklistOptionalTitleKo: '사업장에 따라 추가로 필요해요',
      checklistOptionalTitleEn: 'Also needed for some workplaces',
      checklistOptionalKo: [
        '외국인 유학생 시간제취업 요건 준수 확인서 — 사업자등록증에 제조업이나 건설업이 '
            '포함된 경우',
      ],
      checklistOptionalEn: [
        'Declaration of compliance with part-time work requirements — when '
            'the business registration lists manufacturing or construction',
      ],
      checklistNoteKo: '※ 동아대학교 국제교류과는 시간제취업 확인서에 담당자 서명이 필요하며, '
          '서명을 받으러 갈 때 위 서류(통합신고서·확인서·사업자등록증 사본·고용계약서·여권·'
          '외국인등록증·성적 또는 출석증명서·TOPIK 증명서)를 가져오라고 안내합니다. '
          '하이코리아 매뉴얼·전자민원은 수수료를 「면제」로 적고 있지만 출입국관리법 '
          '시행규칙 제72조는 유학·일반연수 시간제 취업을 2만원으로 적고 있어 서로 다르니, '
          '방문 신청이라면 수수료를 함께 확인하세요. '
          '출입국·외국인관서는 심사에 필요하면 서류를 더 요청할 수 있습니다.',
      checklistNoteEn: "※ Dong-A's Office of International Affairs says the "
          'confirmation needs a staff signature, and asks you to bring the '
          'documents above (application form, confirmation, business '
          'registration copy, employment contract, passport, Residence Card, '
          'transcript or attendance certificate, TOPIK certificate) when you '
          'come for it. The HiKorea manual and e-application say the fee is '
          'waived, while art. 72 of the Enforcement Rules of the Immigration '
          'Act lists ₩20,000 for student and training part-time work, so check '
          'the fee if you apply in person. The '
          'immigration office may ask for more documents for its review.',
      stepsKo: [
        '고용주와 표준근로계약서 작성(시급 기재) — 사업자등록증상 고용주와 직접 맺는 계약이어야 '
            '하며, 인력파견업체처럼 고용과 사용이 분리된 계약은 허용되지 않습니다.',
        '학교 유학생 담당자에게 시간제 취업 확인서 작성 받기 — 동아대학교는 국제교류과에서 '
            '시간제취업 관련 학교 확인을 안내합니다.',
        '하이코리아 전자민원(온라인) 또는 관할 출입국·외국인관서 방문으로 신청 — 전자민원 '
            '처리기간은 일반 10일, 조사가 필요하면 2개월로 안내됩니다.',
        '허가 결과 확인(전자민원은 마이페이지 › 전자민원신청 현황) — 허가되면 허가 스티커를 '
            '붙이거나 온라인 허가서를 출력합니다.',
        '허가된 근무처와 기간·시간 안에서 근무 시작',
      ],
      stepsEn: [
        'Sign a standard employment contract with the employer (stating the '
            'hourly wage). It must be directly with the employer named on the '
            'business registration — contracts where the hiring and the '
            'actual workplace are split, as with staffing agencies, are not '
            'accepted.',
        'Ask the university’s international student adviser to fill in the '
            'part-time employment confirmation. At Dong-A, the Office of '
            'International Affairs handles university confirmation for '
            'part-time work.',
        'Apply online through HiKorea e-application, or in person at your '
            'immigration office. E-applications are listed as taking 10 days, '
            'or 2 months when an investigation is needed.',
        'Check the result (for e-applications: My Page › e-application '
            'status). If permitted, a permission sticker is attached or you '
            'print the online permission.',
        'Start work only at the permitted workplace, within the permitted '
            'period and hours.',
      ],
      sections: [
        GuideSection(
          titleKo: '허가 기간과 근무처',
          titleEn: 'Permission period and workplaces',
          iconName: 'format_list_numbered',
          notes: [
            GuideNote(
              titleKo: '📅 한 번 받으면',
              titleEn: '📅 How long one permission lasts',
              linesKo: [
                '유학(D-2): 체류기간 안에서 최장 1년, 허용 시간 범위 안에서 동시에 일할 수 있는 '
                    '곳은 2곳까지입니다.',
                '어학연수(D-4): 체류기간 안에서 최장 6개월, 1곳만 가능합니다.',
              ],
              linesEn: [
                'Student (D-2): up to 1 year within your period of stay, and at '
                    'most 2 workplaces at a time within the permitted hours.',
                'Language training (D-4): up to 6 months within your period of '
                    'stay, at 1 workplace only.',
              ],
            ),
            GuideNote(
              titleKo: '🔁 근무처를 바꾸거나 더할 때',
              titleEn: '🔁 Changing or adding a workplace',
              linesKo: [
                '고용주가 달라져 근무 장소가 바뀌면 새 근무처에서 일하기 전에 절차를 다시 밟아야 '
                    '합니다. 기존 허가는 그 근무처에만 해당합니다.',
                '하이코리아 매뉴얼은 「사전에 새로이 시간제 취업허가를 받아야 함」으로, 하이코리아 '
                    '전자민원은 「시간제취업 업체변경 신고」(처리 14일 이내, 통상 3일)로 안내합니다. '
                    '본인에게 어느 절차가 적용되는지 신청 전에 확인하세요.',
                '어느 쪽이든 새 근무처의 계약서와 학교 확인서를 다시 준비합니다.',
              ],
              linesEn: [
                'If you move to a different employer, you must go through the '
                    'procedure again before you start at the new workplace. An '
                    'existing permission covers only that workplace.',
                'The HiKorea manual says you must “obtain a new part-time work '
                    'permission in advance”, while HiKorea e-application offers '
                    'a “workplace change report” for part-time work (processed '
                    'within 14 days, usually 3). Check which applies to you '
                    'before you apply.',
                'Either way, prepare the new contract and a new university '
                    'confirmation.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '할 수 없는 일',
          titleEn: 'Work you cannot do',
          iconName: 'gavel',
          bodyKo: '허가 대상은 학생이 통상적으로 하는 시간제 일(단순 노무 등)입니다. 다음 분야는 '
              '원칙적으로 제한됩니다.',
          bodyEn: 'Permission covers the kind of part-time work students '
              'usually do (such as simple labour). The following are restricted '
              'in principle.',
          notes: [
            GuideNote(
              titleKo: '🚫 제한 분야',
              titleEn: '🚫 Restricted',
              linesKo: [
                '선량한 풍속이나 사회질서에 반하는 업종',
                '전문 분야(E-1~E-7) 활동 — 예: 미성년 학생 대상 외국어 교육 시설에서의 회화지도',
                '제조업(한국어능력 4급 이상이면 허용)·건설업, 선원 업종',
                '택배기사, 배달대행 라이더, 대리기사, 보험설계사, 학습지 교사, 방문판매원 같은 '
                    '특수형태근로',
                '파견·도급·알선 관계에 따른 취업, 원거리 근무',
                '과거 불법고용 등으로 처벌받아 사증발급이 제한된 업체',
                '개인과외는 엄격히 제한됩니다.',
              ],
              linesEn: [
                'Businesses contrary to public morals or social order',
                'Professional work (E-1 to E-7) — e.g. teaching conversation at '
                    'a foreign-language facility for minors',
                'Manufacturing (allowed with Korean level 4 or above), '
                    'construction, and work as a seafarer',
                'Special-type work such as parcel delivery, delivery-app '
                    'riding, designated driving, insurance sales, home-study '
                    'tutoring for learning-material companies and door-to-door '
                    'sales',
                'Work through dispatch, subcontracting or placement, and '
                    'long-distance workplaces',
                'Employers barred from visa sponsorship for past illegal '
                    'hiring',
                'Private tutoring is strictly limited.',
              ],
            ),
            GuideNote(
              titleKo: '🆗 허가 없이 받아도 되는 돈',
              titleEn: '🆗 Payments that need no permission',
              linesKo: [
                '유학 활동의 본질을 해치지 않는 범위의 일시적 사례금, 상금, 그 밖에 일상생활에 '
                    '따르는 보수',
                '소속 대학·산학협력단에서 연구수당을 받는 학업 연계 연구·인턴 참여(학업과 무관한 '
                    '연구·인턴은 허가 필요)',
              ],
              linesEn: [
                'One-off honoraria, prize money and other everyday payments '
                    'that do not undermine your study',
                'Study-related research or internships at your own university '
                    'or its industry-cooperation foundation that pay a research '
                    'allowance (research or internships unrelated to your study '
                    'need permission)',
              ],
            ),
          ],
          footnoteKo: '※ 계절근로, 방학 중 학위과정 유학생의 전문분야 인턴 등 예외적으로 허용되는 '
              '활동도 있습니다. 해당하는지는 신청 전에 하이코리아나 1345에서 확인하세요.',
          footnoteEn: '※ Some activities are allowed as exceptions — seasonal '
              'farm work, or professional internships for degree students '
              'during vacations, for example. Check with HiKorea or 1345 before '
              'applying.',
        ),
        GuideSection(
          titleKo: '허가 없이 일했거나 조건을 어기면',
          titleEn: 'If you work without permission or break the conditions',
          iconName: 'warning',
          notes: [
            GuideNote(
              titleKo: '허가 없이 일한 경우',
              titleEn: 'Working without permission',
              linesKo: [
                '법은 허가 없이 다른 체류자격의 활동을 한 사람을 형사처벌(3년 이하 징역 또는 '
                    '3천만원 이하 벌금)과 강제퇴거 대상으로 정하고 있습니다(출입국관리법 제20조·'
                    '제46조·제94조).',
                '매뉴얼의 처리 기준: 처음 적발되고 위반 정도가 가벼우면 통고처분 후 체류허가를 '
                    '받을 수 있고, 두 번째 적발되면 강제퇴거될 수 있습니다.',
                '건설업에서 허가 없이 일한 경우는 적발 횟수와 관계없이 출국명령 대상으로 '
                    '안내됩니다.',
              ],
              linesEn: [
                'The law makes working in another status’s activity without '
                    'permission a criminal offence (up to 3 years in prison or a '
                    'fine of up to ₩30 million) and grounds for deportation '
                    '(Immigration Act arts. 20, 46, 94).',
                'Handling standards in the manual: a first, minor offence can '
                    'end with a notice of disposition and permission to stay; a '
                    'second offence can lead to deportation.',
                'Working without permission in construction is listed for a '
                    'departure order regardless of how many times you were '
                    'caught.',
              ],
            ),
            GuideNote(
              titleKo: '허가 조건을 어긴 경우',
              titleEn: 'Breaking the conditions',
              linesKo: [
                '1차: 엄중 경고 / 2차: 유학기간 중 시간제취업 불허 / 3차: 유학자격 취소',
                '허용 시간을 넘기거나 허가받지 않은 곳에서 일하는 것도 조건 위반입니다.',
              ],
              linesEn: [
                '1st time: a strict warning / 2nd: no part-time work for the '
                    'rest of your studies / 3rd: your student status is '
                    'cancelled.',
                'Working more than the permitted hours, or somewhere you are '
                    'not permitted, also breaks the conditions.',
              ],
            ),
          ],
          noticeKo: '위 기준은 매뉴얼의 처리 기준이며 실제 처분은 출입국·외국인관서가 사안별로 '
              '정합니다. 최근 3개월 안에 처벌받은 경력이 있으면 새 허가도 제한될 수 있습니다.',
          noticeEn: 'These are the manual’s handling standards; the immigration '
              'office decides each case. A penalty in the last 3 months can '
              'also block a new permission.',
        ),
        GuideSection(
          titleKo: '임금을 못 받았거나 근로 문제가 생기면',
          titleEn: 'If you are not paid or have a problem at work',
          iconName: 'call',
          bodyKo: '체류 허가 문제와 임금·근로계약 문제는 담당 기관이 다릅니다. 임금체불이나 '
              '근로계약 문제는 고용노동부에 상담하거나 진정할 수 있습니다.',
          bodyEn: 'Stay permission and wage or contract problems are handled by '
              'different authorities. For unpaid wages or contract problems you '
              'can ask the Ministry of Employment and Labor for advice or file a '
              'petition there.',
          links: [
            GuideLink(
              labelKo: '고용노동부 고객상담센터 1350',
              labelEn: 'Ministry of Employment and Labor helpline 1350',
              descriptionKo: '국번 없이 1350(유료, 평일 09:00~18:00)',
              descriptionEn: 'Dial 1350 from anywhere (paid call, weekdays '
                  '09:00–18:00)',
              url: 'tel:1350',
              iconName: 'call',
            ),
            GuideLink(
              labelKo: '노동포털 민원 신청',
              labelEn: 'Labor portal — file a petition',
              descriptionKo: '임금체불 진정 등 민원(고용노동부)',
              descriptionEn: 'Petitions such as unpaid wages (Ministry of '
                  'Employment and Labor, Korean)',
              url: 'https://labor.moel.go.kr/minwonApply/minwonFormat.do?searchVal=OF0002',
            ),
          ],
          footnoteKo: '※ 체류 관련 문의는 외국인종합안내센터 1345(유료)에서 할 수 있습니다.',
          footnoteEn: '※ For stay questions, call the Immigration Contact Center '
              'on 1345 (paid call).',
        ),
      ],
      tipsKo: [
        '방학 중이나 주말에 일할 때도 허가가 있어야 합니다. 시간 제한이 없다는 것은 허가를 받은 '
            '뒤의 근무 시간 이야기입니다.',
        '허가서(또는 허가 스티커), 근로계약서, 학교 확인서 사본을 허가 기간 동안 보관하세요.',
        '허가 기간이 끝나면 계속 일하기 전에 다시 허가를 받아야 합니다.',
        '졸업하거나 학업을 마친 뒤에는 유학생 시간제취업 허가가 그대로 이어지지 않습니다. 이후 '
            '체류자격에 맞는 허가를 확인하세요.',
        '일이 학업보다 주된 활동이 되면 체류자격외 활동허가가 아니라 체류자격 변경허가 대상이 '
            '될 수 있습니다.',
        '임금을 받지 못한 문제는 경찰이 아니라 고용노동부(1350, 노동포털 진정)에서 다룹니다.',
      ],
      tipsEn: [
        'You need the permission for vacation and weekend work too — '
            '“no hour limit” is about hours once you are permitted.',
        'Keep the permission (or sticker), your contract and the university '
            'confirmation for as long as the permission lasts.',
        'When the permission period ends, get a new one before you carry on '
            'working.',
        'Student part-time permission does not carry over once you graduate '
            'or finish your studies. Check what your next status of stay '
            'allows.',
        'If work becomes your main activity rather than study, you may need a '
            'change of status of stay instead of permission for activities '
            'outside your status.',
        'Unpaid wages are handled by the Ministry of Employment and Labor '
            '(1350, or a petition on the labor portal), not the police.',
      ],
      phrases: [
        GuidePhrase(
          ko: '시간제취업 허가를 신청하려고 합니다. 시간제 취업 확인서를 받을 수 있을까요?',
          en: 'I want to apply for part-time work permission. Could I get the '
              'part-time employment confirmation?',
        ),
        GuidePhrase(
          ko: '표준근로계약서에 시급과 근무 시간을 적어 주세요.',
          en: 'Please write the hourly wage and working hours in the standard '
              'employment contract.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '하이코리아 — 시간제취업 허가 신청 안내',
          labelEn: 'HiKorea — part-time work permission',
          descriptionKo: '전자민원 구비서류·처리기간(신청은 로그인 필요)',
          descriptionEn: 'E-application documents and processing time '
              '(applying needs a login)',
          url: 'https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=2189',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '하이코리아 — 시간제취업 업체변경 신고 안내',
          labelEn: 'HiKorea — part-time workplace change report',
          descriptionKo: '근무처가 바뀔 때의 전자민원 안내',
          descriptionEn: 'E-application for a change of workplace',
          url: 'https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=2190',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '동아대 국제교류과 VISA 정보',
          labelEn: 'Dong-A OIA — visa information',
          descriptionKo: '시간제취업 준비물과 확인서 서명 안내',
          descriptionEn: 'What to bring and how the confirmation is signed '
              '(Korean)',
          url: 'https://global.donga.ac.kr/global/CMS/Contents/Contents.do?mCode=MN064',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '체류자격별 안내 매뉴얼',
          labelEn: 'Stay manual by status (HiKorea)',
          descriptionKo: '하이코리아 공지 — 유학(D-2) 시간제취업 활동 허가 수록',
          descriptionEn: 'HiKorea notice — includes part-time work permission '
              'for D-2 (Korean)',
          url: 'https://www.hikorea.go.kr/board/BoardNtcDetailR.pt?BBS_SEQ=1&BBS_GB_CD=BS10&NTCCTT_SEQ=1062&page=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '스터디인코리아 — 아르바이트 안내',
          labelEn: 'Study in Korea — part-time jobs',
          descriptionKo: '국립국제교육원 체류 안내의 시간제 취업 표',
          descriptionEn: 'Part-time work table in the NIIED stay guide',
          url: 'https://www.studyinkorea.go.kr/ko/life/residenceAndStayInfo.do?tab=part-time-job',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '가이드 — 국제교류과 방문 안내',
          labelEn: 'Guide — International Affairs Office',
          descriptionKo: '시간제취업 학교 확인 문의처',
          descriptionEn: 'Where to ask for the university confirmation',
          url: '/guide/item/oia-visit',
          iconName: 'swap_horiz',
        ),
        GuideLink(
          labelKo: '가이드 — 비자 종류 안내',
          labelEn: 'Guide — Visa types',
          descriptionKo: 'D-2·D-4 체류자격 설명',
          descriptionEn: 'What D-2 and D-4 statuses cover',
          url: '/guide/item/visa-types',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 어학연수→학위과정 체류자격 변경',
          labelEn: 'Guide — Changing from D-4 to D-2',
          descriptionKo: '어학연수에서 학위과정으로 바꿀 때',
          descriptionEn: 'When you move from D-4 to D-2',
          url: '/guide/item/status-change-d4-to-d2',
          iconName: 'compare_arrows',
        ),
      ],
      // No durationText: no official source gives a processing time.
      difficulty: 2,
      status: GuideStatus.published,
    ),

    // academic-status-and-visa — 학교 절차: 동아대 학사안내 휴학(MN124)·복학(MN125)·
    // 제적(MN126)·자퇴(MN127)를 2026-09-13 리드가 원문으로 다시 읽음(에이전트 A 02/021과 일치).
    // 체류: 출입국관리법 제19조의4(학교의 15일 신고)·시행령 제24조의8(기산일)·제89조(체류허가
    // 취소·변경) — A 02/021 조문 열람. 휴학자 연장 제한: 하이코리아 「체류민원 자격별 안내
    // 매뉴얼」 2026-09-01판 유학(D-2) 체류기간 연장허가 「가사, 졸업연기 등을 위한 휴학 불인정」.
    // 재입국허가 면제: 법 제30조① + 법제처 생활법령(A 인용). 휴학한 유학생의 국내 체류 가부를
    // 일반적으로 적은 공식 안내는 찾지 못해 단정하지 않는다. 대학원 규정은 미확인(학부 기준).
    AdminGuideItem(
      id: 'academic-status-and-visa',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['휴학', '복학', '자퇴', '제적', '재입학'],
      searchAliasesEn: ['leave of absence', 'return to school', 'withdrawal', 'dismissal'],
      titleKo: '휴학·복학·자퇴와 체류',
      titleEn: 'Leave, Return, Withdrawal & Your Stay',
      detailTitleKo: '휴학·복학·자퇴·제적 전에 체류까지 확인하기',
      detailTitleEn: 'Leave, Return, Withdrawal or Dismissal — and Your Stay',
      summaryKo: '학교 절차와 출입국 체류 판단은 따로 확인',
      summaryEn: 'The school procedure and your stay are decided separately',
      iconName: 'event_busy',
      overviewKo: '휴학·복학·자퇴는 학교에 신청하는 학적 절차이지만, 외국인 유학생은 그 결과가 '
          '체류에도 이어집니다. 학교는 유학생이 등록하지 않거나 휴학하거나 제적·자퇴 등으로 '
          '유학이 끝나면 15일 안에 출입국·외국인관서에 신고해야 합니다.\n\n'
          '학교가 승인했다고 체류가 그대로 보장되는 것은 아닙니다. 체류허가를 유지할지, 연장·'
          '변경·취소할지는 출입국·외국인관서가 판단합니다. 학적을 바꾸기 전에 국제교류과와 '
          '출입국(1345)에 본인의 체류 계획을 먼저 확인하세요.',
      overviewEn: 'Leave of absence, return and withdrawal are academic '
          'procedures you file with the university, but for international '
          'students they also affect your stay. When a student does not '
          'register, takes leave, or ends their studies through dismissal or '
          'withdrawal, the university must report it to the immigration office '
          'within 15 days.\n\n'
          'University approval does not guarantee your stay. The immigration '
          'office decides whether your permission is kept, extended, changed '
          'or cancelled. Before you change your academic status, check your '
          'plan with the Office of International Affairs and with immigration '
          '(1345).',
      topSections: [
        GuideSection(
          titleKo: '학교가 하는 일, 출입국이 하는 일',
          titleEn: 'What the university does, what immigration does',
          iconName: 'compare_arrows',
          notes: [
            GuideNote(
              titleKo: '🏫 학교(동아대학교)',
              titleEn: '🏫 The university (Dong-A)',
              linesKo: [
                '휴학·복학·자퇴를 학칙에 따라 승인하거나 제적 처리합니다.',
                '유학생이 등록기한까지 등록하지 않거나 휴학한 경우, 제적 등으로 유학이 끝난 경우 '
                    '15일 안에 출입국에 신고합니다(출입국관리법 제19조의4).',
                '15일은 미등록이면 등록기한 다음 날, 휴학이면 휴학일, 제적이면 제적한 날부터 '
                    '셉니다.',
              ],
              linesEn: [
                'Approves leave, return and withdrawal under its academic '
                    'rules, or dismisses students.',
                'Reports to immigration within 15 days when an international '
                    'student does not register by the deadline, takes leave, '
                    'or ends their studies through dismissal and the like '
                    '(Immigration Act art. 19-4).',
                'The 15 days run from the day after the registration deadline '
                    '(non-registration), the leave date (leave), or the '
                    'dismissal date (dismissal).',
              ],
            ),
            GuideNote(
              titleKo: '🛂 출입국·외국인관서',
              titleEn: '🛂 The immigration office',
              linesKo: [
                '체류허가를 유지·연장·변경·취소할지 판단합니다. 사정이 바뀌어 허가 상태를 유지할 '
                    '수 없는 중대한 사유가 생기면 체류허가를 취소하거나 변경할 수 있습니다(제89조).',
                '하이코리아 체류민원 매뉴얼은 가사, 졸업연기 등 개인적인 사정이나 학점미달로 '
                    '학업을 중단(휴학)한 사람은 체류기간 연장을 제한하고, 질병·사고 등 부득이한 '
                    '사유가 인정되면 예외적으로 조치한다고 적고 있습니다.',
              ],
              linesEn: [
                'Decides whether your permission is kept, extended, changed or '
                    'cancelled. If circumstances change so that the permission '
                    'can no longer be maintained for a serious reason, it can '
                    'be cancelled or changed (art. 89).',
                'The HiKorea stay manual says extensions are restricted for '
                    'people who stop studying (take leave) for personal reasons '
                    'such as family matters or postponing graduation, or '
                    'because of missing credits, with exceptions where '
                    'unavoidable reasons such as illness or an accident are '
                    'accepted.',
              ],
            ),
          ],
          noticeKo: '휴학한 유학생이 한국에 계속 머물 수 있는지를 일반적으로 정한 공식 안내는 '
              '찾지 못했습니다. 휴학 기간·사유·남은 체류기간에 따라 달라지므로 신청 전에 1345나 '
              '관할 출입국·외국인관서에 확인하세요.',
          noticeEn: 'We found no official guidance that says in general whether '
              'an international student on leave may stay in Korea. It depends '
              'on the length and reason of the leave and on your remaining '
              'period of stay, so check with 1345 or your immigration office '
              'before you apply.',
          noticeIconName: 'info',
        ),
      ],
      checklistTitleKo: '신청 전에 확인할 것',
      checklistTitleEn: 'Check before you apply',
      checklistKo: [
        '외국인등록증의 체류기간 만료일',
        '휴학·자퇴 사유와 기간(질병이면 진단서 등 증빙)',
        '등록금 납부 여부와 신청 날짜 — 이월·환불 금액이 달라집니다',
        '휴학 중 한국에 머물지, 출국할지에 대한 계획',
        '장학금·기숙사·시간제취업 허가 등 학적에 묶인 혜택이나 허가',
      ],
      checklistEn: [
        'The expiry date of the period of stay on your Residence Card',
        'Why and for how long you are taking leave or withdrawing (for '
            'illness, a medical certificate or other proof)',
        'Whether you have paid tuition and on what date you apply — the '
            'carry-over or refund amount depends on it',
        'Whether you plan to stay in Korea or leave during the leave',
        'Scholarships, dormitory places, part-time work permission and other '
            'benefits or permissions tied to your enrolment',
      ],
      checklistNoteKo: '※ 동아대학교 학부 학사안내 기준입니다. 대학원생은 소속 대학원 '
          '행정실에서 규정을 확인하세요.',
      checklistNoteEn: '※ Based on Dong-A’s undergraduate academic guidance. '
          'Graduate students should check their graduate school office’s '
          'rules.',
      stepsKo: [
        '국제교류과와 출입국(1345)에 휴학·자퇴가 체류에 미치는 영향을 먼저 확인',
        '학교 절차 신청 — 일반휴학·복학은 인터넷, 자퇴는 소속대학 행정실 방문(지도교수 상담)',
        '승인 결과와 등록금 이월·환불 내역 확인, 필요한 증명서(휴학증명서·제적증명서 등) 발급',
        '출입국 안내에 따라 체류 조치 — 계속 체류, 체류기간 연장·체류자격 변경 신청, 또는 출국',
        '복학할 때는 복학 신청 → 학적이 「재학」으로 바뀐 뒤 등록금 납부 → 수강신청 순서로 진행',
      ],
      stepsEn: [
        'First check with the Office of International Affairs and immigration '
            '(1345) how leave or withdrawal will affect your stay.',
        'File the university procedure — general leave and return online; '
            'withdrawal in person at your college administration office '
            '(with a talk with your academic adviser).',
        'Check the decision and any tuition carry-over or refund, and get the '
            'certificates you need (certificate of leave, of dismissal, etc.).',
        'Follow immigration’s guidance on your stay — keep staying, apply to '
            'extend or change your status, or leave Korea.',
        'To return: apply for return → once your status shows “enrolled”, pay '
            'tuition → register for courses.',
      ],
      sections: [
        GuideSection(
          titleKo: '휴학',
          titleEn: 'Leave of absence',
          iconName: 'event_busy',
          notes: [
            GuideNote(
              titleKo: '신청',
              titleEn: 'Applying',
              linesKo: [
                '일반휴학·육아휴학·병역휴학은 인터넷으로, 창업휴학은 소속대학 행정실 방문으로 '
                    '신청합니다.',
                '일반휴학은 재학 중 최대 8학기(5년제는 10학기), 한 번에 최대 2학기까지입니다.',
                '미등록 휴학: 학기말 시험 후~다음 학기 개강 전(1학기는 2월 말, 2학기는 8월 말)',
                '등록 휴학: 등록금 납부 후~학기말 시험 공고 전. 수업일수 15주 종료일 2주 전부터는 '
                    '일반휴학을 할 수 없습니다.',
              ],
              linesEn: [
                'General, parental and military leave are filed online; '
                    'start-up leave in person at your college administration '
                    'office.',
                'General leave: up to 8 semesters in total (10 on 5-year '
                    'programmes), at most 2 semesters at a time.',
                'Leave without registering: from after final exams until the '
                    'next semester starts (end of February for spring, end of '
                    'August for autumn).',
                'Leave after registering: from paying tuition until the final '
                    'exam notice. General leave is not possible from 2 weeks '
                    'before the end of the 15-week term.',
              ],
            ),
            GuideNote(
              titleKo: '⚠️ 신입생 첫 학기',
              titleEn: '⚠️ First semester',
              linesKo: [
                '입학 후 첫 학기에는 일반휴학이 허용되지 않습니다. 질병(종합병원급 4주 이상 '
                    '진단서)과 군입대만 예외입니다.',
              ],
              linesEn: [
                'General leave is not allowed in your first semester. Only '
                    'illness (a general-hospital certificate of 4+ weeks) and '
                    'military enlistment are exceptions.',
              ],
            ),
            GuideNote(
              titleKo: '💰 등록 후 휴학하면 등록금은 이월',
              titleEn: '💰 Tuition is carried over, not refunded',
              linesKo: [
                '학기 개시일부터 30일까지 휴학: 전액 이월',
                '30일 지난 날부터 60일까지: 3분의 2 이월 / 60일 지난 날부터 90일까지: 2분의 1 이월',
                '90일이 지난 뒤 휴학: 이월하지 않음',
              ],
              linesEn: [
                'Leave within 30 days of the semester start: the full amount '
                    'is carried over.',
                'Day 31–60: two thirds carried over / day 61–90: half carried '
                    'over.',
                'After day 90: nothing is carried over.',
              ],
            ),
          ],
          footnoteKo: '※ 휴학을 취소하려면 사유가 생긴 날부터 5일 안에 휴학취소원을 '
              '소속대학 행정지원실에 방문 제출합니다.',
          footnoteEn: '※ To cancel a leave, submit the cancellation form in '
              'person at your college administration office within 5 days of '
              'the reason arising.',
        ),
        GuideSection(
          titleKo: '복학',
          titleEn: 'Returning',
          iconName: 'event_repeat',
          bodyKo: '일반복학·군복학은 인터넷으로 신청하고, 기간은 학기 시작 전 학사공지로 '
              '안내됩니다. 복학 신청 후 학적이 「재학」으로 바뀌어야 등록금 납부와 수강신청을 할 '
              '수 있습니다.',
          bodyEn: 'General and military return are filed online; the dates are '
              'announced in academic notices before the semester. You can pay '
              'tuition and register for courses only after your status changes '
              'to “enrolled”.',
          noticeKo: '복학 예정 학기에 복학하지 않으면 미복학제적 처리될 수 있습니다. 휴학을 더 '
              '하려면 복학 예정 학기가 시작되기 전까지 휴학연장을 인터넷으로 신청하고, 정확한 '
              '기간은 해당 학기 학사공지에서 확인하세요. 휴학연장은 재학 중 1회만 가능합니다.',
          noticeEn: 'If you do not return in the semester you are due back, you '
              'may be dismissed for non-return. To extend your leave, apply '
              'online before that semester starts and check the semester’s '
              'academic notice for the exact dates. A leave extension can be '
              'used only once while enrolled.',
          footnoteKo: '※ 휴학 중 출국했다면 체류기간이 남아 있는지, 다시 들어올 때 사증이 '
              '필요한지 복학 신청 전에 확인하세요.',
          footnoteEn: '※ If you left Korea during your leave, check before you '
              'apply to return whether your period of stay is still valid and '
              'whether you need a visa to come back.',
        ),
        GuideSection(
          titleKo: '자퇴와 제적',
          titleEn: 'Withdrawal and dismissal',
          iconName: 'warning',
          notes: [
            GuideNote(
              titleKo: '자퇴 신청',
              titleEn: 'Withdrawing',
              linesKo: [
                '소속대학 행정실을 직접 방문해 자퇴원을 쓰고 지도교수 상담을 거칩니다.',
                '환불받을 수업료가 있으면 학교 안내 준비물(본인 도장, 부모님 도장, 부모님 명의 '
                    '통장 사본)을 가져갑니다. 유학생에게 같은 서류를 요구하는지는 행정실에 '
                    '확인하세요.',
                '수업료 반환: 학기 개시일 전날까지 전액 / 개시 후에는 입학금을 빼고 30일까지 6분의 5, '
                    '60일까지 3분의 2, 90일까지 2분의 1, 그 뒤에는 반환하지 않음',
              ],
              linesEn: [
                'Go to your college administration office in person, fill in '
                    'the withdrawal form and have a talk with your academic '
                    'adviser.',
                'If tuition is to be refunded, the university asks for your '
                    'seal, a parent’s seal and a copy of a bankbook in a '
                    'parent’s name. Ask the office whether international '
                    'students need the same documents.',
                'Tuition refund: in full up to the day before the semester '
                    'starts / after that, excluding the admission fee, five '
                    'sixths up to day 30, two thirds up to day 60, half up to '
                    'day 90, nothing after that.',
              ],
            ),
            GuideNote(
              titleKo: '이런 경우 제적됩니다',
              titleEn: 'You are dismissed if you',
              linesKo: [
                '복학해야 할 학기에 복학하지 않음(미복학) · 등록금을 기간 안에 내지 않음(미등록)',
                '등록금을 내고 수강신청을 하지 않음(미수강) · 중간시험 종료일까지 무단결석 통산 4주 '
                    '이상(장기결석)',
                '학사경고 통산 3회 · 유급 통산 2회 · 징계 퇴학 · 본인 희망 자퇴',
              ],
              linesEn: [
                'Do not return when due (non-return) · do not pay tuition on '
                    'time (non-registration)',
                'Pay tuition but do not register for courses (no courses) · '
                    'are absent without leave for 4+ weeks in total by the end '
                    'of midterms (long absence)',
                'Receive a third academic warning · repeat a year for the '
                    'second time · are expelled for discipline · withdraw at '
                    'your own request',
              ],
            ),
          ],
          noticeKo: '자퇴·제적으로 학업이 끝나면 학교는 유학이 끝난 것으로 출입국에 신고합니다. '
              '출국할지, 다른 체류자격으로 바꿀 수 있는지 자퇴 신청 전에 1345나 관할 '
              '출입국·외국인관서에서 확인하세요.',
          noticeEn: 'When withdrawal or dismissal ends your studies, the '
              'university reports to immigration that your studies have ended. '
              'Before you withdraw, check with 1345 or your immigration office '
              'whether you must leave Korea or can change to another status.',
          footnoteKo: '※ 학사경고·유급 등 성적불량 제적자는 1학기 이상 지난 뒤 재입학을 '
              '신청할 수 있고, 징계로 제적되면 재입학할 수 없습니다. 재입학은 여석이 있을 때 '
              '허가됩니다.',
          footnoteEn: '※ Students dismissed for poor grades (academic warnings, '
              'repeated years) may apply for readmission after at least one '
              'semester; those dismissed for discipline cannot. Readmission '
              'depends on places being available.',
        ),
        GuideSection(
          titleKo: '휴학 중 본국에 다녀오려면',
          titleEn: 'Going home during your leave',
          iconName: 'flight_takeoff',
          notes: [
            GuideNote(
              titleKo: '재입국과 외국인등록증',
              titleEn: 'Re-entry and your Residence Card',
              linesKo: [
                '외국인등록을 한 유학(D-2)·일반연수(D-4) 체류자는 출국한 날부터 1년(남은 체류기간이 '
                    '1년보다 짧으면 그 기간) 안에 다시 들어오면 재입국허가가 면제될 수 있습니다.',
                '체류기간 안에 다시 들어올 예정이라면 출국할 때 외국인등록증을 반납하지 않아도 되는 '
                    '경우가 있습니다. 반납 대상인지 출국 전에 확인하세요.',
                '휴학 중 체류기간이 끝나면 연장이 제한될 수 있으므로, 만료일을 넘겨 해외에 머물 '
                    '계획이라면 복학 때 새 사증이 필요한지 미리 확인하세요.',
                '건강보험 지역가입자는 출국해 1개월 이상 해외에 머물면 출국 다음 날로 자격이 '
                    '끝납니다. 자세한 내용은 건강보험 가이드를 보세요.',
              ],
              linesEn: [
                'Registered student (D-2) and general training (D-4) residents '
                    'who come back within 1 year of leaving (or within their '
                    'remaining period of stay, if shorter) may be exempt from '
                    'a re-entry permit.',
                'If you will come back within your period of stay, you may not '
                    'need to hand in your Residence Card when you leave. Check '
                    'whether you must return it before departure.',
                'Extensions can be restricted during leave, so if you plan to '
                    'stay abroad past your expiry date, check in advance '
                    'whether you will need a new visa to return.',
                'For regional health insurance subscribers, coverage ends from '
                    'the day after departure once you stay abroad 1 month or '
                    'more. See the health insurance guide for details.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '학교는 휴학·미등록·제적을 출입국에 신고하지만, 그것으로 학생 본인의 체류 절차가 끝나는 '
            '것은 아닙니다. 연장·변경·출국은 본인이 챙겨야 합니다.',
        '대학 휴학 자체는 외국인등록사항 변경신고 항목으로 규정돼 있지 않습니다. 다만 전학·편입처럼 '
            '소속 학교가 바뀌면 15일 안에 변경신고를 해야 합니다.',
        '휴학하면 시간제취업 허가 요건(재학·성적·출석)에 영향이 있을 수 있습니다. 일하고 있다면 '
            '1345에 먼저 확인하세요.',
        '등록금을 냈는데 수강신청을 하지 않으면 제적될 수 있습니다. 휴학하지 않을 거라면 기간 '
            '안에 수강신청을 마치세요.',
      ],
      tipsEn: [
        'The university reports leave, non-registration and dismissal to '
            'immigration, but that does not complete your own stay procedures. '
            'Extensions, changes of status and departure are up to you.',
        'Taking leave from university is not itself listed as a change of '
            'foreign resident registration. Moving to another school, such as '
            'a transfer, must be reported within 15 days.',
        'Leave can affect the conditions of a part-time work permission '
            '(enrolment, grades, attendance). If you are working, check with '
            '1345 first.',
        'If you pay tuition but do not register for courses, you can be '
            'dismissed. If you are not taking leave, finish course '
            'registration on time.',
      ],
      phrases: [
        GuidePhrase(
          ko: '휴학하려고 하는데, 체류에 어떤 영향이 있는지 확인하고 싶습니다.',
          en: 'I want to take a leave of absence and would like to check how '
              'it affects my stay.',
        ),
        GuidePhrase(
          ko: '자퇴하면 등록금은 얼마나 돌려받을 수 있나요?',
          en: 'If I withdraw, how much of my tuition will be refunded?',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대 학사안내 — 휴학',
          labelEn: 'Dong-A academic guide — leave of absence',
          descriptionKo: '종류·기간·등록금 이월·신청 바로가기',
          descriptionEn: 'Types, periods, tuition carry-over and the online '
              'application (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN124',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 복학',
          labelEn: 'Dong-A academic guide — returning',
          descriptionKo: '복학 신청과 미복학제적',
          descriptionEn: 'Applying to return, and dismissal for non-return '
              '(Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN125',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 자퇴',
          labelEn: 'Dong-A academic guide — withdrawal',
          descriptionKo: '신청 방법과 수업료 반환 기준',
          descriptionEn: 'How to withdraw and the refund table (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN127',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 제적',
          labelEn: 'Dong-A academic guide — dismissal',
          descriptionKo: '제적 요건과 재입학',
          descriptionEn: 'Grounds for dismissal and readmission (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN126',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '생활법령 — 입국 및 재입국',
          labelEn: 'Easy-to-find Law — entry and re-entry',
          descriptionKo: '법제처 외국인유학생 — 재입국허가 면제',
          descriptionEn: 'Ministry of Government Legislation — re-entry permit '
              'exemption (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=2853&ccfNo=2&cciNo=2&cnpClsNo=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '가이드 — 국제교류과 방문 안내',
          labelEn: 'Guide — International Affairs Office',
          descriptionKo: '학적 변경 전 체류 상담',
          descriptionEn: 'Talk about your stay before changing your status',
          url: '/guide/item/oia-visit',
          iconName: 'swap_horiz',
        ),
        GuideLink(
          labelKo: '가이드 — 체류기간 연장',
          labelEn: 'Guide — Extension of Stay',
          descriptionKo: '연장 신청 방법',
          descriptionEn: 'How to apply for an extension',
          url: '/guide/item/stay-extension',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '복학 후 수강신청과 미수강제적',
          descriptionEn: 'Registering after you return, and dismissal for no '
              'courses',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '휴학·제적 증명서 발급',
          descriptionEn: 'Getting a certificate of leave or dismissal',
          url: '/guide/item/certificate-issue',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '등록금 이월·납부',
          descriptionEn: 'Tuition carry-over and payment',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 학사경고·제적 예방',
          labelEn: 'Guide — Academic Warning & Avoiding Dismissal',
          descriptionKo: '학사경고 누적 제적 예방',
          descriptionEn: 'Avoiding dismissal for academic warnings',
          url: '/guide/item/academic-probation',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: '휴학·학적 변경과 아르바이트 허가',
          descriptionEn: 'Part-time permission when your status changes',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 귀국·출국 전 행정 정리',
          labelEn: 'Guide — Before You Leave Korea',
          descriptionKo: '학업을 마치고 출국한다면',
          descriptionEn: 'If your studies end and you leave',
          url: '/guide/item/departure-checklist',
          iconName: 'flight_takeoff',
        ),
        GuideLink(
          labelKo: '가이드 — 건강보험 가입',
          labelEn: 'Guide — National Health Insurance',
          descriptionKo: '장기 귀국 시 건강보험 자격',
          descriptionEn: 'Health insurance if you are abroad for long',
          url: '/guide/item/health-insurance',
          iconName: 'receipt_long',
        ),
      ],
      difficulty: 3,
      status: GuideStatus.published,
    ),

    // academic-probation — 동아대 학사안내 학사경고(MN134, 학칙 제46조)·유급(MN135, 학칙
    // 제47조)을 2026-09-13 리드가 원문으로 읽음. 체류 연결: 하이코리아 매뉴얼 2026-09-01판
    // (시간제취업 제한 「직전학기 평균 성적 C학점(2.0) 미만」, 인증대학 우대 「전체 평균학점 C
    // 이상」)과 기존 stay-extension의 동아대 단체접수 제외 대상(직전학기 2.0 미만) — 수치를
    // 여기서 다시 길게 옮기지 않고 연결만 한다. 학부 학사안내 기준(대학원 미확인).
    AdminGuideItem(
      id: 'academic-probation',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['학사경고', '유급', '성적 불량', '학점 낮음'],
      searchAliasesEn: ['academic warning', 'probation', 'low GPA', 'repeat year'],
      titleKo: '학사경고·제적 예방',
      titleEn: 'Academic Warning & Avoiding Dismissal',
      detailTitleKo: '학사경고·유급을 받았거나 받을 것 같을 때',
      detailTitleEn: 'If You Get — or May Get — an Academic Warning',
      summaryKo: '평점 1.5 미만·F 9학점 이상이면 경고, 통산 3회면 제적',
      summaryEn: 'GPA under 1.5 or 9+ F credits means a warning; 3 means dismissal',
      iconName: 'fact_check',
      overviewKo: '학사경고는 한 학기 성적이 낮은 학생에게 주의를 주는 제도입니다. 통산 3회가 되면 '
          '성적불량으로 제적되므로, 첫 경고부터 다음 학기 계획을 세우는 것이 중요합니다.\n\n'
          '외국인 유학생은 성적이 체류와도 이어집니다. 직전 학기 성적이 낮으면 시간제취업 허가가 '
          '제한될 수 있고 학교의 비자연장 단체접수에서도 빠질 수 있으며, 제적되면 학교가 '
          '출입국에 신고합니다.',
      overviewEn: 'An academic warning is a caution given to students whose '
          'grades for a semester are low. A third warning in total means '
          'dismissal for poor grades, so plan the next semester from the first '
          'warning.\n\n'
          'For international students, grades also affect your stay. Low '
          'grades last semester can limit part-time work permission and take '
          'you out of the university’s group visa extension, and if you are '
          'dismissed the university reports it to immigration.',
      topSections: [
        GuideSection(
          titleKo: '누가 학사경고를 받나요?',
          titleEn: 'Who gets an academic warning?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '📉 경고 기준',
              titleEn: '📉 The threshold',
              linesKo: [
                '매 학기 평점평균이 1.5 미만이거나, 9학점 이상을 F로 받은 경우(의예과·의학과 제외)',
                '다음 학기 개강 전에 본인·보호자·소속대학장에게 통보되고(통지서 우편 발송), '
                    '평생지도교수와 상담해야 합니다.',
              ],
              linesEn: [
                'A semester GPA below 1.5, or 9 or more credits graded F '
                    '(except pre-medicine and medicine).',
                'You, your guardian and your college dean are notified before '
                    'the next semester (a letter is posted), and you must meet '
                    'your lifelong academic adviser.',
              ],
            ),
            GuideNote(
              titleKo: '⚠️ 횟수가 쌓이면',
              titleEn: '⚠️ As warnings add up',
              linesKo: [
                '2회째: 그다음 학기 수강신청 학점이 3학점 제한됩니다.',
                '통산 3회: 성적불량으로 제적됩니다(의예과·의학과 제외).',
                '성적불량으로 제적되면 한 학기가 지난 뒤 여석이 있을 때 재입학할 수 있습니다.',
              ],
              linesEn: [
                '2nd warning: your course load next semester is cut by 3 '
                    'credits.',
                '3rd in total: dismissal for poor grades (except pre-medicine '
                    'and medicine).',
                'After dismissal for poor grades you may be readmitted after one '
                    'semester, if a place is available.',
              ],
            ),
          ],
          footnoteKo: '※ 동아대학교 학부 학사안내(학칙 제46조, 졸업·학사경고·유급에 관한 규정) '
              '기준, 2026-09-13 확인. 대학원생은 소속 대학원 규정을 확인하세요.',
          footnoteEn: '※ Based on Dong-A’s undergraduate academic guidance '
              '(academic rules art. 46 and its regulation on graduation, '
              'warnings and repeating a year), checked 2026-09-13. Graduate '
              'students should check their own school’s rules.',
        ),
      ],
      checklistTitleKo: '경고를 받았다면 확인할 것',
      checklistTitleEn: 'If you have been warned, check',
      checklistKo: [
        '학사경고 통지서와 지금까지 받은 경고 횟수',
        '이번 학기 과목별 성적과 F를 받은 과목',
        '다음 학기 수강신청 가능 학점(2회째라면 3학점 제한)',
        '평생지도교수 상담 일정',
        '시간제취업 허가·비자연장·장학금처럼 성적 기준이 붙은 허가나 혜택',
      ],
      checklistEn: [
        'The warning letter, and how many warnings you have in total',
        'Your grades this semester and which courses you failed',
        'How many credits you may register for next semester (3 fewer after '
            'a 2nd warning)',
        'When you will meet your lifelong academic adviser',
        'Permissions or benefits with grade conditions — part-time work, visa '
            'extension, scholarships',
      ],
      stepsKo: [
        '통합정보시스템에서 성적과 경고 여부 확인',
        '평생지도교수와 상담 — 경고를 받으면 반드시 해야 합니다.',
        '낮은 성적의 원인(언어, 결석, 과목 난이도 등)을 정리하고 다음 학기 수강 계획 조정',
        '재수강·수강 학점 조정 방법은 수강신청 안내와 소속 학과에서 확인',
        '시간제취업이나 비자연장을 앞두고 있다면 국제교류과에 성적 요건을 미리 확인',
      ],
      stepsEn: [
        'Check your grades and any warning in the integrated information '
            'system.',
        'Meet your lifelong academic adviser — this is required after a '
            'warning.',
        'Work out why your grades were low (language, absences, course '
            'difficulty…) and adjust next semester’s plan.',
        'Check how to retake courses or change your load in the course '
            'registration guidance and with your department.',
        'If part-time work permission or a visa extension is coming up, ask '
            'the Office of International Affairs about the grade conditions.',
      ],
      sections: [
        GuideSection(
          titleKo: '유급도 제적으로 이어져요',
          titleEn: 'Repeating a year can also lead to dismissal',
          iconName: 'warning',
          notes: [
            GuideNote(
              titleKo: '유급 기준',
              titleEn: 'When you repeat a year',
              linesKo: [
                '직권유급: 해당 학년(1·2학기) 평점평균 1.2 미만(의예과·의학과는 기준이 다름)',
                '희망유급: 해당 학년 평점평균 2.7 미만(간호학과 2.3 미만)이면 원하는 학생만 신청',
                '유급되면 그 학년 수업료와 취득 학점이 모두 소멸하고 그 학년을 다시 이수합니다. '
                    'B등급 이상이나 P등급 과목은 성적복원을 신청할 수 있습니다.',
                '유급 통산 2회(희망유급 제외)면 성적불량으로 제적됩니다.',
              ],
              linesEn: [
                'Compulsory: a GPA below 1.2 for the academic year (both '
                    'semesters); pre-medicine and medicine differ.',
                'Voluntary: students with a year GPA below 2.7 (nursing: below '
                    '2.3) may ask to repeat.',
                'Repeating cancels that year’s tuition and credits, and you '
                    'take the year again. Courses graded B or above, or P, can '
                    'be restored on request.',
                'Two compulsory repeats in total (voluntary ones excluded) mean '
                    'dismissal for poor grades.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '성적과 체류',
          titleEn: 'Grades and your stay',
          iconName: 'badge',
          notes: [
            GuideNote(
              titleKo: '성적이 낮으면 영향을 받는 것',
              titleEn: 'What low grades can affect',
              linesKo: [
                '시간제취업: 직전 학기 평균 성적이 C학점(2.0) 미만이면 허가가 제한될 수 '
                    '있습니다(하이코리아 매뉴얼).',
                '비자연장: 동아대 단체접수에서 직전 학기 성적 2.0 미만 재학생은 개인접수로 '
                    '서류를 더 냅니다(체류기간 연장 가이드 참고).',
                '제적되면 학교가 15일 안에 출입국에 신고하므로, 체류 계획을 따로 세워야 합니다.',
              ],
              linesEn: [
                'Part-time work: permission can be restricted if your previous '
                    'semester average is below C (2.0) (HiKorea manual).',
                'Visa extension: students with a previous-semester GPA below 2.0 '
                    'are left out of Dong-A’s group filing and apply individually '
                    'with extra documents (see the extension guide).',
                'If you are dismissed, the university reports it to immigration '
                    'within 15 days, so you need your own stay plan.',
              ],
            ),
          ],
          noticeKo: '성적 기준은 허가 종류와 학기 공지마다 다를 수 있습니다. 신청 전에 해당 '
              '가이드와 국제교류과 공지로 확인하세요.',
          noticeEn: 'Grade conditions can differ by permission and by semester '
              'notice. Check the relevant guide and the office notices before '
              'you apply.',
          noticeIconName: 'info',
        ),
      ],
      tipsKo: [
        '학사경고 2회째에는 수강신청 학점이 줄고, 그 학기에는 이월학점도 쓸 수 없습니다'
            '(수강신청 가이드 참고).',
        '결석이 쌓여도 제적될 수 있습니다. 중간시험 종료일까지 무단결석이 통산 4주 이상이면 '
            '장기결석제적 대상입니다.',
        '공부나 생활이 힘들다면 경고 전에라도 학생상담센터나 국제교류과에 도움을 요청하세요.',
      ],
      tipsEn: [
        'After a 2nd warning your course load drops and you cannot use carried '
            'credits that semester (see the course registration guide).',
        'Absences can also lead to dismissal: 4 or more weeks of unexcused '
            'absence in total by the end of midterms counts as long absence.',
        'If study or life is getting hard, ask the student counseling centre or '
            'the Office of International Affairs for help — even before a '
            'warning.',
      ],
      phrases: [
        GuidePhrase(
          ko: '학사경고를 받았는데 상담을 예약하고 싶습니다.',
          en: 'I received an academic warning and would like to book a '
              'counseling session.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대 학사안내 — 학사경고',
          labelEn: 'Dong-A academic guide — academic warning',
          descriptionKo: '기준·통지·학점 제한·제적',
          descriptionEn: 'Threshold, notice, credit limit and dismissal '
              '(Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN134',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 유급',
          labelEn: 'Dong-A academic guide — repeating a year',
          descriptionKo: '직권·희망유급과 성적복원',
          descriptionEn: 'Compulsory and voluntary repeats, restoring grades '
              '(Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN135',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '재수강·학점 제한·이월학점',
          descriptionEn: 'Retakes, credit limits and carried credits',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 휴학·복학·자퇴와 체류',
          labelEn: 'Guide — Leave, Return, Withdrawal & Your Stay',
          descriptionKo: '제적 후 체류와 재입학',
          descriptionEn: 'Your stay after dismissal, and readmission',
          url: '/guide/item/academic-status-and-visa',
          iconName: 'event_busy',
        ),
        GuideLink(
          labelKo: '가이드 — 체류기간 연장',
          labelEn: 'Guide — Extension of Stay',
          descriptionKo: '단체접수 제외 대상과 개인접수 서류',
          descriptionEn: 'Who is left out of the group filing, and what to '
              'bring',
          url: '/guide/item/stay-extension',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 상담 창구',
          labelEn: 'Guide — Counseling',
          descriptionKo: '학업·생활 고민 상담',
          descriptionEn: 'Help with study and life worries',
          url: '/guide/item/counseling',
          iconName: 'help',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: '성적과 시간제취업 허가 요건',
          descriptionEn: 'Grades and part-time work permission',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '미등록제적을 피하려면',
          descriptionEn: 'Avoiding dismissal for non-registration',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 출결·공결·시험·성적',
          labelEn: 'Guide — Attendance, Exams & Grades',
          descriptionKo: '결석·공결과 시험',
          descriptionEn: 'Absences, excused absence and exams',
          url: '/guide/item/class-attendance-and-exams',
          iconName: 'fact_check',
        ),
      ],
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // address-and-registration-changes — 출입국관리법 제35조·제36조·제88조의2·제98조·제100조,
    // 시행령 제44조·제45조·별표 2, 시행규칙 제49조의2·제49조의3·별표 7(에이전트 A 02/022 조문
    // 열람), 하이코리아 「체류민원 자격별 안내 매뉴얼」 2026-09-01판 유학(D-2) 기타 5·6(리드 재열람),
    // 하이코리아 전자민원 CAT_SEQ=1807(여권변경, 리드 재열람). 등록외국인의 하이코리아 체류지
    // 변경 전자신고 조건은 원문을 확인하지 못해 경로만 법령(정보통신망 신고 가능) 수준으로 적는다.
    // 동아대 VISA 정보(MN064)의 「14일」「출입국 직접신청」 표기는 법·매뉴얼과 달라 차이를 알린다.
    AdminGuideItem(
      id: 'address-and-registration-changes',
      categoryId: GuideCategory.immigration,
      searchAliasesKo: ['이사', '주소 변경', '체류지 변경', '여권 변경', '새 여권', '전입신고'],
      searchAliasesEn: ['moving', 'move house', 'change of address', 'new passport', 'passport change'],
      titleKo: '체류지·등록사항 변경신고',
      titleEn: 'Reporting Address & Registration Changes',
      detailTitleKo: '이사했거나 여권·인적사항이 바뀌었을 때 신고하기',
      detailTitleEn: 'Moved, or Got a New Passport? Report the Change',
      summaryKo: '이사는 전입일부터, 여권·학교 변경은 변경일부터 15일 안에',
      summaryEn: 'Within 15 days — of moving in, or of the change',
      iconName: 'edit_location_alt',
      overviewKo: '외국인등록을 한 유학생은 사는 곳이나 등록된 정보가 바뀌면 직접 신고해야 합니다. '
          '신고는 두 가지로 나뉩니다.\n\n'
          '① 체류지 변경신고 — 이사했을 때(기숙사에 들어가거나 나올 때 포함)\n'
          '② 외국인등록사항 변경신고 — 여권을 새로 받았거나 이름·국적 등이 바뀌었을 때, 다니는 '
          '학교가 바뀌었을 때\n\n'
          '두 신고는 기한을 세는 날, 신고할 수 있는 곳, 늦었을 때의 제재가 서로 다릅니다.',
      overviewEn: 'Registered international students must report it themselves '
          'when their address or registered details change. There are two '
          'separate reports.\n\n'
          '① Change of address — when you move (including moving into or out '
          'of a dormitory)\n'
          '② Change of foreign resident registration — when you get a new '
          'passport, your name or nationality changes, or you move to a '
          'different school\n\n'
          'The two differ in when the deadline starts, where you can report, '
          'and what happens if you are late.',
      topSections: [
        GuideSection(
          titleKo: '어떤 신고인가요?',
          titleEn: 'Which report do I need?',
          iconName: 'compare_arrows',
          notes: [
            GuideNote(
              titleKo: '🏠 체류지 변경신고(이사)',
              titleEn: '🏠 Change of address (moving)',
              linesKo: [
                '기한: 새 주소로 전입한 날부터 15일 이내',
                '신고처: 새 체류지의 시·군·구청이나 읍·면·동 주민센터, 또는 관할 출입국·외국인관서',
                '제출: 체류지변경신고서, 여권, 외국인등록증과 이사 사실을 확인할 수 있는 '
                    '서류(임대차계약서 등). 신고하면 등록증에 새 주소가 적힙니다.',
                '늦거나 안 하면: 100만원 이하의 벌금 대상(출입국관리법 제98조)',
              ],
              linesEn: [
                'Deadline: within 15 days of moving in to the new address',
                'Where: the city/county/district office or the community '
                    'service centre (eup/myeon/dong) for your new address, or '
                    'your immigration office',
                'Bring: the change-of-address form, passport, Residence Card '
                    'and proof of the move (such as the lease). The new address '
                    'is written on your card.',
                'If late or not reported: a fine of up to ₩1 million '
                    '(Immigration Act art. 98)',
              ],
            ),
            GuideNote(
              titleKo: '🪪 외국인등록사항 변경신고',
              titleEn: '🪪 Change of registration details',
              linesKo: [
                '대상: 성명·성별·생년월일·국적, 여권 번호·발급일자·유효기간, 유학(D-2)·연수(D-4)의 '
                    '소속 학교 변경(명칭 변경 포함)이나 추가',
                '기한: 변경된 날부터 15일 이내',
                '신고처: 관할 출입국·외국인관서(여권 정보만 바뀌었으면 하이코리아 전자민원 가능)',
                '제출: 외국인등록사항 변경신고서, 여권, 외국인등록증(수수료 없음). 학교가 바뀐 '
                    '경우 새 학교 재학증명서와 전 학교 제적증명서',
                '늦거나 안 하면: 100만원 이하의 과태료 대상(제100조)',
              ],
              linesEn: [
                'Covers: name, sex, date of birth, nationality; passport '
                    'number, issue date and expiry; and for student (D-2) or '
                    'training (D-4) status, a change of school (including a '
                    'name change) or an added school',
                'Deadline: within 15 days of the change',
                'Where: your immigration office (HiKorea e-application if only '
                    'passport details changed)',
                'Bring: the change-of-registration form, passport and '
                    'Residence Card (no fee). If you changed school, a '
                    'certificate of enrolment from the new school and a '
                    'certificate of withdrawal from the old one.',
                'If late or not reported: an administrative fine of up to '
                    '₩1 million (art. 100)',
              ],
            ),
          ],
          footnoteKo: '※ 출입국관리법·시행령·시행규칙과 하이코리아 「체류민원 자격별 안내 매뉴얼」'
              '(2026년 9월 게시) 기준, 2026-09-13 확인.',
          footnoteEn: '※ Based on the Immigration Act, its Decree and Rules and '
              'the HiKorea stay manual by status (posted September 2026), '
              'checked 2026-09-13.',
        ),
      ],
      checklistKo: [
        '외국인등록증',
        '여권(새 여권을 받았다면 새 여권)',
        '신고서 — 체류지변경신고서 또는 외국인등록사항 변경신고서(통합신청서 양식)',
        '이사했다면: 이사 사실을 확인할 서류 — 임대차계약서 등',
      ],
      checklistEn: [
        'Residence Card',
        'Passport (the new one, if you have been issued a new passport)',
        'The report form — change of address, or change of registration '
            '(integrated application form)',
        'If you moved: proof of the move — such as the lease',
      ],
      checklistOptionalTitleKo: '상황에 따라 필요해요',
      checklistOptionalTitleEn: 'Depending on your situation',
      checklistOptionalKo: [
        '기숙사에 들어갔다면: 기숙사비 영수증이나 숙소제공 확인서 등(매뉴얼 표기). 학교 발급 '
            '서류 이름은 기숙사·국제교류과에서 확인',
        '학교가 바뀌었다면: 새 학교 재학증명서, 전 학교 제적증명서',
      ],
      checklistOptionalEn: [
        'If you moved into a dormitory: a dormitory fee receipt or a '
            'confirmation of accommodation (as the manual lists them). Ask '
            'the dormitory or the international office what the university '
            'issues.',
        'If you changed school: certificate of enrolment from the new '
            'school, certificate of withdrawal from the old one',
      ],
      stepsKo: [
        '바뀐 날짜 확인 — 이사는 새 주소로 전입한 날, 여권·학교 등은 변경된 날부터 15일',
        '어떤 신고인지 고르고 서류 준비',
        '신고처 선택 — 이사는 주민센터·시군구청·출입국 중 한 곳, 등록사항은 출입국(여권 정보만 '
            '바뀌었으면 하이코리아 전자민원). 출입국 방문은 하이코리아 방문예약 확인',
        '신고 후 외국인등록증에 새 주소가 적혔는지(또는 변경 처리가 끝났는지) 확인',
        '임대차계약서·접수증 등 신고 증빙을 보관',
      ],
      stepsEn: [
        'Check the date — for a move, the day you moved in; for passport, '
            'school and other changes, the day of the change. You have 15 '
            'days.',
        'Pick the right report and prepare the documents.',
        'Choose where to report — a move at a community service centre, the '
            'district office or immigration; registration details at '
            'immigration (or HiKorea e-application if only your passport '
            'changed). For immigration visits, check HiKorea visit booking.',
        'After reporting, check that your new address is on your Residence '
            'Card (or that the change has been processed).',
        'Keep the lease, receipt and other proof of the report.',
      ],
      sections: [
        GuideSection(
          titleKo: '여권을 새로 받았다면',
          titleEn: 'If you got a new passport',
          iconName: 'badge',
          bodyKo: '여권 번호·발급일자·유효기간만 바뀌었다면 하이코리아 전자민원 「등록사항변경신고'
              '(여권변경)」으로 신고할 수 있습니다. 이름·생년월일·성별이 하나라도 바뀌었다면 반드시 '
              '출입국·외국인관서를 방문해야 합니다.',
          bodyEn: 'If only your passport number, issue date or expiry changed, '
              'you can report it through HiKorea e-application “Report of '
              'change of registration (passport change)”. If your name, date '
              'of birth or sex changed, you must visit the immigration office.',
          notes: [
            GuideNote(
              titleKo: '하이코리아 안내 기준',
              titleEn: 'What HiKorea lists',
              linesKo: [
                '전자민원: 여권 인적사항면 이미지 첨부, 수수료 없음, 업무일 기준 3일 이내 처리',
                '방문: 통합신청서·외국인등록증·여권, 즉시 처리',
                '전자민원 접수 시간: 07:00~22:00(토·일·공휴일 제외)',
                '이름·성별·생년월일·국적이 바뀌면 외국인등록증이 재발급됩니다.',
              ],
              linesEn: [
                'Online: attach an image of the passport photo page; no fee; '
                    'processed within 3 working days.',
                'In person: integrated application form, Residence Card and '
                    'passport; processed on the spot.',
                'Online applications accepted 07:00–22:00 (not at weekends or '
                    'on public holidays).',
                'If your name, sex, date of birth or nationality changes, a new '
                    'Residence Card is issued.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '늦었다면',
          titleEn: 'If you are late',
          iconName: 'warning',
          bodyKo: '기한을 넘겼더라도 알게 된 즉시 신고하세요. 제재 금액은 위반 기간에 따라 기준이 '
              '있지만 사정에 따라 줄거나 늘 수 있어, 얼마를 내게 될지는 출입국이 정합니다.',
          bodyEn: 'Even past the deadline, report as soon as you realise. There '
              'are standard amounts by how late you are, but they can be '
              'reduced or increased, so immigration decides what you pay.',
          notes: [
            GuideNote(
              titleKo: '법령의 기준액',
              titleEn: 'Standard amounts in the rules',
              linesKo: [
                '체류지 변경신고(벌금·범칙금 기준): 3개월 미만 10만원, 3~6개월 30만원, 6개월~1년 '
                    '50만원, 1~2년 70만원, 2년 이상 100만원',
                '외국인등록사항 변경신고(과태료 기준): 3개월 미만 10만원, 3~6개월 30만원, 6개월~1년 '
                    '50만원, 1년 이상 100만원',
                '기준액은 사정에 따라 2분의 1 범위에서 감경·가중될 수 있지만, 최종 금액은 법률상 '
                    '상한(100만원)을 넘을 수 없습니다.',
              ],
              linesEn: [
                'Change of address (fine / penalty-notice standard): under 3 '
                    'months ₩100,000; 3–6 months ₩300,000; 6 months–1 year '
                    '₩500,000; 1–2 years ₩700,000; 2 years or more ₩1 million.',
                'Change of registration (administrative fine standard): under '
                    '3 months ₩100,000; 3–6 months ₩300,000; 6 months–1 year '
                    '₩500,000; 1 year or more ₩1 million.',
                'The standard amount may be reduced or increased by up to half '
                    'for the circumstances, but the final amount cannot exceed '
                    'the statutory cap of ₩1 million.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '동아대 안내와 다른 점',
          titleEn: 'Where Dong-A’s page differs',
          iconName: 'info',
          bodyKo: '동아대학교 국제교류과 「VISA 정보」 페이지(게시일 표기 없음)는 등록사항 '
              '변경(체류지 변경) 신고를 「변경일로 14일 이내」, 「출입국관리사무소 직접신청(하이코리아 '
              '방문예약)」으로 안내합니다. 법은 전입한 날부터 15일 이내이고, 주민센터·시군구청에서도 '
              '신고할 수 있습니다. 여유를 두고 빨리 신고하되 신고처는 편한 곳을 고르세요.',
          bodyEn: 'Dong-A’s Office of International Affairs “VISA information” '
              'page (no posting date) says to report a change of address '
              '“within 14 days of the change” and “in person at the immigration '
              'office (HiKorea visit booking)”. The law gives 15 days from '
              'moving in, and you can also report at a community service centre '
              'or district office. Report early, at whichever office suits you.',
        ),
      ],
      tipsKo: [
        '외국인은 체류지 변경신고가 주민등록 전입신고를 대신합니다(출입국관리법 제88조의2).',
        '학교 포털(학생정보)에서 주소를 바꾸는 것만으로 출입국 신고가 된다는 공식 안내는 없습니다. '
            '출입국 신고는 따로 하세요.',
        '기숙사에 들어가거나 나와 다른 곳으로 옮기는 것도 체류지 변경입니다.',
        '대학 휴학 자체는 등록사항 변경신고 항목으로 규정돼 있지 않습니다. 학교를 옮기는 경우가 '
            '신고 대상입니다.',
        '체류기간 연장 등 다른 신청을 할 때도 새 주소 입증서류가 필요하니 계약서를 보관하세요.',
      ],
      tipsEn: [
        'For foreign residents, the change-of-address report takes the place '
            'of the resident move-in report (Immigration Act art. 88-2).',
        'No official guidance says that changing your address in the '
            'university portal counts as reporting to immigration. Report to '
            'immigration separately.',
        'Moving into a dormitory, or out of one to somewhere else, is also a '
            'change of address.',
        'Taking leave from university is not itself listed as a registration '
            'change; moving to a different school is.',
        'Other applications such as an extension of stay also ask for proof '
            'of your address, so keep your lease.',
      ],
      phrases: [
        GuidePhrase(
          ko: '이사해서 체류지 변경신고를 하려고 합니다.',
          en: 'I moved and want to report my change of address.',
        ),
        GuidePhrase(
          ko: '여권을 새로 받아서 외국인등록사항 변경신고를 하고 싶습니다.',
          en: 'I got a new passport and want to report the change to my '
              'registration.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '하이코리아 — 여권변경 신고 안내',
          labelEn: 'HiKorea — passport change report',
          descriptionKo: '전자민원 서류·처리기간(신청은 로그인 필요)',
          descriptionEn: 'Online documents and processing time (applying needs '
              'a login)',
          url: 'https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=1807',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '하이코리아 방문예약',
          labelEn: 'HiKorea visit booking',
          descriptionKo: '출입국·외국인관서 방문 전 예약',
          descriptionEn: 'Book before visiting the immigration office',
          url: 'https://www.hikorea.go.kr/resv/ResvIntroR.pt',
          iconName: 'event_repeat',
        ),
        GuideLink(
          labelKo: '생활법령 — 외국인등록 및 변경신고',
          labelEn: 'Easy-to-find Law — registration and change reports',
          descriptionKo: '법제처 외국인유학생 안내',
          descriptionEn: 'Ministry of Government Legislation guide for '
              'international students (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=2853&ccfNo=2&cciNo=3&cnpClsNo=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '가이드 — 교외주거 구하기',
          labelEn: 'Guide — Finding Off-Campus Housing',
          descriptionKo: '방을 구할 때 확인할 것',
          descriptionEn: 'What to check when you look for a room',
          url: '/guide/item/off-campus-housing',
          iconName: 'home_work',
        ),
        GuideLink(
          labelKo: '가이드 — 기숙사 신청',
          labelEn: 'Guide — Dormitory Application',
          descriptionKo: '입사·퇴사 일정',
          descriptionEn: 'Move-in and move-out dates',
          url: '/guide/item/dormitory',
          iconName: 'home_work',
        ),
        GuideLink(
          labelKo: '가이드 — 외국인등록증(ARC) 발급',
          labelEn: 'Guide — Residence Card (ARC)',
          descriptionKo: '처음 외국인등록을 할 때',
          descriptionEn: 'Registering for the first time',
          url: '/guide/item/arc-issue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 체류기간 연장',
          labelEn: 'Guide — Extension of Stay',
          descriptionKo: '연장 신청 때 주소 입증서류',
          descriptionEn: 'Address proof for an extension',
          url: '/guide/item/stay-extension',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 임대차 보증금 지키기',
          labelEn: 'Guide — Protecting Your Rental Deposit',
          descriptionKo: '교외로 이사할 때 보증금 보호',
          descriptionEn: 'Protecting your deposit when you move off campus',
          url: '/guide/item/rental-deposit-protection',
          iconName: 'home_work',
        ),
      ],
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // d10-job-seeking — 하이코리아 「체류민원 자격별 안내 매뉴얼」 2026-09-01판 구직(D-10)
    // 편(점수제 면제 특례·제한대상·제출서류·체류기간 상한·시간제 취업 특례·연수 신고)을 에이전트 A
    // 02/022가 정리하고 리드가 특례 문언(txt 7955~7971행)과 상한(9025행)을 다시 읽음. 수수료는
    // 시행규칙 제72조(변경 10만원)와 하이코리아 전자민원 CAT_SEQ=1809 표기(119,000원, 등록증
    // 발급·결제대행 포함)가 달라 금액을 단정하지 않는다. 졸업 전(학위 수여 전) 신청 가능 여부는
    // 매뉴얼 문언끼리 달라 미확정. 스터디인코리아의 「6개월씩 최대 2년」 표기는 매뉴얼과 달라
    // 쓰지 않고 차이만 알린다.
    AdminGuideItem(
      id: 'd10-job-seeking',
      categoryId: GuideCategory.immigration,
      searchAliasesKo: ['구직', '취업 비자', '졸업 후 취업', 'D-10', '구직비자'],
      searchAliasesEn: ['job seeking', 'job-seeking visa', 'D-10', 'after graduation work'],
      titleKo: '졸업 후 구직(D-10) 체류',
      titleEn: 'Job-Seeking Visa (D-10) after Graduation',
      detailTitleKo: '졸업 후 한국에서 일자리를 찾으려면 — 구직(D-10)',
      detailTitleEn: 'Staying On to Look for Work — Job-Seeking (D-10)',
      summaryKo: '전문 분야 구직·인턴용, 첫 변경은 점수제 면제 특례',
      summaryEn: 'For professional job-seeking and internships; first change '
          'skips the points test',
      iconName: 'work',
      overviewKo: '구직(D-10-1) 체류자격은 교수·회화지도·특정활동 등 전문 분야(E-1~E-7)에 '
          '취업하기 위해 한국에서 구직활동을 하거나, 정식 취업 전에 연수비를 받는 단기 인턴을 하는 '
          '사람을 위한 자격입니다. 단순 노무 일자리를 찾기 위한 자격이 아닙니다.\n\n'
          '현재 체류자격과 다른 자격의 활동을 하려면 미리 체류자격 변경허가를 받아야 하므로, '
          '졸업 후 한국에 남아 구직활동을 하려면 유학(D-2)에서 구직(D-10)으로 바꾸는 허가를 '
          '받아야 합니다. 취업이 확정되면 그 일에 맞는 체류자격으로 다시 바꿔야 합니다.',
      overviewEn: 'Job-seeking (D-10-1) status is for people looking for work '
          'in Korea in a professional field (E-1 to E-7, such as professor, '
          'conversation instructor or special activities), or doing a short '
          'paid internship before regular employment. It is not a status for '
          'finding simple-labour jobs.\n\n'
          'Doing the activities of a different status requires a change of '
          'status in advance, so to stay on after graduation and look for '
          'work you need permission to change from student (D-2) to '
          'job-seeking (D-10). When you are hired, you must change again to '
          'the status that fits the job.',
      topSections: [
        GuideSection(
          titleKo: '점수제를 면제받을 수 있나요?',
          titleEn: 'Do I skip the points test?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '✅ 점수제 면제 특례',
              titleEn: '✅ Points-test exemptions',
              linesKo: [
                '국내 대학 졸업 후 첫 구직 변경: 국내 대학 전문학사 이상 학위과정 유학생(D-2)으로 '
                    '졸업해 학위를 받은 뒤 처음으로 D-10-1로 바꾸는 경우. 첫 체류기간은 1년이고, '
                    '연장할 때는 점수제를 적용합니다.',
                '졸업 후 출국했다가 졸업일부터 1년 안에 구직(D-10) 사증을 받는 경우도 면제 대상에 '
                    '포함됩니다. 다만 과거에 D-10을 받은 적이 있으면 첫 변경이 아니므로 점수제를 '
                    '적용합니다.',
                '한국어능력 우수자: 국내 정규 대학 전문학사 이상 학위를 받은 지 3년이 지나지 않았고 '
                    'TOPIK 4급 이상 유효 성적표나 사회통합프로그램 4단계 중간평가 합격(사전평가 '
                    '5단계 배정 포함)이 있는 경우',
              ],
              linesEn: [
                'First job-seeking change after graduating in Korea: you '
                    'studied a degree (associate or higher) at a Korean '
                    'university on D-2, graduated with the degree, and are '
                    'changing to D-10-1 for the first time. You get 1 year at '
                    'first; extensions use the points test.',
                'Leaving Korea after graduation and getting a job-seeking '
                    '(D-10) visa within 1 year of graduating also counts. But '
                    'if you have held D-10 before, it is not a first change and '
                    'the points test applies.',
                'Excellent Korean: within 3 years of receiving an associate or '
                    'higher degree from a regular Korean university, with a '
                    'valid TOPIK level 4+ score, or a pass in the KIIP level 4 '
                    'mid-term test (or placement at level 5 in the pre-test).',
              ],
            ),
            GuideNote(
              titleKo: '📊 그 밖에는 점수제',
              titleEn: '📊 Otherwise, the points test',
              linesKo: [
                '학사(국내 전문학사 포함) 이상 학위를 가진 국내 합법 체류자로, 구직 점수표 190점 중 '
                    '기본항목 20점 이상이고 총점 60점 이상이어야 합니다.',
                '학력 점수는 학위증만 인정되고 졸업증·수료증·자격증은 인정되지 않습니다.',
              ],
              linesEn: [
                'Lawful residents with a bachelor’s degree or higher (a '
                    'Korean associate degree counts) need at least 20 basic '
                    'points and 60 in total out of 190 on the job-seeking '
                    'points table.',
                'Only a degree certificate counts for education points — not a '
                    'graduation certificate, certificate of completion or other '
                    'qualification.',
              ],
            ),
          ],
          noticeKo: '최근 5년 안에 금고 이상의 형을 받았거나 출입국관리법 위반으로 강제퇴거·'
              '출국명령을 받은 경우, 최근 3년 안에 300만원 이상 벌금형을 받은 경우 등은 허가가 '
              '제한됩니다. 요건을 갖춰도 허가 여부는 심사로 정해집니다.',
          noticeEn: 'Permission is restricted if, for example, within the last 5 '
              'years you were sentenced to imprisonment or deported or ordered '
              'to leave for breaking the Immigration Act, or within the last 3 '
              'years fined ₩3 million or more. Even if you qualify, the review '
              'decides.',
          footnoteKo: '※ 하이코리아 「체류민원 자격별 안내 매뉴얼」(2026년 9월 게시) 구직(D-10) '
              '편 기준, 2026-09-13 확인.',
          footnoteEn: '※ Based on the job-seeking (D-10) chapter of the HiKorea '
              'stay manual by status (posted September 2026), checked '
              '2026-09-13.',
        ),
      ],
      checklistTitleKo: '제출서류 — 졸업 후 첫 구직 변경(점수제 면제)',
      checklistTitleEn: 'Documents — first change after graduating (no points '
          'test)',
      checklistKo: [
        '통합신청서, 사진, 여권(사본), 외국인등록증, 수수료',
        '구직활동 계획서(하이코리아 민원서식)',
        '국내 정규 대학 전문학사 이상 학위증(또는 졸업증명서)',
        '체류지 입증서류(임대차계약서 등)',
      ],
      checklistEn: [
        'Integrated application form, photo, passport (copy), Residence Card, '
            'fee',
        'Job-seeking activity plan (HiKorea forms)',
        'Degree certificate (or graduation certificate) from a regular Korean '
            'university, associate or higher',
        'Proof of address (such as your lease)',
      ],
      checklistOptionalTitleKo: '점수제로 신청한다면 더 필요해요',
      checklistOptionalTitleEn: 'Also needed on the points test',
      checklistOptionalKo: [
        '점수표 항목을 증명하는 서류(한국어능력·경력 등 해당자)',
        '체재비 입증서류 — 「연도별 1인 가구 주거급여 기준액 × 체류개월 수」 이상이 예치된 '
            '은행잔고증명서 등',
      ],
      checklistOptionalEn: [
        'Proof for the points you claim (Korean ability, work experience and '
            'so on, where relevant)',
        'Proof of living costs — such as a bank balance certificate of at '
            'least “the yearly single-person housing benefit standard × the '
            'months of stay”',
      ],
      checklistNoteKo: '※ 졸업 후 첫 구직 변경 특례자는 체재비 입증서류 제출이 면제됩니다. '
          '수수료는 시행규칙(체류자격 변경허가 10만원)과 하이코리아 전자민원 표기(119,000원, '
          '외국인등록증 발급·결제대행 수수료 포함)가 달라, 신청 화면이나 1345에서 확인하세요.',
      checklistNoteEn: '※ The first-change exemption also waives proof of '
          'living costs. The fee differs between the Enforcement Rules (change '
          'of status ₩100,000) and HiKorea e-application (₩119,000 including '
          'the Residence Card and payment-processing fees), so check it on the '
          'application screen or with 1345.',
      stepsKo: [
        '졸업(학위 수여) 일정과 외국인등록증의 체류기간 만료일 확인',
        '점수제 면제 특례에 해당하는지, 아니면 점수제인지 확인',
        '구직활동 계획서와 학위증·체류지 입증서류 등 준비',
        '신분이 바뀌는 즉시 하이코리아 전자민원 또는 관할 출입국·외국인관서 방문으로 체류자격 '
            '변경허가 신청',
        '허가 후 구직활동 — 인턴을 시작하거나 연수기관을 바꾸면 15일 안에 신고',
        '취업이 확정되면 그 일에 맞는 체류자격(E-1~E-7 등)으로 변경',
      ],
      stepsEn: [
        'Check your graduation (degree conferral) date and the expiry date '
            'on your Residence Card.',
        'Check whether you fall under a points-test exemption or need the '
            'points test.',
        'Prepare the job-seeking plan, degree certificate, proof of address '
            'and the rest.',
        'As soon as your status changes, apply for a change of status through '
            'HiKorea e-application or at your immigration office.',
        'Look for work once permitted — if you start an internship or change '
            'the host organisation, report it within 15 days.',
        'When you are hired, change to the status that fits the job (E-1 to '
            'E-7 and so on).',
      ],
      sections: [
        GuideSection(
          titleKo: '얼마나 머물 수 있나요?',
          titleEn: 'How long can I stay?',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '체류기간',
              titleEn: 'Period of stay',
              linesKo: [
                '한 번에 주는 기간은 원칙적으로 1년이며, 점수제 60~80점 미만 등은 한 번에 최대 '
                    '6개월입니다.',
                '누적 상한은 최대 3년이고 점수·특례 대상에 따라 차등을 둡니다(60~80점 미만은 '
                    '1년).',
                '국내 체류기간은 합산하며, 완전히 출국했다가 사증을 받아 다시 들어오면 새로 '
                    '계산합니다.',
              ],
              linesEn: [
                'Each grant is normally 1 year; for, e.g., 60 to under 80 '
                    'points it is at most 6 months at a time.',
                'The overall cap is at most 3 years, tiered by points and '
                    'exemption (1 year for 60 to under 80 points).',
                'Time in Korea is added up; if you leave for good and come back '
                    'on a new visa, the count restarts.',
              ],
            ),
          ],
          footnoteKo: '※ 스터디인코리아 안내에는 「6개월씩 최대 2년」으로 적혀 있어 2026년 9월 '
              '매뉴얼과 다릅니다. 신청 전 하이코리아나 1345에서 최신 기준을 확인하세요.',
          footnoteEn: '※ Study in Korea still says “6 months at a time, up to 2 '
              'years”, which differs from the September 2026 manual. Check the '
              'current rule with HiKorea or 1345 before applying.',
        ),
        GuideSection(
          titleKo: 'D-10으로 할 수 있는 일과 없는 일',
          titleEn: 'What D-10 does and does not allow',
          iconName: 'gavel',
          notes: [
            GuideNote(
              titleKo: '인턴',
              titleEn: 'Internships',
              linesKo: [
                '정식 취업 전 연수비를 받는 단기 인턴은 활동 범위에 포함됩니다. 같은 기업 인턴은 '
                    '한 번에 최대 1년입니다.',
                '인턴을 시작하거나 연수기관을 바꾸면 사유가 생긴 날부터 15일 안에 외국인등록사항 '
                    '변경신고를 합니다.',
              ],
              linesEn: [
                'Short paid internships before regular employment are within '
                    'the status. An internship at the same company is up to 1 '
                    'year at a time.',
                'If you start an internship or change the host organisation, '
                    'report a change of registration within 15 days.',
              ],
            ),
            GuideNote(
              titleKo: '아르바이트(시간제 취업)',
              titleEn: 'Part-time work',
              linesKo: [
                '유학생 시간제취업 허가는 이어지지 않습니다. D-10-1의 시간제 취업은 별도 특례로, '
                    '국내 대학 전문학사 이상 학위를 받은 지 3년 미만이고 과거 E-1~E-7 체류 이력이 '
                    '없는 등 요건을 모두 갖춘 사람에게만 적용됩니다.',
                '분야는 제조업과 농업으로 제한됩니다. 농업은 어학 요건이 없지만, 제조업은 '
                    '사회통합프로그램 4단계 이상 이수자만 가능하며 TOPIK 성적만으로는 제조업 허가 '
                    '대상이 되지 않습니다.',
                '허가 시 주중 25시간(사회통합프로그램 5단계 이상 30시간), 주말·공휴일은 시간 '
                    '제한이 없고, 체류자격외 활동허가라 수수료가 있습니다. 허가 전에 일하면 구직자와 '
                    '고용주 모두 처벌될 수 있습니다.',
              ],
              linesEn: [
                'Student part-time permission does not carry over. Part-time '
                    'work on D-10-1 is a separate exception that applies only '
                    'if you meet every condition, including a Korean associate '
                    'degree or higher received less than 3 years ago and no '
                    'previous E-1 to E-7 stay.',
                'It is limited to manufacturing and agriculture. Agriculture '
                    'has no language requirement, but manufacturing is only for '
                    'people who completed KIIP level 4 or higher — TOPIK alone '
                    'does not qualify you for manufacturing.',
                'If permitted: 25 weekday hours (30 with KIIP level 5+), no '
                    'limit at weekends and on public holidays; it is permission '
                    'for activities outside your status, so there is a fee. '
                    'Working before permission can get both you and the '
                    'employer penalised.',
              ],
            ),
          ],
          noticeKo: 'D-10은 전문 분야 구직을 위한 자격입니다. 단순 노무 일을 하거나 허가 없이 '
              '일하면 체류에 불이익이 생길 수 있습니다.',
          noticeEn: 'D-10 is for looking for professional work. Doing simple '
              'labour, or working without permission, can harm your stay.',
        ),
        GuideSection(
          titleKo: '아직 확인이 필요한 점',
          titleEn: 'Still to confirm',
          iconName: 'info',
          bodyKo: '매뉴얼의 특례 문구는 「졸업하여 학위 취득한 후」인데, 같은 매뉴얼의 신청 요령은 '
              '「신분이 변동(예정 포함)되는 즉시」 신청하라고 적고 있습니다. 학위 수여 전에 졸업예정 '
              '서류로 신청할 수 있는지, 수료(학위 미취득)만 한 경우 D-10이 가능한지는 1345나 '
              '관할 출입국·외국인관서에 확인하세요.',
          bodyEn: 'The manual’s exemption says “after graduating and receiving '
              'the degree”, while its application tips say to apply “as soon as '
              'your status changes (including when it is about to)”. Ask 1345 '
              'or your immigration office whether you can apply before the '
              'degree is conferred with proof of expected graduation, and '
              'whether completing coursework without a degree qualifies.',
        ),
      ],
      tipsKo: [
        '유학(D-2) 체류기간이 끝나기 전에 준비하세요. 졸업 일정과 만료일이 가깝다면 미리 1345에 '
            '신청 시기를 확인하세요.',
        '학위증·졸업증명서 발급은 증명서 발급 가이드를 참고하세요.',
        '한국을 떠날 계획이라면 출국 전 행정 정리도 함께 챙기세요.',
      ],
      tipsEn: [
        'Prepare before your student (D-2) period of stay ends. If graduation '
            'and the expiry date are close, ask 1345 early about when to '
            'apply.',
        'For degree and graduation certificates, see the certificate guide.',
        'If you plan to leave Korea instead, sort out your pre-departure '
            'paperwork too.',
      ],
      phrases: [
        GuidePhrase(
          ko: '졸업 후 구직(D-10) 체류자격으로 변경하려고 합니다. 점수제 면제 대상인지 확인하고 '
              '싶습니다.',
          en: 'I want to change to job-seeking (D-10) status after graduation. '
              'I would like to check whether I am exempt from the points test.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '하이코리아 — 체류자격 변경허가 안내',
          labelEn: 'HiKorea — change of status of stay',
          descriptionKo: '등록외국인 전자민원 안내(신청은 로그인 필요)',
          descriptionEn: 'E-application guide for registered foreigners '
              '(applying needs a login)',
          url: 'https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=1809',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '체류자격별 안내 매뉴얼',
          labelEn: 'Stay manual by status (HiKorea)',
          descriptionKo: '구직(D-10) 편 — 점수표·제출서류',
          descriptionEn: 'Job-seeking (D-10) chapter — points table and '
              'documents (Korean)',
          url: 'https://www.hikorea.go.kr/board/BoardNtcDetailR.pt?BBS_SEQ=1&BBS_GB_CD=BS10&NTCCTT_SEQ=1062&page=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '하이코리아 방문예약',
          labelEn: 'HiKorea visit booking',
          descriptionKo: '출입국·외국인관서 방문 전 예약',
          descriptionEn: 'Book before visiting the immigration office',
          url: 'https://www.hikorea.go.kr/resv/ResvIntroR.pt',
          iconName: 'event_repeat',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '학위·졸업증명서',
          descriptionEn: 'Degree and graduation certificates',
          url: '/guide/item/certificate-issue',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: '재학 중 아르바이트 규칙과의 차이',
          descriptionEn: 'How student part-time rules differ',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 비자 종류 안내',
          labelEn: 'Guide — Visa types',
          descriptionKo: '체류자격 기본 설명',
          descriptionEn: 'Status-of-stay basics',
          url: '/guide/item/visa-types',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 귀국·출국 전 행정 정리',
          labelEn: 'Guide — Before You Leave Korea',
          descriptionKo: '한국을 떠나기로 했다면',
          descriptionEn: 'If you decide to leave Korea',
          url: '/guide/item/departure-checklist',
          iconName: 'flight_takeoff',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업요건 확인',
          labelEn: 'Guide — Checking Graduation Requirements',
          descriptionKo: '졸업·학위 수여 요건 확인',
          descriptionEn: 'Checking you will graduate with a degree',
          url: '/guide/item/graduation-requirements',
          iconName: 'fact_check',
        ),
      ],
      difficulty: 3,
      status: GuideStatus.published,
    ),

    // tuition-payment — 동아대 「등록금 납부안내」(MN159)를 2026-09-13 리드가 원문으로 다시
    // 읽음(에이전트 A 02/022와 일치). 분할납부는 2026-2학기 공지(MN170 board_seq 8510036,
    // 2026-08-19) 기준 제도 설명만 옮기고 날짜는 학기마다 바뀌어 적지 않는다. 가상계좌 이용
    // 시간·납부확인 문자·경리과 번호는 2025-2학기 공지(8402837) 기준이라 「직전 공지 기준」으로
    // 표시한다. 2026-2 정규 등록 공지·해외 송금·카드 납부 조건은 찾지 못해 단정하지 않는다.
    // 학기초과자·학위취득유예생 비율표는 셀 병합으로 열 대응이 불명확해 수치를 옮기지 않는다.
    AdminGuideItem(
      id: 'tuition-payment',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['등록금', '학비', '등록금 납부', '분할납부', '고지서'],
      searchAliasesEn: ['tuition', 'fees', 'tuition payment', 'installment'],
      titleKo: '등록금 납부·등록 확인',
      titleEn: 'Paying Tuition & Confirming Registration',
      summaryKo: '고지서 출력 → 기간 내 납부 → 다음 날 납입확인서 확인',
      summaryEn: 'Print the bill → pay on time → check the receipt the next day',
      iconName: 'payments',
      overviewKo: '매 학기 고지된 등록금을 기간 안에 내야 등록이 됩니다. 기간 안에 내지 않으면 '
          '미등록제적 대상이 되고, 외국인 유학생은 제적이 체류에도 영향을 줍니다. 전액 장학금 '
          '등으로 납부액이 0원이라면 고지서와 해당 학기 공지에서 별도 등록 절차가 있는지 '
          '확인하세요.\n\n'
          '동아대학교는 학기마다 등록 일정을 홈페이지 공지사항으로 알리므로, 이 가이드의 기본 '
          '절차와 함께 해당 학기 공지를 꼭 확인하세요.',
      overviewEn: 'You are registered for a semester only once the billed '
          'tuition is paid on time. If you do not pay within the period you '
          'can be dismissed for non-registration, and for international '
          'students dismissal also affects your stay. If your bill is ₩0 '
          'because of a full scholarship, check the bill and that semester’s '
          'notice for any separate registration step.\n\n'
          'Dong-A announces each semester’s dates in its website notices, so '
          'check that semester’s notice alongside the basic steps here.',
      topSections: [
        GuideSection(
          titleKo: '언제, 누가 내나요?',
          titleEn: 'When, and who pays?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '📅 납부기간',
              titleEn: '📅 Payment period',
              linesKo: [
                '1학기는 2월 말, 2학기는 8월 말 — 정확한 날짜는 해당 학기 홈페이지 공지사항',
                '대상: 해당 학기 재학생·복학생, 학기초과자, 학사학위취득유예생, 재입학생 등',
                '신입생은 입학관리과 홈페이지 안내를 따릅니다.',
              ],
              linesEn: [
                'Spring semester: end of February; autumn: end of August — '
                    'exact dates in that semester’s website notice.',
                'Who: continuing and returning students, extra-semester '
                    'students, students deferring their degree, readmitted '
                    'students and others.',
                'New students follow the Admissions Office website.',
              ],
            ),
          ],
          noticeKo: '복학생은 복학 신청 후 학적이 「재학」으로 바뀐 뒤부터 등록금을 낼 수 '
              '있습니다.',
          noticeEn: 'Returning students can pay tuition only after applying to '
              'return and their status changes to “enrolled”.',
          noticeIconName: 'info',
          footnoteKo: '※ 동아대학교 「등록금 납부안내」 기준, 2026-09-13 확인.',
          footnoteEn: '※ Based on Dong-A’s “Tuition payment” page, checked '
              '2026-09-13.',
        ),
      ],
      checklistTitleKo: '납부 전에 준비할 것',
      checklistTitleEn: 'Before you pay',
      checklistKo: [
        '학생정보(통합정보시스템)에 로그인할 수 있는 학교 계정',
        '등록금고지서 — 학교홈페이지 › 학생정보 › 등록장학 › 등록금고지서 발급에서 출력',
        '고지서에 적힌 금액과 가상계좌 번호',
        '수납은행(부산은행·농협은행) 창구 방문 또는 인터넷뱅킹·폰뱅킹·ATM',
      ],
      checklistEn: [
        'Your university account for Student Information (the integrated '
            'information system)',
        'The tuition bill — print it at university website › Student '
            'Information › Registration & Scholarships › Tuition bill',
        'The amount and virtual account number on the bill',
        'A counter at a receiving bank (BNK Busan Bank or NongHyup Bank), or '
            'internet/phone banking or an ATM',
      ],
      checklistNoteKo: '※ 학기초과자·학사학위취득유예생은 수강신청 학점에 따라 등록금이 '
          '달라지고, 수강신청을 하지 않으면 학기초과자는 전액, 유예생은 5.5%가 고지됩니다. '
          '학점별 비율은 등록금 납부안내 페이지의 표에서 확인하세요.',
      checklistNoteEn: '※ For extra-semester and degree-deferral students, '
          'tuition depends on the credits you register for; with no courses, '
          'extra-semester students are billed in full and deferral students '
          '5.5%. See the table on the tuition payment page for the ratios.',
      stepsKo: [
        '해당 학기 등록금 납부 공지에서 기간 확인',
        '학생정보 › 등록장학 › 등록금고지서 발급에서 고지서 출력',
        '기간 안에 부산은행·농협은행 창구에서 내거나, 고지서의 가상계좌로 인터넷뱅킹·폰뱅킹·'
            'ATM 이체',
        '납부한 다음 날부터 학생정보 › 등록장학 › 등록장학내역조회에서 납부 확인',
        '등록금 납입확인서(영수증) 출력·보관',
        '등록금을 냈다면 기간 안에 수강신청까지 마치기',
      ],
      stepsEn: [
        'Check the dates in that semester’s tuition notice.',
        'Print the bill at Student Information › Registration & '
            'Scholarships › Tuition bill.',
        'Within the period, pay at a BNK Busan Bank or NongHyup counter, or '
            'transfer to the virtual account on the bill by internet or phone '
            'banking or at an ATM.',
        'From the day after paying, check it at Student Information › '
            'Registration & Scholarships › Registration history.',
        'Print and keep the tuition payment certificate (receipt).',
        'Once paid, finish course registration within its period too.',
      ],
      sections: [
        GuideSection(
          titleKo: '가상계좌로 낼 때',
          titleEn: 'Paying to the virtual account',
          iconName: 'account_balance',
          notes: [
            GuideNote(
              titleKo: '직전 학기 공지(2025-2학기) 기준',
              titleEn: 'Per the previous notice (autumn 2025)',
              linesKo: [
                '가상계좌는 학생별로 번호가 따로 있어, 보내는 사람 이름과 관계없이 수납됩니다.',
                '이용 시간은 09:00~16:00이었고, 필수 경비를 포함해 합계 금액이 고지서와 정확히 '
                    '맞아야 수납됩니다.',
                '고지서는 우편·팩스로 보내지 않으며 인터넷에서 직접 출력합니다. 납부 후에는 '
                    '고지서 대신 납입확인서를 출력합니다.',
              ],
              linesEn: [
                'Each student has their own virtual account number, so payment '
                    'is matched regardless of the sender’s name.',
                'The account was available 09:00–16:00, and the total must '
                    'match the bill exactly (including the required fees) for '
                    'the payment to go through.',
                'Bills are not posted or faxed — you print them online. After '
                    'paying, print the payment certificate instead of the bill.',
              ],
            ),
          ],
          noticeKo: '이용 시간과 조건은 학기마다 바뀔 수 있으니 해당 학기 공지에서 다시 '
              '확인하세요.',
          noticeEn: 'Hours and conditions can change each semester — check '
              'them again in that semester’s notice.',
        ),
        GuideSection(
          titleKo: '나눠서 내고 싶다면 — 분할납부',
          titleEn: 'Paying in instalments',
          iconName: 'event_repeat',
          bodyKo: '학부 재학생·복학생은 학기 시작 전에 정해진 기간 안에 신청하면 등록금을 최대 '
              '4회로 나눠 낼 수 있습니다(대학원생 제외). 신청 기간이 정규 등록보다 앞서므로 공지를 '
              '미리 확인하세요.',
          bodyEn: 'Undergraduate continuing and returning students can split '
              'tuition into up to 4 payments if they apply within a set period '
              'before the semester (not graduate students). The application '
              'period comes before regular registration, so watch for the '
              'notice.',
          notes: [
            GuideNote(
              titleKo: '2026-2학기 공지 기준',
              titleEn: 'Per the autumn 2026 notice',
              linesKo: [
                '신청: 학생정보서비스 › 등록 장학 › 등록금분할납부 신청',
                '분할납부는 부산은행(가상계좌 가능)으로만 낼 수 있습니다.',
                '제외: 편입생·재입학생·학기초과자·학위취득유예자·학자금대출자·교류학생·카드수납 '
                    '예정자·국가장학금 외 교외장학금 수혜자·직전 분할납부 연체자',
                '회차별 기한까지 내지 않으면 제적될 수 있습니다. 분할을 취소하고 한 번에 내려면 '
                    '경리과에 연락합니다.',
              ],
              linesEn: [
                'Apply: Student Information Service › Registration & '
                    'Scholarships › Tuition instalment application.',
                'Instalments can be paid only at BNK Busan Bank (virtual '
                    'account allowed).',
                'Not eligible: transfer and readmitted students, extra-semester '
                    'and degree-deferral students, student-loan borrowers, '
                    'exchange students, those planning to pay by card, '
                    'recipients of outside scholarships other than the national '
                    'scholarship, and anyone late on a previous instalment plan.',
                'Missing an instalment deadline can lead to dismissal. To cancel '
                    'and pay in one go, contact the Accounting Office.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '확인이 필요한 경우',
          titleEn: 'When to check with the university',
          iconName: 'info',
          bodyKo: '해외 송금이나 카드 납부 조건을 적은 학교 공식 안내는 찾지 못했습니다. 중국인 '
              '유학생 대상으로는 국제교류과가 알리페이 등록금 납부 안내를 올린 적이 있지만 수수료·'
              '환율 조건은 적혀 있지 않습니다. 고지서 금액이 장학금 반영 결과와 다르거나, 납부했는데 '
              '다음 날에도 확인되지 않으면 기간이 끝나기 전에 경리과에 문의하세요.',
          bodyEn: 'We found no official university guidance on paying from '
              'abroad or by card. For Chinese students, the international office '
              'has posted an Alipay tuition payment guide, but it gives no fee '
              'or exchange-rate terms. If the bill does not reflect your '
              'scholarship, or a payment still is not shown the next day, '
              'contact the Accounting Office before the period ends.',
          footnoteKo: '※ 2025-2학기 공지의 등록금 문의처: 경리과 051-200-6702~3',
          footnoteEn: '※ Tuition enquiries in the autumn 2025 notice: '
              'Accounting Office, 051-200-6702~3',
        ),
      ],
      tipsKo: [
        '등록금을 냈더라도 수강신청을 하지 않으면 미수강제적 대상입니다.',
        '등록 후 휴학하면 등록금은 돌려받지 않고 다음 등록으로 이월됩니다(신청 시점에 따라 '
            '비율이 다름). 자퇴 환불 기준은 따로 있습니다.',
        '연말정산용 교육비납입증명서는 다음 해 1월경부터 발급됩니다.',
        '비자연장 등에서 등록금 납입 증빙이 필요하면 납입확인서를 출력해 두세요.',
      ],
      tipsEn: [
        'Even with tuition paid, not registering for courses can get you '
            'dismissed.',
        'If you take leave after registering, tuition is carried over to your '
            'next registration rather than refunded (the share depends on '
            'when you apply). Withdrawal has its own refund rules.',
        'The education-expense certificate for year-end tax settlement is '
            'available from around January of the following year.',
        'If a visa extension or similar asks for proof of tuition, print the '
            'payment certificate.',
      ],
      phrases: [
        GuidePhrase(
          ko: '등록금을 냈는데 납부 확인이 되지 않습니다. 확인 부탁드립니다.',
          en: 'I paid my tuition but it is not showing as paid. Could you '
              'check it?',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대 등록금 납부안내',
          labelEn: 'Dong-A tuition payment guide',
          descriptionKo: '납부기간·은행·고지서·납입확인서·학기초과자 표',
          descriptionEn: 'Periods, banks, bills, receipts and the '
              'extra-semester table (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN159',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '동아대 공지사항',
          labelEn: 'Dong-A notices',
          descriptionKo: '학기별 등록금 납부·분할납부 공지',
          descriptionEn: 'Each semester’s tuition and instalment notices '
              '(Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Board/Board.do?mCode=MN170',
          iconName: 'info',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '등록 후 수강신청과 미수강제적',
          descriptionEn: 'Registering for courses after paying',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 휴학·복학·자퇴와 체류',
          labelEn: 'Guide — Leave, Return, Withdrawal & Your Stay',
          descriptionKo: '휴학 시 이월, 자퇴 시 환불',
          descriptionEn: 'Carry-over on leave, refunds on withdrawal',
          url: '/guide/item/academic-status-and-visa',
          iconName: 'event_busy',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '등록금 납입 확인서 발급',
          descriptionEn: 'Getting a tuition payment certificate',
          url: '/guide/item/certificate-issue',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업요건 확인',
          labelEn: 'Guide — Checking Graduation Requirements',
          descriptionKo: '학기초과·학위취득 유예 판단',
          descriptionEn: 'Extra semesters and degree deferral',
          url: '/guide/item/graduation-requirements',
          iconName: 'fact_check',
        ),
      ],
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // residence-card-reissue — 출입국관리법 시행령 제42조(재발급 사유·서류, 현행 조문에 신청
    // 기한 없음), 시행규칙 제48조의2(모바일 외국인등록증), 하이코리아 매뉴얼 2026-09-01판
    // 수수료(215행 3만5천원, 2605행 면제 대상자도 납부) — 조사 코덱스 04/007. 분실 직후 행동
    // (하이코리아 분실신고·24시간 철회·현금 수납·사진 규격)은 기존 incident-response가 이미
    // 감사를 거쳐 담고 있어 여기서는 연결하고 반복하지 않는다. 온라인 재발급 가능 여부·처리기간·
    // 사실증명의 임시 신분증 인정 범위는 확인하지 못해 단정하지 않는다.
    AdminGuideItem(
      id: 'residence-card-reissue',
      categoryId: GuideCategory.immigration,
      searchAliasesKo: ['분실', '등록증 분실', '외국인등록증 분실', '재발급', '잃어버렸어요'],
      searchAliasesEn: ['lost card', 'lost residence card', 'reissue', 'replacement card'],
      titleKo: '외국인등록증 재발급',
      titleEn: 'Replacing Your Residence Card',
      detailTitleKo: '외국인등록증을 잃어버렸거나 새로 받아야 할 때',
      detailTitleEn: 'Lost Your Residence Card, or Need a New One?',
      summaryKo: '분실·훼손·인적사항 변경 등 사유별로 관할 출입국에 신청',
      summaryEn: 'Apply to your immigration office — loss, damage, changed '
          'details and more',
      iconName: 'badge',
      overviewKo: '외국인등록증을 잃어버렸거나 망가졌을 때, 또는 이름·국적 등이 바뀌어 카드를 '
          '새로 받아야 할 때는 체류지 관할 출입국·외국인관서에 재발급을 신청합니다.\n\n'
          '분실 신고는 카드가 부정하게 쓰이지 않도록 알리는 절차일 뿐, 새 카드를 받는 신청이 '
          '아닙니다. 분실 직후 할 일은 사건·사고 대응 가이드를, 재발급 신청은 이 가이드를 '
          '보세요.',
      overviewEn: 'If your Residence Card is lost or damaged, or you need a new '
          'one because your name, nationality or other details changed, apply '
          'for a replacement at the immigration office for your address.\n\n'
          'A loss report only records the loss to prevent misuse — it is not '
          'an application for a new card. For what to do right after losing '
          'it, see the incident response guide; for the replacement itself, '
          'use this guide.',
      topSections: [
        GuideSection(
          titleKo: '재발급을 받는 경우',
          titleEn: 'When a card is reissued',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '📋 재발급 사유(시행령 제42조)',
              titleEn: '📋 Grounds (Enforcement Decree art. 42)',
              linesKo: [
                '분실했거나 훼손된 경우',
                '카드의 기재란이 부족한 경우',
                '체류자격 변경허가를 받은 경우',
                '성명·성별·생년월일·국적이 바뀌어 변경신고를 한 경우',
                '카드를 일괄 갱신해야 하는 경우',
              ],
              linesEn: [
                'It was lost or damaged.',
                'There is no more room on the card for entries.',
                'You were granted a change of status of stay.',
                'You reported a change of name, sex, date of birth or '
                    'nationality.',
                'Cards have to be renewed all at once.',
              ],
            ),
          ],
          noticeKo: '주소·여권·학교가 바뀐 것만으로는 새 카드 사유가 아닐 수 있습니다. 먼저 '
              '변경신고를 하고, 카드 교체가 필요한지는 신고할 때 확인하세요.',
          noticeEn: 'A new address, passport or school alone may not mean a new '
              'card. Report the change first and ask whether the card needs '
              'replacing when you do.',
          noticeIconName: 'info',
          footnoteKo: '※ 출입국관리법 시행령 제42조와 하이코리아 「체류민원 자격별 안내 매뉴얼」'
              '(2026년 9월 게시) 기준, 2026-09-13 확인.',
          footnoteEn: '※ Based on Enforcement Decree art. 42 and the HiKorea '
              'stay manual by status (posted September 2026), checked '
              '2026-09-13.',
        ),
      ],
      checklistKo: [
        '외국인등록증 재발급 신청서(통합신청서)',
        '사진 1장 — 최근 6개월 이내 촬영한 3.5×4.5cm 정면 사진',
        '여권',
        '수수료 35,000원(현금)',
        '분실이 아닌 사유라면 원래 외국인등록증',
      ],
      checklistEn: [
        'Residence Card reissue application (integrated application form)',
        'One photo — front-facing, 3.5 × 4.5 cm, taken within the last 6 '
            'months',
        'Passport',
        'Fee: ₩35,000 (cash)',
        'For any reason other than loss, your current Residence Card',
      ],
      checklistNoteKo: '※ 수수료 면제 대상자(정부초청장학생 등)도 외국인등록증 발급·재발급 '
          '수수료는 내야 합니다. 분실 사유를 설명하는 자료처럼 추가로 요구될 수 있는 서류는 '
          '하이코리아나 1345에서 확인하세요.',
      checklistNoteEn: '※ Even people exempt from other fees (such as government '
          'scholarship students) pay the card issue and reissue fee. Check '
          'any extra documents that may be asked for — such as a note '
          'explaining the loss — with HiKorea or 1345.',
      stepsKo: [
        '분실이라면 먼저 사건·사고 대응 가이드에 따라 분실 신고와 습득물 확인',
        '재발급 사유와 필요한 서류 확인',
        '체류지 관할 출입국·외국인관서 방문 — 하이코리아 방문예약 확인',
        '신청서·사진·여권·수수료(분실 외 사유는 기존 카드) 제출',
        '새 카드를 받은 뒤, 모바일 외국인등록증을 쓰고 있었다면 모바일 카드도 다시 발급',
      ],
      stepsEn: [
        'If it was lost, first follow the incident response guide: report '
            'the loss and check lost-and-found.',
        'Confirm the reason for reissue and the documents you need.',
        'Visit the immigration office for your address — check HiKorea visit '
            'booking.',
        'Submit the form, photo, passport and fee (and the old card, for '
            'reasons other than loss).',
        'Once you have the new card, if you used a mobile Residence Card, get '
            'the mobile card reissued too.',
      ],
      sections: [
        GuideSection(
          titleKo: '기한과 기다리는 동안',
          titleEn: 'Deadlines, and while you wait',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '신청 기한',
              titleEn: 'Deadline',
              linesKo: [
                '현행 시행령 제42조에는 재발급 신청 기한이 적혀 있지 않습니다. 예전 조문의 '
                    '「14일 이내」는 현재 규정이 아닙니다.',
                '다만 카드는 신분 증명에 계속 쓰이므로 미루지 말고 가능한 한 빨리 신청하세요.',
                '이름·국적 등 등록사항이 바뀐 경우의 변경신고는 15일 기한이 따로 있습니다.',
              ],
              linesEn: [
                'The current Enforcement Decree art. 42 sets no deadline for '
                    'applying. The old “within 14 days” wording is no longer '
                    'the rule.',
                'Your card is still your ID, though, so apply as soon as you '
                    'can.',
                'Reporting a change of name, nationality and similar details '
                    'has its own 15-day deadline.',
              ],
            ),
            GuideNote(
              titleKo: '카드가 없는 동안',
              titleEn: 'Without a card',
              linesKo: [
                '외국인등록 사실증명을 발급받을 수 있지만, 은행·통신사·병원 등이 이를 등록증 대신 '
                    '인정하는지는 제출처마다 다르므로 먼저 확인하세요.',
                '처리 기간과 카드 수령 방법은 신청할 때 관서에 확인하세요.',
              ],
              linesEn: [
                'You can get a certificate of foreign resident registration, '
                    'but whether a bank, phone company or hospital accepts it '
                    'instead of the card is up to each of them — ask first.',
                'Ask the office about processing time and how you will collect '
                    'the card when you apply.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '모바일 외국인등록증',
          titleEn: 'Mobile Residence Card',
          iconName: 'smartphone',
          bodyKo: '모바일 외국인등록증은 실물 카드와 같은 효력이 있고, 14세 이상 등록외국인이 '
              '본인 명의 스마트폰 1대에만 발급받을 수 있습니다. 유효기간은 체류기간 만료일까지이며, '
              '실물 카드를 재발급받으면 모바일 카드도 재발급 사유가 됩니다.',
          bodyEn: 'A mobile Residence Card has the same legal effect as the '
              'physical card. Registered foreigners aged 14 or over can get one '
              'on a single smartphone in their own name. It is valid until your '
              'period of stay expires, and when the physical card is reissued '
              'the mobile card has to be reissued as well.',
          footnoteKo: '※ 모바일 카드가 있어도 실물 카드 재발급을 생략해도 된다는 공식 안내는 '
              '확인하지 못했습니다.',
          footnoteEn: '※ We found no official guidance saying a mobile card lets '
              'you skip replacing the physical card.',
        ),
      ],
      tipsKo: [
        '경찰에 낸 분실 신고는 출입국 재발급 신청을 대신하지 않습니다.',
        '도난이나 범죄 피해라면 112에 신고하세요.',
        '출국할 때 외국인등록증이 필요할 수 있으니, 출국 예정이 있다면 재발급 일정과 반납 여부를 '
            '함께 확인하세요.',
      ],
      tipsEn: [
        'A loss report to the police does not replace applying to immigration '
            'for a new card.',
        'If it was stolen or you were a victim of crime, call 112.',
        'You may need the card when you leave Korea, so if you are travelling '
            'soon, check reissue timing and whether you must hand it in.',
      ],
      phrases: [
        GuidePhrase(
          ko: '외국인등록증을 잃어버려서 재발급을 신청하려고 합니다.',
          en: 'I lost my Residence Card and want to apply for a new one.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '가이드 — 사건·사고 대응',
          labelEn: 'Guide — Incident Response',
          descriptionKo: '분실 직후 할 일과 하이코리아 분실 신고',
          descriptionEn: 'What to do right after a loss, and the HiKorea loss '
              'report',
          url: '/guide/item/incident-response',
          iconName: 'local_police',
        ),
        GuideLink(
          labelKo: '가이드 — 체류지·등록사항 변경신고',
          labelEn: 'Guide — Reporting Address & Registration Changes',
          descriptionKo: '이름·국적·여권이 바뀐 경우의 15일 신고',
          descriptionEn: '15-day report when your name, nationality or passport '
              'changes',
          url: '/guide/item/address-and-registration-changes',
          iconName: 'edit_location_alt',
        ),
        GuideLink(
          labelKo: '가이드 — 외국인등록증(ARC) 발급',
          labelEn: 'Guide — Residence Card (ARC)',
          descriptionKo: '처음 발급받을 때',
          descriptionEn: 'Getting your first card',
          url: '/guide/item/arc-issue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '하이코리아 방문예약',
          labelEn: 'HiKorea visit booking',
          descriptionKo: '출입국·외국인관서 방문 전 예약',
          descriptionEn: 'Book before visiting the immigration office',
          url: 'https://www.hikorea.go.kr/resv/ResvIntroR.pt',
          iconName: 'event_repeat',
        ),
        GuideLink(
          labelKo: '법무부 — 모바일 외국인등록증 발급',
          labelEn: 'Ministry of Justice — mobile Residence Card',
          descriptionKo: '대상과 발급 방법',
          descriptionEn: 'Who can get one and how (Korean)',
          url: 'https://www.immigration.go.kr/bbs/immigration/220/591020/artclView.do',
          iconName: 'smartphone',
        ),
        GuideLink(
          labelKo: '가이드 — 귀국·출국 전 행정 정리',
          labelEn: 'Guide — Before You Leave Korea',
          descriptionKo: '출국 시 등록증 반납',
          descriptionEn: 'Handing in the card when leaving',
          url: '/guide/item/departure-checklist',
          iconName: 'flight_takeoff',
        ),
      ],
      difficulty: 1,
      status: GuideStatus.published,
    ),

    // departure-checklist — 조사 코덱스 04/007 2절: 출입국관리법 제37조①(등록증 반납·예외)·
    // 제30조(재입국허가·면제), 법무부 재입국허가 면제 안내, 보건복지부고시 「장기체류 재외국민
    // 및 외국인에 대한 건강보험 적용기준」 제4조(지역가입자 1개월 이상 국외 체류 시 출국 다음 날
    // 상실 — 기존 health-insurance 문구와 일치), 국민연금공단 외국인 반환일시금(조건 충족자만),
    // 근로자퇴직급여 보장법 제4조. 통신·은행·주거·기숙사는 전국 공통 출국 절차가 없어 각 계약
    // 기관 확인으로만 안내한다. 출국기한 유예·보험료 최종 정산은 개인별이라 단정하지 않는다.
    AdminGuideItem(
      id: 'departure-checklist',
      categoryId: GuideCategory.immigration,
      searchAliasesKo: ['출국', '귀국', '한국 떠나기', '본국 귀국', '등록증 반납'],
      searchAliasesEn: ['leaving Korea', 'departure', 'go home', 'return home'],
      titleKo: '귀국·출국 전 행정 정리',
      titleEn: 'Before You Leave Korea',
      detailTitleKo: '한국을 떠나기 전에 정리할 것',
      detailTitleEn: 'What to Sort Out Before Leaving Korea',
      summaryKo: '일시 출국인지 완전 출국인지부터, 등록증·보험·계약 정리',
      summaryEn: 'Short trip or leaving for good? Card, insurance and '
          'contracts',
      iconName: 'flight_takeoff',
      overviewKo: '졸업·자퇴·교환학기 종료 등으로 한국을 떠나거나, 방학에 잠시 본국에 다녀올 때 '
          '챙길 행정 절차를 정리했습니다.\n\n'
          '가장 먼저 다시 한국에 돌아올 예정인지(일시 출국), 학업을 마치고 떠나는지(완전 출국)를 '
          '구분하세요. 외국인등록증 반납과 재입국 여부가 여기서 갈립니다. 한국에 남아 일자리를 '
          '찾을 계획이라면 출국 대신 구직(D-10) 가이드를 보세요.',
      overviewEn: 'The paperwork to handle when you leave Korea after '
          'graduating, withdrawing or finishing an exchange — or when you go '
          'home briefly during the holidays.\n\n'
          'First decide whether you will come back (a temporary trip) or are '
          'leaving after your studies (leaving for good). Whether you hand in '
          'your Residence Card, and how you re-enter, depends on it. If you '
          'plan to stay and look for work, see the job-seeking (D-10) guide '
          'instead.',
      topSections: [
        GuideSection(
          titleKo: '일시 출국인가요, 완전 출국인가요?',
          titleEn: 'A short trip, or leaving for good?',
          iconName: 'compare_arrows',
          notes: [
            GuideNote(
              titleKo: '✈️ 다시 돌아올 예정(일시 출국)',
              titleEn: '✈️ Coming back (temporary trip)',
              linesKo: [
                '외국인등록을 한 유학(D-2)·일반연수(D-4) 체류자는 출국일부터 1년 안에(남은 '
                    '체류기간이 1년보다 짧으면 그 기간 안에) 다시 들어오면 재입국허가가 면제될 수 '
                    '있습니다.',
                '재입국허가를 받았거나 복수사증·재입국허가 면제 등 법이 정한 예외에 해당해 체류기간 '
                    '안에 다시 들어올 예정이면 외국인등록증을 반납하지 않는 경우가 있습니다. 본인이 '
                    '예외에 해당하는지는 출국 전에 1345에 확인하세요.',
                '재입국 면제는 체류기간을 늘려 주지 않습니다. 돌아오는 날이 체류기간 만료 전인지 '
                    '확인하세요.',
              ],
              linesEn: [
                'Registered student (D-2) and general training (D-4) residents '
                    'who come back within 1 year of leaving (or within their '
                    'remaining period of stay, if shorter) may be exempt from a '
                    're-entry permit.',
                'If you hold a re-entry permit, or fall under a legal exception '
                    'such as a multiple-entry visa or a re-entry permit exemption '
                    'and will return within your period of stay, you may not have '
                    'to hand in your Residence Card. Check with 1345 before you '
                    'leave whether the exception applies to you.',
                'The exemption does not extend your stay. Check that you will '
                    'be back before your period of stay ends.',
              ],
            ),
            GuideNote(
              titleKo: '🧳 학업을 마치고 떠남(완전 출국)',
              titleEn: '🧳 Leaving after your studies',
              linesKo: [
                '출국할 때 외국인등록증을 출입국관리공무원에게 반납하는 것이 원칙입니다'
                    '(출입국관리법 제37조).',
                '반납 여부는 졸업했는지가 아니라 다시 들어올 자격과 기간이 남는지로 정해지므로, '
                    '헷갈리면 1345에 확인하세요.',
              ],
              linesEn: [
                'As a rule you hand in your Residence Card to the immigration '
                    'officer when you leave (Immigration Act art. 37).',
                'Whether you hand it in depends on whether you keep a right and '
                    'time to come back, not simply on graduating — if unsure, '
                    'ask 1345.',
              ],
            ),
          ],
          footnoteKo: '※ 출입국관리법 제30조·제37조와 법무부 재입국허가 면제 안내 기준, '
              '2026-09-13 확인. 입국규제 대상 등은 따로 심사될 수 있습니다.',
          footnoteEn: '※ Based on Immigration Act arts. 30 and 37 and the '
              'Ministry of Justice re-entry exemption notice, checked '
              '2026-09-13. People subject to entry restrictions may be '
              'reviewed separately.',
        ),
      ],
      checklistTitleKo: '떠나기 전 체크리스트',
      checklistTitleEn: 'Checklist before you leave',
      checklistKo: [
        '체류: 외국인등록증 반납 여부, 체류기간 만료일, 한국에 남을 계획이면 체류자격 변경',
        '학교: 졸업·성적 등 필요한 증명서 발급, 기숙사 퇴사 절차(해당 학기 공지)',
        '건강보험: 지역가입자는 출국해 1개월 이상 해외에 머물면 출국 다음 날 자격이 끝남 — '
            '보험료 정산은 국민건강보험공단에 확인',
        '일했다면: 마지막 임금 정산, 퇴직급여 대상인지, 국민연금 반환일시금 대상인지 확인',
        '주거: 임대차 보증금 반환 일정, 공과금·관리비 정산',
        '휴대폰·은행: 해지하거나 유지할지 각 회사에 확인(해외에서 본인 확인이 필요한 서비스 포함)',
      ],
      checklistEn: [
        'Stay: whether to hand in your Residence Card, your expiry date, and a '
            'change of status if you are staying on',
        'University: the certificates you need (graduation, transcript), '
            'dormitory move-out steps (that semester’s notice)',
        'Health insurance: for regional subscribers, coverage ends from the '
            'day after departure once you stay abroad 1 month or more — check '
            'the final premium with the National Health Insurance Service',
        'If you worked: your final wages, whether you qualify for severance '
            'pay, and whether you qualify for a National Pension lump-sum '
            'refund',
        'Housing: when your deposit comes back, and settling utilities and '
            'maintenance fees',
        'Phone and bank: ask each company whether to cancel or keep it '
            '(including services that need identity checks from abroad)',
      ],
      stepsKo: [
        '출국 한 달 전쯤: 완전 출국인지 정하고, 집주인·기숙사·통신사·은행에 필요한 해지나 '
            '반환 일정을 확인',
        '필요한 증명서를 미리 발급받아 보관(출국 뒤 발급 방법은 증명서 발급 가이드와 학교에서 '
            '확인)',
        '일했다면 임금·퇴직급여·국민연금 반환일시금 대상 여부를 확인하고 신청',
        '출국 직전: 공과금·관리비 정산과 보증금 반환 확인',
        '출국할 때: 완전 출국이면 외국인등록증 반납',
      ],
      stepsEn: [
        'About a month before: decide whether you are leaving for good, and '
            'check cancellation or refund timing with your landlord, dormitory, '
            'phone company and bank.',
        'Get the certificates you will need and keep them (for getting them '
            'from abroad, see the certificate guide and ask the university).',
        'If you worked, check whether you qualify for wages owed, severance '
            'pay or a National Pension lump-sum refund, and apply.',
        'Just before leaving: settle utilities and maintenance fees and '
            'confirm your deposit refund.',
        'At departure: if you are leaving for good, hand in your Residence '
            'Card.',
      ],
      sections: [
        GuideSection(
          titleKo: '일했다면 확인할 것',
          titleEn: 'If you worked in Korea',
          iconName: 'work',
          notes: [
            GuideNote(
              titleKo: '받을 수 있는 돈은 조건이 달라요',
              titleEn: 'Each payment has its own conditions',
              linesKo: [
                '퇴직급여: 외국인 여부가 아니라 근로자인지와 계속근로 1년 이상·주 평균 15시간 이상 '
                    '등 요건으로 판단합니다. 단기 아르바이트는 대상이 아닐 수 있습니다.',
                '퇴직급여 대상이 아니어도 받지 못한 임금은 따로 청구할 수 있습니다(고용노동부 1350).',
                '국민연금 반환일시금은 모든 외국인에게 주지 않습니다. 국적(사회보장협정·상호주의)과 '
                    '체류자격 등 조건을 국민연금공단에서 확인하세요. 출국 전 국내에서 청구할 때는 '
                    '1개월 안에 출국한다는 증빙 등이 필요합니다.',
              ],
              linesEn: [
                'Severance pay depends on being an employee and on conditions '
                    'such as 1+ year of continuous work and 15+ hours a week on '
                    'average — not on nationality. Short part-time jobs may not '
                    'qualify.',
                'Even without severance pay, you can claim unpaid wages '
                    'separately (Ministry of Employment and Labor, 1350).',
                'The National Pension lump-sum refund is not paid to every '
                    'foreigner. Check the conditions — nationality (social '
                    'security agreements, reciprocity), status of stay and so '
                    'on — with the National Pension Service. Claiming in Korea '
                    'before you leave needs proof such as departure within 1 '
                    'month.',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '계약은 각 기관에서 정리해요',
          titleEn: 'Contracts are closed with each provider',
          iconName: 'receipt_long',
          bodyKo: '휴대폰·은행·임대차·기숙사·공과금은 나라에 한 번 신고하면 끝나는 절차가 없고, '
              '각 계약 기관의 해지·정산·반환 절차를 따릅니다. 은행 계좌나 휴대폰을 반드시 해지해야 '
              '하는 것은 아니지만, 외국인등록증을 반납한 뒤에는 본인 확인이 어려워질 수 있으니 '
              '출국 전에 필요한 일을 마치세요.',
          bodyEn: 'Phones, banks, leases, dormitories and utilities have no '
              'single “leaving Korea” report — each provider has its own '
              'cancellation, settlement or refund steps. You do not have to '
              'close your bank account or phone, but identity checks can get '
              'harder once you hand in your Residence Card, so finish what you '
              'need before you go.',
        ),
      ],
      tipsKo: [
        '체류기간이 끝나기 전에 떠나는 것이 원칙입니다. 출국기한 유예 같은 예외는 사유별로 '
            '심사되므로, 사정이 있으면 만료 전에 1345나 관할 출입국에 상담하세요.',
        '건강보험료가 출국 뒤에도 고지될 수 있으니 공단에 최종 정산 방법을 확인하세요.',
        '한국에 남아 구직하려면 출국 대신 체류자격 변경을 먼저 알아보세요.',
      ],
      tipsEn: [
        'As a rule, leave before your period of stay ends. Exceptions such as '
            'a deferral of the departure deadline are decided case by case, so '
            'if something comes up, talk to 1345 or your immigration office '
            'before it expires.',
        'Health insurance bills can still arrive after you leave, so ask the '
            'NHIS how the final settlement works.',
        'If you want to stay and look for work, look into a change of status '
            'before planning to leave.',
      ],
      phrases: [
        GuidePhrase(
          ko: '다음 달에 출국하는데, 해지하거나 정산할 것이 있는지 확인하고 싶습니다.',
          en: 'I am leaving Korea next month and want to check what I need to '
              'cancel or settle.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '생활법령 — 출국 시 준수사항',
          labelEn: 'Easy-to-find Law — rules when leaving',
          descriptionKo: '법제처 외국인유학생 — 등록증 반납과 예외',
          descriptionEn: 'Ministry of Government Legislation — handing in the '
              'card, and exceptions (Korean)',
          url: 'https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=2853&ccfNo=4&cciNo=2&cnpClsNo=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '국민연금공단 — 외국인 반환일시금',
          labelEn: 'National Pension Service — lump-sum refund for foreigners',
          descriptionKo: '대상 국가·체류자격과 신청 방법',
          descriptionEn: 'Eligible countries, statuses and how to apply',
          url: 'https://www.nps.or.kr/eng/ntnlpnsplan/frgnrlpsmrfnd/getOHAI0015M0.do',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 건강보험 가입',
          labelEn: 'Guide — National Health Insurance',
          descriptionKo: '출국 시 자격과 보험료',
          descriptionEn: 'Coverage and premiums when you leave',
          url: '/guide/item/health-insurance',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '출국 전에 받아 둘 증명서',
          descriptionEn: 'Certificates to get before you go',
          url: '/guide/item/certificate-issue',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업 후 구직(D-10) 체류',
          labelEn: 'Guide — Job-Seeking Visa (D-10) after Graduation',
          descriptionKo: '한국에 남아 일자리를 찾는다면',
          descriptionEn: 'If you are staying to look for work',
          url: '/guide/item/d10-job-seeking',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 교외주거 구하기',
          labelEn: 'Guide — Finding Off-Campus Housing',
          descriptionKo: '계약과 보증금',
          descriptionEn: 'Leases and deposits',
          url: '/guide/item/off-campus-housing',
          iconName: 'home_work',
        ),
        GuideLink(
          labelKo: '가이드 — 휴대폰 개통',
          labelEn: 'Guide — Get a Mobile Plan',
          descriptionKo: '약정·해지 확인',
          descriptionEn: 'Contracts and cancelling',
          url: '/guide/item/mobile-plan',
          iconName: 'smartphone',
        ),
        GuideLink(
          labelKo: '가이드 — 은행 계좌 개설',
          labelEn: 'Guide — Open a Bank Account',
          descriptionKo: '계좌·해외송금',
          descriptionEn: 'Accounts and sending money abroad',
          url: '/guide/item/bank-account',
          iconName: 'account_balance',
        ),
        GuideLink(
          labelKo: '가이드 — 휴학·복학·자퇴와 체류',
          labelEn: 'Guide — Leave, Return, Withdrawal & Your Stay',
          descriptionKo: '휴학·자퇴·제적 등 학적 변경과 체류',
          descriptionEn: 'Leave, withdrawal or dismissal, and your stay',
          url: '/guide/item/academic-status-and-visa',
          iconName: 'event_busy',
        ),
        GuideLink(
          labelKo: '가이드 — 외국인등록증 재발급',
          labelEn: 'Guide — Replacing Your Residence Card',
          descriptionKo: '출국 전 카드를 잃어버렸다면',
          descriptionEn: 'If you lose your card before leaving',
          url: '/guide/item/residence-card-reissue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 기숙사 신청',
          labelEn: 'Guide — Dormitory Application',
          descriptionKo: '기숙사 퇴사 절차',
          descriptionEn: 'Dormitory move-out',
          url: '/guide/item/dormitory',
          iconName: 'home_work',
        ),
        GuideLink(
          labelKo: '가이드 — 임대차 보증금 지키기',
          labelEn: 'Guide — Protecting Your Rental Deposit',
          descriptionKo: '보증금 반환 일정과 미반환 대응',
          descriptionEn: 'Deposit refund timing, and if it is not returned',
          url: '/guide/item/rental-deposit-protection',
          iconName: 'home_work',
        ),
      ],
      difficulty: 2,
      status: GuideStatus.published,
    ),

    // graduation-requirements — 동아대 학사안내 「졸업기준 안내」(MN137)·「학사학위취득 유예」
    // (MN139)를 2026-09-13 리드가 www.donga.ac.kr에서 원문으로 다시 읽음(조사 코덱스 04/007
    // 1절과 일치), 학사안내 FAQ Ver.23(2026-02-25) 학업성적 사정표 경로, 경제학과 졸업요건 예시
    // (TOPIK 5급·학과 시험). 외국인 필수교과목 과목 수는 입학연도별 공식 자료가 서로 달라(2023~
    // 2025) course-registration이 이미 「확인 필요」로 다루므로 여기서는 수치를 적지 않는다.
    // 대학원·교환학생·한국어연수 수료는 이 가이드 범위가 아니다(학부 기준).
    AdminGuideItem(
      id: 'graduation-requirements',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['졸업', '졸업요건', '졸업 학점', '학위취득 유예', '졸업유예'],
      searchAliasesEn: ['graduation', 'graduate', 'degree requirements', 'credits to graduate'],
      titleKo: '졸업요건 확인',
      titleEn: 'Checking Graduation Requirements',
      detailTitleKo: '졸업할 수 있는지 미리 확인하기',
      detailTitleEn: 'Check Early Whether You Can Graduate',
      summaryKo: '학업성적 사정표로 학점·평점·TOPIK·학과요건 점검',
      summaryEn: 'Use the grade audit to check credits, GPA, TOPIK and '
          'department rules',
      iconName: 'fact_check',
      overviewKo: '졸업은 총학점만 채운다고 되지 않습니다. 영역별 이수학점, 평점평균, 논문이나 학과 '
          '시험, 그리고 외국인 특별전형 입학생이라면 입학연도에 따라 더해지는 한국어능력·'
          '지정교과목 요건을 모두 충족해야 합니다.\n\n'
          '요건은 입학연도·학과·편입 여부에 따라 달라 한 가지 표로 정리할 수 없습니다. 3학년 무렵부터 '
          '학업성적 사정표로 본인 기준을 확인하고, 부족한 요건은 남은 학기의 수강 계획에 반영하세요.',
      overviewEn: 'Graduating takes more than the total credit count. You must '
          'meet the credits for each area, the minimum GPA, any thesis or '
          'department exam, and — if you were admitted through the '
          'international track — the Korean-language and designated-course '
          'conditions for your admission year.\n\n'
          'The rules depend on your admission year, department and whether you '
          'transferred, so no single table fits everyone. From around your '
          'third year, check your own requirements in the grade audit and '
          'plan the remaining semesters around anything missing.',
      topSections: [
        GuideSection(
          titleKo: '졸업하려면 무엇이 필요한가요?',
          titleEn: 'What do you need to graduate?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '🎓 학교 공통 기준(학부)',
              titleEn: '🎓 University-wide rules (undergraduate)',
              linesKo: [
                '졸업 조건: 영역별 이수학점 충족 + 논문 합격. 외국인 특별전형 입학생은 입학연도와 '
                    '편입 여부에 따라 한국어능력·지정교과목 요건이 더해질 수 있습니다(아래).',
                '누적 평점평균은 원칙적으로 2.0 이상이어야 하며, 졸업학점을 모두 채워도 이에 '
                    '못 미치면 졸업할 수 없습니다. 의학과를 제외한 2008학년도 이전 신입생은 학교 '
                    '안내의 1.5 기준을 확인하세요.',
                '졸업대상자는 재학생·학사학위취득 유예생 중 등록·이수 학기를 채운 학생이며(휴학생 '
                    '제외), 일반학과는 등록 8학기·이수 7학기 이상입니다(편입·학과별 예외는 안내 표 '
                    '확인).',
              ],
              linesEn: [
                'To graduate: meet the credits for each area + pass the thesis. '
                    'Students admitted through the international track may have '
                    'extra Korean-language and designated-course requirements '
                    'depending on admission year and transfer status (below).',
                'The cumulative GPA must generally be 2.0 or higher; below that '
                    'you cannot graduate even with all credits. Students admitted '
                    'in 2008 or earlier, except Medicine, should check the '
                    'university’s 1.5 threshold.',
                'Graduation candidates are enrolled students or degree-deferral '
                    'students who have completed enough registered and studied '
                    'semesters (not students on leave) — 8 registered and 7 '
                    'completed semesters for regular departments (see the table '
                    'for transfers and other departments).',
              ],
            ),
            GuideNote(
              titleKo: '🌏 외국인 특별전형 입학생',
              titleEn: '🌏 Admitted through the international student track',
              linesKo: [
                '2011학년도 이후 외국인 특별전형 입학생(편입 포함)은 TOPIK 4급 이상 또는 국제교류처 '
                    '한국어능력시험 4급 이상 성적증명서를 졸업예정학기에 제출해야 합니다.',
                '2017학년도 이후 외국인 특별전형 입학생(편입 제외)은 국제교류처가 지정한 한국어 '
                    '교과목도 이수해야 합니다. 입학연도별 과목은 수강신청 가이드와 교양대학에서 '
                    '확인하세요.',
              ],
              linesEn: [
                'Students admitted through the international track from 2011 '
                    '(including transfers) must submit a TOPIK level 4+ score, '
                    'or level 4+ in the international office’s Korean test, in '
                    'their expected graduation semester.',
                'Those admitted through that track from 2017 (excluding '
                    'transfers) must also complete the Korean courses the '
                    'international office designates. Check the courses for '
                    'your year in the course registration guide and with the '
                    'College of General Education.',
              ],
            ),
          ],
          noticeKo: '학과에 따라 공통 기준보다 높은 요건이 있습니다. 예를 들어 경제학과 졸업요건 '
              '페이지는 외국인 유학생에게 TOPIK 5급 이상과 학과 졸업시험을 모두 요구합니다. 본인 '
              '학과 요건을 꼭 확인하세요.',
          noticeEn: 'Some departments set stricter rules than the university '
              'minimum. The Department of Economics page, for example, asks '
              'international students for both TOPIK level 5+ and a department '
              'graduation exam. Always check your own department.',
          footnoteKo: '※ 동아대학교 학사안내 「졸업기준 안내」 기준, 2026-09-13 확인. 대학원생은 '
              '학위청구 규정을 따로 확인하세요.',
          footnoteEn: '※ Based on Dong-A’s academic guidance “Graduation '
              'standards”, checked 2026-09-13. Graduate students should check '
              'their degree rules separately.',
        ),
      ],
      checklistTitleKo: '사정표에서 확인할 것',
      checklistTitleEn: 'What to check in the grade audit',
      checklistKo: [
        '입학연도(복학생은 적용 교과과정)와 소속 학과',
        '총 졸업학점과 영역별(교양·전공 등) 이수학점',
        '누적 평점평균 2.0 이상 여부',
        '논문·졸업시험 등 학과 요건',
        '해당자: TOPIK(또는 국제교류처 시험) 4급 이상 성적증명서 제출 여부',
        '해당자: 외국인 지정 한국어 교과목 이수 여부(입학연도별)',
      ],
      checklistEn: [
        'Your admission year (for returning students, the curriculum applied) '
            'and department',
        'Total graduation credits and credits in each area (general '
            'education, major and so on)',
        'Whether your cumulative GPA is 2.0 or higher',
        'Department requirements such as a thesis or graduation exam',
        'If it applies to you: whether you have submitted a TOPIK (or '
            'international office test) level 4+ certificate',
        'If it applies to you: whether you have completed the designated '
            'Korean courses (by admission year)',
      ],
      stepsKo: [
        '통합정보시스템 › 학생정보서비스 › 학부학사 › 졸업 › 학업성적 사정표 확인',
        '입학연도별 교과과정·영역별 이수학점표와 학과 졸업요건 페이지로 부족한 항목 대조',
        '부족한 학점·과목은 다음 학기 수강신청에 반영하고, 학과사무실이나 학사관리과에 확인',
        '예비 졸업사정(1학기 4월, 2학기 10월) 결과를 확인하고, 부족한 학점은 계절학기 수강을 '
            '검토하거나 바로 문의',
        '최종 졸업사정(1학기 8월, 2학기 2월) 뒤 졸업·학위 증명서 발급',
      ],
      stepsEn: [
        'Open Integrated Information System › Student Information Service › '
            'Undergraduate › Graduation › Grade audit.',
        'Compare anything missing with the curriculum and area credit table '
            'for your admission year and your department’s graduation page.',
        'Put missing credits or courses into next semester’s registration, and '
            'check with your department office or Academic Affairs.',
        'Check the preliminary graduation review (April for spring, October '
            'for autumn); consider seasonal-semester courses for missing '
            'credits, or ask straight away.',
        'After the final review (August for spring, February for autumn), get '
            'your graduation and degree certificates.',
      ],
      sections: [
        GuideSection(
          titleKo: '요건을 다 못 채웠거나 졸업을 미루고 싶다면',
          titleEn: 'If you fall short, or want to delay graduating',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '학사학위취득 유예',
              titleEn: 'Deferring your degree',
              linesKo: [
                '졸업예정 재학생 중 수료 또는 졸업이 가능한 학생이 신청할 수 있습니다. 영역별 '
                    '이수학점을 모두 채웠다면 졸업논문을 통과하지 못한 수료예정자도 신청할 수 있지만, '
                    '졸업학점이나 영역별 학점이 부족하면 신청할 수 없습니다.',
                '학기 단위로 총 2회(1년)까지 가능합니다.',
                '수강하지 않으면 정규학기 등록금의 5.5%를 유예비로 내고, 수강하면 신청 학점에 따른 '
                    '등록금을 냅니다. 내지 않으면 제적됩니다.',
                '유예자는 재학생이 아닌 별도 학적이라 재학증명서가 발급되지 않고(졸업예정증명서는 '
                    '가능) 그 학기에 휴학할 수 없으며, 승인 뒤에는 취소할 수 없습니다. 체류기간 연장 '
                    '서류에 영향이 있으니 신청 전에 국제교류과에 확인하세요.',
              ],
              linesEn: [
                'Enrolled expected graduates who can complete the course or '
                    'graduate may apply. If you have met all area credits but '
                    'not passed the graduation thesis, you may still apply; if '
                    'you are short of total or area credits, you may not.',
                'Up to 2 semesters in total (1 year).',
                'With no courses you pay 5.5% of regular tuition as a deferral '
                    'fee; if you take courses, you pay by credits. If you do not '
                    'pay, you are dismissed.',
                'Deferral students are not classed as enrolled, so no '
                    'certificate of enrolment is issued (the expected-graduation '
                    'certificate still is), they cannot take leave that '
                    'semester, and an approved deferral cannot be cancelled. This '
                    'affects documents for extending your stay, so check with the '
                    'Office of International Affairs before applying.',
              ],
            ),
            GuideNote(
              titleKo: '구분해 두세요',
              titleEn: 'Keep these apart',
              linesKo: [
                '학점이나 평점이 부족해 정규 학기를 넘겨 다니면 학기초과자로 등록합니다(등록금은 '
                    '신청 학점에 따라 다름).',
                '학위를 받지 못한 채 과정을 마친 수료는 졸업이 아니며, 학위증이 필요한 체류자격 '
                    '신청 등에서 다르게 취급될 수 있습니다.',
              ],
              linesEn: [
                'If credits or GPA are short and you study past the regular '
                    'semesters, you register as an extra-semester student '
                    '(tuition depends on credits).',
                'Completing the course without a degree is not graduation, and '
                    'it can be treated differently in applications that need a '
                    'degree certificate, such as some statuses of stay.',
              ],
            ),
          ],
          noticeKo: '졸업이 늦어지면 체류기간 연장·구직(D-10) 계획에도 영향을 줄 수 있으니 '
              '국제교류과와 함께 일정을 확인하세요.',
          noticeEn: 'A late graduation can affect your extension of stay or a '
              'job-seeking (D-10) plan, so check the timing with the Office of '
              'International Affairs too.',
        ),
      ],
      tipsKo: [
        '예비 졸업사정 전에 사정표를 먼저 확인하면 마지막 학기에 부족한 과목을 들을 시간이 '
            '생깁니다.',
        '졸업예정자는 마지막 8학기 개강 직후 선정되고, 그때부터 졸업예정증명서를 발급받을 수 '
            '있습니다.',
        '복학생은 최초 입학연도와 복학 학년 입학연도 중 유리한 교과과정을 선택할 수 있다고 '
            '안내되어 있으니 어떤 절차로 적용되는지 학과에 확인하세요.',
      ],
      tipsEn: [
        'Checking the audit before the preliminary review leaves time to take '
            'missing courses in your last semester.',
        'Expected graduates are selected just after the start of the 8th '
            'semester, and the certificate of expected graduation is available '
            'from then.',
        'Returning students are told they may choose the more favourable '
            'curriculum — their original admission year or that of the year '
            'they rejoin — so ask your department how that is applied.',
      ],
      phrases: [
        GuidePhrase(
          ko: '학업성적 사정표를 보고 졸업요건을 확인하고 싶습니다.',
          en: 'I would like to check my graduation requirements in the grade '
              'audit.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대 학사안내 — 졸업기준',
          labelEn: 'Dong-A academic guide — graduation standards',
          descriptionKo: '졸업대상자·졸업사정·평점·외국인 요건',
          descriptionEn: 'Candidates, review dates, GPA and international '
              'student rules (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN137',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 학사학위취득 유예',
          labelEn: 'Dong-A academic guide — degree deferral',
          descriptionKo: '신청 조건·유예비·기간',
          descriptionEn: 'Conditions, fee and period (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN139',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '외국인 필수교과목과 학점 계획',
          descriptionEn: 'Required courses and credit planning',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 학사경고·제적 예방',
          labelEn: 'Guide — Academic Warning & Avoiding Dismissal',
          descriptionKo: '평점이 낮을 때',
          descriptionEn: 'If your GPA is low',
          url: '/guide/item/academic-probation',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '학기초과·유예 등록금',
          descriptionEn: 'Extra-semester and deferral tuition',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '졸업예정·졸업증명서',
          descriptionEn: 'Expected-graduation and graduation certificates',
          url: '/guide/item/certificate-issue',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업 후 구직(D-10) 체류',
          labelEn: 'Guide — Job-Seeking Visa (D-10) after Graduation',
          descriptionKo: '졸업 뒤 한국에 남는다면',
          descriptionEn: 'If you stay in Korea after graduating',
          url: '/guide/item/d10-job-seeking',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 귀국·출국 전 행정 정리',
          labelEn: 'Guide — Before You Leave Korea',
          descriptionKo: '졸업 후 귀국한다면',
          descriptionEn: 'If you leave Korea after graduating',
          url: '/guide/item/departure-checklist',
          iconName: 'flight_takeoff',
        ),
        GuideLink(
          labelKo: '가이드 — 휴학·복학·자퇴와 체류',
          labelEn: 'Guide — Leave, Return, Withdrawal & Your Stay',
          descriptionKo: '휴학·자퇴·제적 등 학적 변경과 체류',
          descriptionEn: 'Leave, withdrawal or dismissal, and your stay',
          url: '/guide/item/academic-status-and-visa',
          iconName: 'event_busy',
        ),
      ],
      difficulty: 2,
      status: GuideStatus.published,
    ),

    // rental-deposit-protection — 에이전트 A 02/023: 주택임대차보호법 제3조·제3조의2·제3조의3·
    // 제4조·제6조·제6조의2·제6조의3·제14조와 시행령(확정일자 부여·수수료), 출입국관리법
    // 제36조·제88조의2, HUG 안심전세포털·전세보증금반환보증 상품 안내·전세피해지원센터, HF 일반
    // 전세지킴보증, 주택임대차분쟁조정위원회, 대한법률구조공단, 부산외국인통합콜센터. 기존
    // off-campus-housing이 등기부·소유자 확인·확정일자·대항력 기본과 사기 예방을 이미 담고 있어
    // 여기서는 심화 확인·반환보증 조건·계약 종료·미반환 대응만 맡는다. 법률 결론(보호받는다/못
    // 받는다)은 일반화하지 않는다. HF·SGI의 외국인 가입, 외국인의 HUG 전입 요건 증빙, 미납국세
    // 열람 조건은 확인하지 못했거나 표현이 달라 단정하지 않는다.
    AdminGuideItem(
      id: 'rental-deposit-protection',
      categoryId: GuideCategory.housing,
      searchAliasesKo: ['보증금', '전세', '전세사기', '확정일자', '보증금 반환'],
      searchAliasesEn: ['deposit', 'jeonse', 'lease deposit', 'fixed date', 'rental scam'],
      titleKo: '임대차 보증금 지키기',
      titleEn: 'Protecting Your Rental Deposit',
      detailTitleKo: '보증금을 지키려면 — 계약 전·입주 후·계약 끝날 때',
      detailTitleEn: 'Protecting Your Deposit — Before, After Moving In, and '
          'at the End',
      summaryKo: '권리관계 확인, 체류지 신고·확정일자, 돌려받지 못할 때 대응',
      summaryEn: 'Check the property, report your address and get a fixed '
          'date, and what to do if it is not returned',
      iconName: 'home_work',
      overviewKo: '원룸·투룸 등 교외 주택을 빌릴 때 낸 보증금은 계약이 끝나면 돌려받아야 할 큰 '
          '돈입니다. 이 가이드는 방 구하기 가이드의 기본 확인에 더해, 보증금을 지키기 위해 '
          '계약 전·입주 직후·계약 종료 때 할 일과 돌려받지 못했을 때 도움받는 곳을 정리했습니다.\n\n'
          '아래 절차를 모두 지켜도 보증금이 반드시 보호된다는 뜻은 아닙니다. 선순위 권리 등 개별 '
          '사정에 따라 결과가 달라지므로, 불안한 점이 있으면 계약 전에 공식 상담을 받으세요.',
      overviewEn: 'The deposit you pay to rent an off-campus room is a large '
          'sum you should get back when the lease ends. On top of the basics '
          'in the housing guide, this guide covers what to do before signing, '
          'right after moving in and at the end of the lease to protect it, '
          'and where to get help if it is not returned.\n\n'
          'Following every step below does not guarantee your deposit is '
          'protected. Outcomes depend on individual facts such as prior '
          'claims on the property, so get official advice before signing if '
          'anything worries you.',
      topSections: [
        GuideSection(
          titleKo: '외국인도 보호받을 수 있나요?',
          titleEn: 'Are foreign tenants covered?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '🛡 대항력과 우선변제권',
              titleEn: '🛡 Opposability and priority repayment',
              linesKo: [
                '임차인이 주택을 인도받고(입주) 주민등록을 마치면 그다음 날부터 제3자에게 임대차를 '
                    '주장할 수 있습니다(대항력, 주택임대차보호법 제3조).',
                '외국인은 출입국관리법에 따라 외국인등록과 체류지 변경신고가 주민등록과 전입신고를 '
                    '대신합니다. 이사하면 전입한 날부터 15일 안에 체류지 변경신고를 하세요.',
                '대항요건에 더해 계약서에 확정일자를 받으면 경매·공매 때 후순위 권리자보다 먼저 '
                    '보증금을 변제받을 권리(우선변제권)가 생깁니다. 전액 회수를 보장한다는 뜻은 '
                    '아닙니다.',
              ],
              linesEn: [
                'Once a tenant has moved in and completed resident registration, '
                    'the lease can be asserted against third parties from the '
                    'next day (Housing Lease Protection Act art. 3).',
                'For foreigners, foreign resident registration and the '
                    'change-of-address report stand in for resident '
                    'registration and the move-in report (Immigration Act). '
                    'When you move, report within 15 days of moving in.',
                'If you also get a fixed date on the lease, you gain a right to '
                    'be repaid ahead of later claimants in an auction or public '
                    'sale (priority repayment). That does not guarantee you get '
                    'it all back.',
              ],
            ),
          ],
          footnoteKo: '※ 주택임대차보호법·출입국관리법 조문과 HUG 안심전세포털 기준, 2026-09-13 '
              '확인. 개별 사건의 법률 판단은 아래 공식 상담 기관에 받으세요.',
          footnoteEn: '※ Based on the Housing Lease Protection Act, the '
              'Immigration Act and the HUG Safe Jeonse portal, checked '
              '2026-09-13. For legal advice on your case, use the official '
              'services below.',
        ),
      ],
      checklistTitleKo: '계약 전·잔금 전 더 확인할 것',
      checklistTitleEn: 'Extra checks before signing and before the final '
          'payment',
      checklistKo: [
        '등기사항증명서를 계약 전과 잔금 치르기 직전에 다시 확인 — 갑구(소유권·압류·가압류 등), '
            '을구(근저당권·전세권 등). 아파트 같은 집합건물이 아니면 토지 등기부도 확인',
        '다른 임차인의 보증금 — 임대인 동의를 받아 주민센터 등에서 확정일자 부여 현황 등 정보 '
            '제공을 요청할 수 있음',
        '임대인이 계약할 때 제시해야 하는 확정일자 부여 정보와 국세·지방세 납세증명서',
        '중개사무소 등록 여부(한국공인중개사협회·국가공간정보포털 등 조회)',
        '대리인과 계약한다면 위임장과 인감증명서(또는 본인서명사실확인서)를 확인하고 임대인과 '
            '직접 통화',
        '매매 시세 대비 보증금이 너무 높지 않은지(국토교통부 실거래가 공개시스템 등)',
      ],
      checklistEn: [
        'Check the property register again before signing and just before '
            'the final payment — section A (ownership, seizures, provisional '
            'seizures), section B (mortgages, jeonse rights). For buildings '
            'that are not multi-unit complexes, check the land register too.',
        'Other tenants’ deposits — with the landlord’s consent you can ask a '
            'community service centre or similar for fixed-date and deposit '
            'information on the property.',
        'The fixed-date information and national/local tax payment '
            'certificates the landlord must show when signing',
        'That the real estate agency is registered (Korea Association of '
            'Realtors search, National Spatial Data Infrastructure Portal, '
            'etc.)',
        'If signing with an agent, check the power of attorney and seal '
            'certificate (or signature confirmation) and phone the landlord '
            'directly.',
        'That the deposit is not too high compared with the sale price '
            '(MOLIT real transaction price system, etc.)',
      ],
      checklistNoteKo: '※ 등기부·소유자 확인과 사기 예방의 기본은 교외주거 구하기 가이드에 '
          '있습니다. 임대인의 미납 세금 확인 가능 범위는 기관 안내마다 표현이 달라, 필요하면 '
          '국세청(126)에 확인하세요.',
      checklistNoteEn: '※ The basics — checking the register and owner, avoiding '
          'scams — are in the off-campus housing guide. Official guidance words '
          'the landlord’s unpaid-tax check differently, so ask the National Tax '
          'Service (126) if you need it.',
      stepsKo: [
        '계약 전: 위 체크리스트 확인, 공인중개사를 통한 계약서 작성',
        '잔금 직전: 등기사항증명서 다시 확인',
        '입주한 날부터 15일 안에 체류지 변경신고',
        '주택 임대차계약 신고 대상(부산은 보증금 6천만원 또는 월세 30만원 초과)이면 계약 '
            '체결일부터 30일 안에 신고 — 임차인이 계약서를 첨부해 신고하면 확정일자가 자동 부여됩니다. '
            '자세한 내용은 교외주거 구하기 가이드',
        '신고 대상이 아니면 계약서 원본과 여권 또는 외국인등록증을 가지고 주민센터 등에서 '
            '확정일자 받기(1건 600원)',
        '필요하면 전세보증금반환보증 가입 조건 확인',
        '계약서·영수증·확정일자 받은 계약서를 계약이 끝날 때까지 보관',
      ],
      stepsEn: [
        'Before signing: go through the checklist above and sign through a '
            'licensed real estate agent.',
        'Just before the final payment: check the property register again.',
        'Within 15 days of moving in, report your change of address.',
        'If the lease must be reported (in Busan, a deposit over ₩60 million '
            'or rent over ₩300,000), report it within 30 days of signing — '
            'if the tenant reports it with the lease attached, a fixed date is '
            'given automatically. See the off-campus housing guide.',
        'If it does not need reporting, take the original lease and your '
            'passport or Residence Card to a community service centre or '
            'similar to get a fixed date (₩600 per contract).',
        'If needed, check the conditions for deposit-return guarantee '
            'insurance.',
        'Keep the lease, receipts and the fixed-date lease until the lease '
            'ends.',
      ],
      sections: [
        GuideSection(
          titleKo: '보증금 반환보증',
          titleEn: 'Deposit-return guarantee',
          iconName: 'receipt_long',
          bodyKo: '주택도시보증공사(HUG) 전세보증금반환보증은 「개인, 법인, 외국인도 보증가입이 '
              '가능」하다고 안내합니다. 가입은 심사를 거치며 조건이 있습니다.',
          bodyEn: 'HUG’s jeonse deposit return guarantee says “individuals, '
              'corporations and foreigners can also apply”. Applications are '
              'reviewed and conditions apply.',
          notes: [
            GuideNote(
              titleKo: 'HUG 안내의 주요 조건',
              titleEn: 'Main conditions in HUG’s guidance',
              linesKo: [
                '보증금 수도권 7억원·그 외 지역 5억원 이하(보증부 월세는 전월세전환율로 환산한 금액)',
                '잔금지급일과 전입신고일 중 늦은 날부터 계약기간의 2분의 1이 지나기 전에 신청',
                '그 집에 살면서 전입신고와 확정일자를 받았을 것, 계약기간 1년 이상, 공인중개사를 '
                    '통해 체결한 계약서',
                '등기부 권리침해가 없고 선순위채권이 주택가액의 60% 이내 등 주택 조건',
              ],
              linesEn: [
                'Deposit up to ₩700 million in the capital region, ₩500 million '
                    'elsewhere (for monthly rent with a deposit, the converted '
                    'amount)',
                'Apply before half the lease term has passed, counted from the '
                    'later of the final-payment date and the move-in report date',
                'You live there with a move-in report and fixed date; lease of 1 '
                    'year or more; contract signed through a licensed agent',
                'Property conditions such as no infringing entries in the '
                    'register and prior claims within 60% of the property value',
              ],
            ),
          ],
          noticeKo: '외국인이 체류지 변경신고로 전입신고 요건을 어떻게 증명하는지, HUG 외 다른 '
              '보증기관의 외국인 가입 가능 여부는 확인하지 못했습니다. 신청 전에 HUG 등 보증기관에 '
              '확인하세요.',
          noticeEn: 'We could not confirm how a foreigner proves the move-in '
              'condition with a change-of-address report, or whether guarantors '
              'other than HUG accept foreigners. Check with HUG or the guarantor '
              'before applying.',
        ),
        GuideSection(
          titleKo: '계약이 끝날 때',
          titleEn: 'When the lease ends',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '기간과 통지',
              titleEn: 'Term and notice',
              linesKo: [
                '기간을 정하지 않았거나 2년 미만으로 정했으면 2년으로 보지만, 임차인은 정한 짧은 '
                    '기간을 주장할 수 있습니다.',
                '나가려면 계약이 끝나기 2개월 전까지 임대인에게 알리세요. 서로 알리지 않으면 같은 '
                    '조건으로 갱신되고 기간은 2년으로 봅니다(묵시적 갱신).',
                '묵시적 갱신이 된 뒤에는 임차인이 언제든 해지를 통지할 수 있고, 임대인이 통지를 받은 '
                    '날부터 3개월이 지나면 효력이 생깁니다.',
                '계약기간이 끝나도 보증금을 돌려받을 때까지는 임대차관계가 계속되는 것으로 봅니다.',
                '더 살고 싶다면 계약갱신요구권을 계약 종료 6개월 전부터 2개월 전까지 1회 행사할 수 '
                    '있고, 갱신 기간은 2년으로 봅니다. 임대인의 실제 거주 등 법정 거절 사유가 있으니 '
                    '본인 상황을 확인하세요.',
              ],
              linesEn: [
                'A lease with no term, or under 2 years, is treated as 2 years, '
                    'but the tenant may insist on the shorter term agreed.',
                'To leave, tell the landlord at least 2 months before the end. If '
                    'neither side gives notice, the lease renews on the same '
                    'terms and is treated as 2 years (implied renewal).',
                'After an implied renewal, the tenant can give notice to end it '
                    'at any time; it takes effect 3 months after the landlord '
                    'receives the notice.',
                'Even after the term ends, the lease is treated as continuing '
                    'until the deposit is returned.',
                'To stay on, you may use the statutory renewal right once, from '
                    '6 months until 2 months before the lease ends; the renewed '
                    'term is treated as 2 years. Statutory refusal grounds, such '
                    'as the landlord genuinely moving in, may apply, so check '
                    'your situation.',
              ],
            ),
          ],
          footnoteKo: '※ 통지는 문자·내용증명 등 기록이 남는 방법으로 하고, 이사 날짜와 보증금 '
              '반환 날짜를 미리 맞추세요.',
          footnoteEn: '※ Give notice in a way that leaves a record (text message, '
              'certified mail) and agree the move-out and deposit-return dates in '
              'advance.',
        ),
        GuideSection(
          titleKo: '보증금을 돌려받지 못했다면',
          titleEn: 'If your deposit is not returned',
          iconName: 'gavel',
          bodyKo: '임대차가 끝났는데 보증금을 돌려받지 못했다면 이사하기 전에 대응 방법을 '
              '확인하세요. 주택 소재지 관할 법원에 임차권등기명령을 신청할 수 있고, 등기를 마치면 '
              '이사하더라도 이미 가진 대항력·우선변제권을 잃지 않습니다(관련 비용은 임대인에게 청구 '
              '가능). 신청 시점과 방법은 개인 사정에 따라 다르니 상담을 먼저 받으세요.',
          bodyEn: 'If the lease has ended and your deposit has not come back, '
              'look into your options before moving out. You can apply to the '
              'court for the property’s area for a tenancy registration order; '
              'once registered, you keep the opposability and priority you '
              'already had even if you move (costs can be claimed from the '
              'landlord). Timing and method depend on your situation, so get '
              'advice first.',
          links: [
            GuideLink(
              labelKo: '대한법률구조공단 132',
              labelEn: 'Korea Legal Aid Corporation 132',
              descriptionKo: '전화 법률상담(국번 없이 132, 평일 09:00~18:00)',
              descriptionEn: 'Legal advice by phone (dial 132, weekdays '
                  '09:00–18:00)',
              url: 'tel:132',
              iconName: 'call',
            ),
            GuideLink(
              labelKo: '부산외국인통합콜센터 1600-0051',
              labelEn: 'Busan Foreigner Call Center 1600-0051',
              descriptionKo: '영어·중국어·베트남어 등, 부동산·법률 전문상담 사전 예약',
              descriptionEn: 'English, Chinese, Vietnamese and more; book '
                  'specialist real estate and legal advice',
              url: 'tel:16000051',
              iconName: 'translate',
            ),
          ],
          notes: [
            GuideNote(
              titleKo: '도움받을 수 있는 곳',
              titleEn: 'Where to get help',
              linesKo: [
                '주택임대차분쟁조정위원회: 보증금·주택 반환 등 분쟁 조정(부산위원회 있음, 온라인 '
                    '조정신청 가능)',
                'HUG 전세피해지원센터: 법률·주거·금융 상담과 전세사기 피해 접수 연계(부산센터 — '
                    '부산광역시청 1층, 평일 10:00~17:00, 점심시간 12:00~13:00)',
                '사기가 의심되면 경찰(112) 신고도 함께 검토하세요.',
              ],
              linesEn: [
                'Housing Lease Dispute Mediation Committee: mediates disputes '
                    'such as deposit and property return (Busan committee; '
                    'online applications)',
                'HUG Jeonse Fraud Support Center: legal, housing and financial '
                    'advice and fraud-report referrals (Busan center — Busan City '
                    'Hall 1F, weekdays 10:00–17:00, closed 12:00–13:00)',
                'If you suspect fraud, consider reporting to the police (112) '
                    'as well.',
              ],
            ),
          ],
          noticeKo: '상담 기관의 외국어 지원 여부는 기관마다 다르니 필요하면 부산외국인통합콜센터에 '
              '먼저 문의하세요.',
          noticeEn: 'Foreign-language support differs by organisation, so if you '
              'need it, start with the Busan Foreigner Call Center.',
        ),
      ],
      tipsKo: [
        '확정일자는 외국인도 주민센터 등에서 여권이나 외국인등록증으로 받을 수 있습니다.',
        '대항력은 전입 다음 날부터 생기므로, 입주 당일에 설정된 근저당을 조심하라는 HUG 안내가 '
            '있습니다. 잔금 직전 등기부를 다시 확인하세요.',
        '임대인의 차임·보증금 증액청구는 원칙적으로 약정액의 5%(20분의 1)를 넘을 수 없고, 계약 '
            '또는 직전 증액 후 1년 안에는 다시 청구할 수 없습니다. 지역 조례가 더 낮은 상한을 정할 수 '
            '있습니다.',
        '기숙사는 주택임대차보호법 적용 판단이 따로 필요하므로 이 가이드 대상이 아닙니다.',
      ],
      tipsEn: [
        'Foreigners can also get a fixed date at a community service centre, '
            'using a passport or Residence Card.',
        'Opposability starts the day after moving in, and HUG warns about '
            'mortgages set up on the move-in day — check the register again '
            'just before the final payment.',
        'As a rule, a landlord’s request to raise rent or the deposit cannot '
            'exceed 5% (one twentieth) of the agreed amount, and another '
            'increase cannot be requested within 1 year of the contract or the '
            'last increase. A local ordinance may set a lower cap.',
        'Dormitories need a separate assessment under the Housing Lease '
            'Protection Act, so they are outside this guide.',
      ],
      phrases: [
        GuidePhrase(
          ko: '임대차계약서에 확정일자를 받고 싶습니다.',
          en: 'I would like to get a fixed date on my lease.',
        ),
        GuidePhrase(
          ko: '계약이 끝났는데 보증금을 돌려받지 못해 상담을 받고 싶습니다.',
          en: 'My lease has ended but my deposit has not been returned, and I '
              'would like advice.',
        ),
      ],
      links: [
        GuideLink(
          labelKo: 'HUG 안심전세포털 — 계약 전 유의사항',
          labelEn: 'HUG Safe Jeonse — before signing',
          descriptionKo: '등기부 보는 법과 위험 신호',
          descriptionEn: 'Reading the register and warning signs (Korean)',
          url: 'https://www.khug.or.kr/jeonse/web/s03/s030105.jsp',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: 'HUG 전세보증금반환보증',
          labelEn: 'HUG deposit return guarantee',
          descriptionKo: '가입 조건과 신청 방법',
          descriptionEn: 'Conditions and how to apply (Korean)',
          url: 'https://www.khug.or.kr/hug/web/ig/dr/igdr000001.jsp',
          iconName: 'receipt_long',
        ),
        GuideLink(
          labelKo: 'HUG 전세피해지원센터',
          labelEn: 'HUG Jeonse Fraud Support Center',
          descriptionKo: '상담 분야와 지역센터(부산)',
          descriptionEn: 'Services and regional centers, incl. Busan (Korean)',
          url: 'https://www.khug.or.kr/jeonse/web/s01/s010001.jsp',
          iconName: 'location_on',
        ),
        GuideLink(
          labelKo: '주택임대차분쟁조정위원회',
          labelEn: 'Housing Lease Dispute Mediation Committee',
          descriptionKo: '조정 신청과 지역 위원회',
          descriptionEn: 'Applying for mediation and regional committees '
              '(Korean)',
          url: 'https://www.hldcc.or.kr/',
          iconName: 'gavel',
        ),
        GuideLink(
          labelKo: '생활법령 — 주택임대차 확정일자',
          labelEn: 'Easy-to-find Law — fixed date on a lease',
          descriptionKo: '확정일자 부여 기관·서류',
          descriptionEn: 'Where to get it and what to bring (Korean)',
          url: 'https://www.easylaw.go.kr/CSP/CnpClsMain.laf?csmSeq=629&ccfNo=2&cciNo=3&cnpClsNo=1',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '가이드 — 교외주거 구하기',
          labelEn: 'Guide — Finding Off-Campus Housing',
          descriptionKo: '방 구하기와 계약 기본',
          descriptionEn: 'Finding a room and lease basics',
          url: '/guide/item/off-campus-housing',
          iconName: 'home_work',
        ),
        GuideLink(
          labelKo: '가이드 — 체류지·등록사항 변경신고',
          labelEn: 'Guide — Reporting Address & Registration Changes',
          descriptionKo: '이사 후 15일 안에 신고',
          descriptionEn: 'Report within 15 days of moving',
          url: '/guide/item/address-and-registration-changes',
          iconName: 'edit_location_alt',
        ),
        GuideLink(
          labelKo: '가이드 — 귀국·출국 전 행정 정리',
          labelEn: 'Guide — Before You Leave Korea',
          descriptionKo: '출국 전 보증금 반환 일정',
          descriptionEn: 'Deposit refund timing before you leave',
          url: '/guide/item/departure-checklist',
          iconName: 'flight_takeoff',
        ),
      ],
      difficulty: 3,
      status: GuideStatus.published,
    ),

    // status-change-d4-to-d2 — 에이전트 A 02/024 1절: 출입국관리법 제24조, 시행규칙 제72조,
    // 하이코리아 매뉴얼 2026-09-01판 유학(D-2) 체류자격 변경허가, 하이코리아 전자민원 CAT_SEQ=1809,
    // 동아대 국제교류과 VISA 정보(MN064) D4→D2 변경. 수수료(13만원·119,000원·법정 10만원+재발급
    // 3만5천원)·재정능력 금액·학력 인증 방식은 출처마다 달라 차이를 드러낸다. 구체 신청 기한과
    // 변경 뒤 시간제취업 허가 효력은 원문이 없어 단정하지 않는다.
    AdminGuideItem(
      id: 'status-change-d4-to-d2',
      categoryId: GuideCategory.immigration,
      searchAliasesKo: ['어학연수 진학', '한국어학당 졸업 후 입학', 'D-4 D-2', '비자 변경', '체류자격 변경'],
      searchAliasesEn: ['change visa', 'D-4 to D-2', 'language school to degree', 'change of status'],
      titleKo: '어학연수→학위과정 체류자격 변경',
      titleEn: 'Changing from D-4 to D-2',
      detailTitleKo: '어학연수(D-4)에서 학위과정 유학(D-2)으로 바꿀 때',
      detailTitleEn: 'Moving from Language Study (D-4) to a Degree (D-2)',
      summaryKo: '입학 허가를 받았다면 학위과정 수업 전에 변경허가',
      summaryEn: 'Admitted to a degree? Get the change approved before classes',
      iconName: 'compare_arrows',
      overviewKo: '한국어학당 같은 어학연수(D-4) 과정에 있다가 학부나 대학원 입학 허가를 받았다면, 학위과정 '
          '수업을 시작하기 전에 유학(D-2)으로 체류자격 변경허가를 받아야 합니다. 현재 체류자격과 다른 활동을 '
          '하려면 미리 허가를 받아야 하기 때문입니다.\n\n'
          '변경은 하이코리아 전자민원이나 출입국·외국인관서 방문으로 신청하며, 허가되면 외국인등록증도 새로 '
          '발급받습니다. 필요한 서류와 수수료는 학교 안내와 법무부 안내의 표기가 조금씩 다르므로 신청 전에 '
          '국제교류과와 하이코리아에서 확인하세요.',
      overviewEn: 'If you are on a language programme (D-4), such as the Korean '
          'Language Institute, and have been admitted to an undergraduate or '
          'graduate degree, you need permission to change to student status '
          '(D-2) before your degree classes begin — doing something your '
          'current status does not cover requires permission in advance.\n\n'
          'Apply through HiKorea e-application or at an immigration office; '
          'once approved, you also get a new Residence Card. The university’s '
          'and the Ministry of Justice’s lists differ slightly on documents and '
          'fees, so check with the Office of International Affairs and HiKorea '
          'before you apply.',
      topSections: [
        GuideSection(
          titleKo: '언제 신청하나요?',
          titleEn: 'When do I apply?',
          iconName: 'help',
          bodyKo: '학위과정 수업을 시작하기 전에 신청하세요. 법무부 안내에는 구체적인 마감일이 따로 적혀 있지 '
              '않지만, 하이코리아 안내의 처리시간이 접수일부터 1개월 이내이므로 입학 일정이 정해지면 바로 '
              '국제교류과에 문의하고 D-4 체류기간이 끝나기 전에 신청을 마치세요.',
          bodyEn: 'Apply before your degree classes start. The Ministry’s guidance '
              'gives no fixed deadline, but HiKorea lists a processing time of up '
              'to 1 month from receipt, so ask the Office of International '
              'Affairs as soon as your admission dates are set, and apply before '
              'your D-4 period of stay ends.',
          noticeKo: '허가가 나기 전에는 학위과정 학생(D-2)으로 체류하는 것이 아닙니다.',
          noticeEn: 'Until it is approved, you are not yet staying as a degree '
              'student (D-2).',
          footnoteKo: '※ 출입국관리법 제24조, 하이코리아 「체류민원 자격별 안내 매뉴얼」(2026년 9월 게시), '
              '동아대 국제교류과 VISA 정보 기준, 2026-09-13 확인.',
          footnoteEn: '※ Based on Immigration Act art. 24, the HiKorea stay manual '
              '(posted September 2026) and Dong-A’s visa information page, '
              'checked 2026-09-13.',
        ),
      ],
      checklistTitleKo: '신청 전 준비할 것',
      checklistTitleEn: 'Get these ready',
      checklistKo: [
        '통합신청서(체류자격 변경허가), 여권과 사본, 외국인등록증',
        '사진 1장 — 최근 6개월 이내 촬영한 3.5×4.5cm 정면 사진(동아대 안내: 흰색 배경, 기존 등록증·여권과 다른 새 사진)',
        '표준입학허가서',
        '학교의 사업자등록증(또는 고유번호증) 사본',
        '재정능력 입증서류 — 동아대 안내: 1,600만원 이상(본교 어학연수생은 800만원)',
        '어학연수 출석(출결)증명서 — 동아대 어학연수생은 국제교류과 발급',
        '학력증명서(졸업·성적) 인증본 — 동아대 안내: 아포스티유·영사확인·중국교육부 인증 중 하나',
        '체류지 입증서류(기숙사 거주자는 기숙사에서 발급) — 동아대 안내: 임대차계약서가 본인 명의가 아니면 '
            '거주·숙소제공확인서와 계약자 신분증 앞·뒷면 사본 추가',
        '등록금납입증명서 — 등록금 납부 후 출력',
      ],
      checklistEn: [
        'Integrated application form (change of status), passport and a copy, '
            'Residence Card',
        'One photo — front-facing, 3.5 × 4.5 cm, taken within the last 6 '
            'months (Dong-A guidance: white background, different from your '
            'card and passport photos)',
        'Standard certificate of admission',
        'Copy of the university’s business registration (or unique number) '
            'certificate',
        'Proof of funds — Dong-A guidance: KRW 16,000,000 or more (KRW '
            '8,000,000 for Dong-A language students)',
        'Language-programme attendance certificate — issued by the Office of '
            'International Affairs for Dong-A students',
        'Certified academic records (graduation, transcript) — Dong-A guidance: '
            'apostille, consular legalisation or China Ministry of Education '
            'verification',
        'Proof of address (dormitory residents get it from the dormitory) — '
            'Dong-A guidance: if the lease is not in your name, add a '
            'confirmation of accommodation and a copy of both sides of the '
            'leaseholder’s ID',
        'Tuition payment certificate — print it after paying',
      ],
      checklistOptionalKo: ['부모의 잔고증명서를 냈다면 가족관계 입증서류'],
      checklistOptionalEn: [
        'Proof of family relationship, if you submit a parent’s bank statement',
      ],
      checklistNoteKo: '※ 법무부 매뉴얼은 학력요건·재정능력 입증서류를 요구하지만 금액과 인증 방식은 '
          '동아대 국제교류과 안내 기준입니다. 서류는 바뀔 수 있으니 신청 전에 확인하세요.',
      checklistNoteEn: '※ The Ministry’s manual asks for proof of academic '
          'background and funds; the amounts and certification methods here '
          'follow Dong-A’s Office of International Affairs. Requirements can '
          'change, so check before you apply.',
      stepsKo: [
        '학위과정 입학 허가와 표준입학허가서 받기',
        '국제교류과 안내에 맞춰 서류 준비',
        '하이코리아 전자민원(온라인 결제) 또는 방문예약 후 관할 출입국·외국인관서에서 신청',
        '심사 결과 조회',
        '허가되면 허가서를 출력하고 새 외국인등록증 발급 절차 진행',
        '새 등록증을 받은 뒤 시간제취업 등 필요한 허가·신고를 다시 확인',
      ],
      stepsEn: [
        'Receive your degree admission and standard certificate of admission.',
        'Prepare documents following the Office of International Affairs list.',
        'Apply through HiKorea e-application (pay online) or book a visit to '
            'your immigration office.',
        'Check the decision.',
        'Once approved, print the permit and get your new Residence Card.',
        'After receiving the new card, check again which permits or reports '
            '(such as part-time work) you need.',
      ],
      sections: [
        GuideSection(
          titleKo: '수수료 — 표기가 서로 달라요',
          titleEn: 'Fees — the figures differ',
          iconName: 'payments',
          notes: [
            GuideNote(
              titleKo: '출처별 표기',
              titleEn: 'What each source says',
              linesKo: [
                '현행 법정 금액: 체류자격 변경허가 10만원, 외국인등록증 발급 3만5천원',
                '하이코리아 전자민원 화면: 온라인 결제액 119,000원(외국인등록증 발급 수수료·결제대행 수수료 포함)',
                '동아대 국제교류과 페이지의 13만원 표기는 현행 법정 금액과 다릅니다.',
              ],
              linesEn: [
                'Current statutory amounts: KRW 100,000 for the change of status, '
                    'KRW 35,000 for the Residence Card',
                'HiKorea e-application screen: KRW 119,000 online payment '
                    '(includes the Residence Card fee and the payment-processing '
                    'fee)',
                'The KRW 130,000 on Dong-A’s international office page differs '
                    'from the current statutory amounts.',
              ],
            ),
          ],
          noticeKo: '실제 결제 금액은 결제 화면이나 관할 출입국·외국인관서에서 확인하세요.',
          noticeEn: 'Confirm the amount you pay on the payment screen or with '
              'your immigration office.',
        ),
        GuideSection(
          titleKo: '허가 뒤와 허가되지 않을 때',
          titleEn: 'After approval, or if refused',
          iconName: 'event_repeat',
          notes: [
            GuideNote(
              titleKo: '확인할 것',
              titleEn: 'What to check',
              linesKo: [
                '학위과정(D-2) 체류기간은 2년 이내에서 3월 말 또는 9월 말까지로 정해집니다.',
                '허가되지 않으면 통지를 받습니다. 기존 자격으로 체류하게 할 수 있고, 출국기한이 적힐 때는 '
                    '통지서 발급일부터 14일 이내 범위입니다. 통지서 내용을 먼저 확인하고 국제교류과에 알리세요.',
                '어학연수 때 받은 시간제취업 허가가 변경 후에도 유지되는지는 원문에서 확인되지 않았습니다. '
                    '일을 계속하려면 먼저 하이코리아나 1345에 확인하세요.',
              ],
              linesEn: [
                'D-2 periods of stay are granted for up to 2 years, ending at the '
                    'end of March or September.',
                'If refused, you are notified. You may be allowed to stay on your '
                    'current status; if a departure deadline is set, it is within '
                    '14 days of the date the notice is issued. Read the notice '
                    'first and tell the '
                    'Office of International Affairs.',
                'Official guidance does not say whether a part-time work permit '
                    'from your language programme carries over. Check with '
                    'HiKorea or 1345 before you keep working.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '방문 신청은 하이코리아 방문예약을 먼저 하세요.',
        '동아대 어학연수생의 출석증명서는 국제교류과에서 발급합니다.',
      ],
      tipsEn: [
        'Book on HiKorea before visiting the immigration office.',
        'Dong-A language students get the attendance certificate from the '
            'Office of International Affairs.',
      ],
      phrases: [
        GuidePhrase(
          ko: '어학연수(D-4)에서 유학(D-2)으로 체류자격을 변경하려고 합니다. 필요한 서류를 확인하고 '
              '싶습니다.',
          en: 'I’d like to change from D-4 to D-2. Could you tell me which '
              'documents I need?',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '하이코리아 — 체류자격 변경허가 안내',
          labelEn: 'HiKorea — change of status of stay',
          descriptionKo: '전자민원 안내(신청은 로그인 필요)',
          descriptionEn: 'E-application guide (applying needs a login)',
          url: 'https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=1809',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '동아대 국제교류과 VISA 정보',
          labelEn: 'Dong-A OIA — visa information',
          descriptionKo: 'D4→D2 변경 준비물',
          descriptionEn: 'What to prepare for D-4 to D-2 (Korean)',
          url: 'https://global.donga.ac.kr/global/CMS/Contents/Contents.do?mCode=MN064',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 비자 종류 안내',
          labelEn: 'Guide — Visa types',
          descriptionKo: 'D-2·D-4 체류자격',
          descriptionEn: 'D-2 and D-4 statuses',
          url: '/guide/item/visa-types',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: '변경 뒤 아르바이트 허가 확인',
          descriptionEn: 'Checking part-time permission after the change',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 국제교류과 방문 안내',
          labelEn: 'Guide — International Affairs Office',
          descriptionKo: '서류 발급과 문의',
          descriptionEn: 'Documents and questions',
          url: '/guide/item/oia-visit',
          iconName: 'swap_horiz',
        ),
        GuideLink(
          labelKo: '가이드 — 외국인등록증 재발급',
          labelEn: 'Guide — Replacing Your Residence Card',
          descriptionKo: '허가 뒤 새 등록증',
          descriptionEn: 'Your new card after approval',
          url: '/guide/item/residence-card-reissue',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '등록금납입증명서 출력',
          descriptionEn: 'Printing the tuition payment certificate',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
      ],
      difficulty: 3,
      status: GuideStatus.published,
    ),

    // class-attendance-and-exams — 에이전트 A 02/024 2절: 동아대 학사안내 공결(MN100)·시험안내
    // (MN099)·성적관리(MN131)·성적조회(MN132)·학사일정(MN173), 2026-2 공결 신청 공지(MN171
    // board_seq 8514159), 수험규정. 학부 기준. 화상 수업 공결(상설 페이지 가능 vs 2026-2 공지
    // 대면 수업만), 공결 신청 기한 표현(전후 2주 vs 사유 발생일부터 2주), 결시·재시험 처리, 이의신청
    // 결과 절차는 원문이 다르거나 없어 단정하지 않는다. 학기별 날짜는 공지로 넘긴다.
    AdminGuideItem(
      id: 'class-attendance-and-exams',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['출석', '결석', '공결', '시험', '중간고사', '기말고사', '성적 확인', '성적 이의신청'],
      searchAliasesEn: ['attendance', 'absence', 'excused absence', 'exam', 'midterm', 'final exam', 'grades'],
      titleKo: '출결·공결·시험·성적',
      titleEn: 'Attendance, Exams & Grades',
      detailTitleKo: '수업에 빠질 때부터 성적을 확인할 때까지',
      detailTitleEn: 'From Missing a Class to Checking Your Grades',
      summaryKo: '결석이 수업시간의 1/3을 넘으면 F, 공결은 정해진 기한 안에 신청',
      summaryEn: 'Miss over a third of class time and you get an F; apply for '
          'excused absence on time',
      iconName: 'fact_check',
      overviewKo: '동아대학교 학부 성적은 출석, 과제, 시험을 종합해 매깁니다. 수업실시 시간의 3분의 1을 '
          '넘게 결석하면 그 과목은 F(또는 NP)가 됩니다.\n\n'
          '부득이하게 결석해야 한다면 정해진 사유와 증빙으로 공결을 신청할 수 있습니다. 시험 시간·장소와 '
          '성적 공시·확정 날짜는 매 학기 학사일정과 공지로 확인하세요.',
      overviewEn: 'Dong-A undergraduate grades combine attendance, coursework and '
          'exams. If you are absent for more than a third of a course’s class '
          'time, you get an F (or NP) for it.\n\n'
          'If you have to miss class, you can apply for an excused absence '
          '(공결) with an accepted reason and proof. Check exam times and rooms, '
          'and the dates grades are posted and finalised, in each semester’s '
          'academic calendar and notices.',
      topSections: [
        GuideSection(
          titleKo: '결석이 많으면 어떻게 되나요?',
          titleEn: 'What if I miss too many classes?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '⚠️ 기준',
              titleEn: '⚠️ The rules',
              linesKo: [
                '수업실시 시간의 3분의 1을 초과해 결석하면 해당 과목 성적은 F 또는 NP입니다.',
                '중간시험 종료일까지 통산 무단결석이 4주 이상이면 장기결석으로 제적될 수 있습니다.',
                '공결로 인정받을 수 있는 한도는 해당 학기 수업일수의 3분의 1까지입니다.',
              ],
              linesEn: [
                'Missing more than a third of a course’s class time means an F or '
                    'NP for that course.',
                'If unexcused absences add up to 4 weeks or more by the end of '
                    'mid-terms, you can be dismissed for long absence.',
                'Excused absences are allowed for up to a third of the semester’s '
                    'class days.',
              ],
            ),
          ],
          noticeKo: '외국인 유학생은 출석과 성적이 시간제취업 허가에도 영향을 줄 수 있어요. 조건은 '
              '시간제취업 가이드에서 확인하세요.',
          noticeEn: 'For international students, attendance and grades can also '
              'affect part-time work permission — see the part-time work guide.',
          noticeIconName: 'info',
          footnoteKo: '※ 동아대학교 학부 학사안내(공결·시험·성적관리·성적조회)와 2026-2학기 공결 신청 '
              '공지 기준, 2026-09-13 확인. 대학원은 이 가이드 범위가 아닙니다.',
          footnoteEn: '※ Based on Dong-A’s undergraduate academic guidance '
              '(excused absence, exams, grading, grade checks) and the autumn '
              '2026 excused-absence notice, checked 2026-09-13. Graduate study '
              'is outside this guide.',
        ),
      ],
      checklistTitleKo: '공결 신청 전에 준비할 것',
      checklistTitleEn: 'Before applying for an excused absence',
      checklistKo: [
        '결석 사유가 인정 사유에 해당하는지(아래 대표 사유)',
        '증빙서류 — 입·퇴원확인서, 전염병은 의사소견서 등',
        '통합정보시스템 로그인 계정',
      ],
      checklistEn: [
        'Whether your reason is an accepted one (see common reasons below)',
        'Proof — admission/discharge record, a doctor’s note for infectious '
            'disease, and so on',
        'Your integrated information system login',
      ],
      stepsKo: [
        '통합정보시스템 › 학생정보서비스 › 학부학사 › 수업 › 공결신청에서 신청',
        '증빙서류를 신청 페이지에 올리기(방문 제출 불필요)',
        '소속 단과대학 행정지원실의 승인 여부 확인',
        '승인되면 공결허가서를 출력해 보관하고 전자출결(출결현황)에 반영됐는지 확인',
        '전자출결을 쓰지 않는 과목은 공결허가서를 담당 교강사에게 제출',
      ],
      stepsEn: [
        'Apply under Integrated Information System › Student Information '
            'Service › Undergraduate › Classes › Excused absence.',
        'Upload your proof on the application page (no need to visit).',
        'Check whether your college’s administrative office approved it.',
        'Once approved, print and keep the approval letter and check that '
            'electronic attendance shows it.',
        'For courses without electronic attendance, give the approval letter '
            'to the instructor.',
      ],
      sections: [
        GuideSection(
          titleKo: '공결 기한·한도·사유',
          titleEn: 'Excused absence: deadlines, limits, reasons',
          iconName: 'event_busy',
          notes: [
            GuideNote(
              titleKo: '기한과 한도',
              titleEn: 'Deadlines and limits',
              linesKo: [
                '학사안내는 「사유 발생 전후 2주 이내(휴일 포함)」로, 2026-2학기 공지의 절차표는 「사유 발생일로부터 '
                    '2주 이내」로도 적고 있습니다. 늦지 않게 사유가 생기면 바로 신청하세요.',
                '신청 후 2주 안에 증빙을 올리지 않으면 자동 취소됩니다.',
                '일반 공결은 처리 중에만 시스템에서 취소할 수 있습니다. 다만 승인된 취·창업 공결의 조건을 '
                    '더 이상 유지하지 못하면 공결취소원과 관련 서류를 내야 하므로 단과대학 행정지원실에 바로 '
                    '문의하세요.',
              ],
              linesEn: [
                'The academic guidance says “within 2 weeks before or after the '
                    'reason arises (holidays included)”, while the autumn 2026 '
                    'notice’s procedure table also says “within 2 weeks of the '
                    'reason arising”. Apply as soon as the reason arises.',
                'If you do not upload proof within 2 weeks of applying, it is '
                    'cancelled automatically.',
                'A general excused absence can be cancelled in the system only '
                    'while it is being processed. If you no longer meet the '
                    'conditions of an approved employment or start-up absence, '
                    'submit the cancellation form and documents — contact your '
                    'college office straight away.',
              ],
            ),
            GuideNote(
              titleKo: '대표적인 인정 사유',
              titleEn: 'Common accepted reasons',
              linesKo: [
                '입원·전염성 질병: 입원·격리치료 기간',
                '본인·배우자의 부모·자녀 사망: 5일 이내(토·공휴일 제외)',
                '본인·배우자의 (외)조부모·형제자매 사망: 3일 이내(토·공휴일 제외)',
                '학교가 주관·인정한 답사·현장실습 등: 해당 기간',
              ],
              linesEn: [
                'Hospital stay or infectious disease: the hospital or isolation '
                    'period',
                'Death of your or your spouse’s parent or child: up to 5 days '
                    '(excluding Saturdays and public holidays)',
                'Death of your or your spouse’s grandparent or sibling: up to 3 '
                    'days (excluding Saturdays and public holidays)',
                'University-run or approved field trips or placements: the period '
                    'itself',
              ],
            ),
          ],
          noticeKo: 'LMS 온라인 수업은 공결 대상이 아니므로 출석인정 기간 안에 들어야 합니다. 실시간 화상 '
              '수업은 학사안내(가능)와 2026-2학기 공지(대면 수업만)가 달라, 해당 학기 공지를 확인하세요.',
          noticeEn: 'Online LMS classes are not covered — complete them within the '
              'attendance window. For live video classes the academic guidance '
              '(allowed) and the autumn 2026 notice (in-person classes only) '
              'differ, so check that semester’s notice.',
        ),
        GuideSection(
          titleKo: '시험',
          titleEn: 'Exams',
          iconName: 'fact_check',
          notes: [
            GuideNote(
              titleKo: '알아둘 것',
              titleEn: 'Good to know',
              linesKo: [
                '중간시험은 개강 후 8주차, 기말시험은 15주차에 봅니다. 날짜는 학사일정으로 확인하세요.',
                '강의시간표상 시간·강의실이 원칙이지만 바뀔 수 있고, 시간·장소를 몰라 못 본 책임은 학생에게 '
                    '있습니다.',
                '시험장에는 외국인등록증이나 여권을 가져가세요. 시험안내의 외국인 인정 신분증은 외국인등록증·'
                    '여권·재외국민 주민등록증이며, 학생증과 모바일학생증은 외국인 칸에 없습니다. 시험 시작 전까지 '
                    '입실하세요.',
                '대리시험 등 부정행위는 정학·성적 무효 처분 대상입니다.',
              ],
              linesEn: [
                'Mid-terms are in week 8 and finals in week 15; check the dates in '
                    'the academic calendar.',
                'Exams are normally at the timetabled time and room, but these can '
                    'change — missing one because you did not check is your '
                    'responsibility.',
                'Bring your Residence Card or passport — for international '
                    'students the exam guidance accepts a Residence Card, passport or '
                    'overseas-Korean resident card; student IDs, including the mobile '
                    'student ID, are not on that list. Be in the room before the exam '
                    'starts.',
                'Cheating, such as sitting an exam for someone else, can lead to '
                    'suspension and cancelled grades.',
              ],
            ),
          ],
          noticeKo: '시험을 못 봤을 때의 처리(추가시험 등)나 공결이 시험에도 적용되는지는 학교 안내에 정해져 '
              '있지 않아요. 바로 담당 교수에게 연락하세요.',
          noticeEn: 'The university’s guidance sets no rule for a missed exam '
              '(such as a make-up) or for whether an excused absence covers an '
              'exam — contact your instructor straight away.',
        ),
        GuideSection(
          titleKo: '성적 확인과 이의신청',
          titleEn: 'Checking grades and raising a concern',
          iconName: 'receipt_long',
          stepsKo: [
            '성적공시 기간에 성적입력조회로 성적 확인(기간은 학사일정)',
            '강의평가를 마친 뒤 일정 시간이 지나야 조회됩니다(기말 평가 후 24시간, 중간·기말 모두 마쳤다면 '
                '12시간).',
            '이의가 있으면 공시기간 안에 담당 교수에게 직접 이의신청',
            '성적확정일 이후 다시 확인 — 공시기간 성적은 바뀔 수 있어요',
          ],
          stepsEn: [
            'During the grade review period, check your grades under grade entry '
                'lookup (dates in the academic calendar).',
            'Grades appear some time after course evaluation: 24 hours after the '
                'final evaluation, or 12 hours if you did both.',
            'If something looks wrong, raise it directly with the instructor '
                'within the review period.',
            'Check again after grades are finalised — they can change during '
                'review.',
          ],
          footnoteKo: '※ 이의신청 결과 통지·정정 절차는 학교 안내에 자세히 적혀 있지 않습니다.',
          footnoteEn: '※ The university’s guidance does not detail how the result '
              'of a grade concern is notified or corrected.',
        ),
      ],
      tipsKo: [
        '공결 승인 뒤에도 전자출결에 반영됐는지 꼭 확인하세요.',
        '시험 전날 시간표와 강의실 공지를 다시 확인하세요.',
        '수강취소는 번복할 수 없고, 취소 후 신청학점이 0학점이면 이수학기에 포함되지 않습니다. 기간은 '
            '학기 공지를 확인하세요.',
      ],
      tipsEn: [
        'Even after approval, check that electronic attendance shows it.',
        'Recheck the exam time and room the day before.',
        'A course drop cannot be undone, and if it leaves you with 0 credits the '
            'semester does not count as completed. Check the dates in the '
            'semester notice.',
      ],
      phrases: [
        GuidePhrase(
          ko: '입원 때문에 결석했습니다. 공결 신청을 했는데 출결에 반영되었는지 확인해 주실 수 있을까요?',
          en: 'I was absent because I was in hospital. I applied for an excused '
              'absence — could you check whether it shows in attendance?',
        ),
      ],
      links: [
        GuideLink(
          labelKo: '동아대 학사안내 — 공결',
          labelEn: 'Dong-A academic guide — excused absence',
          descriptionKo: '인정 사유·기한·신청',
          descriptionEn: 'Reasons, deadlines and applying (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN100',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 시험',
          labelEn: 'Dong-A academic guide — exams',
          descriptionKo: '시험 시기·신분증·부정행위',
          descriptionEn: 'Exam periods, ID and misconduct (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN099',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 성적관리 기준',
          labelEn: 'Dong-A academic guide — grading rules',
          descriptionKo: '결석 1/3 초과 F 기준',
          descriptionEn: 'The over-one-third absence F rule (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN131',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사안내 — 성적조회',
          labelEn: 'Dong-A academic guide — checking grades',
          descriptionKo: '공시·이의신청·확정',
          descriptionEn: 'Review, concerns and finalisation (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN132',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대 학사일정',
          labelEn: 'Dong-A academic calendar',
          descriptionKo: '시험·성적 공시·수강취소 날짜',
          descriptionEn: 'Exam, grade review and drop dates (Korean)',
          url: 'https://www.donga.ac.kr/kor/CMS/Contents/Contents.do?mCode=MN173',
          iconName: 'event_repeat',
        ),
        GuideLink(
          labelKo: '가이드 — 학사경고·제적 예방',
          labelEn: 'Guide — Academic Warning & Avoiding Dismissal',
          descriptionKo: '장기결석·성적 불량 제적',
          descriptionEn: 'Dismissal for long absence or poor grades',
          url: '/guide/item/academic-probation',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: '출석·성적 요건',
          descriptionEn: 'Attendance and grade conditions',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '수강신청과 정정',
          descriptionEn: 'Registering and changing courses',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
      ],
      difficulty: 1,
      status: GuideStatus.published,
    ),
  ];
}
