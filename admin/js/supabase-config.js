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

  let displayMessage = message;
  if (type === 'error' && typeof message === 'string') {
    // Try to extract prefix if the message follows "Action Name: Technical Error details"
    const colonIndex = message.indexOf(':');
    if (colonIndex !== -1 && colonIndex < 40) { // check if colon is reasonably early (like prefix)
      const prefix = message.substring(0, colonIndex + 1).trim();
      const technicalPart = message.substring(colonIndex + 1).trim();
      displayMessage = getFriendlyErrorMessage(technicalPart, prefix);
    } else {
      displayMessage = getFriendlyErrorMessage(message);
    }
  }

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerText = displayMessage;

  container.appendChild(toast);

  // Auto remove after 4 seconds
  setTimeout(() => {
    toast.style.animation = 'slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) reverse forwards';
    setTimeout(() => {
      toast.remove();
    }, 300);
  }, 4000);
}

// Maps technical errors to clean user experience descriptions
function getFriendlyErrorMessage(err, prefix = "") {
  if (!err) return (prefix ? prefix + " " : "") + "An unexpected error occurred. Please try again.";
  
  // Log the original error for debugging in developers console
  console.warn("Original Technical Error:", err);

  const message = typeof err === 'string' ? err : (err.message || "");
  const code = err.code || "";
  
  let friendly = "";

  // PostgREST/PostgreSQL error codes mapping
  if (code) {
    switch (code) {
      case "23505":
        friendly = "This item already exists. Duplicate entries are not allowed.";
        break;
      case "23503":
        friendly = "This action could not be completed because a related database record (like a course, department, or user uploader) does not exist.";
        break;
      case "23502":
        friendly = "A required field was empty. Please fill out all required fields and try again.";
        break;
      case "42501":
        friendly = "Access denied. You do not have the required permissions to perform this action.";
        break;
      case "42P01":
        friendly = "Database table error. The requested resource table was not found.";
        break;
      case "28P01":
        friendly = "Database authentication failed. Access denied.";
        break;
    }
  }

  if (!friendly) {
    // Text matching for other standard error patterns
    const lowerMessage = message.toLowerCase();

    if (lowerMessage.includes("failed to fetch") || lowerMessage.includes("networkerror") || lowerMessage.includes("network error")) {
      friendly = "Network connection issue. Please check your internet connection and try again.";
    } else if (lowerMessage.includes("violates foreign key constraint")) {
      friendly = "This action could not be completed because it depends on a related record that is missing.";
    } else if (lowerMessage.includes("violates unique constraint")) {
      friendly = "This record already exists. Duplicate entries are not allowed.";
    } else if (lowerMessage.includes("violates row-level security policy") || lowerMessage.includes("violates row level security")) {
      friendly = "You do not have permission to modify or access this record.";
    } else if (lowerMessage.includes("invalid login credentials") || lowerMessage.includes("invalid credentials")) {
      friendly = "Invalid email address or password. Please verify your credentials.";
    } else if (lowerMessage.includes("email not confirmed")) {
      friendly = "Please confirm your email address before signing in.";
    } else if (lowerMessage.includes("user not found")) {
      friendly = "This user account does not exist.";
    } else if (lowerMessage.includes("bucket not found") || lowerMessage.includes("storage bucket")) {
      friendly = "Storage access error. The files bucket could not be found.";
    } else if (lowerMessage.includes("object not found")) {
      friendly = "The requested file or resource could not be found in storage.";
    } else if (lowerMessage.includes("already exists")) {
      friendly = "This item already exists.";
    } else {
      friendly = message || "An unexpected error occurred. Please try again.";
    }
  }

  if (prefix) {
    return `${prefix} ${friendly}`;
  }
  return friendly;
}

window.getFriendlyErrorMessage = getFriendlyErrorMessage;
