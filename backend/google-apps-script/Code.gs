/**
 * TutorFlow SecureNotes & Mini-LMS - Google Apps Script Backend (REST API)
 * Zero-cost serverless backend connecting Google Sheets as the relational database.
 * 
 * Target Spreadsheet ID: 1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI
 * Target Drive Folder ID: 1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ
 * Developer: Abhishek Maheshwari | Curriculum: BCA (Pravin-hub-rgb)
 * Version: 2.0.0 (Supports Live Lectures, Attendance, Certificates, and Notes DRM)
 */

var SPREADSHEET_ID = '1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI';

function getSpreadsheet() {
  try {
    if (SPREADSHEET_ID && SPREADSHEET_ID !== '') {
      return SpreadsheetApp.openById(SPREADSHEET_ID);
    }
  } catch (e) {
    Logger.log('Could not open by ID, falling back to active spreadsheet: ' + e);
  }
  return SpreadsheetApp.getActiveSpreadsheet();
}

/**
 * Handle HTTP GET Requests
 */
function doGet(e) {
  var params = e ? e.parameter || {} : {};
  var action = params.action || 'ping';
  var responseData = {};

  try {
    switch (action) {
      case 'ping':
        responseData = { 
          status: 'success', 
          message: 'TutorFlow BCA LMS API is live', 
          developer: 'Abhishek Maheshwari',
          institute: 'Prince Electronics & Electricals, Bilsi',
          timestamp: new Date() 
        };
        break;
      case 'get_catalog':
        responseData = getCatalog(params.user_id || '');
        break;
      case 'get_live_classes':
        responseData = getLiveClasses(params.user_id || '');
        break;
      case 'get_certificates':
        responseData = getCertificates(params.user_id || '');
        break;
      default:
        responseData = { status: 'error', message: 'Invalid GET action: ' + action };
    }
  } catch (err) {
    responseData = { status: 'error', message: err.toString() };
  }

  return ContentService.createTextOutput(JSON.stringify(responseData))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Handle HTTP POST Requests
 */
function doPost(e) {
  var responseData = {};

  try {
    var body = {};
    if (e && e.postData && e.postData.contents) {
      body = JSON.parse(e.postData.contents);
    } else if (e && e.parameter) {
      body = e.parameter;
    }

    var action = body.action || '';

    switch (action) {
      case 'register':
        responseData = registerUser(body);
        break;
      case 'login':
        responseData = loginUser(body);
        break;
      case 'get_catalog':
        responseData = getCatalog(body.user_id);
        break;
      case 'record_purchase':
        responseData = recordPurchase(body);
        break;
      case 'mark_attendance':
        responseData = markAttendance(body);
        break;
      case 'get_live_classes':
        responseData = getLiveClasses(body.user_id);
        break;
      case 'get_certificates':
        responseData = getCertificates(body.user_id);
        break;
      case 'generate_certificate':
        responseData = generateCertificate(body);
        break;

      // Admin Actions
      case 'admin_add_note':
        responseData = adminAddNote(body);
        break;
      case 'admin_add_live_class':
        responseData = adminAddLiveClass(body);
        break;
      case 'admin_toggle_unlock':
        responseData = adminToggleUnlock(body);
        break;
      case 'admin_list_purchases':
        responseData = adminListPurchases(body);
        break;
      case 'admin_list_attendance':
        responseData = adminListAttendance(body);
        break;

      default:
        responseData = { status: 'error', message: 'Unknown action: ' + action };
    }
  } catch (err) {
    responseData = { status: 'error', message: err.toString() };
  }

  return ContentService.createTextOutput(JSON.stringify(responseData))
    .setMimeType(ContentService.MimeType.JSON);
}

// ==========================================
// 1. AUTHENTICATION MODULE
// ==========================================

function registerUser(data) {
  var sheet = getOrCreateSheet('Users', ['user_id', 'name', 'email', 'phone', 'password_hash', 'is_admin', 'created_at']);
  var email = (data.email || '').trim().toLowerCase();
  
  if (!email || !data.password) {
    return { status: 'error', message: 'Email and password are required' };
  }

  var rows = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][2].toString().toLowerCase() === email) {
      return { status: 'error', message: 'A user with this email already exists' };
    }
  }

  var userId = 'usr_' + Utilities.getUuid().substring(0, 8);
  var passwordHash = hashPassword(data.password);
  var isAdmin = data.is_admin === true || data.is_admin === 'true' || email === 'admin@tutorflow.com';

  sheet.appendRow([
    userId,
    data.name || 'BCA Student',
    email,
    data.phone || '',
    passwordHash,
    isAdmin,
    new Date()
  ]);

  return {
    status: 'success',
    data: {
      user_id: userId,
      name: data.name,
      email: email,
      is_admin: isAdmin,
      session_token: 'tok_' + Utilities.getUuid()
    }
  };
}

