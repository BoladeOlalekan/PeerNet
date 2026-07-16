// admin/js/users.js

let allUsers = [];

// ==========================================
// 1. FETCH & FILTER USERS
// ==========================================
async function fetchUsersList() {
  const tableBody = document.getElementById("users-table-body");
  const userCountBadge = document.getElementById("users-count-badge");
  
  if (!tableBody) return;

  tableBody.innerHTML = `
    <tr>
      <td colspan="6" style="text-align: center; color: var(--text-muted);">
        <div class="btn-loader" style="margin: 20px auto;"></div>
        Loading users...
      </td>
    </tr>
  `;

  try {
    const { data: users, error } = await supabaseClient
      .from("users")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    allUsers = users || [];
    renderUsersTable();
  } catch (err) {
    showToast("Failed to load users: " + err.message, "error");
    tableBody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align: center; color: var(--danger); font-weight: 500;">
          Failed to load users. Please refresh.
        </td>
      </tr>
    `;
  }
}

function renderUsersTable() {
  const tableBody = document.getElementById("users-table-body");
  const userCountBadge = document.getElementById("users-count-badge");
  
  const searchVal = document.getElementById("users-search")?.value.toLowerCase().trim() || "";
  const deptVal = document.getElementById("users-filter-dept")?.value || "all";
  const levelVal = document.getElementById("users-filter-level")?.value || "all";

  // Filter users list
  const filtered = allUsers.filter(user => {
    const name = (user.full_name || "").toLowerCase();
    const email = (user.email || "").toLowerCase();
    const nickname = (user.nickname || "").toLowerCase();
    const matchesSearch = name.includes(searchVal) || email.includes(searchVal) || nickname.includes(searchVal);

    const matchesDept = deptVal === "all" || user.department === deptVal;
    
    const userLevelStr = user.level ? user.level.toString() : "";
    const matchesLevel = levelVal === "all" || userLevelStr === levelVal;

    return matchesSearch && matchesDept && matchesLevel;
  });

  // Update badge count
  if (userCountBadge) {
    userCountBadge.innerText = filtered.length;
  }

  if (filtered.length === 0) {
    tableBody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px 20px;">
          No users found matching the search/filter criteria.
        </td>
      </tr>
    `;
    return;
  }

  let html = "";
  filtered.forEach(user => {
    const initials = (user.full_name || user.email || "??").substring(0, 2).toUpperCase();
    const avatarUrl = user.avatar_url || user.image_url;
    const avatarHtml = avatarUrl 
      ? `<img src="${avatarUrl}" class="w-9 h-9 rounded-full object-cover border border-slate-100" onerror="this.outerHTML='<div class=\'w-9 h-9 rounded-full bg-emerald-50 text-emerald-700 font-bold text-xs flex items-center justify-center\'>${initials}</div>'">`
      : `<div class="w-9 h-9 rounded-full bg-emerald-50 text-emerald-700 font-bold text-xs flex items-center justify-center">${initials}</div>`;

    const joinedDate = user.created_at ? new Date(user.created_at).toLocaleDateString(undefined, {
      year: 'numeric', month: 'short', day: 'numeric'
    }) : '—';

    html += `
      <tr>
        <td class="px-4 py-3">
          <div class="flex items-center gap-3">
            ${avatarHtml}
            <div>
              <div class="font-semibold text-slate-800">${user.full_name || 'No Name'}</div>
              <div class="text-xs text-slate-400">@${user.nickname || 'nickname'}</div>
            </div>
          </div>
        </td>
        <td class="px-4 py-3 text-slate-600">${user.email}</td>
        <td class="px-4 py-3">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
            ${user.department || 'General'}
          </span>
        </td>
        <td class="px-4 py-3 text-slate-600">${user.level ? user.level + ' L' : '—'}</td>
        <td class="px-4 py-3 text-slate-400">${joinedDate}</td>
        <td class="px-4 py-3 text-right">
          <div class="flex justify-end gap-2">
            <button onclick="viewUserDetails('${user.firebase_uid}')" 
              class="p-2 hover:bg-slate-50 text-slate-600 hover:text-slate-900 rounded-lg transition-colors cursor-pointer" title="View Details">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </button>
            <button onclick="confirmDeleteUser('${user.firebase_uid}', '${user.full_name || user.email}')" 
              class="p-2 hover:bg-red-50 text-red-500 hover:text-red-700 rounded-lg transition-colors cursor-pointer" title="Delete User">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
              </svg>
            </button>
          </div>
        </td>
      </tr>
    `;
  });

  tableBody.innerHTML = html;
}

