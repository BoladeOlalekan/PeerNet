// admin/js/mass-upload.js

// State
let massUploadMatchedCourses = [];
let massUploadUnmatchedCourses = [];
let massUploadCoursesDB = [];
let massUploadIsRunning = false;

const VALID_FILE_TYPES = {
  'notes': 'note',
  'past_questions': 'past_question',
  'videos': 'video'
};

// ==========================================
// 1. PARSE FOLDER FILES
// ==========================================
function parseFolderFiles(fileList) {
  // Groups files by courseCode -> fileType -> File[]
  // Expected path: RootFolder/CourseCode/fileType/filename
  const courseMap = new Map();

  for (const file of fileList) {
    const path = file.webkitRelativePath;
    const parts = path.split('/');

    // Expect at least: RootFolder / CourseCode / fileType / filename
    if (parts.length < 4) continue;

    // parts[0] = root folder name (ignored)
    // parts[1] = course code folder
    // parts[2] = file type folder (notes, past_questions, videos)
    // parts[3+] = filename (could be nested deeper, but we take the file)
    const courseCode = parts[1].trim().toUpperCase();
    const fileTypeFolder = parts[2].trim().toLowerCase();

    // Skip videos folder (YouTube links only) and unrecognized folders
    if (!VALID_FILE_TYPES[fileTypeFolder]) continue;

    // Skip hidden files and system files
    if (file.name.startsWith('.') || file.name === 'Thumbs.db' || file.name === 'desktop.ini') continue;

    if (!courseMap.has(courseCode)) {
      courseMap.set(courseCode, { notes: [], past_questions: [], videos: [] });
    }

    courseMap.get(courseCode)[fileTypeFolder].push(file);
  }

  return courseMap;
}

// ==========================================
// 2. MATCH COURSES TO DATABASE
// ==========================================
async function matchCoursesToDB(parsedMap, dept, level, semester) {
  // Fetch all courses matching criteria
  const { data: courses, error } = await supabaseClient
    .from("courses")
    .select("id, course_code, course_name")
    .eq("department", dept)
    .eq("level", parseInt(level, 10))
    .eq("semester", semester)
    .order("course_code");

  if (error) throw error;

  massUploadCoursesDB = courses || [];

  const matched = [];
  const unmatched = [];

  for (const [courseCode, filesByType] of parsedMap) {
    const dbCourse = massUploadCoursesDB.find(
      c => c.course_code.toUpperCase() === courseCode
    );

    const totalFiles = filesByType.notes.length + filesByType.past_questions.length + filesByType.videos.length;

    if (dbCourse) {
      matched.push({
        courseCode,
        courseId: dbCourse.id,
        courseName: dbCourse.course_name,
        files: filesByType,
        totalFiles
      });
    } else {
      unmatched.push({
        courseCode,
        files: filesByType,
        totalFiles
      });
    }
  }

  return { matched, unmatched };
}