function loginUser(data) {
  var sheet = getOrCreateSheet('Users', ['user_id', 'name', 'email', 'phone', 'password_hash', 'is_admin', 'created_at']);
  var email = (data.email || '').trim().toLowerCase();
  var password = data.password || '';

  if (!email || !password) {
    return { status: 'error', message: 'Email and password required' };
  }

  var passwordHash = hashPassword(password);
  var rows = sheet.getDataRange().getValues();

  for (var i = 1; i < rows.length; i++) {
    var rowEmail = rows[i][2].toString().toLowerCase();
    var rowHash = rows[i][4].toString();

    if (rowEmail === email && rowHash === passwordHash) {
      return {
        status: 'success',
        data: {
          user_id: rows[i][0],
          name: rows[i][1],
          email: rows[i][2],
          phone: rows[i][3],
          is_admin: rows[i][5] === true || rows[i][5] === 'TRUE',
          session_token: 'tok_' + Utilities.getUuid()
        }
      };
    }
  }

  return { status: 'error', message: 'Invalid credentials. Please verify your email and password.' };
}

// ==========================================
// 2. NOTES & CATALOG MODULE
// ==========================================

function getCatalog(userId) {
  var notesSheet = getOrCreateSheet('Notes', ['note_id', 'title', 'subject', 'semester', 'description', 'price', 'drive_file_id', 'youtube_video_id', 'is_active', 'created_at']);
  var purchasesSheet = getOrCreateSheet('Purchases', ['purchase_id', 'user_id', 'note_id', 'status', 'txn_reference', 'unlocked_at']);

  var userPurchased = {};
  if (userId) {
    var pRows = purchasesSheet.getDataRange().getValues();
    for (var j = 1; j < pRows.length; j++) {
      if (pRows[j][1] === userId && pRows[j][3] === 'ACTIVE') {
        userPurchased[pRows[j][2]] = true;
      }
    }
  }

  var noteRows = notesSheet.getDataRange().getValues();
  var catalog = [];

  for (var i = 1; i < noteRows.length; i++) {
    var isActive = noteRows[i][8];
    if (isActive === false || isActive === 'FALSE') continue;

    var noteId = noteRows[i][0];
    var price = Number(noteRows[i][5]) || 0;
    var isUnlocked = price === 0 || (userPurchased[noteId] === true);

    catalog.push({
      note_id: noteId,
      title: noteRows[i][1],
      subject: noteRows[i][2],
      semester: noteRows[i][3] || 'General',
      description: noteRows[i][4],
      price: price,
      // Zero-leakage: hide raw Google Drive ID until user has unlocked
      drive_file_id: isUnlocked ? noteRows[i][6] : '',
      youtube_video_id: noteRows[i][7],
      is_unlocked: isUnlocked
    });
  }

  return { status: 'success', data: catalog };
}

