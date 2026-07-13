// admin/js/courses.js

let selectedCourseIdToEdit = null;

// Fetch and display courses
async function fetchCoursesList() {
  const tableBody = document.getElementById("courses-table-body");
  if (!tableBody) return;

  const filterDept = document.getElementById("course-list-filter-dept")?.value || "all";

  tableBody.innerHTML = `
    <tr>
      <td colspan="4" style="text-align: center; color: var(--text-muted);">
        <div class="btn-loader" style="margin: 20px auto;"></div>
        Loading courses...
      </td>
    </tr>
  `;

  try {
    let query = supabase
      .from("courses")
      .select("*");

    if (filterDept !== "all") {
      query = query.eq("department", filterDept);
    }

    const { data: courses, error } = await query.order("course_code", { ascending: true });

    if (error) throw error;

    if (!courses || courses.length === 0) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="4" style="text-align: center; color: var(--text-muted); padding: 20px;">
            No courses found. Create one.
          </td>
        </tr>
      `;
      return;
    }

    tableBody.innerHTML = "";
    courses.forEach(course => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td style="font-weight: 700; color: var(--primary-light);">${course.course_code}</td>
        <td style="font-weight: 500;">${course.course_name}</td>
        <td>
          <div style="font-size: 12px; color: var(--text-secondary);">${course.department}</div>
          <div style="font-size: 11px; color: var(--text-muted);">${course.level} Level | ${course.semester} Semester</div>
        </td>
        <td style="text-align: right;">
          <div class="action-buttons-cell" style="justify-content: flex-end;">
            <button class="action-btn btn-edit-item" onclick="startEditCourse('${course.id}', '${course.course_code}', '${course.course_name}', '${course.department}', '${course.level}', '${course.semester}')">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="18" height="18">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-2.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
            <button class="action-btn btn-delete-item" onclick="confirmDeleteCourse('${course.id}', '${course.course_code}')">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="18" height="18">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </td>
      `;
      tableBody.appendChild(row);
    });
  } catch (err) {
    showToast("Error loading courses: " + err.message, "error");
    tableBody.innerHTML = `
      <tr>
        <td colspan="4" style="text-align: center; color: var(--danger); padding: 20px;">
          Failed to load courses.
        </td>
      </tr>
    `;
  }
}

// Start editing a course
function startEditCourse(id, code, name, dept, level, semester) {
  selectedCourseIdToEdit = id;
  
  document.getElementById("course-form-title").innerText = "Edit Course";
  document.getElementById("course-edit-id").value = id;
  document.getElementById("course-code").value = code;
  document.getElementById("course-name").value = name;
  document.getElementById("course-dept").value = dept;
  document.getElementById("course-level").value = level;
  document.getElementById("course-semester").value = semester;
  
  document.getElementById("course-cancel-btn").classList.remove("hidden");
  
  // Scroll form into view
  document.getElementById("course-form").scrollIntoView({ behavior: 'smooth' });
}

// Reset course form
function resetCourseForm() {
  selectedCourseIdToEdit = null;
  document.getElementById("course-form-title").innerText = "Create New Course";
  document.getElementById("course-form").reset();
  document.getElementById("course-edit-id").value = "";
  document.getElementById("course-cancel-btn").classList.add("hidden");
}

// Delete course action
function confirmDeleteCourse(id, code) {
  showConfirmModal({
    title: "Delete Course?",
    message: `Are you sure you want to delete course "${code}"? All resources associated with this course may become orphaned.`,
    isDanger: true,
    onConfirm: async () => {
      try {
        const { error } = await supabase
          .from("courses")
          .delete()
          .eq("id", id);

        if (error) throw error;

        showToast(`Course "${code}" deleted successfully!`, "success");
        fetchCoursesList();
      } catch (err) {
        showToast("Error deleting course: " + err.message, "error");
      }
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  // Course Filter Change Event
  const filterDept = document.getElementById("course-list-filter-dept");
  if (filterDept) {
    filterDept.addEventListener("change", () => {
      fetchCoursesList();
    });
  }

  // Cancel Button Action
  const cancelBtn = document.getElementById("course-cancel-btn");
  if (cancelBtn) {
    cancelBtn.addEventListener("click", () => {
      resetCourseForm();
    });
  }

  // Submit Course Form (Create / Update)
  const courseForm = document.getElementById("course-form");
  if (courseForm) {
    courseForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      
      const id = document.getElementById("course-edit-id").value;
      const code = document.getElementById("course-code").value.trim().toUpperCase();
      const name = document.getElementById("course-name").value.trim();
      const dept = document.getElementById("course-dept").value;
      const level = parseInt(document.getElementById("course-level").value, 10);
      const semester = document.getElementById("course-semester").value;

      try {
        if (id) {
          // Update
          const { error } = await supabase
            .from("courses")
            .update({
              course_code: code,
              course_name: name,
              department: dept,
              level: level,
              semester: semester
            })
            .eq("id", id);

          if (error) throw error;
          showToast(`Course "${code}" updated successfully!`, "success");
        } else {
          // Create
          const { error } = await supabase
            .from("courses")
            .insert([{
              course_code: code,
              course_name: name,
              department: dept,
              level: level,
              semester: semester
            }]);

          if (error) throw error;
          showToast(`Course "${code}" created successfully!`, "success");
        }

        resetCourseForm();
        fetchCoursesList();
      } catch (err) {
        showToast("Error saving course: " + err.message, "error");
      }
    });
  }
});