// ==========================================
// 3. RENDER FILE PREVIEW
// ==========================================
function renderFilePreview(matched, unmatched) {
  const previewSection = document.getElementById("mass-upload-preview");
  const fileTree = document.getElementById("mass-upload-file-tree");
  const summaryText = document.getElementById("mass-upload-summary-text");
  const startBtn = document.getElementById("mass-upload-start-btn");

  const totalMatchedFiles = matched.reduce((sum, c) => sum + c.totalFiles, 0);
  const totalUnmatchedFiles = unmatched.reduce((sum, c) => sum + c.totalFiles, 0);
  const totalFiles = totalMatchedFiles + totalUnmatchedFiles;

  summaryText.innerText = `${totalFiles} files across ${matched.length + unmatched.length} courses (${totalMatchedFiles} matched, ${totalUnmatchedFiles} skipped)`;

  let html = '';

  // Matched courses
  matched.forEach(course => {
    html += `
      <div class="bg-emerald-50/50 border border-emerald-100/60 rounded-xl p-4">
        <div class="flex items-center gap-3 mb-2">
          <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-emerald-100 text-emerald-600">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
            </svg>
          </span>
          <span class="text-sm font-bold text-slate-800">${course.courseCode}</span>
          <span class="text-xs text-slate-500">— ${course.courseName}</span>
          <span class="ml-auto text-xs font-semibold text-emerald-600">${course.totalFiles} file${course.totalFiles !== 1 ? 's' : ''}</span>
        </div>
        <div class="pl-8 space-y-1">
          ${course.files.notes.length > 0 ? `<div class="text-xs text-slate-600">📄 <strong>notes/</strong> — ${course.files.notes.length} file${course.files.notes.length !== 1 ? 's' : ''}</div>` : ''}
          ${course.files.past_questions.length > 0 ? `<div class="text-xs text-slate-600">📝 <strong>past_questions/</strong> — ${course.files.past_questions.length} file${course.files.past_questions.length !== 1 ? 's' : ''}</div>` : ''}
          ${course.files.videos.length > 0 ? `<div class="text-xs text-slate-600">🎬 <strong>videos/</strong> — ${course.files.videos.length} link${course.files.videos.length !== 1 ? 's' : ''}</div>` : ''}
        </div>
      </div>
    `;
  });

  // Unmatched courses
  unmatched.forEach(course => {
    html += `
      <div class="bg-red-50/50 border border-red-100/60 rounded-xl p-4">
        <div class="flex items-center gap-3 mb-1">
          <span class="inline-flex items-center justify-center w-5 h-5 rounded-full bg-red-100 text-red-500">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </span>
          <span class="text-sm font-bold text-slate-800">${course.courseCode}</span>
          <span class="text-xs text-red-500 font-semibold">Not found in database — will be skipped</span>
          <span class="ml-auto text-xs font-semibold text-red-500">${course.totalFiles} file${course.totalFiles !== 1 ? 's' : ''}</span>
        </div>
      </div>
    `;
  });

  if (matched.length === 0 && unmatched.length === 0) {
    html = `
      <div class="text-center py-8 text-slate-400">
        <p class="text-sm">No valid files detected. Please check your folder structure.</p>
      </div>
    `;
  }

  fileTree.innerHTML = html;
  previewSection.classList.remove("hidden");

  // Enable upload button only if there are matched files
  if (totalMatchedFiles > 0) {
    startBtn.disabled = false;
  } else {
    startBtn.disabled = true;
  }

  massUploadMatchedCourses = matched;
  massUploadUnmatchedCourses = unmatched;
}

