import { serve } from "https://deno.land/std/http/server.ts";

serve(async (req) => {
  try {
    const { email, otp } = await req.json();

    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("SENDGRID_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [
          {
            to: [{ email }],
            subject: "Your OTP Code",
          },
        ],
        from: { 
          email: "demogit001@gmail.com", 
          name: "PeerNet" 
        }, 
        content: [
          {
            type: "text/plain",
            value: `Your 6-digit OTP is ${otp}.`,
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("SendGrid error:", errorText);
      return new Response("Failed to send OTP", { status: 500 });
    }
    return new Response("OTP sent successfully", { status: 200 });
  } catch (err) {
      console.error("Function error:", err.message);
      return new Response("Internal Server Error", { status: 500 });
    }
});