// ==========================================
// 2. VIEW DETAILS MODAL
// ==========================================
function viewUserDetails(uid) {
  const user = allUsers.find(u => u.firebase_uid === uid);
  if (!user) return;

  const modal = document.getElementById("user-details-modal");
  const modalContent = document.getElementById("user-details-modal-content");
  
  if (!modal || !modalContent) return;

  const initials = (user.full_name || user.email || "??").substring(0, 2).toUpperCase();
  const avatarUrl = user.avatar_url || user.image_url;
  const avatarHtml = avatarUrl 
    ? `<img src="${avatarUrl}" class="w-20 h-20 rounded-2xl object-cover border border-slate-100 shadow-sm" onerror="this.outerHTML='<div class=\'w-20 h-20 rounded-2xl bg-emerald-50 text-emerald-700 font-bold text-xl flex items-center justify-center\'>${initials}</div>'">`
    : `<div class="w-20 h-20 rounded-2xl bg-emerald-50 text-emerald-700 font-bold text-xl flex items-center justify-center shadow-sm">${initials}</div>`;

  const createdDate = user.created_at ? new Date(user.created_at).toLocaleString() : '—';
  const updatedDate = user.updated_at ? new Date(user.updated_at).toLocaleString() : '—';

  modalContent.innerHTML = `
    <div class="flex items-start gap-5 pb-6 border-b border-slate-100">
      ${avatarHtml}
      <div class="space-y-1 min-w-0">
        <h4 class="text-xl font-bold text-slate-800 truncate">${user.full_name || 'No Name'}</h4>
        <p class="text-sm text-slate-400">@${user.nickname || 'nickname'}</p>
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${user.is_admin ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-slate-100 text-slate-800'}">
          ${user.is_admin ? 'ADMIN' : 'USER'}
        </span>
      </div>
    </div>

    <div class="py-6 grid grid-cols-1 md:grid-cols-2 gap-5 text-sm">
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Email Address</span>
        <span class="text-slate-800 font-semibold break-all">${user.email}</span>
      </div>
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Firebase UID</span>
        <span class="text-slate-600 font-mono text-xs break-all">${user.firebase_uid}</span>
      </div>
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Department</span>
        <span class="text-slate-800 font-semibold">${user.department || 'General'}</span>
      </div>
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Academic Level</span>
        <span class="text-slate-800 font-semibold">${user.level ? user.level + ' Level' : '—'}</span>
      </div>
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Registered On</span>
        <span class="text-slate-600">${createdDate}</span>
      </div>
      <div class="space-y-1">
        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Last Updated</span>
        <span class="text-slate-600">${updatedDate}</span>
      </div>
    </div>
  `;

  modal.classList.remove("hidden");
}

function closeUserDetailsModal() {
  const modal = document.getElementById("user-details-modal");
  if (modal) modal.classList.add("hidden");
}

// ==========================================
// 3. DELETE USER
// ==========================================
function confirmDeleteUser(uid, name) {
  showConfirmModal({
    title: "Delete User Account",
    message: `Are you sure you want to permanently delete user \"${name}\"? This action will remove their database record and attempt to delete their Firebase Authentication account. This is irreversible.`,
    isDanger: true,
    onConfirm: async () => {
      try {
        // Try invoking the edge function first
        const { data, error } = await supabaseClient.functions.invoke("delete-user", {
          body: { firebaseUid: uid }
        });

        if (error) {
          // Fallback if edge function doesn't exist
          console.warn("Edge function failed or doesn't exist. Falling back to direct database delete.", error);
          const { error: dbError } = await supabaseClient
            .from("users")
            .delete()
            .eq("firebase_uid", uid);

          if (dbError) throw dbError;
          showToast(`Deleted profile for ${name} (Firebase Auth deletion skipped).`, "warning");
        } else {
          if (data.firebaseDeleted) {
            showToast(`Successfully deleted ${name} from Database and Firebase Auth.`, "success");
          } else {
            showToast(`Deleted profile from DB. Firebase Auth deletion skipped/failed: ${data.firebaseError || 'Service Account not set'}`, "warning");
          }
        }
        
        fetchUsersList();
      } catch (err) {
        showToast("Error deleting user: " + err.message, "error");
      }
    }
  });
}

// ==========================================
// 4. EVENT BINDINGS
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  const searchInput = document.getElementById("users-search");
  const filterDept = document.getElementById("users-filter-dept");
  const filterLevel = document.getElementById("users-filter-level");
  const refreshBtn = document.getElementById("users-refresh-btn");
  const modalCloseBtn = document.getElementById("user-details-modal-close");

  if (searchInput) {
    searchInput.addEventListener("input", renderUsersTable);
  }
  if (filterDept) {
    filterDept.addEventListener("change", renderUsersTable);
  }
  if (filterLevel) {
    filterLevel.addEventListener("change", renderUsersTable);
  }
  if (refreshBtn) {
    refreshBtn.addEventListener("click", fetchUsersList);
  }
  if (modalCloseBtn) {
    modalCloseBtn.addEventListener("click", closeUserDetailsModal);
  }

  // Close modal when clicking outside card
  const modal = document.getElementById("user-details-modal");
  if (modal) {
    modal.addEventListener("click", (e) => {
      if (e.target === modal) closeUserDetailsModal();
    });
  }
});
