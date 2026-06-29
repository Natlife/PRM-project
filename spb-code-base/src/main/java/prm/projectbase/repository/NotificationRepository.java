package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.AppNotification;

import java.util.List;

public interface NotificationRepository extends JpaRepository<AppNotification, Long> {
    List<AppNotification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);
    List<AppNotification> findByRecipientIdAndReadAtIsNullOrderByCreatedAtDesc(Long recipientId);
    long countByRecipientIdAndReadAtIsNull(Long recipientId);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query(value = "UPDATE notifications SET notification_type = 'ACTIVITY_ASSIGNED' WHERE notification_type = 'URGENT'", nativeQuery = true)
    void fixUrgentNotifications();

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query(value = "UPDATE notifications SET notification_type = 'MILESTONE_UPDATED' WHERE notification_type = 'GRADE'", nativeQuery = true)
    void fixGradeNotifications();

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query(value = "UPDATE notifications SET notification_type = 'MATERIAL_PUBLISHED' WHERE notification_type = 'ASSIGNMENT'", nativeQuery = true)
    void fixAssignmentNotifications();
}
