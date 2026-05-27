-- Migration: Add is_pinned column to boards table
-- Created: 2026-05-25
-- Purpose: Enable pinning boards to the top of the group list

ALTER TABLE public.boards
ADD COLUMN is_pinned boolean NOT NULL DEFAULT false;

-- Create index for efficient sorting by is_pinned + created_at
CREATE INDEX boards_pinned_created_idx ON public.boards (is_pinned DESC, created_at DESC);
