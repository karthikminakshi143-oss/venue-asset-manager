Venue Asset Manager - Asset Excel Import/Export Patch

Features added to Assets page:
- Download Excel: exports the currently filtered inventory with the table columns.
- Excel Template: downloads a blank template with the supported headings.
- Upload Excel: imports multiple .xlsx asset rows and validates the venue, asset type,
  category, model, quantity, status, serial number, invoice fields, and removal date.
- Venue ID in Excel matches the Venue Master business Venue ID (for example 16106).
- Existing assets are preserved; imported rows are added and synchronized through the
  existing /api/sync/assets route.

Installation:
1. Extract this ZIP.
2. Open PowerShell as Administrator if needed for IIS folder permissions.
3. Run:
   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-AssetExcel.ps1
4. The script backs up src\main.jsx and the existing IIS deployment, runs npm run build,
   then copies dist to D:\IIS\VenueAssetManager.
5. Open http://localhost/venueassetmanager/login, sign in, and go to Assets.

Assumptions:
- Project path: D:\venue-asset-manager
- IIS deployment path: D:\IIS\VenueAssetManager
- IIS app URL: http://localhost/venueassetmanager
- The current backend and MySQL connection are already working.
- Excel import uses the first worksheet of an .xlsx file.

Supported Excel headings:
Venue ID, Venue, Asset Type, Category, Model Name, Serial Number, Invoice No,
Invoice Date, Vendor Name, Qty, Status, Removal Asset, Removal Date.

For Own assets, Serial Number, Invoice No, Invoice Date, and Vendor Name are required.
For Rental assets, serial/invoice/vendor fields are ignored. Quantity must be 1-25.
