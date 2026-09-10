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

function readDiningGroups_() {
  const sheet = requireSheet_(CONFIG.sheets.dining);
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return { sheet, groups: [], orphanErrors: [] };
  const values = sheet.getRange(2, 1, lastRow - 1, DINING_HEADERS.length).getValues();
  const grouped = new Map();
  const orphanErrors = [];

  values.forEach((v, index) => {
    const rowNumber = index + 2;
    if (isBlankRow_(v)) return;
    const errors = [];
    const date = validDate_(v[0], '날짜', errors);
    const cafeteriaId = allowlisted_(v[1], CAFETERIAS, '식당', errors);
    const status = allowlisted_(v[5], DINING_STATUSES, '상태', errors);
    const dateString = date ? formatDateSeoul_(date) : null;
    if (!dateString || !cafeteriaId) {
      orphanErrors.push({ rowNumber, errors });
      return;
    }
    const key = `${cafeteriaId}_${dateString}`;
    // Defense in depth: even if the mapping step is bypassed, the final document id
    // must be a known cafeteria id plus a yyyy-MM-dd date.
    if (!Object.values(CAFETERIAS).includes(cafeteriaId) || !/^[a-z0-9-]+_\d{4}-\d{2}-\d{2}$/.test(key)) {
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
      mealTypes: new Map(),
    });
    const group = grouped.get(key);
    if (status) group.statuses.add(status);

    let meal = null;
    if (status === 'open') {
      const type = allowlisted_(v[2], MEAL_TYPES, '식사', errors);
      const rawMenu = requiredText_(v[3], '메뉴', errors);
      const items = rawMenu ? rawMenu.split(',').map(s => s.trim()) : [];
      if (items.some(s => !s)) errors.push('메뉴에 빈 항목이 있습니다. 쉼표를 확인하세요.');
      let price = null;
      if (!blank_(v[4])) {
        // Only a numeric cell or a plain digit string is accepted; Number('   ') === 0
        // style coercions and booleans are rejected.
        if (typeof v[4] === 'number') {
          price = v[4];
        } else if (typeof v[4] === 'string' && /^\d+$/.test(v[4].trim())) {
          price = Number(v[4].trim());
        }
        if (price === null || !Number.isInteger(price) || price < CONFIG.priceMin || price > CONFIG.priceMax) {
          errors.push(`가격은 ${CONFIG.priceMin}~${CONFIG.priceMax} 사이의 정수여야 합니다.`);
          price = null;
        }
      }
      if (type && group.mealTypes.has(type)) {
        errors.push(`${MEAL_TYPES_LABEL_(type)}이 ${group.mealTypes.get(type)}행과 중복됩니다.`);
      } else if (type) {
        group.mealTypes.set(type, rowNumber);
      }
      if (type && items.length && !items.some(s => !s)) meal = { type, items, price };
    } else if (status === 'closed' || status === 'unpublished') {
      if (!blank_(v[2]) || !blank_(v[3]) || !blank_(v[4])) {
        errors.push('휴무/게시취소 행에는 식사·메뉴·가격을 입력하지 마세요.');
      }
    }
    const parsed = { rowNumber, status, meal, errors };
    group.rows.push(parsed);
    group.errors.push(...errors.map(message => ({ rowNumber, message })));
  });

  const groups = Array.from(grouped.values());
  groups.forEach(group => {
    if (group.statuses.size !== 1) {
      group.rows.forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '같은 식당·날짜 그룹의 상태는 모두 같아야 합니다.' }));
    }
    group.status = group.statuses.size === 1 ? Array.from(group.statuses)[0] : null;
    group.meals = group.rows.map(r => r.meal).filter(Boolean);
    if (group.status === 'open' && group.meals.length === 0) {
      group.rows.forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '게시 상태에는 한 끼 이상의 메뉴가 필요합니다.' }));
    }
    if ((group.status === 'closed' || group.status === 'unpublished') && group.rows.length > 1) {
      group.rows.slice(1).forEach(r => group.errors.push({ rowNumber: r.rowNumber, message: '휴무/게시취소는 식당·날짜별 한 행만 입력하세요.' }));
    }
  });
  return { sheet, groups, orphanErrors };
}

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
  if (!sheet) throw new Error(`'${name}' 시트가 없습니다. 먼저 템플릿을 만드세요.`);
  return sheet;
}

function MEAL_TYPES_LABEL_(id) {
  return Object.keys(MEAL_TYPES).find(label => MEAL_TYPES[label] === id) || id;
}
