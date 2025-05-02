# from rest_framework import serializers
# from .models import doc

# class PageSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = doc
#         fields = ['id', 'title', 'content', 'owner', 'created_at', 'updated_at']
#         read_only_fields = ['id', 'owner', 'created_at', 'updated_at']

from rest_framework import serializers
import json
from .models import Doc

class PageSerializer(serializers.ModelSerializer):
    # Define content as a JSONField with custom handling
    content = serializers.JSONField(required=False)
    parent_id = serializers.IntegerField(required=False, allow_null=True, write_only=True)
    subpages = serializers.SerializerMethodField()

    class Meta:
        model = Doc
        fields = ['id', 'title', 'content', 'owner', 'parent', 'parent_id', 'subpages', 'created_at', 'updated_at']
        read_only_fields = ['id', 'owner', 'created_at', 'updated_at', 'subpages']

    def get_subpages(self, instance):
        """Get direct subpages of this page"""
        # Get direct subpages
        subpages = instance.subpages.all().order_by('-created_at')
        # Return minimal data for each subpage to avoid recursion issues
        return [{'id': subpage.id, 'title': subpage.title} for subpage in subpages]

    def to_representation(self, instance):
        """Add parent_id to the serialized data for the frontend"""
        data = super().to_representation(instance)
        # Add parent_id field for the frontend
        data['parent_id'] = instance.parent.id if instance.parent else None

        # Debug the content field
        print(f"Serializing page: ID={instance.id}, Title='{instance.title}'")
        print(f"Content type: {type(instance.content)}")
        print(f"Content (truncated): {str(instance.content)[:100] if instance.content else 'None'}")

        # Ensure content is properly serialized
        if instance.content is not None:
            # If content is already a string, leave it as is
            if isinstance(instance.content, str):
                print("Content is already a string, keeping as is")
            # If content is a dict, convert it to a JSON string
            elif isinstance(instance.content, dict):
                print("Content is a dict, converting to JSON string")
                data['content'] = json.dumps(instance.content)

        return data

    def to_internal_value(self, data):
        """Handle content field parsing"""
        print(f"Processing input data: {data}")

        # Handle content field if it's a string that should be JSON
        if 'content' in data and isinstance(data['content'], str):
            try:
                # Try to parse the content as JSON
                content_str = data['content']
                print(f"Content is a string, attempting to parse as JSON: {content_str[:100]}...")
                parsed_content = json.loads(content_str)
                print(f"Successfully parsed content as JSON: {str(parsed_content)[:100]}...")
                data['content'] = parsed_content
            except json.JSONDecodeError as e:
                print(f"Error parsing content as JSON: {e}")
                # Keep the content as a string if it's not valid JSON

        return super().to_internal_value(data)

    def update(self, instance, validated_data):
        """Custom update method to handle parent_id field"""
        print(f"Updating page with validated data: {validated_data}")

        # Import Doc at the beginning of the method to ensure it's in scope
        from .models import Doc

        # Handle parent_id separately
        parent_id = validated_data.pop('parent_id', None)
        if parent_id is not None:
            try:
                # Get the parent page
                parent = Doc.objects.get(id=parent_id)
                validated_data['parent'] = parent
                print(f"Set parent to page with ID: {parent.id}, title: {parent.title}")
            except Doc.DoesNotExist:
                print(f"Parent page with ID {parent_id} not found")
                # Don't set parent if it doesn't exist
                pass

        # Update the instance with the remaining validated data
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance

    def create(self, validated_data):
        """Custom create method to handle parent_id field"""
        print(f"Creating page with validated data: {validated_data}")

        # Import Doc at the beginning of the method to ensure it's in scope
        from .models import Doc

        # Handle parent_id separately
        parent_id = validated_data.pop('parent_id', None)
        if parent_id is not None:
            try:
                # Get the parent page
                parent = Doc.objects.get(id=parent_id)
                validated_data['parent'] = parent
                print(f"Set parent to page with ID: {parent.id}, title: {parent.title}")
            except Doc.DoesNotExist:
                print(f"Parent page with ID {parent_id} not found")
                # Don't set parent if it doesn't exist
                pass

        # Create the instance with the remaining validated data
        return Doc.objects.create(**validated_data)
