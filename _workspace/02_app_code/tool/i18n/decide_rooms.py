# -*- coding: utf-8 -*-
"""Writes the hand decisions for the 281 names the rules could not place.

Each name gets generic (translate), proper (keep the Korean sign text), or
unsure (still Korean, still listed). The reason is recorded so the call can be
argued with instead of guessed at.
"""
import io
import json

OUT = 'tool/i18n/room_decisions.json'

G = {}
P = {}
U = {}


def g(reason, *names):
    for n in names:
        G[n] = reason


def p(reason, *names):
    for n in names:
        P[n] = reason


def u(reason, *names):
    for n in names:
        U[n] = reason


# --- a kind of space, written with a stray space or an odd spelling -----------
g('kind_of_space', '주 방', '주 방(임대)', '강 당', '매 점', '창 고', '식 당(임대)',
  '커피점', '복사점', '복사점(임대)', '구내서점', '스넥코너', '차고', '저수조',
  '무기고', '목공소', '철공소', '탁구장', '골프장(옥외)', '테니스장(옥외)',
  '체육관및대강당', '대강당(상부)', '대강당(하부)', '공대서류고', '창의공간',
  '코워킹스페이스', '글로벌 존', '유스호스텔', '동문방', '육아시설',
  '출판부인쇄소', '차세대LSI LAB', '모바일네트워크랩', '공학스튜디오',
  '실내건축스튜디오', '메이커스페이스 스튜디오', '특성화사업 예정 공간',
  '지정폐기물임시보관장(안전관리센터)', '안내실(우편물)', '입주기업',
  'STUDY ROOM1~6', '설계실D', '설계실E', '설계실F', '설계실G', '설계실H',
  '도시공학과설계실3-1', '시험실-1~12', '전공실기실1~61', '물리교육실험',
  '생활체육', '산업체인력교육장', '경기지도자연수원')

# --- rooms named after what is done in them ----------------------------------
g('functional_room', '모의대법정', '모의법정(민사)', '모의법정(형사)',
  '목업실(레이져,3D프린터)', '목업실(이미징스튜디오)', '배양실(병균접종)',
  '배양실(토양비료,조직배양)', '식물생장조절실(단일)', '식물생장조절실(장일)',
  '응급시뮬레이션실(ER)', '중환자시뮬레이션실(ICU)', '의학시뮬레이션랩',
  '의학시뮬레이션센터(Debriefing Room)', '안전관리센터(방사선안전관리실)',
  '이슬람문화실(남)', '이슬람문화실(여)', '생활지도실(여)', '생활지도자실(여)',
  '과제도서실(경영대학원)', '과제도서실(사회복지)', '과제도서실(전자)',
  '과제도서실(환경)', '외국어특강실1~3', '외국어특강실(공자아카데미)',
  '석당전용학습실1~3', '튜터링학습실[국문학과(야)/영문학과(야)]',
  '정보처리교육실(생자대)', '정보처리교육실(스포츠대B)', '정보처리교육실(인문대)',
  '정보처리교육실(자연대)', '정보처리교육실(학생회관)', '정보처리교육실A',
  '정보처리교육실B', '교양교육원(영어수업지원실)',
  '원격교육지원센터 e-러닝 스튜디오 A', '편의시설(농협)', '편의시설(서점)',
  '편의시설(분식점)(임대)', '편의시설(패스트푸드)(임대)', '복지임대마장(여행사)')

# --- exam and job preparation rooms ------------------------------------------
g('exam_prep', '고시반', '국가고시반', '언론고시반', '관세사반',
  '고시연구반실(기술고시)', '의과대학고시방', '임용고사 준비반',
  '인문대 취업준비반')

# --- a university office, institute or committee -----------------------------
g('university_unit', '정보기술연구소', '경영문제연구소', '관광레저연구소',
  '글로벌금융연구소', '기업가정신연구소', '법학연구소', '맑스엥겔스연구소',
  '해양자원연구소', '해양도시건설·방재연구소', '젠더·어펙트연구소',
  '젠더어펙트연구소', '국어문화원', '언어교육원', '석당학술원',
  '석당학술원 인문도시지원사업단', '교수협의회', '사무국',
  '관리과(관리1팀)', '관리과(관리2팀)', '관리과(비품지원팀)',
  '행정지원실(통합)', '행정지원실(통합대학원)', '원장실(경영대학원)',
  '원장실(국제전문대학원)', '원장실(사회복지대학원)',
  '미디어디바이스연구센터(소장실)', '교육연구정책실/BK총괄사업단',
  '동아대학교 소비자생활협동조합', '경영대학원동문회', '청촌장학재단',
  '소방심리지원단', '부산어린이 복합문화공간 시범사업 운영지원단',
  '총학생회', '총학생회학생소통위원회', '학생복지위원회/학생권익위원회',
  '건축공학과학생회', '기계공학과학생회')

