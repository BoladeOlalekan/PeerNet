// admin/js/supabase-config.js

const SUPABASE_URL = "https://tfgvpremvcqdoqknnzei.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmZ3ZwcmVtdmNxZG9xa25uemVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2NDUxOTAsImV4cCI6MjA3NDIyMTE5MH0.IittDAW_ugbyKZMXcWo9VFDqiUdnOiLPFj7orb591Oc";

// Initialize Supabase Client using a non-conflicting variable name
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
window.supabaseClient = supabaseClient;

// Helper function to show notifications
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerText = message;

  container.appendChild(toast);

  // Auto remove after 4 seconds
  setTimeout(() => {
    toast.style.animation = 'slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) reverse forwards';
    setTimeout(() => {
      toast.remove();
    }, 300);
  }, 4000);
}
