const functions = require("firebase-functions");
const {createClient} = require("@supabase/supabase-js");

const supabase = createClient(
    functions.config().supabase.url,
    functions.config().supabase.service_key,
    {auth: {persistSession: false}},
);

// 1) Create shadow user in Supabase when a Firebase user is created
exports.onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const email = user.email || "";
  const firebase_uid = user.uid;

  const {error} = await supabase
      .from("users")
      .insert({
        firebase_uid,
        email,
        department: "UNSET",
        level: 0,
      });

  if (error) {
    console.error("Supabase insert error:", error);
  } else {
    console.log("Shadow user created in Supabase for:", firebase_uid);
  }
});

// 2) Callable function to update profile (department, level, etc.)
exports.updateUserProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }
  const firebase_uid = context.auth.uid;
  const {department, level, full_name, nickname, avatar_url, is_admin} = data;

  if (!department || !level) {
    throw new functions.https.HttpsError("invalid-argument", "department and level are required");
  }

  const {error} = await supabase
      .from("users")
      .upsert({
        firebase_uid,
        email: context.auth.token.email,
        full_name,
        nickname,
        avatar_url,
        department,
        level,
        is_admin: !!is_admin,
        updated_at: new Date().toISOString(),
      }, {onConflict: "firebase_uid"});

  if (error) {
    console.error("Supabase upsert error:", error);
    throw new functions.https.HttpsError("internal", "Failed to update profile");
  }
  return {ok: true};
});

// 3) Callable to create resource metadata after file upload
exports.createResourceMetadata = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Login required.");
  const firebase_uid = context.auth.uid;

  const {
    course_id,
    storage_path,
    mime_type,
    size_bytes,
    file_type, // 'note' | 'video' | 'past_question'
  } = data;

  if (!course_id || !storage_path || !file_type) {
    throw new functions.https.HttpsError("invalid-argument", "Missing fields");
  }

  const {error} = await supabase.from("resources").insert({
    course_id,
    uploader_firebase_uid: firebase_uid,
    storage_path,
    mime_type,
    size_bytes,
    file_type,
    approval_status: "pending",
  });

  if (error) {
    console.error("Supabase insert error:", error);
    throw new functions.https.HttpsError("internal", "Failed to create resource");
  }

  return {ok: true};
});
