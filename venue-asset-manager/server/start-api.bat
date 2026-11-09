@echo off
cd /d "D:\venue-asset-manager\server"
"C:\Program Files\nodejs\node.exe" server.js >> "D:\venue-asset-manager\server\api-service.log" 2>&1
