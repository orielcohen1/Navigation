-- Indoor Navigation — multi-tenant schema
-- Run this once in the Supabase SQL Editor (Project > SQL Editor > New query).

create table venues (
  id              text primary key,
  name            text not null,
  map_width       double precision not null,
  map_height      double precision not null,
  meters_per_unit double precision not null default 0.1
);

create table floors (
  venue_id text not null references venues(id) on delete cascade,
  id       text not null,
  name     text not null,
  primary key (venue_id, id)
);

create table nodes (
  venue_id text not null,
  floor_id text not null,
  id       text not null,
  x        double precision not null,
  y        double precision not null,
  label    text,
  primary key (venue_id, id),
  foreign key (venue_id, floor_id) references floors(venue_id, id) on delete cascade
);

create table edges (
  id       bigint generated always as identity primary key,
  venue_id text not null,
  floor_id text not null,
  from_node text not null,
  to_node   text not null,
  weight    double precision not null default 1.0,
  foreign key (venue_id, floor_id) references floors(venue_id, id) on delete cascade
);

create table qr_codes (
  venue_id text not null,
  floor_id text not null,
  id       text not null,
  node_id  text not null,
  label    text not null,
  primary key (venue_id, id),
  foreign key (venue_id, floor_id) references floors(venue_id, id) on delete cascade
);

create table inter_floor_edges (
  id        bigint generated always as identity primary key,
  venue_id  text not null references venues(id) on delete cascade,
  from_node text not null,
  to_node   text not null,
  type      text not null
);

create table pois (
  venue_id text not null references venues(id) on delete cascade,
  id       text not null,
  name     text not null,
  category text not null,
  floor_id text not null,
  node_id  text not null,
  icon     text not null,
  primary key (venue_id, id)
);

-- Row Level Security: the app uses the public "anon" key, which must only
-- ever be able to READ venue data, never write it. No write policies are
-- created, so inserts/updates/deletes are rejected for anon by default.
alter table venues            enable row level security;
alter table floors            enable row level security;
alter table nodes             enable row level security;
alter table edges             enable row level security;
alter table qr_codes          enable row level security;
alter table inter_floor_edges enable row level security;
alter table pois              enable row level security;

create policy "public read" on venues            for select using (true);
create policy "public read" on floors            for select using (true);
create policy "public read" on nodes             for select using (true);
create policy "public read" on edges             for select using (true);
create policy "public read" on qr_codes          for select using (true);
create policy "public read" on inter_floor_edges for select using (true);
create policy "public read" on pois              for select using (true);
