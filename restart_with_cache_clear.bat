@echo off
echo ===================================
echo NeoNote Full Restart with Cache Clear
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

echo Step 3: Starting Django server with enhanced CORS settings...
start cmd /k "cd core && python manage.py runserver"
echo.

echo Step 4: Waiting for Django server to start...
timeout /t 5 /nobreak
echo.

echo Step 5: Starting Flutter web server...
start cmd /k "cd project && flutter run -d chrome --web-port=62354"
echo.

echo ===================================
echo All servers started successfully!
echo ===================================
echo.
echo IMPORTANT: Clear your browser cache and storage:
echo 1. Open developer tools (F12 or Ctrl+Shift+I)
echo 2. Go to Application tab
echo 3. Select Local Storage and clear it
echo 4. Select Session Storage and clear it
echo 5. Go to Network tab and check "Disable cache"
echo 6. Refresh the page and log in again
echo.
echo See DIRECT_API_FIX_README.md for more details
echo.
echo Press any key to exit this script...
pause > nul
