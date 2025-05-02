# from django.db import models
# from rest_framework import viewsets, status
# from rest_framework.response import Response
# from rest_framework.decorators import action
# from rest_framework.permissions import IsAuthenticated
# from django.shortcuts import get_object_or_404
# from django.contrib.auth import get_user_model
# from .models import Project, TeamInvitation
# from .serializers import ProjectSerializer, TeamInvitationSerializer
# from accounts.models import CustomUser
# import logging
# from django.utils import timezone

# logger = logging.getLogger(__name__)

# User = get_user_model()

# class ProjectViewSet(viewsets.ModelViewSet):
#     permission_classes = [IsAuthenticated]
#     serializer_class = ProjectSerializer

#     def get_queryset(self):
#         return Project.objects.filter(
#             models.Q(user=self.request.user) |
#             models.Q(members=self.request.user)
#         ).distinct()

#     def get_serializer_context(self):
#         context = super().get_serializer_context()
#         context['request'] = self.request
#         return context

#     def perform_create(self, serializer):
#         serializer.save(user=self.request.user)

#     @action(detail=True, methods=['post'], url_path='invite_member')
#     def invite_member(self, request, pk=None):
#         project = self.get_object()

#         if project.user != request.user:
#             logger.warning("User is not the owner of the project")
#             return Response(
#                 {'error': 'Only project owner can invite members'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         email = request.data.get('email')
#         if not email:
#             logger.error("Email is missing in the request")
#             return Response(
#                 {'error': 'Email is required'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         if email == request.user.email:
#             logger.info("Validation failed: User is trying to invite themselves")
#             return Response(
#                 {'error': 'You are the host'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         logger.info(f"Invite member request received for project {project.id} with email: {email}")

#         try:
#             recipient = CustomUser.objects.get(email=email)
#         except CustomUser.DoesNotExist:
#             logger.error(f"Validation failed: User with email {email} does not exist")
#             return Response(
#                 {'error': 'User with this email does not exist'},
#                 status=status.HTTP_404_NOT_FOUND
#             )

#         if recipient in project.members.all():
#             logger.info(f"Validation failed: User {recipient.email} is already a member of the project")
#             return Response(
#                 {'error': 'User is already a member of this project'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         existing_invitation = TeamInvitation.objects.filter(
#             project=project,
#             recipient_email=email,
#             status='pending'
#         ).first()

#         if existing_invitation:
#             logger.info(f"Validation failed: An invitation has already been sent to {email}")
#             return Response(
#                 {'error': 'An invitation has already been sent to this user'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         logger.info(f"Creating a new invitation for {email}")
#         TeamInvitation.objects.create(
#             project=project,
#             sender=request.user,
#             recipient=recipient,
#             recipient_email=email
#         )

#         logger.info(f"Invitation sent successfully to {email}")
#         return Response(
#             {'message': 'Invitation sent successfully'},
#             status=status.HTTP_201_CREATED
#         )

#     def create(self, request, *args, **kwargs):
#         try:
#             logger.info(f"Attempting to create project with data: {request.data}")

#             # Check if user is authenticated
#             if not request.user.is_authenticated:
#                 logger.error("User is not authenticated")
#                 return Response(
#                     {"error": "Authentication required"},
#                     status=status.HTTP_401_UNAUTHORIZED
#                 )

#             serializer = self.get_serializer(data=request.data)
#             if serializer.is_valid():
#                 self.perform_create(serializer)
#                 logger.info(f"Project created successfully: {serializer.data}")
#                 return Response(serializer.data, status=status.HTTP_201_CREATED)

#             logger.error(f"Validation error: {serializer.errors}")
#             return Response(
#                 {"error": "Validation failed", "details": serializer.errors},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         except Exception as e:
#             logger.error(f"Error creating project: {str(e)}", exc_info=True)
#             return Response(
#                 {"error": "Failed to create project", "details": str(e)},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )

