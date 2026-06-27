package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.NotificationType;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications", indexes = {
        @Index(name = "idx_notifications_recipient_id", columnList = "recipient_id"),
        @Index(name = "idx_notifications_read_at", columnList = "read_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AppNotification extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    User recipient;

    @Column(nullable = false, length = 255)
    String title;

    @Column(nullable = false, length = 2000)
    String body;

    @Enumerated(EnumType.STRING)
    @Column(name = "notification_type", nullable = false, length = 40)
    NotificationType notificationType;

    @Column(name = "reference_type", length = 50)
    String referenceType;

    @Column(name = "reference_id")
    Integer referenceId;

    @Column(name = "read_at")
    LocalDateTime readAt;
}