function recordPurchase(data) {
  var sheet = getOrCreateSheet('Purchases', ['purchase_id', 'user_id', 'note_id', 'status', 'txn_reference', 'unlocked_at']);
  if (!data.user_id || !data.note_id) {
    return { status: 'error', message: 'User ID and Note ID are required' };
  }

  var purchaseId = 'pur_' + Utilities.getUuid().substring(0, 8);
  var status = data.auto_unlock ? 'ACTIVE' : 'PENDING';

  sheet.appendRow([
    purchaseId,
    data.user_id,
    data.note_id,
    status,
    data.txn_reference || 'MANUAL_UPI',
    status === 'ACTIVE' ? new Date() : ''
  ]);

  return {
    status: 'success',
    data: { purchase_id: purchaseId, status: status }
  };
}

// ==========================================
// 3. LIVE LECTURES & CONFERENCING MODULE
// ==========================================

function getLiveClasses(userId) {
  var sheet = getOrCreateSheet('LiveClasses', ['class_id', 'title', 'instructor', 'subject', 'meeting_type', 'meeting_room_or_url', 'schedule_time', 'is_active', 'created_at']);
  var rows = sheet.getDataRange().getValues();
  var list = [];

  for (var i = 1; i < rows.length; i++) {
    var isActive = rows[i][7];
    if (isActive === false || isActive === 'FALSE') continue;

    list.push({
      class_id: rows[i][0],
      title: rows[i][1],
      instructor: rows[i][2],
      subject: rows[i][3],
      meeting_type: rows[i][4], // 'JITSI' | 'MEET' | 'ZOOM'
      meeting_room_or_url: rows[i][5],
      schedule_time: rows[i][6],
      is_active: true
    });
  }

  return { status: 'success', data: list };
}

function adminAddLiveClass(data) {
  var sheet = getOrCreateSheet('LiveClasses', ['class_id', 'title', 'instructor', 'subject', 'meeting_type', 'meeting_room_or_url', 'schedule_time', 'is_active', 'created_at']);
  var classId = 'live_' + Utilities.getUuid().substring(0, 8);

  sheet.appendRow([
    classId,
    data.title || 'Live BCA Lecture',
    data.instructor || 'Abhishek Maheshwari',
    data.subject || 'Computer Applications',
    data.meeting_type || 'JITSI', // Default to free embedded Jitsi
    data.meeting_room_or_url || ('TutorFlow_BCA_' + Math.floor(Math.random() * 90000 + 10000)),
    data.schedule_time || new Date().toISOString(),
    true,
    new Date()
  ]);

  return { status: 'success', data: { class_id: classId } };
}

// ==========================================
// 4. AUTOMATED ATTENDANCE TRACKING MODULE
// ==========================================

function markAttendance(data) {
  var sheet = getOrCreateSheet('Attendance', ['attendance_id', 'user_id', 'user_name', 'session_id', 'session_title', 'session_type', 'timestamp']);
  
  if (!data.user_id) {
    return { status: 'error', message: 'User ID is required to log attendance' };
  }

  var attId = 'att_' + Utilities.getUuid().substring(0, 8);
  sheet.appendRow([
    attId,
    data.user_id,
    data.user_name || 'BCA Student',
    data.session_id || 'GENERAL',
    data.session_title || 'Class Session',
    data.session_type || 'LIVE_CLASS', // 'LIVE_CLASS' | 'NOTE_READ'
    new Date()
  ]);

  return { status: 'success', message: 'Attendance recorded successfully', attendance_id: attId };
}

function adminListAttendance(data) {
  var sheet = getOrCreateSheet('Attendance', ['attendance_id', 'user_id', 'user_name', 'session_id', 'session_title', 'session_type', 'timestamp']);
  var rows = sheet.getDataRange().getValues();
  var records = [];

  for (var i = 1; i < rows.length; i++) {
    records.push({
      attendance_id: rows[i][0],
      user_id: rows[i][1],
      user_name: rows[i][2],
      session_id: rows[i][3],
      session_title: rows[i][4],
      session_type: rows[i][5],
      timestamp: rows[i][6]
    });
  }

  return { status: 'success', data: records };
}

