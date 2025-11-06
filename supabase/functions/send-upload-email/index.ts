import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 🔐 Environment variables
const SENDGRID_ADMIN_MAIL_KEY = Deno.env.get("SENDGRID_ADMIN_MAIL_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// 🧠 Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// 📩 Admin email & dashboard URL
const ADMIN_EMAIL = "demogit001@gmail.com";

// ⚙️ Direct dashboard link (corrected to avoid 404)
const SUPABASE_DASHBOARD_URL =
  "https://supabase.com/dashboard/project/tfgvpremvcqdoqknnzei/editor/20737?schema=public&loadFromCache=true";

serve(async (req) => {
  try {
    const body = await req.json();
    const record = body.record ?? body;
    const { uploader_firebase_uid, uploader, file_name, course_id } = record;

    // 🧩 Step 1: Fetch department & level from the courses table
    let department = "Unknown";
    let level = "Unknown";

    if (course_id) {
      const { data: courseData, error: courseError } = await supabase
        .from("courses")
        .select("department, level")
        .eq("id", course_id)
        .single();

      if (courseError) {
        console.error("⚠️ Could not fetch course details:", courseError.message);
      } else if (courseData) {
        department = courseData.department ?? "N/A";
        level = courseData.level ?? "N/A";
      }
    }

    // 🧩 Step 2: Construct professional email content
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; background-color: #f6f9fc; padding: 20px;">
        <div style="max-width: 600px; margin: auto; background: white; border-radius: 10px; padding: 20px; box-shadow: 0 2px 6px rgba(0,0,0,0.1);">
          <h2 style="color: #2f855a;">📢 New Upload Pending Approval</h2>
          <p>A new resource has been uploaded and is awaiting your review.</p>
          <hr style="margin: 16px 0;" />
          <p><strong>Uploader UID:</strong> ${uploader_firebase_uid ?? uploader ?? "Unknown"}</p>
          <p><strong>File Name:</strong> ${file_name}</p>
          <p><strong>Department:</strong> ${department}</p>
          <p><strong>Level:</strong> ${level}</p>
          <p><strong>Course ID:</strong> ${course_id}</p>
          <hr style="margin: 16px 0;" />
          <a href="${SUPABASE_DASHBOARD_URL}" 
             style="display: inline-block; background-color: #2b6cb0; color: white; padding: 12px 20px; 
             border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 15px;">
            🔗 Open in Dashboard
          </a>
          <p style="margin-top: 20px; color: #718096; font-size: 14px;">
            This is an automated notification from <strong>PeerNet</strong>.<br />
            Please log in to review the uploaded resource.
          </p>
        </div>
      </div>
    `;

    // 🧩 Step 3: Send via SendGrid
    const message = {
      personalizations: [
        {
          to: [{ email: ADMIN_EMAIL }],
          subject: `📢 New Upload Pending Approval: ${file_name}`,
        },
      ],
      // 💡 Use a custom domain or verified sender if available
      from: { email: "demogit001@gmail.com", name: "PeerNet Notifications" },
      reply_to: { email: "demogit001@gmail.com", name: "PeerNet Support" },
      content: [{ type: "text/html", value: htmlContent }],
      headers: {
        "List-Unsubscribe": "<mailto:demogit001@gmail.com>, <https://peernet.app/unsubscribe>",
      },
    };

    const res = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SENDGRID_ADMIN_MAIL_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    if (!res.ok) {
      const error = await res.text();
      console.error("❌ SendGrid Error:", error);
      return new Response("Failed to send email", { status: 500 });
    }

    console.log("✅ Email sent to admin successfully.");
    return new Response("Email sent to admin ✅", { status: 200 });

  } catch (error) {
    console.error("❌ Error processing request:", error);
    return new Response("Error processing request", { status: 500 });
  }
});
