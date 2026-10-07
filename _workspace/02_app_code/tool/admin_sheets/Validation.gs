// ---------------------------------------------------------------------------
// 학사일정
// ---------------------------------------------------------------------------

function readAcademicRows_() {
  const sheet = requireSheet_(CONFIG.sheets.academic);
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return { sheet, rows: [], errors: [] };
  const values = sheet.getRange(2, 1, lastRow - 1, ACADEMIC_HEADERS.length).getValues();
  const rows = [];
  const errors = [];
  const ids = new Map();

  values.forEach((v, index) => {
    const rowNumber = index + 2;
    if (isBlankRow_(v)) return;
    let eventId = String(v[6] || '').trim();
    if (!eventId) {
      eventId = Utilities.getUuid();
      sheet.getRange(rowNumber, 7).setValue(eventId);
    }
    const rowErrors = [];
    const start = validDate_(v[0], '시작일', rowErrors);
    const end = blank_(v[1]) ? null : validDate_(v[1], '종료일', rowErrors);
    const titleKo = requiredText_(v[2], '일정명(국문)', rowErrors);
    const titleEn = requiredText_(v[3], '일정명(영문)', rowErrors);
    const category = allowlisted_(v[4], ACADEMIC_CATEGORIES, '분류', rowErrors);
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(eventId)) rowErrors.push('event_id 형식이 잘못되었습니다.');
    if (start && end && end.getTime() < start.getTime()) rowErrors.push('종료일은 시작일보다 빠를 수 없습니다.');
    if (ids.has(eventId)) rowErrors.push(`event_id가 ${ids.get(eventId)}행과 중복됩니다.`);
    else ids.set(eventId, rowNumber);

    const record = {
      rowNumber,
      id: eventId,
      data: {
        title_ko: titleKo,
        title_en: titleEn,
        category,
        start: start ? formatDateSeoul_(start) : null,
        end: end ? formatDateSeoul_(end) : null,
        updatedAt: new Date(),
      },
      errors: rowErrors,
    };
    rows.push(record);
    if (rowErrors.length) errors.push({ rowNumber, errors: rowErrors });
  });
  return { sheet, rows, errors };
}

// ---------------------------------------------------------------------------
// 식당 (cafeterias)
// ---------------------------------------------------------------------------

function readCafeteriaRows_() {
  const sheet = requireSheet_(CONFIG.sheets.cafeterias);
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return { sheet, rows: [], errors: [] };
  const values = sheet.getRange(2, 1, lastRow - 1, CAFETERIA_HEADERS.length).getValues();
  const parsed = parseCafeteriaRows_(values);
  return { sheet, rows: parsed.rows, errors: parsed.errors };
}

