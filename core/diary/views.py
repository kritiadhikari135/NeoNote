
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Diary, DiaryImage
from .serializers import DiarySerializer, DiaryImageSerializer


class DiaryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing diary entries.
    """
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Returns the list of diaries for the currently authenticated user.
        """
        user = self.request.user
        print(f"Getting diary entries for user: {user.email}")

        queryset = Diary.objects.filter(user=user)
        print(f"Found {queryset.count()} diary entries")

        # Debug the first entry if available
        if queryset.exists():
            first_entry = queryset.first()
            print(f"First entry: ID={first_entry.id}, Title='{first_entry.title}', Content='{first_entry.content[:50]}...'")

        return queryset

    def perform_create(self, serializer):
        print("Creating diary with data:", serializer.validated_data)  # Log the data
        try:
            # The user is already added in the serializer's create method
            instance = serializer.save()
            print(f"Successfully created diary with ID: {instance.id}")
        except Exception as e:
            print(f"Error creating diary: {e}")
            raise

    def update(self, request, *args, **kwargs):
        print("\n\nUpdate method called with data:", request.data)  # Log the data
        print("Request method:", request.method)
        print("Current user:", request.user.email)

        # Get the instance
        instance = self.get_object()
        print(f"Found diary with ID: {instance.id}, Title: '{instance.title}'")

        # Create a serializer with the instance and data
        serializer = self.get_serializer(instance, data=request.data, partial=True)

        # Validate the data
        try:
            serializer.is_valid(raise_exception=True)
            print("Validated data:", serializer.validated_data)
        except Exception as e:
            print(f"Validation error: {e}")
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # Save the instance
        try:
            self.perform_update(serializer)
            print(f"Successfully updated diary with ID: {instance.id}")
        except Exception as e:
            print(f"Error updating diary: {e}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response(serializer.data)

    def perform_update(self, serializer):
        print("Performing update with data:", serializer.validated_data)  # Log the data
        try:
            instance = serializer.save()
            print(f"Successfully updated diary with ID: {instance.id}")
        except Exception as e:
            print(f"Error updating diary: {e}")
            raise

    @action(detail=False, methods=['get'])
    def moods(self, request):
        """
        Returns the available mood choices.
        """
        return Response(dict(Diary.MOOD_CHOICES))

    @action(detail=False, methods=['get'])
    def templates(self, request):
        """
        Returns the available templates and their contents.
        """
        templates = [
            'Default',
            'Gratitude Journal',
            'Daily Reflection',
            'Travel Log',
            'Dream Journal'
        ]
        template_contents = {
            'Default': '',
            'Gratitude Journal': 'Today I am grateful for:\n1. \n2. \n3. \n\nOne positive thing that happened today: ',
            'Daily Reflection': 'Morning thoughts:\n\nMain achievements today:\n\nChallenges faced:\n\nLessons learned:',
            'Travel Log': 'Location: \nWeather: \nPlaces visited: \n\nHighlights: \n\nFood tried: \n\nMemories:',
            'Dream Journal': 'Dream summary: \n\nKey symbols: \n\nEmotions: \n\nPossible interpretations:'
        }
        return Response({
            'templates': templates,
            'template_contents': template_contents
        })


class DiaryImageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing diary images.
    """
    serializer_class = DiaryImageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Returns the list of images for diaries owned by the currently authenticated user.
        """
        user = self.request.user
        queryset = DiaryImage.objects.filter(diary__user=user)
        diary_id = self.request.query_params.get('diary_id')
        if diary_id:
            queryset = queryset.filter(diary_id=diary_id)
        return queryset

    def perform_create(self, serializer):
        """
        Automatically associate the diary image with the diary entry.
        """
        diary_id = self.request.data.get('diary')
        if not diary_id:
            return Response({'error': 'Diary ID is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            diary = Diary.objects.get(id=diary_id, user=self.request.user)
        except Diary.DoesNotExist:
            return Response({'error': 'Diary not found or not owned by the user'}, status=status.HTTP_404_NOT_FOUND)
        serializer.save(diary=diary)