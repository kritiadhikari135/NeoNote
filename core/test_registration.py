import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from accounts.models import EmailOtp, CustomUser
from django.utils import timezone

# Create a test OTP
email = 'test2@example.com'
otp_code = '123456'

# Create or update OTP
EmailOtp.objects.update_or_create(
    email=email,
    defaults={'otp': otp_code, 'created_at': timezone.now()}
)

print(f"Created OTP {otp_code} for {email}")

# Try to create a user with this OTP
try:
    # Check if user already exists
    if CustomUser.objects.filter(email=email).exists():
        print(f"User with email {email} already exists. Deleting...")
        CustomUser.objects.filter(email=email).delete()
    
    # Create user
    user = CustomUser.objects.create_user(
        email=email,
        full_name='Test User',
        password='testpassword'
    )
    print(f"User created successfully: {user}")
    
    # Clean up OTP
    EmailOtp.objects.filter(email=email).delete()
    print("OTP cleaned up")
    
except Exception as e:
    print(f"Error creating user: {e}")