// ==========================================
// 5. DIGITAL CERTIFICATES MODULE
// ==========================================

function getCertificates(userId) {
  var sheet = getOrCreateSheet('Certificates', ['certificate_id', 'user_id', 'user_name', 'course_title', 'issue_date', 'verification_hash', 'instructor']);
  var rows = sheet.getDataRange().getValues();
  var list = [];

  for (var i = 1; i < rows.length; i++) {
    if (!userId || rows[i][1] === userId) {
      list.push({
        certificate_id: rows[i][0],
        user_id: rows[i][1],
        user_name: rows[i][2],
        course_title: rows[i][3],
        issue_date: rows[i][4],
        verification_hash: rows[i][5],
        instructor: rows[i][6] || 'Abhishek Maheshwari'
      });
    }
  }

  return { status: 'success', data: list };
}

function generateCertificate(data) {
  var sheet = getOrCreateSheet('Certificates', ['certificate_id', 'user_id', 'user_name', 'course_title', 'issue_date', 'verification_hash', 'instructor']);
  
  if (!data.user_id || !data.course_title) {
    return { status: 'error', message: 'User ID and Course Title are required' };
  }

  var certId = 'TF-BCA-' + Math.floor(100000 + Math.random() * 900000);
  var issueDate = new Date().toISOString().substring(0, 10);
  var verificationHash = hashPassword(certId + data.user_id + issueDate).substring(0, 16);

  sheet.appendRow([
    certId,
    data.user_id,
    data.user_name || 'BCA Student',
    data.course_title,
    issueDate,
    verificationHash,
    'Abhishek Maheshwari'
  ]);

  return {
    status: 'success',
    data: {
      certificate_id: certId,
      issue_date: issueDate,
      verification_hash: verificationHash,
      instructor: 'Abhishek Maheshwari'
    }
  };
}

// ==========================================
// 6. ADMIN UTILITIES & SEEDING (BCA CURRICULUM)
// ==========================================

function adminAddNote(data) {
  var sheet = getOrCreateSheet('Notes', ['note_id', 'title', 'subject', 'semester', 'description', 'price', 'drive_file_id', 'youtube_video_id', 'is_active', 'created_at']);
  var noteId = 'note_' + Utilities.getUuid().substring(0, 8);

  sheet.appendRow([
    noteId,
    data.title || 'Untitled Note',
    data.subject || 'BCA Core',
    data.semester || 'Semester 1',
    data.description || '',
    Number(data.price) || 0,
    data.drive_file_id || '',
    data.youtube_video_id || '',
    true,
    new Date()
  ]);

  return { status: 'success', data: { note_id: noteId } };
}

function adminToggleUnlock(data) {
  var sheet = getOrCreateSheet('Purchases', ['purchase_id', 'user_id', 'note_id', 'status', 'txn_reference', 'unlocked_at']);
  var purchaseId = data.purchase_id;
  var targetStatus = data.status || 'ACTIVE';

  var rows = sheet.getDataRange().getValues();
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0] === purchaseId) {
      sheet.getRange(i + 1, 4).setValue(targetStatus);
      if (targetStatus === 'ACTIVE') {
        sheet.getRange(i + 1, 6).setValue(new Date());
      }
      return { status: 'success', message: 'Status updated to ' + targetStatus };
    }
  }

  return { status: 'error', message: 'Purchase record not found' };
}

function adminListPurchases(data) {
  var sheet = getOrCreateSheet('Purchases', ['purchase_id', 'user_id', 'note_id', 'status', 'txn_reference', 'unlocked_at']);
  var rows = sheet.getDataRange().getValues();
  var list = [];

  for (var i = 1; i < rows.length; i++) {
    list.push({
      purchase_id: rows[i][0],
      user_id: rows[i][1],
      note_id: rows[i][2],
      status: rows[i][3],
      txn_reference: rows[i][4],
      unlocked_at: rows[i][5]
    });
  }

  return { status: 'success', data: list };
}

