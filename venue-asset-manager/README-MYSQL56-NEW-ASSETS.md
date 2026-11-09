# Venue Asset Manager - MySQL 5.6 New Asset Build

This build stays on MySQL 5.6. It does NOT use MySQL 8 JSON functions.

## New options
- Own Asset: Invoice No, Invoice Date, Vendor Name, Model Name, Serial Number, Quantity, Status.
- Rental Asset: Model Name, Quantity, Status, Removal Asset checkbox, Removal Date.
- Asset Letters: venue + calendar date + upload any file format (PDF/JPG/PNG/DOC/DOCX/XLS/XLSX/ZIP/etc.), stored in MySQL LONGBLOB. Maximum 30 MB per file.
- Venue ID in Assets is clickable and filters all assets for that venue.
- State-wise and District-wise reports use MySQL-compatible views.
- Persistent application data is stored in MySQL. Browser localStorage is used only as a UI cache/session cache.

## Database
Run `database.sql` in MySQL 5.6.

The Node API also creates the required tables at startup. It can migrate the previous `venues.data_json` and `assets.data_json` tables without using MySQL JSON functions because the JSON is parsed by Node.js.

## API configuration
Copy `server/.env.example` to `server/.env` and set your MySQL 5.6 password.

Install API dependencies:
`cd server`
`npm install`

Start:
`node server.js`

Health:
`http://127.0.0.1:4000/api/health`

## Existing IIS
Keep your existing IIS reverse proxy and `/venueassetmanager` configuration. Build the frontend with the existing Vite base path.
