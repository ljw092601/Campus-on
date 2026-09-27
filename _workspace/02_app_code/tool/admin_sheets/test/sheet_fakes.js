/* A small stand-in for the Sheets API, enough to run the academic-calendar
 * paths of Config.gs / Validation.gs / Setup.gs.
 *
 * Apps Script has no test runner and this project has no Node, so these tests
 * run in Chrome (tool/admin_sheets/test/run_in_chrome.py). The fakes record
 * every write, which is the point: the two BLOCKERs this suite guards were
 * both about writing to the wrong cell.
 */

function FakeSheet(name, grid) {
  this.name = name;
  // grid[row][col], 0-based, row 0 is the header
  this.grid = grid.map(function (r) { return r.slice(); });
  this.maxRows = Math.max(this.grid.length, 1000);
  this.writes = [];          // {row, col, value} in 1-based sheet coordinates
  this.insertedColumns = []; // {after, count}
  this.hidden = [];
  this.widths = {};
  this.validations = [];
}

FakeSheet.prototype._cell = function (r, c) {
  while (this.grid.length <= r) this.grid.push([]);
  var row = this.grid[r];
  while (row.length <= c) row.push('');
  return row[c];
};

FakeSheet.prototype._set = function (r, c, v) {
  while (this.grid.length <= r) this.grid.push([]);
  var row = this.grid[r];
  while (row.length <= c) row.push('');
  row[c] = v;
};

FakeSheet.prototype.getLastRow = function () {
  var last = 0;
  for (var r = 0; r < this.grid.length; r++) {
    for (var c = 0; c < this.grid[r].length; c++) {
      var v = this.grid[r][c];
      if (v !== '' && v !== null && typeof v !== 'undefined') { last = r + 1; break; }
    }
  }
  return last;
};

FakeSheet.prototype.getLastColumn = function () {
  var last = 0;
  for (var r = 0; r < this.grid.length; r++) {
    for (var c = 0; c < this.grid[r].length; c++) {
      var v = this.grid[r][c];
      if (v !== '' && v !== null && typeof v !== 'undefined') last = Math.max(last, c + 1);
    }
  }
  return last;
};

FakeSheet.prototype.getMaxRows = function () { return this.maxRows; };
FakeSheet.prototype.getProtections = function () { return []; };
FakeSheet.prototype.setFrozenRows = function () { return this; };
FakeSheet.prototype.hideColumns = function (c) { this.hidden.push(c); return this; };
FakeSheet.prototype.setColumnWidth = function (c, w) { this.widths[c] = w; return this; };

FakeSheet.prototype.insertColumnsAfter = function (after, count) {
  this.insertedColumns.push({ after: after, count: count });
  for (var r = 0; r < this.grid.length; r++) {
    var row = this.grid[r];
    while (row.length < after) row.push('');
    var blanks = [];
    for (var i = 0; i < count; i++) blanks.push('');
    this.grid[r] = row.slice(0, after).concat(blanks, row.slice(after));
  }
  return this;
};

FakeSheet.prototype.getRange = function (row, col, numRows, numCols) {
  var sheet = this;
  numRows = numRows || 1;
  numCols = numCols || 1;
  return {
    getValues: function () {
      var out = [];
      for (var r = 0; r < numRows; r++) {
        var line = [];
        for (var c = 0; c < numCols; c++) line.push(sheet._cell(row - 1 + r, col - 1 + c));
        out.push(line);
      }
      return out;
    },
    setValue: function (v) {
      sheet.writes.push({ row: row, col: col, value: v });
      sheet._set(row - 1, col - 1, v);
      return this;
    },
    setValues: function (vals) {
      for (var r = 0; r < vals.length; r++) {
        for (var c = 0; c < vals[r].length; c++) {
          sheet.writes.push({ row: row + r, col: col + c, value: vals[r][c] });
          sheet._set(row - 1 + r, col - 1 + c, vals[r][c]);
        }
      }
      return this;
    },
    setDataValidation: function (rule) {
      sheet.validations.push({ row: row, col: col, numRows: numRows, numCols: numCols, rule: rule });
      return this;
    },
    setNumberFormat: function () { return this; },
    setFontWeight: function () { return this; },
    setBackground: function () { return this; },
    clearContent: function () {
      for (var r = 0; r < numRows; r++) {
        for (var c = 0; c < numCols; c++) sheet._set(row - 1 + r, col - 1 + c, '');
      }
      return this;
    },
    protect: function () {
      var protection = {
        setDescription: function () { return protection; },
        getDescription: function () { return ''; },
        setWarningOnly: function () { return protection; },
        addEditor: function () { return protection; },
        removeEditor: function () { return protection; },
        getEditors: function () { return []; },
        canDomainEdit: function () { return false; },
        setDomainEdit: function () { return protection; },
        remove: function () {},
      };
      return protection;
    },
  };
};

function FakeSpreadsheet(sheets) {
  this.sheets = sheets || {};
  this.timeZone = null;
}
FakeSpreadsheet.prototype.getSheetByName = function (n) { return this.sheets[n] || null; };
FakeSpreadsheet.prototype.insertSheet = function (n) {
  this.sheets[n] = new FakeSheet(n, [[]]);
  return this.sheets[n];
};
FakeSpreadsheet.prototype.setSpreadsheetTimeZone = function (tz) { this.timeZone = tz; };

/* Globals the .gs files expect. Only what the academic paths touch. */
function installGlobals(scope, spreadsheet) {
  scope.SpreadsheetApp = {
    getActive: function () { return spreadsheet; },
    newDataValidation: function () {
      var rule = { criteria: null };
      var api = {
        requireDate: function () { rule.criteria = 'date'; return api; },
        requireValueInList: function (list) { rule.criteria = 'list'; rule.list = list; return api; },
        setAllowInvalid: function () { return api; },
        build: function () { return rule; },
      };
      return api;
    },
    getUi: function () {
      return {
        alert: function () { return 'OK'; },
        ButtonSet: { OK: 'OK', YES_NO: 'YES_NO' },
        Button: { YES: 'YES', NO: 'NO' },
      };
    },
    ProtectionType: { RANGE: 'RANGE', SHEET: 'SHEET' },
  };
  var uuid = 0;
  scope.Utilities = {
    getUuid: function () {
      uuid += 1;
      var n = ('0000000' + uuid).slice(-8);
      return n + '-1111-2222-3333-444444444444';
    },
    formatDate: function (d) { return d.toISOString().slice(0, 10); },
  };
  scope.Session = {
    getScriptTimeZone: function () { return 'Asia/Seoul'; },
    getEffectiveUser: function () {
      return { getEmail: function () { return 'admin@example.test'; } };
    },
  };
  scope.Logger = { log: function () {} };
}
