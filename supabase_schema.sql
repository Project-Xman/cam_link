-- Create users table
create table if not exists camlink.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  full_name text not null,
  approved boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Create or replace updated_at function
create or replace function camlink.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Drop existing trigger before creating
drop trigger if exists update_users_updated_at on camlink.users;
create trigger update_users_updated_at 
  before update on camlink.users 
  for each row 
  execute function camlink.update_updated_at_column();

-- Enable RLS
alter table camlink.users enable row level security;

-- Drop policies if they exist before recreating
drop policy if exists "Users can view their own data" on camlink.users;
create policy "Users can view their own data" 
  on camlink.users 
  for select 
  using (auth.uid() = id);

drop policy if exists "Users can update their own data" on camlink.users;
create policy "Users can update their own data" 
  on camlink.users 
  for update 
  using (auth.uid() = id);

drop policy if exists "Users can insert their own data" on camlink.users;
create policy "Users can insert their own data" 
  on camlink.users 
  for insert 
  with check (auth.uid() = id);

drop policy if exists "Admins can view all users" on camlink.users;
create policy "Admins can view all users" 
  on camlink.users 
  for select 
  using (
    exists (
      select 1 from camlink.users 
      where id = auth.uid() 
      and email = 'admin@example.com'  -- Replace with actual admin email
    )
  );

drop policy if exists "Admins can update user approval status" on camlink.users;
create policy "Admins can update user approval status" 
  on camlink.users 
  for update 
  using (
    exists (
      select 1 from camlink.users 
      where id = auth.uid() 
      and email = 'admin@example.com'  -- Replace with actual admin email
    )
  );

-- Create function to handle new users
create or replace function camlink.handle_new_user()
returns trigger as $$
begin
  insert into camlink.users (id, email, full_name, approved)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', false)
  on conflict (id) do nothing; -- avoid duplicate insert
  return new;
end;
$$ language plpgsql security definer;

-- Drop existing trigger before creating
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure camlink.handle_new_user();

-- Grants
grant usage on schema camlink to postgres, anon, authenticated;
grant all privileges on table camlink.users to postgres, authenticated;

-- Ensure select granted for auth.users
grant select on table auth.users to authenticated;