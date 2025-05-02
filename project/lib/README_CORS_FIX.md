# Fixing Web Connection Issues in NeoNote

This document explains how to fix the "Error connecting to server" issue that occurs when accessing the NeoNote application in a web browser.

## The Problem

When running the NeoNote application in a web browser, you may encounter an error message like:

```
Error connecting to server: ClientException: Failed to fetch, uri=http://localhost:8000/api/work/invitations/?include_sent=true
```

The issue is related to CORS (Cross-Origin Resource Sharing) restrictions in web browsers. When your Flutter web application tries to make API requests to your Django backend, the browser blocks these requests due to security policies.

## Solution 0: Use 127.0.0.1 Instead of localhost

The simplest solution is to use `127.0.0.1` instead of `localhost` in your web application:

1. Update all API URLs in your Flutter web app to use `127.0.0.1:8000` instead of `localhost:8000`
2. Use the provided `UrlHelper` class to automatically handle this based on the platform:

```dart
import 'package:project/utils/url_helper.dart';

// Get the base URL (http://127.0.0.1:8000 for web, http://localhost:8000 for native)
String baseUrl = UrlHelper.getBaseUrl();

// Get a full API URL
String loginUrl = UrlHelper.getApiUrl('api/accounts/login/');
```

This solution works in most cases and doesn't require any changes to your backend server.

## Alternative Solution 1: Install django-cors-headers

The most reliable solution is to install the django-cors-headers package in your Django project:

1. Run the provided `install_cors_headers.bat` script or manually install the package:
   ```bash
   pip install django-cors-headers
   ```

2. Add it to your `INSTALLED_APPS` in `settings.py`:
   ```python
   INSTALLED_APPS = [
       # ...
       'corsheaders',
       # ...
   ]
   ```

3. Add the middleware to `MIDDLEWARE` in `settings.py` (make sure it's placed before `django.middleware.common.CommonMiddleware`):
   ```python
   MIDDLEWARE = [
       # ...
       'corsheaders.middleware.CorsMiddleware',
       'django.middleware.common.CommonMiddleware',
       # ...
   ]
   ```

4. Configure CORS settings in `settings.py`:
   ```python
   # CORS settings
   CORS_ALLOW_ALL_ORIGINS = True  # For development only
   CORS_ALLOW_CREDENTIALS = True
   ```

5. Restart your Django server for the changes to take effect.

## Alternative Solution 1: Use the Custom CORS Middleware

If you can't install the django-cors-headers package, you can use the custom CORS middleware provided in this project:

1. Copy the `cors_middleware.py` file to your Django project (e.g., in the same directory as `settings.py`).

2. Add the middleware to `MIDDLEWARE` in `settings.py`:

```python
MIDDLEWARE = [
    # ...
    'yourapp.cors_middleware.CorsMiddleware',  # Adjust the path as needed
    'django.middleware.common.CommonMiddleware',
    # ...
]
```

3. Configure CORS settings in `settings.py` (optional):

```python
# CORS settings
CORS_ALLOWED_ORIGINS = ['*']  # Allow all origins (for development only)
CORS_ALLOWED_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']
CORS_ALLOWED_HEADERS = ['Authorization', 'Content-Type', 'X-Requested-With']
```

## Alternative Solution 2: Use a Proxy Server

If you're using Flutter web in development, you can set up a proxy server to bypass CORS restrictions:

1. Install the `http_proxy` package:

```bash
dart pub global activate http_proxy
```

2. Run the proxy server:

```bash
dart pub global run http_proxy --port 8888 --host 0.0.0.0
```

3. Configure your Flutter web app to use the proxy server by updating the API base URL:

```dart
String baseUrl = 'http://localhost:8888/http://localhost:8000';
```

## Alternative Solution 3: Use the Desktop App

As a workaround, you can use the desktop app instead of the web app. The desktop app doesn't have CORS restrictions and can directly communicate with the backend server.

## Why These Solutions Work

### Solution 0: Using 127.0.0.1 Instead of localhost

When using `127.0.0.1` instead of `localhost`:

1. Both refer to the same machine (the loopback address)
2. Browsers sometimes handle them differently for security purposes
3. Using the IP address directly can bypass certain browser restrictions
4. This is the simplest solution that requires no backend changes

### Solution 1-3: CORS Configuration

CORS is a security feature implemented by web browsers that restricts web pages from making requests to a different domain than the one that served the web page. By adding the CORS middleware to your Django application, you're telling the browser that it's okay for your Flutter web app to communicate with your Django backend.

The django-cors-headers package adds the necessary HTTP headers to your server's responses, which allows the browser to make cross-origin requests.

## Important Notes

- CORS issues only affect web applications, not native mobile or desktop apps.
- In production, you should never use `CORS_ALLOW_ALL_ORIGINS = True`. Always specify the exact origins that are allowed to access your API.
- Client-side CORS headers (added in the Flutter app) don't solve the problem - these headers need to be set by the server.
