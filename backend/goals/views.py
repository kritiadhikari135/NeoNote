from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Goal, Task
from .serializers import GoalSerializer, TaskSerializer

class GoalViewSet(viewsets.ModelViewSet):
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all the goals
        for the currently authenticated user.
        """
        user = self.request.user
        return Goal.objects.filter(user=user)
    
    def perform_create(self, serializer):
        """
        Override this method to associate the created goal with the authenticated user.
        """
        serializer.save(user=self.request.user, created_by=self.request.user.email)

    def perform_update(self, serializer):
        """
        Override this method to ensure the goal remains associated with the authenticated user.
        """
        serializer.save(user=self.request.user, last_modified_by=self.request.user.email)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Task.objects.all()
        goal_id = self.request.query_params.get('goal_id')
        if goal_id is not None:
            queryset = queryset.filter(goal_id=goal_id)
        return queryset
    
    def perform_create(self, serializer):
        # Automatically set the user and created_by fields
        serializer.save(
            user=self.request.user,
            created_by=self.request.user.email,
        )
    
    def perform_update(self, serializer):
        # Preserve the goal and user fields during updates
        serializer.save(goal=serializer.instance.goal, user=serializer.instance.user)


class GoalTasksView(APIView):
    def get(self, request, goal_id):
        active_tasks = Task.objects.filter(goal_id=goal_id).exclude(status='completed')
        completed_tasks = Task.objects.filter(goal_id=goal_id, status='completed')

        # Use the updated TaskSerializer that includes reminder fields
        active_serializer = TaskSerializer(active_tasks, many=True)
        completed_serializer = TaskSerializer(completed_tasks, many=True)

        return Response({
            "active_tasks": active_serializer.data,
            "completed_tasks": completed_serializer.data
        })
