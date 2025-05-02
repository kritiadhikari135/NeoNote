@echo off
echo ===================================================
echo Flutter Windows Symlink Fix
echo ===================================================

cd project

echo.
echo Step 1: Cleaning Flutter project...
call flutter clean
echo.

echo Step 2: Deleting problematic directories...
if exist windows\flutter\ephemeral rmdir /s /q windows\flutter\ephemeral
if exist .dart_tool rmdir /s /q .dart_tool
if exist build rmdir /s /q build
echo.

echo Step 3: Getting dependencies...
call flutter pub get
echo.

echo Step 4: Creating Windows build files...
call flutter create --platforms=windows .
echo.

echo Step 5: Building Windows app...
call flutter build windows --debug
echo.

echo ===================================================
echo Fix complete! Now try running:
echo cd project
echo flutter run -d windows
echo ===================================================