// Pure: `values` are sheet rows starting at sheet row 2 (CAFETERIA_HEADERS order).
function parseCafeteriaRows_(values) {
  const rows = [];
  const errors = [];
  const ids = new Map();
  const names = new Map();
  const C = CAFETERIA_COL;

  values.forEach((v, index) => {
    const rowNumber = index + 2;
    if (isBlankRow_(v)) return;
    const rowErrors = [];
    const id = String(v[C.id] || '').trim();
    if (!id) rowErrors.push('식당ID는 필수입니다.');
    else if (!CAFETERIA_ID_PATTERN.test(id)) rowErrors.push('식당ID는 영문 소문자·숫자·하이픈(-)만 쓸 수 있습니다.');
    else if (ids.has(id)) rowErrors.push(`식당ID가 ${ids.get(id)}행과 중복됩니다.`);
    else ids.set(id, rowNumber);

    const nameKo = requiredText_(v[C.nameKo], '이름(국문)', rowErrors);
    const nameEn = requiredText_(v[C.nameEn], '이름(영문)', rowErrors);
    if (nameKo) {
      if (names.has(nameKo)) rowErrors.push(`이름(국문)이 ${names.get(nameKo)}행과 중복됩니다. 학식 탭은 이 이름으로 식당을 고르므로 이름은 고유해야 합니다.`);
      else names.set(nameKo, rowNumber);
    }
    const campus = allowlisted_(v[C.campus], CAMPUSES, '캠퍼스', rowErrors);
    const hours = parseHours_(v[C.hours], rowErrors);
    const hoursKo = optionalText_(v[C.hoursKo]);
    const hoursEn = optionalText_(v[C.hoursEn]);
    const facilityId = optionalText_(v[C.facilityId]);
    if (facilityId !== null && !FACILITY_ID_PATTERN.test(facilityId)) rowErrors.push('지도 건물ID는 영문 소문자·숫자·하이픈(-)만 쓸 수 있습니다.');
    const order = parseIntegerCell_(v[C.order]);
    if (order === null || order < CONFIG.orderMin || order > CONFIG.orderMax) {
      rowErrors.push(`표시 순서는 ${CONFIG.orderMin}~${CONFIG.orderMax} 사이의 정수여야 합니다.`);
    }

    rows.push({
      rowNumber,
      id,
      nameKo,
      data: {
        name_ko: nameKo,
        name_en: nameEn,
        campus,
        hours,
        hours_ko: hoursKo,
        hours_en: hoursEn,
        facilityId,
        order,
        updatedAt: new Date(),
      },
      errors: rowErrors,
    });
    if (rowErrors.length) errors.push({ rowNumber, errors: rowErrors });
  });
  return { rows, errors };
}

// "09:00-09:30, 10:00-14:30" → [{open, close}, ...]. Blank → []. Windows must be
// HH:mm-HH:mm with open < close and must not overlap each other.
function parseHours_(value, errors) {
  const text = String(value === null || typeof value === 'undefined' ? '' : value).trim();
  if (!text) return [];
  const windows = [];
  const parts = text.split(',').map(s => s.trim());
  parts.forEach(part => {
    if (!part) {
      errors.push('운영시간에 빈 구간이 있습니다. 쉼표를 확인하세요.');
      return;
    }
    const match = /^(\d{1,2}:\d{2})\s*[-~–]\s*(\d{1,2}:\d{2})$/.exec(part);
    if (!match) {
      errors.push(`운영시간 '${part}'은 HH:mm-HH:mm 형식이어야 합니다.`);
      return;
    }
    const open = normalizeTime_(match[1]);
    const close = normalizeTime_(match[2]);
    if (open === null || close === null) {
      errors.push(`운영시간 '${part}'의 시각이 올바르지 않습니다 (00:00~23:59).`);
      return;
    }
    if (minutesOf_(open) >= minutesOf_(close)) {
      errors.push(`운영시간 '${part}'은 시작이 종료보다 빨라야 합니다.`);
      return;
    }
    windows.push({ open, close });
  });
  const sorted = windows.slice().sort((a, b) => minutesOf_(a.open) - minutesOf_(b.open));
  for (let i = 1; i < sorted.length; i += 1) {
    if (minutesOf_(sorted[i].open) < minutesOf_(sorted[i - 1].close)) {
      errors.push(`운영시간 구간 ${sorted[i - 1].open}-${sorted[i - 1].close}과 ${sorted[i].open}-${sorted[i].close}이 겹칩니다.`);
      break;
    }
  }
  return sorted;
}

