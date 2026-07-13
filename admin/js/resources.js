// admin/js/resources.js

let selectedUploadFile = null;

// ==========================================
// 1. PENDING REVIEWS
// ==========================================
async function fetchPendingResources() {
  const container = document.getElementById("pending-container");
  if (!container) return;

  container.innerHTML = `
    <div class="empty-state">
      <div class="btn-loader" style="margin: 20px auto;"></div>
      <p>Loading pending reviews...</p>
    </div>
  `;

  try {
    // Fetch pending resources and join with courses to get course info
    const { data: resources, error } = await supabase
      .from("resources")
      .select(`
        id,
        file_name,
        file_type,
        size_bytes,
        storage_path,
        created_at,
        uploader_firebase_uid,
        youtube_url,
        course:course_id (
          course_code,
          course_name,
          department,
          level,
          semester
        )
      `)
      .eq("approval_status", "pending")
      .order("created_at", { ascending: false });

    if (error) throw error;

    if (!resources || resources.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3>Clean Slate!</h3>
          <p>No student uploads are pending review right now.</p>
        </div>
      `;
      return;
    }

    container.innerHTML = "";
    resources.forEach(res => {
      const card = document.createElement("div");
      card.className = "pending-card";
      
      const courseInfo = res.course || { course_code: "N/A", course_name: "Unknown Course", department: "N/A", level: "N/A", semester: "N/A" };
      const formattedSize = formatBytes(res.size_bytes);
      const formattedDate = new Date(res.created_at).toLocaleDateString(undefined, {
        month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit'
      });

      card.innerHTML = `
        <div class="card-header">
          <div class="file-info-badge">
            <div class="file-icon">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div class="file-meta-top">
              <span class="file-name" title="${res.file_name || 'Unnamed File'}">${res.file_name || 'Unnamed File'}</span>
              <span class="file-type-label">${res.file_type.replace('_', ' ')}</span>
            </div>
          </div>
          <span class="badge badge-pending">Pending</span>
        </div>

        <div class="card-details">
          <div class="detail-row">
            <span class="detail-label">Course:</span>
            <span class="detail-val" style="font-weight: 700;">${courseInfo.course_code} - ${courseInfo.course_name}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Dept / Info:</span>
            <span class="detail-val">${courseInfo.department} (${courseInfo.level}L, ${courseInfo.semester})</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Uploader:</span>
            <span class="detail-val" style="font-family: monospace; font-size: 11px;">${res.uploader_firebase_uid.substring(0, 8)}...</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Size:</span>
            <span class="detail-val">${formattedSize}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Date:</span>
            <span class="detail-val">${formattedDate}</span>
          </div>
          ${res.youtube_url ? `
          <div class="detail-row">
            <span class="detail-label">YouTube:</span>
            <span class="detail-val"><a href="${res.youtube_url}" target="_blank" style="color: var(--primary-light);">Watch video</a></span>
          </div>` : ''}
        </div>

        <div class="card-actions">
          <button class="btn btn-secondary" onclick="previewResource('${res.storage_path}')">Preview</button>
          <button class="btn btn-primary" style="background-color: var(--success);" onclick="moderateResource('${res.id}', 'approved')">Approve</button>
          <button class="btn btn-danger" onclick="moderateResource('${res.id}', 'rejected')">Reject</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    showToast("Error fetching reviews: " + err.message, "error");
    container.innerHTML = `
      <div class="empty-state">
        <h3 style="color: var(--danger);">Load Failed</h3>
        <p>${err.message}</p>
      </div>
    `;
  }
}

async function moderateResource(id, status) {
  try {
    const { error } = await supabase
      .from("resources")
      .update({ approval_status: status })
      .eq("id", id);

    if (error) throw error;

    showToast(`Resource ${status === 'approved' ? 'Approved' : 'Rejected'} successfully!`, "success");
    fetchPendingResources();
  } catch (err) {
    showToast("Moderation failed: " + err.message, "error");
  }
}

// Get public URL and preview file
function previewResource(storagePath) {
  if (!storagePath) {
    showToast("Storage path missing.", "error");
    return;
  }
  const { data } = supabase.storage.from("resources").getPublicUrl(storagePath);
  if (data && data.publicUrl) {
    window.open(data.publicUrl, "_blank");
  } else {
    showToast("Could not generate public URL.", "error");
  }
}

// Helper to format bytes to human readable format
function formatBytes(bytes, decimals = 2) {
  if (!bytes || bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// ==========================================
// 2. ALL RESOURCES
// ==========================================
async function fetchAllResources() {
  const tableBody = document.getElementById("resources-list");
  if (!tableBody) return;

  const searchQuery = document.getElementById("resource-search")?.value.trim().toLowerCase() || "";
  const statusFilter = document.getElementById("resource-filter-status")?.value || "all";
  const deptFilter = document.getElementById("resource-filter-dept")?.value || "all";

  tableBody.innerHTML = `
    <tr>
      <td colspan="9" style="text-align: center; color: var(--text-muted); padding: 30px;">
        <div class="btn-loader" style="margin: 0 auto 10px;"></div>
        Loading resources list...
      </td>
    </tr>
  `;

  try {
    let query = supabase
      .from("resources")
      .select(`
        id,
        file_name,
        file_type,
        size_bytes,
        storage_path,
        created_at,
        uploader_firebase_uid,
        approval_status,
        course:course_id (
          course_code,
          course_name,
          department
        )
      `);

    if (statusFilter !== "all") {
      query = query.eq("approval_status", statusFilter);
    }

    const { data: resources, error } = await query.order("created_at", { ascending: false });

    if (error) throw error;

    // Apply client-side filters (for search and department join)
    let filteredResources = resources;

    if (deptFilter !== "all") {
      filteredResources = filteredResources.filter(res => res.course && res.course.department === deptFilter);
    }

    if (searchQuery) {
      filteredResources = filteredResources.filter(res => {
        const fileName = (res.file_name || "").toLowerCase();
        const courseCode = res.course ? res.course.course_code.toLowerCase() : "";
        const courseName = res.course ? res.course.course_name.toLowerCase() : "";
        return fileName.includes(searchQuery) || courseCode.includes(searchQuery) || courseName.includes(searchQuery);
      });
    }

    if (filteredResources.length === 0) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="9" style="text-align: center; color: var(--text-muted); padding: 20px;">
            No resources found.
          </td>
        </tr>
      `;
      return;
    }

    tableBody.innerHTML = "";
    filteredResources.forEach(res => {
      const courseInfo = res.course || { course_code: "N/A", course_name: "Unknown", department: "N/A" };
      const formattedDate = new Date(res.created_at).toLocaleDateString(undefined, {
        month: 'short', day: 'numeric', year: 'numeric'
      });
      const formattedSize = formatBytes(res.size_bytes);
      
      let badgeClass = "badge-pending";
      if (res.approval_status === 'approved') badgeClass = "badge-approved";
      if (res.approval_status === 'rejected') badgeClass = "badge-rejected";

      const row = document.createElement("tr");
      row.innerHTML = `
        <td style="font-weight: 500; max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="${res.file_name}">${res.file_name || 'Unnamed'}</td>
        <td style="font-weight: 600; color: var(--primary-light);">${courseInfo.course_code}</td>
        <td style="font-size: 13px; color: var(--text-secondary);">${courseInfo.department}</td>
        <td style="font-family: monospace; font-size: 11px;">${res.uploader_firebase_uid === 'admin' ? '<span style="color: var(--accent); font-weight: bold;">ADMIN</span>' : res.uploader_firebase_uid.substring(0, 8) + '...'}</td>
        <td style="font-size: 13px;">${formattedSize}</td>
        <td style="text-transform: capitalize; font-size: 13px;">${res.file_type.replace('_', ' ')}</td>
        <td><span class="badge ${badgeClass}">${res.approval_status}</span></td>
        <td style="font-size: 13px; color: var(--text-muted);">${formattedDate}</td>
        <td>
          <div class="action-buttons-cell">
            <button class="action-btn" onclick="previewResource('${res.storage_path}')" title="Preview">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="16" height="16">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
            </button>
            <button class="action-btn btn-delete-item" onclick="confirmDeleteResource('${res.id}', '${res.storage_path}', '${res.file_name}')" title="Delete">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="16" height="16">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </td>
      `;
      tableBody.appendChild(row);
    });
  } catch (err) {
    showToast("Error fetching resources: " + err.message, "error");
    tableBody.innerHTML = `
      <tr>
        <td colspan="9" style="text-align: center; color: var(--danger); padding: 20px;">
          Failed to load resources.
        </td>
      </tr>
    `;
  }
}

function confirmDeleteResource(id, storagePath, filename) {
  showConfirmModal({
    title: "Delete Resource?",
    message: `Are you sure you want to permanently delete "${filename}" from the database and storage?`,
    isDanger: true,
    onConfirm: async () => {
      try {
        // 1. Delete DB record
        const { error: dbError } = await supabase
          .from("resources")
          .delete()
          .eq("id", id);

        if (dbError) throw dbError;

        // 2. Delete storage file if path exists
        if (storagePath) {
          const { error: storageError } = await supabase.storage
            .from("resources")
            .remove([storagePath]);
          
          if (storageError) {
            console.error("Storage deletion warning:", storageError.message);
          }
        }

        showToast("Resource deleted successfully!", "success");
        fetchAllResources();
      } catch (err) {
        showToast("Failed to delete resource: " + err.message, "error");
      }
    }
  });
}

// ==========================================
// 3. ADMIN UPLOAD FORM
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  const uploadForm = document.getElementById("admin-upload-form");
  const uploadDept = document.getElementById("upload-dept");
  const uploadLevel = document.getElementById("upload-level");
  const uploadSemester = document.getElementById("upload-semester");
  const uploadCourse = document.getElementById("upload-course");
  const uploadFileType = document.getElementById("upload-file-type");
  const youtubeUrlGroup = document.getElementById("youtube-url-group");
  const fileSelectGroup = document.getElementById("file-select-group");
  const fileInput = document.getElementById("upload-file-input");
  const fileZone = document.getElementById("file-select-zone");
  const fileDisplay = document.getElementById("selected-file-display");
  const fileNameLabel = document.getElementById("selected-file-name");
  const removeFileBtn = document.getElementById("remove-file-btn");
  const submitBtn = document.getElementById("upload-submit-btn");

  // Dynamic Course Populator on uploading form dependent on inputs
  async function populateUploadCoursesDropdown() {
    const dept = uploadDept.value;
    const level = parseInt(uploadLevel.value, 10);
    const semester = uploadSemester.value;

    if (!dept || !level || !semester) {
      uploadCourse.disabled = true;
      uploadCourse.innerHTML = `<option value="" disabled selected>Select Course (Choose Department, Level & Semester first)</option>`;
      return;
    }

    uploadCourse.disabled = false;
    uploadCourse.innerHTML = `<option value="" disabled selected>Loading courses...</option>`;

    try {
      const { data: courses, error } = await supabase
        .from("courses")
        .select("id, course_code, course_name")
        .eq("department", dept)
        .eq("level", level)
        .eq("semester", semester)
        .order("course_code");

      if (error) throw error;

      if (!courses || courses.length === 0) {
        uploadCourse.innerHTML = `<option value="" disabled selected>No courses found matching criteria</option>`;
        return;
      }

      uploadCourse.innerHTML = `<option value="" disabled selected>Select Course</option>`;
      courses.forEach(course => {
        const opt = document.createElement("option");
        opt.value = course.id;
        opt.dataset.code = course.course_code;
        opt.innerText = `${course.course_code} - ${course.course_name}`;
        uploadCourse.appendChild(opt);
      });
    } catch (err) {
      uploadCourse.innerHTML = `<option value="" disabled selected>Error loading courses</option>`;
      showToast("Could not load courses: " + err.message, "error");
    }
  }

  // Bind dropdown change listeners
  if (uploadDept) uploadDept.addEventListener("change", populateUploadCoursesDropdown);
  if (uploadLevel) uploadLevel.addEventListener("change", populateUploadCoursesDropdown);
  if (uploadSemester) uploadSemester.addEventListener("change", populateUploadCoursesDropdown);

  // Toggle Video YouTube URL vs File Upload fields
  if (uploadFileType) {
    uploadFileType.addEventListener("change", () => {
      if (uploadFileType.value === "video") {
        youtubeUrlGroup.classList.remove("hidden");
        fileSelectGroup.classList.add("hidden");
      } else {
        youtubeUrlGroup.classList.add("hidden");
        fileSelectGroup.classList.remove("hidden");
      }
    });
  }

  // File Picker Click
  if (fileZone) {
    fileZone.addEventListener("click", () => fileInput.click());
    
    // Drag & drop
    fileZone.addEventListener("dragover", (e) => {
      e.preventDefault();
      fileZone.classList.add("dragover");
    });
    
    fileZone.addEventListener("dragleave", () => {
      fileZone.classList.remove("dragover");
    });
    
    fileZone.addEventListener("drop", (e) => {
      e.preventDefault();
      fileZone.classList.remove("dragover");
      if (e.dataTransfer.files.length > 0) {
        handleFileSelection(e.dataTransfer.files[0]);
      }
    });
  }

  if (fileInput) {
    fileInput.addEventListener("change", (e) => {
      if (e.target.files.length > 0) {
        handleFileSelection(e.target.files[0]);
      }
    });
  }

  function handleFileSelection(file) {
    selectedUploadFile = file;
    fileNameLabel.innerText = `${file.name} (${formatBytes(file.size)})`;
    fileZone.classList.add("hidden");
    fileDisplay.classList.remove("hidden");
  }

  if (removeFileBtn) {
    removeFileBtn.addEventListener("click", () => {
      selectedUploadFile = null;
      fileInput.value = "";
      fileDisplay.classList.add("hidden");
      fileZone.classList.remove("hidden");
    });
  }

  // Upload Form Submit Event
  if (uploadForm) {
    uploadForm.addEventListener("submit", async (e) => {
      e.preventDefault();

      const type = uploadFileType.value;
      const dept = uploadDept.value;
      const level = parseInt(uploadLevel.value, 10);
      const semester = uploadSemester.value;
      const courseId = uploadCourse.value;
      const selectedCourseOpt = uploadCourse.options[uploadCourse.selectedIndex];
      const courseCode = selectedCourseOpt.dataset.code;

      const youtubeUrl = document.getElementById("upload-youtube-url").value.trim();

      if (type !== "video" && !selectedUploadFile) {
        showToast("Please choose a file to upload.", "error");
        return;
      }

      if (type === "video" && !youtubeUrl) {
        showToast("Please provide a valid YouTube reference link.", "error");
        return;
      }

      // Loader State
      const btnText = submitBtn.querySelector(".btn-text");
      const btnLoader = submitBtn.querySelector(".btn-loader");
      submitBtn.disabled = true;
      btnText.classList.add("hidden");
      btnLoader.classList.remove("hidden");

      try {
        let storagePath = "";
        let sizeBytes = 0;
        let mimeType = "";
        let fileName = "";

        if (type !== "video") {
          // File upload flow
          fileName = selectedUploadFile.name;
          sizeBytes = selectedUploadFile.size;
          mimeType = selectedUploadFile.type || "application/octet-stream";

          // Format Storage Folders: notes, videos, past_questions, others
          let storageFolder = "others";
          if (type === "note") storageFolder = "notes";
          else if (type === "past_question") storageFolder = "past_questions";

          const cleanDept = dept.trim();
          const cleanLevel = level.toString();
          const cleanSemester = semester.trim();
          const cleanCourse = courseCode.trim().toUpperCase();
          const timestamp = Date.now();
          
          storagePath = `resources/${cleanDept}/${cleanLevel}/${cleanSemester}/${cleanCourse}/${storageFolder}/${timestamp}_${fileName}`;

          // Upload binary to Supabase storage
          const { error: uploadError } = await supabase.storage
            .from("resources")
            .upload(storagePath, selectedUploadFile, {
              cacheControl: '3600',
              upsert: false
            });

          if (uploadError) throw uploadError;
        } else {
          // Video reference link flow
          fileName = `Video Resource: ${selectedCourseOpt.innerText}`;
          mimeType = "video/youtube";
        }

        // Insert metadata row
        const dbFileType = type; // matching note, past_question, video
        const { error: dbError } = await supabase
          .from("resources")
          .insert([{
            course_id: courseId,
            uploader_firebase_uid: "admin",
            storage_path: storagePath || null,
            youtube_url: youtubeUrl || null,
            mime_type: mimeType,
            size_bytes: sizeBytes,
            file_type: dbFileType,
            approval_status: "approved", // auto approved
            file_name: fileName
          }]);

        if (dbError) throw dbError;

        showToast("Resource uploaded and auto-approved successfully!", "success");
        
        // Reset form
        uploadForm.reset();
        selectedUploadFile = null;
        if (fileInput) fileInput.value = "";
        fileDisplay.classList.add("hidden");
        fileZone.classList.remove("hidden");
        uploadCourse.disabled = true;
        uploadCourse.innerHTML = `<option value="" disabled selected>Select Course (Choose Department & Level first)</option>`;
        
      } catch (err) {
        showToast("Upload failed: " + err.message, "error");
      } finally {
        // Reset button loading
        submitBtn.disabled = false;
        btnText.classList.remove("hidden");
        btnLoader.classList.add("hidden");
      }
    });
  }

  // Refresh and filters bindings in All Resources tab
  const searchInput = document.getElementById("resource-search");
  const filterStatus = document.getElementById("resource-filter-status");
  const filterDept = document.getElementById("resource-filter-dept");
  const refreshBtn = document.getElementById("resource-refresh-btn");

  if (searchInput) searchInput.addEventListener("input", fetchAllResources);
  if (filterStatus) filterStatus.addEventListener("change", fetchAllResources);
  if (filterDept) filterDept.addEventListener("change", fetchAllResources);
  if (refreshBtn) refreshBtn.addEventListener("click", fetchAllResources);
});
