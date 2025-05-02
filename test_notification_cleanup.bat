@echo off
echo ===================================
echo Testing Notification Cleanup Feature
echo ===================================
echo.

cd core

echo Running debug command to show current notifications...
python manage.py debug_notifications
echo.

echo Press any key to continue...
pause > nul

echo.
echo ===================================
echo Restart the Django server to apply changes
echo ===================================
echo.
echo 1. Stop the current Django server
echo 2. Start it again with: python manage.py runserver
echo 3. Test leaving or deleting a project
echo 4. Run the debug command again to verify notifications were deleted:
echo    python manage.py debug_notifications
echo.
echo Press any key to exit...
pause > nul