function normalizeTime_(text) {
  const match = /^(\d{1,2}):(\d{2})$/.exec(text);
  if (!match) return null;
  const h = Number(match[1]);
  const m = Number(match[2]);
  if (h > 23 || m > 59) return null;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function minutesOf_(hhmm) {
  return Number(hhmm.substring(0, 2)) * 60 + Number(hhmm.substring(3, 5));
}

// Korean name → { id, rowNumber } for cafeteria rows that passed validation.
// Names shared by several rows are marked ambiguous so dining rows cannot pick
// one silently.
function cafeteriaIndex_(parsedCafeterias) {
  const index = new Map();
  const seen = new Map();
  parsedCafeterias.rows.forEach(row => {
    if (!row.nameKo) return;
    seen.set(row.nameKo, (seen.get(row.nameKo) || 0) + 1);
  });
  parsedCafeterias.rows.forEach(row => {
    if (!row.nameKo) return;
    // A name that appears twice is ambiguous even when the duplicate row is itself
    // invalid; the admin must fix the "식당" tab before dining rows can use it.
    if (seen.get(row.nameKo) > 1) {
      index.set(row.nameKo, { ambiguous: true });
      return;
    }
    if (row.errors.length || !row.id) return;
    index.set(row.nameKo, { id: row.id, rowNumber: row.rowNumber });
  });
  return index;
}

// ---------------------------------------------------------------------------
// 학식 (dining_menus)
// ---------------------------------------------------------------------------

function readDiningGroups_() {
  const sheet = requireSheet_(CONFIG.sheets.dining);
  const cafeteriaIndex = cafeteriaIndex_(readCafeteriaRows_());
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return { sheet, groups: [], orphanErrors: [] };
  const values = sheet.getRange(2, 1, lastRow - 1, DINING_HEADERS.length).getValues();
  const parsed = parseDiningRows_(values, cafeteriaIndex);
  return { sheet, groups: parsed.groups, orphanErrors: parsed.orphanErrors };
}

// Pure: `values` are sheet rows starting at sheet row 2 (DINING_HEADERS order),
// `cafeteriaIndex` comes from cafeteriaIndex_(). Returns groups keyed by
// (cafeteriaId, date) with per-row errors, plus rows that could not be grouped.
function parseDiningRows_(values, cafeteriaIndex) {
  const grouped = new Map();
  const orphanErrors = [];
  const C = DINING_COL;

  values.forEach((v, index) => {
    const rowNumber = index + 2;
    if (isBlankRow_(v)) return;
    const errors = [];
    const date = validDate_(v[C.date], '날짜', errors);
    const cafeteriaId = lookupCafeteria_(v[C.cafeteria], cafeteriaIndex, errors);
    const status = allowlisted_(v[C.status], DINING_STATUSES, '상태', errors);
    const dateString = date ? formatDateSeoul_(date) : null;
    if (!dateString || !cafeteriaId) {
      orphanErrors.push({ rowNumber, errors });
      return;
    }
    const key = `${cafeteriaId}_${dateString}`;
    // Defense in depth: the final document id must be a validated cafeteria id
    // plus a yyyy-MM-dd date, whatever the lookup step returned.
    if (!CAFETERIA_ID_PATTERN.test(cafeteriaId) || !/^[a-z0-9-]+_\d{4}-\d{2}-\d{2}$/.test(key)) {
      errors.push('식당·날짜로 만든 문서 ID가 허용 형식이 아닙니다.');
      orphanErrors.push({ rowNumber, errors });
      return;
    }
    if (!grouped.has(key)) grouped.set(key, {
      id: key,
      cafeteriaId,
      date: dateString,
      rows: [],
      errors: [],
      statuses: new Set(),
      sectionKeys: new Map(),
    });
    const group = grouped.get(key);
    if (status) group.statuses.add(status);

    let section = null;
    if (status === 'open') {
      section = parseSectionRow_(v, rowNumber, group, errors);
    } else if (status === 'closed' || status === 'unpublished') {
      if (!blank_(v[C.slot]) || !blank_(v[C.kind]) || !blank_(v[C.menu]) || !blank_(v[C.price]) || !blank_(v[C.note])) {
        errors.push('휴무/게시취소 행에는 시간대·유형·메뉴·가격·비고를 입력하지 마세요.');
      }
    }
    group.rows.push({ rowNumber, status, section, errors });
    group.errors.push(...errors.map(message => ({ rowNumber, message })));
  });

  const groups = Array.from(grouped.values());
  groups.forEach(group => {
    if (group.statuses.size !== 1) {
      group.rows.forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '같은 식당·날짜 그룹의 상태는 모두 같아야 합니다.' }));
    }
    group.status = group.statuses.size === 1 ? Array.from(group.statuses)[0] : null;
    group.sections = group.rows.map(r => r.section).filter(Boolean);
    if (group.status === 'open' && group.sections.length === 0) {
      group.rows.forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '게시 상태에는 한 개 이상의 메뉴 섹션이 필요합니다.' }));
    }
    if ((group.status === 'closed' || group.status === 'unpublished') && group.rows.length > 1) {
      group.rows.slice(1).forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '휴무/게시취소는 식당·날짜별 한 행만 입력하세요.' }));
    }
    delete group.statuses;
    delete group.sectionKeys;
  });
  return { groups, orphanErrors };
}