// ==========================================
// 4. START MASS UPLOAD
// ==========================================
async function startMassUpload(matched, dept, level, semester) {
  if (massUploadIsRunning) return;
  massUploadIsRunning = true;

  const progressSection = document.getElementById("mass-upload-progress");
  const progressBar = document.getElementById("mass-upload-progress-bar");
  const progressLabel = document.getElementById("mass-upload-progress-label");
  const progressPct = document.getElementById("mass-upload-progress-pct");
  const logContainer = document.getElementById("mass-upload-log");
  const summarySection = document.getElementById("mass-upload-final-summary");
  const startBtn = document.getElementById("mass-upload-start-btn");
  const btnText = startBtn.querySelector(".btn-text");
  const btnLoader = startBtn.querySelector(".btn-loader");

  // Show progress, disable button
  progressSection.classList.remove("hidden");
  summarySection.classList.add("hidden");
  startBtn.disabled = true;
  btnText.classList.add("hidden");
  btnLoader.classList.remove("hidden");
  logContainer.innerHTML = '';
  progressBar.style.width = '0%';

  // Build flat file list
  const fileQueue = [];
  for (const course of matched) {
    for (const [fileTypeFolder, files] of Object.entries(course.files)) {
      const dbFileType = VALID_FILE_TYPES[fileTypeFolder];
      if (!dbFileType) continue;
      for (const file of files) {
        fileQueue.push({
          file,
          courseCode: course.courseCode,
          courseId: course.courseId,
          fileTypeFolder, // notes or past_questions
          dbFileType      // note or past_question
        });
      }
    }
  }

  const totalFiles = fileQueue.length;
  let successCount = 0;
  let failCount = 0;
  const skippedCount = massUploadUnmatchedCourses.reduce((sum, c) => sum + c.totalFiles, 0);

  for (let i = 0; i < fileQueue.length; i++) {
    const item = fileQueue[i];
    const { file, courseCode, courseId, fileTypeFolder, dbFileType } = item;

    const cleanDept = dept.trim();
    const cleanLevel = level.toString();
    const cleanSemester = semester.trim();
    const cleanCourse = courseCode.trim().toUpperCase();
    const timestamp = Date.now();

    try {
      if (dbFileType === 'video') {
        // Video: read file content as YouTube URL text
        const youtubeUrl = await readFileAsText(file);
        const trimmedUrl = youtubeUrl.trim();

        if (!trimmedUrl) {
          throw new Error('Empty video link file');
        }

        // Insert database record with YouTube URL (no storage upload)
        const { error: dbError } = await supabaseClient
          .from("resources")
          .insert([{
            course_id: courseId,
            uploader_firebase_uid: "admin",
            storage_path: null,
            youtube_url: trimmedUrl,
            mime_type: "video/youtube",
            size_bytes: 0,
            file_type: dbFileType,
            approval_status: "approved",
            file_name: file.name.replace(/\.txt$/i, '')
          }]);

        if (dbError) throw dbError;

        successCount++;
        appendLog(logContainer, `✅ ${courseCode}/videos/${file.name} → ${trimmedUrl}`, 'success');
      } else {
        // Notes / Past Questions: upload file to storage
        const storagePath = `resources/${cleanDept}/${cleanLevel}/${cleanSemester}/${cleanCourse}/${fileTypeFolder}/${timestamp}_${file.name}`;

        const { error: uploadError } = await supabaseClient.storage
          .from("resources")
          .upload(storagePath, file, {
            cacheControl: '3600',
            upsert: false
          });

        if (uploadError) throw uploadError;

        // Insert database record
        const { error: dbError } = await supabaseClient
          .from("resources")
          .insert([{
            course_id: courseId,
            uploader_firebase_uid: "admin",
            storage_path: storagePath,
            youtube_url: null,
            mime_type: file.type || "application/octet-stream",
            size_bytes: file.size,
            file_type: dbFileType,
            approval_status: "approved",
            file_name: file.name
          }]);

        if (dbError) throw dbError;

        successCount++;
        appendLog(logContainer, `✅ ${courseCode}/${fileTypeFolder}/${file.name}`, 'success');
      }
    } catch (err) {
      failCount++;
      appendLog(logContainer, `❌ ${courseCode}/${fileTypeFolder}/${file.name} — ${err.message}`, 'error');
    }

    // Update progress
    const progress = Math.round(((i + 1) / totalFiles) * 100);
    progressBar.style.width = `${progress}%`;
    progressLabel.innerText = `${i + 1} of ${totalFiles} files`;
    progressPct.innerText = `${progress}%`;
  }

  // Show summary
  document.getElementById("mass-upload-count-success").innerText = successCount;
  document.getElementById("mass-upload-count-skipped").innerText = skippedCount;
  document.getElementById("mass-upload-count-failed").innerText = failCount;
  summarySection.classList.remove("hidden");

  // Reset button
  startBtn.disabled = false;
  btnText.classList.remove("hidden");
  btnLoader.classList.add("hidden");
  massUploadIsRunning = false;

  if (successCount > 0) {
    showToast(`Mass upload complete! ${successCount} files uploaded successfully.`, "success");
  } else {
    showToast("Mass upload finished with no successful uploads.", "error");
  }
}

function appendLog(container, message, type) {
  const entry = document.createElement("div");
  entry.className = type === 'success'
    ? 'text-slate-600'
    : 'text-red-500 font-semibold';
  entry.innerText = message;
  container.appendChild(entry);
  container.scrollTop = container.scrollHeight;
}

// Helper to read a file's text content
function readFileAsText(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
}

