function firestoreBase_() {
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(CONFIG.projectId)}/databases/${encodeURIComponent(CONFIG.databaseId)}/documents`;
}

function documentName_(collection, id) {
  return `projects/${CONFIG.projectId}/databases/${CONFIG.databaseId}/documents/${collection}/${id}`;
}

function listDocumentIds_(collection) {
  const ids = [];
  let pageToken = '';
  do {
    const query = ['pageSize=300', 'showMissing=false'];
    if (pageToken) query.push(`pageToken=${encodeURIComponent(pageToken)}`);
    const result = firestoreRequest_('get', `${firestoreBase_()}/${collection}?${query.join('&')}`);
    (result.documents || []).forEach(doc => ids.push(doc.name.substring(doc.name.lastIndexOf('/') + 1)));
    pageToken = result.nextPageToken || '';
  } while (pageToken);
  return ids;
}

function commitWrites_(writes) {
  if (writes.length > CONFIG.maxCommitWrites) {
    throw new Error(`단일 커밋 쓰기 수 ${writes.length}건이 한도 ${CONFIG.maxCommitWrites}건을 넘었습니다.`);
  }
  if (!writes.length) return { writeResults: [] };
  return firestoreRequest_('post', `${firestoreBase_()}:commit`, { writes });
}

function updateWrite_(collection, id, data) {
  return {
    update: {
      name: documentName_(collection, id),
      fields: encodeMap_(data),
    },
  };
}

function deleteWrite_(collection, id) {
  return { delete: documentName_(collection, id) };
}

function upsertDocument_(collection, id, data) {
  const url = `${firestoreBase_()}/${collection}/${encodeURIComponent(id)}`;
  return firestoreRequest_('patch', url, { fields: encodeMap_(data) });
}

function firestoreRequest_(method, url, body) {
  const options = {
    method,
    muteHttpExceptions: true,
    headers: { Authorization: `Bearer ${ScriptApp.getOAuthToken()}` },
  };
  if (typeof body !== 'undefined') {
    options.contentType = 'application/json';
    options.payload = JSON.stringify(body);
  }
  const response = UrlFetchApp.fetch(url, options);
  const text = response.getContentText();
  const code = response.getResponseCode();
  let parsed = {};
  if (text) {
    try { parsed = JSON.parse(text); } catch (e) { parsed = { raw: text }; }
  }
  if (code < 200 || code >= 300) {
    const detail = parsed.error && parsed.error.message ? parsed.error.message : text;
    throw new Error(`Firestore REST 오류(${code}): ${detail}`);
  }
  return parsed;
}

function encodeMap_(object) {
  const fields = {};
  Object.keys(object).forEach(key => { fields[key] = encodeValue_(object[key]); });
  return fields;
}

function encodeValue_(value) {
  if (value === null || typeof value === 'undefined') return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encodeValue_) } };
  if (typeof value === 'object') return { mapValue: { fields: encodeMap_(value) } };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  return { stringValue: String(value) };
}
