# Venue Asset Manager - IIS + MySQL 5.6

This package keeps the existing React/Vite page and changes the persistence layer to MySQL 5.6.

## Architecture

Browser -> IIS -> React `dist` frontend
                 -> `/api/*` reverse proxy -> Node.js/Express :4000 -> MySQL 5.6

## 1. MySQL 5.6

Create the database:

    mysql -u root -p < database.sql

Or run `database.sql` in MySQL Workbench.

Database: `venue_asset_manager`

## 2. Backend

Copy:

    server/.env.example -> server/.env

Set your MySQL password and a strong JWT secret.

Then:

    cd server
    npm install
    npm start

Test:

    http://127.0.0.1:4000/api/health

Expected:

    {"ok":true,"service":"venue-asset-manager-api","database":"mysql"}

The backend automatically creates the tables and, when the tables are empty, imports the existing `server/data.json` once. This makes the first migration easier.

## 3. Frontend build

From the project root:

    npm install
    npm run build

The IIS site folder is:

    dist

The generated `dist/web.config` is copied from the root during deployment if you copy `web.config` into `dist`.

## 4. IIS

Install IIS plus:

- URL Rewrite module
- Application Request Routing (ARR)

Enable ARR proxy in IIS Manager -> server -> Application Request Routing Cache -> Server Proxy Settings -> Enable proxy.

Create a website whose physical path is the `dist` folder.

Copy `web.config` into `dist` if it is not already there.

The rule `/api/*` forwards to Node.js on port 4000. The React fallback sends application routes to `index.html`.

## 5. Login

Initial administrator:

Email: `admin@venueassetmanager.local`
Password: `admin123`

Change `ADMIN_PASSWORD` before production and change the password from the application when user management is implemented.

## 6. Important

Do not expose port 4000 directly to the internet. Keep Node bound behind IIS or restrict Windows Firewall access to localhost.
