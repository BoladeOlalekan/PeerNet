// admin/js/departments.js

// Fetch departments and display them in a list
async function fetchDepartments() {
  const listElement = document.getElementById("departments-list");
  if (!listElement) return;

  listElement.innerHTML = `
    <tr>
      <td colspan="2" style="text-align: center; color: var(--text-muted);">
        <div class="btn-loader" style="margin: 20px auto;"></div>
        Loading departments...
      </td>
    </tr>
  `;

  try {
    const { data, error } = await supabaseClient
      .from("departments")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;

    if (!data || data.length === 0) {
      listElement.innerHTML = `
        <tr>
          <td colspan="2" style="text-align: center; color: var(--text-muted); padding: 20px;">
            No departments found. Add one below.
          </td>
        </tr>
      `;
      return;
    }

    listElement.innerHTML = "";
    data.forEach((dept) => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td style="font-weight: 500;">${dept.name}</td>
        <td style="text-align: right;">
          <button class="action-btn btn-delete-item" onclick="confirmDeleteDept('${dept.id}', '${dept.name}')">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="18" height="18">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </td>
      `;
      listElement.appendChild(row);
    });
  } catch (err) {
    showToast("Error loading departments: " + err.message, "error");
    listElement.innerHTML = `
      <tr>
        <td colspan="2" style="text-align: center; color: var(--danger); padding: 20px;">
          Failed to load departments.
        </td>
      </tr>
    `;
  }
}

// Add Department Form
document.addEventListener("DOMContentLoaded", () => {
  const addDeptForm = document.getElementById("add-dept-form");
  if (addDeptForm) {
    addDeptForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const nameInput = document.getElementById("new-dept-name");
      const name = nameInput.value.trim();

      if (!name) return;

      try {
        const { error } = await supabaseClient
          .from("departments")
          .insert([{ name }]);

        if (error) throw error;

        showToast(`Department "${name}" added successfully!`, "success");
        nameInput.value = "";
        
        // Refresh department list
        fetchDepartments();
        // Load into dropdowns
        loadDepartmentsIntoDropdowns();
      } catch (err) {
        showToast("Error adding department: " + err.message, "error");
      }
    });
  }
});

// Delete Department Action
function confirmDeleteDept(id, name) {
  showConfirmModal({
    title: "Delete Department?",
    message: `Are you sure you want to delete the department "${name}"? This could affect existing courses and users under this department.`,
    isDanger: true,
    onConfirm: async () => {
      try {
        const { error } = await supabaseClient
          .from("departments")
          .delete()
          .eq("id", id);

        if (error) throw error;

        showToast(`Department "${name}" deleted!`, "success");
        fetchDepartments();
        loadDepartmentsIntoDropdowns();
      } catch (err) {
        showToast("Error deleting department: " + err.message, "error");
      }
    }
  });
}

// Global helper to populate departments select/filter elements
async function loadDepartmentsIntoDropdowns() {
  try {
    const { data: departments, error } = await supabaseClient
      .from("departments")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;

    // Dropdown list in All Resources filter
    const filterDept = document.getElementById("resource-filter-dept");
    if (filterDept) {
      const currentValue = filterDept.value;
      filterDept.innerHTML = `<option value="all">All Departments</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        filterDept.appendChild(opt);
      });
      filterDept.value = currentValue;
    }

    // Dropdown in Admin Upload form
    const uploadDept = document.getElementById("upload-dept");
    if (uploadDept) {
      const currentValue = uploadDept.value;
      uploadDept.innerHTML = `<option value="" disabled selected>Select Department</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        uploadDept.appendChild(opt);
      });
      uploadDept.value = currentValue;
    }

    // Dropdown in Course Form
    const courseDept = document.getElementById("course-dept");
    if (courseDept) {
      const currentValue = courseDept.value;
      courseDept.innerHTML = `<option value="" disabled selected>Select Department</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        courseDept.appendChild(opt);
      });
      courseDept.value = currentValue;
    }

    // Dropdown in Courses List filter
    const courseListFilterDept = document.getElementById("course-list-filter-dept");
    if (courseListFilterDept) {
      const currentValue = courseListFilterDept.value;
      courseListFilterDept.innerHTML = `<option value="all">All Departments</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        courseListFilterDept.appendChild(opt);
      });
      courseListFilterDept.value = currentValue;
    }

    // Dropdown in Mass Upload form
    const massUploadDept = document.getElementById("mass-upload-dept");
    if (massUploadDept) {
      const currentValue = massUploadDept.value;
      massUploadDept.innerHTML = `<option value="" disabled selected>Select Department</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        massUploadDept.appendChild(opt);
      });
      massUploadDept.value = currentValue;
    }

    // Dropdown in Users filter
    const usersFilterDept = document.getElementById("users-filter-dept");
    if (usersFilterDept) {
      const currentValue = usersFilterDept.value;
      usersFilterDept.innerHTML = `<option value="all">All Departments</option>`;
      departments.forEach(dept => {
        const opt = document.createElement("option");
        opt.value = dept.name;
        opt.innerText = dept.name;
        usersFilterDept.appendChild(opt);
      });
      usersFilterDept.value = currentValue;
    }

  } catch (err) {
    console.error("Failed to populate department dropdowns:", err);
  }
}
