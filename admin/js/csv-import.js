// admin/js/csv-import.js

let csvParsedCourses = [];
let csvImportIsRunning = false;

// ==========================================
// 1. DELIMITER DETECTION & PARSING
// ==========================================
function detectDelimiter(text) {
  const firstLine = text.split(/\r?\n/)[0] || "";
  const delimiters = [',', ';', '\t', '|'];
  let bestDelimiter = ',';
  let maxCount = -1;

  for (const delim of delimiters) {
    const count = firstLine.split(delim).length - 1;
    if (count > maxCount) {
      maxCount = count;
      bestDelimiter = delim;
    }
  }
  return bestDelimiter;
}

function parseCSVText(text) {
  const delimiter = detectDelimiter(text);
  const lines = text.split(/\r?\n/);
  if (lines.length === 0) return [];

  // Clean headers
  const rawHeaders = lines[0].split(delimiter);
  const headers = rawHeaders.map(h => 
    h.trim()
     .replace(/^["']|["']$/g, '')
     .toLowerCase()
     .replace(/\s+/g, '_') // Normalize "course code" to "course_code" etc
  );

  const parsedRows = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    // Parse respecting quotes
    const fields = [];
    let current = "";
    let inQuotes = false;
    
    for (let c = 0; c < line.length; c++) {
      const char = line[c];
      if (char === '"' || char === "'") {
        inQuotes = !inQuotes;
      } else if (char === delimiter && !inQuotes) {
        fields.push(current.trim());
        current = "";
      } else {
        current += char;
      }
    }
    fields.push(current.trim());

    const row = {};
    headers.forEach((header, index) => {
      let val = fields[index] || "";
      // Strip outer quotes
      val = val.replace(/^["']|["']$/g, '').trim();
      row[header] = val;
    });

    parsedRows.push(row);
  }

  return parsedRows;
}

// ==========================================
// 2. VALIDATION & DUPLICATE CHECKING
// ==========================================
async function validateCSVRows(rows) {
  // Get all existing courses in DB
  const { data: dbCourses, error } = await supabaseClient
    .from("courses")
    .select("course_code");

  if (error) {
    console.error("Error fetching courses for validation:", error);
    throw error;
  }

  const existingCodes = new Set((dbCourses || []).map(c => c.course_code.toUpperCase().trim()));

  return rows.map((row, idx) => {
    // Map alternate names to standardized keys if necessary
    const rawCode = row.course_code || row.code || "";
    const rawName = row.course_name || row.name || row.title || "";
    const rawDept = row.department || row.dept || "";
    const rawLevel = row.level || "";
    const rawSemester = row.semester || "";

    const course_code = rawCode.trim().toUpperCase();
    const course_name = rawName.trim();
    const department = rawDept.trim();
    const semester = rawSemester.trim();
    
    // Parse level safely
    const levelInt = parseInt(rawLevel.replace(/[^0-9]/g, ''), 10);

    const errors = [];
    if (!course_code) errors.push("Missing Course Code");
    if (!course_name) errors.push("Missing Course Name");
    if (!department) errors.push("Missing Department");
    if (isNaN(levelInt) || levelInt < 100 || levelInt > 500) errors.push("Invalid Level (must be 100-500)");
    
    const validSemesters = ["First", "Second"];
    const normalizedSemester = semester.charAt(0).toUpperCase() + semester.slice(1).toLowerCase();
    if (!validSemesters.includes(normalizedSemester)) {
      errors.push("Invalid Semester (must be First or Second)");
    }

    const isDuplicate = existingCodes.has(course_code);
    const isValid = errors.length === 0;

    return {
      index: idx + 1,
      course_code,
      course_name,
      department,
      level: isNaN(levelInt) ? null : levelInt,
      semester: normalizedSemester,
      isValid,
      isDuplicate,
      errors: errors.join(", ")
    };
  });
}

// ==========================================
// 3. RENDER PREVIEW
// ==========================================
function renderCSVPreview(validatedRows) {
  const container = document.getElementById("csv-preview-section");
  const tableBody = document.getElementById("csv-preview-table-body");
  const summaryText = document.getElementById("csv-summary-text");
  const importBtn = document.getElementById("csv-import-start-btn");

  const validCount = validatedRows.filter(r => r.isValid && !r.isDuplicate).length;
  const duplicateCount = validatedRows.filter(r => r.isValid && r.isDuplicate).length;
  const invalidCount = validatedRows.filter(r => !r.isValid).length;

  summaryText.innerText = `${validatedRows.length} rows detected (${validCount} ready, ${duplicateCount} duplicate, ${invalidCount} invalid)`;

  let html = "";
  validatedRows.forEach(row => {
    let statusBadge = "";
    if (!row.isValid) {
      statusBadge = `<span class="px-2 py-0.5 bg-red-50 text-red-600 rounded text-xs font-semibold border border-red-100">Invalid: ${row.errors}</span>`;
    } else if (row.isDuplicate) {
      statusBadge = `<span class="px-2 py-0.5 bg-amber-50 text-amber-600 rounded text-xs font-semibold border border-amber-100">Duplicate (Exists)</span>`;
    } else {
      statusBadge = `<span class="px-2 py-0.5 bg-emerald-50 text-emerald-600 rounded text-xs font-semibold border border-emerald-100">Ready</span>`;
    }

    html += `
      <tr class="${!row.isValid ? 'bg-red-50/20' : row.isDuplicate ? 'bg-amber-50/20' : ''}">
        <td class="px-4 py-3 font-semibold text-slate-800">${row.course_code || '—'}</td>
        <td class="px-4 py-3">${row.course_name || '—'}</td>
        <td class="px-4 py-3">${row.department || '—'} · ${row.level || '—'}L · ${row.semester || '—'} Sem</td>
        <td class="px-4 py-3 text-right">${statusBadge}</td>
      </tr>
    `;
  });

  tableBody.innerHTML = html;
  container.classList.remove("hidden");

  if (validCount > 0) {
    importBtn.disabled = false;
  } else {
    importBtn.disabled = true;
  }

  csvParsedCourses = validatedRows;
}

// ==========================================
// 4. IMPORT ACTIONS
// ==========================================
async function startCSVImport() {
  if (csvImportIsRunning) return;
  csvImportIsRunning = true;

  const importBtn = document.getElementById("csv-import-start-btn");
  const btnText = importBtn.querySelector(".btn-text");
  const btnLoader = importBtn.querySelector(".btn-loader");
  const progressSection = document.getElementById("csv-import-progress");
  const progressBar = document.getElementById("csv-import-progress-bar");
  const progressLabel = document.getElementById("csv-import-progress-label");
  const progressPct = document.getElementById("csv-import-progress-pct");
  const logContainer = document.getElementById("csv-import-log");

  const toImport = csvParsedCourses.filter(r => r.isValid && !r.isDuplicate);
  const total = toImport.length;

  progressSection.classList.remove("hidden");
  importBtn.disabled = true;
  btnText.classList.add("hidden");
  btnLoader.classList.remove("hidden");

  progressBar.style.width = "0%";
  logContainer.innerHTML = "";

  let success = 0;
  let failure = 0;

  for (let i = 0; i < total; i++) {
    const course = toImport[i];
    try {
      const { error } = await supabaseClient
        .from("courses")
        .insert([{
          course_code: course.course_code,
          course_name: course.course_name,
          department: course.department,
          level: course.level,
          semester: course.semester
        }]);

      if (error) throw error;

      success++;
      const entry = document.createElement("div");
      entry.className = "text-slate-600";
      entry.innerText = `✅ Imported: ${course.course_code} — ${course.course_name}`;
      logContainer.appendChild(entry);
    } catch (err) {
      failure++;
      const entry = document.createElement("div");
      entry.className = "text-red-500 font-semibold";
      entry.innerText = `❌ Failed ${course.course_code}: ${err.message}`;
      logContainer.appendChild(entry);
    }

    const pct = Math.round(((i + 1) / total) * 100);
    progressBar.style.width = `${pct}%`;
    progressLabel.innerText = `${i + 1} of ${total} courses`;
    progressPct.innerText = `${pct}%`;
    logContainer.scrollTop = logContainer.scrollHeight;
  }

  showToast(`CSV Import Complete: ${success} imported, ${failure} failed.`, success > 0 ? "success" : "error");

  // Reset button state
  importBtn.disabled = false;
  btnText.classList.remove("hidden");
  btnLoader.classList.add("hidden");
  csvImportIsRunning = false;

  // Refresh courses list if the list fetcher function exists
  if (window.fetchCoursesList) {
    window.fetchCoursesList();
  }
}

// ==========================================
// 5. EVENT BINDINGS
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  const dropZone = document.getElementById("csv-drop-zone");
  const fileInput = document.getElementById("csv-file-input");
  const importStartBtn = document.getElementById("csv-import-start-btn");

  if (dropZone) {
    dropZone.addEventListener("click", () => fileInput?.click());

    dropZone.addEventListener("dragover", (e) => {
      e.preventDefault();
      dropZone.classList.add("border-emerald-500", "bg-emerald-50/20");
    });

    dropZone.addEventListener("dragleave", () => {
      dropZone.classList.remove("border-emerald-500", "bg-emerald-50/20");
    });

    dropZone.addEventListener("drop", (e) => {
      e.preventDefault();
      dropZone.classList.remove("border-emerald-500", "bg-emerald-50/20");
      if (e.dataTransfer.files.length > 0) {
        handleCSVFile(e.dataTransfer.files[0]);
      }
    });
  }

  if (fileInput) {
    fileInput.addEventListener("change", (e) => {
      if (e.target.files.length > 0) {
        handleCSVFile(e.target.files[0]);
      }
    });
  }

  function handleCSVFile(file) {
    if (!file.name.endsWith(".csv")) {
      showToast("Please upload a valid CSV file.", "error");
      return;
    }

    const reader = new FileReader();
    reader.onload = async (e) => {
      const text = e.target.result;
      try {
        const rawRows = parseCSVText(text);
        if (rawRows.length === 0) {
          showToast("CSV file is empty or formatted incorrectly.", "error");
          return;
        }

        const validated = await validateCSVRows(rawRows);
        renderCSVPreview(validated);

        // Update drop zone visual
        dropZone.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5" class="w-10 h-10 text-emerald-500 mx-auto mb-2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-xs font-semibold text-emerald-700">${file.name} loaded successfully</p>
        `;
      } catch (err) {
        showToast("Failed to parse CSV: " + err.message, "error");
      }
    };
    reader.readAsText(file);
  }

  if (importStartBtn) {
    importStartBtn.addEventListener("click", () => {
      startCSVImport();
    });
  }
});
