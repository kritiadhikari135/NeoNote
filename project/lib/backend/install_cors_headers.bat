@echo off
echo Installing django-cors-headers package...
pip install django-cors-headers
echo.
echo Installation complete!
echo.
echo Now add the following to your settings.py file:
echo.
echo 1. Add 'corsheaders' to INSTALLED_APPS
echo 2. Add 'corsheaders.middleware.CorsMiddleware' to MIDDLEWARE (before CommonMiddleware)
echo 3. Add CORS settings from cors_settings.py
echo.
echo See cors_settings.py for the complete configuration.
echo.
pause
