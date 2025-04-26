# from rest_framework import serializers
# from .models import doc

# class PageSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = doc
#         fields = ['id', 'title', 'content', 'owner', 'created_at', 'updated_at']
#         read_only_fields = ['id', 'owner', 'created_at', 'updated_at']

from rest_framework import serializers
from .models import Doc

class PageSerializer(serializers.ModelSerializer):
    # Optionally, define content explicitly as a JSONField.
    content = serializers.JSONField(required=False)

    class Meta:
        model = Doc
        fields = ['id', 'title', 'content', 'owner', 'created_at', 'updated_at']
        read_only_fields = ['id', 'owner', 'created_at', 'updated_at']
