// admin/js/auth.js

document.addEventListener("DOMContentLoaded", () => {
  const loginForm = document.getElementById("login-form");
  const submitBtn = document.getElementById("submit-btn");

  // ALWAYS register the form submission handler first!
  // This guarantees that e.preventDefault() is called and prevents page reload/clear.
  if (loginForm) {
    loginForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      
      const email = document.getElementById("email").value.trim();
      const password = document.getElementById("password").value;
      
      const btnText = submitBtn.querySelector(".btn-text");
      const btnLoader = submitBtn.querySelector(".btn-loader");

      // Show Loading state
      submitBtn.disabled = true;
      btnText.classList.add("hidden");
      btnLoader.classList.remove("hidden");

      try {
        if (typeof supabaseClient === 'undefined' || !supabaseClient.auth) {
          throw new Error("Supabase is not initialized. Please check your internet connection and console logs.");
        }

        // Sign in via Supabase Auth
        const { data, error } = await supabaseClient.auth.signInWithPassword({
          email,
          password
        });

        if (error) throw error;

        // Verify if user is an approved admin in the 'admins' table
        const isAdmin = await checkIsAdmin(data.user.email);
        
        if (isAdmin) {
          showToast("Login successful! Redirecting...", "success");
          setTimeout(() => {
            window.location.href = "dashboard.html";
          }, 1000);
        } else {
          // If authenticated but not in the admins table, sign out
          await supabaseClient.auth.signOut();
          throw new Error("Access denied. You are not registered as an administrator in the database.");
        }
      } catch (err) {
        console.error("Login Error:", err);
        showToast(err.message || "Authentication failed. Please check your credentials.", "error");
        
        // Reset button state
        submitBtn.disabled = false;
        btnText.classList.remove("hidden");
        btnLoader.classList.add("hidden");
      }
    });
  }

  // Toggle password visibility
  const togglePasswordBtn = document.getElementById("toggle-password");
  const passwordInput = document.getElementById("password");
  const eyeIcon = document.getElementById("eye-icon");
  const eyeSlashIcon = document.getElementById("eye-slash-icon");

  if (togglePasswordBtn && passwordInput) {
    togglePasswordBtn.addEventListener("click", () => {
      const type = passwordInput.getAttribute("type") === "password" ? "text" : "password";
      passwordInput.setAttribute("type", type);
      
      if (type === "password") {
        eyeIcon.classList.remove("hidden");
        eyeSlashIcon.classList.add("hidden");
      } else {
        eyeIcon.classList.add("hidden");
        eyeSlashIcon.classList.remove("hidden");
      }
    });
  }

  // Safe auto-redirect check
  async function checkSessionAndRedirect() {
    try {
      if (typeof supabaseClient !== 'undefined' && supabaseClient.auth) {
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (session) {
          // Verify if email is admin
          const isAdmin = await checkIsAdmin(session.user.email);
          if (isAdmin) {
            window.location.href = "dashboard.html";
          }
        }
      }
    } catch (e) {
      console.error("Error during auto-redirect check:", e);
    }
  }

  // Check path and redirect
  const path = window.location.pathname;
  if (path.endsWith("index.html") || path.endsWith("/") || path === "") {
    checkSessionAndRedirect();
  }
});

// Helper function to check if email exists in public.admins table
async function checkIsAdmin(email) {
  try {
    const { data, error } = await supabaseClient
      .from("admins")
      .select("email")
      .eq("email", email)
      .maybeSingle();

    if (error) {
      console.error("Error querying admins table:", error);
      return false;
    }
    return data !== null;
  } catch (e) {
    console.error("Exception checking admin status:", e);
    return false;
  }
}