// ==========================================
// 7. INITIALIZATION & DATABASE BOOTSTRAP
// ==========================================

function getOrCreateSheet(sheetName, headers) {
  var ss = getSpreadsheet();
  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    if (headers && headers.length > 0) {
      sheet.appendRow(headers);
      sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold').setBackground('#E8F0FE');
    }
  }
  return sheet;
}

function hashPassword(password) {
  var rawHash = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, password, Utilities.Charset.UTF_8);
  var txtHash = '';
  for (var i = 0; i < rawHash.length; i++) {
    var hashVal = rawHash[i];
    if (hashVal < 0) hashVal += 256;
    var byteString = hashVal.toString(16);
    if (byteString.length == 1) byteString = '0' + byteString;
    txtHash += byteString;
  }
  return txtHash;
}

/**
 * Run this function ONCE in Apps Script to bootstrap all tables and pre-populate BCA syllabus!
 */
function setupDatabase() {
  getOrCreateSheet('Users', ['user_id', 'name', 'email', 'phone', 'password_hash', 'is_admin', 'created_at']);
  
  var notesSheet = getOrCreateSheet('Notes', ['note_id', 'title', 'subject', 'semester', 'description', 'price', 'drive_file_id', 'youtube_video_id', 'is_active', 'created_at']);
  
  getOrCreateSheet('Purchases', ['purchase_id', 'user_id', 'note_id', 'status', 'txn_reference', 'unlocked_at']);
  getOrCreateSheet('LiveClasses', ['class_id', 'title', 'instructor', 'subject', 'meeting_type', 'meeting_room_or_url', 'schedule_time', 'is_active', 'created_at']);
  getOrCreateSheet('Attendance', ['attendance_id', 'user_id', 'user_name', 'session_id', 'session_title', 'session_type', 'timestamp']);
  getOrCreateSheet('Certificates', ['certificate_id', 'user_id', 'user_name', 'course_title', 'issue_date', 'verification_hash', 'instructor']);

  // Pre-seed sample BCA Curriculum entries (from Pravin-hub-rgb/BCA) if Notes is empty
  if (notesSheet.getLastRow() <= 1) {
    var bcaModules = [
      ['note_c_prog', 'C Programming & Algorithms Handout', 'Programming in C', 'Semester 1', 'Pointers, memory management, and file operations', 0, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()],
      ['note_ds_algo', 'Data Structures & Algorithms Complete Notes', 'Data Structures', 'Semester 2', 'Arrays, Linked Lists, Stacks, Queues, Trees and Sorting', 49, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()],
      ['note_dbms', 'Database Management Systems (DBMS) Notes & SQL', 'DBMS', 'Semester 3', 'Relational algebra, SQL queries, Normalization (1NF to BCNF)', 49, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()],
      ['note_java', 'Java Programming & OOP Core Concepts', 'Java Programming', 'Semester 4', 'OOP principles, Exception handling, Collections & Multithreading', 99, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()],
      ['note_os', 'Operating Systems Principles & Lab Manual', 'Operating Systems', 'Semester 4', 'Process synchronization, CPU scheduling, Memory management', 0, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()],
      ['note_python', 'Python for Modern Applications & Data Science', 'Python', 'Semester 5', 'NumPy, Pandas, Web frameworks, and Scripting exercises', 99, '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ', '', true, new Date()]
    ];

    for (var i = 0; i < bcaModules.length; i++) {
      notesSheet.appendRow(bcaModules[i]);
    }
  }

  // Pre-seed a default Admin user (admin@tutorflow.com / admin123)
  var usersSheet = getSpreadsheet().getSheetByName('Users');
  if (usersSheet.getLastRow() <= 1) {
    usersSheet.appendRow([
      'usr_admin01',
      'Abhishek Maheshwari (Admin)',
      'admin@tutorflow.com',
      '9876543210',
      hashPassword('admin123'),
      true,
      new Date()
    ]);
  }

  Logger.log('TutorFlow Database Tables & BCA Curriculum initialized successfully!');
}
