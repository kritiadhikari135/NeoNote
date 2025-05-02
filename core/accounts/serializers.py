from rest_framework import serializers
from .models import CustomUser

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name', 'email', 'password', 'is_active', 'is_staff']
        extra_kwargs = {
            'password': {'write_only': True},  # Ensure passwords are not readable in responses
            'is_active': {'default': True, 'read_only': True},  # Set default value and make read-only
            'is_staff': {'default': False, 'read_only': True}   # Set default value and make read-only
        }

    def create(self, validated_data):
        """
        Create a new user instance with a hashed password.
        """
        password = validated_data.pop('password')
        # Ensure is_active is set to True
        validated_data['is_active'] = True
        user = CustomUser(**validated_data)
        user.set_password(password)  # Hash the password before saving
        user.save()
        return user

    def update(self, instance, validated_data):
        """
        Update an existing user instance. Handles password hashing if it's updated.
        """
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)  # Hash the password if updated
        instance.save()
        return instance

class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile information.
    """
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name', 'email', 'is_active', 'is_staff', 'date_joined']
        read_only_fields = ['id', 'email', 'is_active', 'is_staff', 'date_joined']



# for user profile

from rest_framework import serializers
from .models import CustomUser

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name']  # Include id and full_name
