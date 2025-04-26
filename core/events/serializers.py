from rest_framework import serializers
from .models import CalendarEvent

class CalendarEventSerializer(serializers.ModelSerializer):
    """Serializer for calendar events"""
    color_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CalendarEvent
        fields = ['id', 'title', 'description', 'date', 'start_time', 'end_time', 
                  'color', 'color_name', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_color_name(self, obj):
        """Map hex color to a color name for easier frontend handling"""
        color_map = {
            '#3788d8': 'blue',
            '#d83737': 'red',
            '#37d874': 'green',
            '#d8a737': 'orange',
            '#9437d8': 'purple',
            '#37d8c7': 'teal',
        }
        return color_map.get(obj.color, 'blue')
    
    def create(self, validated_data):
        """Create a new event with the current user"""
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)
