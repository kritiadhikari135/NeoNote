from django.urls import path
from .views import RegisterUserView, LoginUserView, UserProfileView, SendOtpView

urlpatterns = [
    path('register/', RegisterUserView.as_view(), name='register'),
    path('login/', LoginUserView.as_view(), name='login'),
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('send-otp/', SendOtpView.as_view(), name='send_otp'),
    # Verify OTP is handled in the registration process
]
