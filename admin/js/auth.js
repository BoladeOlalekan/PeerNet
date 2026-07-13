// admin/js/auth.js

document.addEventListener("DOMContentLoaded", async () => {
  const loginForm = document.getElementById("login-form");
  const submitBtn = document.getElementById("submit-btn");

  // If on login page, check if already logged in and redirect to dashboard
  if (window.location.pathname.endsWith("index.html") || window.location.pathname.endsWith("/") || window.location.pathname === "") {
    const { data: { session } } = await supabase.auth.getSession();
    if (session) {
      // Verify if email is admin
      const isAdmin = await checkIsAdmin(session.user.email);
      if (isAdmin) {
        window.location.href = "dashboard.html";
        return;
      }
    }
  }

  // Handle Login Form Submission
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
        // Sign in via Supabase Auth
        const { data, error } = await supabase.auth.signInWithPassword({
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
          await supabase.auth.signOut();
          throw new Error("Access denied. You are not registered as an administrator.");
        }
      } catch (err) {
        showToast(err.message || "Authentication failed. Please check your credentials.", "error");
        
        // Reset button state
        submitBtn.disabled = false;
        btnText.classList.remove("hidden");
        btnLoader.classList.add("hidden");
      }
    });
  }
});

// Helper function to check if email exists in public.admins table
async function checkIsAdmin(email) {
  try {
    const { data, error } = await supabase
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