function lookupCafeteria_(value, cafeteriaIndex, errors) {
  const name = String(value || '').trim();
  if (!name) {
    errors.push('식당은 필수입니다.');
    return null;
  }
  const entry = cafeteriaIndex.get(name);
  if (!entry) {
    errors.push(`식당 '${name}'이 '${CONFIG.sheets.cafeterias}' 탭에 없거나 그 행에 오류가 있습니다.`);
    return null;
  }
  if (entry.ambiguous) {
    errors.push(`식당 '${name}'이 '${CONFIG.sheets.cafeterias}' 탭에 여러 번 있어 고를 수 없습니다.`);
    return null;
  }
  return entry.id;
}

// One "게시" row → one menu section. Enforces the price rules per kind and the
// (slot, kind) uniqueness inside the group.
function parseSectionRow_(v, rowNumber, group, errors) {
  const C = DINING_COL;
  const slot = allowlisted_(v[C.slot], MEAL_SLOTS, '시간대', errors);
  const kind = allowlisted_(v[C.kind], MENU_KINDS, '유형', errors);
  const rawMenu = requiredText_(v[C.menu], '메뉴', errors);
  const items = rawMenu ? parseMenuItems_(rawMenu, errors) : [];
  const note = optionalText_(v[C.note]);

  let price = null;
  if (!blank_(v[C.price])) {
    price = parsePriceCell_(v[C.price]);
    if (price === null) {
      errors.push(`가격은 ${CONFIG.priceMin}~${CONFIG.priceMax} 사이의 정수여야 합니다.`);
    }
  }

  if (kind && SECTION_PRICED_KINDS.includes(kind)) {
    if (blank_(v[C.price])) errors.push(`${labelOf_(MENU_KINDS, kind)}은 가격 열이 필수입니다.`);
    if (items.some(item => typeof item.price === 'number')) {
      errors.push(`${labelOf_(MENU_KINDS, kind)}은 가격 열에 한 가격만 쓰고 메뉴 항목 끝에는 가격을 붙이지 마세요.`);
    }
  } else if (kind) {
    if (!blank_(v[C.price])) errors.push(`${labelOf_(MENU_KINDS, kind)}은 가격 열을 비우고 필요하면 항목 끝에 가격을 적으세요 (예: 국밥 6000).`);
  }

  if (slot && kind) {
    const key = `${slot}/${kind}`;
    if (group.sectionKeys.has(key)) {
      errors.push(`${labelOf_(MEAL_SLOTS, slot)} ${labelOf_(MENU_KINDS, kind)}이 ${group.sectionKeys.get(key)}행과 중복됩니다.`);
    } else {
      group.sectionKeys.set(key, rowNumber);
    }
  }

  if (errors.length || !slot || !kind || !items.length) return null;
  const section = { slot, kind, items };
  if (SECTION_PRICED_KINDS.includes(kind)) section.price = price;
  if (note !== null) section.note = note;
  return section;
}

