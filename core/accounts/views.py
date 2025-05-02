# from rest_framework import status, generics
# from rest_framework.response import Response
# from rest_framework_simplejwt.tokens import RefreshToken
# from rest_framework.views import APIView
# from rest_framework.permissions import AllowAny, IsAuthenticated
# from django.core.exceptions import ValidationError
# from django.db import transaction
# from .models import CustomUser, EmailOtp
# from .serializers import CustomUserSerializer, UserSerializer

# import logging

# # Set up logging
# logger = logging.getLogger(__name__)

# class SendOTPView(APIView):
#     """
#     View to send OTP to the user's email.
#     """
#     permission_classes = [AllowAny]

#     def post(self, request, *args, **kwargs):
#         email = request.data.get('email')

#         if not email:
#             return Response(
#                 {"detail": "Email is required."},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         try:
#             # Generate and send OTP
#             otp = OTP.generate_otp(email)

#             # Log success but don't include the OTP in the response for security
#             logger.info(f"OTP sent successfully to {email}")

#             return Response(
#                 {"detail": "OTP sent successfully to your email."},
#                 status=status.HTTP_200_OK
#             )
#         except Exception as e:
#             logger.error(f"Error sending OTP to {email}: {str(e)}")
#             return Response(
#                 {"detail": f"Failed to send OTP: {str(e)}"},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )

# class VerifyOTPView(APIView):
#     """
#     View to verify OTP before registration.
#     """
#     permission_classes = [AllowAny]

#     def post(self, request, *args, **kwargs):
#         email = request.data.get('email')
#         otp_code = request.data.get('otp')

#         if not email or not otp_code:
#             return Response(
#                 {"detail": "Email and OTP are required."},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         # Verify OTP
#         if OTP.verify_otp(email, otp_code):
#             return Response(
#                 {"detail": "OTP verified successfully."},
#                 status=status.HTTP_200_OK
#             )
#         else:
#             return Response(
#                 {"detail": "Invalid or expired OTP."},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

# class RegisterUserView(generics.CreateAPIView):
#     """
#     View to register a new user.
#     """
#     queryset = CustomUser.objects.all()
#     serializer_class = CustomUserSerializer
#     permission_classes = [AllowAny]  # No authentication required for registration

#     def create(self, request, *args, **kwargs):
#         # Extract OTP from request data
#         otp_code = request.data.get('otp')
#         email = request.data.get('email')

#         # If OTP is provided, verify it
#         if otp_code and email:
#             if not OTP.verify_otp(email, otp_code):
#                 return Response(
#                     {"detail": "Invalid or expired OTP."},
#                     status=status.HTTP_400_BAD_REQUEST
#                 )

#         # Proceed with user registration
#         return super().create(request, *args, **kwargs)

# class LoginUserView(generics.GenericAPIView):
#     """
#     View to login and create a token for the user.
#     """
#     serializer_class = CustomUserSerializer
#     permission_classes = [AllowAny]  # No authentication required for login

#     def post(self, request, *args, **kwargs):
#         email = request.data.get('email')
#         password = request.data.get('password')

#         try:
#             user = CustomUser.objects.get(email=email)
#         except CustomUser.DoesNotExist:
#             return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)

#         if not user.check_password(password):
#             return Response({"detail": "Invalid credentials."}, status=status.HTTP_400_BAD_REQUEST)

#         refresh = RefreshToken.for_user(user)
#         access_token = refresh.access_token
#         # Print access token in the terminal
#         print(f"\n[DEBUG] Access Token for {email}: {access_token}\n")
#         logger.info(f"Access Token for {email}: {access_token}")

#         return Response({
#             "refresh": str(refresh),
#             "access": str(access_token),
#         })

# class UserProfileView(APIView):
#     permission_classes = [IsAuthenticated]  # Ensure only authenticated users can access this view

#     def get(self, request):
#         user = request.user  # `request.user` is the currently authenticated user
#         serializer = UserSerializer(user)
#         return Response(serializer.data)

# ======================================================================================================================================


# from rest_framework import status, generics
# from rest_framework.response import Response
# from rest_framework_simplejwt.tokens import RefreshToken
# from .models import CustomUser
# from .serializers import CustomUserSerializer
# from rest_framework.permissions import AllowAny

# import logging

# # Set up logging
# logger = logging.getLogger(__name__)

# class RegisterUserView(generics.CreateAPIView):
#     """
#     View to register a new user.
#     """
#     queryset = CustomUser.objects.all()
#     serializer_class = CustomUserSerializer
#     permission_classes = [AllowAny]  # No authentication required for registration


# class LoginUserView(generics.GenericAPIView):
#     """
#     View to login and create a token for the user.
#     """
#     serializer_class = CustomUserSerializer
#     permission_classes = [AllowAny]  # No authentication required for login

#     def post(self, request, *args, **kwargs):
#         email = request.data.get('email')
#         password = request.data.get('password')

#         try:
#             user = CustomUser.objects.get(email=email)
#         except CustomUser.DoesNotExist:
#             return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)

#         if not user.check_password(password):
#             return Response({"detail": "Invalid credentials."}, status=status.HTTP_400_BAD_REQUEST)

