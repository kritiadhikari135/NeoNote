from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Q
from datetime import datetime, timedelta
from .models import CalendarEvent
from .serializers import CalendarEventSerializer

class CalendarEventViewSet(viewsets.ModelViewSet):
    """ViewSet for calendar events"""
    serializer_class = CalendarEventSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return events for the current user"""
        user = self.request.user
        return CalendarEvent.objects.filter(user=user)
    
    @action(detail=False, methods=['get'])
    def month(self, request):
        """Get events for a specific month"""
        try:
            year = int(request.query_params.get('year', datetime.now().year))
            month = int(request.query_params.get('month', datetime.now().month))
            
            # Get the first and last day of the month
            first_day = datetime(year, month, 1).date()
            if month == 12:
                last_day = datetime(year + 1, 1, 1).date() - timedelta(days=1)
            else:
                last_day = datetime(year, month + 1, 1).date() - timedelta(days=1)
            
            # Get events for the month
            events = self.get_queryset().filter(
                date__gte=first_day,
                date__lte=last_day
            )
            
            serializer = self.get_serializer(events, many=True)
            return Response(serializer.data)
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid year or month parameters"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['get'])
    def range(self, request):
        """Get events for a date range"""
        try:
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            
            if not start_date or not end_date:
                return Response(
                    {"error": "Both start_date and end_date are required"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
            end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
            
            events = self.get_queryset().filter(
                date__gte=start_date,
                date__lte=end_date
            )
            
            serializer = self.get_serializer(events, many=True)
            return Response(serializer.data)
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['get'])
    def day(self, request):
        """Get events for a specific day"""
        try:
            date_str = request.query_params.get('date')
            
            if not date_str:
                date_obj = datetime.now().date()
            else:
                date_obj = datetime.strptime(date_str, '%Y-%m-%d').date()
            
            events = self.get_queryset().filter(date=date_obj)
            
            serializer = self.get_serializer(events, many=True)
            return Response(serializer.data)
        except (ValueError, TypeError):
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
