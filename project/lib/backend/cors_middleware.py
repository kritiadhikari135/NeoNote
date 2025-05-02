"""
CORS Middleware for Django

This middleware adds CORS headers to responses to allow cross-origin requests
from web browsers. This is particularly important for Flutter web applications
that need to communicate with the Django backend.

IMPORTANT: The recommended approach is to use django-cors-headers instead of this custom middleware.

Option 1 (Recommended): Use django-cors-headers
------------------------------------------------
1. Install the package:
   pip install django-cors-headers

2. Add it to INSTALLED_APPS in settings.py:
   INSTALLED_APPS = [
       # ...
       'corsheaders',
       # ...
   ]

3. Add the middleware to MIDDLEWARE in settings.py (before CommonMiddleware):
   MIDDLEWARE = [
       # ...
       'corsheaders.middleware.CorsMiddleware',
       'django.middleware.common.CommonMiddleware',
       # ...
   ]

4. Configure CORS settings in settings.py:
   # CORS settings
   CORS_ALLOW_ALL_ORIGINS = True  # For development only
   CORS_ALLOW_CREDENTIALS = True

Option 2: Use this custom middleware
------------------------------------
If you can't install django-cors-headers, you can use this custom middleware:

1. Copy this file to your Django project (e.g., in the same directory as settings.py)

2. Add the middleware to MIDDLEWARE in settings.py:
   MIDDLEWARE = [
       # ...
       'yourapp.cors_middleware.CorsMiddleware',  # Adjust the path as needed
       'django.middleware.common.CommonMiddleware',
       # ...
   ]

3. Configure CORS settings in settings.py:
   CORS_ALLOWED_ORIGINS = [
       'http://localhost:60002',  # Flutter web app origin
       'http://127.0.0.1:60002',
       # Add other origins as needed
   ]

   CORS_ALLOWED_METHODS = [
       'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'
   ]

   CORS_ALLOWED_HEADERS = [
       'Authorization', 'Content-Type', 'X-Requested-With'
   ]
"""

from django.conf import settings
from django.http import HttpResponse


class CorsMiddleware:
    """Middleware to add CORS headers to responses."""

    def __init__(self, get_response):
        self.get_response = get_response
        # Get settings or use defaults
        self.allowed_origins = getattr(
            settings, 'CORS_ALLOWED_ORIGINS', ['*']
        )
        self.allowed_methods = getattr(
            settings, 'CORS_ALLOWED_METHODS', [
                'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'
            ]
        )
        self.allowed_headers = getattr(
            settings, 'CORS_ALLOWED_HEADERS', [
                'Authorization', 'Content-Type', 'X-Requested-With'
            ]
        )

    def __call__(self, request):
        # Handle preflight OPTIONS requests
        if request.method == 'OPTIONS':
            response = HttpResponse()
            self._add_cors_headers(response, request)
            return response

        # Process the request normally
        response = self.get_response(request)

        # Add CORS headers to the response
        self._add_cors_headers(response, request)

        return response

    def _add_cors_headers(self, response, request):
        """Add CORS headers to the response."""
        origin = request.META.get('HTTP_ORIGIN')

        # Check if the origin is allowed
        if origin and (origin in self.allowed_origins or '*' in self.allowed_origins):
            response['Access-Control-Allow-Origin'] = origin
        else:
            response['Access-Control-Allow-Origin'] = '*'

        response['Access-Control-Allow-Methods'] = ', '.join(self.allowed_methods)
        response['Access-Control-Allow-Headers'] = ', '.join(self.allowed_headers)
        response['Access-Control-Allow-Credentials'] = 'true'
        response['Access-Control-Max-Age'] = '86400'  # 24 hours
