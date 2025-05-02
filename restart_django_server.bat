@echo off
echo Stopping any running Django server...
taskkill /f /im python.exe /t 2>nul

echo Starting Django server with new CORS settings...
cd core
python manage.py runserver

echo Django server started with new CORS settings.
