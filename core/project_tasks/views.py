from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.parsers import MultiPartParser, FormParser
from .models import ProjectTask, TaskSubmission
from .serializers import ProjectTaskSerializer, TaskSubmissionSerializer
from work.models import Project # Import Project to check membership/ownership

class IsProjectMemberOrOwner(permissions.BasePermission):
    """
    Custom permission to only allow project members or the owner to view/edit tasks.
    Adjust based on your exact permission needs (e.g., can only assigned user modify?).
    """
    def has_permission(self, request, view):
        project_id = view.kwargs.get('project_pk')
        if not project_id:
            return False
        try:
            project = Project.objects.get(pk=project_id)
            # Check if the user is the owner or a member
            return project.user == request.user or request.user in project.members.all()
        except Project.DoesNotExist:
            return False

    # Optional: Implement has_object_permission for finer control (e.g., only creator/assignee can edit)
    # def has_object_permission(self, request, view, obj): ...

class ProjectTaskViewSet(viewsets.ModelViewSet):
    """
    API endpoint for tasks associated with a specific project.
    """
    serializer_class = ProjectTaskSerializer
    permission_classes = [permissions.IsAuthenticated, IsProjectMemberOrOwner]

    def get_queryset(self):
        """ Filter tasks by the project_pk from the URL """
        project_id = self.kwargs['project_pk']
        return ProjectTask.objects.filter(project_id=project_id)

    def list(self, request, *args, **kwargs):
        """ Override list method to separate active and completed tasks """
        project_id = self.kwargs['project_pk']
        queryset = ProjectTask.objects.filter(project_id=project_id)

        active_tasks = queryset.exclude(status="completed")
        completed_tasks = queryset.filter(status="completed")

        return Response({
            "active_tasks": ProjectTaskSerializer(active_tasks, many=True).data,
            "completed_tasks": ProjectTaskSerializer(completed_tasks, many=True).data
        })

    def perform_create(self, serializer):
        """ Sets the project and created_by user automatically """
        project_id = self.kwargs['project_pk']
        # Set completed field based on status
        status_value = serializer.validated_data.get('status', 'pending')
        completed = status_value == 'completed'
        serializer.save(
            project_id=project_id,
            created_by=self.request.user,
            completed=completed
        )

    def perform_update(self, serializer):
        """ Update the completed field based on status """
        status_value = serializer.validated_data.get('status')
        if status_value:
            completed = status_value == 'completed'
            serializer.save(completed=completed)
        else:
            serializer.save()

    @action(detail=True, methods=['get'])
    def submissions(self, request, project_pk=None, pk=None):
        """
        Get all submissions for a specific task
        """
        task = self.get_object()
        submissions = TaskSubmission.objects.filter(task=task)
        serializer = TaskSubmissionSerializer(submissions, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def submit(self, request, project_pk=None, pk=None):
        """
        Submit a file for a specific task
        """
        task = self.get_object()

        # Get the uploaded file
        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response(
                {'error': 'No file was submitted'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create submission
        submission = TaskSubmission(
            task=task,
            submitted_by=request.user,
            file=file_obj,
            file_name=file_obj.name,
            file_type=file_obj.content_type,
            comment=request.data.get('comment', '')
        )
        submission.save()

        serializer = TaskSubmissionSerializer(submission)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class TaskSubmissionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for task submissions (read-only).
    """
    serializer_class = TaskSubmissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Filter submissions by task_id if provided
        """
        task_id = self.request.query_params.get('task_id')
        if task_id:
            return TaskSubmission.objects.filter(task_id=task_id)
        return TaskSubmission.objects.none()  # Return empty queryset if no task_id