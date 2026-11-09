# Venue Asset Manager — Final Reports Build v2

Run `02_BUILD_FINAL_REPORTS.ps1` from an elevated PowerShell window.

It:
1. Backs up current `server.js` and `main.jsx`.
2. Applies the MySQL 5.6 report tables.
3. Adds MySQL-backed report APIs.
4. Adds login/logout activity logging.
5. Removes mandatory auth only from Venue Asset Swapping endpoints.
6. Replaces the existing Reports component with 8 report views.
7. Runs `node --check`.
8. Runs `npm run build`.

The script does not upgrade MySQL.
