import '../../domain/entities/admin_guide.dart';

/// The two guides approved for r21 (2026-10-30): scholarships and TOPIK
/// support, and the university's online services. Both answer «which of these
/// applies to me, where do I go, and who do I ask» and send the actual
/// procedures to the guides that already own them (tuition, certificates,
/// course registration, graduation, attendance, library).
///
/// Kept apart from the others so the addition reviews as its own diff;
/// [MockData.guideItems] is expected to append this list (registration is the
/// lead's), so search, categories, the seed export and the screens treat them
/// like the rest.
///
/// Every official source below was read on 2026-10-30 (A 02/089). Amounts,
/// dates and conditions that change by year carry their source and date in a
/// footnote; where two official pages disagree, the guide shows both instead
/// of picking one. Links to the old `www.donga.ac.kr/kor/CMS/` pages return
/// 404 since the homepage redesign, so only current addresses are used.
abstract final class SupportGuides {
  static const List<AdminGuideItem> items = [
    // ── 장학금·TOPIK 지원받기 ──────────────────────────────────────────
    // 동아대 장학 규정 및 지침(https://donga.ac.kr/academics/scholarship/rules) ·
    // 국제교류과 「2026학년도 TOPIK 응시료 및 성적장려금 지원 안내」(게시 2025-11-21,
    // board_seq=8413838, 첨부 「2026 토픽 장학금 안내.pdf」) · 국제교류과 「외국인 유학생
    // 수강신청 안내 책자」 2026.8판 인쇄 p.14~15 · 학부 한국어트랙 장학금(MN037) ·
    // 국립국제교육원 공고 제2025-317호(2026년 TOPIK 시행계획) — 2026-10-30 A 가 원문으로
    // 읽음(089 근거표). 국제교류과 공지·첨부·책자는 같은 기관 문서라 근거 하나로 센다.
    // 학부 기준. 급수·시간·금액 가운데 다른 가이드가 가진 숫자(졸업·시간제취업·D-10)는
    // 여기서 다시 쓰지 않고 연결만 한다.
    AdminGuideItem(
      id: 'scholarships-and-topik',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['장학금', '장학', '토픽', 'TOPIK 장학금', '응시료', '성적장려금', '성적우수장학금',
        '한국어능력시험'],
      searchAliasesEn: ['scholarship', 'scholarships', 'TOPIK scholarship', 'exam fee',
        'tuition waiver', 'Korean test', 'merit scholarship'],
      titleKo: '장학금·TOPIK 지원받기',
      titleEn: 'Scholarships & TOPIK Support',
      detailTitleKo: '외국인 유학생 장학금과 TOPIK 응시료·성적장려금 받기',
      detailTitleEn: 'Scholarships, TOPIK Exam Fees and Score Awards',
      summaryKo: '성적우수장학 · TOPIK 응시료·장려금',
      summaryEn: 'Merit awards; TOPIK fee & score awards',
      iconName: 'payments',
      overviewKo: '이 가이드는 동아대학교 외국인 학부 재학생이 신청하거나 받는 교내 장학 가운데 두 '
          '가지를 다룹니다. 직전 학기 성적순위에 따라 수업료를 감면하는 외국인 '
          '성적우수장학금과, TOPIK 응시료 일부와 급수별 성적장려금을 주는 TOPIK '
          '장학금입니다. 입학 때 받는 신입생 장학금은 입학전형·트랙·어학 성적으로 이미 '
          '정해집니다. 장학 규정에는 이 밖에도 대외국제처가 자체 기준으로 선발하는 외국인 '
          '장학(해외자매대학 편입생·협약기관 추천·특별장학·초기정착지원)이 있지만, 개인이 '
          '신청할 기준이 공개돼 있지 않아 여기서는 다루지 않습니다.\n\n'
          '두 장학 모두 대상이 정해져 있고, 금액과 일정은 해마다 바뀔 수 있습니다. 이 '
          '가이드는 본인이 대상인지 확인하는 순서와 신청에서 놓치기 쉬운 점을 정리합니다. '
          '숫자에는 출처와 기준 시점을 함께 적었으니, 신청 전에 국제교류과 공지로 다시 '
          '확인하세요.\n\n'
          '이 안내는 학부 기준입니다. 대학원생·교환학생·GKS 장학생·한국어학당 학생은 '
          '아래 「나에게 해당하나요?」에서 확인할 곳을 보세요.',
      overviewEn: 'This guide covers two of the on-campus scholarships that '
          'international undergraduates at Dong-A apply for or receive '
          'while studying: the international merit scholarship, which '
          'reduces tuition according to your class rank last semester, and '
          'the TOPIK scholarship, which covers part of the TOPIK exam fee '
          'and pays a score award for each level. Freshman scholarships '
          'are fixed at admission by your admission track and language '
          'scores. The scholarship rules also list international '
          'scholarships selected by the Office of External and '
          'International Affairs on its own criteria (partner-university '
          'transfers, partner referrals, special awards, settling-in '
          'support); no criteria for individual applicants are published, '
          'so they are not covered here.\n\n'
          'Both have a defined target group, and the amounts and dates can '
          'change every year. This guide sets out how to check whether you '
          'qualify and what is easy to miss when you apply. Figures are '
          'given with their source and date — check the Office of '
          'International Affairs notice again before you apply.\n\n'
          'This guide is for undergraduates. Graduate, exchange, GKS and '
          'Korean Language Institute students: see «Does this apply to '
          'me?» below for where to check.',
      topSections: [
        GuideSection(
          titleKo: '나에게 해당하나요?',
          titleEn: 'Does this apply to me?',
          iconName: 'help',
          notes: [
            GuideNote(
              titleKo: '✅ 외국인 학부 재학생',
              titleEn: '✅ International undergraduates',
              linesKo: [
                'TOPIK 장학금은 외국인 학부 재학생이 대상입니다. 공지는 입학전형을 따로 '
                    '한정하지 않습니다.',
                '외국인 성적우수장학금은 외국인 특별전형으로 입학한 학부생이 대상이며, '
                    '융합경영학과는 빠집니다.',
                '영어트랙 재학생의 성적장학은 「영어트랙 성적우수장학금」으로 따로 정해지며, 학과 '
                    '장학생 선발 기준을 따릅니다.',
              ],
              linesEn: [
                'The TOPIK scholarship is for international undergraduates '
                    'currently enrolled; the notice does not limit it by admission '
                    'track.',
                'The international merit scholarship is for undergraduates '
                    'admitted through the international track, except the Department '
                    'of Convergence Management.',
                'English-track students have a separate English-track merit '
                    'scholarship, awarded under the department’s selection rules.',
              ],
            ),
            GuideNote(
              titleKo: '↪ 다른 과정이라면',
              titleEn: '↪ If you are on a different programme',
              linesKo: [
                // r23 역연결(리드 지시 5): 새 graduate-degree-guide 로 잇는다. 이 줄은 뜻이
                // 늘었으므로 zh·vi 재번역 대상.
                '대학원생: 국제교류과 「대학원 › 장학금」 안내를 따릅니다. 이 가이드의 범위가 '
                    '아닙니다. 대학원 학위과정 절차와 외국인장학금 안내는 「대학원 학위과정 '
                    '길잡이」 가이드에 있습니다.',
                'GKS 장학생·교환학생: 2026학년도 TOPIK 장학 대상에서 빠집니다. GKS '
                    '장학생은 GKS 담당(051-200-6449)에 문의하세요.',
                '한국어학당 학생: 학당을 2개 학기 이상 수료하고 마지막 2개 학기 출석률이 '
                    '80% 이상인 학생이 외국인 특별전형으로 입학하면 입학 학기에 DAU 외국인 '
                    '우수신입생 장학금을 받을 수 있습니다. 학당에 다니는 동안 받는 장학이 아닙니다.',
              ],
              linesEn: [
                'Graduate students: follow the Office of International Affairs '
                    '«Graduate › Scholarships» page. Not covered here. Graduate '
                    'degree steps and the international scholarship are in the '
                    '"Graduate Degree Roadmap" guide.',
                'GKS scholars and exchange students are excluded from the 2026 '
                    'TOPIK scholarship. GKS scholars should ask the GKS desk '
                    '(051-200-6449).',
                'Korean Language Institute students: if you complete two or more '
                    'institute terms with at least 80% attendance in the last two '
                    'and then enter through the international track, you can receive '
                    'the DAU freshman scholarship for your first semester. It is not '
                    'paid while you are at the institute.',
              ],
            ),
          ],
          footnoteKo: '※ 대상은 동아대학교 장학 규정 및 지침(학사안내 › 장학)과 국제교류과 '
              '「2026학년도 한국어능력시험(TOPIK) 응시료 및 성적장려금 지원 '
              '안내」(2025-11-21 게시) 기준, 2026-10-30 확인.',
          footnoteEn: '※ Based on Dong-A’s scholarship rules (Academics › '
              'Scholarships) and the Office of International Affairs notice on '
              '2026 TOPIK exam fee and score award support (posted '
              '2025-11-21), checked 2026-10-30.',
        ),
      ],
      checklistTitleKo: '신청 전에 확인할 것',
      checklistTitleEn: 'Check before you apply',
      checklistKo: [
        '입학전형(외국인 특별전형인지)·트랙(한국어/영어)·소속 학과',
        '직전 학기 성적 — 수강신청을 하지 않아 성적이 나오지 않으면 성적 기준을 채우지 '
            '못한 것으로 봅니다',
        'TOPIK 성적표 원본과 입학 때 제출한 TOPIK 급수',
        '통합정보시스템에 등록된 본인 계좌번호',
        '이번 학년도 국제교류과 장학 공지',
      ],
      checklistEn: [
        'Your admission track (international or not), language track '
            '(Korean/English) and department',
        'Last semester’s grades — if no grade was produced because you '
            'did not register for courses, you are treated as not meeting '
            'the grade condition',
        'Your original TOPIK score report, and the level you submitted '
            'at admission',
        'Your own bank account number, registered in the integrated '
            'information system',
        'This year’s scholarship notice from the Office of International '
            'Affairs',
      ],
      stepsKo: [
        '내가 어느 장학의 대상인지 확인한다. 입학전형·트랙·과정에 따라 장학 종류가 '
            '다릅니다. 위 「나에게 해당하나요?」를 먼저 보세요.',
        '국제교류과 공지사항에서 이번 학년도 장학 공지를 찾는다. 금액·일정·제외 대상은 '
            '해마다 바뀔 수 있습니다. 공지의 「유학생지원」 분류를 확인하세요.',
        '성적우수장학금은 직전 학기 성적으로 정해진다. 학과 안 성적순위로 등급이 갈리므로 '
            '학기 중 수강과 시험을 관리하고, 수강취소로 학점이 줄면 선발에서 빠질 수 있다는 '
            '점을 기억하세요.',
        'TOPIK을 보고 성적표 원본을 기한 안에 국제교류과에 낸다. 응시료 지원은 '
            '급수와 관계없이 성적표를 내면 받고, 성적장려금은 급수마다 한 번입니다. 시험 '
            '회차마다 제출기한이 있습니다.',
        '통합정보시스템에 본인 계좌번호를 등록해 둔다. 장려금은 이 계좌로 지급되며, 제출 '
            '뒤 약 2개월 안에 지급된다고 안내합니다(상황에 따라 바뀔 수 있음).',
        '감면 결과는 등록금고지서에서 확인한다. 장학금이 반영된 금액과 납부는 「등록금 '
            '납부·등록 확인」 가이드를 보세요.',
      ],
      stepsEn: [
        'Work out which scholarship applies to you. It depends on your '
            'admission track, language track and programme — start with '
            '«Does this apply to me?» above.',
        'Find this year’s scholarship notice on the '
            'Office of International Affairs notice board. '
            'Amounts, dates and exclusions can change '
            'every year — look under the «유학생지원» (student '
            'support) category.',
        'The merit scholarship is decided by last semester’s grades. The '
            'grade depends on your rank within your department, so keep up '
            'with your courses and exams — and remember that dropping '
            'courses can take you below the credits needed for selection.',
        'Take TOPIK and hand the original score report to the Office of '
            'International Affairs before the deadline. The fee support is '
            'paid whatever level you get; the score award is paid once per '
            'level. Each exam round has its own deadline.',
        'Register your own bank account in the integrated information '
            'system. Awards are paid into it, about 2 months after you hand '
            'in the report according to the notice (this can change).',
        'Check the tuition reduction on your tuition bill. For the '
            'amount after the scholarship and how to pay, see the tuition '
            'payment guide.',
      ],
      sections: [
        GuideSection(
          titleKo: '외국인 성적우수장학금',
          titleEn: 'International merit scholarship',
          iconName: 'school',
          notes: [
            GuideNote(
              titleKo: '대상과 기준',
              titleEn: 'Who and how',
              linesKo: [
                '외국인 특별전형으로 입학한 학부생(융합경영학과 제외)',
                '성적이 산출된 직전 학기의 성적순위로 등급을 정합니다.',
              ],
              linesEn: [
                'Undergraduates admitted through the international track '
                    '(Convergence Management excluded)',
                'The grade is set by your rank in the last semester for which '
                    'grades were produced.',
              ],
            ),
            GuideNote(
              titleKo: '등급과 감면율',
              titleEn: 'Grades and reductions',
              linesKo: [
                '성적순위 10% 미만: A — 수업료 최대 100%',
                '40% 미만: B — 수업료 최대 70%',
                '60% 미만: C — 수업료 최대 40%',
                '80% 미만: D — 수업료 최대 20%',
              ],
              linesEn: [
                'Rank in the top 10% (below 10%): A — up to 100% of tuition',
                'Below 40%: B — up to 70% of tuition',
                'Below 60%: C — up to 40% of tuition',
                'Below 80%: D — up to 20% of tuition',
              ],
            ),
          ],
          noticeKo: '「최대」 감면율입니다 / 학교 장학 규정은 감면율 앞에 「최대」를 붙입니다. '
              '국제교류과 안내책자(2026.8)에는 같은 등급이 수업료 '
              '전액·70%·40%·20%로 적혀 있습니다. 실제 감면액은 등록금고지서에서 '
              '확인하세요.',
          noticeEn: 'These are maximum rates / The university’s scholarship rules '
              'put «up to» before each rate; the Office of International '
              'Affairs handbook (Aug 2026) lists the same grades as full '
              'tuition, 70%, 40% and 20%. Check the actual reduction on your '
              'tuition bill.',
          noticeIconName: 'info',
          footnoteKo: '※ 동아대학교 장학 규정 및 지침(게시일 표기 없음)과 국제교류과 「외국인 유학생 '
              '수강신청 안내 책자」 2026.8판 인쇄 p.14 기준, 2026-10-30 '
              '확인. 교내 장학 공통사항의 평점평균 2.5 기준이 이 장학에도 함께 적용되는지는 '
              '공식 안내에 따로 적혀 있지 않으니 국제교류과에 확인하세요.',
          footnoteEn: '※ Based on Dong-A’s scholarship rules (no posting date shown) '
              'and the Office of International Affairs handbook for '
              'international students, Aug 2026 edition, printed p.14, checked '
              '2026-10-30. Whether the general on-campus condition of a 2.5 '
              'GPA also applies to this scholarship is not stated separately — '
              'ask the office.',
        ),
        GuideSection(
          titleKo: 'TOPIK 장학금 — 응시료와 성적장려금',
          titleEn: 'TOPIK scholarship — exam fee and score award',
          iconName: 'payments',
          notes: [
            GuideNote(
              titleKo: '대상',
              titleEn: 'Who',
              linesKo: [
                '외국인 학부 재학생',
                'GKS 장학생·교환학생·휴학생·초과학기생·수료생은 대상이 아닙니다.',
              ],
              linesEn: [
                'International undergraduates currently enrolled',
                'Not GKS scholars, exchange students, students on leave, '
                    'students beyond their regular semesters, or those who have '
                    'completed coursework without graduating.',
              ],
            ),
            GuideNote(
              titleKo: '응시료 지원 (2026학년도)',
              titleEn: 'Exam fee support (2026)',
              linesKo: [
                'TOPIK(PBT) 35,000원 · TOPIK IBT 45,000원 · '
                    'TOPIK 말하기 평가 40,000원',
                '응시료의 나머지는 본인이 냅니다. 급수와 관계없이 성적표를 내면 지원하고, 횟수 '
                    '제한은 없습니다.',
              ],
              linesEn: [
                'TOPIK (PBT) 35,000 won · TOPIK IBT 45,000 won · TOPIK Speaking '
                    '40,000 won',
                'You pay the rest of the fee. Support is paid whatever your '
                    'level once you hand in the score report, with no limit on the '
                    'number of times.',
              ],
            ),
            GuideNote(
              titleKo: '성적장려금 (2026학년도, 세전)',
              titleEn: 'Score award (2026, before tax)',
              linesKo: [
                '3급 500,000원 · 4급 700,000원 · 5급 500,000원 · 6급 '
                    '500,000원',
                'TOPIK(PBT)·TOPIK IBT 성적만 해당하고, 말하기 평가는 해당하지 '
                    '않습니다.',
                '같은 급수는 한 번만 받습니다. 4급을 받은 뒤 5급을 받으면 두 번 다 받을 수 '
                    '있습니다.',
                '입학 때 낸 급수보다 높은 급수부터 받을 수 있습니다. 같은 급수라면 국제교류과에 '
                    '확인하세요 — 공지 본문은 「입학 당시 급수 이상」, 첨부 안내는 「입학 당시보다 '
                    '급수가 높아야」로 적었습니다.',
                '세금을 뺀 금액이 입금됩니다.',
              ],
              linesEn: [
                'Level 3: 500,000 won · Level 4: 700,000 won · Level 5: 500,000 '
                    'won · Level 6: 500,000 won',
                'Only TOPIK (PBT) and TOPIK IBT scores count — not the Speaking '
                    'test.',
                'Each level is paid once. If you get Level 4 and later Level 5, '
                    'you receive both.',
                'Only levels above the one you entered with are paid. If it is '
                    'the same level, ask the office — the notice says «at or above '
                    'the level at admission», the attached guide «higher than at '
                    'admission».',
                'The amount paid in is after tax.',
              ],
            ),
          ],
          noticeKo: '시험마다 제출기한이 있습니다 / 2026학년도 안내는 시험 성적 발표일로부터 '
              '1주일 이내(제출기한 내)에 성적표 원본을 국제교류과에 내라고 하고, 첨부 '
              '일정표에 시험 회차별 성적제출기간을 따로 적었습니다. 성적이 나오면 바로 그 '
              '회차의 기한을 확인하세요.',
          noticeEn: 'Every exam has a deadline / The 2026 notice asks for the '
              'original score report at the office within one week of the '
              'results (within the deadline), and its attached timetable gives '
              'a submission period for each exam round. Check your round’s '
              'deadline as soon as results are out.',
          noticeIconName: 'event_repeat',
          footnoteKo: '※ 국제교류과 「2026학년도 한국어능력시험(TOPIK) 응시료 및 성적장려금 '
              '지원 안내」(2025-11-21 게시)와 첨부 안내 기준, 2026-10-30 '
              '확인. 금액과 대상은 해마다 바뀔 수 있습니다. 같은 안내의 문의처는 국제교류과 '
              '051-200-6447입니다.',
          footnoteEn: '※ Based on the Office of International Affairs notice on 2026 '
              'TOPIK exam fee and score award support (posted 2025-11-21) and '
              'its attachment, checked 2026-10-30. Amounts and eligibility can '
              'change every year. The contact given in that notice is '
              '051-200-6447.',
        ),
        GuideSection(
          titleKo: 'TOPIK 시험 접수는 따로 합니다',
          titleEn: 'You register for TOPIK yourself',
          iconName: 'event_repeat',
          bodyKo: 'TOPIK 원서 접수는 학교가 아니라 TOPIK 홈페이지에서 본인이 합니다. 학교 '
              '지원금은 시험을 본 뒤 성적표를 내야 받는 별도 절차입니다. 응시료는 먼저 본인이 '
              '내고, 지원금은 나중에 받습니다.',
          bodyEn: 'You register for TOPIK yourself on the TOPIK website, not '
              'through the university. The university’s support is a separate '
              'step after the exam, once you hand in your score report — you '
              'pay the exam fee first and get the support later.',
          notes: [
            GuideNote(
              titleKo: '2026년 국내 응시수수료',
              titleEn: '2026 exam fees in Korea',
              linesKo: [
                'TOPIK PBT: 토픽 Ⅰ 40,000원 · 토픽 Ⅱ 55,000원',
                'TOPIK IBT: 토픽 Ⅰ 70,000원 · 토픽 Ⅱ 95,000원',
                'TOPIK 말하기 평가: 80,000원',
              ],
              linesEn: [
                'TOPIK PBT: TOPIK I 40,000 won · TOPIK II 55,000 won',
                'TOPIK IBT: TOPIK I 70,000 won · TOPIK II 95,000 won',
                'TOPIK Speaking: 80,000 won',
              ],
            ),
          ],
          noticeKo: '접수기간·시험일·성적 발표일은 회차마다 다르고 바뀔 수 있습니다. 시험을 보기 '
              '전에 TOPIK 홈페이지에서 그 회차 일정을 확인하세요.',
          noticeEn: 'Registration periods, exam dates and result dates differ by '
              'round and can change. Check the round on the TOPIK website '
              'before you plan around it.',
          noticeIconName: 'info',
          footnoteKo: '※ 국립국제교육원 공고 제2025-317호 「2026년 한국어능력시험 '
              '시행계획」(2025-10-10) 기준, 2026-10-30 확인. 국외 접수기간과 '
              '응시수수료는 현지 시행기관 기준입니다.',
          footnoteEn: '※ Based on National Institute for International Education '
              'notice No. 2025-317, the 2026 TOPIK plan (2025-10-10), checked '
              '2026-10-30. Outside Korea, the local administering body sets '
              'the dates and fees.',
        ),
        GuideSection(
          titleKo: 'TOPIK 성적이 쓰이는 다른 곳',
          titleEn: 'Other places your TOPIK score is used',
          iconName: 'compare_arrows',
          bodyKo: '같은 TOPIK 성적이라도 장학·졸업·체류는 각각 따로 판단하고 따로 냅니다. '
              '장학금을 받았다고 다른 요건이 채워지는 것은 아닙니다.',
          bodyEn: 'The same TOPIK score is judged and submitted separately for '
              'scholarships, graduation and your stay. Receiving a scholarship '
              'does not satisfy any of the other requirements.',
          notes: [
            GuideNote(
              titleKo: '어디에 필요한지',
              titleEn: 'Where it is needed',
              linesKo: [
                '졸업: 외국인 특별전형 입학생은 졸업예정학기에 성적증명서를 냅니다 — 「졸업요건 '
                    '확인」 가이드',
                '시간제취업: 급수에 따라 허용 시간이 달라집니다 — 「시간제취업(아르바이트) '
                    '허가」 가이드',
                '졸업 후 구직(D-10): 점수제 면제 요건 가운데 하나입니다 — 「졸업 후 '
                    '구직(D-10) 체류」 가이드',
                '외국인 필수교양: TOPIK으로 면제·대체되는지는 교양대학에 확인합니다 — '
                    '「수강신청」 가이드',
              ],
              linesEn: [
                'Graduation: international-track students submit a score '
                    'certificate in their expected final semester — see the '
                    'graduation requirements guide',
                'Part-time work: the hours allowed depend on your level — see '
                    'the part-time work guide',
                'Job-seeking (D-10) after graduation: one of the conditions for '
                    'skipping the points test — see the D-10 guide',
                'Required Korean courses for international students: ask the '
                    'College of General Education whether TOPIK can exempt you — see '
                    'the course registration guide',
              ],
            ),
          ],
        ),
        GuideSection(
          titleKo: '입학 때 받은 신입생 장학금',
          titleEn: 'The freshman scholarship you got at admission',
          iconName: 'badge',
          bodyKo: '외국인 신입생 장학금은 입학 학기 수업료에만 적용되며, 입학전형·트랙·어학 성적과 '
              '한국어학당 수료 여부에 따라 등급이 다릅니다. 이미 입학했다면 본인이 받은 감면은 '
              '입학 학기 등록금고지서에서 확인할 수 있습니다.',
          bodyEn: 'Freshman scholarships for international students apply only to '
              'tuition in your first semester, and the grade depends on your '
              'admission track, language scores and whether you completed the '
              'Korean Language Institute. If you have already enrolled, your '
              'first-semester tuition bill shows the reduction you received.',
          noticeKo: '두 공식 안내의 등급표가 다릅니다 / 학교 장학 규정은 외국인 우수신입생 장학금을 '
              'A~E 다섯 등급(동아 TOPIK 3급 이상 D 40%, 나머지 입학자 E '
              '30%)으로, 국제교류과 학부 한국어트랙 안내는 A~D 네 등급(나머지 입학자 D '
              '30%)으로 적습니다. 입학 예정이라면 본인 모집요강과 국제교류과에 적용 기준을 '
              '확인하세요.',
          noticeEn: 'Two official tables differ / The university’s scholarship rules '
              'give five grades A–E for the international freshman scholarship '
              '(Dong-A TOPIK level 3 or above: D, 40%; everyone else: E, 30%), '
              'while the office’s Korean-track page gives four grades A–D '
              '(everyone else: D, 30%). If you are about to enrol, check which '
              'applies in your admission guidelines and with the office.',
          noticeIconName: 'warning',
          footnoteKo: '※ 동아대학교 장학 규정 및 지침과 국제교류과 「학부 한국어트랙 › 장학금」 '
              '페이지(둘 다 게시일 표기 없음) 기준, 2026-10-30 확인.',
          footnoteEn: '※ Based on Dong-A’s scholarship rules and the office’s '
              '«Undergraduate Korean track › Scholarships» page (neither shows '
              'a posting date), checked 2026-10-30.',
        ),
      ],
      tipsKo: [
        '📅 TOPIK 성적이 나오면 바로 제출하세요 — 회차별 제출기한이 정해져 있습니다.',
        '🧾 성적표는 원본을 냅니다. 내기 전에 사본을 따로 남겨 두세요.',
        '💳 계좌번호가 등록돼 있어야 장려금이 지급됩니다.',
        '📉 수강취소 전에 장학 학점 기준을 확인하세요. 신청 학점이 장학생 선발 기준보다 '
            '적어지면 선발 대상에서 빠질 수 있습니다(장학 기준 문의: 학생복지과 장학팀 '
            '051-200-6212).',
      ],
      tipsEn: [
        '📅 Hand in your TOPIK report as soon as results are out — each '
            'round has a fixed deadline.',
        '🧾 The original report is handed in, so keep a copy for yourself '
            'first.',
        '💳 The award can only be paid once your account number is '
            'registered.',
        '📉 Check the scholarship credit rule before you drop a course. '
            'If your registered credits fall below the selection rule you '
            'can lose eligibility (scholarship rules: Student Welfare, '
            'Scholarship Team, 051-200-6212).',
      ],
      phrases: [
        GuidePhrase(
          ko: 'TOPIK 성적표 원본을 제출하러 왔습니다. 응시료 지원과 성적장려금을 신청하고 '
              '싶습니다.',
          en: 'I have come to hand in my original TOPIK score report. I would '
              'like to apply for the exam fee support and the score award.',
        ),
        GuidePhrase(
          ko: '이번 학기 외국인 성적우수장학금 대상인지 확인하고 싶습니다.',
          en: 'I would like to check whether I qualify for the international '
              'merit scholarship this semester.',
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '동아대 장학 규정 및 지침',
          labelEn: 'Dong-A scholarship rules',
          descriptionKo: '외국인 신입생·성적우수 장학 등급표',
          descriptionEn: 'Freshman and merit scholarship tables for international '
              'students (Korean)',
          url: 'https://donga.ac.kr/academics/scholarship/rules',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '국제교류과 — 2026학년도 TOPIK 장학 안내',
          labelEn: 'International Affairs — 2026 TOPIK scholarship notice',
          descriptionKo: '대상·지원액·회차별 제출기한(첨부)',
          descriptionEn: 'Who, how much, and the deadline for each round (attachment, '
              'Korean)',
          url: 'https://global.donga.ac.kr/global/CMS/Board/Board.do?board_seq=8413838&mCode=MN066&mgr_seq=717&mode=view',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '국제교류과 공지사항',
          labelEn: 'International Affairs notices',
          descriptionKo: '「유학생지원」 분류 — 학년도별 장학 공지',
          descriptionEn: '«유학생지원» category — each year’s scholarship '
              'notices',
          url: 'https://global.donga.ac.kr/global/CMS/Board/Board.do?mCode=MN066',
          iconName: 'info',
        ),
        GuideLink(
          labelKo: '국제교류과 — 학부 한국어트랙 장학금',
          labelEn: 'International Affairs — Korean-track scholarships',
          descriptionKo: '신입생 장학 등급(국제교류과 안내)',
          descriptionEn: 'Freshman scholarship grades (office page)',
          url: 'https://global.donga.ac.kr/global/CMS/Contents/Contents.do?mCode=MN037',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: 'TOPIK 한국어능력시험',
          labelEn: 'TOPIK — Test of Proficiency in Korean',
          descriptionKo: '원서 접수·시험 일정·성적 확인',
          descriptionEn: 'Registration, exam dates and results',
          url: 'https://www.topik.go.kr/',
          iconName: 'translate',
        ),
        GuideLink(
          labelKo: '국제교류과 051-200-6447',
          labelEn: 'International Affairs 051-200-6447',
          descriptionKo: 'TOPIK 장학 문의(2026학년도 안내 기준)',
          descriptionEn: 'TOPIK scholarship questions (per the 2026 notice)',
          url: 'tel:0512006447',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '장학 반영액 확인과 납부',
          descriptionEn: 'Checking the amount after scholarships, and paying',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업요건 확인',
          labelEn: 'Guide — Checking Graduation Requirements',
          descriptionKo: '졸업용 TOPIK 성적 제출',
          descriptionEn: 'Submitting TOPIK for graduation',
          url: '/guide/item/graduation-requirements',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 시간제취업(아르바이트) 허가',
          labelEn: 'Guide — Part-time Work Permission',
          descriptionKo: 'TOPIK 급수와 허용 시간',
          descriptionEn: 'TOPIK level and hours allowed',
          url: '/guide/item/part-time-work',
          iconName: 'work',
        ),
        GuideLink(
          labelKo: '가이드 — 국제교류과 방문 안내',
          labelEn: 'Guide — International Affairs Office',
          descriptionKo: '위치와 업무별 연락처',
          descriptionEn: 'Location and contacts by task',
          url: '/guide/item/oia-visit',
          iconName: 'location_on',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '장학금 수혜 확인서',
          descriptionEn: 'Scholarship receipt certificate',
          url: '/guide/item/certificate-issue',
          iconName: 'description',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '수강취소와 장학 학점 기준',
          descriptionEn: 'Dropping courses and the scholarship credit rule',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 졸업 후 구직(D-10) 체류',
          labelEn: 'Guide — Job-Seeking Visa (D-10) after Graduation',
          descriptionKo: '졸업 후 구직 변경과 한국어 요건',
          descriptionEn: 'Changing to D-10 after graduation, and the Korean-language '
              'condition',
          url: '/guide/item/d10-job-seeking',
          iconName: 'work',
        ),
        // r23 역연결: 「↪ 다른 과정이라면」의 대학원생 줄이 가리키는 새 가이드. 끝에 붙인다.
        GuideLink(
          labelKo: '가이드 — 대학원 학위과정 길잡이',
          labelEn: 'Guide — Graduate Degree Roadmap',
          descriptionKo: '대학원생: 외국어시험·종합시험·학위논문과 외국인장학금',
          descriptionEn: 'For graduate students: language and comprehensive '
              'exams, thesis, and the international scholarship',
          url: '/guide/item/graduate-degree-guide',
          iconName: 'school',
        ),
      ],
    ),

    // ── 학교 온라인 서비스 사용하기 ──────────────────────────────────────
    // 통합로그인(login.donga.ac.kr)·수강신청(dxsugang.donga.ac.kr/login) 공개 로그인 화면 ·
    // 동아대 홈페이지 E-캠퍼스(무선랜 이용안내·네트워크 접근 제어·학생메일&오피스 365)와
    // 기기별 무선랜 설정(/etc/ios·/etc/windows-10·/etc/wifi-setup) · 학생증 발급안내 ·
    // 원격교육지원센터 LMS 안내(MN020) · eclass 공개 첫 화면 · 국제교류과 「외국인 유학생
    // 수강신청 안내 책자」 2026.8판 인쇄 p.2 — 2026-10-30 A 가 원문으로 읽음(089 근거표).
    // 로그인 뒤 화면은 확인하지 않았으므로 메뉴는 공개 안내에 적힌 이름만 쓴다. 시스템 이름은
    // 홈페이지 E-캠퍼스 메뉴의 「통합정보시스템」으로 통일하고, 같은 곳을 부르는 「학생정보」·
    // 「학생정보서비스」는 본문 한 줄과 별칭으로 둔다(리드 r21 결정 ②).
    AdminGuideItem(
      id: 'campus-online-services',
      categoryId: GuideCategory.school,
      searchAliasesKo: ['통합정보시스템', '학생정보', '학생정보서비스', '포털', 'LMS', '학교 메일', '오피스 365',
        '와이파이', '모바일 학생증', '캠퍼스락', '비밀번호 찾기'],
      searchAliasesEn: ['student portal', 'dx', 'LMS', 'eclass', 'school email',
        'Office 365', 'Wi-Fi', 'wifi', 'student ID', 'password', 'login'],
      titleKo: '학교 온라인 서비스 사용하기',
      titleEn: 'Using Dong-A Online Services',
      detailTitleKo: '통합정보시스템·LMS·메일·Wi-Fi — 어디에 어떤 계정으로 들어가나',
      detailTitleEn: 'Integrated system, LMS, email, Wi-Fi — where to log in, and '
          'with what',
      summaryKo: '첫 로그인·LMS·메일·Wi-Fi·학생증',
      summaryEn: 'First login, LMS, email, Wi-Fi, ID',
      iconName: 'computer',
      overviewKo: '동아대학교의 학생용 온라인 서비스는 대부분 학번과 학교 비밀번호 하나로 '
          '들어갑니다. 수강 내역·성적·등록금고지서·공결 신청 같은 학사 업무는 '
          '통합정보시스템(dx.donga.ac.kr)에서, 강의자료와 과제는 LMS에서 '
          '처리하고, Wi-Fi·모바일 학생증·학생메일도 같은 계정으로 시작합니다.\n\n'
          '처음에는 어느 사이트로 가야 하는지, 학번이 나오기 전에는 무엇으로 '
          '로그인하는지에서 막히기 쉽습니다. 이 가이드는 서비스별 주소와 로그인 방법, '
          '막혔을 때 연락할 곳을 정리합니다. 각 업무의 자세한 절차는 연결된 가이드에서 '
          '확인하세요. 이 안내는 학위과정 재학생 기준입니다. 교환학생과 한국어학당 학생은 '
          '계정·메일·학생증을 쓸 수 있는지 국제교류과(051-200-6447)나 '
          '한국어학당(051-200-6446)에 확인하세요.\n\n'
          '학교 홈페이지의 영어·중국어·베트남어 화면은 Google 자동 번역이라고 학교가 '
          '안내합니다. 연결된 시스템이 모두 외국어로 나오는 것은 아니므로, 이 가이드는 '
          '메뉴 이름을 한국어 그대로 적었습니다.',
      overviewEn: 'Most of Dong-A’s student services use one login: your student '
          'number and your university password. Academic tasks — your '
          'registered courses, grades, tuition bill, excused-absence '
          'requests — are done in the integrated information system '
          '(dx.donga.ac.kr); course materials and assignments are in the '
          'LMS; Wi-Fi, the mobile student ID and student email start from '
          'the same account.\n\n'
          'The usual sticking points are which site to go to and what to '
          'log in with before you have a student number. This guide lists '
          'the address and login for each service, and whom to contact '
          'when you are stuck. For the full procedure of each task, follow '
          'the linked guides. This guide is for degree students; exchange '
          'and Korean Language Institute students should check with the '
          'Office of International Affairs (051-200-6447) or the institute '
          '(051-200-6446) which accounts, email and ID they can use.\n\n'
          'The university says the English, Chinese and Vietnamese '
          'versions of its homepage are Google machine translations, and '
          'not every linked system has them — so this guide keeps menu '
          'names in Korean.',
      topSections: [
        GuideSection(
          titleKo: '처음 로그인 — 학번이 나오기 전과 후',
          titleEn: 'First login — before and after you have a student number',
          iconName: 'badge',
          notes: [
            GuideNote(
              titleKo: '학번이 나온 뒤',
              titleEn: 'Once you have a student number',
              linesKo: [
                '아이디는 학번, 비밀번호는 통합정보시스템 비밀번호입니다. 통합로그인 화면은 '
                    '학생에게 「기존에 설정된 비밀번호를 그대로」 쓰라고 안내합니다.',
                '비밀번호는 문자·숫자·특수문자를 섞은 9자리 이상입니다.',
                '아이디 찾기·비밀번호 찾기·비밀번호 변경은 통합정보시스템(dx.donga.ac.kr'
                    ')에서 합니다.',
              ],
              linesEn: [
                'Your ID is your student number and your password is your '
                    'integrated-system password. The single sign-on page tells '
                    'students to keep using the password already set.',
                'Passwords are at least 9 characters and mix letters, numbers '
                    'and symbols.',
                'Finding your ID, resetting or changing your password are done '
                    'in the integrated information system (dx.donga.ac.kr).',
              ],
            ),
            GuideNote(
              titleKo: '학번이 나오기 전 — 신입·편입생 수강신청',
              titleEn: 'Before you have one — new and transfer students registering for '
                  'courses',
              linesKo: [
                '아이디는 원서접수 수험번호입니다. 수험번호는 '
                    '진학어플라이(www.jinhakapply.com)에서 조회합니다.',
                '수강신청 로그인 화면의 초기 비밀번호: 생년월일 6자리 + 입학원서에 적은 '
                    '휴대폰번호 뒤 4자리(총 10자리)',
                '국제교류과 2026.8 신입생 안내책자는 같은 수강신청 화면의 외국인 신입생 '
                    '초기 비밀번호를 「생년월일 6자리 + 0000」(예: 2002.01.01. → '
                    '0201010000)으로 안내했습니다.',
                '두 안내 중 어느 쪽이 누구에게 적용되는지는 공개된 안내에 적혀 있지 '
                    '않습니다. 수강신청 전에 국제교류과(051-200-6447)에 확인하세요.',
              ],
              linesEn: [
                'Your ID is your application number. Look it up on Jinhak Apply '
                    '(www.jinhakapply.com).',
                'Initial password on the course registration login page: your '
                    'date of birth (6 digits) + the last 4 digits of the mobile '
                    'number on your application (10 digits in all)',
                'The Office of International Affairs handbook for new students '
                    '(Aug 2026) gave international freshmen a different initial '
                    'password for the same registration page: «date of birth (6 '
                    'digits) + 0000» (e.g. 2002.01.01. → 0201010000).',
                'Neither source says which one applies to whom. Before '
                    'registration opens, ask the Office of International Affairs '
                    '(051-200-6447) which to use.',
              ],
            ),
          ],
          noticeKo: '학번이 나오면 학번으로 / 신·편입생도 학번이 부여된 뒤에는 수험번호가 아니라 '
              '학번으로 로그인합니다.',
          noticeEn: 'Switch to your student number / New and transfer students log '
              'in with their student number, not the application number, once '
              'it is issued.',
          noticeIconName: 'badge',
          footnoteKo: '※ 통합로그인(login.donga.ac.kr)·수강신청(dxsugang.donga'
              '.ac.kr) 로그인 화면 안내와 국제교류과 「외국인 유학생 수강신청 안내 책자」 '
              '2026.8판 인쇄 p.2 기준, 2026-10-30 확인. 두 초기 비밀번호 '
              '안내가 서로 다릅니다.',
          footnoteEn: '※ Based on the login pages of the single sign-on '
              '(login.donga.ac.kr) and course registration '
              '(dxsugang.donga.ac.kr) sites and the Office of International '
              'Affairs handbook for international students, Aug 2026 edition, '
              'printed p.2, checked 2026-10-30. The two initial-password '
              'instructions differ.',
        ),
      ],
      checklistTitleKo: '처음 쓰기 전에 준비할 것',
      checklistTitleEn: 'Have these ready',
      checklistKo: [
        '학번(아직 없으면 원서접수 수험번호)',
        '통합정보시스템 비밀번호',
        '본인 사진 — 모바일 학생증 발급에 필요',
        '여권과 같은 영문 성명 — 영문 증명서 발급 전에 등록',
        '앱을 설치할 스마트폰, LMS용 PC(Chrome 권장)',
      ],
      checklistEn: [
        'Your student number (or your application number if you do not '
            'have one yet)',
        'Your integrated-system password',
        'A photo of yourself — needed for the mobile student ID',
        'Your English name exactly as in your passport — register it '
            'before you need an English certificate',
        'A smartphone for the apps, and a PC for the LMS (Chrome '
            'recommended)',
      ],
      stepsKo: [
        '통합정보시스템에 로그인해 본다. 학번과 비밀번호로 들어가지는지 먼저 확인합니다. '
            '학번이 아직 없으면 위 「처음 로그인」을 보세요 — 수험번호 로그인은 수강신청 '
            '사이트 안내에만 있습니다. 안 되면 아래 「막혔을 때」를 보세요.',
        'Wi-Fi를 쓰기 전에 비밀번호를 바꾼다. 학교는 통합정보시스템(학생정보서비스) '
            '비밀번호를 변경해야 무선랜을 쓸 수 있다고 안내합니다.',
        '학생정보에 사진과 영문 성명을 등록한다. 사진이 없으면 모바일 학생증이 발급되지 '
            '않고, 영문 성명이 없으면 영문 증명서를 발급받을 수 없습니다.',
        '모바일 학생증 앱 「캠퍼스락」을 설치한다. Google Play·App '
            'Store에서 「캠퍼스락」을 검색해 설치하고 학번·비밀번호로 로그인합니다.',
        'LMS(eclass.donga.ac.kr)에 들어가 수강 과목을 확인한다. '
            '로그인할 때 「통합 로그인」을 고릅니다. 모바일 앱은 LearningX '
            'Student입니다.',
        '학생메일·오피스 365 계정을 만든다. 홈페이지 E-캠퍼스 › 학생메일&오피스 '
            '365에서 통합정보시스템의 클라우드 서비스로 들어가 계정을 생성합니다.',
      ],
      stepsEn: [
        'Try logging in to the integrated information system. Check that '
            'your student number and password work. If you have no student '
            'number yet, see «First login» above — logging in with an '
            'application number is described only for the course '
            'registration site. If it does not work, see «If you are stuck» '
            'below.',
        'Change your password before using Wi-Fi. The university says '
            'campus Wi-Fi only works after you change your integrated-system '
            '(student information service) password.',
        'Register your photo and English name in student information. '
            'Without a photo the mobile student ID cannot be issued, and '
            'without an English name you cannot get English certificates.',
        'Install the mobile student ID app, «캠퍼스락» '
            '(CampusLock). Search for it on Google Play or '
            'the App Store and log in with your student '
            'number and password.',
        'Open the LMS (eclass.donga.ac.kr) and check '
            'your courses. Choose «통합 로그인» (single '
            'sign-on) when you log in. The mobile app is '
            'LearningX Student.',
        'Create your student email and Office 365 '
            'accounts. From the homepage, go to E-캠퍼스 › '
            '학생메일&오피스 365 and follow the link to the cloud '
            'service in the integrated system.',
      ],
      sections: [
        GuideSection(
          titleKo: '어디서 무엇을 하나요',
          titleEn: 'Which service does what',
          iconName: 'computer',
          notes: [
            GuideNote(
              titleKo: '통합정보시스템 — dx.donga.ac.kr',
              titleEn: 'Integrated information system — dx.donga.ac.kr',
              linesKo: [
                '수강 내역·성적·등록금고지서·공결 신청·졸업 사정표·개인정보 변경 등 학사 업무를 '
                    '합니다.',
                '학교 안내에 따라 「학생정보」·「학생정보서비스」라고도 부르며, 모두 이 주소입니다.',
              ],
              linesEn: [
                'Academic tasks: your registered courses, grades, tuition bill, '
                    'excused-absence requests, graduation audit, personal details.',
                'University pages also call it «학생정보» (student '
                    'information) or «학생정보서비스» (student '
                    'information service) — all the same address.',
              ],
            ),
            GuideNote(
              titleKo: '수강신청 — dxsugang.donga.ac.kr',
              titleEn: 'Course registration — dxsugang.donga.ac.kr',
              linesKo: [
                '수강신청·정정을 하는 별도 사이트입니다. 기간과 절차는 「수강신청」 가이드를 '
                    '보세요.',
              ],
              linesEn: [
                'A separate site for registering and changing courses. For dates '
                    'and steps, see the course registration guide.',
              ],
            ),
            GuideNote(
              titleKo: 'LMS — eclass.donga.ac.kr',
              titleEn: 'LMS — eclass.donga.ac.kr',
              linesKo: [
                '강의자료·과제·온라인 강의와 진도·출석을 관리하는 학습관리시스템입니다.',
                '모바일 앱: LearningX Student(Android는 LearningX '
                    'Student 2.0)',
                '첫 화면에서 한국어·영어를 고를 수 있습니다.',
              ],
              linesEn: [
                'The learning management system for course materials, '
                    'assignments, online lectures, progress and attendance.',
                'Mobile app: LearningX Student (on Android, LearningX Student '
                    '2.0)',
                'The front page can be switched between Korean and English.',
              ],
            ),
            GuideNote(
              titleKo: 'Wi-Fi — donga-wpa2',
              titleEn: 'Wi-Fi — donga-wpa2',
              linesKo: [
                '사용자 이름은 학번, 암호는 학생정보서비스(통합정보시스템) 비밀번호입니다.',
                '기기별 설정 방법은 학교 「무선랜 이용안내」에 있습니다. 비밀번호가 틀리면 '
                    '통합정보시스템에서 비밀번호를 초기화한 뒤 다시 로그인하라고 안내합니다.',
                '다른 대학에서는 eduroam에 「무선랜ID@dau.ac.kr」로 접속할 수 '
                    '있습니다.',
              ],
              linesEn: [
                'User name: your student number. Password: your student '
                    'information service (integrated-system) password.',
                'Set-up steps for each device are on the university’s Wi-Fi '
                    'page. If the password is rejected, the page says to reset it in '
                    'the integrated system and log in again.',
                'At other universities you can join eduroam as '
                    '«무선랜ID@dau.ac.kr» (your Wi-Fi ID@dau.ac.kr).',
              ],
            ),
            GuideNote(
              titleKo: '모바일 학생증 — 캠퍼스락 앱',
              titleEn: 'Mobile student ID — the 캠퍼스락 app',
              linesKo: [
                '학생정보에 본인 사진을 등록해야 발급됩니다.',
                '도서관 출입·대출에 쓰는 「모바일 이용증」은 도서관 앱에 따로 있습니다.',
                '시험장 신분증으로는 외국인등록증이나 여권을 가져가세요.',
              ],
              linesEn: [
                'It is only issued once your photo is registered in student '
                    'information.',
                'The library’s «mobile library card» for entry and loans is a '
                    'separate thing, in the library app.',
                'For exams, bring your residence card or passport as ID.',
              ],
            ),
          ],
          noticeKo: 'portal.donga.ac.kr은 교직원용입니다 / 홈페이지에서 「그룹웨어」로 '
              '연결되는 portal.donga.ac.kr의 화면 제목은 교직원정보시스템입니다. '
              '학생 업무는 통합정보시스템에서 시작하세요.',
          noticeEn: 'portal.donga.ac.kr is for staff / The «그룹웨어» '
              '(groupware) link on the homepage goes to '
              'portal.donga.ac.kr, titled «staff information '
              'system». Start student tasks from the '
              'integrated system.',
          noticeIconName: 'info',
          footnoteKo: '※ 동아대학교 홈페이지 E-캠퍼스(무선랜 이용안내·기기별 설정·네트워크 접근 '
              '제어·학생메일&오피스 365), 학생증 발급안내, 원격교육지원센터 LMS 안내 '
              '기준, 2026-10-30 확인. 로그인한 뒤의 메뉴 위치는 바뀔 수 있습니다.',
          footnoteEn: '※ Based on the university homepage E-campus pages (Wi-Fi, '
              'device set-up, network access control, student email & Office '
              '365), the student ID page and the Distance Education Center’s '
              'LMS page, checked 2026-10-30. Menus after login may move.',
        ),
        GuideSection(
          titleKo: '막혔을 때',
          titleEn: 'If you are stuck',
          iconName: 'call',
          notes: [
            GuideNote(
              titleKo: '본인인증이 안 될 때',
              titleEn: 'If identity verification fails',
              linesKo: [
                '통합로그인 화면은 본인 인증을 하지 못하면 정보전산과로 문의하라고 안내합니다: '
                    '051-200-6803, 6820, 6837, 6723',
                '학번 찾기에는 성명·생년월일 6자리·휴대폰번호가 필요합니다. 조회되지 않으면 '
                    '이름이나 번호를 임의로 바꿔 넣지 말고 문의하세요.',
              ],
              linesEn: [
                'The single sign-on page says to contact the Information '
                    'Technology Division if you cannot verify your identity: '
                    '051-200-6803, 6820, 6837, 6723',
                'Looking up your student number needs your name, date of birth '
                    '(6 digits) and mobile number. If it does not work, ask rather '
                    'than trying other spellings or numbers.',
              ],
            ),
            GuideNote(
              titleKo: '서비스별 문의처',
              titleEn: 'Who to call',
              linesKo: [
                'Wi-Fi: 정보전산원 교육지원팀 051-200-6809, 6119',
                'LMS: LMS 안의 문의게시판, 원격교육지원센터 051-200-1046',
                '증명서: 학사관리과 051-200-6090~1',
                '학번·초기 비밀번호 등 유학생 학사: 국제교류과 051-200-6447',
              ],
              linesEn: [
                'Wi-Fi: IT Center, Education Support Team, 051-200-6809, 6119',
                'LMS: the question board inside the LMS, or the Distance '
                    'Education Center, 051-200-1046',
                'Certificates: Academic Affairs, 051-200-6090~1',
                'Student number, initial password and other academic questions '
                    'for international students: Office of International Affairs, '
                    '051-200-6447',
              ],
            ),
          ],
          noticeKo: '계정은 본인만 씁니다 / 다른 사람의 학번으로 로그인하거나 인증을 대신 받게 하지 '
              '마세요. 본인 정보로 인증이 안 되면 위 담당 부서에 문의하세요.',
          noticeEn: 'Use only your own account / Do not log in with someone else’s '
              'student number or have someone verify for you. If your own '
              'details do not work, contact the office above.',
          noticeIconName: 'warning',
          footnoteKo: '※ 부서 이름과 번호는 각 서비스 안내 페이지의 표기 그대로입니다(통합로그인 화면 '
              '「정보전산과」, 무선랜 이용안내 「정보전산원 교육지원팀」). 2026-10-30 '
              '확인.',
          footnoteEn: '※ Office names and numbers are as each '
              'service page shows them (the sign-on page '
              'says «정보전산과», the Wi-Fi page «정보전산원 교육지원팀»). '
              'Checked 2026-10-30.',
        ),
        GuideSection(
          titleKo: '개인정보를 바꿀 때',
          titleEn: 'Changing your details',
          iconName: 'edit_location_alt',
          notes: [
            GuideNote(
              titleKo: '학교 시스템과 출입국 신고는 따로',
              titleEn: 'The university system and immigration are separate',
              linesKo: [
                '학생정보에서 주소를 바꿔도 출입국 체류지 변경신고가 되지 않습니다. 이사했다면 '
                    '「체류지·등록사항 변경신고」 가이드를 따로 보세요.',
                '영문 성명은 학생정보 › 학적변동 › 개인정보변경에서 등록합니다. 여권과 같은 '
                    '철자로 넣으세요.',
              ],
              linesEn: [
                'Changing your address in student information does not report it '
                    'to immigration. If you have moved, see the address-change guide '
                    'as well.',
                'Register your English name under 학생정보 › 학적변동 '
                    '› 개인정보변경 (student information › record '
                    'changes › personal details), spelled exactly '
                    'as in your passport.',
              ],
            ),
          ],
        ),
      ],
      tipsKo: [
        '🌐 학교 홈페이지의 외국어 화면은 자동 번역입니다. 메뉴는 한국어 이름으로 찾는 '
            '것이 정확합니다.',
        '💻 LMS는 PC에서 Chrome을 쓰라고 안내합니다.',
        '📱 학생증 앱(캠퍼스락)과 도서관 앱(모바일 이용증)은 서로 다른 앱입니다.',
      ],
      tipsEn: [
        '🌐 The homepage’s foreign-language versions are machine '
            'translations. Searching for menus by their Korean names is more '
            'reliable.',
        '💻 The LMS recommends Chrome on a PC.',
        '📱 The student ID app (캠퍼스락) and the library '
            'app (mobile library card) are different apps.',
      ],
      phrases: [
        GuidePhrase(
          ko: '통합정보시스템에 로그인할 수 없습니다. 본인인증을 도와주실 수 있나요?',
          en: 'I cannot log in to the integrated information system. Could you '
              'help me with identity verification?',
        ),
        GuidePhrase(
          ko: '아직 학번이 없습니다. 수강신청 초기 비밀번호를 확인하고 싶습니다.',
          en: 'I do not have a student number yet. I would like to check my '
              'initial password for course registration.',
        ),
      ],
      status: GuideStatus.published,
      links: [
        GuideLink(
          labelKo: '동아대학교 통합정보시스템',
          labelEn: 'Dong-A integrated information system',
          descriptionKo: '학사·등록·성적·개인정보',
          descriptionEn: 'Academic records, tuition, grades, personal details',
          url: 'https://dx.donga.ac.kr/',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '동아대학교 통합로그인',
          labelEn: 'Dong-A single sign-on',
          descriptionKo: '로그인 안내·본인인증 문의처',
          descriptionEn: 'Login help and who to call for verification',
          url: 'https://login.donga.ac.kr/login?rd_c_p=checked',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '동아대학교 수강신청',
          labelEn: 'Dong-A course registration',
          descriptionKo: '신·편입생 수험번호 로그인 안내',
          descriptionEn: 'Login help for new and transfer students',
          url: 'https://dxsugang.donga.ac.kr/',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '동아대학교 LMS',
          labelEn: 'Dong-A LMS',
          descriptionKo: '강의자료·과제·온라인 강의',
          descriptionEn: 'Course materials, assignments, online lectures',
          url: 'https://eclass.donga.ac.kr/',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: 'LMS 이용 안내(원격교육지원센터)',
          labelEn: 'LMS help (Distance Education Center)',
          descriptionKo: '앱 이름·로그인·문의처',
          descriptionEn: 'App names, login and contacts',
          url: 'https://dec.donga.ac.kr/dec/CMS/Contents/Contents.do?mCode=MN020',
          iconName: 'help',
        ),
        GuideLink(
          labelKo: '학생메일&오피스 365',
          labelEn: 'Student email & Office 365',
          descriptionKo: '계정 생성·관리 안내',
          descriptionEn: 'Creating and managing the accounts',
          url: 'https://www.donga.ac.kr/community/e-campus/email',
          iconName: 'computer',
        ),
        GuideLink(
          labelKo: '무선랜 이용안내',
          labelEn: 'Campus Wi-Fi',
          descriptionKo: '기기별 설정·이용 가능 건물',
          descriptionEn: 'Set-up by device and where it works',
          url: 'https://www.donga.ac.kr/community/e-campus/wifi',
          iconName: 'smartphone',
        ),
        GuideLink(
          labelKo: '학생증 발급안내',
          labelEn: 'Student ID',
          descriptionKo: '모바일 학생증(캠퍼스락)·사진 등록',
          descriptionEn: 'Mobile student ID (캠퍼스락) and photo upload',
          url: 'https://www.donga.ac.kr/community/life-info/student-id',
          iconName: 'badge',
        ),
        GuideLink(
          labelKo: '정보전산과 051-200-6803',
          labelEn: 'IT Division 051-200-6803',
          descriptionKo: '본인인증 문의(통합로그인 안내 기준)',
          descriptionEn: 'Identity verification (per the sign-on page)',
          url: 'tel:0512006803',
          iconName: 'call',
        ),
        GuideLink(
          labelKo: '가이드 — 수강신청',
          labelEn: 'Guide — Course Registration',
          descriptionKo: '기간·학점·확정 확인',
          descriptionEn: 'Dates, credits and confirmation',
          url: '/guide/item/course-registration',
          iconName: 'school',
        ),
        GuideLink(
          labelKo: '가이드 — 증명서 발급',
          labelEn: 'Guide — Certificate Issuance',
          descriptionKo: '인터넷 발급·영문 성명 등록',
          descriptionEn: 'Online issuance and registering your English name',
          url: '/guide/item/certificate-issue',
          iconName: 'description',
        ),
        GuideLink(
          labelKo: '가이드 — 등록금 납부·등록 확인',
          labelEn: 'Guide — Paying Tuition & Confirming Registration',
          descriptionKo: '고지서 출력과 납부 확인',
          descriptionEn: 'Printing the bill and confirming payment',
          url: '/guide/item/tuition-payment',
          iconName: 'payments',
        ),
        GuideLink(
          labelKo: '가이드 — 출결·공결·시험·성적',
          labelEn: 'Guide — Attendance, Exams & Grades',
          descriptionKo: '공결 신청·성적 확인',
          descriptionEn: 'Excused absences and grades',
          url: '/guide/item/class-attendance-and-exams',
          iconName: 'fact_check',
        ),
        GuideLink(
          labelKo: '가이드 — 도서관 이용안내',
          labelEn: 'Guide — Library Guide',
          descriptionKo: '도서관 앱과 모바일 이용증',
          descriptionEn: 'The library app and mobile library card',
          url: '/guide/item/library-guide',
          iconName: 'menu_book',
        ),
        GuideLink(
          labelKo: '가이드 — 체류지·등록사항 변경신고',
          labelEn: 'Guide — Reporting Address & Registration Changes',
          descriptionKo: '이사했을 때 출입국 신고',
          descriptionEn: 'Reporting a move to immigration',
          url: '/guide/item/address-and-registration-changes',
          iconName: 'edit_location_alt',
        ),
      ],
    ),
  ];
}
