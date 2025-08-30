-- Script to add user_email column to group_members table
-- Run this script in your Supabase SQL editor

-- Add user_email column if it doesn't exist
ALTER TABLE public.group_members 
ADD COLUMN IF NOT EXISTS user_email TEXT;

-- Update existing records to populate user_email from auth.users
UPDATE public.group_members 
SET user_email = (
    SELECT email 
    FROM auth.users 
    WHERE auth.users.id = group_members.user_id
)
WHERE user_email IS NULL;

-- Make user_email NOT NULL after populating existing data
ALTER TABLE public.group_members 
ALTER COLUMN user_email SET NOT NULL;

-- Add unique constraint on group_id and user_email if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'group_members_group_id_user_email_key' 
        AND table_name = 'group_members'
    ) THEN
        ALTER TABLE public.group_members 
        ADD CONSTRAINT group_members_group_id_user_email_key 
        UNIQUE (group_id, user_email);
    END IF;
END $$;

-- Create index on user_email for better performance
CREATE INDEX IF NOT EXISTS idx_group_members_user_email 
ON public.group_members(user_email);
