from rest_framework import serializers
from .models import CustomUser

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True}  # Ensure passwords are not readable in responses
        }

    def create(self, validated_data):
        """
        Create a new user instance with a hashed password.
        """
        password = validated_data.pop('password')
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



# for user profile

from rest_framework import serializers
from .models import CustomUser

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'full_name']  # Include id and full_name