// ==========================================
// 5. EVENT BINDINGS
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  const dropZone = document.getElementById("mass-upload-drop-zone");
  const folderInput = document.getElementById("mass-upload-folder-input");
  const loadCoursesBtn = document.getElementById("mass-upload-load-courses-btn");
  const startBtn = document.getElementById("mass-upload-start-btn");

  const deptSelect = document.getElementById("mass-upload-dept");
  const levelSelect = document.getElementById("mass-upload-level");
  const semesterSelect = document.getElementById("mass-upload-semester");

  // Load Matching Courses button
  if (loadCoursesBtn) {
    loadCoursesBtn.addEventListener("click", async () => {
      const dept = deptSelect?.value;
      const level = levelSelect?.value;
      const semester = semesterSelect?.value;

      if (!dept || !level || !semester) {
        showToast("Please select Department, Level, and Semester first.", "error");
        return;
      }

      try {
        const { data: courses, error } = await supabaseClient
          .from("courses")
          .select("id, course_code, course_name")
          .eq("department", dept)
          .eq("level", parseInt(level, 10))
          .eq("semester", semester)
          .order("course_code");

        if (error) throw error;

        massUploadCoursesDB = courses || [];

        const chipsSection = document.getElementById("mass-upload-course-chips");
        const chipsContainer = document.getElementById("mass-upload-chips-container");

        if (!courses || courses.length === 0) {
          chipsContainer.innerHTML = `<span class="text-xs text-slate-400">No courses found for this selection.</span>`;
        } else {
          chipsContainer.innerHTML = courses.map(c =>
            `<span class="inline-flex items-center gap-1 px-3 py-1.5 bg-emerald-50 text-emerald-700 text-xs font-semibold rounded-lg border border-emerald-100/60">${c.course_code}</span>`
          ).join('');
        }

        chipsSection.classList.remove("hidden");
        showToast(`Found ${courses.length} course(s) matching criteria.`, "info");
      } catch (err) {
        showToast("Failed to load courses: " + err.message, "error");
      }
    });
  }

  // Folder click to select
  if (dropZone) {
    dropZone.addEventListener("click", () => folderInput?.click());

    // Drag and drop
    dropZone.addEventListener("dragover", (e) => {
      e.preventDefault();
      dropZone.classList.add("dragover");
    });

    dropZone.addEventListener("dragleave", () => {
      dropZone.classList.remove("dragover");
    });

    dropZone.addEventListener("drop", (e) => {
      e.preventDefault();
      dropZone.classList.remove("dragover");
      // Note: drop event doesn't support webkitdirectory well in most browsers
      // Fall back to showing a hint
      if (e.dataTransfer.files.length > 0) {
        handleFolderSelection(e.dataTransfer.files);
      }
    });
  }

  // Folder input change
  if (folderInput) {
    folderInput.addEventListener("change", (e) => {
      if (e.target.files.length > 0) {
        handleFolderSelection(e.target.files);
      }
    });
  }

  async function handleFolderSelection(fileList) {
    const dept = deptSelect?.value;
    const level = levelSelect?.value;
    const semester = semesterSelect?.value;

    if (!dept || !level || !semester) {
      showToast("Please select Department, Level, and Semester and load courses first.", "error");
      return;
    }

    // Parse files from folder
    const parsedMap = parseFolderFiles(fileList);

    if (parsedMap.size === 0) {
      showToast("No valid files detected. Ensure your folder has CourseCode/notes/ or CourseCode/past_questions/ subdirectories.", "error");
      return;
    }

    try {
      // Match against DB
      const { matched, unmatched } = await matchCoursesToDB(parsedMap, dept, level, semester);

      // Render preview
      renderFilePreview(matched, unmatched);

      // Update drop zone to show selected state
      const totalFiles = [...parsedMap.values()].reduce((sum, v) => sum + v.notes.length + v.past_questions.length, 0);
      dropZone.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"
          stroke-width="1.5" class="w-12 h-12 text-emerald-500 mx-auto mb-4">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="text-sm font-semibold text-emerald-700 mb-1">Folder loaded — ${totalFiles} files detected</p>
        <p class="text-xs text-slate-400">Click again to select a different folder</p>
      `;
    } catch (err) {
      showToast("Error processing folder: " + err.message, "error");
    }
  }

  // Start Upload button
  if (startBtn) {
    startBtn.addEventListener("click", async () => {
      const dept = deptSelect?.value;
      const level = levelSelect?.value;
      const semester = semesterSelect?.value;

      if (massUploadMatchedCourses.length === 0) {
        showToast("No matched courses to upload.", "error");
        return;
      }

      await startMassUpload(massUploadMatchedCourses, dept, level, semester);
    });
  }
});
