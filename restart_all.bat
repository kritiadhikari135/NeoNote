@echo off
echo ===================================
echo NeoNote Full Restart Script
echo ===================================
echo.

echo Step 1: Stopping any running servers...
taskkill /f /im python.exe /t 2>nul
taskkill /f /im dart.exe /t 2>nul
taskkill /f /im chrome.exe /t 2>nul
echo.

echo Step 2: Clearing Flutter web cache...
cd project
flutter clean web
cd ..
echo.

echo Step 3: Starting Django server with new CORS settings...
start cmd /k "cd core && python manage.py runserver"
echo.

echo Step 4: Waiting for Django server to start...
timeout /t 5 /nobreak
echo.

echo Step 5: Starting Flutter web server with CORS proxy...
start cmd /k "cd project && flutter run -d chrome --web-port=62354"
echo.

echo ===================================
echo All servers started successfully!
echo ===================================
echo.
echo Instructions:
echo 1. Log out and log in again to refresh your authentication token
echo 2. If issues persist, clear your browser cache and local storage
echo 3. See AUTHENTICATION_FIX_README.md for more details
echo.
echo Press any key to exit this script...
pause > nul
