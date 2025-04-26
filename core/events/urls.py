from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CalendarEventViewSet

# Try to import the API views if they exist
try:
    from .api_views import CalendarEventAPIViewSet
    has_api_views = True
except ImportError:
    has_api_views = False

# Router for the original viewset
router = DefaultRouter()
router.register(r'events', CalendarEventViewSet, basename='calendar-events')

urlpatterns = [
    path('', include(router.urls)),
]

# Add API endpoint if API views exist
if has_api_views:
    api_router = DefaultRouter()
    api_router.register(r'api/events', CalendarEventAPIViewSet, basename='api-calendar-events')
    urlpatterns += [
        path('', include(api_router.urls)),  # Add API endpoint
    ]
