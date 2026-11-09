-- Venue Asset Manager - MySQL 5.6 compatible database
CREATE DATABASE IF NOT EXISTS venue_asset_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE venue_asset_manager;

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(100) NOT NULL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  permissions TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS venue_master (
  id VARCHAR(100) NOT NULL PRIMARY KEY,
  venue_id VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  state VARCHAR(120) NOT NULL,
  state_code VARCHAR(20) NULL,
  district VARCHAR(120) NOT NULL,
  district_code VARCHAR(20) NULL,
  location VARCHAR(255) NULL,
  contact VARCHAR(30) NULL,
  address TEXT NULL,
  updated_by VARCHAR(190) NULL,
  created_by VARCHAR(190) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS asset_master (
  id VARCHAR(100) NOT NULL PRIMARY KEY,
  venue_id VARCHAR(100) NOT NULL,
  asset_type ENUM('Own','Rental') NOT NULL DEFAULT 'Own',
  category VARCHAR(120) NOT NULL,
  model_name VARCHAR(200) NULL,
  serial_number VARCHAR(200) NULL,
  quantity INT NOT NULL DEFAULT 1,
  details VARCHAR(255) NULL,
  invoice_no VARCHAR(150) NULL,
  invoice_date DATE NULL,
  vendor_name VARCHAR(200) NULL,
  removal_date DATE NULL,
  removed TINYINT(1) NOT NULL DEFAULT 0,
  updated_by VARCHAR(190) NULL,
  created_by VARCHAR(190) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_asset_venue(venue_id),
  INDEX idx_asset_category(category),
  INDEX idx_asset_type(asset_type),
  INDEX idx_asset_removal(removed,removal_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS asset_letters (
  id VARCHAR(100) NOT NULL PRIMARY KEY,
  venue_id VARCHAR(100) NOT NULL,
  letter_date DATE NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(150) NULL,
  file_size BIGINT NOT NULL DEFAULT 0,
  file_data LONGBLOB NOT NULL,
  uploaded_by VARCHAR(190) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_letter_venue(venue_id),
  INDEX idx_letter_date(letter_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE OR REPLACE VIEW state_asset_report AS
SELECT v.state AS state,
       COUNT(DISTINCT v.id) AS total_venues,
       COALESCE(SUM(CASE WHEN a.removed=0 THEN a.quantity ELSE 0 END),0) AS total_assets
FROM venue_master v
LEFT JOIN asset_master a ON a.venue_id=v.id
GROUP BY v.state;

CREATE OR REPLACE VIEW district_asset_report AS
SELECT v.state AS state,
       v.district AS district,
       COUNT(DISTINCT v.id) AS total_venues,
       COALESCE(SUM(CASE WHEN a.removed=0 THEN a.quantity ELSE 0 END),0) AS total_assets
FROM venue_master v
LEFT JOIN asset_master a ON a.venue_id=v.id
GROUP BY v.state,v.district;

-- Initial administrator. Change the password from the application after first login.
INSERT INTO users(id,name,email,password_hash,role,permissions)
SELECT '1','Administrator','admin@venueassetmanager.local',
       '$2b$10$8aVwQwJx6m3vZ5dH0mXK1uG6i1z6FQJq5Z0X0rH0w5VQ5b0Yx0w0O',
       'Admin','["dashboard","venues","assets","letters","reports","calculator","users"]'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id='1');
