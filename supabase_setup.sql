-- supabase_setup.sql
-- Run this script in the Supabase SQL Editor (Dashboard -> SQL Editor)

-- ==========================================
-- 1. Create Departments Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed initial departments (e.g. Software Engineering)
INSERT INTO public.departments (name) 
VALUES ('Software Engineering')
ON CONFLICT (name) DO NOTHING;

-- ==========================================
-- 2. Create Admins Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.admins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Note: Seed this table with your admin email:
-- INSERT INTO public.admins (email) VALUES ('your-admin-email@example.com') ON CONFLICT DO NOTHING;

-- ==========================================
-- 3. Configure Row Level Security (RLS)
-- ==========================================

-- Enable RLS on newly created tables
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- Departments Policies
CREATE POLICY "Allow public read access to departments" 
    ON public.departments FOR SELECT 
    USING (true);

CREATE POLICY "Allow admin write access to departments" 
    ON public.departments FOR ALL 
    USING (
        auth.jwt() ->> 'email' IN (SELECT email FROM public.admins)
    );

-- Admins Policies
CREATE POLICY "Allow authenticated read access to admins list" 
    ON public.admins FOR SELECT 
    USING (auth.role() = 'authenticated');

-- Configure/Extend RLS on existing courses and resources tables
-- Note: Enable RLS on courses and resources if not already enabled.
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- Courses Policies (Public read, admin write)
CREATE POLICY "Allow public read access to courses" 
    ON public.courses FOR SELECT 
    USING (true);

CREATE POLICY "Allow admin write access to courses" 
    ON public.courses FOR ALL 
    USING (
        auth.jwt() ->> 'email' IN (SELECT email FROM public.admins)
    );

-- Resources Policies (Public read approved, users insert, admin manage all)
CREATE POLICY "Allow public read access to approved resources" 
    ON public.resources FOR SELECT 
    USING (approval_status = 'approved');

CREATE POLICY "Allow users to upload pending resources" 
    ON public.resources FOR INSERT 
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow admin full access to resources" 
    ON public.resources FOR ALL 
    USING (
        auth.jwt() ->> 'email' IN (SELECT email FROM public.admins)
    );

-- ==========================================
-- 4. Seed Admin Placeholder User in public.users
-- ==========================================
-- This ensures that admin resource uploads (which reference uploader_firebase_uid = 'admin') 
-- do not violate foreign key constraints on public.users.
INSERT INTO public.users (firebase_uid, email, full_name, nickname, is_admin, department, level)
VALUES ('admin', 'admin@peernet.com', 'System Administrator', 'admin', true, 'Software Engineering', 500)
ON CONFLICT (firebase_uid) DO NOTHING;

