@echo off
setlocal
echo ========================================================
echo   TutorFlow BCA LMS - Automated APK Build Script
echo ========================================================
echo.

:: Check if flutter is in PATH, otherwise try C:\Users\princ\flutter\bin
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
        set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
        echo [INFO] Found Flutter SDK at %USERPROFILE%\flutter\bin
    ) else (
        echo [ERROR] Flutter SDK not detected in PATH or %USERPROFILE%\flutter\bin.
        echo Please ensure Flutter SDK is downloaded and added to your system PATH.
        pause
        exit /b 1
    )
)

echo [1/3] Navigating to flutter_app directory...
cd /d "%~dp0flutter_app"

echo [2/3] Fetching dependencies (flutter pub get)...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to fetch flutter dependencies.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Compiling Release APK (flutter build apk --release)...
echo Enforcing Android FLAG_SECURE and in-memory byte streaming...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] APK build encountered an issue. Check the logs above.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo   BUILD SUCCESSFUL!
echo   Your production APK is ready at:
echo   %~dp0flutter_app\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
