# from django.urls import path, include
# from rest_framework.routers import DefaultRouter
# from .views import ProjectViewSet, TeamInvitationViewSet

# router = DefaultRouter()
# router.register(r'projects', ProjectViewSet, basename='project')
# router.register(r'invitations', TeamInvitationViewSet, basename='invitation')

# urlpatterns = [
#     path('', include(router.urls)),
# ]


# ============================================================================================================

from django.urls import path, include
from rest_framework.routers import DefaultRouter
# Use nested routers
from rest_framework_nested import routers
from .views import ProjectViewSet, TeamInvitationViewSet
from project_tasks.urls import project_task_router # Import the project_task router

router = DefaultRouter()
router = routers.DefaultRouter()
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'invitations', TeamInvitationViewSet, basename='invitation')

# Create a nested router for tasks under projects
projects_router = routers.NestedSimpleRouter(router, r'projects', lookup='project')
projects_router.register(r'tasks', project_task_router.registry[0][1], basename='project-tasks')

urlpatterns = [
    path('', include(router.urls)),
    path('', include(projects_router.urls)), # Include the nested task URLs
]

