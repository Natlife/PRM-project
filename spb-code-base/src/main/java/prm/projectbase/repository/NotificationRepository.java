package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.AppNotification;

import java.util.List;

public interface NotificationRepository extends JpaRepository<AppNotification, Long> {
    List<AppNotification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);
    List<AppNotification> findByRecipientIdAndReadAtIsNullOrderByCreatedAtDesc(Long recipientId);
    long countByRecipientIdAndReadAtIsNull(Long recipientId);
}
