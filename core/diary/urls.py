from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DiaryViewSet, DiaryImageViewSet

router = DefaultRouter()
router.register(r'entries', DiaryViewSet, basename='diary-entry')
router.register(r'images', DiaryImageViewSet, basename='diary-image')

urlpatterns = [
    path('', include(router.urls)),
]