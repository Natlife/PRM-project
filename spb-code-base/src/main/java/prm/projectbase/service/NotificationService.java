package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.response.NotificationResponse;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.entity.enums.NotificationType;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.ClassroomEnrollmentRepository;
import prm.projectbase.repository.NotificationRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final UserService userService;

    @jakarta.annotation.PostConstruct
    @Transactional
    public void init() {
        log.info("Cleaning up invalid notification types in database...");
        try {
            notificationRepository.fixUrgentNotifications();
            notificationRepository.fixGradeNotifications();
            notificationRepository.fixAssignmentNotifications();
            log.info("Database notification clean-up complete!");
        } catch (Exception e) {
            log.error("Failed to clean up database notifications: {}", e.getMessage());
        }
    }

    public AppNotification createNotification(
            User recipient,
            String title,
            String body,
            NotificationType type,
            String referenceType,
            Long referenceId) {

        log.debug("Creating notification for user {}: {}", recipient.getId(), title);

        AppNotification notification = AppNotification.builder()
                .recipient(recipient)
                .title(title)
                .body(body)
                .notificationType(type)
                .referenceType(referenceType)
                .referenceId(referenceId)
                .build();

        return notificationRepository.save(notification);
    }

    public void sendNotificationToAllEnrolled(
            Classroom classroom,
            String title,
            String body,
            NotificationType type,
            String referenceType,
            Long referenceId) {

        log.debug("Broadcasting notification in classroom {}: {}", classroom.getId(), title);

        List<ClassroomEnrollment> enrollments = enrollmentRepository.findByClassroomId(classroom.getId());

        for (ClassroomEnrollment enrollment : enrollments) {
            if (enrollment.getStatus() == ClassroomEnrollmentStatus.ACTIVE) {
                createNotification(enrollment.getStudent(), title, body, type, referenceType, referenceId);
            }
        }
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getUserNotifications() {
        User currentUser = userService.getCurrentUser();
        log.info("Fetching notifications for user {}", currentUser.getId());

        List<AppNotification> list = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(currentUser.getId());
        return list.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getUnreadNotifications() {
        User currentUser = userService.getCurrentUser();
        log.info("Fetching unread notifications for user {}", currentUser.getId());

        List<AppNotification> list = notificationRepository
                .findByRecipientIdAndReadAtIsNullOrderByCreatedAtDesc(currentUser.getId());
        return list.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long getUnreadCount() {
        User currentUser = userService.getCurrentUser();
        return notificationRepository.countByRecipientIdAndReadAtIsNull(currentUser.getId());
    }

    public NotificationResponse markAsRead(Long notificationId) {
        log.info("Marking notification {} as read", notificationId);

        AppNotification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new AppException(ErrorCode.FILE_NOT_FOUND)); 

        User currentUser = userService.getCurrentUser();
        if (!notification.getRecipient().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (notification.getReadAt() == null) {
            notification.setReadAt(LocalDateTime.now());
            notification = notificationRepository.save(notification);
        }

        return toResponse(notification);
    }

    public void markAllAsRead() {
        User currentUser = userService.getCurrentUser();
        log.info("Marking all notifications as read for user {}", currentUser.getId());

        List<AppNotification> unread = notificationRepository
                .findByRecipientIdAndReadAtIsNullOrderByCreatedAtDesc(currentUser.getId());

        LocalDateTime now = LocalDateTime.now();
        for (AppNotification notification : unread) {
            notification.setReadAt(now);
        }
        notificationRepository.saveAll(unread);
    }

    private NotificationResponse toResponse(AppNotification notif) {
        return NotificationResponse.builder()
                .id(notif.getId())
                .title(notif.getTitle())
                .body(notif.getBody())
                .notificationType(notif.getNotificationType().name())
                .referenceType(notif.getReferenceType())
                .referenceId(notif.getReferenceId())
                .readAt(notif.getReadAt())
                .createdAt(notif.getCreatedAt())
                .build();
    }
}
