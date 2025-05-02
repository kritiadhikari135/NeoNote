from rest_framework import serializers
from .models import Notification
from django.utils import timezone

class NotificationSerializer(serializers.ModelSerializer):
    remaining_time = serializers.SerializerMethodField()
    formatted_due_date_time = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'title', 'message', 'notification_type', 
            'created_at', 'due_date_time', 'is_read', 'source_id',
            'remaining_time', 'formatted_due_date_time', 'is_past_due'
        ]
        read_only_fields = ['user', 'created_at']
    
    def get_remaining_time(self, obj):
        """Calculate remaining time until the notification is due"""
        if not obj.due_date_time:
            return ''
            
        now = timezone.now()
        if obj.due_date_time < now:
            return 'Overdue'
            
        difference = obj.due_date_time - now
        
        days = difference.days
        hours, remainder = divmod(difference.seconds, 3600)
        minutes, _ = divmod(remainder, 60)
        
        if days > 0:
            return f"{days} day{'s' if days > 1 else ''} remaining"
        elif hours > 0:
            return f"{hours} hour{'s' if hours > 1 else ''} remaining"
        elif minutes > 0:
            return f"{minutes} minute{'s' if minutes > 1 else ''} remaining"
        else:
            return "Due now"
    
    def get_formatted_due_date_time(self, obj):
        """Format the due date and time"""
        if not obj.due_date_time:
            return ''
        return obj.due_date_time.strftime('%b %d, %Y - %I:%M %p')
