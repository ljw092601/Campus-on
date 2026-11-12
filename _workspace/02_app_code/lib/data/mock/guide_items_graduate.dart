import '../../domain/entities/admin_guide.dart';

/// The graduate-student guide approved for r23 (2026-10-31, ③): what an
/// international master's, doctoral or integrated student at the Graduate
/// School has to finish, and in which semester, before the thesis can be
/// examined — the foreign language exam, the comprehensive exam, the research
/// plan and plan presentation, and the thesis examination itself. Six school
/// guides put graduate students out of scope (A 02/100 S-1), and 「외국어시험」
/// and 「종합시험」 appeared nowhere in the 38 guides.
///
/// Kept apart from the others so the addition reviews as its own diff;
/// [MockData.guideItems] is expected to append this list (registration is the
/// lead's), so search, categories, the seed export and the screens treat them
/// like the rest.
///
/// Every official source below was read on 2026-10-30~31 (A 02/100 §2·§6,
/// re-read for r23 in A 02/101). Graduate School pages disagree on the TOPIK
/// level that exempts the language exam, on what the two-year score validity
/// counts from, on where a score is handed in, and on the international
/// scholarship rates. No page gives an effective date or cohort that would
/// settle which applies, so the guide shows both readings with where to ask
/// instead of picking one (r23 공통지침: 상충 숫자 임의 확정 금지). Schedules move
/// every semester, so the body says «which semester, what» and sends exact
/// dates to the Graduate School notices.
abstract final class GraduateGuides {
  static const List<AdminGuideItem> items = [
    // ── 대학원 유학생 학위과정 길잡이 ────────────────────────────────────
    // 동아대 대학원(gra.donga.ac.kr) 원문, 2026-10-31 열람(KST):
    //  · 「종합 및 외국어 시험」 MN124(게시일 표기 없음) — 종합시험 응시자격 18/27/45학점, 석사
    //    2과목·박사·통합 3과목, 과목당 70점, 「종합시험 지원서를 대학원 행정지원실에 제출」,
    //    「학기별 일정 상이하오니 학과로 필히 문의」 / 외국어시험 「1학기 이상 등록한 자」,
    //    「연 2회, 5월과 11월」, 「석사 - 영어 / 박사 - 영어」, 「60점 이상」, 면제표(TOPIK
    //    「3급 이상」, 「응시일로부터 2년이내의 성적」, 「시험 접수기간내에 대학원행정지원실에
    //    접수하여야만」), 영어강좌 「총 45시간」 「2/3이상 출석」 「70점 이상」, 「051-200-5502~4」.
    //  · 「학위논문 진행 절차」 MN111 첨부 「학위청구 자격요건 및 논문심사 절차안내(최종수정).pdf」
    //    (같은 페이지 HWP 파일명 20260904_…(최종수정), sha256 dc020fda324718e8) — 1쪽 「학위청구
    //    (논문심사)하는 학기 전까지 완료」, 교과학점 석사 24 / 박사 36(「33학점, 2026-1학기
    //    신입생부터」) / 통합 60(「48학점, 2026-1학기 신입생부터」), 외국어 「3가지 방법 중 선택」
    //    1~3학기, 종합시험 2~3학기, 연구계획서 3학기, 공개발표 결과보고서 3학기, 연구실적물
    //    (박사·통합), 수료생 연구등록 1회 / 2쪽 심사 절차(「예비심사 불합격 시 해당학기
    //    논문제출불가」, 「매 학기 초 반드시 재확인」) / 3쪽 면제 기준표 「제출일 기준 2년 이내」,
    //    TOPIK 「4급 이상」, 「단 한국어는 외국인에 한함」.
    //    같은 페이지 소스에 남은 이전판(20240304_…, sha256 00bc4b052bafd0be — 링크 주소가
    //    `${tmplSiteCode!}` 그대로라 화면에서는 열리지 않음)은 TOPIK 「3급 이상」, 유효기간
    //    문구 없음 — 2024-03 → 2026-09 사이에 기준표가 바뀌었다. 적용 시점·대상은 어느 판에도 없다.
    //  · 「2026학년도 1학기 대학원 외국어(영어) 시험 안내」(학사공지 8446412 첨부, 대학원
    //    교육정책실 2026.4.) — 응시대상 재학생·휴학생·수료생, 「통합정보서비스 로그인 → 졸업 →
    //    졸업신청 → 외국어시험 신청」 → 접수증 → 학과사무실, 유형 1(영어지문 한국어 번역, 종이사전)
    //    ·유형 2(토익 part 5~6 유사, 사전 불가), 신청 후 유형 변경 불가, 「모바일 학생증으로는
    //    본인확인 절차 불가」, 「불합격 시 공인어학성적을 제출하거나 … 영어강좌 프로그램 수강」.
    //  · 학사공지 8518661(2026-10-22) — 2026-2학기 「11. 6.(금)까지 온라인 신청 후 각 학과로
    //    접수증을 제출」(첨부 없음). 학사공지 8337086(2023-01-05)·첨부 규정(부칙 「2021년 9월
    //    1일부터 시행」) — 공인성적 「학과로 제출」, 제5조제3호 국제전문·특수대학원 따로 정할 수
    //    있음, 제5조제4호 「제출일 기준으로 2년 이내」, TOPIK 3급, 제7조 외국인 한국어 선택 가능.
    //  · 「장학금 안내」 MN103 — 「외국인장학금 어학성적에 따라 차등지급 수업료의 50%~70%」.
    //  · 「업무별 담당자」 MN023 — 종합·외국어시험·학위논문 담당, 등록·장학 담당, 「대학원
    //    유학생 사증 및 체류 관리」·「대학원 유학생 학사 지원 및 상담」 담당(이름은 적지 않는다).
    // 국제교류과 「대학원 › 장학금」 MN043과 대학원 영문 사이트 Scholarships(graeng MN133, 같은
    // 표의 영어판으로 보임) — B 70%(TOPIK 5급)·C 50%(4급)·D 25%(3급 또는 학과 추천), 「지급기간
    // 2년」, 재학생 「매 학기 성적 백분율 85점 이상」, 「직전 학기 학업성적 평균이 85점 미만일 경우
    // 지급하지 않음」. 게시일 표기 없음. MN103(50~70%)과 최저 비율이 다르다.
    // 대학원 영문 「Comprehensive Examination and Foreign Language Examination」(graeng MN108)은
    // 면제표에 한국어 줄이 없고 「within the exam application period」 옛 문구라 근거로 쓰지 않는다.
    // 모두 동아대 문서라 학교 규정은 학교 단일 출처다(02/100 §2). 대학원 멘토링은 2026-2학기
    // 공지 1건뿐이라(02/100 §6-3) 프로그램 이름은 적지 않고 학사공지로만 보낸다.
    AdminGuideItem(
      id: 'graduate-degree-guide',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['대학원', '대학원생', '석사', '박사', '통합과정', '외국어시험', '외국어 시험 면제',
        '영어시험', '종합시험', '학위청구', '학위논문', '논문심사', '예비심사', '본심사',
        '연구계획서', '공개발표', '연구등록', '수료생', '외국인장학금'],
      searchAliasesEn: ['graduate school', 'graduate student', 'master\'s', 'doctoral',
        'PhD', 'integrated programme', 'foreign language exam', 'English exam',
        'language exam exemption', 'comprehensive exam', 'qualifying exam', 'thesis',
        'dissertation', 'thesis examination', 'degree claim', 'research plan',
        'research registration', 'graduate scholarship'],
      titleKo: '대학원 학위과정 길잡이',
      titleEn: 'Graduate Degree Roadmap',
      detailTitleKo: '대학원 유학생 학위과정 길잡이 — 외국어시험·종합시험·학위논문',
      detailTitleEn: 'Graduate Degree Roadmap for International Students — '
          'Language Exam, Comprehensive Exam and Thesis',
      summaryKo: '외국어·종합시험 → 학위논문 순서',
      summaryEn: 'Language exam → comps → thesis',
      iconName: 'school',
      overviewKo: '이 가이드는 동아대학교 일반대학원에 다니는 외국인 석사·박사·통합과정 학생이 '
          '학위를 받기까지 무엇을, 몇 학기에 해야 하는지 정리합니다. 학위논문 심사를 받으려면'
          '(학위청구) 그 학기 전까지 교과학점, 외국어시험, 종합시험, 연구계획서, 논문계획 '
          '공개발표를 마쳐야 합니다. 하나라도 늦으면 학위청구 학기가 밀릴 수 있습니다.\n\n'
          '다른 학교 가이드(수강신청·졸업요건·학사경고 등)는 학부 기준입니다. 대학원 학사는 '
          '대학원 행정지원실과 소속 학과 사무실이 맡습니다.\n\n'
          '일정은 학기마다 바뀔 수 있어 「몇 학기에 무엇을」만 적고, 날짜는 대학원 학사공지로 '
          '안내합니다. 외국어시험 면제 기준과 외국인장학금 비율은 대학원 안내끼리 서로 달라 두 '
          '안내를 함께 적었습니다. 성적을 내거나 장학을 확인하기 전에 대학원 행정지원실에 '
          '지금 적용되는 기준을 물어보세요.',
      overviewEn: 'This guide sets out what an international master’s, doctoral '
          'or integrated-programme student at Dong-A’s Graduate School has to do, '
          'and in which semester, to get a degree. Before the semester in which '
          'your thesis is examined (the «degree claim»), you must have finished '
          'your coursework credits, the foreign language exam, the comprehensive '
          'exam, the research plan and the thesis plan presentation. If any of '
          'these is late, your degree claim can slip by a semester.\n\n'
          'The other school guides (course registration, graduation '
          'requirements, academic probation and so on) are written for '
          'undergraduates. Graduate academic matters are handled by the Graduate '
          'School Administrative Support Office and your department office.\n\n'
          'Dates change every semester, so this guide says which semester and '
          'what, and sends you to the Graduate School notices for exact dates. '
          'Graduate School pages disagree on the language-exam exemption and on '
          'international scholarship rates, so both versions are shown. Before '
          'you hand in a score or count on a scholarship, ask the Administrative '
          'Support Office which rule applies now.',
      topSections: [
        GuideSection(
          titleKo: '나에게 해당하나요?',
          titleEn: 'Does this apply to me?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '✅ 일반대학원 외국인 학생',
              titleEn: '✅ International students at the Graduate School',
              linesKo: [
                '동아대학교 일반대학원 석사·박사·석박사통합과정에 다니는 외국인 학생(재학·휴학·'
                    '수료)이 대상입니다.',
              ],
              linesEn: [
                'International students in a master’s, doctoral or integrated '
                    'programme at Dong-A’s Graduate School — enrolled, on leave '
                    'or having completed coursework.',
              ],
            ),
            GuideNote(
              titleKo: '↪ 다른 과정이라면',
              titleEn: '↪ If you are on a different programme',
              linesKo: [
                '국제전문대학원·특수대학원: 대학원 규정은 각 대학원장이 외국어시험과 종합시험을 '
                    '따로 정할 수 있게 합니다. 소속 대학원 행정실에 기준을 확인하세요.',
                '학부생: 「졸업요건 확인」 가이드를 보세요.',
              ],
              linesEn: [
                'International professional and special graduate schools: the '
                    'Graduate School rules let each dean set the language and '
                    'comprehensive exams separately. Check with your own school’s '
                    'office.',
                'Undergraduates: see the «Checking Graduation Requirements» guide.',
              ],
            ),
          ],
          footnoteKo: '※ 「대학원 외국어 및 종합시험에 관한 규정」(2021-09-01 시행본, 대학원 '
              '학사공지 2023-01-05 첨부) 제5조 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on Article 5 of the Graduate School rules on the '
              'foreign language and comprehensive exams (version in force from '
              '2021-09-01, attached to a 2023-01-05 notice), checked 2026-10-31.',
        ),
      ],
      checklistKo: [
        '학번과 통합정보시스템 로그인 (외국어시험 신청)',
        '지도교수와 소속 학과 사무실 연락처',
        '외국어시험을 면제받으려면 공인어학성적표 (TOEIC·TOEFL·IELTS 등, 외국인은 TOPIK)',
        '시험 날 신분증 (모바일 학생증으로는 본인확인이 안 됩니다)',
        '박사·통합과정은 학과가 정한 연구실적 요건',
      ],
      checklistEn: [
        'Your student number and a working login for the university '
            'information system (to apply for the language exam)',
        'Contact details for your advisor and your department office',
        'An official test score if you want the language exam waived (TOEIC, '
            'TOEFL, IELTS etc.; international students can use TOPIK)',
        'ID on exam day (a mobile student ID is not accepted for the identity '
            'check)',
        'Doctoral and integrated students: your department’s research output '
            'requirement',
      ],
      checklistNoteKo: '연구실적 요건과 세부 일정은 학과마다 다릅니다. 입학한 첫 학기에 학과 '
          '사무실에서 본인 과정의 학위청구 요건을 확인해 두세요.',
      checklistNoteEn: 'Research output requirements and detailed schedules '
          'differ by department. In your first semester, ask your department '
          'office for the degree-claim requirements of your programme.',
      stepsKo: [
        '첫 학기에 학위청구 요건을 확인한다. '
            '학과 사무실과 지도교수를 통해 본인 과정의 교과학점, 연구실적 요건, 졸업 예정 '
            '학기를 확인합니다. 아래 단계는 4학기에 졸업하는 경우를 기준으로 한 대학원 '
            '안내입니다.',
        '외국어 요건을 채운다 (1~3학기). '
            '한 학기 이상 등록하면 외국어시험을 볼 수 있습니다. 시험은 5월과 11월에 있고 60점 '
            '이상이면 합격입니다. 시험 대신 공인어학성적을 내거나 방학 영어강좌를 이수해도 '
            '됩니다. 세 가지 중 하나를 학위청구 학기 전까지 마치면 됩니다.',
        '종합시험을 본다 (2~3학기). '
            '석사 18학점, 박사 27학점, 통합과정 45학점 이상을 이수하면 응시할 수 있습니다. '
            '접수기간 안에 종합시험 지원서를 대학원 행정지원실에 내고, 시험은 학과가 정한 '
            '장소에서 봅니다. 학기마다 일정이 달라 학과에 꼭 물어보라고 대학원은 안내합니다.',
        '연구계획서를 내고 논문계획을 발표한다 (3학기). '
            '연구계획서를 내고, 논문계획 공개발표를 한 뒤 결과보고서를 냅니다. 논문 대신 '
            '대체실적을 낼 사람도 공개발표 결과보고서를 냅니다. 박사·통합과정은 학과가 정한 '
            '연구실적을 채운 뒤 연구실적확인서를 냅니다.',
        '수료했다면 연구등록을 한다. '
            '교과를 마치고 수료한 뒤 학위청구를 하려면 연구등록을 한 번 해야 합니다. 연구등록을 '
            '하지 않은 수료생은 연구계획서 등 학위청구 자격 서류를 낼 수 없습니다.',
        '학위청구 학기에 논문 심사를 받는다. '
            '학과 추천 → 예비심사 → 본심사 서류 제출과 심사료 납부 → 심사위원 추천 → 본심사 → '
            '논문 1차 제출 → 최종 제출 순서입니다. 예비심사에 떨어지면 그 학기에는 논문을 낼 '
            '수 없습니다. 날짜는 매 학기 초 대학원 학사공지로 다시 확인하세요.',
      ],
      stepsEn: [
        'Check your degree-claim requirements in your first semester. '
            'Through your department office and advisor, confirm the coursework '
            'credits, research output requirement and the semester you expect '
            'to graduate. The steps below follow the Graduate School’s guide '
            'for finishing in four semesters.',
        'Meet the foreign language requirement (semesters 1–3). '
            'Once you have registered for at least one semester you can sit '
            'the foreign language exam. It is held in May and November, and 60 points is a pass. '
            'Instead of the exam you can hand in an official test score or '
            'complete the vacation English course. One of the three, done '
            'before your degree-claim semester, is enough.',
        'Take the comprehensive exam (semesters 2–3). '
            'You can sit it after 18 credits (master’s), 27 (doctoral) or 45 '
            '(integrated). Hand the application to the Graduate School '
            'Administrative Support Office within the application period; the '
            'exam is held where your department decides. The Graduate School '
            'says to ask your department, as the schedule differs each '
            'semester.',
        'Submit your research plan and present your thesis plan (semester 3). '
            'Hand in the research plan, give the public thesis plan '
            'presentation, then hand in its report. Students submitting '
            'thesis-equivalent work instead of a thesis also hand in the '
            'presentation report. Doctoral and integrated students hand in a '
            'research output confirmation once they meet the department’s '
            'requirement.',
        'If you have completed coursework, do research registration. '
            'After completing coursework, you must do research registration '
            'once before claiming the degree. A student who has not done it '
            'cannot hand in the research plan or other degree-claim documents.',
        'Have your thesis examined in the degree-claim semester. '
            'The order is: department recommendation → preliminary examination '
            '→ final examination documents and fee → examination panel '
            'recommendation → final examination → first submission → final '
            'submission. If you fail the preliminary examination you cannot '
            'submit a thesis that semester. Check the dates in the Graduate '
            'School notices at the start of every semester.',
      ],
      sections: [
        GuideSection(
          titleKo: '외국어시험',
          titleEn: 'Foreign language exam',
          iconName: 'translate',
          notes: [
            GuideNote(
              titleKo: '시험',
              titleEn: 'The exam',
              linesKo: [
                '대상: 한 학기 이상 등록한 학생 (2026학년도 1학기 안내는 재학생·휴학생·수료생 모두 '
                    '응시 가능이라고 적습니다)',
                '시기: 해마다 5월과 11월 · 과목: 영어 · 합격: 60점 이상',
                '유형은 신청할 때 고르고 바꿀 수 없습니다. 유형 1은 영어 지문을 한국어로 옮기는 '
                    '주관식(종이사전 가능, 전자사전 불가), 유형 2는 토익 Part 5~6과 비슷한 객관식 '
                    '어휘·어법 문제(사전 불가)입니다.',
                '신청: 통합정보시스템(안내문 표기 「통합정보서비스」) → 졸업 → 졸업신청 → '
                    '외국어시험 신청 → 접수증을 출력해 학과 사무실에 냅니다.',
              ],
              linesEn: [
                'Who: students with at least one registered semester (the '
                    'spring 2026 notice says enrolled students, students on leave '
                    'and those who have completed coursework can all apply)',
                'When: every May and November · Subject: English · Pass: 60 '
                    'points or more',
                'You choose the format when you apply and cannot change it. '
                    'Format 1 is written translation of an English passage into '
                    'Korean (paper dictionary allowed, no electronic ones); format '
                    '2 is multiple-choice vocabulary and grammar like TOEIC Parts '
                    '5–6 (no dictionary).',
                'Apply: university information system (the notice calls it '
                    '«통합정보서비스») → Graduation → Graduation application → '
                    'Foreign language exam application → print the receipt and '
                    'hand it to your department office.',
              ],
            ),
            GuideNote(
              titleKo: '시험 대신 — 공인성적 또는 방학 영어강좌',
              titleEn: 'Instead of the exam — a test score or the vacation course',
              linesKo: [
                '시험에 떨어져도 공인어학성적을 내거나 방학 영어강좌를 이수하면 외국어 요건을 '
                    '채울 수 있습니다.',
                '영어 성적 기준(영어영문학 외 전공): TOEIC 700점, TOEFL iBT 76점, TEPS 600점'
                    '(NEW TEPS 327점), IELTS 5.5, TOEIC Speaking·OPIc Intermediate Mid2 이상. '
                    '영어영문학 전공자는 기준이 더 높습니다.',
                '방학 영어강좌: 매 방학 오프라인 45시간, 3분의 2 이상 출석하고 평가에서 70점 '
                    '이상이면 시험을 면제합니다.',
              ],
              linesEn: [
                'Even if you fail the exam, an official test score or the '
                    'vacation English course still meets the requirement.',
                'English score thresholds (majors other than English language '
                    'and literature): TOEIC 700, TOEFL iBT 76, TEPS 600 (NEW TEPS '
                    '327), IELTS 5.5, TOEIC Speaking or OPIc Intermediate Mid 2 '
                    'or above. English majors need higher scores.',
                'Vacation English course: 45 hours in person each vacation; '
                    'attend at least two-thirds and score 70 or more on the '
                    'assessment and the exam is waived.',
              ],
            ),
          ],
          // 02/100 §6-1·6-2 와 이 파일 머리 주석의 대조. 시행일·대상으로 가리지 못해 두 안내를
          // 함께 적는다. 「접수기간 안에 내면 안전」은 두 안내를 함께 만족하는 시기라는 추론이다.
          // 감사 05/082 R-1: 시기에 한정한 추론임이 드러나게, 제출처·급수 상충은 남는다고 덧붙였다.
          noticeKo: 'TOPIK 면제 기준이 안내마다 다릅니다 / 대학원 「종합 및 외국어 시험」 '
              '페이지와 2021년 시행 규정은 TOPIK 3급 이상, 2026년 9월에 고친 학위청구 안내의 '
              '기준표는 4급 이상으로 적습니다(한국어 성적은 외국인만). 어느 기준이 언제부터 '
              '누구에게 적용되는지는 어느 안내에도 없습니다. 성적 유효기간 2년을 세는 기준도 '
              '「응시일로부터」와 「제출일 기준」으로 다르고, 성적을 내는 곳도 대학원 행정지원실과 '
              '학과로 다르게 적혀 있습니다. 성적을 내기 전에 대학원 행정지원실'
              '(051-200-5502~4)에 지금 기준과 제출처를 확인하세요. 가장 이른 시기를 적은 안내는 '
              '외국어시험 접수기간 안에 내라고 하므로, 그때 맞춰 내면 제출 시기로는 모든 안내를 '
              '지키는 셈입니다. 다만 제출처와 급수 기준이 서로 다른 점은 그대로 남으니, 이 둘은 '
              '따로 확인해야 합니다.',
          noticeEn: 'The TOPIK exemption differs between pages / The Graduate '
              'School’s exam page and the rules in force from 2021 say TOPIK '
              'level 3 or above; the degree-claim guide revised in September '
              '2026 says level 4 or above (Korean scores count only for '
              'international students). None of them says from when or for whom '
              'each applies. They also differ on what the two-year score '
              'validity counts from («from the test date» or «as of the '
              'submission date») and on where to hand the score in (the '
              'Administrative Support Office or your department). Before you '
              'hand in a score, ask the Administrative Support Office '
              '(051-200-5502~4) which rule applies now and where to submit. The '
              'earliest deadline any page gives is within the language exam '
              'application period, so handing it in then meets every page’s '
              'timing. It does not settle where to submit or which level '
              'counts — check those two separately.',
          noticeIconName: 'warning',
          footnoteKo: '※ 동아대 대학원 「종합 및 외국어 시험」 페이지(게시일 표기 없음), '
              '「학위청구 자격요건 및 논문심사 절차안내(최종수정)」(2026-09-04 파일), 「2026학년도 '
              '1학기 대학원 외국어(영어) 시험 안내」(2026-05-04 게시)와 「대학원 외국어 및 '
              '종합시험에 관한 규정」(2021-09-01 시행) 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on the Graduate School’s exam page (no posting '
              'date shown), its revised degree-claim guide (file dated '
              '2026-09-04), the spring 2026 language exam notice (posted '
              '2026-05-04) and the rules on the language and comprehensive exams '
              '(in force from 2021-09-01), checked 2026-10-31.',
        ),
        GuideSection(
          titleKo: '종합시험',
          titleEn: 'Comprehensive exam',
          iconName: 'fact_check',
          bodyKo: '석사과정은 재학 중 이수한 과목 가운데 2과목, 박사·통합과정은 3과목을 봅니다. '
              '과목마다 100점 만점에 70점 이상이어야 합격입니다. 시험은 한 해에 두 번 있고, '
              '대학원 학위청구 안내는 2~3학기에 마치도록 적습니다. 학기마다 일정이 달라 정확한 '
              '날짜는 학과에 물어보세요.',
          bodyEn: 'Master’s students take 2 subjects and doctoral and integrated '
              'students 3, chosen from courses taken in the programme. Each '
              'subject is marked out of 100 and needs 70 to pass. The exam is '
              'held twice a year, and the Graduate School’s degree-claim guide '
              'places it in semesters 2–3. The schedule differs each semester, '
              'so ask your department for the dates.',
          footnoteKo: '※ 동아대 대학원 「종합 및 외국어 시험」 페이지와 「학위청구 자격요건 및 '
              '논문심사 절차안내(최종수정)」(2026-09-04 파일) 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on the Graduate School’s exam page and its revised '
              'degree-claim guide (file dated 2026-09-04), checked 2026-10-31.',
        ),
        GuideSection(
          titleKo: '학위청구 전까지 마칠 것',
          titleEn: 'What to finish before the degree claim',
          iconName: 'format_list_numbered',
          notes: [
            GuideNote(
              titleKo: '교과학점 (4학기 졸업 기준)',
              titleEn: 'Coursework credits (four-semester track)',
              linesKo: [
                '석사 24학점 이상 + 논문연구 2학점',
                '박사 36학점 이상(2026학년도 1학기 신입생부터 33학점) + 논문연구 4학점',
                '석박사통합 60학점 이상(2026학년도 1학기 신입생부터 48학점) + 논문연구 6학점',
              ],
              linesEn: [
                'Master’s: 24 credits or more + 2 thesis research credits',
                'Doctoral: 36 credits or more (33 for students entering from '
                    'spring 2026) + 4 thesis research credits',
                'Integrated: 60 credits or more (48 for students entering from '
                    'spring 2026) + 6 thesis research credits',
              ],
            ),
            GuideNote(
              titleKo: '학기별로 할 일',
              titleEn: 'By semester',
              linesKo: [
                '1~3학기: 외국어 요건 (시험은 5월·11월)',
                '2~3학기: 종합시험',
                '3학기: 연구계획서 제출 (안내 기준 5월 초·11월 초)',
                '3학기: 논문계획 공개발표 결과보고서 제출 (안내 기준 6월 말·12월 말)',
                '3학기(박사·통합): 학과 연구실적을 채우고 연구실적확인서 제출',
                '수료 뒤: 연구등록 1회 (안내 기준 3월 초·9월 초)',
              ],
              linesEn: [
                'Semesters 1–3: language requirement (exam in May and November)',
                'Semesters 2–3: comprehensive exam',
                'Semester 3: research plan (the guide says early May or early '
                    'November)',
                'Semester 3: thesis plan presentation report (the guide says '
                    'end of June or end of December)',
                'Semester 3 (doctoral and integrated): meet your department’s '
                    'research output requirement and hand in the confirmation',
                'After completing coursework: research registration once (the '
                    'guide says early March or early September)',
              ],
            ),
          ],
          footnoteKo: '※ 동아대 대학원 「학위청구 자격요건 및 논문심사 절차안내(최종수정)」'
              '(2026-09-04 파일) 1쪽 기준, 2026-10-31 확인. 학과 사정에 따라 다를 수 있습니다.',
          footnoteEn: '※ Based on page 1 of the Graduate School’s revised '
              'degree-claim guide (file dated 2026-09-04), checked 2026-10-31. '
              'Your department may differ.',
        ),
        GuideSection(
          titleKo: '논문 심사 — 대략의 일정',
          titleEn: 'Thesis examination — rough timeline',
          iconName: 'menu_book',
          notes: [
            GuideNote(
              titleKo: '8월 졸업 (1학기에 심사)',
              titleEn: 'Graduating in August (examined in spring)',
              linesKo: [
                '3월 중순 추천 → 3월 말 예비심사 → 4월 초 본심사 서류·심사료 → 4월 중순 '
                    '심사위원 추천 → 4월 말~6월 초 본심사 → 6월 중순 1차 제출 → 6월 말 최종 제출',
              ],
              linesEn: [
                'Mid-March recommendation → late March preliminary examination → '
                    'early April final-exam documents and fee → mid-April panel '
                    'recommendation → late April to early June final examination → '
                    'mid-June first submission → end of June final submission',
              ],
            ),
            GuideNote(
              titleKo: '2월 졸업 (2학기에 심사)',
              titleEn: 'Graduating in February (examined in autumn)',
              linesKo: [
                '9월 중순 추천 → 9월 말 예비심사 → 10월 초 본심사 서류·심사료 → 10월 중순 '
                    '심사위원 추천 → 10월 말~12월 초 본심사 → 12월 중순 1차 제출 → 12월 말 최종 '
                    '제출',
              ],
              linesEn: [
                'Mid-September recommendation → late September preliminary '
                    'examination → early October final-exam documents and fee → '
                    'mid-October panel recommendation → late October to early '
                    'December final examination → mid-December first submission → '
                    'end of December final submission',
              ],
            ),
          ],
          noticeKo: '예비심사에 떨어지면 / 그 학기에는 논문(대체실적)을 낼 수 없습니다. 위 일정은 '
              '대략이며 바뀔 수 있어, 대학원은 매 학기 초 다시 확인하라고 안내합니다.',
          noticeEn: 'If you fail the preliminary examination / You cannot submit '
              'the thesis (or thesis-equivalent work) that semester. The '
              'timeline above is approximate and can change; the Graduate School '
              'asks you to recheck it at the start of every semester.',
          noticeIconName: 'warning',
          footnoteKo: '※ 동아대 대학원 「학위청구 자격요건 및 논문심사 절차안내(최종수정)」'
              '(2026-09-04 파일) 2쪽 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on page 2 of the Graduate School’s revised '
              'degree-claim guide (file dated 2026-09-04), checked 2026-10-31.',
        ),
        GuideSection(
          titleKo: '외국인장학금 — 안내마다 다른 점',
          titleEn: 'International scholarship — where the pages differ',
          iconName: 'payments',
          notes: [
            GuideNote(
              titleKo: '국제교류과 · 대학원 영문 장학 안내',
              titleEn: 'International Affairs and the Graduate School English page',
              linesKo: [
                '어학성적에 따라 B 수업료 70%(TOPIK 5급 이상), C 50%(TOPIK 4급 이상), D 25%'
                    '(TOPIK 3급, 또는 B·C에 해당하지 않는 학과 추천자)로 적습니다. 영어트랙 '
                    '입학자는 영어 성적 기준을 따릅니다.',
                '지급기간 2년. 재학생은 매 학기 성적 백분율 85점 이상을 유지해야 하며, 직전 학기 '
                    '평균이 85점 미만이면 지급하지 않는다고 적습니다.',
              ],
              linesEn: [
                'By language score: B, 70% of tuition (TOPIK level 5 or above); '
                    'C, 50% (level 4 or above); D, 25% (level 3, or department '
                    'recommendation for those not meeting B or C). English-track '
                    'entrants follow English score criteria.',
                'Paid for 2 years. Current students must keep a grade of 85 or '
                    'above every semester; the pages say it is not paid if the '
                    'previous semester’s average is below 85.',
              ],
            ),
            GuideNote(
              titleKo: '대학원 장학금 안내',
              titleEn: 'The Graduate School scholarship page',
              linesKo: [
                '외국인장학금은 어학성적에 따라 수업료의 50%~70%를 차등 지급한다고 적습니다. '
                    '25% 등급과 85점·2년 조건은 이 페이지에 없습니다.',
              ],
              linesEn: [
                'Says the international scholarship is 50%–70% of tuition '
                    'depending on language scores. The 25% grade and the 85-point '
                    'and two-year conditions are not on this page.',
              ],
            ),
          ],
          noticeKo: '내 장학 조건은 확인하세요 / 두 안내 모두 게시일이 없고 적용 학년도도 적혀 '
              '있지 않습니다. 등록금고지서에서 실제 감면액을 보고, 유지 조건과 비율은 대학원 '
              '행정지원실(등록·장학 담당) 또는 국제교류과에 확인하세요.',
          noticeEn: 'Check your own scholarship terms / Neither page shows a '
              'posting date or the academic year it applies to. See the actual '
              'reduction on your tuition bill, and ask the Administrative Support '
              'Office (registration and scholarships) or International Affairs '
              'about the conditions and rate.',
          noticeIconName: 'warning',
          footnoteKo: '※ 국제교류과 「대학원 › 장학금」, 대학원 영문 사이트 「Scholarships」, 대학원 '
              '「장학금 안내」 페이지(모두 게시일 표기 없음) 기준, 2026-10-31 확인.',
          footnoteEn: '※ Based on the International Affairs «Graduate › '
              'Scholarships» page, the Graduate School English site’s '
              '«Scholarships» page and the Graduate School scholarship page (none '
              'shows a posting date), checked 2026-10-31.',
        ),
        GuideSection(
          titleKo: '알아두기',
          titleEn: 'Good to know',
          iconName: 'info',
          notes: [
            GuideNote(
              titleKo: '한국어로 외국어시험을 볼 수 있나요?',
              titleEn: 'Can I take the language exam in Korean?',
              linesKo: [
                '2021년 시행 규정은 외국인 학생이 시험 과목으로 한국어를 고를 수 있다고 적지만, '
                    '현행 시험 안내는 영어 시험만 안내합니다. 원하면 대학원 행정지원실에 '
                    '물어보세요.',
              ],
              linesEn: [
                'The rules in force from 2021 say international students may '
                    'choose Korean as the exam subject, but the current exam '
                    'notices describe an English exam only. If you want this, ask '
                    'the Administrative Support Office.',
              ],
            ),
            GuideNote(
              titleKo: '유학생 담당이 있습니다',
              titleEn: 'There is a desk for international students',
              linesKo: [
                '대학원 업무별 담당자 안내에 대학원 유학생의 사증·체류 관리와 학사 지원·상담 '
                    '담당이 따로 있습니다. 시험·학위논문은 학위논문 담당, 등록금·장학은 등록·'
                    '장학 담당이 맡습니다.',
              ],
              linesEn: [
                'The Graduate School staff list has a separate person for '
                    'international students’ visa and stay matters and academic '
                    'support. Exams and theses go to the thesis desk; tuition and '
                    'scholarships to the registration and scholarship desk.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '📅 외국어 요건은 일찍 끝내 두세요 — 한 학기 이상 등록하면 시험을 볼 수 있고, 대학원 '
            '안내는 1~3학기에 마치도록 적습니다.',
        '🗂️ 접수증과 제출한 성적표의 사본을 보관하세요.',
        '📢 학기 초마다 대학원 학사공지를 확인하세요 — 외국어시험 신청, 학위청구 일정, '
            '유학생 프로그램이 여기에 올라옵니다.',
      ],
      tipsEn: [
        '📅 Finish the language requirement early — you can sit the exam once '
            'you have registered for a semester, and the Graduate School '
            'places it in semesters 1–3.',
        '🗂️ Keep copies of your exam receipt and any score report you hand in.',
        '📢 Check the Graduate School notices at the start of each semester — '
            'language exam applications, degree-claim schedules and programmes '
            'for international students are posted there.',
      ],
      phrases: [
        GuidePhrase(
          ko: '외국어시험 면제를 받으려고 TOPIK 성적표를 내려고 합니다. 지금 적용되는 급수 기준과 '
              '제출처를 알려 주시겠어요?',
          en: 'I would like to hand in my TOPIK score to be exempted from the '
              'foreign language exam. Could you tell me which level applies now '
              'and where to submit it?',
        ),
        GuidePhrase(
          ko: '다음 학기에 학위청구를 하려고 합니다. 제가 자격요건을 다 갖췄는지 확인할 수 '
              '있을까요?',
          en: 'I plan to claim my degree next semester. Could you check whether '
              'I meet all the requirements?',
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '대학원 — 종합 및 외국어 시험',
          labelEn: 'Graduate School — comprehensive and language exams',
          descriptionKo: '응시자격·과목·합격 기준·면제 기준',
          descriptionEn: 'Eligibility, subjects, pass marks and exemptions '
              '(Korean)',
          url: 'https://gra.donga.ac.kr/gra/CMS/Contents/Contents.do?mCode=MN124',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '대학원 — 학위논문 진행 절차',
          labelEn: 'Graduate School — thesis procedure',
          descriptionKo: '학위청구 자격요건과 논문심사 절차 (PDF·HWP)',
          descriptionEn: 'Degree-claim requirements and thesis examination '
              '(PDF/HWP, Korean)',
          url: 'https://gra.donga.ac.kr/gra/CMS/Contents/Contents.do?mCode=MN111',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '대학원 학사공지',
          labelEn: 'Graduate School notices',
          descriptionKo: '외국어시험 신청·학위청구 일정·유학생 프로그램',
          descriptionEn: 'Language exam applications, degree-claim schedules, '
              'programmes for international students (Korean)',
          url: 'https://gra.donga.ac.kr/gra/CMS/Board/Board.do?mCode=MN119',
          iconName: 'info',
        ),
        GuideLink(
          labelKo: '대학원 — 장학금 안내',
          labelEn: 'Graduate School — scholarships',
          descriptionKo: '교내·교외 장학과 외국인장학금',
          descriptionEn: 'On- and off-campus scholarships, international '
              'scholarship (Korean)',
          url: 'https://gra.donga.ac.kr/gra/CMS/Contents/Contents.do?mCode=MN103',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '국제교류과 — 대학원 장학금',
          labelEn: 'International Affairs — graduate scholarships',
          descriptionKo: '어학장학금 등급과 유지 조건',
          descriptionEn: 'Language scholarship grades and conditions (Korean)',
          url: 'https://global.donga.ac.kr/global/CMS/Contents/Contents.do?mCode=MN043',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '대학원 영문 사이트 — Scholarships',
          labelEn: 'Graduate School English site — Scholarships',
          descriptionKo: '어학장학금 안내 (영어)',
          descriptionEn: 'Language scholarship in English',
          url: 'https://graeng.donga.ac.kr/graeng/CMS/Contents/Contents.do?mCode=MN133',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '대학원 — 업무별 담당자',
          labelEn: 'Graduate School — staff by task',
          descriptionKo: '시험·학위논문·장학·유학생 담당',
          descriptionEn: 'Who handles exams, theses, scholarships and '
              'international students (Korean)',
          url: 'https://gra.donga.ac.kr/gra/CMS/Contents/Contents.do?mCode=MN023',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '대학원 행정지원실 051-200-5502',
          labelEn: 'Graduate School Administrative Support Office 051-200-5502',
          descriptionKo: '대표 051-200-5502~4',
          descriptionEn: 'Main lines 051-200-5502~4',
          url: 'tel:0512005502',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '가이드 — 장학금·TOPIK 지원받기',
          labelEn: 'Guide — Scholarships & TOPIK Support',
          descriptionKo: 'TOPIK 시험 접수 방법',
          descriptionEn: 'How to register for TOPIK',
          url: '/guide/item/scholarships-and-topik',
          iconName: 'translate',
        ),
        GuideLink(
          labelKo: '가이드 — 학교 온라인 서비스 사용하기',
          labelEn: 'Guide — Using the University’s Online Services',
          descriptionKo: '통합정보시스템 로그인',
          descriptionEn: 'Logging in to the university information system',
          url: '/guide/item/campus-online-services',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '대학원 수강신청 페이지로 가는 링크',
          descriptionEn: 'Link to the graduate course registration page',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
      ],
    ),
  ];
}
