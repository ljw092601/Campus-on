import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../domain/repositories/dining_repository.dart';

/// PLACEHOLDER dining data until the school API contract arrives
/// (TODO(dining-api)): three campus cafeterias with a small menu pool rotated
/// deterministically by date, closed on weekends. Cafeteria names/hours are
/// provisional too — replace everything with API data.
class MockDiningRepository implements DiningRepository {
  static const _latency = Duration(milliseconds: 120);

  // Menu pools rotated by day-of-month so every day looks plausible without
  // hand-writing a calendar.
  static const _lunchPool = [
    ['제육볶음', '미역국', '쌀밥', '배추김치', '콩나물무침'],
    ['치킨마요덮밥', '유부장국', '단무지', '샐러드'],
    ['돈까스', '크림수프', '쌀밥', '깍두기', '마카로니샐러드'],
    ['김치찌개', '계란말이', '쌀밥', '어묵볶음', '김'],
    ['불고기', '된장국', '쌀밥', '배추김치', '시금치나물'],
  ];
  static const _dinnerPool = [
    ['순두부찌개', '쌀밥', '배추김치', '멸치볶음'],
    ['카레라이스', '미소국', '단무지', '요구르트'],
    ['비빔밥', '계란국', '배추김치'],
    ['부대찌개', '쌀밥', '깍두기', '감자채볶음'],
  ];
  static const _breakfastPool = [
    ['토스트', '시리얼', '우유', '삶은계란'],
    ['북엇국', '쌀밥', '김', '배추김치'],
  ];

  @override
  Future<List<CafeteriaMenu>> getMenus(DateTime date) async {
    await Future<void>.delayed(_latency);
    final weekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final d = date.day;

    List<Meal> meals(List<MealType> types) => weekend
        ? const []
        : [
            for (final t in types)
              switch (t) {
                MealType.breakfast => Meal(
                    type: t,
                    items: _breakfastPool[d % _breakfastPool.length],
                    price: 3500),
                MealType.lunch => Meal(
                    type: t,
                    items: _lunchPool[d % _lunchPool.length],
                    price: 5500),
                MealType.dinner => Meal(
                    type: t,
                    items: _dinnerPool[d % _dinnerPool.length],
                    price: 5000),
              }
          ];

    return [
      CafeteriaMenu(
        id: 'seunghak-student',
        nameKo: '승학캠퍼스 학생식당',
        nameEn: 'Seunghak Student Cafeteria',
        campus: Campus.seunghak,
        hoursKo: '조식 08:00-09:30 · 중식 11:30-13:30 · 석식 17:00-18:30',
        hoursEn: 'Breakfast 08:00-09:30 · Lunch 11:30-13:30 · Dinner 17:00-18:30',
        facilityId: 's02',
        meals: meals(
            const [MealType.breakfast, MealType.lunch, MealType.dinner]),
      ),
      CafeteriaMenu(
        id: 'gudeok-student',
        nameKo: '구덕캠퍼스 학생식당',
        nameEn: 'Gudeok Student Cafeteria',
        campus: Campus.gudeok,
        hoursKo: '중식 11:30-13:30',
        hoursEn: 'Lunch 11:30-13:30',
        facilityId: 'g12',
        meals: meals(const [MealType.lunch]),
      ),
      CafeteriaMenu(
        id: 'bumin-student',
        nameKo: '부민캠퍼스 학생식당',
        nameEn: 'Bumin Student Cafeteria',
        campus: Campus.bumin,
        hoursKo: '중식 11:30-13:30 · 석식 17:00-18:30',
        hoursEn: 'Lunch 11:30-13:30 · Dinner 17:00-18:30',
        facilityId: 'b04',
        meals: meals(const [MealType.lunch, MealType.dinner]),
      ),
    ];
  }
}