#     def update(self, request, *args, **kwargs):
#         try:
#             partial = kwargs.pop('partial', False)
#             instance = self.get_object()
#             serializer = self.get_serializer(instance, data=request.data, partial=partial)

#             if serializer.is_valid():
#                 serializer.save()
#                 return Response(serializer.data)

#             return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#         except Exception as e:
#             logger.error(f"Error updating project: {str(e)}", exc_info=True)
#             return Response(
#                 {"error": "Failed to update project", "details": str(e)},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )

#     @action(detail=True, methods=['post'], url_path='leave')
#     def leave_project(self, request, pk=None):
#         project = self.get_object()

#         if request.user not in project.members.all():
#             return Response(
#                 {'error': 'You are not a member of this project'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         # Remove related notifications for the user
#         from notifications.models import Notification
#         Notification.objects.filter(user=request.user, project=project).delete()

#         project.members.remove(request.user)
#         return Response(
#             {'message': 'You have successfully left the project'},
#             status=status.HTTP_200_OK
#         )

# class TeamInvitationViewSet(viewsets.ModelViewSet):
#     permission_classes = [IsAuthenticated]
#     serializer_class = TeamInvitationSerializer

#     def get_queryset(self):
#         # Check if include_sent parameter is provided
#         include_sent = self.request.query_params.get('include_sent', 'false').lower() == 'true'

#         if include_sent:
#             # Return both sent and received invitations
#             return TeamInvitation.objects.filter(
#                 models.Q(recipient=self.request.user) |
#                 models.Q(sender=self.request.user)
#             ).order_by('-created_at')
#         else:
#             # Return only received invitations (default behavior)
#             return TeamInvitation.objects.filter(recipient=self.request.user).order_by('-created_at')

#     @action(detail=True, methods=['post'])
#     def respond(self, request, pk=None):
#         invitation = self.get_object()
#         if invitation.recipient != request.user:
#             return Response(
#                 {'error': 'Only the recipient can respond to this invitation'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         action = request.data.get('action')
#         if action not in ['accept', 'reject']:
#             return Response(
#                 {'error': 'Invalid action'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         if invitation.status != 'pending':
#             return Response(
#                 {'error': 'Invitation has already been responded to'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         # Set responded_at timestamp
#         invitation.responded_at = timezone.now()

#         if action == 'accept':
#             invitation.project.members.add(request.user)
#             invitation.status = 'accepted'
#         else:
#             invitation.status = 'rejected'

#         invitation.save()
#         serializer = self.get_serializer(invitation)
#         return Response(serializer.data)

#     @action(detail=True, methods=['delete'], url_path='delete')
#     def delete_invitation(self, request, pk=None):
#         invitation = self.get_object()
#         if invitation.recipient != request.user and invitation.sender != request.user:
#             return Response(
#                 {'error': 'You do not have permission to delete this invitation'},
#                 status=status.HTTP_403_FORBIDDEN
#             )
#         invitation.delete()
#         return Response(
#             {'message': 'Invitation deleted successfully'},
#             status=status.HTTP_200_OK
#         )


# =================================================================================================================







from django.db import models
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from .models import Project, TeamInvitation
from .serializers import ProjectSerializer, TeamInvitationSerializer
from accounts.models import CustomUser
import logging
from django.utils import timezone

logger = logging.getLogger(__name__)

User = get_user_model()


class ProjectViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = ProjectSerializer

    def get_queryset(self):
        return Project.objects.filter(
            models.Q(user=self.request.user) |
            models.Q(members=self.request.user)
        ).distinct()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'], url_path='invite_member')
    def invite_member(self, request, pk=None):
        project = self.get_object()

        if project.user != request.user:
            logger.warning(f"User {request.user.id} is not the owner of project {project.id}")
            return Response(
                {'error': 'Only project owner can invite members'},
                status=status.HTTP_403_FORBIDDEN
            )

        email = request.data.get('email')
        if not email:
            logger.error("Email is missing in the request")
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if email == request.user.email:
            logger.info(f"User {request.user.id} tried to invite themselves to project {project.id}")
            return Response(
                {'error': 'You are the host'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            recipient = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            logger.error(f"User with email {email} does not exist")
            return Response(
                {'error': 'User with this email does not exist'},
                status=status.HTTP_404_NOT_FOUND
            )

        if recipient in project.members.all():
            logger.info(f"User {recipient.email} is already a member of project {project.id}")
            return Response(
                {'error': 'User is already a member of this project'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check for any existing invitations for this user and project
        existing_invitation = TeamInvitation.objects.filter(
            project=project,
            recipient_email=email
        ).first()

        # If there's a pending invitation, don't create a new one
        if existing_invitation and existing_invitation.status == 'pending':
            logger.info(f"A pending invitation already exists for {email} to project {project.id}")
            return Response(
                {'error': 'An invitation has already been sent to this user'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # If there's an accepted or rejected invitation, update it instead of creating a new one
        if existing_invitation:
            logger.info(f"Updating existing {existing_invitation.status} invitation for {email} to project {project.id}")

            # Update the invitation status to pending
            existing_invitation.status = 'pending'
            existing_invitation.sender = request.user
            existing_invitation.created_at = timezone.now()  # Reset creation time
            existing_invitation.save()

            # Create a new notification for the recipient about the re-invitation
            try:
                from notifications.models import Notification

                # Create a notification using our specialized method
                Notification.create_project_invitation_notification(
                    existing_invitation,
                    is_reinvitation=True
                )
                logger.info(f"Created re-invitation notification for user {recipient.id}")
            except Exception as notification_error:
                logger.error(f"Error creating re-invitation notification: {str(notification_error)}")
                # Continue even if notification creation fails
        else:
            # Create a new invitation
            logger.info(f"Creating a new invitation for {email} to project {project.id}")
            invitation = TeamInvitation.objects.create(
                project=project,
                sender=request.user,
                recipient=recipient,
                recipient_email=email
            )

            # Create a notification for the recipient
            try:
                from notifications.models import Notification

                # Create a notification using our specialized method
                Notification.create_project_invitation_notification(
                    invitation,
                    is_reinvitation=False
                )
                logger.info(f"Created invitation notification for user {recipient.id}")
            except Exception as notification_error:
                logger.error(f"Error creating invitation notification: {str(notification_error)}")
                # Continue even if notification creation fails

        logger.info(f"Invitation sent successfully to {email} for project {project.id}")
        return Response(
            {'message': 'Invitation sent successfully'},
            status=status.HTTP_201_CREATED
        )

    def create(self, request, *args, **kwargs):
        try:
            logger.info(f"Attempting to create project with data: {request.data}")

            serializer = self.get_serializer(data=request.data)
            if serializer.is_valid():
                self.perform_create(serializer)
                logger.info(f"Project created successfully: {serializer.data}")
                return Response(serializer.data, status=status.HTTP_201_CREATED)

            logger.error(f"Validation error: {serializer.errors}")
            return Response(
                {"error": "Validation failed", "details": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST
            )

        except Exception as e:
            logger.error(f"Error creating project: {str(e)}", exc_info=True)
            return Response(
                {"error": "Failed to create project", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, *args, **kwargs):
        try:
            partial = kwargs.pop('partial', False)
            instance = self.get_object()
            serializer = self.get_serializer(instance, data=request.data, partial=partial)

            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Error updating project: {str(e)}", exc_info=True)
            return Response(
                {"error": "Failed to update project", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def destroy(self, request, *args, **kwargs):
        """
        Override the destroy method to delete related notifications
        when a project is deleted.
        """
        try:
            project = self.get_object()

            # Check if user is the owner of the project
            if project.user != request.user:
                return Response(
                    {'error': 'Only the project owner can delete this project'},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get all users associated with the project (owner and members)
            project_users = list(project.members.all())
            project_users.append(project.user)

            # Delete all notifications related to this project for all users
            try:
                from notifications.models import Notification
                from django.db.models import Q

                # First, delete notifications where source_id matches the project ID
                direct_notifications_deleted, _ = Notification.objects.filter(
                    source_id=project.id).delete()

                # Next, delete invitation notifications that mention this project's name
                invitation_notifications_deleted, _ = Notification.objects.filter(
                    Q(notification_type='invitation_accepted') |
                    Q(notification_type='invitation_rejected'),
                    Q(message__contains=f"project '{project.name}'")).delete()

                # Also delete notifications for invitations related to this project
                project_invitations = project.invitations.all()
                invitation_ids = [inv.id for inv in project_invitations]

                if invitation_ids:
                    inv_source_notifications_deleted, _ = Notification.objects.filter(
                        Q(source_id__in=invitation_ids),
                        Q(notification_type='invitation_accepted') |
                        Q(notification_type='invitation_rejected')).delete()
                else:
                    inv_source_notifications_deleted = 0

                total_deleted = direct_notifications_deleted + invitation_notifications_deleted + inv_source_notifications_deleted
                logger.info(f"{total_deleted} notifications deleted for project {project.id} ({project.name})")
                logger.info(f"  - Direct: {direct_notifications_deleted}")
                logger.info(f"  - By message: {invitation_notifications_deleted}")
                logger.info(f"  - By invitation source: {inv_source_notifications_deleted}")
            except Exception as notification_error:
                logger.error(f"Error deleting project notifications: {str(notification_error)}", exc_info=True)
                # Continue with project deletion even if notification deletion fails

            # Perform the standard delete operation
            project.delete()

            return Response(status=status.HTTP_204_NO_CONTENT)

        except Exception as e:
            logger.error(f"Error deleting project: {str(e)}", exc_info=True)
            return Response(
                {"error": "Failed to delete project", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], url_path='leave')
    def leave_project(self, request, pk=None):
        project = self.get_object()

        if request.user not in project.members.all():
            return Response(
                {'error': 'You are not a member of this project'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            from notifications.models import Notification

            from django.db.models import Q

            # First, delete notifications for the user who is leaving
            user_notifications_deleted, _ = Notification.objects.filter(
                user=request.user, source_id=project.id).delete()
            logger.info(f"{user_notifications_deleted} notifications deleted for user {request.user.id} in project {project.id}")

            # Also delete any invitation notifications related to this project and user
            # This ensures that invitation notifications are also cleaned up
            invitation_notifications_deleted, _ = Notification.objects.filter(
                Q(notification_type='invitation_accepted') |
                Q(notification_type='invitation_rejected'),
                Q(user=request.user),
                Q(message__contains=f"project '{project.name}'")).delete()

            # Also delete notifications for invitations related to this project for this user
            project_invitations = project.invitations.filter(
                Q(sender=request.user) | Q(recipient=request.user)
            )
            invitation_ids = [inv.id for inv in project_invitations]

            if invitation_ids:
                inv_source_notifications_deleted, _ = Notification.objects.filter(
                    Q(source_id__in=invitation_ids),
                    Q(user=request.user),
                    Q(notification_type='invitation_accepted') |
                    Q(notification_type='invitation_rejected')).delete()

                if inv_source_notifications_deleted > 0:
                    logger.info(f"{inv_source_notifications_deleted} invitation source notifications deleted for user {request.user.id} in project {project.id}")

            if invitation_notifications_deleted > 0:
                logger.info(f"{invitation_notifications_deleted} invitation notifications deleted for user {request.user.id} in project {project.id}")

            project.members.remove(request.user)
            logger.info(f"User {request.user.id} left project {project.id}")

            return Response(
                {'message': 'You have successfully left the project'},
                status=status.HTTP_200_OK
            )

        except Exception as e:
            logger.error(f"Error while leaving project {project.id}: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while leaving the project.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TeamInvitationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = TeamInvitationSerializer

    def get_queryset(self):
        include_sent = self.request.query_params.get('include_sent', 'false').lower() == 'true'

        if include_sent:
            # Return all invitations where the user is either sender or recipient
            return TeamInvitation.objects.filter(
                models.Q(recipient=self.request.user) |
                models.Q(sender=self.request.user)
            ).order_by('-created_at')
        else:
            # Return only invitations where the user is the recipient
            return TeamInvitation.objects.filter(
                recipient=self.request.user
            ).order_by('-created_at')

    @action(detail=True, methods=['post'])
    def respond(self, request, pk=None):
        invitation = self.get_object()
        if invitation.recipient != request.user:
            return Response(
                {'error': 'Only the recipient can respond to this invitation'},
                status=status.HTTP_403_FORBIDDEN
            )

        action = request.data.get('action')
        if action not in ['accept', 'reject']:
            return Response(
                {'error': 'Invalid action'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if invitation.status != 'pending':
            return Response(
                {'error': 'Invitation has already been responded to'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Set responded_at timestamp
            invitation.responded_at = timezone.now()

            if action == 'accept':
                invitation.project.members.add(request.user)
                invitation.status = 'accepted'
                logger.info(f"User {request.user.id} accepted invitation to project {invitation.project.id}")
            else:
                invitation.status = 'rejected'
                logger.info(f"User {request.user.id} rejected invitation to project {invitation.project.id}")

            invitation.save()

            # Create notification for the sender
            try:
                from notifications.models import Notification
                Notification.create_invitation_notification(invitation, action)
                logger.info(f"Created notification for user {invitation.sender.id} about invitation {action}")
            except Exception as notification_error:
                logger.error(f"Error creating notification: {str(notification_error)}")
                # Continue even if notification creation fails

            serializer = self.get_serializer(invitation)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Error processing invitation response: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while responding to the invitation.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['delete'], url_path='delete')
    def delete_invitation(self, request, pk=None):
        invitation = self.get_object()
        if invitation.recipient != request.user and invitation.sender != request.user:
            return Response(
                {'error': 'You do not have permission to delete this invitation'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            # Delete any notifications related to this invitation
            try:
                from notifications.models import Notification
                from django.db.models import Q

                # Delete notifications where source_id matches the invitation ID
                source_notifications_deleted, _ = Notification.objects.filter(
                    Q(notification_type='invitation_accepted') |
                    Q(notification_type='invitation_rejected'),
                    Q(source_id=invitation.id)).delete()

                # Also delete notifications that mention this project
                project_name = invitation.project.name
                message_notifications_deleted, _ = Notification.objects.filter(
                    Q(notification_type='invitation_accepted') |
                    Q(notification_type='invitation_rejected'),
                    Q(message__contains=f"project '{project_name}'"),
                    Q(user=invitation.sender) | Q(user=invitation.recipient)).delete()

                total_deleted = source_notifications_deleted + message_notifications_deleted

                if total_deleted > 0:
                    logger.info(f"{total_deleted} invitation notifications deleted for invitation {pk}")
                    logger.info(f"  - By source: {source_notifications_deleted}")
                    logger.info(f"  - By message: {message_notifications_deleted}")
            except Exception as notification_error:
                logger.error(f"Error deleting invitation notifications: {str(notification_error)}", exc_info=True)
                # Continue with invitation deletion even if notification deletion fails

            invitation.delete()
            logger.info(f"Invitation {pk} deleted by user {request.user.id}")
            return Response(
                {'message': 'Invitation deleted successfully'},
                status=status.HTTP_200_OK
            )

        except Exception as e:
            logger.error(f"Error deleting invitation: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while deleting the invitation.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
