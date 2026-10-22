
-- Day 28: Row Level Security (RLS)
-- Kanban Task Management System

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- PROFILES: users can view and update their own profile
DROP POLICY IF EXISTS "Users can view own profile"
    ON public.profiles;
CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own profile"
    ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = (SELECT auth.uid()))
WITH CHECK (id = (SELECT auth.uid()));

-- BOARDS: users manage only their own boards
DROP POLICY IF EXISTS "Users can view own boards"
    ON public.boards;
CREATE POLICY "Users can view own boards"
ON public.boards
FOR SELECT
TO authenticated
USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own boards"
    ON public.boards;
CREATE POLICY "Users can create own boards"
ON public.boards
FOR INSERT
TO authenticated
WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own boards"
    ON public.boards;
CREATE POLICY "Users can update own boards"
ON public.boards
FOR UPDATE
TO authenticated
USING (owner_id = (SELECT auth.uid()))
WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own boards"
    ON public.boards;
CREATE POLICY "Users can delete own boards"
ON public.boards
FOR DELETE
TO authenticated
USING (owner_id = (SELECT auth.uid()));

-- LISTS: access only through boards owned by the user
DROP POLICY IF EXISTS "Users can view lists on own boards"
    ON public.lists;
CREATE POLICY "Users can view lists on own boards"
ON public.lists
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.boards b
        WHERE b.id = lists.board_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can create lists on own boards"
    ON public.lists;
CREATE POLICY "Users can create lists on own boards"
ON public.lists
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.boards b
        WHERE b.id = lists.board_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can update lists on own boards"
    ON public.lists;
CREATE POLICY "Users can update lists on own boards"
ON public.lists
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.boards b
        WHERE b.id = lists.board_id
          AND b.owner_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.boards b
        WHERE b.id = lists.board_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can delete lists on own boards"
    ON public.lists;
CREATE POLICY "Users can delete lists on own boards"
ON public.lists
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.boards b
        WHERE b.id = lists.board_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

-- TASKS: access only through lists on boards owned by the user
DROP POLICY IF EXISTS "Users can view tasks on own boards"
    ON public.tasks;
CREATE POLICY "Users can view tasks on own boards"
ON public.tasks
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.lists l
        JOIN public.boards b ON b.id = l.board_id
        WHERE l.id = tasks.list_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can create tasks on own boards"
    ON public.tasks;
CREATE POLICY "Users can create tasks on own boards"
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.lists l
        JOIN public.boards b ON b.id = l.board_id
        WHERE l.id = tasks.list_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can update tasks on own boards"
    ON public.tasks;
CREATE POLICY "Users can update tasks on own boards"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.lists l
        JOIN public.boards b ON b.id = l.board_id
        WHERE l.id = tasks.list_id
          AND b.owner_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.lists l
        JOIN public.boards b ON b.id = l.board_id
        WHERE l.id = tasks.list_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can delete tasks on own boards"
    ON public.tasks;
CREATE POLICY "Users can delete tasks on own boards"
ON public.tasks
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.lists l
        JOIN public.boards b ON b.id = l.board_id
        WHERE l.id = tasks.list_id
          AND b.owner_id = (SELECT auth.uid())
    )
);

-- Grant table access to authenticated users.
-- RLS policies still determine which rows they can access.
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.profiles, public.boards, public.lists, public.tasks
TO authenticated;
