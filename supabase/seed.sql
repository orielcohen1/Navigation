-- Generated from app/assets/data/mall_data.json by tool/generate_seed.ps1
-- Run this in the Supabase SQL Editor AFTER schema.sql

insert into venues (id, name, map_width, map_height, meters_per_unit) values
  ('city_center_mall', 'City Center Mall', 1000, 620, 0.1);

insert into floors (venue_id, id, name) values
  ('city_center_mall', 'G', 'Ground Floor');
insert into floors (venue_id, id, name) values
  ('city_center_mall', 'U', 'Upper Floor');

insert into nodes (venue_id, floor_id, id, x, y, label) values
  ('city_center_mall', 'G', 'G_NORTH_ENT', 500, 20, 'North Entrance'),
  ('city_center_mall', 'G', 'G_NORTH', 500, 120, null),
  ('city_center_mall', 'G', 'G_NW', 250, 120, null),
  ('city_center_mall', 'G', 'G_NE', 750, 120, null),
  ('city_center_mall', 'G', 'G_INFO', 500, 220, 'Information Desk'),
  ('city_center_mall', 'G', 'G_WEST_ENT', 20, 300, 'West Entrance'),
  ('city_center_mall', 'G', 'G_WEST', 250, 300, null),
  ('city_center_mall', 'G', 'G_CENTER', 500, 300, 'Escalators'),
  ('city_center_mall', 'G', 'G_EAST', 750, 300, null),
  ('city_center_mall', 'G', 'G_EAST_ENT', 980, 300, 'East Entrance'),
  ('city_center_mall', 'G', 'G_FOOD_W', 350, 400, null),
  ('city_center_mall', 'G', 'G_FOOD_E', 620, 400, null),
  ('city_center_mall', 'G', 'G_SW', 250, 480, null),
  ('city_center_mall', 'G', 'G_SE', 750, 480, null),
  ('city_center_mall', 'G', 'G_SOUTH', 500, 480, null),
  ('city_center_mall', 'G', 'G_SOUTH_ENT', 500, 580, 'South Entrance'),
  ('city_center_mall', 'G', 'G_SUPERMART', 120, 160, null),
  ('city_center_mall', 'G', 'G_PHARMACY', 880, 160, null),
  ('city_center_mall', 'G', 'G_BANK', 120, 440, null),
  ('city_center_mall', 'U', 'U_CINEMA_ENT', 500, 50, 'Cinema Entrance'),
  ('city_center_mall', 'U', 'U_NORTH', 500, 120, null),
  ('city_center_mall', 'U', 'U_NW', 250, 120, null),
  ('city_center_mall', 'U', 'U_NE', 750, 120, null),
  ('city_center_mall', 'U', 'U_INFO', 500, 220, null),
  ('city_center_mall', 'U', 'U_WEST', 250, 300, null),
  ('city_center_mall', 'U', 'U_CENTER', 500, 300, 'Escalators'),
  ('city_center_mall', 'U', 'U_EAST', 750, 300, null),
  ('city_center_mall', 'U', 'U_KIDS_W', 350, 410, null),
  ('city_center_mall', 'U', 'U_KIDS_E', 620, 410, null),
  ('city_center_mall', 'U', 'U_SW', 250, 490, null),
  ('city_center_mall', 'U', 'U_SE', 750, 490, null),
  ('city_center_mall', 'U', 'U_SOUTH', 500, 490, null),
  ('city_center_mall', 'U', 'U_ZARA', 110, 160, null),
  ('city_center_mall', 'U', 'U_APPLE', 890, 160, null),
  ('city_center_mall', 'U', 'U_NIKE', 110, 460, null),
  ('city_center_mall', 'U', 'U_HM', 890, 460, null);

