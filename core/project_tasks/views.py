from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import ProjectTask
from .serializers import ProjectTaskSerializer
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

    def perform_create(self, serializer):
        """ Sets the project and created_by user automatically """
        project_id = self.kwargs['project_pk']
        serializer.save(project_id=project_id, created_by=self.request.user)