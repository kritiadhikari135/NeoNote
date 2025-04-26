from rest_framework import serializers
from .models import Diary, DiaryImage

class DiaryImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiaryImage
        fields = ['id', 'diary', 'image', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at']

# class DiarySerializer(serializers.ModelSerializer):
#     images = DiaryImageSerializer(many=True, read_only=True)  # Nested serializer for related images

#     class Meta:
#         model = Diary
#         fields = [
#             'id', 'title', 'content', 'date', 'mood', 'background_color',
#             'text_color', 'template', 'created_at', 'updated_at', 'images'
#         ]
#         read_only_fields = ['id', 'created_at', 'updated_at']

    # def create(self, validated_data):
    #     # Pop 'user' from validated_data if it's already provided; otherwise, use the request's user
    #     user = validated_data.pop('user', self.context['request'].user)

    #     # Optional: Set defaults if not provided
    #     validated_data['mood'] = validated_data.get('mood', '')
    #     validated_data['background_color'] = validated_data.get('background_color', 0xFFFFFF)
    #     validated_data['text_color'] = validated_data.get('text_color', 0x000000)
    #     validated_data['template'] = validated_data.get('template', 'Default')

    #     return Diary.objects.create(user=user, **validated_data)

class DiarySerializer(serializers.ModelSerializer):
    # Use a nested serializer for images with many=True, read_only=True, and required=False
    images = DiaryImageSerializer(many=True, read_only=True, required=False)

    class Meta:
        model = Diary
        fields = [
            'id', 'title', 'content', 'date', 'mood', 'background_color',
            'text_color', 'template', 'created_at', 'updated_at', 'images'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_representation(self, instance):
        """Override to add debugging for title and content"""
        print(f"Serializing diary entry: ID={instance.id}, Title='{instance.title}', Content='{instance.content[:50]}...'")
        data = super().to_representation(instance)
        print(f"Serialized data: {data}")
        return data

    def validate_background_color(self, value):
        if value is None:
            print('Background color is None, defaulting to white')
            return 0xFFFFFF  # Default to white
        try:
            int_value = int(value)  # Ensure it's an integer
            print(f'Validated background_color: {int_value}')
            return int_value
        except (TypeError, ValueError) as e:
            print(f'Error validating background_color: {e}, defaulting to white')
            return 0xFFFFFF  # Default to white if conversion fails

    def validate_text_color(self, value):
        if value is None:
            print('Text color is None, defaulting to black')
            return 0x000000  # Default to black
        try:
            int_value = int(value)  # Ensure it's an integer
            print(f'Validated text_color: {int_value}')
            return int_value
        except (TypeError, ValueError) as e:
            print(f'Error validating text_color: {e}, defaulting to black')
            return 0x000000  # Default to black if conversion fails

    def create(self, validated_data):
        user = self.context['request'].user
        print(f'Creating diary entry for user: {user.email}')
        # Make a copy of validated_data to avoid modifying the original
        validated_data = dict(validated_data)
        print(f'Initial validated data: {validated_data}')

        validated_data['mood'] = validated_data.get('mood', '')  # Default to empty string

        # Ensure background_color and text_color are integers and not null
        if validated_data.get('background_color') is None:
            print('background_color is None in create, defaulting to white')
            validated_data['background_color'] = 0xFFFFFF  # Default to white
        else:
            try:
                bg_color = int(validated_data['background_color'])
                validated_data['background_color'] = bg_color
                print(f'Set background_color to {bg_color} in create')
            except (TypeError, ValueError) as e:
                print(f'Error converting background_color in create: {e}')
                validated_data['background_color'] = 0xFFFFFF  # Default to white

        if validated_data.get('text_color') is None:
            print('text_color is None in create, defaulting to black')
            validated_data['text_color'] = 0x000000  # Default to black
        else:
            try:
                txt_color = int(validated_data['text_color'])
                validated_data['text_color'] = txt_color
                print(f'Set text_color to {txt_color} in create')
            except (TypeError, ValueError) as e:
                print(f'Error converting text_color in create: {e}')
                validated_data['text_color'] = 0x000000  # Default to black

        validated_data['template'] = validated_data.get('template', 'Default')  # Default to 'Default'
        # Add the user to validated_data
        validated_data['user'] = user
        print(f'Final validated data for create: {validated_data}')
        return Diary.objects.create(**validated_data)

    def update(self, instance, validated_data):
        print(f'Updating diary entry with ID: {instance.id}')
        print(f'Initial validated data for update: {validated_data}')

        validated_data['mood'] = validated_data.get('mood', instance.mood or '')  # Default to empty string

        # Ensure background_color and text_color are integers and not null
        if validated_data.get('background_color') is None:
            print(f'background_color is None in update, using instance value: {instance.background_color}')
            validated_data['background_color'] = instance.background_color or 0xFFFFFF
        else:
            try:
                bg_color = int(validated_data['background_color'])
                validated_data['background_color'] = bg_color
                print(f'Set background_color to {bg_color} in update')
            except (TypeError, ValueError) as e:
                print(f'Error converting background_color in update: {e}')
                validated_data['background_color'] = instance.background_color or 0xFFFFFF

        if validated_data.get('text_color') is None:
            print(f'text_color is None in update, using instance value: {instance.text_color}')
            validated_data['text_color'] = instance.text_color or 0x000000
        else:
            try:
                txt_color = int(validated_data['text_color'])
                validated_data['text_color'] = txt_color
                print(f'Set text_color to {txt_color} in update')
            except (TypeError, ValueError) as e:
                print(f'Error converting text_color in update: {e}')
                validated_data['text_color'] = instance.text_color or 0x000000

        validated_data['template'] = validated_data.get('template', instance.template or 'Default')  # Default to 'Default'
        print(f'Final validated data for update: {validated_data}')
        return super().update(instance, validated_data)