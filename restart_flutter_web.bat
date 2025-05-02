@echo off
echo Stopping any running Flutter web server...
taskkill /f /im dart.exe /t 2>nul
taskkill /f /im chrome.exe /t 2>nul

echo Clearing Flutter web cache...
cd project
flutter clean web

echo Starting Flutter web server with new CORS proxy...
flutter run -d chrome --web-port=62354

echo Flutter web server started with CORS proxy.
