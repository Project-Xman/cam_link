-- Create users table
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  full_name text not null,
  approved boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Create a trigger to update the updated_at column
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

create trigger update_users_updated_at 
  before update on public.users 
  for each row 
  execute function public.update_updated_at_column();

-- Set up Row Level Security (RLS)
alter table public.users enable row level security;

-- Create policies
create policy "Users can view their own data" 
  on public.users 
  for select 
  using (auth.uid() = id);

create policy "Users can update their own data" 
  on public.users 
  for update 
  using (auth.uid() = id);

create policy "Users can insert their own data" 
  on public.users 
  for insert 
  with check (auth.uid() = id);

-- Create admin role and policies for admin access
create policy "Admins can view all users" 
  on public.users 
  for select 
  using (
    exists (
      select 1 from public.users 
      where id = auth.uid() 
      and email = 'admin@example.com'  -- Replace with actual admin email
    )
  );

create policy "Admins can update user approval status" 
  on public.users 
  for update 
  using (
    exists (
      select 1 from public.users 
      where id = auth.uid() 
      and email = 'admin@example.com'  -- Replace with actual admin email
    )
  );

-- Create a function to automatically insert user data when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, full_name, approved)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', false);
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger to automatically insert user data
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Grant permissions
grant usage on schema public to postgres, anon, authenticated;
grant all privileges on table public.users to postgres, authenticated;

-- Grant select permission for auth.users to authenticated users
grant select on table auth.users to authenticated;