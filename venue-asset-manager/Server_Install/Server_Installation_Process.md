# Venue Asset Manager - Server Installation Process

## Target architecture
- IIS serves the React/Vite frontend from `C:\VenueAssetManager\dist`.
- IIS URL Rewrite + ARR proxies `/api/*` to Node.js on `127.0.0.1:4000`.
- Node.js/Express runs the backend from `C:\VenueAssetManager\server`.
- MySQL 5.6 stores users, venues and assets.

## Important difference from the legacy TicketNew/Boxoffice stack
This application is React + Node.js + MySQL. It does **not** require ASP.NET, ASPAJAX, Enterprise Library, Crystal Reports, .NET Framework, ID Automation, or SAP Crystal runtime for the core application. Those can remain part of an organization's standard server image, but they are not application dependencies.

## Recommended server sequence
1. Windows Server updates and reboot.
2. Install IIS: Web Server, Static Content, Default Document, IIS Management Console.
3. Install IIS URL Rewrite.
4. Install IIS Application Request Routing (ARR) and enable proxy.
5. Install Node.js LTS (18+; 20 LTS recommended for this build).
6. Install WinRAR/7-Zip if required by the organization's deployment process.
7. Install MySQL 5.6 64-bit according to the approved organization package. Use D: for MySQL data if required.
8. Create database `venue_asset_manager` and import `database.sql`.
9. Copy this application to `C:\VenueAssetManager`.
10. Copy `Prerequisite` to `D:\VenueAssetManager\Prerequisite` if the organization wants the same C:/D: separation used by the legacy deployment.
11. Edit `Prerequisite\Config\Config.json`: set VenueId if used; keep `SkipVenueValidation=true` unless validation is required.
12. Run the build check:
   `cd D:\VenueAssetManager\Prerequisite\Installer`
   `powershell -ExecutionPolicy Bypass -File .\check.build.ps1 .\..\Config\Config.json`
13. Configure `C:\VenueAssetManager\server\.env` with MySQL credentials and JWT secret.
14. Install dependencies and build:
   `cd C:\VenueAssetManager`
   `npm install --no-audit --no-fund`
   `npm --prefix server install --no-audit --no-fund`
   `npm run build`
15. Create an IIS site pointing to `C:\VenueAssetManager\dist`.
16. Confirm `web.config` is in `dist`.
17. Start the Node backend and test `http://127.0.0.1:4000/api/health`.
18. Open the IIS URL and test login.

## Database restore
Use MySQL Workbench, mysql.exe, or your organization's approved restore tool. Example:
`mysql -u root -p venue_asset_manager < C:\VenueAssetManager\database.sql`

## MySQL 5.6 configuration
The application uses MySQL port 3306, UTF-8 tables, and the `mysql2` Node.js driver. Do not enable remote root access unless your organization requires it. Prefer localhost/127.0.0.1 for the application connection.

## IIS reverse proxy
The included `web.config` has:
- `/api/*` -> `http://127.0.0.1:4000/api/*`
- `/lgd-api/*` -> `http://127.0.0.1:4000/lgd-api/*`
- React SPA fallback -> `index.html`

ARR proxy must be enabled for the API rewrite to work.

## Production recommendation
Run Node.js as a Windows service rather than keeping PowerShell open. The included `start-backend.bat` is intended for initial testing.
