-- Add class_code column to classes table
ALTER TABLE classes ADD COLUMN IF NOT EXISTS class_code TEXT;
