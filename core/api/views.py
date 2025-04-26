

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


from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Doc
from .serializers import PageSerializer

class PageViewSet(viewsets.ModelViewSet):
    serializer_class = PageSerializer
    permission_classes = [IsAuthenticated] 

    def get_queryset(self):
        print(f"Current user: {self.request.user}")  # Debugging line
        return Doc.objects.filter(owner=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        print(f"Creating page for user: {self.request.user}")
        serializer.save(owner=self.request.user)
