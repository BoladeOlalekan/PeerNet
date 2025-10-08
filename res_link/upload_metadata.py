import os
from supabase import create_client, Client

# --- CONFIGURE YOUR PROJECT ---
SUPABASE_URL = "https://tfgvpremvcqdoqknnzei.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmZ3ZwcmVtdmNxZG9xa25uemVpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODY0NTE5MCwiZXhwIjoyMDc0MjIxMTkwfQ.JR47DMskgPmJ0PM5zlUJoN6gutRy3D2YRZSELTriRLU"
BUCKET_NAME = "resources"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- YOUR RESOURCE SETTINGS ---
DEPARTMENT = "Software Engineering"
LEVEL = 400
SEMESTER = "First"
UPLOADER_FIREBASE_UID = "zEBOcTZ1tkXafYZpryXBuSj9VEq1"

def list_files(path_prefix=""):
    """Recursively list all files in the bucket"""
    files = []
    print ("Scanning:", path_prefix)
    items = supabase.storage.from_(BUCKET_NAME).list(path_prefix)
    for item in items:
        item_name = item["name"]
        full_path = f"{path_prefix}/{item_name}" if path_prefix else item_name
        if item["metadata"] is None:
            files.extend(list_files(full_path))
        else:
            if full_path.endswith(".pdf"):
                files.append(full_path)
    return files


def get_course_id(course_code):
    """Fetch course_id from the courses table by course code"""
    result = (
        supabase.table("courses")
        .select("id")
        .eq("course_code", course_code)
        .eq("department", DEPARTMENT)
        .eq("level", LEVEL)
        .eq("semester", SEMESTER)
        .limit(1)
        .execute()
    )
    data = result.data
    return data[0]["id"] if data else None


def insert_metadata(files):
    # Map folder names to ENUM values
    file_type_mapping = {
        "notes": "note",
        "note": "note",
        "videos": "video",
        "video": "video",
        "past_questions": "past_question",
        "past_question": "past_question",
        
    }

    for file_path in files:
        parts = file_path.split("/")

        # Expected: dept/level/semester/course/file_type/file.pdf
        if len(parts) < 7:
            print(f"⚠️  Skipping {file_path}: invalid path structure.")
            continue

        course_code = parts[4].strip()
        file_type_folder = parts[5].strip().lower()
        file_type = file_type_mapping.get(file_type_folder, "note")  # default to 'note'
        file_name = parts[-1]

        course_id = get_course_id(course_code)
        if not course_id:
            print(f"⚠️  Skipping {file_name}: Course {course_code} not found in courses table.")
            continue

        # Insert resource metadata
        data = {
            "course_id": course_id,
            "uploader_firebase_uid": UPLOADER_FIREBASE_UID,
            "storage_path": file_path,
            "mime_type": "application/pdf",
            "size_bytes": 0,  # optional, if you want to fill it later
            "file_type": file_type,
            "approval_status": "approved",
        }

        print(f"✅ Linking {file_name} → {course_code} ({file_type})")
        supabase.table("resources").insert(data).execute()


if __name__ == "__main__":
    pdf_files = list_files("resources")
    print(f"Found {len(pdf_files)} PDF files.")
    insert_metadata(pdf_files)
    print("✅ All metadata inserted successfully!")
