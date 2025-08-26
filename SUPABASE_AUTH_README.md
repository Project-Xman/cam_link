# Supabase Authentication Setup

This document explains how to set up and use Supabase authentication in the Photo Uploader app.

## Database Schema

The app uses a `camlink.users` table with the following structure:

```sql
create table if not exists camlink.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  full_name text not null,
  approved boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);
```

## Key Features

1. **Email/Password Authentication**: Users can sign up and sign in with email and password
2. **Admin Approval Workflow**: New users require admin approval before they can use the app
3. **Password Reset**: Users can reset their password via email
4. **Automatic User Creation**: A trigger function automatically creates user records when they sign up

## Setup Instructions

1. Create a Supabase project at https://supabase.io
2. Update the Supabase URL and anon key in [main.dart](file:///e:/code/Flutter/photo_uploader/lib/main.dart)
3. Run the SQL schema in the [supabase_schema.sql](file:///e:/code/Flutter/photo_uploader/supabase_schema.sql) file in your Supabase SQL editor
4. Update the admin email in the RLS policies to match your admin user's email
5. Enable email confirmations in your Supabase project settings

## How It Works

1. When a user signs up, they are automatically created in the `auth.users` table
2. A trigger function then creates a corresponding record in the `camlink.users` table
3. New users have `approved` set to `false` by default
4. Admin users can update the `approved` field to `true` to grant access
5. When users sign in, the app checks if they are approved before allowing access
6. Unapproved users are redirected to an admin approval screen

## Admin Approval Process

To approve a user:
1. Go to the Supabase dashboard
2. Navigate to Table Editor
3. Find the user in the `camlink.users` table
4. Set their `approved` field to `true`

## Error Handling

The app handles various authentication errors:
- Invalid credentials
- Unapproved accounts
- Network issues
- Password reset failures

All errors are displayed to the user with appropriate messages.