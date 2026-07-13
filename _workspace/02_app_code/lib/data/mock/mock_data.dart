import '../../domain/entities/facility.dart';
import '../../domain/entities/admin_guide.dart';

/// Seed data for week-2 development. The api-integrator replaces the repository
/// implementations (not this file) with Firestore; this stays as fixtures for
/// tests / offline demo.
class MockData {
  const MockData._();

  static final List<Facility> facilities = [
    const Facility(
      id: 'lib-central',
      nameKo: '중앙도서관',
      nameEn: 'Central Library',
      category: FacilityCategory.library,
      lat: 37.5670,
      lng: 126.9785,
      addressKo: '캠퍼스 A동 옆',
      addressEn: 'Next to Building A',
      buildingKo: '도서관동',
      buildingEn: 'Library Hall',
      hoursKo: '09:00–22:00 (평일)',
      hoursEn: '09:00–22:00 (weekdays)',
      phone: '02-000-0001',
      descriptionKo: '열람실, 그룹스터디룸, 노트북 대여를 제공합니다.',
      descriptionEn: 'Reading rooms, group study rooms, laptop rentals.',
    ),
    const Facility(
      id: 'dining-union',
      nameKo: '학생회관 식당',
      nameEn: 'Student Union Cafeteria',
      category: FacilityCategory.dining,
      lat: 37.5662,
      lng: 126.9772,
      buildingKo: '학생회관 1F',
      buildingEn: 'Student Union 1F',
      hoursKo: '11:00–19:00',
      hoursEn: '11:00–19:00',
      phone: '02-000-0002',
    ),
    const Facility(
      id: 'bld-eng-3',
      nameKo: '공학관 3호관',
      nameEn: 'Engineering Building 3',
      category: FacilityCategory.building,
      lat: 37.5675,
      lng: 126.9760,
      buildingKo: 'E동',
      buildingEn: 'Building E',
    ),
    const Facility(
      id: 'cafe-on',
      nameKo: '카페 온',
      nameEn: 'Cafe On',
      category: FacilityCategory.amenity,
      lat: 37.5668,
      lng: 126.9790,
      hoursKo: '08:00–20:00',
      hoursEn: '08:00–20:00',
    ),
    const Facility(
      id: 'oia-office',
      nameKo: '국제교류처',
      nameEn: 'Office of International Affairs',
      category: FacilityCategory.building,
      lat: 37.5660,
      lng: 126.9788,
      buildingKo: 'A동 2F',
      buildingEn: 'Building A 2F',
      hoursKo: '09:00–17:00 (평일)',
      hoursEn: '09:00–17:00 (weekdays)',
      phone: '02-000-0003',
    ),
    const Facility(
      id: 'room-101',
      nameKo: '제1강의동 101호',
      nameEn: 'Lecture Hall 1 Room 101',
      category: FacilityCategory.classroom,
      lat: 37.5672,
      lng: 126.9778,
    ),
  ];

  static final List<AdminGuideItem> guideItems = [
    const AdminGuideItem(
      id: 'arc-issue',
      categoryId: GuideCategory.immigration,
      titleKo: '외국인등록증 발급',
      titleEn: 'Alien Registration Card',
      summaryKo: '입국 90일 이내 신청',
      summaryEn: 'Apply within 90 days of entry',
      relatedFacilityIds: ['oia-office'],
      status: GuideStatus.published,
    ),
    const AdminGuideItem(
      id: 'bank-account',
      categoryId: GuideCategory.living,
      titleKo: '은행 계좌 개설',
      titleEn: 'Open a Bank Account',
      summaryKo: '여권·외국인등록증 지참',
      summaryEn: 'Bring passport & ARC',
      status: GuideStatus.comingSoon,
    ),
    const AdminGuideItem(
      id: 'library-guide',
      categoryId: GuideCategory.school,
      titleKo: '도서관 이용 안내',
      titleEn: 'Library Guide',
      summaryKo: '대출·열람실 이용',
      summaryEn: 'Borrowing & reading rooms',
      relatedFacilityIds: ['lib-central'],
      status: GuideStatus.comingSoon,
    ),
  ];
}
