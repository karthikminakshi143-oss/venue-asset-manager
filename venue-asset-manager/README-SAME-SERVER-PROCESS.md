# Same Server Installation Process - Venue Asset Manager

This package is arranged to follow the same operational style as the existing TicketNew/Boxoffice server installation process, while using the actual dependencies of this project: IIS + Node.js + MySQL 5.6.

## Folder convention
C: application/runtime
D: prerequisites/database backups/installers

Example:
C:\VenueAssetManager\
D:\VenueAssetManager\Prerequisite\
D:\VenueAssetManager\Backup\

## Legacy steps that are not required by this project
- ASP.NET / .NET Framework application runtime
- ASPAJAX
- Enterprise Library
- ID Automation
- Crystal Reports 32-bit/64-bit
- Crystal Report runtime

The React/Node application has no references to those components.

## Equivalent build command
Legacy style:
`cd D:\Prerequisite\Installer`
`Set-ExecutionPolicy Unrestricted`
`.check.build.ps1 ..\Config\Config.json`

This project:
`cd D:\VenueAssetManager\Prerequisite\Installer`
`powershell -ExecutionPolicy Bypass -File .\check.build.ps1 ..\Config\Config.json`

Then:
`powershell -ExecutionPolicy Bypass -File .\build.ps1`

## Initial administrator
Email: admin@venueassetmanager.local
Password: admin123

Change the administrator password after first login if the UI supports it, or change the backend admin configuration before production use.
