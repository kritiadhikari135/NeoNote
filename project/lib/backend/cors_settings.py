"""
Django CORS Settings

This file contains the recommended CORS settings for your Django project.
Copy these settings to your settings.py file.
"""

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True  # For development only
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# For production, specify allowed origins instead of allowing all origins
# CORS_ALLOWED_ORIGINS = [
#     "http://localhost:60002",
#     "http://127.0.0.1:60002",
#     "https://yourdomain.com",
# ]

# Add corsheaders to INSTALLED_APPS
# INSTALLED_APPS = [
#     ...
#     'corsheaders',
#     ...
# ]

# Add CORS middleware to MIDDLEWARE (before CommonMiddleware)
# MIDDLEWARE = [
#     ...
#     'corsheaders.middleware.CorsMiddleware',
#     'django.middleware.common.CommonMiddleware',
#     ...
# ]
