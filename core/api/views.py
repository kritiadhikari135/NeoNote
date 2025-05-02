

# from rest_framework import viewsets
# from rest_framework.permissions import IsAuthenticated
# from .models import doc
# from .serializers import PageSerializer

# class PageViewSet(viewsets.ModelViewSet):
#     serializer_class = PageSerializer
#     permission_classes = [IsAuthenticated]

#     # def get_queryset(self):
#     #     return doc.objects.filter(owner=self.request.user).order_by('-created_at')
#     def get_queryset(self):
#         print(f"Current user: {self.request.user}")  # Debugging line
#         return doc.objects.filter(owner=self.request.user).order_by('-created_at')


#     def perform_create(self, serializer):
#         print(f"Creating page for user: {self.request.user}")
#         serializer.save(owner=self.request.user)


from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import json
from .models import Doc
from .serializers import PageSerializer

class PageViewSet(viewsets.ModelViewSet):
    serializer_class = PageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        print(f"Current user: {self.request.user}")  # Debugging line
        return Doc.objects.filter(owner=self.request.user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        print(f"Creating page for user: {request.user}")
        print(f"Request data: {request.data}")

        try:
            # Check if parent_id is provided
            parent_id = request.data.get('parent_id')
            if parent_id:
                print(f"Parent ID provided: {parent_id}")
                try:
                    # Ensure the parent page exists and belongs to the current user
                    parent = Doc.objects.get(id=parent_id, owner=request.user)
                    print(f"Found parent page with ID: {parent.id}, title: {parent.title}")

                    # Check if this would create a deeper nesting than allowed
                    nesting_level = 1  # Start with this new page
                    current_parent = parent
                    max_nesting = 5  # Maximum allowed nesting level

                    while current_parent.parent is not None:
                        nesting_level += 1
                        if nesting_level > max_nesting:
                            print(f"Error: Maximum nesting level ({max_nesting}) exceeded")
                            return Response(
                                {"error": f"Maximum nesting level ({max_nesting}) exceeded"},
                                status=status.HTTP_400_BAD_REQUEST
                            )
                        current_parent = current_parent.parent

                except Doc.DoesNotExist:
                    print(f"Parent page with ID {parent_id} not found or doesn't belong to user")
                    return Response(
                        {"error": "Parent page not found"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Get the serializer with the request data
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)

            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED,
                headers=headers
            )

        except Exception as e:
            print(f"Error creating page: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def perform_create(self, serializer):
        print(f"Performing create for user: {self.request.user}")
        # Save the page with the current user as owner
        instance = serializer.save(owner=self.request.user)
        print(f"Created page with ID: {instance.id}, title: {instance.title}")
        print(f"Content type: {type(instance.content)}")
        print(f"Content (truncated): {str(instance.content)[:100] if instance.content else 'None'}")

    def update(self, request, *args, **kwargs):
        print(f"Updating page with ID: {kwargs.get('pk')}")
        print(f"Request data: {request.data}")

        try:
            # Get the instance
            instance = self.get_object()
            print(f"Found page with ID: {instance.id}, title: {instance.title}")
            print(f"Current content type: {type(instance.content)}")
            print(f"Current content (truncated): {str(instance.content)[:100] if instance.content else 'None'}")

            # Check if parent_id is provided
            parent_id = request.data.get('parent_id')
            if parent_id:
                print(f"Parent ID provided: {parent_id}")

                # Check for circular reference
                if int(kwargs.get('pk')) == int(parent_id):
                    print("Error: Circular reference detected - page cannot be its own parent")
                    return Response(
                        {"error": "A page cannot be its own parent"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

                try:
                    # Ensure the parent page exists and belongs to the current user
                    parent = Doc.objects.get(id=parent_id, owner=request.user)
                    print(f"Found parent page with ID: {parent.id}, title: {parent.title}")

                    # Check if this would create a deeper nesting than allowed
                    nesting_level = 1  # Start with this page
                    current_parent = parent
                    max_nesting = 5  # Maximum allowed nesting level

                    while current_parent.parent is not None:
                        nesting_level += 1
                        if nesting_level > max_nesting:
                            print(f"Error: Maximum nesting level ({max_nesting}) exceeded")
                            return Response(
                                {"error": f"Maximum nesting level ({max_nesting}) exceeded"},
                                status=status.HTTP_400_BAD_REQUEST
                            )
                        current_parent = current_parent.parent

                except Doc.DoesNotExist:
                    print(f"Parent page with ID {parent_id} not found or doesn't belong to user")
                    return Response(
                        {"error": "Parent page not found"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Get the serializer with the request data
            serializer = self.get_serializer(instance, data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_update(serializer)

            print(f"Updated page with ID: {instance.id}")
            print(f"New content type: {type(instance.content)}")
            print(f"New content (truncated): {str(instance.content)[:100] if instance.content else 'None'}")

            return Response(serializer.data)

        except Exception as e:
            print(f"Error updating page: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def perform_update(self, serializer):
        instance = serializer.save()
        print(f"Performed update for page with ID: {instance.id}")
        print(f"Updated content type: {type(instance.content)}")
        print(f"Updated content (truncated): {str(instance.content)[:100] if instance.content else 'None'}")
