from rest_framework_nested import routers
from django.urls import path, include
from .views import ProjectTaskViewSet, TaskSubmissionViewSet

# This router will be registered under the project router in work/urls.py
# It expects 'project_pk' from the parent router.
project_task_router = routers.SimpleRouter()
project_task_router.register(r'tasks', ProjectTaskViewSet, basename='project-tasks')

# Create a router for task submissions
submission_router = routers.SimpleRouter()
submission_router.register(r'task-submissions', TaskSubmissionViewSet, basename='task-submissions')

# Add additional URL patterns if needed
urlpatterns = [
    path('', include(submission_router.urls)),
]

# The project_task_router will be included by the parent router in work/urls.py