from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Notification
from .serializers import NotificationSerializer
import logging

# Set up logging
logger = logging.getLogger(__name__)

class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing notifications.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return notifications for the current user"""
        return Notification.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        """Set the user when creating a notification"""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get the count of unread notifications"""
        count = self.get_queryset().filter(is_read=False).count()
        return Response({'unread_count': count})

    @action(detail=False, methods=['get'])
    def unread_invitation_responses(self, request):
        """Get the count of unread invitation response notifications"""
        count = self.get_queryset().filter(
            is_read=False,
            notification_type__in=['invitation_accepted', 'invitation_rejected']
        ).count()
        return Response({'count': count})

    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """Mark all notifications as read"""
        self.get_queryset().update(is_read=True)
        return Response({'status': 'All notifications marked as read'})

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark a specific notification as read"""
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'Notification marked as read'})

    @action(detail=False, methods=['delete'])
    def delete_all(self, request):
        """Delete all notifications"""
        self.get_queryset().delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['delete'], url_path='delete')
    def delete_notification(self, request, pk=None):
        """Delete a specific notification"""
        notification = self.get_object()
        if notification.user != request.user:
            return Response(
                {'error': 'You do not have permission to delete this notification'},
                status=status.HTTP_403_FORBIDDEN
            )
        notification.delete()
        return Response(
            {'message': 'Notification deleted successfully'},
            status=status.HTTP_200_OK
        )

    def list(self, request, *args, **kwargs):
        """Override list to handle missing user data"""
        logger.info(f"Received request to list notifications for user: {request.user}")
        if not request.user.is_authenticated:
            logger.warning("User not authenticated. Returning 401 Unauthorized.")
            return Response({'error': 'User not authenticated. Please log in.'}, status=status.HTTP_401_UNAUTHORIZED)
        return super().list(request, *args, **kwargs)
