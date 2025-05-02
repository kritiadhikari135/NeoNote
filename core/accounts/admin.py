from django.contrib import admin
from .models import CustomUser, EmailOtp

class CustomUserAdmin(admin.ModelAdmin):
    model = CustomUser
    list_display = ('email', 'full_name', 'is_active', 'is_staff')
    search_fields = ('email', 'full_name')
    ordering = ('email',)

class EmailOtpAdmin(admin.ModelAdmin):
    model = EmailOtp
    list_display = ('email', 'otp', 'created_at')
    search_fields = ('email',)
    ordering = ('-created_at',)
    readonly_fields = ('created_at',)

admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(EmailOtp, EmailOtpAdmin)
