from rest_framework import serializers
from .models import ProjectTask
from accounts.serializers import CustomUserSerializer # Use your existing user serializer
from work.models import Project # Needed for validation
from accounts.models import CustomUser # Import the CustomUser model

class ProjectTaskSerializer(serializers.ModelSerializer):
    """
    Serializer for the ProjectTask model.
    """
    created_by = CustomUserSerializer(read_only=True)
    assigned_to = CustomUserSerializer(read_only=True) # Display assigned user details
    assigned_to_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(), source='assigned_to', write_only=True, allow_null=True, required=False
    ) # Allow assigning by user ID

    class Meta:
        model = ProjectTask
        fields = [
            'id', 'project', 'title',  'priority', 'due_date',
            'created_by', 'assigned_to', 'assigned_to_id', 'date_created'
        ]
        read_only_fields = ['project', 'created_by', 'date_created']

    # Optional: Add validation to ensure assigned_to user is a member of the project
    # def validate(self, data): ...