#         refresh = RefreshToken.for_user(user)
#         access_token = refresh.access_token
#         # Print access token in the terminal
#         print(f"\n[DEBUG] Access Token for {email}: {access_token}\n")
#         logger.info(f"Access Token for {email}: {access_token}")

#         return Response({
#             "refresh": str(refresh),
#             "access": str(access_token),
#         })


# # views.py

# from rest_framework.permissions import IsAuthenticated
# from rest_framework.views import APIView
# from rest_framework.response import Response
# from .models import CustomUser
# from .serializers import UserSerializer

# class UserProfileView(APIView):
#     permission_classes = [IsAuthenticated]  # Ensure only authenticated users can access this view

#     def get(self, request):
#         user = request.user  # `request.user` is the currently authenticated user
#         serializer = UserSerializer(user)
#         return Response(serializer.data)


from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CustomUser, EmailOtp  # Added EmailOtp model
from .serializers import CustomUserSerializer, UserSerializer
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone

import random
import logging

# Set up logging
logger = logging.getLogger(__name__)

# -------------------- EXISTING REGISTER --------------------
class RegisterUserView(generics.CreateAPIView):
    """
    View to register a new user after OTP verification.
    """
    queryset = CustomUser.objects.all()
    serializer_class = CustomUserSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        logger.info(f"Registration request received: {request.data}")
        print(f"Registration request received: {request.data}")

        email = request.data.get('email')
        full_name = request.data.get('full_name')
        password = request.data.get('password')
        otp = request.data.get('otp')

        logger.info(f"Extracted data - Email: {email}, Full Name: {full_name}, OTP: {otp}")
        print(f"Extracted data - Email: {email}, Full Name: {full_name}, OTP: {otp}")

        if not all([email, full_name, password, otp]):
            logger.error(f"Missing required fields: email={bool(email)}, full_name={bool(full_name)}, password={bool(password)}, otp={bool(otp)}")
            print(f"Missing required fields: email={bool(email)}, full_name={bool(full_name)}, password={bool(password)}, otp={bool(otp)}")
            return Response({"detail": "All fields are required."}, status=status.HTTP_400_BAD_REQUEST)

        # Validate OTP
        try:
            email_otp = EmailOtp.objects.get(email=email)
            logger.info(f"Found OTP in database: {email_otp.otp} for email: {email}")
            print(f"Found OTP in database: {email_otp.otp} for email: {email}")
        except EmailOtp.DoesNotExist:
            logger.error(f"No OTP found for email: {email}")
            print(f"No OTP found for email: {email}")
            return Response({"detail": "OTP not sent or invalid."}, status=status.HTTP_400_BAD_REQUEST)

        if str(email_otp.otp) != str(otp):
            logger.error(f"OTP mismatch. Expected: {email_otp.otp}, Received: {otp}")
            print(f"OTP mismatch. Expected: {email_otp.otp}, Received: {otp}")
            return Response({"detail": "Invalid OTP."}, status=status.HTTP_400_BAD_REQUEST)

        logger.info("OTP verified successfully")
        print("OTP verified successfully")

        # OTP verified, create user
        try:
            # Check if user already exists
            if CustomUser.objects.filter(email=email).exists():
                logger.error(f"User with email {email} already exists")
                print(f"User with email {email} already exists")
                return Response({"detail": "User with this email already exists."}, status=status.HTTP_400_BAD_REQUEST)

            # Create user directly
            user = CustomUser.objects.create_user(
                email=email,
                full_name=full_name,
                password=password
            )

            # Clean up OTP
            email_otp.delete()
            logger.info(f"User created successfully for email: {email}")
            print(f"User created successfully for email: {email}")

            return Response({"detail": "User registered successfully."}, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.error(f"Error creating user: {str(e)}")
            print(f"Error creating user: {str(e)}")
            return Response({"detail": f"Error creating user: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# -------------------- EXISTING LOGIN --------------------
class LoginUserView(generics.GenericAPIView):
    """
    View to login and create a token for the user.
    """
    serializer_class = CustomUserSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')
        password = request.data.get('password')

        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        if not user.check_password(password):
            return Response({"detail": "Invalid credentials."}, status=status.HTTP_400_BAD_REQUEST)

        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        logger.info(f"Access Token for {email}: {access_token}")

        return Response({
            "refresh": str(refresh),
            "access": str(access_token),
        })


# -------------------- EXISTING PROFILE --------------------
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        serializer = UserSerializer(user)
        return Response(serializer.data)


# -------------------- NEW: SEND OTP --------------------
class SendOtpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')

        if not email:
            return Response({"detail": "Email is required."}, status=status.HTTP_400_BAD_REQUEST)

        otp = random.randint(100000, 999999)

        # Save or update OTP in database
        EmailOtp.objects.update_or_create(
            email=email,
            defaults={'otp': otp, 'created_at': timezone.now()}
        )

        # Send email
        send_mail(
            'Your OTP Code',
            f'Your OTP code is {otp}',
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )

        logger.info(f"OTP {otp} sent to {email}")

        return Response({"detail": "OTP sent successfully."}, status=status.HTTP_200_OK)
