-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Customers Table
create table if not exists customers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text,
  email text,
  address text,
  total_spent numeric default 0,
  last_visit timestamptz,
  created_at timestamptz default now()
);

-- Vehicles Table
create table if not exists vehicles (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid references customers(id),
  number text not null,
  model text,
  year text,
  color text,
  fuel_type text,
  last_service timestamptz,
  total_services integer default 0,
  status text default 'active',
  created_at timestamptz default now()
);

-- Jobs Table
create table if not exists jobs (
  id uuid primary key default uuid_generate_v4(),
  vehicle_id uuid references vehicles(id),
  customer_id uuid references customers(id),
  description text,
  status text default 'booked', -- booked, in-progress, completed, delivered
  estimated_amount numeric default 0,
  created_at timestamptz default now()
);

-- Inventory Table
create table if not exists inventory (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text,
  stock numeric default 0,
  min_stock numeric default 0,
  unit text,
  cost_price numeric default 0,
  selling_price numeric default 0,
  vendor text,
  created_at timestamptz default now()
);

-- Enable Realtime safely
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'customers') then
    alter publication supabase_realtime add table customers;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'vehicles') then
    alter publication supabase_realtime add table vehicles;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'jobs') then
    alter publication supabase_realtime add table jobs;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'inventory') then
    alter publication supabase_realtime add table inventory;
  end if;
end $$;

-- Insert Mock Data (Only if empty, ideally)
-- ... (Customer/Vehicle mock data same as before)

insert into jobs (vehicle_id, customer_id, description, status, estimated_amount, created_at)
select v.id, c.id, 'Full service', 'in-progress', 8500, now() - interval '2 hours'
from vehicles v join customers c on v.customer_id = c.id
where c.name = 'Rajesh Kumar' limit 1;

insert into inventory (name, category, stock, min_stock, unit, cost_price, selling_price, vendor) values
('Engine Oil (5W-30)', 'Lubricants', 25, 10, 'liters', 450, 600, 'Castrol India'),
('Brake Pads (Front)', 'Brakes', 8, 15, 'sets', 1200, 1800, 'Bosch Auto');
