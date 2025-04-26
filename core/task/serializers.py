from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'  # Serialize all fields
        read_only_fields = ['id', 'user', 'date_created']  # Prevent modification of these fields
