
-- Day 28: Kanban Task Management System
-- Database Schema for Supabase PostgreSQL

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. User Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Boards
CREATE TABLE IF NOT EXISTS public.boards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 100),
    description TEXT,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Lists / Columns
CREATE TABLE IF NOT EXISTS public.lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    board_id UUID NOT NULL REFERENCES public.boards(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 100),
    position INTEGER NOT NULL DEFAULT 0 CHECK (position >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Tasks
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 1 AND 200),
    description TEXT,
    priority TEXT NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high')),
    status TEXT NOT NULL DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'done')),
    due_date DATE,
    position INTEGER NOT NULL DEFAULT 0 CHECK (position >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_boards_owner_id
    ON public.boards(owner_id);

CREATE INDEX IF NOT EXISTS idx_lists_board_id
    ON public.lists(board_id);

CREATE INDEX IF NOT EXISTS idx_tasks_list_id
    ON public.tasks(list_id);

CREATE INDEX IF NOT EXISTS idx_tasks_status
    ON public.tasks(status);

CREATE INDEX IF NOT EXISTS idx_tasks_priority
    ON public.tasks(priority);

-- Automatically create a profile for a new auth user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data ->> 'full_name'
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Create trigger only if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'on_auth_user_created'
          AND tgrelid = 'auth.users'::regclass
    ) THEN
        CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_new_user();
    END IF;
END;
$$;
