
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]  # Ensure only logged-in users can access tasks

    def get_queryset(self):
        return Task.objects.filter(user=self.request.user).order_by('-date_created')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)  # Set the task's user to the logged-in user

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        active_tasks = queryset.exclude(status="completed")
        completed_tasks = queryset.filter(status="completed")

        return Response({
            "active_tasks": TaskSerializer(active_tasks, many=True).data,
            "completed_tasks": TaskSerializer(completed_tasks, many=True).data
        })