insert into edges (venue_id, floor_id, from_node, to_node, weight) values
  ('city_center_mall', 'G', 'G_NORTH_ENT', 'G_NORTH', 1),
  ('city_center_mall', 'G', 'G_NORTH', 'G_NW', 1),
  ('city_center_mall', 'G', 'G_NORTH', 'G_NE', 1),
  ('city_center_mall', 'G', 'G_NORTH', 'G_INFO', 1),
  ('city_center_mall', 'G', 'G_INFO', 'G_CENTER', 1),
  ('city_center_mall', 'G', 'G_NW', 'G_SUPERMART', 1),
  ('city_center_mall', 'G', 'G_NW', 'G_WEST', 1),
  ('city_center_mall', 'G', 'G_NE', 'G_PHARMACY', 1),
  ('city_center_mall', 'G', 'G_NE', 'G_EAST', 1),
  ('city_center_mall', 'G', 'G_WEST_ENT', 'G_WEST', 1),
  ('city_center_mall', 'G', 'G_WEST', 'G_CENTER', 1),
  ('city_center_mall', 'G', 'G_WEST', 'G_SW', 1),
  ('city_center_mall', 'G', 'G_CENTER', 'G_EAST', 1),
  ('city_center_mall', 'G', 'G_CENTER', 'G_FOOD_W', 1),
  ('city_center_mall', 'G', 'G_CENTER', 'G_FOOD_E', 1),
  ('city_center_mall', 'G', 'G_EAST_ENT', 'G_EAST', 1),
  ('city_center_mall', 'G', 'G_EAST', 'G_SE', 1),
  ('city_center_mall', 'G', 'G_FOOD_W', 'G_FOOD_E', 1),
  ('city_center_mall', 'G', 'G_FOOD_W', 'G_SW', 1),
  ('city_center_mall', 'G', 'G_FOOD_E', 'G_SE', 1),
  ('city_center_mall', 'G', 'G_SW', 'G_SOUTH', 1),
  ('city_center_mall', 'G', 'G_SW', 'G_BANK', 1),
  ('city_center_mall', 'G', 'G_SE', 'G_SOUTH', 1),
  ('city_center_mall', 'G', 'G_SOUTH', 'G_SOUTH_ENT', 1),
  ('city_center_mall', 'U', 'U_CINEMA_ENT', 'U_NORTH', 1),
  ('city_center_mall', 'U', 'U_NORTH', 'U_NW', 1),
  ('city_center_mall', 'U', 'U_NORTH', 'U_NE', 1),
  ('city_center_mall', 'U', 'U_NORTH', 'U_INFO', 1),
  ('city_center_mall', 'U', 'U_INFO', 'U_CENTER', 1),
  ('city_center_mall', 'U', 'U_NW', 'U_ZARA', 1),
  ('city_center_mall', 'U', 'U_NW', 'U_WEST', 1),
  ('city_center_mall', 'U', 'U_NE', 'U_APPLE', 1),
  ('city_center_mall', 'U', 'U_NE', 'U_EAST', 1),
  ('city_center_mall', 'U', 'U_WEST', 'U_CENTER', 1),
  ('city_center_mall', 'U', 'U_WEST', 'U_SW', 1),
  ('city_center_mall', 'U', 'U_CENTER', 'U_EAST', 1),
  ('city_center_mall', 'U', 'U_CENTER', 'U_KIDS_W', 1),
  ('city_center_mall', 'U', 'U_CENTER', 'U_KIDS_E', 1),
  ('city_center_mall', 'U', 'U_EAST', 'U_SE', 1),
  ('city_center_mall', 'U', 'U_KIDS_W', 'U_KIDS_E', 1),
  ('city_center_mall', 'U', 'U_KIDS_W', 'U_SW', 1),
  ('city_center_mall', 'U', 'U_KIDS_E', 'U_SE', 1),
  ('city_center_mall', 'U', 'U_SW', 'U_SOUTH', 1),
  ('city_center_mall', 'U', 'U_SW', 'U_NIKE', 1),
  ('city_center_mall', 'U', 'U_SE', 'U_SOUTH', 1),
  ('city_center_mall', 'U', 'U_SE', 'U_HM', 1);

insert into qr_codes (venue_id, floor_id, id, node_id, label) values
  ('city_center_mall', 'G', 'QR_G_01', 'G_NORTH_ENT', 'North Entrance'),
  ('city_center_mall', 'G', 'QR_G_02', 'G_WEST', 'West Wing'),
  ('city_center_mall', 'G', 'QR_G_03', 'G_CENTER', 'Center / Escalators'),
  ('city_center_mall', 'G', 'QR_G_04', 'G_FOOD_W', 'Food Court West'),
  ('city_center_mall', 'G', 'QR_G_05', 'G_SOUTH_ENT', 'South Entrance'),
  ('city_center_mall', 'U', 'QR_U_01', 'U_CINEMA_ENT', 'Cinema Entrance'),
  ('city_center_mall', 'U', 'QR_U_02', 'U_CENTER', 'Upper Center'),
  ('city_center_mall', 'U', 'QR_U_03', 'U_ZARA', 'Near Zara'),
  ('city_center_mall', 'U', 'QR_U_04', 'U_KIDS_W', 'Kids Zone West'),
  ('city_center_mall', 'U', 'QR_U_05', 'U_APPLE', 'Near Apple Store');

insert into inter_floor_edges (venue_id, from_node, to_node, type) values
  ('city_center_mall', 'G_CENTER', 'U_CENTER', 'escalator');

insert into pois (venue_id, id, name, category, floor_id, node_id, icon) values
  ('city_center_mall', 'poi_food_court', 'Food Court', 'Food', 'G', 'G_FOOD_W', 'restaurant'),
  ('city_center_mall', 'poi_starbucks', 'Starbucks', 'Coffee', 'G', 'G_INFO', 'local_cafe'),
  ('city_center_mall', 'poi_mcdonalds', 'McDonald''s', 'Food', 'G', 'G_FOOD_E', 'fastfood'),
  ('city_center_mall', 'poi_supermart', 'SuperMart', 'Supermarket', 'G', 'G_SUPERMART', 'shopping_cart'),
  ('city_center_mall', 'poi_pharmacy', 'Green Pharmacy', 'Health', 'G', 'G_PHARMACY', 'local_pharmacy'),
  ('city_center_mall', 'poi_bank', 'City Bank ATM', 'Services', 'G', 'G_BANK', 'account_balance'),
  ('city_center_mall', 'poi_info', 'Information Desk', 'Services', 'G', 'G_INFO', 'info'),
  ('city_center_mall', 'poi_cinema', 'CinePlex Cinema', 'Entertainment', 'U', 'U_CINEMA_ENT', 'movie'),
  ('city_center_mall', 'poi_zara', 'Zara', 'Fashion', 'U', 'U_ZARA', 'checkroom'),
  ('city_center_mall', 'poi_apple', 'Apple Store', 'Electronics', 'U', 'U_APPLE', 'phone_iphone'),
  ('city_center_mall', 'poi_hm', 'H&M', 'Fashion', 'U', 'U_HM', 'checkroom'),
  ('city_center_mall', 'poi_nike', 'Nike', 'Sports', 'U', 'U_NIKE', 'directions_run'),
  ('city_center_mall', 'poi_kids', 'Kids Zone', 'Kids', 'U', 'U_KIDS_W', 'child_care'),
  ('city_center_mall', 'poi_coffee_upper', 'Coffee Corner', 'Coffee', 'U', 'U_INFO', 'local_cafe');