// "국밥 6000\n돈까스 7,500원, 연어포케 9000" → [{name, price?}, ...]. Items are
// separated by newlines or commas; a trailing integer (commas and 원 allowed)
// becomes the item price. A comma followed by exactly three digits is a
// thousands separator ("7,500원"), not an item separator.
function parseMenuItems_(text, errors) {
  const parts = String(text).split(/\r?\n|,(?!\d{3}(?!\d))/).map(s => s.trim());
  const items = [];
  let blankSeen = false;
  parts.forEach(part => {
    if (!part) {
      blankSeen = true;
      return;
    }
    const match = /^(.*?)\s+(\d{1,3}(?:,\d{3})+|\d+)\s*원?$/.exec(part);
    if (!match) {
      if (/^(\d{1,3}(?:,\d{3})+|\d+)\s*원?$/.test(part)) {
        errors.push(`메뉴 항목 '${part}'에 이름이 없습니다.`);
        return;
      }
      items.push({ name: part });
      return;
    }
    const name = match[1].trim();
    const price = Number(match[2].replace(/,/g, ''));
    if (!name) {
      errors.push(`메뉴 항목 '${part}'에 이름이 없습니다.`);
      return;
    }
    if (!Number.isInteger(price) || price < CONFIG.priceMin || price > CONFIG.priceMax) {
      errors.push(`메뉴 항목 '${name}'의 가격은 ${CONFIG.priceMin}~${CONFIG.priceMax} 사이의 정수여야 합니다.`);
      return;
    }
    items.push({ name, price });
  });
  if (blankSeen) errors.push('메뉴에 빈 항목이 있습니다. 쉼표나 빈 줄을 확인하세요.');
  return items;
}

// Price cell: a numeric cell or a digit string ("7500", "7,500", "7,500원").
// Returns an integer in range or null.
function parsePriceCell_(value) {
  let price = null;
  if (typeof value === 'number') {
    price = value;
  } else if (typeof value === 'string') {
    const text = value.trim();
    if (/^(\d{1,3}(?:,\d{3})+|\d+)\s*원?$/.test(text)) price = Number(text.replace(/[,원\s]/g, ''));
  }
  if (price === null || !Number.isInteger(price) || price < CONFIG.priceMin || price > CONFIG.priceMax) return null;
  return price;
}

// Integer cell (numeric or digit string); null when invalid.
function parseIntegerCell_(value) {
  if (typeof value === 'number') return Number.isInteger(value) ? value : null;
  if (typeof value === 'string' && /^-?\d+$/.test(value.trim())) return Number(value.trim());
  return null;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

function validDate_(value, label, errors) {
  if (!(value instanceof Date) || isNaN(value.getTime())) {
    errors.push(`${label}은 날짜 형식으로 입력하세요.`);
    return null;
  }
  return value;
}

function requiredText_(value, label, errors) {
  const text = String(value || '').trim();
  if (!text) errors.push(`${label}은(는) 필수입니다.`);
  return text;
}

function optionalText_(value) {
  if (blank_(value)) return null;
  return String(value).trim();
}

function allowlisted_(value, allowlist, label, errors) {
  const labelValue = String(value || '').trim();
  // Own-property check blocks Object.prototype chain lookups (toString, __proto__, ...).
  if (!Object.prototype.hasOwnProperty.call(allowlist, labelValue)) {
    errors.push(`${label} 값이 허용 목록에 없습니다.`);
    return null;
  }
  const mapped = allowlist[labelValue];
  if (typeof mapped !== 'string' || !mapped) {
    errors.push(`${label} 값이 허용 목록에 없습니다.`);
    return null;
  }
  return mapped;
}

function labelOf_(allowlist, id) {
  return Object.keys(allowlist).find(label => allowlist[label] === id) || id;
}

function formatDateSeoul_(date) {
  return Utilities.formatDate(date, CONFIG.timeZone, 'yyyy-MM-dd');
}

function isBlankRow_(values) {
  return values.every(v => blank_(v));
}

function blank_(value) {
  if (value === null || typeof value === 'undefined') return true;
  if (typeof value === 'string') return value.trim() === '';
  return false;
}

function requireSheet_(name) {
  const sheet = SpreadsheetApp.getActive().getSheetByName(name);
  if (!sheet) throw new Error(`'${name}' 시트가 없습니다. 먼저 '동아메이트 > 시트 초기화'를 실행하세요.`);
  return sheet;
}
