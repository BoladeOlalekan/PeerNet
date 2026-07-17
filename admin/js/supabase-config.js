// admin/js/supabase-config.js

// Beautiful configuration setup overlay
function showConfigErrorOverlay(technicalDetail = "") {
  if (document.getElementById('config-error-overlay')) return;

  const overlay = document.createElement('div');
  overlay.id = 'config-error-overlay';
  overlay.style.position = 'fixed';
  overlay.style.top = '0';
  overlay.style.left = '0';
  overlay.style.width = '100vw';
  overlay.style.height = '100vh';
  overlay.style.backgroundColor = 'rgba(15, 23, 42, 0.96)';
  overlay.style.display = 'flex';
  overlay.style.justifyContent = 'center';
  overlay.style.alignItems = 'center';
  overlay.style.zIndex = '999999';
  overlay.style.fontFamily = 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  overlay.style.color = '#f8fafc';
  overlay.style.padding = '20px';

  overlay.innerHTML = `
    <div style="background: rgba(30, 41, 59, 0.7); border: 1px solid rgba(255, 255, 255, 0.08); backdrop-filter: blur(16px); padding: 40px; border-radius: 24px; max-width: 550px; width: 100%; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); text-align: center; box-sizing: border-box;">
      <div style="width: 80px; height: 80px; background: rgba(239, 68, 68, 0.08); border: 2px solid rgba(239, 68, 68, 0.3); border-radius: 50%; display: flex; justify-content: center; align-items: center; margin: 0 auto 24px; box-shadow: 0 0 20px rgba(239, 68, 68, 0.15);">
        <svg style="width: 40px; height: 40px; color: #ef4444;" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
        </svg>
      </div>

      <h2 style="font-size: 24px; font-weight: 700; margin: 0 0 12px; color: #ffffff; letter-spacing: -0.025em;">Configuration Required</h2>
      <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0 0 28px;">
        The admin panel configuration file (<code style="font-family: monospace; color: #f472b6;">admin/js/config.js</code>) is missing, incomplete, or failed to load. Please set up your local secrets to run the admin portal.
      </p>

      <div style="text-align: left; background: rgba(15, 23, 42, 0.4); border-radius: 14px; padding: 20px; border: 1px solid rgba(255, 255, 255, 0.05); margin-bottom: 24px; box-sizing: border-box;">
        <h4 style="font-size: 12px; text-transform: uppercase; color: #38bdf8; font-weight: 600; margin: 0 0 12px; letter-spacing: 0.05em;">Setup Steps:</h4>
        <ol style="margin: 0; padding-left: 20px; color: #cbd5e1; font-size: 13px; line-height: 1.8;">
          <li style="margin-bottom: 8px;">Locate the file <code style="font-family: monospace; color: #38bdf8; background: rgba(56, 189, 248, 0.08); padding: 2px 6px; border-radius: 4px;">admin/js/config.example.js</code>.</li>
          <li style="margin-bottom: 8px;">Duplicate and rename it to <code style="font-family: monospace; color: #38bdf8; background: rgba(56, 189, 248, 0.08); padding: 2px 6px; border-radius: 4px;">config.js</code> inside the same folder.</li>
          <li style="margin-bottom: 8px;">Open <code style="font-family: monospace; color: #cbd5e1;">config.js</code> and enter your Supabase URL and Anon Key.</li>
          <li>Save the file and refresh this page.</li>
        </ol>
      </div>

      ${technicalDetail ? `
      <details style="text-align: left; margin-bottom: 24px; cursor: pointer;">
        <summary style="font-size: 11px; color: #64748b; font-weight: 600; outline: none; user-select: none;">Show Technical Details</summary>
        <pre style="background: rgba(0, 0, 0, 0.25); border-radius: 8px; padding: 12px; border: 1px solid rgba(239, 68, 68, 0.15); color: #ef4444; font-family: monospace; font-size: 11px; margin-top: 8px; overflow-x: auto; white-space: pre-wrap; word-break: break-all; max-height: 100px;">${technicalDetail}</pre>
      </details>
      ` : ''}

      <button onclick="window.location.reload()" style="background: #38bdf8; color: #0f172a; border: none; font-size: 14px; font-weight: 600; padding: 12px 24px; border-radius: 8px; cursor: pointer; transition: all 0.2s ease; width: 100%; box-shadow: 0 4px 14px rgba(56, 189, 248, 0.25);">
        Reload Page
      </button>
    </div>
  `;

  // Use DOMContentLoaded or direct append depending on page readiness
  if (document.body) {
    document.body.appendChild(overlay);
  } else {
    document.addEventListener("DOMContentLoaded", () => document.body.appendChild(overlay));
  }
}

// Safely initialize Supabase Client and create proxy fallback
let supabaseClient = null;
let initError = "";

if (typeof CONFIG === 'undefined' || !CONFIG.SUPABASE_URL || !CONFIG.SUPABASE_ANON_KEY) {
  initError = "Configuration object 'CONFIG' is not defined or is missing keys.";
} else {
  try {
    supabaseClient = window.supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
    window.supabaseClient = supabaseClient;
  } catch (err) {
    initError = err.message || err;
  }
}

if (initError || !supabaseClient) {
  console.error("Configuration Error:", initError);
  showConfigErrorOverlay(initError);
  
  // Set up mock client proxy to prevent ReferenceError/Null pointer crashes in other dashboard scripts
  const mockClient = {
    auth: {
      getSession: () => Promise.resolve({ data: { session: null }, error: null }),
      getUser: () => Promise.resolve({ data: { user: null }, error: null }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } })
    },
    from: () => ({
      select: () => ({
        eq: () => ({
          order: () => Promise.resolve({ data: [], error: null }),
          single: () => Promise.resolve({ data: null, error: null }),
          eq: () => Promise.resolve({ data: [], error: null })
        }),
        order: () => Promise.resolve({ data: [], error: null }),
        single: () => Promise.resolve({ data: null, error: null })
      }),
      insert: () => Promise.resolve({ data: null, error: null }),
      update: () => Promise.resolve({ data: null, error: null }),
      delete: () => Promise.resolve({ data: null, error: null })
    }),
    storage: {
      from: () => ({
        upload: () => Promise.resolve({ data: null, error: null }),
        getPublicUrl: () => ({ data: { publicUrl: "" } })
      })
    }
  };

  supabaseClient = mockClient;
  window.supabaseClient = mockClient;
}

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