# --- a project office or platform: the acronym stays, the words translate -----
g('project_office', 'URP사업단', 'UPR사업단', 'URP사업단 사무국',
  'URP사업단 비즈니스 랩', 'URP사업단 프로젝트 랩', 'URP사업단 입주기업',
  'URP사업단스마트팩토리실증테스트베드', 'SW전문인재양성사업단',
  '친환경스마트선박R&D/스마트공장운영설계전문인력양성사업단',
  'AI·디지털트윈 실증 플랫폼(AI 3-Ex 기술 체험룸)',
  'AI·디지털트윈 실증 플랫폼(AI 3-Ex 클라우드서버룸)',
  'AI·디지털트윈 실증 플랫폼(AI 디지털트윈 PBL실)',
  '디지털혁신허브(DI-Hub)', 'HUMANUTAS 컨텐츠 스튜디오',
  '바이오·헬스 플랫폼1', '정밀화학 소재·부품·장비 플랫폼',
  '창의오아시스플랫폼1', '창의오아시스플랫폼2',
  '스마트웰니스플랫폼(동아기능성운동트레이닝센터)')

# --- a nursery class: the class name stays, the room word translates ---------
g('nursery_class', '도담반(보육실)', '마루반(보육실)', '아라반(보육실)',
  '한울반(보육실)')

# --- a club whose name says what it does -------------------------------------
g('club_descriptive', '동아검도회-1', '동아검도회-2', '동아농구회', '동아수영회',
  '동아탁구회', '동아테니스', '동아싸이클', '동아요트', '동아볼링연구회',
  '동아자동차연구회', '동아화학공학연구회(KEMI)', '동아증권연구회(DUSC)',
  '동아교지편집위원회', '동아시아평화인권캠프', '극예술연구회',
  '사진예술연구회', '소설창작연구회', '영화예술연구회', '일본문학예술연구회',
  '불교학생회', '카톨릭학생회', '응원단', '합창단', '원드써핑',
  '한아리국악회', '생명자원산업학학회방', '식품생명공학학회방',
  '유전공학학회방', '응용생물공학회방')

# --- a person's name on the door --------------------------------------------
p('person', '김태철', '성낙창', '이수호', '임병찬', '조윤현', '최영익',
  'AI-디지털트윈실증랩(옥수열,이석환)',
  '교육성과관리센터(강요명,이선영,이승형,정성광)')

# --- a tenant company or a brand --------------------------------------------
p('company', '㈜유디엠', '노아전자', '도경기술', '도미토리솔루션', '서주테크',
  '스틸파트너', '씨엠알엔디', '제이에스데이타', '코테크엔지니어링',
  '효창엔지니어링', '블루맥스', '내쇼날', 'T.N.S 머시닝', '페이퍼펀',
  '포디브', '프릭스', '레브스텝', '커즈아이', '디스이즈', '부산은행',
  '스마트에듀케이션', 'CS디자인', 'N-care 플랫폼', 'S·MART LAB',
  'Lounge 동아 DAU:M', '팬코 글로벌존')

# --- a name that is only a name: a club, a room or a shop --------------------
p('name_only', '가리온', '그랑부르', '그리메', '기라성', '나눔', '내일',
  '노둣돌', '노래의메아리', '다연회', '다우악', '다울', '더조커',
  '따뜻한사람들', '라온', '라일락', '동이동모', '동아경당', '방구석',
  '바둑사랑', '사람과사랑', '상앗대', '성아회', '셈틀마당', '소리누리',
  '소리오름', '순대', '스니치', '신서유기', '아고라', '아마란스', '아미고',
  '안면당', '역동', '열림그림마당', '유네스코', '유니피스', '유레카',
  '이음맥', '인터카툰', '인터콥', '서부산로타렉트', '윤유월', '블링크',
  '석당함진재', '크레파스', '타래', '터', '파이', '팝콘', '하네', '하늘별',
  '한울림', '한울회', '호우회', '흙사랑', '희망')

# --- still a person's call --------------------------------------------------
u('needs_human', '미션1', '스틸샵')


def main():
    src = json.load(io.open('tool/i18n/room_classification.json', encoding='utf-8'))
    unsure = set(src['unsure'])
    decided = {}
    for bucket, kind in ((G, 'generic'), (P, 'proper'), (U, 'unsure')):
        for name, why in bucket.items():
            if name in decided:
                raise SystemExit('decided twice: ' + name)
            decided[name] = {'decision': kind, 'why': why}
    missing = sorted(unsure - set(decided))
    extra = sorted(set(decided) - unsure)
    doc = {
        '_what': '규칙으로 판정하지 못한 층별 안내 공간명을 사람이 판정한 결과. '
                 'classify_rooms.py가 규칙보다 먼저 읽는다.',
        '_who': '리드 클로드 2026-09-27 판정. 독립 검토 대상이다.',
        '_rule': 'generic은 번역 대상, proper는 문 앞 표지판대로 한국어 유지, '
                 'unsure는 판정 보류(한국어 유지).',
        'counts': {
            'generic': sum(1 for v in decided.values() if v['decision'] == 'generic'),
            'proper': sum(1 for v in decided.values() if v['decision'] == 'proper'),
            'unsure': sum(1 for v in decided.values() if v['decision'] == 'unsure'),
        },
        'decisions': {k: decided[k] for k in sorted(decided)},
    }
    io.open(OUT, 'w', encoding='utf-8', newline='').write(
        json.dumps(doc, ensure_ascii=False, indent=2) + '\n')
    print('decided', len(decided), doc['counts'])
    print('unsure rows with no decision:', len(missing))
    for m in missing:
        print('   MISSING', m)
    print('decisions not in the unsure list:', len(extra))
    for e in extra:
        print('   EXTRA', e)


main()
