from rest_framework import serializers
from .models import Goal, Task
from accounts.models import CustomUser


class GoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Goal
        fields = [
            'id', 'title', 'start_date', 'completion_date', 'is_completed',
            'completion_time', 'has_reminder', 'reminder_date_time', 'user',
            'created_by', 'created_at', 'last_modified_by', 'last_modified_at'
        ]
        read_only_fields = ['user', 'created_by', 'created_at', 'last_modified_by', 'last_modified_at']


class TaskSerializer(serializers.ModelSerializer):
    goal = serializers.PrimaryKeyRelatedField(queryset=Goal.objects.all())  # Allow goal to be writable
    user = serializers.PrimaryKeyRelatedField(read_only=True)  # Keep user as read-only

    class Meta:
        model = Task
        fields = [
            'id', 'title', 'goal', 'status', 'priority', 'due_date', 'user',
            'created_by', 'date_created', 'has_reminder', 'reminder_date_time'
        ]
