from rest_framework import serializers
from .models import Project, TeamInvitation
from django.contrib.auth import get_user_model
from accounts.serializers import CustomUserSerializer

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name']

class ProjectSerializer(serializers.ModelSerializer):
    owner = UserSerializer(source='user', read_only=True)
    members = CustomUserSerializer(many=True, read_only=True)
    is_hosted_by_user = serializers.SerializerMethodField()  # Add this field

    class Meta:
        model = Project
        fields = ['id', 'name', 'description', 'created_at', 'updated_at', 'owner', 'members', 'is_hosted_by_user']
        read_only_fields = ['user', 'created_at', 'updated_at']

    def get_is_hosted_by_user(self, obj):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            return obj.user == request.user
        return False

class TeamInvitationSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    project = ProjectSerializer(read_only=True)
    project_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = TeamInvitation
        fields = ['id', 'project', 'project_id', 'sender', 'recipient', 'recipient_email', 
                 'status', 'created_at', 'updated_at']
        read_only_fields = ['sender', 'status', 'created_at', 'updated_at']

    def validate_recipient_email(self, value):
        if CustomUser.objects.filter(email=value).exists():
            return value
        # Log the validation error
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Validation failed: User with email {value} does not exist")
        raise serializers.ValidationError("User with this email does not exist.")
